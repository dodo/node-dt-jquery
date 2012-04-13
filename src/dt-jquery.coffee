{ Animation } = require 'animation'
{ singlton_callback, deferred_callbacks,
  cancelable_and_retrivable_callbacks,
  defineJQueryAPI, removed, $fyBuilder } = require './util'

EVENTS = [
    'add', 'end'
    'show', 'hide'
    'attr','text', 'raw'
    'remove', 'replace'
]

# TODO listen on data and use innerHTML to create all dom elems at once
#       http://blog.stevenlevithan.com/archives/faster-than-innerhtml

# TODO listen for dom events to know when a dom manipulation is ready
# TODO mit canvas tag kommt man direkt auf die browser render ticks.


class JQueryAdapter
    constructor: (@template, opts = {}) ->
        @fn = @fn()
        @builder = @template.xml ? @template
        # defaults
        opts.timeoutexecution ?= '20ms'
        opts.execution        ?= '4ms'
        opts.timeout          ?= '120ms'
        opts.toggle           ?= on
        @$ ?= opts.jquery ? opts.$ ? window?.$
        # init requestAnimationFrame handler
        @animation = new Animation(opts)
        @animation.start()
        @initialize()

    initialize: () ->
        do @listen
        # prefill builder with state
        @builder._jquery = @$([])
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

    # jQuery commands

    fn: ->
        add: (parent, el) =>
            if el._jquery.length is 0
                el._jquery = @$('<spaceholder>', parent._jquery)
                el._jquery_wrapped = yes
                if el is el.builder
                    $fyBuilder(el) # includes defineJQueryAPI
                else
                    defineJQueryAPI(el)
            $par = parent._jquery
            if parent is parent.builder
                i = $par.length - 1
                $par = $par.add(el._jquery)
                if $par.parent().length > 0
                    if parent._jquery_wrapped
                        parent._jquery_wrapped = no
                        $par.filter('spaceholder').replaceWith(el._jquery)
                    else
                        el._jquery.insertAfter($par[i])
            else
                $par.append(el._jquery)
            if parent._jquery_wrapped
                parent._jquery_wrapped = no
                $par = $par.not('spaceholder') # rm placeholder span
            parent._jquery = $par
            $fyBuilder(parent) if parent is parent.builder

        replace: (oldtag, newtag) =>
            return if removed newag
            _jquery = newtag._jquery ? newtag
            oldtag._jquery.replaceWith(_jquery)
            # replaceWith isnt inplace
            newtag._jquery = _jquery
            if newtag is newtag.builder
                newtag.jquery = _jquery

        text: (el, text) =>
            el._jquery.text(text)

        raw: (el, html) =>
            el._jquery.html(html)

        attr: (el, key, value) =>
            if value is undefined
                el._jquery.removeAttr(key)
            else
                el._jquery.attr(key, value)

        show: (el) =>
            el._jquery.show()

        hide: (el) =>
            el._jquery.hide()

        remove: (el) =>
            el._jquery.remove()

    # eventlisteners

    onadd: (parent, el) ->
        return if removed el
        if el is el.builder
            el._jquery ?= @$([], el.parent?._jquery)
        else
            el._jquery ?= @$(el.toString(), el.parent._jquery)
        defineJQueryAPI(el)

        that = this
        el._jquery_manip    ?= cancelable_and_retrivable_callbacks()
        el._jquery_done     ?= deferred_callbacks()
        parent._jquery_done ?= deferred_callbacks()
        for tag in [parent, el]
            cb = tag._jquery_done.callback()
            if tag is that.builder
                cb()
            else
                tag.ready(cb)

        el._jquery_insert ?= singlton_callback el, ->
            that.fn.add(@parent, this)
            @_jquery_ready?()
            @_jquery_ready = yes
            @_jquery_insert = yes
        el._jquery_insert.replace?(el)

        el._jquery_parent_done ?= singlton_callback el, ->
            return if removed this
            if @parent is that.builder
                if @parent._jquery_insert is true
                    that.animation.push(@_jquery_insert)
                else
                    @_jquery_insert?()
            else
                that.animation.push(@_jquery_insert)
        el._jquery_parent_done.replace?(el)
        parent._jquery_done(el._jquery_parent_done)

    onreplace: (oldtag, newtag) ->
        newtag._jquery_parent_done ?= oldtag._jquery_parent_done
        newtag._jquery_insert      ?= oldtag._jquery_insert
        newtag._jquery_done        ?= oldtag._jquery_done
        oldtag._jquery_parent_done  = null
        oldtag._jquery_insert       = null
        oldtag._jquery_done         = null

        @onadd(oldtag.parent, newtag)

        oldtag._jquery_manip?.cancel?()
        newtag._jquery_manip.reset()
        # if manip left from last time run them
        while (cb = newtag._jquery_manip.callbacks.shift())?
            @animation.push(cb)

        if newtag._jquery_insert is true
            that = this
            newtag._jquery_replace ?= oldtag._jquery_replace
            noreplacerequest = newtag._jquery_replace?
            newtag._jquery_replace ?= singlton_callback newtag, ->
                that.fn.replace(oldtag, this)
            newtag._jquery_replace.replace?(newtag)
            oldtag._jquery_replace = null
            if noreplacerequest
                @animation.push(newtag._jquery_replace)

    ontext: (el, text) ->
        @animation.push el._jquery_manip =>
            @fn.text(el, text)

    onraw: (el, html) ->
        @animation.push el._jquery_manip =>
            @fn.raw(el, html)

    onattr: (el, key, value) ->
        @animation.push el._jquery_manip =>
            @fn.attr(el, key, value)

    onshow: (el) ->
        @fn.show(el)

    onhide: (el) ->
        @fn.hide(el)

    onremove: (el) ->
        return unless el._jquery?
        @fn.remove(el)
        el._jquery_done.reset()
        el._jquery_manip?.cancel()
        delete el._jquery_manip
        delete el._jquery_done
        delete el._jquery

    onend: () ->
#         @builder._jquery.data('dt-jquery', @template.xml)
        @template.jquery = @template._jquery = @builder._jquery
        defineJQueryAPI(@template)
#         @template.jquery.data('dt-jquery', tpl)



jqueryify = (opts, tpl) ->
    [tpl, opts] = [opts, null] unless tpl?
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
