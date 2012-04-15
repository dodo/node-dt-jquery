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


    normal: (æ) ->
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
                æ.equal "42#{tpl is t.xml?.parent?.builder?.template}",
                        "42true"
            , 42

            setTimeout ->
                api.emit 'view', t = new Template schema:5, ->
                    @$span ->
                        @$p "foo"
                æ.equal "23#{tpl is t.xml?.parent?.builder?.template}",
                        "23true"
            , 23

            @results = [
                '<div class="content">'
                "<span><p>foo</p></span>"
                "<footer><p>bar</p></footer>"
                "</div>"
            ].join("")


        'after end': (æ) ->
            @æ = æ ; { $, api } = this
            tpl = @tpl = jqueryify {$}, new Template schema:5, ->
                content = @$div class:'content'
                api.on('view', content.add)
                content.ready(next_step)

            next_step = ->
                setTimeout ->
                    api.emit 'view', t = new Template schema:5, ->
                        @$span ->
                            @$p "foo"
                    æ.equal "16#{tpl is t.xml?.parent?.builder?.template}",
                            "16true"
                , 16

            @results = [
                '<div class="content">'
                "<span><p>foo</p></span>"
                "</div>"
            ].join("")


        'to second level': (æ) ->
            @æ = æ ; { $, api } = this
            [footer, adds] = [null, {should:0, real:0}]
            tpl = @tpl = jqueryify {$}, new Template schema:5, ->
                api.on('view', @$div(class:'content').add)
                adds.should++
            tpl.on 'add', -> adds.real++

            setTimeout ->
                adds.should++
                api.emit 'view', footer = new Template schema:5, ->
                    api.on('footer', @$footer().add)
                    adds.should++
                æ.equal "8#{tpl is footer.xml?.parent?.builder?.template}",
                        "8true"
            , 8

            setTimeout ->
                adds.should++
                api.emit 'footer', t = new Template schema:5, ->
                    @$p ->
                        @text "foo"
                        @$span "lol"
                        adds.should += 2
                    @$p ->
                        @text "bar"
                        @$span "rofl"
                        adds.should += 2
                æ.equal "13#{footer is t.xml?.parent?.builder?.template}",
                        "13true"
            , 13

            setTimeout ->
                æ.equal adds.should, adds.real
            , 52

            @results = [
                '<div class="content">'
                "<footer>"
                "<p>foo<span>lol</span></p>"
                "<p>bar<span>rofl</span></p>"
                "</footer>"
                "</div>"
            ].join("")




    replace:
        setUp: (callback) ->
            @api = new EventEmitter
            @results = "no results"
            setTimeout =>
                @æ.equal @html(@tpl.jquery), @results
                @æ.done()
            , 100
            callback()


        instand: (æ) ->
            @æ = æ ; { $, api } = this
            tpl = @tpl = jqueryify {$}, new Template schema:5, ->
                @$div class:'content', ->
                    api.on('view', @$p("bla").replace)

            setTimeout ->
                api.emit 'view', t = new Template schema:5, ->
                    @$p ->
                        @text "foo"
                        @$b "bar"
                æ.equal "3#{tpl is t.xml?.parent?.builder?.template}",
                        "3true"
                t.ready ->
                    æ.equal "jqueryified:#{t.jquery? and 'yes' or 'no'}",
                            "jqueryified:yes"
            , 3

            @results = [
                '<div class="content">'
                "<p>foo<b>bar</b></p>"
                "</div>"
            ].join("")

        'after end': (æ) ->
            @æ = æ ; { $, api } = this
            p = null
            tpl = @tpl = jqueryify {$}, new Template schema:5, ->
                @$div class:'content', ->
                    p = @$p("bla")
                    api.on('view', p.replace)
                    p.ready(next_step)

            next_step = ->
                æ.equal "closed:#{p.closed and 'yes' or 'no'}",
                        "closed:yes"
                next_step.called = yes
                setTimeout ->
                    api.emit 'view', t = new Template schema:5, ->
                        @$p ->
                            @text "hack"
                            @$b "hack"
                    æ.equal "7#{tpl is t.xml?.parent?.builder?.template}",
                            "7true"
                    t.ready ->
                        æ.equal "jqueryified:#{t.jquery? and 'yes' or 'no'}",
                                "jqueryified:yes"
                , 7

            setTimeout ->
                æ.equal "called:#{next_step.called and 'yes' or 'no'}",
                        "called:yes"
            , 52

            @results = [
                '<div class="content">'
                "<p>hack<b>hack</b></p>"
                "</div>"
            ].join("")

