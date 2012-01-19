
# TODO i think this should work with asyncxml as well
# TODO use requestAnimationFrame to update dom
# TODO listen on data and use innerHTML to create all dom elems at once
#       http://blog.stevenlevithan.com/archives/faster-than-innerhtml

# requestAnimationFrame shim
requestAnimationFrame = do ->
    last = 0
    request = window.requestAnimationFrame
    for vendor in ["webkit", "moz", "o", "ms"]
        break if (request ?= window["#{vendor}RequestAnimationFrame"])
    return request ? (callback) ->
        cur = new Date().getTime()
        time = Math.max(0, 16 - cur + last)
        setTimeout(callback, time)

frame_queue = []
frame_set = no
nextAnimationFrame = (cb) ->
    frame_queue.push (cb)
    return unless frame_set
    frame_set = yes
    next = ->
        requestAnimationFrame ->
            work_frame_queue()
            if frame_queue.length
                next()
            else
                frame_set = no
    next()

work_frame_queue = ->
    t1 = t2 = new Date().getTime()
    n = 0
    while frame_queue.length && t2 - t1 < 25
        cb = frame_queue.shift()
        cb?()
        n++
        t2 = new Date().getTime()

# delay or invoke job immediately
delay = (job) ->
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

    tpl.on 'add', (parent, el) ->
        # insert into parent
        delay.call parent, ->
            if parent is tpl.xml
                parent._jquery = parent._jquery.add(el._jquery)
#                 parent._jquery.data('dt-jquery', parent)
            else
                nextAnimationFrame ->
                    parent._jquery.append(el._jquery)

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
            nextAnimationFrame ->
                el._jquery.html(html)

    tpl.on 'show', (el) ->
        delay.call el, ->
            el._jquery.show()

    tpl.on 'hide', (el) ->
        delay.call el, ->
            el._jquery.hide()

    tpl.on 'attr', (el, key, value) ->
        delay.call el, ->
            el._jquery.attr(key, value)

    tpl.on 'attr:remove', (el, key) ->
        delay.call el, ->
            el._jquery.removeAttr(key)

    tpl.on 'replace', (el, tag) ->
        delay.call el, ->
            nextAnimationFrame ->
                _jquery = tag._jquery ? tag
                return unless _jquery?.length > 0
                el._jquery.replaceWith(_jquery)
                # replaceWith isnt inplace
                el._jquery = _jquery
                if el is tpl.xml
                    el.jquery = _jquery

    tpl.on 'remove', (el) ->
        el._jquery?.remove()

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
