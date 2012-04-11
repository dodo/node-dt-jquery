{ Animation } = require 'animation'

EVENTS = [
    'add', 'close', 'end'
    'show', 'hide'
    'attr','text', 'raw'
    'remove', 'replace'
]

# TODO listen on data and use innerHTML to create all dom elems at once
#       http://blog.stevenlevithan.com/archives/faster-than-innerhtml

# TODO listen for dom events to know when a dom manipulation is ready
# TODO mit canvas tag kommt man direkt auf die browser render ticks.


# multiple changes of this context possible
singlton_callback = (that, callback) ->
    req = -> callback?.apply(that, arguments)
    req.replace = (replacement) -> that = req.that = replacement
    req.that = that
#     req.callback = callback?.callback
#     req.cancel = callback?.cancel
    return req

cancelable_callback = (callback) ->
    canceled = no
    cb = -> callback?() unless canceled
    cb.cancel = -> canceled = yes
    cb.cancel.reset = -> canceled = no
#     cb.callback = callback?.callback
#     cb.replace = callback?.replace
    return cb

deferred_callbacks = () ->
    done = no
    callbacks = []
    res = (cb) ->
        return cb?() if done
        callbacks.push(cb)
    allowed = null
    res.callback = ->
        return (->) if done
        callback = ->
            if callback is allowed
                while (cb = callbacks.shift())?
                    cb?(arguments...)
                callbacks = null
                allowed = null
                done = yes
        allowed = callback
        return callback
    return res

cancelable_and_retrivable_callbacks = () ->
    canceled = no
    res = (cb) ->
        return ->
            if canceled
                res.callbacks.push(cb)
            else
                cb?(arguments...)
    res.cancel = -> canceled = yes
    res.reset = -> canceled = no
    res.callbacks = []
    return res


removed = (el) ->
    el.closed is "removed"


# NOTE delay and release are only for manipulations where no parent is needed
# delay or invoke job immediately
delay = (job) ->
    return if removed this
    # only when tag is ready
    if @_jquery?
        job.call(this)
    else
        @_jquery_delay ?= []
        @_jquery_delay.push(job)


# invoke all delayed jquery work
release = () ->
    if @_jquery_delay?
        for job in @_jquery_delay
            job.call(this)
        delete @_jquery_delay


class JQueryAdapter
    constructor: (@template, opts = {}) ->
        @builder = @template.xml ? @template
        # defaults
        opts.timeoutexecution ?= '20ms'
        opts.execution        ?= '4ms'
        opts.timeout          ?= '120ms'
        opts.toggle           ?= on
        # init requestAnimationFrame handler
        @animation = new Animation(opts)
        @animation.start()
        @initialize()

    initialize: () ->
        do @listen
        # prefill builder with state
        @builder._jquery = $([])
        @builder._jquery_done = deferred_callbacks()
        do @builder._jquery_done.callback() # builder is allways done
        # override query
        old_query = @builder.query
        @builder.query = (type, tag, key) ->
            return old_query.call(this, type, tag, key) unless tag._jquery?
            if type is 'attr'
                tag._jquery.attr(key)
            else if type is 'text'
                tag._jquery.text()
            else if type is 'tag'
#                 $(key).data('dt-jquery')
                if key._jquery?
                    key
                else
                    # assume this is allready a jquery object
                    if (domel = key[0])?
                        attrs = {}
                        for attr in domel.attributes
                            attrs[attr.name] = attr.value
                        new @builder.Tag domel.nodeName.toLowerCase(), attrs, ->
                            @_jquery = key
                            @end()
                    else
                        old_query.call(this, type, tag, key)
