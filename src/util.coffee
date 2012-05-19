
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


# exports

module.exports = {
    defineJQueryAPI,
    $fyBuilder,
}
