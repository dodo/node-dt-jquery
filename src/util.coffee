
# multiple changes of this context possible
singlton_callback = (that, callback) ->
    req = -> callback?.apply(that, arguments)
    req.replace = (replacement) -> that = replacement
    return req

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
    res.reset = ->
        allowed = null
        callbacks = []
        done = no
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


defineJQueryAPI = (el) ->
    # let $(el) work magically
    el.__defineGetter__('selector', -> el._jquery.selector)
    el.__defineGetter__('context',  -> el._jquery.context )


$fyBuilder = (builder) ->
    $builder = builder._jquery
    builder.jquery = $builder
    builder.template.jquery = $builder
    builder.template._jquery = $builder
    defineJQueryAPI(builder.template)
    defineJQueryAPI(builder)


removed = (el) ->
    el.closed is "removed"


# exports

module.exports = {
    singlton_callback,
    deferred_callbacks,
    cancelable_and_retrivable_callbacks,
    defineJQueryAPI,
    $fyBuilder,
    removed,
}
