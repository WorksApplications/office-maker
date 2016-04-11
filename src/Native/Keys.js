Elm.Native.Keys = {};

Elm.Native.Keys.make = function(localRuntime) {
    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.Keys = localRuntime.Native.Keys || {};
    if (localRuntime.Native.Keys.values) return localRuntime.Native.Keys.values;

    var Signal = Elm.Native.Signal.make(localRuntime);

    function keyStream(node, eventName) {
  		var stream = Signal.input(eventName, { alt: false, meta: false, keyCode: 0 });
  		localRuntime.addListener([stream.id], node, eventName, function(e) {
  			localRuntime.notify(stream.id, e);
  		});
  		return stream;
  	}
    var downs = keyStream(document, 'keydown');

    return localRuntime.Native.Keys.values = {
        downs: downs,
    };
};