#                     $(key).data('dt-jquery') or {_jquery:key}
        # register ready handler
        @template.register 'ready', (tag, next) ->
            # when tag is already in the dom its fine,
            #  else wait until it is inserted into dom
            if tag._jquery_ready is yes
                next(tag)
            else
                tag._jquery_ready = ->
                    next(tag)

    listen: () ->
        EVENTS.forEach (event) =>
            @template.on(event, this["on#{event}"].bind(this))

    # eventlisteners

    onadd: (parent, el) ->
        that = this
        # `this` changes in onreplace
        el._jquery_insert ?= singlton_callback el, ->
            return if removed this
            if @parent is @parent.builder
                $root = @parent._jquery.parent()
                if $root.length is 0
                    jq = @parent._jquery
                    jq = jq.add(@_jquery)
                    if @parent is that.builder
                        that.template.jquery = jq
                        that.template._jquery = jq
                        @parent.jquery = jq
                    @parent._jquery = jq
                else
                    $root.append(@_jquery)
            else
                @parent._jquery?.append(@_jquery)
            @_jquery_ready?()
            @_jquery_ready = yes
            @_jquery_insert = yes
        el._jquery_insert.replace?(el)

        el._jquery_manip ?= cancelable_and_retrivable_callbacks()
        el._jquery_done ?= deferred_callbacks()
        el.ready(el._jquery_done.callback())


    onclose: (el) ->
        if el is el.builder
            el._jquery ?= $([], el.parent._jquery)
        else
            el._jquery ?= $(el.toString(), el.parent._jquery)
        release.call el


        insertion = el._jquery_insert
        insertion = el._jquery_replace if insertion is yes
        if insertion is undefined
            @onadd(el.parent, el)
            insertion = el._jquery_insert
        el.parent?._jquery_done? =>
            if el.parent is el.parent.builder
                insertion()
            else
                @animation.push(insertion)
            # if manip left from last time run them
            insertion?.that?._jquery_manip?.reset()
            while (cb = insertion?.that?._jquery_manip?.callbacks.shift())?
                @animation.push(cb)

    onreplace: (oldtag, newtag) ->
        newtag._jquery_insert ?= oldtag._jquery_insert
        oldtag._jquery_insert = null

        if newtag._jquery_insert is true
            newtag._jquery_replace ?= oldtag._jquery_replace
            noreplacerequest = newtag._jquery_replace?
            newtag._jquery_replace ?= singlton_callback newtag, ->
                return if removed this
                _jquery = @_jquery ? this
#                 return unless _jquery?.length
                oldtag._jquery.replaceWith(_jquery)
                # replaceWith isnt inplace
                @_jquery = _jquery
                if this is @builder
                    @jquery = _jquery
            oldtag._jquery_replace = null
            replace = newtag._jquery_replace
            replace.replace?(newtag)
        else
            newtag._jquery_insert.replace?(newtag)

        newtag._jquery_manip ?= cancelable_and_retrivable_callbacks()
        oldtag._jquery_manip?.cancel?()
        newtag._jquery_manip.reset()
        unless newtag.closed
            # if manip left from last time run them
            while (cb = newtag._jquery_manip.callbacks.shift())?
                @animation.push(cb)

        newtag._jquery_done ?= oldtag._jquery_done
        newtag._jquery_done ?= deferred_callbacks()
        oldtag._jquery_done = null
        cb = newtag._jquery_done.callback()
        if newtag is newtag.builder
            cb()
        else unless newtag.closed
            newtag.ready(cb)
        if (newtag._jquery_insert is true and newtag.closed) or noreplacerequest
            @onclose(newtag)
        # else just throw cb away, but reset allowed callback

    ontext: (el, text) ->
        that = this
        delay.call el, ->
            that.animation.push @_jquery_manip =>
                @_jquery.text(text)

    onraw: (el, html) ->
        that = this
        delay.call el, ->
            that.animation.push @_jquery_manip =>
                @_jquery?.html(html)

    onattr: (el, key, value) ->
        that = this
        delay.call el, ->
            that.animation.push @_jquery_manip =>
                if value is undefined
                    @_jquery.removeAttr(key)
                else
                    @_jquery.attr(key, value)

    onshow: (el) ->
        delay.call el, ->
            @_jquery.show()

    onhide: (el) ->
        delay.call el, ->
            @_jquery.hide()

    onremove: (el) ->
        if el._jquery?
            el._jquery.remove()
            el._jquery_manip?.cancel()
            delete el._jquery_manip
            delete el._jquery

    onend: () ->
#         @builder._jquery.data('dt-jquery', @template.xml)
        @template.jquery = @template._jquery = @builder._jquery
#         @template.jquery.data('dt-jquery', tpl)



jqueryify = (tpl, opts) ->
    new JQueryAdapter(tpl, opts)
    return tpl

# exports

jqueryify.Adapter = JQueryAdapter
module.exports = jqueryify

# browser support

( ->
    if @dynamictemplate?
        @dynamictemplate.jqueryify = jqueryify
    else
        @dynamictemplate = {jqueryify}
).call window if process.title is 'browser'
