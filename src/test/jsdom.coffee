{ EventEmitter } = require 'events'
jQuery = require 'jquery'
jqueryify = require '../dt-jquery'
{ Template } = require 'dynamictemplate'

HTML = (el) -> el.wrap('<div>').parent().html() # m(

module.exports =

    simple: (æ) ->
        $ = jQuery.create()
        tpl = jqueryify {$}, new Template schema:5, ->
            @$div class:'content', ->
                @$p("bla").ready(done)

        done = ->
            æ.equal HTML(tpl.jquery), [
                '<div class="content">'
                "<p>bla</p>"
                '</div>'
            ].join("")
            æ.done()

    add: (æ) ->
        $ = jQuery.create()
        api = new EventEmitter
        tpl = jqueryify {$}, new Template schema:5, ->
#             api.on('view', @$div(class:'content').add)
            div = @$div(class:'content')
            add = div.add
            div.on 'add', ->
                console.log 'div.add'

            api.on 'view', (x) ->
                console.log "view"
                add(x)

        setTimeout ->
            console.log "42>"
            api.emit 'view', t = new Template schema:5, ->
                @$footer ->
                    @$p "bar"
            æ.equal "42#{tpl is t.xml?.parent?.builder?.template}", "42true"
        , 42

        setTimeout ->
            console.log "23>"
            api.emit 'view', t = new Template schema:5, ->
                @$span ->
                    @$p "foo"
            console.log "<23"
            æ.equal "23#{tpl is t.xml?.parent?.builder?.template}", "23true"
        , 23

        setTimeout ->
            æ.equal HTML(tpl.jquery), [
                '<div class="content">'
                "<span><p>foo</p></span>"
                "<footer><p>bar</p></footer>"
                '</div>'
            ].join("")
            æ.done()
        , 100


