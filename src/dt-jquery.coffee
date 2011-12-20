
# TODO i think this should work with asyncxml as well
# TODO use requestAnimationFrame to update dom
# TODO listen on data and use innerHTML to create all dom elems at once
#       http://blog.stevenlevithan.com/archives/faster-than-innerhtml

jqueryify = (tpl) ->
    tpl.xml._jquery = $()

    tpl.on 'close', (el) ->
        el._jquery = $(el.toString())
        # invoke all delayed jquery work
        if el._jquery_delay?
            for delay in el._jquery_delay
                delay?()
            delete el._jquery_delay
        # insert into parent
        append = ->
            if el.parent is tpl.xml
                el.parent._jquery = el.parent._jquery.add(el._jquery)
            else
                el.parent._jquery.append(el._jquery)
        # only when parent is ready
        if el.parent._jquery?
            append()
        else
            el.parent._jquery_delay ?= []
            el.parent._jquery_delay.push(append)

        el.on 'newListener', (type) ->
            return if el._events?[type]?.length # dont bind two times for the same type
            el._jquery.bind type, ->
                el.emit type, this, arguments...
                return # dont return emit result (which is either true or false)

    tpl.on 'text', (el, text) ->
        settext = ->
            el._jquery.text(text)
        # only when tag is ready
        if el._jquery?
            settext()
        else
            el._jquery_delay ?= []
            el._jquery_delay.push(settext)


    tpl.on 'attr', (el, key, value) ->
        el._jquery?.attr key, value

    tpl.on 'attr:remove', (el, key) ->
        el._jquery?.removeAttr key

    tpl.on 'remove', (el) ->
        el._jquery?.remove()

    tpl.on 'end', ->
        tpl.jquery = tpl.xml._jquery

    old_query = tpl.xml.query
    tpl.xml.query = (type, tag, key) ->
        return old_query.call(this, type, tag, key) unless tag._jquery?
        if type is 'attr'
            tag._jquery.attr(key)
        else if type is 'text'
            tag._jquery.text()

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
