
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


createSpaceholder = (el, $par) ->
    el._jquery = @$('<spaceholder>', $par)
    el._jquery_wrapped = yes
    if el is el.builder
        $fyBuilder(el) # includes defineJQueryAPI
    else
        defineJQueryAPI(el)

# exports

module.exports = {
    createSpaceholder,
    defineJQueryAPI,
    $fyBuilder,
}
