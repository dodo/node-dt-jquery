{ Animation } = require 'animation'

# TODO i think this should work with asyncxml as well
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


jqueryify = (tpl) ->
    animation = new Animation
        timeoutexecution:'50ms'
        execution:'5ms'
        timeout:'100ms'
        toggle:on
    animation.start()

    tpl.on 'add', (parent, el) ->
        # insert into parent
        delay.call parent, ->
            if parent is tpl.xml
                parent._jquery = parent._jquery.add(el._jquery)
#                 parent._jquery.data('dt-jquery', parent)
            else
                animation.push ->
                    parent._jquery?.append(el._jquery)

    tpl.on 'close', (el) ->
        el._jquery ?= $(el.toString())
#         el._jquery.data('dt-jquery', el)
        release.call el

        el.on 'newListener', (type) ->
            return if el._events?[type]?.length # dont bind two times for the same type
            el._jquery.bind type, ->
                el.emit type, this, arguments...
                return # dont return emit result (which is either true or false)

    tpl.on 'text', (el, text) ->
        delay.call el, ->
            el._jquery.text(text)

    tpl.on 'raw', (el, html) ->
        delay.call el, ->
            animation.push ->
                el._jquery?.html(html)

    tpl.on 'show', (el) ->
        delay.call el, ->
            el._jquery.show()

    tpl.on 'hide', (el) ->
        delay.call el, ->
            el._jquery.hide()

    tpl.on 'attr', (el, key, value) ->
        delay.call el, ->
            if value is undefined
                el._jquery.removeAttr(key)
            else
                el._jquery.attr(key, value)

    tpl.on 'replace', (el, tag) ->
        delay.call el, ->
            animation.push ->
                return if removed el
                _jquery = tag._jquery ? tag
                return unless _jquery?.length > 0
                el._jquery.replaceWith(_jquery)
                # replaceWith isnt inplace
                el._jquery = _jquery
                if el is tpl.xml
                    el.jquery = _jquery

    tpl.on 'remove', (el) ->
        delay.call el.parent, ->
            el._jquery?.remove()
            delete el._jquery

    tpl.on 'end', ->
        tpl.xml._jquery = $()
#         tpl.xl._jquery.data('dt-jquery', tpl.xml)
        release.call tpl.xml
        tpl.jquery = tpl.xml._jquery
#         tpl.jquery.data('dt-jquery', tpl)

    old_query = tpl.xml.query
    tpl.xml.query = (type, tag, key) ->
        return old_query.call(this, type, tag, key) unless tag._jquery?
        if type is 'attr'
            tag._jquery.attr(key)
        else if type is 'text'
            tag._jquery.text()
        else if type is 'tag'
#             $(key).data('dt-jquery')
            if key._jquery?
                key
            else
                # assume this is allready a jquery object
                {_jquery:key}
#                 $(key).data('dt-jquery') or {_jquery:key}

    return tpl

# exports

module.exports = jqueryify

# browser support

( ->
    if @dynamictemplate?
        @dynamictemplate.jqueryify = jqueryify
    else
        @dynamictemplate = {jqueryify}
).call window if process.title is 'browser'
