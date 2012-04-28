
module.exports =

    add: (parent, el) ->
        $el = el._jquery
        $par = parent._jquery
        if parent is parent.builder
            i = $par.length - 1
            $par = $par.add($el)
            if parent._jquery_wrapped # FIXME
                $par.first().replaceWith($el)
                if parent.parent is parent.parent?.builder # FIXME recursive?
                    $parpar = parent.parent?._jquery
                    parent._jquery_wrapped = no
                    $par = $par.not(':first') # rm placeholder span
                    $parpar?.splice($parpar.index($par), i+1, $par...)
            else if $par.parent().length > 0
                $el.insertAfter($par[i])
        else
            $par.append($el)
        # $.add isnt inplace
        parent._jquery = $par

    replace: (oldtag, newtag) ->
        parent = newtag.parent
        $new = newtag._jquery
        $old = oldtag._jquery
        $par = parent._jquery

        if parent is parent.builder
            $par.splice($par.index($old), $old.length, $new...)

        if $old.parent().length > 0
            $old.replaceWith($new)
        # $.replaceWith isnt inplace
        newtag._jquery = $new

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

    remove: (el, opts) ->
        if opts.soft
            el._jquery.detach()
        else
            el._jquery.remove()
