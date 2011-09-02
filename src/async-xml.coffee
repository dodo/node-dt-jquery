{ EventEmitter } = require 'events'

# helper

indent = ({level, opts:{pretty}}) ->
    return "" unless pretty
    pretty = "  " if pretty is on
    output = ""
    for i in [0...level]
        output += pretty
    return output


new_attrs = (attrs) ->
    strattrs = for k, v of attrs
        if v?
            v = "\"#{v}\"" unless typeof v is 'number'
            "#{k}=#{v}"
        else "#{k}"
    strattrs.unshift '' if strattrs.length
    strattrs.join ' '

# main logic

new_tag = (name, opts) ->
    buffer = []
    @pending.push tag = new Tag name, opts
    tag.self.on 'data', pipe = (data) =>
        if @pending[0] is tag
            @emit 'data', data
        else
            buffer.push data

    tag.self.on 'end', on_end = (data) =>
        buffer.push data unless data is undefined
        if @pending[0] is tag
            if tag.self.pending.length
                (pender = tag.self.pending[0].self).once 'end', =>
                    on_end()
                    @emit 'end' unless @pending.length
            else
                if tag.self.buffer.length
                    buffer = buffer.concat tag.self.buffer
                    tag.self.buffer = []
                @pending = @pending.slice(1)
                tag.self.removeListener 'data', pipe
                tag.self.removeListener 'end', on_end
                for data in buffer
                    @emit 'data', data
        else
            for known, i in @pending
                if tag is known
                    @pending = @pending.slice(0,i).concat @pending.slice i+1
                    before = @pending[i-1].self
                    before.buffer = before.buffer.concat buffer
                    tag.self.removeListener 'data', pipe
                    tag.self.removeListener 'end', on_end
                    return
            throw new Error("this shouldn't happen D:")
    return tag

# classes

class Tag extends EventEmitter
    constructor: (@name, {@level, @opts}) ->
        @buffer = [] # after this tag all children emitted data
        @pending = [] # no open child tag
        @attrs.self = this
        @attrs.end = (attrs) => @attrs(attrs).end()
        return @attrs

    attrs: (attrs = {}) =>
        @headers = "<#{@name}#{new_attrs attrs}"
        return this

    tag: (name) =>
        if @headers
            @emit 'data', "#{indent this}#{@headers}>"
            delete @headers
        new_tag.call this, name, opts:@opts, level:@level+1


    end: () =>
        if @headers
            data = "#{indent this}#{@headers}/>"
        else
            data = "#{indent this}</#{@name}>"
        @emit 'end', data


class Builder extends EventEmitter
    constructor: (@opts = {}) ->
        @buffer = [] # for child output
        @pending = [] # no open child tag
        @opts.pretty ?= off
        @level = @opts.level ? 0

    tag: (name) =>
        new_tag.call this, name, opts:@opts, level:@level

    end: () =>
        @emit 'end' unless @pending.length


# exports

module.exports = { Tag, Builder }

