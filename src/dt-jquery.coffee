{ Adapter:BrowserAdapter } = require 'dt-browser'
defaultfn = require './fn'

# TODO listen on data and use innerHTML to create all dom elems at once
#       http://blog.stevenlevithan.com/archives/faster-than-innerhtml

# TODO listen for dom events to know when a dom manipulation is ready
# TODO browser render ticks are available via canvas tag
# TODO cache css values: http://www.youtube.com/watch?v=Vp524yo0p44

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


class JQueryAdapter extends BrowserAdapter
    constructor: (@template, opts = {}) ->
        @$ ?= opts.jquery ? opts.$ ? window?.$
        # init jquery functions
        @fn ?= {}
        for n,f of defaultfn
            @fn[n] ?= f.bind(this)
        super
        @builder.adapters['jquery'] = this
        do @patch_fn

    # override builder.query
    query: (type, tag, key, old_query) ->
        return old_query.call(this, type, tag, key) unless tag._jquery?
        if type is 'attr'
            tag._jquery.attr(key)
        else if type is 'text'
            tag._jquery.text()
        else if type is 'tag'
            if key._jquery?
                key
            else
                # assume this is already a jquery object
                if (domel = key[0])?
                    attrs = {}
                    for attr in domel.attributes
                        attrs[attr.name] = attr.value
                    new @builder.Tag domel.nodeName.toLowerCase(), attrs, ->
                        @_jquery = key
                        @end()
                else
                    old_query.call(this, type, tag, key)

    # append some $fyBuilder to some fn methods

    patch_fn: ->
        # TODO somehow prevent this code injection
        fnadd = @fn.add
        @fn.add = (parent, el) ->
            res = fnadd(parent, el)
            parpar = parent.parent
            $fyBuilder(parpar) if parpar? and parpar is parpar.builder
            $fyBuilder(parent) if parent is parent.builder
            return res
        fnreplace = @fn.replace
        @fn.replace = (oldtag, newtag) ->
            res = fnreplace(oldtag, newtag)
            $fyBuilder(newtag) if newtag is newtag.builder
            return res

    # overwrite dt-browser dummies

    make: (el) ->
        if el is el.builder
            el._jquery ?= @$([], el.parent?._jquery)
            $fyBuilder(el)
        else
            el._jquery ?= @$(el.toString(), el.parent?._jquery)
            defineJQueryAPI(el)

    createPlaceholder: (el) ->
        el._jquery = @$('<placeholder>', el.parent._jquery)
        $fyBuilder(el) # includes defineJQueryAPI

    removePlaceholder: (el) ->
        el._jquery = el._jquery.not(':first') # rm placeholder
        $fyBuilder(el) # includes defineJQueryAPI

    # flow control : eventlisteners

    onshow: (el) ->
        super if el._jquery?

    onhide: (el) ->
        super if el._jquery?

    onremove: (el, opts) ->
        super if el._jquery?
        unless opts.soft
            delete el._jquery

    onend: () ->
        @template.jquery = @template._jquery = @builder._jquery
        defineJQueryAPI(@template)



jqueryify = (opts, tpl) ->
    [tpl, opts] = [opts, null] unless tpl?
    new JQueryAdapter(tpl, opts)
    return tpl

# exports

jqueryify.fn = defaultfn
jqueryify.Adapter = JQueryAdapter
module.exports = jqueryify

# browser support

( ->
    if @dynamictemplate?
        @dynamictemplate.jqueryify = jqueryify
    else
        @dynamictemplate = {jqueryify}
).call window if process.title is 'browser'
