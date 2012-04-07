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


removed = (el) ->
    el.closed is "removed"

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
        @builder._jquery_tracker = el:@builder
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
        el._jquery_tracker = {el}
        # insert into parent
        that = this
        delay.call parent, -> # !
            el = el?._jquery_tracker?.el
            return if not el or removed this
            if this is @builder and @_jquery.parent().length is 0
                @_jquery = @_jquery.add(el._jquery)
#                 parent._jquery.data('dt-jquery', parent)
#                 console.error "ready!", el.name, el._jquery_ready
                el._jquery_ready?()
                el._jquery_ready = yes
            else
                parent = @_jquery_tracker.el
                done = -> that.animation.push ->
                    parent = parent?._jquery_tracker?.el
                    el = el?._jquery_tracker?.el
                    return unless parent and el
                    if parent is parent.builder
                        parent._jquery.parent().append(el._jquery)
                    else
                        for e in el._jquery ? []
                            parent._jquery?.append(e)
                    # FIXME listen on dom insertion event
#                     console.error "ready!", el.name, el._jquery_ready
                    el._jquery_ready?()
                    el._jquery_ready = yes
                # delay til end if el is a builder
                if el is el.builder
                    el.ready(done)
                else
                    done()

    onclose: (el) ->
        el._jquery_tracker ?= {el}
#         return if removed el
        if el is el.builder
            el._jquery ?= $()
        else
            el._jquery ?= $(el.toString())
#         el._jquery.data('dt-jquery', el)
        release.call el

        el.on 'newListener', (type) ->
            return if el._events?[type]?.length # dont bind two times for the same type
            el._jquery.bind type, ->
                el.emit type, this, arguments...
                return # dont return emit result (which is either true or false)

    ontext: (el, text) ->
        delay.call el, ->
            @_jquery.text(text)

    onraw: (el, html) ->
        that = this
        delay.call el, ->
            that.animation.push =>
                @_jquery?.html(html)

    onshow: (el) ->
        delay.call el, ->
            @_jquery.show()

    onhide: (el) ->
        delay.call el, ->
            @_jquery.hide()

    onattr: (el, key, value) ->
        delay.call el, ->
            if value is undefined
                @_jquery.removeAttr(key)
            else
                @_jquery.attr(key, value)

    onreplace: (oldtag, newtag) ->
        newtag._jquery_tracker ?= el:newtag
        oldtag._jquery_tracker.el = newtag
        that = this
        delay.call oldtag, ->
            newtag = newtag._jquery_tracker.el
            delay.call newtag, ->
                that.animation.push =>
                    newtag = @_jquery_tracker.el
                    return if removed(oldtag) or removed(newtag)
                    _jquery = newtag._jquery ? newtag
                    return unless _jquery?.length > 0
                    oldtag._jquery.replaceWith(_jquery)
                    # replaceWith isnt inplace
                    for tag in [oldtag, newtag]
                        tag._jquery = _jquery
                        if tag is tag.builder
                            tag.jquery = _jquery

    onremove: (el) ->
        if el._jquery?
            el._jquery.remove()
            delete el._jquery
        delete el._jquery_tracker

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
