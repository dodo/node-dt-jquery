# [Δt jQuery Adapter](https://github.com/dodo/node-dt-jquery/)

This is an [jQuery](http://jquery.com/) Adapter for [Δt](http://dodo.github.com/node-dynamictemplate/).

It listen on the [template events](http://dodo.github.com/node-asyncxml/#section-4) and writes to the DOM.

The core logic is implemented in it's [module](http://github.com/dodo/node-dt-browser) to share it with other browser based adapters like [dt-DOM](http://dodo.github.com/node-dt-dom)

→ [Check out the demo!](http://dodo.github.com/node-dynamictemplate/example/backbone.html)

## Installation

```bash
$ npm install dt-jquery
```

## How this Adapter works:

```html
<script src="dt-jquery.browser.js"></script>
<scipt>
    var jqueryify = window.dynamictemplate.jqueryify; // get the jquery adapter
</script>
```

Just throw your template in and add it to the DOM when it's ready:

```javascript
var tpl = jquerify(template(mydata));
tpl.ready(function () {
    $('.container').append(tpl.jquery);
});
```

## Documentation

### jqueryify(tpl)

```javascript
tpl = jqueryify(new dynamictemplate.Template)
```
Expects a fresh [Δt](http://dodo.github.com/node-dynamictemplate/) [template instance](http://dodo.github.com/node-dynamictemplate/doc.html) (fresh means, instantiated in the same tick to prevent event loss).

It just simply listen for a bunch of events to use jQuery for DOM manipulation.

Uses [requestAnimationFrame](http://paulirish.com/2011/requestanimationframe-for-smart-animating/) for heavy DOM manipulation like node insertion and node deletion.

----

Overrides the `query` method of the [async XML Builder](http://dodo.github.com/node-asyncxml/#section-3-1).

For query type `text` it returns the result of [jQuery.text](http://api.jquery.com/text/).

For query type `attr` it returns the result of [jQuery.attr](http://api.jquery.com/attr/).

For query type `tag` it returns a dummy object that it will receive again on an `add` event.

[![Build Status](https://secure.travis-ci.org/dodo/node-dt-jquery.png)](http://travis-ci.org/dodo/node-dt-jquery)
