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
                @æ.equal @html(@tpl.jquery), @results.join("")
                @æ.done()
            , 100
            callback()


        simple: (æ) ->
            @æ = æ ; { $, api } = this
            tpl = @tpl = jqueryify {$}, new Template schema:5, ->
                api.on('view', @$div(class:'content').add)

            setTimeout =>
                api.emit 'view', t = new Template schema:5, ->
                    @$footer ->
                        @$p "bar"
                process.nextTick ->
                    æ.equal 1, t.jquery.length
                    æ.equal 0, t.jquery.filter('spaceholder').length
                æ.equal "42#{tpl is t.xml?.parent?.builder?.template}",
                        "42true"
                t.ready =>
                    æ.equal @html(t.jquery), [
                        "<footer></footer>"
                    ].join("")
            , 42

            setTimeout =>
                api.emit 'view', t = new Template schema:5, ->
                    @$span ->
                        @$p "foo"
                process.nextTick ->
                    æ.equal 1, t.jquery.length
                    æ.equal 0, t.jquery.filter('spaceholder').length
                æ.equal "23#{tpl is t.xml?.parent?.builder?.template}",
                        "23true"
                t.ready =>
                    æ.equal @html(t.jquery), [
                        "<span></span>"
                    ].join("")
            , 23

            @results = [
                '<div class="content">'
                "<span><p>foo</p></span>"
                "<footer><p>bar</p></footer>"
                "</div>"
            ]


        'after end': (æ) ->
            @æ = æ ; { $, api } = this
            tpl = @tpl = jqueryify {$}, new Template schema:5, ->
                content = @$div class:'content'
                api.on('view', content.add)
                content.ready(next_step)

            next_step = =>
                setTimeout =>
                    api.emit 'view', t = new Template schema:5, ->
                        @$span ->
                            @$p "foo"
                    process.nextTick ->
                        æ.equal 1, t.jquery.length
                        æ.equal 0, t.jquery.filter('spaceholder').length
                    æ.equal "16#{tpl is t.xml?.parent?.builder?.template}",
                            "16true"
                    t.ready =>
                        æ.equal @html(t.jquery), [
                            "<span></span>"
                        ].join("")
                , 16

            @results = [
                '<div class="content">'
                "<span><p>foo</p></span>"
                "</div>"
            ]


        'template into template': (æ) ->
            @æ = æ ; { $, api } = this
            tpl = @tpl = jqueryify {$}, new Template schema:5, ->
                api.on('view', @add)

            setTimeout =>
                api.emit 'view', t = new Template schema:5, ->
                    @$span ->
                        @$p "foo"
                process.nextTick ->
                    æ.equal 1, t.jquery.length
                    æ.equal 0, t.jquery.filter('spaceholder').length
                æ.equal "9#{tpl is t.xml?.parent?.builder?.template}",
                        "9true"
                t.ready =>
                    æ.equal @html(t.jquery), [
                        "<span></span>"
                    ].join("")
            , 9

            @results = [
                "<span><p>foo</p></span>"
            ]


        'to second level': (æ) ->
            @æ = æ ; { $, api } = this
            [footer, adds] = [null, {should:0, real:0}]
            tpl = @tpl = jqueryify {$}, new Template schema:5, ->
                api.on('view', @$div(class:'content').add)
                adds.should++
            tpl.on 'add', -> adds.real++

            setTimeout =>
                adds.should++
                api.emit 'view', footer = t = new Template schema:5, ->
                    api.on('footer', @$footer().add)
                    adds.should++
                process.nextTick ->
                    æ.equal 1, t.jquery.length
                    æ.equal 0, t.jquery.filter('spaceholder').length
                æ.equal "8#{tpl is t.xml?.parent?.builder?.template}",
                        "8true"
                t.ready =>
                    æ.equal @html(t.jquery), [
                        "<footer></footer>"
                    ].join("")
            , 8

            setTimeout =>
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
                process.nextTick ->
                    æ.equal 2, t.jquery.length
                    æ.equal 0, t.jquery.filter('spaceholder').length
                æ.equal "13#{footer is t.xml?.parent?.builder?.template}",
                        "13true"
                t.ready =>
                    æ.equal @html(t.jquery), [
                        "<p></p>"
                        "<p></p>"
                    ].join("")
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
            ]



    replace:
        setUp: (callback) ->
            @api = new EventEmitter
            @results = "no results"
            setTimeout =>
                @æ.equal @html(@tpl.jquery), @results.join("")
                @æ.done()
            , 100
            callback()


        instand: (æ) ->
            @æ = æ ; { $, api } = this
            tpl = @tpl = jqueryify {$}, new Template schema:5, ->
                @$div class:'content', ->
                    api.on('view', @$p("bla").replace)

            setTimeout =>
                api.emit 'view', t = new Template schema:5, ->
                    @$p ->
                        @text "foo"
                        @$b "bar"
                process.nextTick ->
                    æ.equal 1, t.jquery.length
                    æ.equal 0, t.jquery.filter('spaceholder').length
                æ.equal "3#{tpl is t.xml?.parent?.builder?.template}",
                        "3true"
                t.ready =>
                    æ.equal "jqueryified:#{t.jquery? and 'yes' or 'no'}",
                            "jqueryified:yes"
                    æ.equal @html(t.jquery), [
                        "<p></p>"
                    ].join("")
            , 3

            @results = [
                '<div class="content">'
                "<p>foo<b>bar</b></p>"
                "</div>"
            ]


        'after end': (æ) ->
            @æ = æ ; { $, api } = this
            [p, adds, replaces] = [null, {should:0, real:0}, {should:0, real:0}]
            tpl = @tpl = jqueryify {$}, new Template schema:5, ->
                @$div class:'content', ->
                    p = @$p("bla")
                    api.on('view', p.replace)
                    p.ready(next_step)
                adds.should += 2
            tpl.on 'replace', ->
                replaces.real++
            tpl.on 'add', ->
                adds.real++

            next_step = =>
                æ.equal "closed:#{p.closed and 'yes' or 'no'}",
                        "closed:yes"
                æ.equal @html(tpl.jquery), [
                    '<div class="content">'
                    "<p>bla</p>"
                    "</div>"
                ].join("")

                next_step.called = yes
                setTimeout =>
                    api.emit 'view', t = new Template schema:5, ->
                        replaces.should++
                        @$p ->
                            @text "hack"
                            @$b "hack"
                        adds.should += 2
                    process.nextTick ->
                        æ.equal 1, t.jquery.length
                        æ.equal 0, t.jquery.filter('spaceholder').length
                    æ.equal "7#{tpl is t.xml?.parent?.builder?.template}",
                            "7true"
                    t.ready =>
                        æ.equal "jqueryified:#{t.jquery? and 'yes' or 'no'}",
                                "jqueryified:yes"
                        æ.equal @html(t.jquery), [
                            "<p></p>"
                        ].join("")
                , 7

            setTimeout ->
                æ.equal adds.should, adds.real
                æ.equal replaces.should, replaces.real
                æ.equal "called:#{next_step.called and 'yes' or 'no'}",
                        "called:yes"
            , 52

            @results = [
                '<div class="content">'
                "<p>hack<b>hack</b></p>"
                "</div>"
            ]

