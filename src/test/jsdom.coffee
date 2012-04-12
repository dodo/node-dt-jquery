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

    add:
        setUp: (callback) ->
            @api = new EventEmitter
            @results = "no results"
            setTimeout =>
                @æ.equal @html(@tpl.jquery), @results
                @æ.done()
            , 100
            callback()


        simple: (æ) ->
            @æ = æ ; { $, api } = this
            tpl = @tpl = jqueryify {$}, new Template schema:5, ->
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

            @results = [
                '<div class="content">'
                "<span><p>foo</p></span>"
                "<footer><p>bar</p></footer>"
                "</div>"
            ].join("")


        'after end': (æ) ->
            @æ = æ ; { $, api } = this
            tpl = @tpl = jqueryify {@$}, new Template schema:5, ->
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

            @results = [
                '<div class="content">'
                "<span><p>foo</p></span>"
                "</div>"
            ].join("")


        'to second level': (æ) ->
            @æ = æ ; { $, api } = this
            footer = null
            tpl = @tpl = jqueryify {@$}, new Template schema:5, ->
                api.on('view', @$div(class:'content').add)


            setTimeout ->
                api.emit 'view', footer = new Template schema:5, ->
                    api.on('footer', @$footer().add)
                æ.equal "8#{tpl is footer.xml?.parent?.builder?.template}", "8true"
            , 8

            setTimeout ->
                api.emit 'footer', t = new Template schema:5, ->
                    @$p ->
                        @text "foo"
                        @span "lol"
                    @$p ->
                        @text "bar"
                        @span "rofl"
                æ.equal "47#{footer is t.xml?.parent?.builder?.template}", "47true"
            , 47

            @results = [
                '<div class="content">'
                "<footer>"
                "<p>foo<span>lol</span></p>"
                "<p>bar<span>rofl</span></p>"
                "</footer>"
                "</div>"
            ].join("")


