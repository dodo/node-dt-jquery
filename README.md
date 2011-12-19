# [Δt jquery adapter](http://dodo.github.com/node-dt-jquery/)

This is an jQuery adapter for [dynamictemplate](http://dodo.github.com/node-dynamictemplate/).
It listen on the template events and writes to the DOM.

→ [Check out the demo!](http://dodo.github.com/node-dynamictemplate/example/list.html)

## Installation

```bash
$ npm install dt-jquery
```

## Documentation

todo

### Adapters

dynamictemplate has a similar approach like [Backbone.js](http://documentcloud.github.com/backbone/) where you can choose your own backend of models, collections or, in this case, templates.

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
tpl.on('end', function () {
    $('.container').append(tpl.jquery);
});
```


