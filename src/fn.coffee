{ defineJQueryAPI, removed, $fyBuilder } = require './util'

module.exports =

    add: (parent, el) ->
        $el = el._jquery ? el
        $par = parent._jquery ? parent
        if $el.length is 0
            el._jquery = $el = @$('<spaceholder>', $par)
            el._jquery_wrapped = yes
            if el is el.builder
                $fyBuilder(el) # includes defineJQueryAPI
            else
                defineJQueryAPI(el)
        if parent is parent.builder
            i = $par.length - 1
            $par = $par.add($el)
            if parent._jquery_wrapped
                $par.first().replaceWith($el)
                if parent.parent is parent.parent?.builder # FIXME recursive?
                    $parpar = parent.parent?._jquery ? parent.parent
                    parent._jquery_wrapped = no
                    $par = $par.not(':first') # rm placeholder span
                    $parpar.splice($parpar.index($par), i+1, $par...)
            else if $par.parent().length > 0
                $el.insertAfter($par[i])
        else
            $par.append($el)
        if parent._jquery_wrapped
            parent._jquery_wrapped = no
            $par = $par.not(':first') # rm placeholder span
        parent._jquery = $par
        $fyBuilder(parent) if parent is parent.builder

    replace: (oldtag, newtag) ->
        return if removed newtag
        parent = newtag.parent
        $new = newtag._jquery ? newtag
        $old = oldtag._jquery ? oldtag
        $par = parent._jquery ? parent

        if $new.length is 0
            newtag._jquery = $new = @$('<spaceholder>', $par)
            newtag._jquery_wrapped = yes
            defineJQueryAPI(newtag) unless newtag is newtag.builder

        if parent is parent.builder
            $par.splice($par.index($old), $old.length, $new...)
            $fyBuilder(parent)

        if $old.parent().length > 0
            $old.replaceWith($new)
        # replaceWith isnt inplace
        newtag._jquery = $new
        $fyBuilder(newtag) if newtag is newtag.builder

    text: (el, text) ->
        el._jquery.text(text)

    raw: (el, html) ->
        el._jquery.html(html)

    attr: (el, key, value) ->
        if value is undefined
            el._jquery.removeAttr(key)
        else
            el._jquery.attr(key, value)

    show: (el) ->
        el._jquery.show()

    hide: (el) ->
        el._jquery.hide()

    remove: (el) ->
        el._jquery.remove()
