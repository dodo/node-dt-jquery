{ EventEmitter } = require 'events'
jQuery = require 'jquery'
jqueryify = require '../dt-jquery'
{ Template } = require 'dynamictemplate'

HTML = ($,el) ->
    $div = $('<div>')
    $div.append(el)
    $div.html() or "<empty/>" # m(

module.exports =

    setUp: (callback) ->
        @$ = jQuery.create()
        @html = (el) => HTML(@$,el)
        callback()

# --------------

    simple: (æ) ->
        tpl = jqueryify {@$}, new Template schema:5, ->
            @$div class:'content', ->
                @$p("bla").ready(done)

        done = =>
            æ.equal @html(tpl.jquery), [
                '<div class="content">'
                "<p>bla</p>"
                "</div>"
            ].join("")
            æ.done()

    add: (æ) ->
        api = new EventEmitter
        tpl = jqueryify {@$}, new Template schema:5, ->
            api.on('view', @$div(class:'content').add)

        setTimeout ->
            api.emit 'view', t = new Template schema:5, ->
                @$footer ->
                    @$p "bar"
            æ.equal "42#{tpl is t.xml?.parent?.builder?.template}", "42true"
        , 42

        setTimeout ->
            api.emit 'view', t = new Template schema:5, ->
                @$span ->
                    @$p "foo"
            æ.equal "23#{tpl is t.xml?.parent?.builder?.template}", "23true"
        , 23

        setTimeout =>
            æ.equal @html(tpl.jquery), [
                '<div class="content">'
                "<span><p>foo</p></span>"
                "<footer><p>bar</p></footer>"
                "</div>"
            ].join("")
            æ.done()
        , 100

    'add after end': (æ) ->
        api = new EventEmitter
        tpl = jqueryify {@$}, new Template schema:5, ->
            content = @$div class:'content'
            api.on('view', content.add)
            content.ready(next_step)

        next_step = ->
            setTimeout ->
                api.emit 'view', t = new Template schema:5, ->
                    @$span ->
                        @$p "foo"
                æ.equal "16#{tpl is t.xml?.parent?.builder?.template}", "16true"
            , 16

        setTimeout =>
            æ.equal @html(tpl.jquery), [
                '<div class="content">'
                "<span><p>foo</p></span>"
                "</div>"
            ].join("")
            æ.done()
        , 100





