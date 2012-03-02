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
        do job
    else
        @_jquery_delay ?= []
        @_jquery_delay.push(job)


# invoke all delayed jquery work
release = () ->
    if @_jquery_delay?
        for job in @_jquery_delay
            do job
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
                    {_jquery:key}
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
        # insert into parent
        delay.call parent, =>
            if parent is @builder
                parent._jquery = parent._jquery.add(el._jquery)
#                 parent._jquery.data('dt-jquery', parent)
#                 console.error "ready!", el.name, el._jquery_ready
                el._jquery_ready?()
                el._jquery_ready = yes
            else
                @animation.push ->
                    parent._jquery?.append(el._jquery)
                    # FIXME listen on dom insertion event
#                     console.error "ready!", el.name, el._jquery_ready
                    el._jquery_ready?()
                    el._jquery_ready = yes

    onclose: (el) ->
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
            el._jquery.text(text)

    onraw: (el, html) ->
        delay.call el, =>
            @animation.push ->
                el._jquery?.html(html)

    onshow: (el) ->
        delay.call el, ->
            el._jquery.show()

    onhide: (el) ->
        delay.call el, ->
            el._jquery.hide()

    onattr: (el, key, value) ->
        delay.call el, ->
            if value is undefined
                el._jquery.removeAttr(key)
            else
                el._jquery.attr(key, value)

    onreplace: (el, tag) ->
        delay.call el, =>
            @animation.push =>
                return if removed el
                _jquery = tag._jquery ? tag
                return unless _jquery?.length > 0
                el._jquery.replaceWith(_jquery)
                # replaceWith isnt inplace
                el._jquery = _jquery
                if el is @builder
                    el.jquery = _jquery

    onremove: (el) ->
        delay.call el.parent, ->
            el._jquery?.remove()
            delete el._jquery

    onend: () ->
        @builder._jquery = $()
#         @builder._jquery.data('dt-jquery', @template.xml)
        release.call @builder
        @template.jquery = @builder._jquery
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
