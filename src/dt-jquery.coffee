{ Adapter:BrowserAdapter } = require 'dt-browser'
{ defineJQueryAPI, $fyBuilder } = require './util'
defaultfn = require './fn'

# TODO listen on data and use innerHTML to create all dom elems at once
#       http://blog.stevenlevithan.com/archives/faster-than-innerhtml

# TODO listen for dom events to know when a dom manipulation is ready
# TODO browser render ticks are available via canvas tag
# TODO cache css values: http://www.youtube.com/watch?v=Vp524yo0p44


class JQueryAdapter extends BrowserAdapter
    constructor: (@template, opts = {}) ->
        @$ ?= opts.jquery ? opts.$ ? window?.$
        # init jquery functions
        @fn ?= {}
        for n,f of defaultfn
            @fn[n] ?= f.bind(this)
        super

    initialize: () ->
        super
        # override query
        old_query = @builder.query
        @builder.query = (type, tag, key) ->
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

    make: (el) ->
        if el is el.builder
            el._jquery ?= @$([], el.parent?._jquery)
            $fyBuilder(el)
        else
            el._jquery ?= @$(el.toString(), el.parent?._jquery)
            defineJQueryAPI(el)

    createPlaceholder: (el) ->
        el._jquery = @$('<placeholder>', el.parent._jquery)
        if el is el.builder
            $fyBuilder(el) # includes defineJQueryAPI
        else
            defineJQueryAPI(el)

    removePlaceholder: (el) ->
        el._jquery = el._jquery.not(':first') # rm placeholder
        if el is el.builder
            $fyBuilder(el) # includes defineJQueryAPI
        else
            defineJQueryAPI(el)

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
