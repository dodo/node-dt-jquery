{ Adapter:BrowserAdapter } = require 'dt-browser-shared'
{ defineJQueryAPI, $fyBuilder,
  createSpaceholder } = require './util'
defaultfn = require './fn'
{ isArray } = Array

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

    make: (el) ->
        if el is el.builder
            el._jquery ?= @$([], el.parent?._jquery)
            $fyBuilder(el)
        else
            el._jquery ?= @$(el.toString(), el.parent?._jquery)
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

    # ready callbacks

    insert_callback: (el) -> # the best i could do :(
        if el._jquery.length is 0
            createSpaceholder.call(this, el, el.parent._jquery)
        @fn.add(el.parent, el) # part of dt-browser-shared
        if el.parent._jquery_wrapped
            el.parent._jquery_wrapped = no
            el.parent._jquery = el.parent._jquery.not(':first') # rm placeholder span
        $fyBuilder(el.parent) if el.parent is el.parent.builder
        el._browser_ready?()
        el._browser_ready  = yes # part of dt-browser-shared
        el._browser_insert = yes # part of dt-browser-shared

    replace_callback: (oldtag, newtag) ->
        if newtag._jquery.length is 0
            createSpaceholder.call(this, newtag, newtag.parent._jquery)
        super
        $fyBuilder(newtag) if newtag is newtag.builder


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
