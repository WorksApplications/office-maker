var Elm = Elm || { Native: {} };
Elm.Native.Basics = {};
Elm.Native.Basics.make = function(localRuntime) {
	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Basics = localRuntime.Native.Basics || {};
	if (localRuntime.Native.Basics.values)
	{
		return localRuntime.Native.Basics.values;
	}

	var Utils = Elm.Native.Utils.make(localRuntime);

	function div(a, b)
	{
		return (a / b) | 0;
	}
	function rem(a, b)
	{
		return a % b;
	}
	function mod(a, b)
	{
		if (b === 0)
		{
			throw new Error('Cannot perform mod 0. Division by zero error.');
		}
		var r = a % b;
		var m = a === 0 ? 0 : (b > 0 ? (a >= 0 ? r : r + b) : -mod(-a, -b));

		return m === b ? 0 : m;
	}
	function logBase(base, n)
	{
		return Math.log(n) / Math.log(base);
	}
	function negate(n)
	{
		return -n;
	}
	function abs(n)
	{
		return n < 0 ? -n : n;
	}

	function min(a, b)
	{
		return Utils.cmp(a, b) < 0 ? a : b;
	}
	function max(a, b)
	{
		return Utils.cmp(a, b) > 0 ? a : b;
	}
	function clamp(lo, hi, n)
	{
		return Utils.cmp(n, lo) < 0 ? lo : Utils.cmp(n, hi) > 0 ? hi : n;
	}

	function xor(a, b)
	{
		return a !== b;
	}
	function not(b)
	{
		return !b;
	}
	function isInfinite(n)
	{
		return n === Infinity || n === -Infinity;
	}

	function truncate(n)
	{
		return n | 0;
	}

	function degrees(d)
	{
		return d * Math.PI / 180;
	}
	function turns(t)
	{
		return 2 * Math.PI * t;
	}
	function fromPolar(point)
	{
		var r = point._0;
		var t = point._1;
		return Utils.Tuple2(r * Math.cos(t), r * Math.sin(t));
	}
	function toPolar(point)
	{
		var x = point._0;
		var y = point._1;
		return Utils.Tuple2(Math.sqrt(x * x + y * y), Math.atan2(y, x));
	}

	return localRuntime.Native.Basics.values = {
		div: F2(div),
		rem: F2(rem),
		mod: F2(mod),

		pi: Math.PI,
		e: Math.E,
		cos: Math.cos,
		sin: Math.sin,
		tan: Math.tan,
		acos: Math.acos,
		asin: Math.asin,
		atan: Math.atan,
		atan2: F2(Math.atan2),

		degrees: degrees,
		turns: turns,
		fromPolar: fromPolar,
		toPolar: toPolar,

		sqrt: Math.sqrt,
		logBase: F2(logBase),
		negate: negate,
		abs: abs,
		min: F2(min),
		max: F2(max),
		clamp: F3(clamp),
		compare: Utils.compare,

		xor: F2(xor),
		not: not,

		truncate: truncate,
		ceiling: Math.ceil,
		floor: Math.floor,
		round: Math.round,
		toFloat: function(x) { return x; },
		isNaN: isNaN,
		isInfinite: isInfinite
	};
};

Elm.Native.Port = {};

Elm.Native.Port.make = function(localRuntime) {
	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Port = localRuntime.Native.Port || {};
	if (localRuntime.Native.Port.values)
	{
		return localRuntime.Native.Port.values;
	}

	var NS;

	// INBOUND

	function inbound(name, type, converter)
	{
		if (!localRuntime.argsTracker[name])
		{
			throw new Error(
				'Port Error:\n' +
				'No argument was given for the port named \'' + name + '\' with type:\n\n' +
				'    ' + type.split('\n').join('\n        ') + '\n\n' +
				'You need to provide an initial value!\n\n' +
				'Find out more about ports here <http://elm-lang.org/learn/Ports.elm>'
			);
		}
		var arg = localRuntime.argsTracker[name];
		arg.used = true;

		return jsToElm(name, type, converter, arg.value);
	}


	function inboundSignal(name, type, converter)
	{
		var initialValue = inbound(name, type, converter);

		if (!NS)
		{
			NS = Elm.Native.Signal.make(localRuntime);
		}
		var signal = NS.input('inbound-port-' + name, initialValue);

		function send(jsValue)
		{
			var elmValue = jsToElm(name, type, converter, jsValue);
			setTimeout(function() {
				localRuntime.notify(signal.id, elmValue);
			}, 0);
		}

		localRuntime.ports[name] = { send: send };

		return signal;
	}


	function jsToElm(name, type, converter, value)
	{
		try
		{
			return converter(value);
		}
		catch(e)
		{
			throw new Error(
				'Port Error:\n' +
				'Regarding the port named \'' + name + '\' with type:\n\n' +
				'    ' + type.split('\n').join('\n        ') + '\n\n' +
				'You just sent the value:\n\n' +
				'    ' + JSON.stringify(value) + '\n\n' +
				'but it cannot be converted to the necessary type.\n' +
				e.message
			);
		}
	}


	// OUTBOUND

	function outbound(name, converter, elmValue)
	{
		localRuntime.ports[name] = converter(elmValue);
	}


	function outboundSignal(name, converter, signal)
	{
		var subscribers = [];

		function subscribe(handler)
		{
			subscribers.push(handler);
		}
		function unsubscribe(handler)
		{
			subscribers.pop(subscribers.indexOf(handler));
		}

		function notify(elmValue)
		{
			var jsValue = converter(elmValue);
			var len = subscribers.length;
			for (var i = 0; i < len; ++i)
			{
				subscribers[i](jsValue);
			}
		}

		if (!NS)
		{
			NS = Elm.Native.Signal.make(localRuntime);
		}
		NS.output('outbound-port-' + name, notify, signal);

		localRuntime.ports[name] = {
			subscribe: subscribe,
			unsubscribe: unsubscribe
		};

		return signal;
	}


	return localRuntime.Native.Port.values = {
		inbound: inbound,
		outbound: outbound,
		inboundSignal: inboundSignal,
		outboundSignal: outboundSignal
	};
};

if (!Elm.fullscreen) {
	(function() {
		'use strict';

		var Display = {
			FULLSCREEN: 0,
			COMPONENT: 1,
			NONE: 2
		};

		Elm.fullscreen = function(module, args)
		{
			var container = document.createElement('div');
			document.body.appendChild(container);
			return init(Display.FULLSCREEN, container, module, args || {});
		};

		Elm.embed = function(module, container, args)
		{
			var tag = container.tagName;
			if (tag !== 'DIV')
			{
				throw new Error('Elm.node must be given a DIV, not a ' + tag + '.');
			}
			return init(Display.COMPONENT, container, module, args || {});
		};

		Elm.worker = function(module, args)
		{
			return init(Display.NONE, {}, module, args || {});
		};

		function init(display, container, module, args, moduleToReplace)
		{
			// defining state needed for an instance of the Elm RTS
			var inputs = [];

			/* OFFSET
			 * Elm's time traveling debugger lets you pause time. This means
			 * "now" may be shifted a bit into the past. By wrapping Date.now()
			 * we can manage this.
			 */
			var timer = {
				programStart: Date.now(),
				now: function()
				{
					return Date.now();
				}
			};

			var updateInProgress = false;
			function notify(id, v)
			{
				if (updateInProgress)
				{
					throw new Error(
						'The notify function has been called synchronously!\n' +
						'This can lead to frames being dropped.\n' +
						'Definitely report this to <https://github.com/elm-lang/Elm/issues>\n');
				}
				updateInProgress = true;
				var timestep = timer.now();
				for (var i = inputs.length; i--; )
				{
					inputs[i].notify(timestep, id, v);
				}
				updateInProgress = false;
			}
			function setTimeout(func, delay)
			{
				return window.setTimeout(func, delay);
			}

			var listeners = [];
			function addListener(relevantInputs, domNode, eventName, func)
			{
				domNode.addEventListener(eventName, func);
				var listener = {
					relevantInputs: relevantInputs,
					domNode: domNode,
					eventName: eventName,
					func: func
				};
				listeners.push(listener);
			}

			var argsTracker = {};
			for (var name in args)
			{
				argsTracker[name] = {
					value: args[name],
					used: false
				};
			}

			// create the actual RTS. Any impure modules will attach themselves to this
			// object. This permits many Elm programs to be embedded per document.
			var elm = {
				notify: notify,
				setTimeout: setTimeout,
				node: container,
				addListener: addListener,
				inputs: inputs,
				timer: timer,
				argsTracker: argsTracker,
				ports: {},

				isFullscreen: function() { return display === Display.FULLSCREEN; },
				isEmbed: function() { return display === Display.COMPONENT; },
				isWorker: function() { return display === Display.NONE; }
			};

			function swap(newModule)
			{
				removeListeners(listeners);
				var div = document.createElement('div');
				var newElm = init(display, div, newModule, args, elm);
				inputs = [];

				return newElm;
			}

			function dispose()
			{
				removeListeners(listeners);
				inputs = [];
			}

			var Module = {};
			try
			{
				Module = module.make(elm);
				checkInputs(elm);
			}
			catch (error)
			{
				if (typeof container.appendChild === "function")
				{
					container.appendChild(errorNode(error.message));
				}
				else
				{
					console.error(error.message);
				}
				throw error;
			}

			if (display !== Display.NONE)
			{
				var graphicsNode = initGraphics(elm, Module);
			}

			var rootNode = { kids: inputs };
			trimDeadNodes(rootNode);
			inputs = rootNode.kids;
			filterListeners(inputs, listeners);

			addReceivers(elm.ports);

			if (typeof moduleToReplace !== 'undefined')
			{
				hotSwap(moduleToReplace, elm);

				// rerender scene if graphics are enabled.
				if (typeof graphicsNode !== 'undefined')
				{
					graphicsNode.notify(0, true, 0);
				}
			}

			return {
				swap: swap,
				ports: elm.ports,
				dispose: dispose
			};
		}

		function checkInputs(elm)
		{
			var argsTracker = elm.argsTracker;
			for (var name in argsTracker)
			{
				if (!argsTracker[name].used)
				{
					throw new Error(
						"Port Error:\nYou provided an argument named '" + name +
						"' but there is no corresponding port!\n\n" +
						"Maybe add a port '" + name + "' to your Elm module?\n" +
						"Maybe remove the '" + name + "' argument from your initialization code in JS?"
					);
				}
			}
		}

		function errorNode(message)
		{
			var code = document.createElement('code');

			var lines = message.split('\n');
			code.appendChild(document.createTextNode(lines[0]));
			code.appendChild(document.createElement('br'));
			code.appendChild(document.createElement('br'));
			for (var i = 1; i < lines.length; ++i)
			{
				code.appendChild(document.createTextNode('\u00A0 \u00A0 ' + lines[i].replace(/  /g, '\u00A0 ')));
				code.appendChild(document.createElement('br'));
			}
			code.appendChild(document.createElement('br'));
			code.appendChild(document.createTextNode('Open the developer console for more details.'));
			return code;
		}


		//// FILTER SIGNALS ////

		// TODO: move this code into the signal module and create a function
		// Signal.initializeGraph that actually instantiates everything.

		function filterListeners(inputs, listeners)
		{
			loop:
			for (var i = listeners.length; i--; )
			{
				var listener = listeners[i];
				for (var j = inputs.length; j--; )
				{
					if (listener.relevantInputs.indexOf(inputs[j].id) >= 0)
					{
						continue loop;
					}
				}
				listener.domNode.removeEventListener(listener.eventName, listener.func);
			}
		}

		function removeListeners(listeners)
		{
			for (var i = listeners.length; i--; )
			{
				var listener = listeners[i];
				listener.domNode.removeEventListener(listener.eventName, listener.func);
			}
		}

		// add receivers for built-in ports if they are defined
		function addReceivers(ports)
		{
			if ('title' in ports)
			{
				if (typeof ports.title === 'string')
				{
					document.title = ports.title;
				}
				else
				{
					ports.title.subscribe(function(v) { document.title = v; });
				}
			}
			if ('redirect' in ports)
			{
				ports.redirect.subscribe(function(v) {
					if (v.length > 0)
					{
						window.location = v;
					}
				});
			}
		}


		// returns a boolean representing whether the node is alive or not.
		function trimDeadNodes(node)
		{
			if (node.isOutput)
			{
				return true;
			}

			var liveKids = [];
			for (var i = node.kids.length; i--; )
			{
				var kid = node.kids[i];
				if (trimDeadNodes(kid))
				{
					liveKids.push(kid);
				}
			}
			node.kids = liveKids;

			return liveKids.length > 0;
		}


		////  RENDERING  ////

		function initGraphics(elm, Module)
		{
			if (!('main' in Module))
			{
				throw new Error("'main' is missing! What do I display?!");
			}

			var signalGraph = Module.main;

			// make sure the signal graph is actually a signal & extract the visual model
			if (!('notify' in signalGraph))
			{
				signalGraph = Elm.Signal.make(elm).constant(signalGraph);
			}
			var initialScene = signalGraph.value;

			// Figure out what the render functions should be
			var render;
			var update;
			if (initialScene.ctor === 'Element_elm_builtin')
			{
				var Element = Elm.Native.Graphics.Element.make(elm);
				render = Element.render;
				update = Element.updateAndReplace;
			}
			else
			{
				var VirtualDom = Elm.Native.VirtualDom.make(elm);
				render = VirtualDom.render;
				update = VirtualDom.updateAndReplace;
			}

			// Add the initialScene to the DOM
			var container = elm.node;
			var node = render(initialScene);
			while (container.firstChild)
			{
				container.removeChild(container.firstChild);
			}
			container.appendChild(node);

			var _requestAnimationFrame =
				typeof requestAnimationFrame !== 'undefined'
					? requestAnimationFrame
					: function(cb) { setTimeout(cb, 1000 / 60); }
					;

			// domUpdate is called whenever the main Signal changes.
			//
			// domUpdate and drawCallback implement a small state machine in order
			// to schedule only 1 draw per animation frame. This enforces that
			// once draw has been called, it will not be called again until the
			// next frame.
			//
			// drawCallback is scheduled whenever
			// 1. The state transitions from PENDING_REQUEST to EXTRA_REQUEST, or
			// 2. The state transitions from NO_REQUEST to PENDING_REQUEST
			//
			// Invariants:
			// 1. In the NO_REQUEST state, there is never a scheduled drawCallback.
			// 2. In the PENDING_REQUEST and EXTRA_REQUEST states, there is always exactly 1
			//    scheduled drawCallback.
			var NO_REQUEST = 0;
			var PENDING_REQUEST = 1;
			var EXTRA_REQUEST = 2;
			var state = NO_REQUEST;
			var savedScene = initialScene;
			var scheduledScene = initialScene;

			function domUpdate(newScene)
			{
				scheduledScene = newScene;

				switch (state)
				{
					case NO_REQUEST:
						_requestAnimationFrame(drawCallback);
						state = PENDING_REQUEST;
						return;
					case PENDING_REQUEST:
						state = PENDING_REQUEST;
						return;
					case EXTRA_REQUEST:
						state = PENDING_REQUEST;
						return;
				}
			}

			function drawCallback()
			{
				switch (state)
				{
					case NO_REQUEST:
						// This state should not be possible. How can there be no
						// request, yet somehow we are actively fulfilling a
						// request?
						throw new Error(
							'Unexpected draw callback.\n' +
							'Please report this to <https://github.com/elm-lang/core/issues>.'
						);

					case PENDING_REQUEST:
						// At this point, we do not *know* that another frame is
						// needed, but we make an extra request to rAF just in
						// case. It's possible to drop a frame if rAF is called
						// too late, so we just do it preemptively.
						_requestAnimationFrame(drawCallback);
						state = EXTRA_REQUEST;

						// There's also stuff we definitely need to draw.
						draw();
						return;

					case EXTRA_REQUEST:
						// Turns out the extra request was not needed, so we will
						// stop calling rAF. No reason to call it all the time if
						// no one needs it.
						state = NO_REQUEST;
						return;
				}
			}

			function draw()
			{
				update(elm.node.firstChild, savedScene, scheduledScene);
				if (elm.Native.Window)
				{
					elm.Native.Window.values.resizeIfNeeded();
				}
				savedScene = scheduledScene;
			}

			var renderer = Elm.Native.Signal.make(elm).output('main', domUpdate, signalGraph);

			// must check for resize after 'renderer' is created so
			// that changes show up.
			if (elm.Native.Window)
			{
				elm.Native.Window.values.resizeIfNeeded();
			}

			return renderer;
		}

		//// HOT SWAPPING ////

		// Returns boolean indicating if the swap was successful.
		// Requires that the two signal graphs have exactly the same
		// structure.
		function hotSwap(from, to)
		{
			function similar(nodeOld, nodeNew)
			{
				if (nodeOld.id !== nodeNew.id)
				{
					return false;
				}
				if (nodeOld.isOutput)
				{
					return nodeNew.isOutput;
				}
				return nodeOld.kids.length === nodeNew.kids.length;
			}
			function swap(nodeOld, nodeNew)
			{
				nodeNew.value = nodeOld.value;
				return true;
			}
			var canSwap = depthFirstTraversals(similar, from.inputs, to.inputs);
			if (canSwap)
			{
				depthFirstTraversals(swap, from.inputs, to.inputs);
			}
			from.node.parentNode.replaceChild(to.node, from.node);

			return canSwap;
		}

		// Returns false if the node operation f ever fails.
		function depthFirstTraversals(f, queueOld, queueNew)
		{
			if (queueOld.length !== queueNew.length)
			{
				return false;
			}
			queueOld = queueOld.slice(0);
			queueNew = queueNew.slice(0);

			var seen = [];
			while (queueOld.length > 0 && queueNew.length > 0)
			{
				var nodeOld = queueOld.pop();
				var nodeNew = queueNew.pop();
				if (seen.indexOf(nodeOld.id) < 0)
				{
					if (!f(nodeOld, nodeNew))
					{
						return false;
					}
					queueOld = queueOld.concat(nodeOld.kids || []);
					queueNew = queueNew.concat(nodeNew.kids || []);
					seen.push(nodeOld.id);
				}
			}
			return true;
		}
	}());

	function F2(fun)
	{
		function wrapper(a) { return function(b) { return fun(a,b); }; }
		wrapper.arity = 2;
		wrapper.func = fun;
		return wrapper;
	}

	function F3(fun)
	{
		function wrapper(a) {
			return function(b) { return function(c) { return fun(a, b, c); }; };
		}
		wrapper.arity = 3;
		wrapper.func = fun;
		return wrapper;
	}

	function F4(fun)
	{
		function wrapper(a) { return function(b) { return function(c) {
			return function(d) { return fun(a, b, c, d); }; }; };
		}
		wrapper.arity = 4;
		wrapper.func = fun;
		return wrapper;
	}

	function F5(fun)
	{
		function wrapper(a) { return function(b) { return function(c) {
			return function(d) { return function(e) { return fun(a, b, c, d, e); }; }; }; };
		}
		wrapper.arity = 5;
		wrapper.func = fun;
		return wrapper;
	}

	function F6(fun)
	{
		function wrapper(a) { return function(b) { return function(c) {
			return function(d) { return function(e) { return function(f) {
			return fun(a, b, c, d, e, f); }; }; }; }; };
		}
		wrapper.arity = 6;
		wrapper.func = fun;
		return wrapper;
	}

	function F7(fun)
	{
		function wrapper(a) { return function(b) { return function(c) {
			return function(d) { return function(e) { return function(f) {
			return function(g) { return fun(a, b, c, d, e, f, g); }; }; }; }; }; };
		}
		wrapper.arity = 7;
		wrapper.func = fun;
		return wrapper;
	}

	function F8(fun)
	{
		function wrapper(a) { return function(b) { return function(c) {
			return function(d) { return function(e) { return function(f) {
			return function(g) { return function(h) {
			return fun(a, b, c, d, e, f, g, h); }; }; }; }; }; }; };
		}
		wrapper.arity = 8;
		wrapper.func = fun;
		return wrapper;
	}

	function F9(fun)
	{
		function wrapper(a) { return function(b) { return function(c) {
			return function(d) { return function(e) { return function(f) {
			return function(g) { return function(h) { return function(i) {
			return fun(a, b, c, d, e, f, g, h, i); }; }; }; }; }; }; }; };
		}
		wrapper.arity = 9;
		wrapper.func = fun;
		return wrapper;
	}

	function A2(fun, a, b)
	{
		return fun.arity === 2
			? fun.func(a, b)
			: fun(a)(b);
	}
	function A3(fun, a, b, c)
	{
		return fun.arity === 3
			? fun.func(a, b, c)
			: fun(a)(b)(c);
	}
	function A4(fun, a, b, c, d)
	{
		return fun.arity === 4
			? fun.func(a, b, c, d)
			: fun(a)(b)(c)(d);
	}
	function A5(fun, a, b, c, d, e)
	{
		return fun.arity === 5
			? fun.func(a, b, c, d, e)
			: fun(a)(b)(c)(d)(e);
	}
	function A6(fun, a, b, c, d, e, f)
	{
		return fun.arity === 6
			? fun.func(a, b, c, d, e, f)
			: fun(a)(b)(c)(d)(e)(f);
	}
	function A7(fun, a, b, c, d, e, f, g)
	{
		return fun.arity === 7
			? fun.func(a, b, c, d, e, f, g)
			: fun(a)(b)(c)(d)(e)(f)(g);
	}
	function A8(fun, a, b, c, d, e, f, g, h)
	{
		return fun.arity === 8
			? fun.func(a, b, c, d, e, f, g, h)
			: fun(a)(b)(c)(d)(e)(f)(g)(h);
	}
	function A9(fun, a, b, c, d, e, f, g, h, i)
	{
		return fun.arity === 9
			? fun.func(a, b, c, d, e, f, g, h, i)
			: fun(a)(b)(c)(d)(e)(f)(g)(h)(i);
	}
}

Elm.Native = Elm.Native || {};
Elm.Native.Utils = {};
Elm.Native.Utils.make = function(localRuntime) {
	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Utils = localRuntime.Native.Utils || {};
	if (localRuntime.Native.Utils.values)
	{
		return localRuntime.Native.Utils.values;
	}


	// COMPARISONS

	function eq(l, r)
	{
		var stack = [{'x': l, 'y': r}];
		while (stack.length > 0)
		{
			var front = stack.pop();
			var x = front.x;
			var y = front.y;
			if (x === y)
			{
				continue;
			}
			if (typeof x === 'object')
			{
				var c = 0;
				for (var i in x)
				{
					++c;
					if (i in y)
					{
						if (i !== 'ctor')
						{
							stack.push({ 'x': x[i], 'y': y[i] });
						}
					}
					else
					{
						return false;
					}
				}
				if ('ctor' in x)
				{
					stack.push({'x': x.ctor, 'y': y.ctor});
				}
				if (c !== Object.keys(y).length)
				{
					return false;
				}
			}
			else if (typeof x === 'function')
			{
				throw new Error('Equality error: general function equality is ' +
								'undecidable, and therefore, unsupported');
			}
			else
			{
				return false;
			}
		}
		return true;
	}

	// code in Generate/JavaScript.hs depends on the particular
	// integer values assigned to LT, EQ, and GT
	var LT = -1, EQ = 0, GT = 1, ord = ['LT', 'EQ', 'GT'];

	function compare(x, y)
	{
		return {
			ctor: ord[cmp(x, y) + 1]
		};
	}

	function cmp(x, y) {
		var ord;
		if (typeof x !== 'object')
		{
			return x === y ? EQ : x < y ? LT : GT;
		}
		else if (x.isChar)
		{
			var a = x.toString();
			var b = y.toString();
			return a === b
				? EQ
				: a < b
					? LT
					: GT;
		}
		else if (x.ctor === '::' || x.ctor === '[]')
		{
			while (true)
			{
				if (x.ctor === '[]' && y.ctor === '[]')
				{
					return EQ;
				}
				if (x.ctor !== y.ctor)
				{
					return x.ctor === '[]' ? LT : GT;
				}
				ord = cmp(x._0, y._0);
				if (ord !== EQ)
				{
					return ord;
				}
				x = x._1;
				y = y._1;
			}
		}
		else if (x.ctor.slice(0, 6) === '_Tuple')
		{
			var n = x.ctor.slice(6) - 0;
			var err = 'cannot compare tuples with more than 6 elements.';
			if (n === 0) return EQ;
			if (n >= 1) { ord = cmp(x._0, y._0); if (ord !== EQ) return ord;
			if (n >= 2) { ord = cmp(x._1, y._1); if (ord !== EQ) return ord;
			if (n >= 3) { ord = cmp(x._2, y._2); if (ord !== EQ) return ord;
			if (n >= 4) { ord = cmp(x._3, y._3); if (ord !== EQ) return ord;
			if (n >= 5) { ord = cmp(x._4, y._4); if (ord !== EQ) return ord;
			if (n >= 6) { ord = cmp(x._5, y._5); if (ord !== EQ) return ord;
			if (n >= 7) throw new Error('Comparison error: ' + err); } } } } } }
			return EQ;
		}
		else
		{
			throw new Error('Comparison error: comparison is only defined on ints, ' +
							'floats, times, chars, strings, lists of comparable values, ' +
							'and tuples of comparable values.');
		}
	}


	// TUPLES

	var Tuple0 = {
		ctor: '_Tuple0'
	};

	function Tuple2(x, y)
	{
		return {
			ctor: '_Tuple2',
			_0: x,
			_1: y
		};
	}


	// LITERALS

	function chr(c)
	{
		var x = new String(c);
		x.isChar = true;
		return x;
	}

	function txt(str)
	{
		var t = new String(str);
		t.text = true;
		return t;
	}


	// GUID

	var count = 0;
	function guid(_)
	{
		return count++;
	}


	// RECORDS

	function update(oldRecord, updatedFields)
	{
		var newRecord = {};
		for (var key in oldRecord)
		{
			var value = (key in updatedFields) ? updatedFields[key] : oldRecord[key];
			newRecord[key] = value;
		}
		return newRecord;
	}


	// MOUSE COORDINATES

	function getXY(e)
	{
		var posx = 0;
		var posy = 0;
		if (e.pageX || e.pageY)
		{
			posx = e.pageX;
			posy = e.pageY;
		}
		else if (e.clientX || e.clientY)
		{
			posx = e.clientX + document.body.scrollLeft + document.documentElement.scrollLeft;
			posy = e.clientY + document.body.scrollTop + document.documentElement.scrollTop;
		}

		if (localRuntime.isEmbed())
		{
			var rect = localRuntime.node.getBoundingClientRect();
			var relx = rect.left + document.body.scrollLeft + document.documentElement.scrollLeft;
			var rely = rect.top + document.body.scrollTop + document.documentElement.scrollTop;
			// TODO: figure out if there is a way to avoid rounding here
			posx = posx - Math.round(relx) - localRuntime.node.clientLeft;
			posy = posy - Math.round(rely) - localRuntime.node.clientTop;
		}
		return Tuple2(posx, posy);
	}


	//// LIST STUFF ////

	var Nil = { ctor: '[]' };

	function Cons(hd, tl)
	{
		return {
			ctor: '::',
			_0: hd,
			_1: tl
		};
	}

	function list(arr)
	{
		var out = Nil;
		for (var i = arr.length; i--; )
		{
			out = Cons(arr[i], out);
		}
		return out;
	}

	function range(lo, hi)
	{
		var list = Nil;
		if (lo <= hi)
		{
			do
			{
				list = Cons(hi, list);
			}
			while (hi-- > lo);
		}
		return list;
	}

	function append(xs, ys)
	{
		// append Strings
		if (typeof xs === 'string')
		{
			return xs + ys;
		}

		// append Text
		if (xs.ctor.slice(0, 5) === 'Text:')
		{
			return {
				ctor: 'Text:Append',
				_0: xs,
				_1: ys
			};
		}


		// append Lists
		if (xs.ctor === '[]')
		{
			return ys;
		}
		var root = Cons(xs._0, Nil);
		var curr = root;
		xs = xs._1;
		while (xs.ctor !== '[]')
		{
			curr._1 = Cons(xs._0, Nil);
			xs = xs._1;
			curr = curr._1;
		}
		curr._1 = ys;
		return root;
	}


	// CRASHES

	function crash(moduleName, region)
	{
		return function(message) {
			throw new Error(
				'Ran into a `Debug.crash` in module `' + moduleName + '` ' + regionToString(region) + '\n'
				+ 'The message provided by the code author is:\n\n    '
				+ message
			);
		};
	}

	function crashCase(moduleName, region, value)
	{
		return function(message) {
			throw new Error(
				'Ran into a `Debug.crash` in module `' + moduleName + '`\n\n'
				+ 'This was caused by the `case` expression ' + regionToString(region) + '.\n'
				+ 'One of the branches ended with a crash and the following value got through:\n\n    ' + toString(value) + '\n\n'
				+ 'The message provided by the code author is:\n\n    '
				+ message
			);
		};
	}

	function regionToString(region)
	{
		if (region.start.line == region.end.line)
		{
			return 'on line ' + region.start.line;
		}
		return 'between lines ' + region.start.line + ' and ' + region.end.line;
	}


	// BAD PORTS

	function badPort(expected, received)
	{
		throw new Error(
			'Runtime error when sending values through a port.\n\n'
			+ 'Expecting ' + expected + ' but was given ' + formatValue(received)
		);
	}

	function formatValue(value)
	{
		// Explicity format undefined values as "undefined"
		// because JSON.stringify(undefined) unhelpfully returns ""
		return (value === undefined) ? "undefined" : JSON.stringify(value);
	}


	// TO STRING

	var _Array;
	var Dict;
	var List;

	var toString = function(v)
	{
		var type = typeof v;
		if (type === 'function')
		{
			var name = v.func ? v.func.name : v.name;
			return '<function' + (name === '' ? '' : ': ') + name + '>';
		}
		else if (type === 'boolean')
		{
			return v ? 'True' : 'False';
		}
		else if (type === 'number')
		{
			return v + '';
		}
		else if ((v instanceof String) && v.isChar)
		{
			return '\'' + addSlashes(v, true) + '\'';
		}
		else if (type === 'string')
		{
			return '"' + addSlashes(v, false) + '"';
		}
		else if (type === 'object' && 'ctor' in v)
		{
			if (v.ctor.substring(0, 6) === '_Tuple')
			{
				var output = [];
				for (var k in v)
				{
					if (k === 'ctor') continue;
					output.push(toString(v[k]));
				}
				return '(' + output.join(',') + ')';
			}
			else if (v.ctor === '_Array')
			{
				if (!_Array)
				{
					_Array = Elm.Array.make(localRuntime);
				}
				var list = _Array.toList(v);
				return 'Array.fromList ' + toString(list);
			}
			else if (v.ctor === '::')
			{
				var output = '[' + toString(v._0);
				v = v._1;
				while (v.ctor === '::')
				{
					output += ',' + toString(v._0);
					v = v._1;
				}
				return output + ']';
			}
			else if (v.ctor === '[]')
			{
				return '[]';
			}
			else if (v.ctor === 'RBNode_elm_builtin' || v.ctor === 'RBEmpty_elm_builtin' || v.ctor === 'Set_elm_builtin')
			{
				if (!Dict)
				{
					Dict = Elm.Dict.make(localRuntime);
				}
				var list;
				var name;
				if (v.ctor === 'Set_elm_builtin')
				{
					if (!List)
					{
						List = Elm.List.make(localRuntime);
					}
					name = 'Set';
					list = A2(List.map, function(x) {return x._0; }, Dict.toList(v._0));
				}
				else
				{
					name = 'Dict';
					list = Dict.toList(v);
				}
				return name + '.fromList ' + toString(list);
			}
			else if (v.ctor.slice(0, 5) === 'Text:')
			{
				return '<text>';
			}
			else if (v.ctor === 'Element_elm_builtin')
			{
				return '<element>'
			}
			else if (v.ctor === 'Form_elm_builtin')
			{
				return '<form>'
			}
			else
			{
				var output = '';
				for (var i in v)
				{
					if (i === 'ctor') continue;
					var str = toString(v[i]);
					var parenless = str[0] === '{' || str[0] === '<' || str.indexOf(' ') < 0;
					output += ' ' + (parenless ? str : '(' + str + ')');
				}
				return v.ctor + output;
			}
		}
		else if (type === 'object' && 'notify' in v && 'id' in v)
		{
			return '<signal>';
		}
		else if (type === 'object')
		{
			var output = [];
			for (var k in v)
			{
				output.push(k + ' = ' + toString(v[k]));
			}
			if (output.length === 0)
			{
				return '{}';
			}
			return '{ ' + output.join(', ') + ' }';
		}
		return '<internal structure>';
	};

	function addSlashes(str, isChar)
	{
		var s = str.replace(/\\/g, '\\\\')
				  .replace(/\n/g, '\\n')
				  .replace(/\t/g, '\\t')
				  .replace(/\r/g, '\\r')
				  .replace(/\v/g, '\\v')
				  .replace(/\0/g, '\\0');
		if (isChar)
		{
			return s.replace(/\'/g, '\\\'');
		}
		else
		{
			return s.replace(/\"/g, '\\"');
		}
	}


	return localRuntime.Native.Utils.values = {
		eq: eq,
		cmp: cmp,
		compare: F2(compare),
		Tuple0: Tuple0,
		Tuple2: Tuple2,
		chr: chr,
		txt: txt,
		update: update,
		guid: guid,
		getXY: getXY,

		Nil: Nil,
		Cons: Cons,
		list: list,
		range: range,
		append: F2(append),

		crash: crash,
		crashCase: crashCase,
		badPort: badPort,

		toString: toString
	};
};

Elm.Basics = Elm.Basics || {};
Elm.Basics.make = function (_elm) {
   "use strict";
   _elm.Basics = _elm.Basics || {};
   if (_elm.Basics.values) return _elm.Basics.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Native$Basics = Elm.Native.Basics.make(_elm),
   $Native$Utils = Elm.Native.Utils.make(_elm);
   var _op = {};
   var uncurry = F2(function (f,_p0) {
      var _p1 = _p0;
      return A2(f,_p1._0,_p1._1);
   });
   var curry = F3(function (f,a,b) {
      return f({ctor: "_Tuple2",_0: a,_1: b});
   });
   var flip = F3(function (f,b,a) {    return A2(f,a,b);});
   var snd = function (_p2) {    var _p3 = _p2;return _p3._1;};
   var fst = function (_p4) {    var _p5 = _p4;return _p5._0;};
   var always = F2(function (a,_p6) {    return a;});
   var identity = function (x) {    return x;};
   _op["<|"] = F2(function (f,x) {    return f(x);});
   _op["|>"] = F2(function (x,f) {    return f(x);});
   _op[">>"] = F3(function (f,g,x) {    return g(f(x));});
   _op["<<"] = F3(function (g,f,x) {    return g(f(x));});
   _op["++"] = $Native$Utils.append;
   var toString = $Native$Utils.toString;
   var isInfinite = $Native$Basics.isInfinite;
   var isNaN = $Native$Basics.isNaN;
   var toFloat = $Native$Basics.toFloat;
   var ceiling = $Native$Basics.ceiling;
   var floor = $Native$Basics.floor;
   var truncate = $Native$Basics.truncate;
   var round = $Native$Basics.round;
   var not = $Native$Basics.not;
   var xor = $Native$Basics.xor;
   _op["||"] = $Native$Basics.or;
   _op["&&"] = $Native$Basics.and;
   var max = $Native$Basics.max;
   var min = $Native$Basics.min;
   var GT = {ctor: "GT"};
   var EQ = {ctor: "EQ"};
   var LT = {ctor: "LT"};
   var compare = $Native$Basics.compare;
   _op[">="] = $Native$Basics.ge;
   _op["<="] = $Native$Basics.le;
   _op[">"] = $Native$Basics.gt;
   _op["<"] = $Native$Basics.lt;
   _op["/="] = $Native$Basics.neq;
   _op["=="] = $Native$Basics.eq;
   var e = $Native$Basics.e;
   var pi = $Native$Basics.pi;
   var clamp = $Native$Basics.clamp;
   var logBase = $Native$Basics.logBase;
   var abs = $Native$Basics.abs;
   var negate = $Native$Basics.negate;
   var sqrt = $Native$Basics.sqrt;
   var atan2 = $Native$Basics.atan2;
   var atan = $Native$Basics.atan;
   var asin = $Native$Basics.asin;
   var acos = $Native$Basics.acos;
   var tan = $Native$Basics.tan;
   var sin = $Native$Basics.sin;
   var cos = $Native$Basics.cos;
   _op["^"] = $Native$Basics.exp;
   _op["%"] = $Native$Basics.mod;
   var rem = $Native$Basics.rem;
   _op["//"] = $Native$Basics.div;
   _op["/"] = $Native$Basics.floatDiv;
   _op["*"] = $Native$Basics.mul;
   _op["-"] = $Native$Basics.sub;
   _op["+"] = $Native$Basics.add;
   var toPolar = $Native$Basics.toPolar;
   var fromPolar = $Native$Basics.fromPolar;
   var turns = $Native$Basics.turns;
   var degrees = $Native$Basics.degrees;
   var radians = function (t) {    return t;};
   return _elm.Basics.values = {_op: _op
                               ,max: max
                               ,min: min
                               ,compare: compare
                               ,not: not
                               ,xor: xor
                               ,rem: rem
                               ,negate: negate
                               ,abs: abs
                               ,sqrt: sqrt
                               ,clamp: clamp
                               ,logBase: logBase
                               ,e: e
                               ,pi: pi
                               ,cos: cos
                               ,sin: sin
                               ,tan: tan
                               ,acos: acos
                               ,asin: asin
                               ,atan: atan
                               ,atan2: atan2
                               ,round: round
                               ,floor: floor
                               ,ceiling: ceiling
                               ,truncate: truncate
                               ,toFloat: toFloat
                               ,degrees: degrees
                               ,radians: radians
                               ,turns: turns
                               ,toPolar: toPolar
                               ,fromPolar: fromPolar
                               ,isNaN: isNaN
                               ,isInfinite: isInfinite
                               ,toString: toString
                               ,fst: fst
                               ,snd: snd
                               ,identity: identity
                               ,always: always
                               ,flip: flip
                               ,curry: curry
                               ,uncurry: uncurry
                               ,LT: LT
                               ,EQ: EQ
                               ,GT: GT};
};
Elm.Maybe = Elm.Maybe || {};
Elm.Maybe.make = function (_elm) {
   "use strict";
   _elm.Maybe = _elm.Maybe || {};
   if (_elm.Maybe.values) return _elm.Maybe.values;
   var _U = Elm.Native.Utils.make(_elm);
   var _op = {};
   var withDefault = F2(function ($default,maybe) {
      var _p0 = maybe;
      if (_p0.ctor === "Just") {
            return _p0._0;
         } else {
            return $default;
         }
   });
   var Nothing = {ctor: "Nothing"};
   var oneOf = function (maybes) {
      oneOf: while (true) {
         var _p1 = maybes;
         if (_p1.ctor === "[]") {
               return Nothing;
            } else {
               var _p3 = _p1._0;
               var _p2 = _p3;
               if (_p2.ctor === "Nothing") {
                     var _v3 = _p1._1;
                     maybes = _v3;
                     continue oneOf;
                  } else {
                     return _p3;
                  }
            }
      }
   };
   var andThen = F2(function (maybeValue,callback) {
      var _p4 = maybeValue;
      if (_p4.ctor === "Just") {
            return callback(_p4._0);
         } else {
            return Nothing;
         }
   });
   var Just = function (a) {    return {ctor: "Just",_0: a};};
   var map = F2(function (f,maybe) {
      var _p5 = maybe;
      if (_p5.ctor === "Just") {
            return Just(f(_p5._0));
         } else {
            return Nothing;
         }
   });
   var map2 = F3(function (func,ma,mb) {
      var _p6 = {ctor: "_Tuple2",_0: ma,_1: mb};
      if (_p6.ctor === "_Tuple2" && _p6._0.ctor === "Just" && _p6._1.ctor === "Just")
      {
            return Just(A2(func,_p6._0._0,_p6._1._0));
         } else {
            return Nothing;
         }
   });
   var map3 = F4(function (func,ma,mb,mc) {
      var _p7 = {ctor: "_Tuple3",_0: ma,_1: mb,_2: mc};
      if (_p7.ctor === "_Tuple3" && _p7._0.ctor === "Just" && _p7._1.ctor === "Just" && _p7._2.ctor === "Just")
      {
            return Just(A3(func,_p7._0._0,_p7._1._0,_p7._2._0));
         } else {
            return Nothing;
         }
   });
   var map4 = F5(function (func,ma,mb,mc,md) {
      var _p8 = {ctor: "_Tuple4",_0: ma,_1: mb,_2: mc,_3: md};
      if (_p8.ctor === "_Tuple4" && _p8._0.ctor === "Just" && _p8._1.ctor === "Just" && _p8._2.ctor === "Just" && _p8._3.ctor === "Just")
      {
            return Just(A4(func,
            _p8._0._0,
            _p8._1._0,
            _p8._2._0,
            _p8._3._0));
         } else {
            return Nothing;
         }
   });
   var map5 = F6(function (func,ma,mb,mc,md,me) {
      var _p9 = {ctor: "_Tuple5"
                ,_0: ma
                ,_1: mb
                ,_2: mc
                ,_3: md
                ,_4: me};
      if (_p9.ctor === "_Tuple5" && _p9._0.ctor === "Just" && _p9._1.ctor === "Just" && _p9._2.ctor === "Just" && _p9._3.ctor === "Just" && _p9._4.ctor === "Just")
      {
            return Just(A5(func,
            _p9._0._0,
            _p9._1._0,
            _p9._2._0,
            _p9._3._0,
            _p9._4._0));
         } else {
            return Nothing;
         }
   });
   return _elm.Maybe.values = {_op: _op
                              ,andThen: andThen
                              ,map: map
                              ,map2: map2
                              ,map3: map3
                              ,map4: map4
                              ,map5: map5
                              ,withDefault: withDefault
                              ,oneOf: oneOf
                              ,Just: Just
                              ,Nothing: Nothing};
};
Elm.Native.List = {};
Elm.Native.List.make = function(localRuntime) {
	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.List = localRuntime.Native.List || {};
	if (localRuntime.Native.List.values)
	{
		return localRuntime.Native.List.values;
	}
	if ('values' in Elm.Native.List)
	{
		return localRuntime.Native.List.values = Elm.Native.List.values;
	}

	var Utils = Elm.Native.Utils.make(localRuntime);

	var Nil = Utils.Nil;
	var Cons = Utils.Cons;

	var fromArray = Utils.list;

	function toArray(xs)
	{
		var out = [];
		while (xs.ctor !== '[]')
		{
			out.push(xs._0);
			xs = xs._1;
		}
		return out;
	}

	// f defined similarly for both foldl and foldr (NB: different from Haskell)
	// ie, foldl : (a -> b -> b) -> b -> [a] -> b
	function foldl(f, b, xs)
	{
		var acc = b;
		while (xs.ctor !== '[]')
		{
			acc = A2(f, xs._0, acc);
			xs = xs._1;
		}
		return acc;
	}

	function foldr(f, b, xs)
	{
		var arr = toArray(xs);
		var acc = b;
		for (var i = arr.length; i--; )
		{
			acc = A2(f, arr[i], acc);
		}
		return acc;
	}

	function map2(f, xs, ys)
	{
		var arr = [];
		while (xs.ctor !== '[]' && ys.ctor !== '[]')
		{
			arr.push(A2(f, xs._0, ys._0));
			xs = xs._1;
			ys = ys._1;
		}
		return fromArray(arr);
	}

	function map3(f, xs, ys, zs)
	{
		var arr = [];
		while (xs.ctor !== '[]' && ys.ctor !== '[]' && zs.ctor !== '[]')
		{
			arr.push(A3(f, xs._0, ys._0, zs._0));
			xs = xs._1;
			ys = ys._1;
			zs = zs._1;
		}
		return fromArray(arr);
	}

	function map4(f, ws, xs, ys, zs)
	{
		var arr = [];
		while (   ws.ctor !== '[]'
			   && xs.ctor !== '[]'
			   && ys.ctor !== '[]'
			   && zs.ctor !== '[]')
		{
			arr.push(A4(f, ws._0, xs._0, ys._0, zs._0));
			ws = ws._1;
			xs = xs._1;
			ys = ys._1;
			zs = zs._1;
		}
		return fromArray(arr);
	}

	function map5(f, vs, ws, xs, ys, zs)
	{
		var arr = [];
		while (   vs.ctor !== '[]'
			   && ws.ctor !== '[]'
			   && xs.ctor !== '[]'
			   && ys.ctor !== '[]'
			   && zs.ctor !== '[]')
		{
			arr.push(A5(f, vs._0, ws._0, xs._0, ys._0, zs._0));
			vs = vs._1;
			ws = ws._1;
			xs = xs._1;
			ys = ys._1;
			zs = zs._1;
		}
		return fromArray(arr);
	}

	function sortBy(f, xs)
	{
		return fromArray(toArray(xs).sort(function(a, b) {
			return Utils.cmp(f(a), f(b));
		}));
	}

	function sortWith(f, xs)
	{
		return fromArray(toArray(xs).sort(function(a, b) {
			var ord = f(a)(b).ctor;
			return ord === 'EQ' ? 0 : ord === 'LT' ? -1 : 1;
		}));
	}

	function take(n, xs)
	{
		var arr = [];
		while (xs.ctor !== '[]' && n > 0)
		{
			arr.push(xs._0);
			xs = xs._1;
			--n;
		}
		return fromArray(arr);
	}


	Elm.Native.List.values = {
		Nil: Nil,
		Cons: Cons,
		cons: F2(Cons),
		toArray: toArray,
		fromArray: fromArray,

		foldl: F3(foldl),
		foldr: F3(foldr),

		map2: F3(map2),
		map3: F4(map3),
		map4: F5(map4),
		map5: F6(map5),
		sortBy: F2(sortBy),
		sortWith: F2(sortWith),
		take: F2(take)
	};
	return localRuntime.Native.List.values = Elm.Native.List.values;
};

Elm.List = Elm.List || {};
Elm.List.make = function (_elm) {
   "use strict";
   _elm.List = _elm.List || {};
   if (_elm.List.values) return _elm.List.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Native$List = Elm.Native.List.make(_elm);
   var _op = {};
   var sortWith = $Native$List.sortWith;
   var sortBy = $Native$List.sortBy;
   var sort = function (xs) {
      return A2(sortBy,$Basics.identity,xs);
   };
   var drop = F2(function (n,list) {
      drop: while (true) if (_U.cmp(n,0) < 1) return list; else {
            var _p0 = list;
            if (_p0.ctor === "[]") {
                  return list;
               } else {
                  var _v1 = n - 1,_v2 = _p0._1;
                  n = _v1;
                  list = _v2;
                  continue drop;
               }
         }
   });
   var take = $Native$List.take;
   var map5 = $Native$List.map5;
   var map4 = $Native$List.map4;
   var map3 = $Native$List.map3;
   var map2 = $Native$List.map2;
   var any = F2(function (isOkay,list) {
      any: while (true) {
         var _p1 = list;
         if (_p1.ctor === "[]") {
               return false;
            } else {
               if (isOkay(_p1._0)) return true; else {
                     var _v4 = isOkay,_v5 = _p1._1;
                     isOkay = _v4;
                     list = _v5;
                     continue any;
                  }
            }
      }
   });
   var all = F2(function (isOkay,list) {
      return $Basics.not(A2(any,
      function (_p2) {
         return $Basics.not(isOkay(_p2));
      },
      list));
   });
   var foldr = $Native$List.foldr;
   var foldl = $Native$List.foldl;
   var length = function (xs) {
      return A3(foldl,
      F2(function (_p3,i) {    return i + 1;}),
      0,
      xs);
   };
   var sum = function (numbers) {
      return A3(foldl,
      F2(function (x,y) {    return x + y;}),
      0,
      numbers);
   };
   var product = function (numbers) {
      return A3(foldl,
      F2(function (x,y) {    return x * y;}),
      1,
      numbers);
   };
   var maximum = function (list) {
      var _p4 = list;
      if (_p4.ctor === "::") {
            return $Maybe.Just(A3(foldl,$Basics.max,_p4._0,_p4._1));
         } else {
            return $Maybe.Nothing;
         }
   };
   var minimum = function (list) {
      var _p5 = list;
      if (_p5.ctor === "::") {
            return $Maybe.Just(A3(foldl,$Basics.min,_p5._0,_p5._1));
         } else {
            return $Maybe.Nothing;
         }
   };
   var indexedMap = F2(function (f,xs) {
      return A3(map2,f,_U.range(0,length(xs) - 1),xs);
   });
   var member = F2(function (x,xs) {
      return A2(any,function (a) {    return _U.eq(a,x);},xs);
   });
   var isEmpty = function (xs) {
      var _p6 = xs;
      if (_p6.ctor === "[]") {
            return true;
         } else {
            return false;
         }
   };
   var tail = function (list) {
      var _p7 = list;
      if (_p7.ctor === "::") {
            return $Maybe.Just(_p7._1);
         } else {
            return $Maybe.Nothing;
         }
   };
   var head = function (list) {
      var _p8 = list;
      if (_p8.ctor === "::") {
            return $Maybe.Just(_p8._0);
         } else {
            return $Maybe.Nothing;
         }
   };
   _op["::"] = $Native$List.cons;
   var map = F2(function (f,xs) {
      return A3(foldr,
      F2(function (x,acc) {    return A2(_op["::"],f(x),acc);}),
      _U.list([]),
      xs);
   });
   var filter = F2(function (pred,xs) {
      var conditionalCons = F2(function (x,xs$) {
         return pred(x) ? A2(_op["::"],x,xs$) : xs$;
      });
      return A3(foldr,conditionalCons,_U.list([]),xs);
   });
   var maybeCons = F3(function (f,mx,xs) {
      var _p9 = f(mx);
      if (_p9.ctor === "Just") {
            return A2(_op["::"],_p9._0,xs);
         } else {
            return xs;
         }
   });
   var filterMap = F2(function (f,xs) {
      return A3(foldr,maybeCons(f),_U.list([]),xs);
   });
   var reverse = function (list) {
      return A3(foldl,
      F2(function (x,y) {    return A2(_op["::"],x,y);}),
      _U.list([]),
      list);
   };
   var scanl = F3(function (f,b,xs) {
      var scan1 = F2(function (x,accAcc) {
         var _p10 = accAcc;
         if (_p10.ctor === "::") {
               return A2(_op["::"],A2(f,x,_p10._0),accAcc);
            } else {
               return _U.list([]);
            }
      });
      return reverse(A3(foldl,scan1,_U.list([b]),xs));
   });
   var append = F2(function (xs,ys) {
      var _p11 = ys;
      if (_p11.ctor === "[]") {
            return xs;
         } else {
            return A3(foldr,
            F2(function (x,y) {    return A2(_op["::"],x,y);}),
            ys,
            xs);
         }
   });
   var concat = function (lists) {
      return A3(foldr,append,_U.list([]),lists);
   };
   var concatMap = F2(function (f,list) {
      return concat(A2(map,f,list));
   });
   var partition = F2(function (pred,list) {
      var step = F2(function (x,_p12) {
         var _p13 = _p12;
         var _p15 = _p13._0;
         var _p14 = _p13._1;
         return pred(x) ? {ctor: "_Tuple2"
                          ,_0: A2(_op["::"],x,_p15)
                          ,_1: _p14} : {ctor: "_Tuple2"
                                       ,_0: _p15
                                       ,_1: A2(_op["::"],x,_p14)};
      });
      return A3(foldr,
      step,
      {ctor: "_Tuple2",_0: _U.list([]),_1: _U.list([])},
      list);
   });
   var unzip = function (pairs) {
      var step = F2(function (_p17,_p16) {
         var _p18 = _p17;
         var _p19 = _p16;
         return {ctor: "_Tuple2"
                ,_0: A2(_op["::"],_p18._0,_p19._0)
                ,_1: A2(_op["::"],_p18._1,_p19._1)};
      });
      return A3(foldr,
      step,
      {ctor: "_Tuple2",_0: _U.list([]),_1: _U.list([])},
      pairs);
   };
   var intersperse = F2(function (sep,xs) {
      var _p20 = xs;
      if (_p20.ctor === "[]") {
            return _U.list([]);
         } else {
            var step = F2(function (x,rest) {
               return A2(_op["::"],sep,A2(_op["::"],x,rest));
            });
            var spersed = A3(foldr,step,_U.list([]),_p20._1);
            return A2(_op["::"],_p20._0,spersed);
         }
   });
   var repeatHelp = F3(function (result,n,value) {
      repeatHelp: while (true) if (_U.cmp(n,0) < 1) return result;
      else {
            var _v18 = A2(_op["::"],value,result),
            _v19 = n - 1,
            _v20 = value;
            result = _v18;
            n = _v19;
            value = _v20;
            continue repeatHelp;
         }
   });
   var repeat = F2(function (n,value) {
      return A3(repeatHelp,_U.list([]),n,value);
   });
   return _elm.List.values = {_op: _op
                             ,isEmpty: isEmpty
                             ,length: length
                             ,reverse: reverse
                             ,member: member
                             ,head: head
                             ,tail: tail
                             ,filter: filter
                             ,take: take
                             ,drop: drop
                             ,repeat: repeat
                             ,append: append
                             ,concat: concat
                             ,intersperse: intersperse
                             ,partition: partition
                             ,unzip: unzip
                             ,map: map
                             ,map2: map2
                             ,map3: map3
                             ,map4: map4
                             ,map5: map5
                             ,filterMap: filterMap
                             ,concatMap: concatMap
                             ,indexedMap: indexedMap
                             ,foldr: foldr
                             ,foldl: foldl
                             ,sum: sum
                             ,product: product
                             ,maximum: maximum
                             ,minimum: minimum
                             ,all: all
                             ,any: any
                             ,scanl: scanl
                             ,sort: sort
                             ,sortBy: sortBy
                             ,sortWith: sortWith};
};
Elm.Native.Transform2D = {};
Elm.Native.Transform2D.make = function(localRuntime) {
	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Transform2D = localRuntime.Native.Transform2D || {};
	if (localRuntime.Native.Transform2D.values)
	{
		return localRuntime.Native.Transform2D.values;
	}

	var A;
	if (typeof Float32Array === 'undefined')
	{
		A = function(arr)
		{
			this.length = arr.length;
			this[0] = arr[0];
			this[1] = arr[1];
			this[2] = arr[2];
			this[3] = arr[3];
			this[4] = arr[4];
			this[5] = arr[5];
		};
	}
	else
	{
		A = Float32Array;
	}

	// layout of matrix in an array is
	//
	//   | m11 m12 dx |
	//   | m21 m22 dy |
	//   |  0   0   1 |
	//
	//  new A([ m11, m12, dx, m21, m22, dy ])

	var identity = new A([1, 0, 0, 0, 1, 0]);
	function matrix(m11, m12, m21, m22, dx, dy)
	{
		return new A([m11, m12, dx, m21, m22, dy]);
	}

	function rotation(t)
	{
		var c = Math.cos(t);
		var s = Math.sin(t);
		return new A([c, -s, 0, s, c, 0]);
	}

	function rotate(t, m)
	{
		var c = Math.cos(t);
		var s = Math.sin(t);
		var m11 = m[0], m12 = m[1], m21 = m[3], m22 = m[4];
		return new A([m11 * c + m12 * s, -m11 * s + m12 * c, m[2],
					  m21 * c + m22 * s, -m21 * s + m22 * c, m[5]]);
	}
	/*
	function move(xy,m) {
		var x = xy._0;
		var y = xy._1;
		var m11 = m[0], m12 = m[1], m21 = m[3], m22 = m[4];
		return new A([m11, m12, m11*x + m12*y + m[2],
					  m21, m22, m21*x + m22*y + m[5]]);
	}
	function scale(s,m) { return new A([m[0]*s, m[1]*s, m[2], m[3]*s, m[4]*s, m[5]]); }
	function scaleX(x,m) { return new A([m[0]*x, m[1], m[2], m[3]*x, m[4], m[5]]); }
	function scaleY(y,m) { return new A([m[0], m[1]*y, m[2], m[3], m[4]*y, m[5]]); }
	function reflectX(m) { return new A([-m[0], m[1], m[2], -m[3], m[4], m[5]]); }
	function reflectY(m) { return new A([m[0], -m[1], m[2], m[3], -m[4], m[5]]); }

	function transform(m11, m21, m12, m22, mdx, mdy, n) {
		var n11 = n[0], n12 = n[1], n21 = n[3], n22 = n[4], ndx = n[2], ndy = n[5];
		return new A([m11*n11 + m12*n21,
					  m11*n12 + m12*n22,
					  m11*ndx + m12*ndy + mdx,
					  m21*n11 + m22*n21,
					  m21*n12 + m22*n22,
					  m21*ndx + m22*ndy + mdy]);
	}
	*/
	function multiply(m, n)
	{
		var m11 = m[0], m12 = m[1], m21 = m[3], m22 = m[4], mdx = m[2], mdy = m[5];
		var n11 = n[0], n12 = n[1], n21 = n[3], n22 = n[4], ndx = n[2], ndy = n[5];
		return new A([m11 * n11 + m12 * n21,
					  m11 * n12 + m12 * n22,
					  m11 * ndx + m12 * ndy + mdx,
					  m21 * n11 + m22 * n21,
					  m21 * n12 + m22 * n22,
					  m21 * ndx + m22 * ndy + mdy]);
	}

	return localRuntime.Native.Transform2D.values = {
		identity: identity,
		matrix: F6(matrix),
		rotation: rotation,
		multiply: F2(multiply)
		/*
		transform: F7(transform),
		rotate: F2(rotate),
		move: F2(move),
		scale: F2(scale),
		scaleX: F2(scaleX),
		scaleY: F2(scaleY),
		reflectX: reflectX,
		reflectY: reflectY
		*/
	};
};

Elm.Transform2D = Elm.Transform2D || {};
Elm.Transform2D.make = function (_elm) {
   "use strict";
   _elm.Transform2D = _elm.Transform2D || {};
   if (_elm.Transform2D.values) return _elm.Transform2D.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Native$Transform2D = Elm.Native.Transform2D.make(_elm);
   var _op = {};
   var multiply = $Native$Transform2D.multiply;
   var rotation = $Native$Transform2D.rotation;
   var matrix = $Native$Transform2D.matrix;
   var translation = F2(function (x,y) {
      return A6(matrix,1,0,0,1,x,y);
   });
   var scale = function (s) {    return A6(matrix,s,0,0,s,0,0);};
   var scaleX = function (x) {    return A6(matrix,x,0,0,1,0,0);};
   var scaleY = function (y) {    return A6(matrix,1,0,0,y,0,0);};
   var identity = $Native$Transform2D.identity;
   var Transform2D = {ctor: "Transform2D"};
   return _elm.Transform2D.values = {_op: _op
                                    ,identity: identity
                                    ,matrix: matrix
                                    ,multiply: multiply
                                    ,rotation: rotation
                                    ,translation: translation
                                    ,scale: scale
                                    ,scaleX: scaleX
                                    ,scaleY: scaleY};
};

// setup
Elm.Native = Elm.Native || {};
Elm.Native.Graphics = Elm.Native.Graphics || {};
Elm.Native.Graphics.Collage = Elm.Native.Graphics.Collage || {};

// definition
Elm.Native.Graphics.Collage.make = function(localRuntime) {
	'use strict';

	// attempt to short-circuit
	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Graphics = localRuntime.Native.Graphics || {};
	localRuntime.Native.Graphics.Collage = localRuntime.Native.Graphics.Collage || {};
	if ('values' in localRuntime.Native.Graphics.Collage)
	{
		return localRuntime.Native.Graphics.Collage.values;
	}

	// okay, we cannot short-ciruit, so now we define everything
	var Color = Elm.Native.Color.make(localRuntime);
	var List = Elm.Native.List.make(localRuntime);
	var NativeElement = Elm.Native.Graphics.Element.make(localRuntime);
	var Transform = Elm.Transform2D.make(localRuntime);
	var Utils = Elm.Native.Utils.make(localRuntime);

	function setStrokeStyle(ctx, style)
	{
		ctx.lineWidth = style.width;

		var cap = style.cap.ctor;
		ctx.lineCap = cap === 'Flat'
			? 'butt'
			: cap === 'Round'
				? 'round'
				: 'square';

		var join = style.join.ctor;
		ctx.lineJoin = join === 'Smooth'
			? 'round'
			: join === 'Sharp'
				? 'miter'
				: 'bevel';

		ctx.miterLimit = style.join._0 || 10;
		ctx.strokeStyle = Color.toCss(style.color);
	}

	function setFillStyle(redo, ctx, style)
	{
		var sty = style.ctor;
		ctx.fillStyle = sty === 'Solid'
			? Color.toCss(style._0)
			: sty === 'Texture'
				? texture(redo, ctx, style._0)
				: gradient(ctx, style._0);
	}

	function trace(ctx, path)
	{
		var points = List.toArray(path);
		var i = points.length - 1;
		if (i <= 0)
		{
			return;
		}
		ctx.moveTo(points[i]._0, points[i]._1);
		while (i--)
		{
			ctx.lineTo(points[i]._0, points[i]._1);
		}
		if (path.closed)
		{
			i = points.length - 1;
			ctx.lineTo(points[i]._0, points[i]._1);
		}
	}

	function line(ctx, style, path)
	{
		if (style.dashing.ctor === '[]')
		{
			trace(ctx, path);
		}
		else
		{
			customLineHelp(ctx, style, path);
		}
		ctx.scale(1, -1);
		ctx.stroke();
	}

	function customLineHelp(ctx, style, path)
	{
		var points = List.toArray(path);
		if (path.closed)
		{
			points.push(points[0]);
		}
		var pattern = List.toArray(style.dashing);
		var i = points.length - 1;
		if (i <= 0)
		{
			return;
		}
		var x0 = points[i]._0, y0 = points[i]._1;
		var x1 = 0, y1 = 0, dx = 0, dy = 0, remaining = 0;
		var pindex = 0, plen = pattern.length;
		var draw = true, segmentLength = pattern[0];
		ctx.moveTo(x0, y0);
		while (i--)
		{
			x1 = points[i]._0;
			y1 = points[i]._1;
			dx = x1 - x0;
			dy = y1 - y0;
			remaining = Math.sqrt(dx * dx + dy * dy);
			while (segmentLength <= remaining)
			{
				x0 += dx * segmentLength / remaining;
				y0 += dy * segmentLength / remaining;
				ctx[draw ? 'lineTo' : 'moveTo'](x0, y0);
				// update starting position
				dx = x1 - x0;
				dy = y1 - y0;
				remaining = Math.sqrt(dx * dx + dy * dy);
				// update pattern
				draw = !draw;
				pindex = (pindex + 1) % plen;
				segmentLength = pattern[pindex];
			}
			if (remaining > 0)
			{
				ctx[draw ? 'lineTo' : 'moveTo'](x1, y1);
				segmentLength -= remaining;
			}
			x0 = x1;
			y0 = y1;
		}
	}

	function drawLine(ctx, style, path)
	{
		setStrokeStyle(ctx, style);
		return line(ctx, style, path);
	}

	function texture(redo, ctx, src)
	{
		var img = new Image();
		img.src = src;
		img.onload = redo;
		return ctx.createPattern(img, 'repeat');
	}

	function gradient(ctx, grad)
	{
		var g;
		var stops = [];
		if (grad.ctor === 'Linear')
		{
			var p0 = grad._0, p1 = grad._1;
			g = ctx.createLinearGradient(p0._0, -p0._1, p1._0, -p1._1);
			stops = List.toArray(grad._2);
		}
		else
		{
			var p0 = grad._0, p2 = grad._2;
			g = ctx.createRadialGradient(p0._0, -p0._1, grad._1, p2._0, -p2._1, grad._3);
			stops = List.toArray(grad._4);
		}
		var len = stops.length;
		for (var i = 0; i < len; ++i)
		{
			var stop = stops[i];
			g.addColorStop(stop._0, Color.toCss(stop._1));
		}
		return g;
	}

	function drawShape(redo, ctx, style, path)
	{
		trace(ctx, path);
		setFillStyle(redo, ctx, style);
		ctx.scale(1, -1);
		ctx.fill();
	}


	// TEXT RENDERING

	function fillText(redo, ctx, text)
	{
		drawText(ctx, text, ctx.fillText);
	}

	function strokeText(redo, ctx, style, text)
	{
		setStrokeStyle(ctx, style);
		// Use native canvas API for dashes only for text for now
		// Degrades to non-dashed on IE 9 + 10
		if (style.dashing.ctor !== '[]' && ctx.setLineDash)
		{
			var pattern = List.toArray(style.dashing);
			ctx.setLineDash(pattern);
		}
		drawText(ctx, text, ctx.strokeText);
	}

	function drawText(ctx, text, canvasDrawFn)
	{
		var textChunks = chunkText(defaultContext, text);

		var totalWidth = 0;
		var maxHeight = 0;
		var numChunks = textChunks.length;

		ctx.scale(1,-1);

		for (var i = numChunks; i--; )
		{
			var chunk = textChunks[i];
			ctx.font = chunk.font;
			var metrics = ctx.measureText(chunk.text);
			chunk.width = metrics.width;
			totalWidth += chunk.width;
			if (chunk.height > maxHeight)
			{
				maxHeight = chunk.height;
			}
		}

		var x = -totalWidth / 2.0;
		for (var i = 0; i < numChunks; ++i)
		{
			var chunk = textChunks[i];
			ctx.font = chunk.font;
			ctx.fillStyle = chunk.color;
			canvasDrawFn.call(ctx, chunk.text, x, maxHeight / 2);
			x += chunk.width;
		}
	}

	function toFont(props)
	{
		return [
			props['font-style'],
			props['font-variant'],
			props['font-weight'],
			props['font-size'],
			props['font-family']
		].join(' ');
	}


	// Convert the object returned by the text module
	// into something we can use for styling canvas text
	function chunkText(context, text)
	{
		var tag = text.ctor;
		if (tag === 'Text:Append')
		{
			var leftChunks = chunkText(context, text._0);
			var rightChunks = chunkText(context, text._1);
			return leftChunks.concat(rightChunks);
		}
		if (tag === 'Text:Text')
		{
			return [{
				text: text._0,
				color: context.color,
				height: context['font-size'].slice(0, -2) | 0,
				font: toFont(context)
			}];
		}
		if (tag === 'Text:Meta')
		{
			var newContext = freshContext(text._0, context);
			return chunkText(newContext, text._1);
		}
	}

	function freshContext(props, ctx)
	{
		return {
			'font-style': props['font-style'] || ctx['font-style'],
			'font-variant': props['font-variant'] || ctx['font-variant'],
			'font-weight': props['font-weight'] || ctx['font-weight'],
			'font-size': props['font-size'] || ctx['font-size'],
			'font-family': props['font-family'] || ctx['font-family'],
			'color': props['color'] || ctx['color']
		};
	}

	var defaultContext = {
		'font-style': 'normal',
		'font-variant': 'normal',
		'font-weight': 'normal',
		'font-size': '12px',
		'font-family': 'sans-serif',
		'color': 'black'
	};


	// IMAGES

	function drawImage(redo, ctx, form)
	{
		var img = new Image();
		img.onload = redo;
		img.src = form._3;
		var w = form._0,
			h = form._1,
			pos = form._2,
			srcX = pos._0,
			srcY = pos._1,
			srcW = w,
			srcH = h,
			destX = -w / 2,
			destY = -h / 2,
			destW = w,
			destH = h;

		ctx.scale(1, -1);
		ctx.drawImage(img, srcX, srcY, srcW, srcH, destX, destY, destW, destH);
	}

	function renderForm(redo, ctx, form)
	{
		ctx.save();

		var x = form.x,
			y = form.y,
			theta = form.theta,
			scale = form.scale;

		if (x !== 0 || y !== 0)
		{
			ctx.translate(x, y);
		}
		if (theta !== 0)
		{
			ctx.rotate(theta % (Math.PI * 2));
		}
		if (scale !== 1)
		{
			ctx.scale(scale, scale);
		}
		if (form.alpha !== 1)
		{
			ctx.globalAlpha = ctx.globalAlpha * form.alpha;
		}

		ctx.beginPath();
		var f = form.form;
		switch (f.ctor)
		{
			case 'FPath':
				drawLine(ctx, f._0, f._1);
				break;

			case 'FImage':
				drawImage(redo, ctx, f);
				break;

			case 'FShape':
				if (f._0.ctor === 'Line')
				{
					f._1.closed = true;
					drawLine(ctx, f._0._0, f._1);
				}
				else
				{
					drawShape(redo, ctx, f._0._0, f._1);
				}
				break;

			case 'FText':
				fillText(redo, ctx, f._0);
				break;

			case 'FOutlinedText':
				strokeText(redo, ctx, f._0, f._1);
				break;
		}
		ctx.restore();
	}

	function formToMatrix(form)
	{
	   var scale = form.scale;
	   var matrix = A6( Transform.matrix, scale, 0, 0, scale, form.x, form.y );

	   var theta = form.theta;
	   if (theta !== 0)
	   {
		   matrix = A2( Transform.multiply, matrix, Transform.rotation(theta) );
	   }

	   return matrix;
	}

	function str(n)
	{
		if (n < 0.00001 && n > -0.00001)
		{
			return 0;
		}
		return n;
	}

	function makeTransform(w, h, form, matrices)
	{
		var props = form.form._0._0.props;
		var m = A6( Transform.matrix, 1, 0, 0, -1,
					(w - props.width ) / 2,
					(h - props.height) / 2 );
		var len = matrices.length;
		for (var i = 0; i < len; ++i)
		{
			m = A2( Transform.multiply, m, matrices[i] );
		}
		m = A2( Transform.multiply, m, formToMatrix(form) );

		return 'matrix(' +
			str( m[0]) + ', ' + str( m[3]) + ', ' +
			str(-m[1]) + ', ' + str(-m[4]) + ', ' +
			str( m[2]) + ', ' + str( m[5]) + ')';
	}

	function stepperHelp(list)
	{
		var arr = List.toArray(list);
		var i = 0;
		function peekNext()
		{
			return i < arr.length ? arr[i]._0.form.ctor : '';
		}
		// assumes that there is a next element
		function next()
		{
			var out = arr[i]._0;
			++i;
			return out;
		}
		return {
			peekNext: peekNext,
			next: next
		};
	}

	function formStepper(forms)
	{
		var ps = [stepperHelp(forms)];
		var matrices = [];
		var alphas = [];
		function peekNext()
		{
			var len = ps.length;
			var formType = '';
			for (var i = 0; i < len; ++i )
			{
				if (formType = ps[i].peekNext()) return formType;
			}
			return '';
		}
		// assumes that there is a next element
		function next(ctx)
		{
			while (!ps[0].peekNext())
			{
				ps.shift();
				matrices.pop();
				alphas.shift();
				if (ctx)
				{
					ctx.restore();
				}
			}
			var out = ps[0].next();
			var f = out.form;
			if (f.ctor === 'FGroup')
			{
				ps.unshift(stepperHelp(f._1));
				var m = A2(Transform.multiply, f._0, formToMatrix(out));
				ctx.save();
				ctx.transform(m[0], m[3], m[1], m[4], m[2], m[5]);
				matrices.push(m);

				var alpha = (alphas[0] || 1) * out.alpha;
				alphas.unshift(alpha);
				ctx.globalAlpha = alpha;
			}
			return out;
		}
		function transforms()
		{
			return matrices;
		}
		function alpha()
		{
			return alphas[0] || 1;
		}
		return {
			peekNext: peekNext,
			next: next,
			transforms: transforms,
			alpha: alpha
		};
	}

	function makeCanvas(w, h)
	{
		var canvas = NativeElement.createNode('canvas');
		canvas.style.width  = w + 'px';
		canvas.style.height = h + 'px';
		canvas.style.display = 'block';
		canvas.style.position = 'absolute';
		var ratio = window.devicePixelRatio || 1;
		canvas.width  = w * ratio;
		canvas.height = h * ratio;
		return canvas;
	}

	function render(model)
	{
		var div = NativeElement.createNode('div');
		div.style.overflow = 'hidden';
		div.style.position = 'relative';
		update(div, model, model);
		return div;
	}

	function nodeStepper(w, h, div)
	{
		var kids = div.childNodes;
		var i = 0;
		var ratio = window.devicePixelRatio || 1;

		function transform(transforms, ctx)
		{
			ctx.translate( w / 2 * ratio, h / 2 * ratio );
			ctx.scale( ratio, -ratio );
			var len = transforms.length;
			for (var i = 0; i < len; ++i)
			{
				var m = transforms[i];
				ctx.save();
				ctx.transform(m[0], m[3], m[1], m[4], m[2], m[5]);
			}
			return ctx;
		}
		function nextContext(transforms)
		{
			while (i < kids.length)
			{
				var node = kids[i];
				if (node.getContext)
				{
					node.width = w * ratio;
					node.height = h * ratio;
					node.style.width = w + 'px';
					node.style.height = h + 'px';
					++i;
					return transform(transforms, node.getContext('2d'));
				}
				div.removeChild(node);
			}
			var canvas = makeCanvas(w, h);
			div.appendChild(canvas);
			// we have added a new node, so we must step our position
			++i;
			return transform(transforms, canvas.getContext('2d'));
		}
		function addElement(matrices, alpha, form)
		{
			var kid = kids[i];
			var elem = form.form._0;

			var node = (!kid || kid.getContext)
				? NativeElement.render(elem)
				: NativeElement.update(kid, kid.oldElement, elem);

			node.style.position = 'absolute';
			node.style.opacity = alpha * form.alpha * elem._0.props.opacity;
			NativeElement.addTransform(node.style, makeTransform(w, h, form, matrices));
			node.oldElement = elem;
			++i;
			if (!kid)
			{
				div.appendChild(node);
			}
			else
			{
				div.insertBefore(node, kid);
			}
		}
		function clearRest()
		{
			while (i < kids.length)
			{
				div.removeChild(kids[i]);
			}
		}
		return {
			nextContext: nextContext,
			addElement: addElement,
			clearRest: clearRest
		};
	}


	function update(div, _, model)
	{
		var w = model.w;
		var h = model.h;

		var forms = formStepper(model.forms);
		var nodes = nodeStepper(w, h, div);
		var ctx = null;
		var formType = '';

		while (formType = forms.peekNext())
		{
			// make sure we have context if we need it
			if (ctx === null && formType !== 'FElement')
			{
				ctx = nodes.nextContext(forms.transforms());
				ctx.globalAlpha = forms.alpha();
			}

			var form = forms.next(ctx);
			// if it is FGroup, all updates are made within formStepper when next is called.
			if (formType === 'FElement')
			{
				// update or insert an element, get a new context
				nodes.addElement(forms.transforms(), forms.alpha(), form);
				ctx = null;
			}
			else if (formType !== 'FGroup')
			{
				renderForm(function() { update(div, model, model); }, ctx, form);
			}
		}
		nodes.clearRest();
		return div;
	}


	function collage(w, h, forms)
	{
		return A3(NativeElement.newElement, w, h, {
			ctor: 'Custom',
			type: 'Collage',
			render: render,
			update: update,
			model: {w: w, h: h, forms: forms}
		});
	}

	return localRuntime.Native.Graphics.Collage.values = {
		collage: F3(collage)
	};
};

Elm.Native.Color = {};
Elm.Native.Color.make = function(localRuntime) {
	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Color = localRuntime.Native.Color || {};
	if (localRuntime.Native.Color.values)
	{
		return localRuntime.Native.Color.values;
	}

	function toCss(c)
	{
		var format = '';
		var colors = '';
		if (c.ctor === 'RGBA')
		{
			format = 'rgb';
			colors = c._0 + ', ' + c._1 + ', ' + c._2;
		}
		else
		{
			format = 'hsl';
			colors = (c._0 * 180 / Math.PI) + ', ' +
					 (c._1 * 100) + '%, ' +
					 (c._2 * 100) + '%';
		}
		if (c._3 === 1)
		{
			return format + '(' + colors + ')';
		}
		else
		{
			return format + 'a(' + colors + ', ' + c._3 + ')';
		}
	}

	return localRuntime.Native.Color.values = {
		toCss: toCss
	};
};

Elm.Color = Elm.Color || {};
Elm.Color.make = function (_elm) {
   "use strict";
   _elm.Color = _elm.Color || {};
   if (_elm.Color.values) return _elm.Color.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm);
   var _op = {};
   var Radial = F5(function (a,b,c,d,e) {
      return {ctor: "Radial",_0: a,_1: b,_2: c,_3: d,_4: e};
   });
   var radial = Radial;
   var Linear = F3(function (a,b,c) {
      return {ctor: "Linear",_0: a,_1: b,_2: c};
   });
   var linear = Linear;
   var fmod = F2(function (f,n) {
      var integer = $Basics.floor(f);
      return $Basics.toFloat(A2($Basics._op["%"],
      integer,
      n)) + f - $Basics.toFloat(integer);
   });
   var rgbToHsl = F3(function (red,green,blue) {
      var b = $Basics.toFloat(blue) / 255;
      var g = $Basics.toFloat(green) / 255;
      var r = $Basics.toFloat(red) / 255;
      var cMax = A2($Basics.max,A2($Basics.max,r,g),b);
      var cMin = A2($Basics.min,A2($Basics.min,r,g),b);
      var c = cMax - cMin;
      var lightness = (cMax + cMin) / 2;
      var saturation = _U.eq(lightness,
      0) ? 0 : c / (1 - $Basics.abs(2 * lightness - 1));
      var hue = $Basics.degrees(60) * (_U.eq(cMax,r) ? A2(fmod,
      (g - b) / c,
      6) : _U.eq(cMax,g) ? (b - r) / c + 2 : (r - g) / c + 4);
      return {ctor: "_Tuple3",_0: hue,_1: saturation,_2: lightness};
   });
   var hslToRgb = F3(function (hue,saturation,lightness) {
      var hue$ = hue / $Basics.degrees(60);
      var chroma = (1 - $Basics.abs(2 * lightness - 1)) * saturation;
      var x = chroma * (1 - $Basics.abs(A2(fmod,hue$,2) - 1));
      var _p0 = _U.cmp(hue$,0) < 0 ? {ctor: "_Tuple3"
                                     ,_0: 0
                                     ,_1: 0
                                     ,_2: 0} : _U.cmp(hue$,1) < 0 ? {ctor: "_Tuple3"
                                                                    ,_0: chroma
                                                                    ,_1: x
                                                                    ,_2: 0} : _U.cmp(hue$,2) < 0 ? {ctor: "_Tuple3"
                                                                                                   ,_0: x
                                                                                                   ,_1: chroma
                                                                                                   ,_2: 0} : _U.cmp(hue$,3) < 0 ? {ctor: "_Tuple3"
                                                                                                                                  ,_0: 0
                                                                                                                                  ,_1: chroma
                                                                                                                                  ,_2: x} : _U.cmp(hue$,
      4) < 0 ? {ctor: "_Tuple3",_0: 0,_1: x,_2: chroma} : _U.cmp(hue$,
      5) < 0 ? {ctor: "_Tuple3",_0: x,_1: 0,_2: chroma} : _U.cmp(hue$,
      6) < 0 ? {ctor: "_Tuple3"
               ,_0: chroma
               ,_1: 0
               ,_2: x} : {ctor: "_Tuple3",_0: 0,_1: 0,_2: 0};
      var r = _p0._0;
      var g = _p0._1;
      var b = _p0._2;
      var m = lightness - chroma / 2;
      return {ctor: "_Tuple3",_0: r + m,_1: g + m,_2: b + m};
   });
   var toRgb = function (color) {
      var _p1 = color;
      if (_p1.ctor === "RGBA") {
            return {red: _p1._0
                   ,green: _p1._1
                   ,blue: _p1._2
                   ,alpha: _p1._3};
         } else {
            var _p2 = A3(hslToRgb,_p1._0,_p1._1,_p1._2);
            var r = _p2._0;
            var g = _p2._1;
            var b = _p2._2;
            return {red: $Basics.round(255 * r)
                   ,green: $Basics.round(255 * g)
                   ,blue: $Basics.round(255 * b)
                   ,alpha: _p1._3};
         }
   };
   var toHsl = function (color) {
      var _p3 = color;
      if (_p3.ctor === "HSLA") {
            return {hue: _p3._0
                   ,saturation: _p3._1
                   ,lightness: _p3._2
                   ,alpha: _p3._3};
         } else {
            var _p4 = A3(rgbToHsl,_p3._0,_p3._1,_p3._2);
            var h = _p4._0;
            var s = _p4._1;
            var l = _p4._2;
            return {hue: h,saturation: s,lightness: l,alpha: _p3._3};
         }
   };
   var HSLA = F4(function (a,b,c,d) {
      return {ctor: "HSLA",_0: a,_1: b,_2: c,_3: d};
   });
   var hsla = F4(function (hue,saturation,lightness,alpha) {
      return A4(HSLA,
      hue - $Basics.turns($Basics.toFloat($Basics.floor(hue / (2 * $Basics.pi)))),
      saturation,
      lightness,
      alpha);
   });
   var hsl = F3(function (hue,saturation,lightness) {
      return A4(hsla,hue,saturation,lightness,1);
   });
   var complement = function (color) {
      var _p5 = color;
      if (_p5.ctor === "HSLA") {
            return A4(hsla,
            _p5._0 + $Basics.degrees(180),
            _p5._1,
            _p5._2,
            _p5._3);
         } else {
            var _p6 = A3(rgbToHsl,_p5._0,_p5._1,_p5._2);
            var h = _p6._0;
            var s = _p6._1;
            var l = _p6._2;
            return A4(hsla,h + $Basics.degrees(180),s,l,_p5._3);
         }
   };
   var grayscale = function (p) {    return A4(HSLA,0,0,1 - p,1);};
   var greyscale = function (p) {    return A4(HSLA,0,0,1 - p,1);};
   var RGBA = F4(function (a,b,c,d) {
      return {ctor: "RGBA",_0: a,_1: b,_2: c,_3: d};
   });
   var rgba = RGBA;
   var rgb = F3(function (r,g,b) {    return A4(RGBA,r,g,b,1);});
   var lightRed = A4(RGBA,239,41,41,1);
   var red = A4(RGBA,204,0,0,1);
   var darkRed = A4(RGBA,164,0,0,1);
   var lightOrange = A4(RGBA,252,175,62,1);
   var orange = A4(RGBA,245,121,0,1);
   var darkOrange = A4(RGBA,206,92,0,1);
   var lightYellow = A4(RGBA,255,233,79,1);
   var yellow = A4(RGBA,237,212,0,1);
   var darkYellow = A4(RGBA,196,160,0,1);
   var lightGreen = A4(RGBA,138,226,52,1);
   var green = A4(RGBA,115,210,22,1);
   var darkGreen = A4(RGBA,78,154,6,1);
   var lightBlue = A4(RGBA,114,159,207,1);
   var blue = A4(RGBA,52,101,164,1);
   var darkBlue = A4(RGBA,32,74,135,1);
   var lightPurple = A4(RGBA,173,127,168,1);
   var purple = A4(RGBA,117,80,123,1);
   var darkPurple = A4(RGBA,92,53,102,1);
   var lightBrown = A4(RGBA,233,185,110,1);
   var brown = A4(RGBA,193,125,17,1);
   var darkBrown = A4(RGBA,143,89,2,1);
   var black = A4(RGBA,0,0,0,1);
   var white = A4(RGBA,255,255,255,1);
   var lightGrey = A4(RGBA,238,238,236,1);
   var grey = A4(RGBA,211,215,207,1);
   var darkGrey = A4(RGBA,186,189,182,1);
   var lightGray = A4(RGBA,238,238,236,1);
   var gray = A4(RGBA,211,215,207,1);
   var darkGray = A4(RGBA,186,189,182,1);
   var lightCharcoal = A4(RGBA,136,138,133,1);
   var charcoal = A4(RGBA,85,87,83,1);
   var darkCharcoal = A4(RGBA,46,52,54,1);
   return _elm.Color.values = {_op: _op
                              ,rgb: rgb
                              ,rgba: rgba
                              ,hsl: hsl
                              ,hsla: hsla
                              ,greyscale: greyscale
                              ,grayscale: grayscale
                              ,complement: complement
                              ,linear: linear
                              ,radial: radial
                              ,toRgb: toRgb
                              ,toHsl: toHsl
                              ,red: red
                              ,orange: orange
                              ,yellow: yellow
                              ,green: green
                              ,blue: blue
                              ,purple: purple
                              ,brown: brown
                              ,lightRed: lightRed
                              ,lightOrange: lightOrange
                              ,lightYellow: lightYellow
                              ,lightGreen: lightGreen
                              ,lightBlue: lightBlue
                              ,lightPurple: lightPurple
                              ,lightBrown: lightBrown
                              ,darkRed: darkRed
                              ,darkOrange: darkOrange
                              ,darkYellow: darkYellow
                              ,darkGreen: darkGreen
                              ,darkBlue: darkBlue
                              ,darkPurple: darkPurple
                              ,darkBrown: darkBrown
                              ,white: white
                              ,lightGrey: lightGrey
                              ,grey: grey
                              ,darkGrey: darkGrey
                              ,lightCharcoal: lightCharcoal
                              ,charcoal: charcoal
                              ,darkCharcoal: darkCharcoal
                              ,black: black
                              ,lightGray: lightGray
                              ,gray: gray
                              ,darkGray: darkGray};
};

// setup
Elm.Native = Elm.Native || {};
Elm.Native.Graphics = Elm.Native.Graphics || {};
Elm.Native.Graphics.Element = Elm.Native.Graphics.Element || {};

// definition
Elm.Native.Graphics.Element.make = function(localRuntime) {
	'use strict';

	// attempt to short-circuit
	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Graphics = localRuntime.Native.Graphics || {};
	localRuntime.Native.Graphics.Element = localRuntime.Native.Graphics.Element || {};
	if ('values' in localRuntime.Native.Graphics.Element)
	{
		return localRuntime.Native.Graphics.Element.values;
	}

	var Color = Elm.Native.Color.make(localRuntime);
	var List = Elm.Native.List.make(localRuntime);
	var Maybe = Elm.Maybe.make(localRuntime);
	var Text = Elm.Native.Text.make(localRuntime);
	var Utils = Elm.Native.Utils.make(localRuntime);


	// CREATION

	var createNode =
		typeof document === 'undefined'
			?
				function(_)
				{
					return {
						style: {},
						appendChild: function() {}
					};
				}
			:
				function(elementType)
				{
					var node = document.createElement(elementType);
					node.style.padding = '0';
					node.style.margin = '0';
					return node;
				}
			;


	function newElement(width, height, elementPrim)
	{
		return {
			ctor: 'Element_elm_builtin',
			_0: {
				element: elementPrim,
				props: {
					id: Utils.guid(),
					width: width,
					height: height,
					opacity: 1,
					color: Maybe.Nothing,
					href: '',
					tag: '',
					hover: Utils.Tuple0,
					click: Utils.Tuple0
				}
			}
		};
	}


	// PROPERTIES

	function setProps(elem, node)
	{
		var props = elem.props;

		var element = elem.element;
		var width = props.width - (element.adjustWidth || 0);
		var height = props.height - (element.adjustHeight || 0);
		node.style.width  = (width | 0) + 'px';
		node.style.height = (height | 0) + 'px';

		if (props.opacity !== 1)
		{
			node.style.opacity = props.opacity;
		}

		if (props.color.ctor === 'Just')
		{
			node.style.backgroundColor = Color.toCss(props.color._0);
		}

		if (props.tag !== '')
		{
			node.id = props.tag;
		}

		if (props.hover.ctor !== '_Tuple0')
		{
			addHover(node, props.hover);
		}

		if (props.click.ctor !== '_Tuple0')
		{
			addClick(node, props.click);
		}

		if (props.href !== '')
		{
			var anchor = createNode('a');
			anchor.href = props.href;
			anchor.style.display = 'block';
			anchor.style.pointerEvents = 'auto';
			anchor.appendChild(node);
			node = anchor;
		}

		return node;
	}

	function addClick(e, handler)
	{
		e.style.pointerEvents = 'auto';
		e.elm_click_handler = handler;
		function trigger(ev)
		{
			e.elm_click_handler(Utils.Tuple0);
			ev.stopPropagation();
		}
		e.elm_click_trigger = trigger;
		e.addEventListener('click', trigger);
	}

	function removeClick(e, handler)
	{
		if (e.elm_click_trigger)
		{
			e.removeEventListener('click', e.elm_click_trigger);
			e.elm_click_trigger = null;
			e.elm_click_handler = null;
		}
	}

	function addHover(e, handler)
	{
		e.style.pointerEvents = 'auto';
		e.elm_hover_handler = handler;
		e.elm_hover_count = 0;

		function over(evt)
		{
			if (e.elm_hover_count++ > 0) return;
			e.elm_hover_handler(true);
			evt.stopPropagation();
		}
		function out(evt)
		{
			if (e.contains(evt.toElement || evt.relatedTarget)) return;
			e.elm_hover_count = 0;
			e.elm_hover_handler(false);
			evt.stopPropagation();
		}
		e.elm_hover_over = over;
		e.elm_hover_out = out;
		e.addEventListener('mouseover', over);
		e.addEventListener('mouseout', out);
	}

	function removeHover(e)
	{
		e.elm_hover_handler = null;
		if (e.elm_hover_over)
		{
			e.removeEventListener('mouseover', e.elm_hover_over);
			e.elm_hover_over = null;
		}
		if (e.elm_hover_out)
		{
			e.removeEventListener('mouseout', e.elm_hover_out);
			e.elm_hover_out = null;
		}
	}


	// IMAGES

	function image(props, img)
	{
		switch (img._0.ctor)
		{
			case 'Plain':
				return plainImage(img._3);

			case 'Fitted':
				return fittedImage(props.width, props.height, img._3);

			case 'Cropped':
				return croppedImage(img, props.width, props.height, img._3);

			case 'Tiled':
				return tiledImage(img._3);
		}
	}

	function plainImage(src)
	{
		var img = createNode('img');
		img.src = src;
		img.name = src;
		img.style.display = 'block';
		return img;
	}

	function tiledImage(src)
	{
		var div = createNode('div');
		div.style.backgroundImage = 'url(' + src + ')';
		return div;
	}

	function fittedImage(w, h, src)
	{
		var div = createNode('div');
		div.style.background = 'url(' + src + ') no-repeat center';
		div.style.webkitBackgroundSize = 'cover';
		div.style.MozBackgroundSize = 'cover';
		div.style.OBackgroundSize = 'cover';
		div.style.backgroundSize = 'cover';
		return div;
	}

	function croppedImage(elem, w, h, src)
	{
		var pos = elem._0._0;
		var e = createNode('div');
		e.style.overflow = 'hidden';

		var img = createNode('img');
		img.onload = function() {
			var sw = w / elem._1, sh = h / elem._2;
			img.style.width = ((this.width * sw) | 0) + 'px';
			img.style.height = ((this.height * sh) | 0) + 'px';
			img.style.marginLeft = ((- pos._0 * sw) | 0) + 'px';
			img.style.marginTop = ((- pos._1 * sh) | 0) + 'px';
		};
		img.src = src;
		img.name = src;
		e.appendChild(img);
		return e;
	}


	// FLOW

	function goOut(node)
	{
		node.style.position = 'absolute';
		return node;
	}
	function goDown(node)
	{
		return node;
	}
	function goRight(node)
	{
		node.style.styleFloat = 'left';
		node.style.cssFloat = 'left';
		return node;
	}

	var directionTable = {
		DUp: goDown,
		DDown: goDown,
		DLeft: goRight,
		DRight: goRight,
		DIn: goOut,
		DOut: goOut
	};
	function needsReversal(dir)
	{
		return dir === 'DUp' || dir === 'DLeft' || dir === 'DIn';
	}

	function flow(dir, elist)
	{
		var array = List.toArray(elist);
		var container = createNode('div');
		var goDir = directionTable[dir];
		if (goDir === goOut)
		{
			container.style.pointerEvents = 'none';
		}
		if (needsReversal(dir))
		{
			array.reverse();
		}
		var len = array.length;
		for (var i = 0; i < len; ++i)
		{
			container.appendChild(goDir(render(array[i])));
		}
		return container;
	}


	// CONTAINER

	function toPos(pos)
	{
		return pos.ctor === 'Absolute'
			? pos._0 + 'px'
			: (pos._0 * 100) + '%';
	}

	// must clear right, left, top, bottom, and transform
	// before calling this function
	function setPos(pos, wrappedElement, e)
	{
		var elem = wrappedElement._0;
		var element = elem.element;
		var props = elem.props;
		var w = props.width + (element.adjustWidth ? element.adjustWidth : 0);
		var h = props.height + (element.adjustHeight ? element.adjustHeight : 0);

		e.style.position = 'absolute';
		e.style.margin = 'auto';
		var transform = '';

		switch (pos.horizontal.ctor)
		{
			case 'P':
				e.style.right = toPos(pos.x);
				e.style.removeProperty('left');
				break;

			case 'Z':
				transform = 'translateX(' + ((-w / 2) | 0) + 'px) ';

			case 'N':
				e.style.left = toPos(pos.x);
				e.style.removeProperty('right');
				break;
		}
		switch (pos.vertical.ctor)
		{
			case 'N':
				e.style.bottom = toPos(pos.y);
				e.style.removeProperty('top');
				break;

			case 'Z':
				transform += 'translateY(' + ((-h / 2) | 0) + 'px)';

			case 'P':
				e.style.top = toPos(pos.y);
				e.style.removeProperty('bottom');
				break;
		}
		if (transform !== '')
		{
			addTransform(e.style, transform);
		}
		return e;
	}

	function addTransform(style, transform)
	{
		style.transform       = transform;
		style.msTransform     = transform;
		style.MozTransform    = transform;
		style.webkitTransform = transform;
		style.OTransform      = transform;
	}

	function container(pos, elem)
	{
		var e = render(elem);
		setPos(pos, elem, e);
		var div = createNode('div');
		div.style.position = 'relative';
		div.style.overflow = 'hidden';
		div.appendChild(e);
		return div;
	}


	function rawHtml(elem)
	{
		var html = elem.html;
		var align = elem.align;

		var div = createNode('div');
		div.innerHTML = html;
		div.style.visibility = 'hidden';
		if (align)
		{
			div.style.textAlign = align;
		}
		div.style.visibility = 'visible';
		div.style.pointerEvents = 'auto';
		return div;
	}


	// RENDER

	function render(wrappedElement)
	{
		var elem = wrappedElement._0;
		return setProps(elem, makeElement(elem));
	}

	function makeElement(e)
	{
		var elem = e.element;
		switch (elem.ctor)
		{
			case 'Image':
				return image(e.props, elem);

			case 'Flow':
				return flow(elem._0.ctor, elem._1);

			case 'Container':
				return container(elem._0, elem._1);

			case 'Spacer':
				return createNode('div');

			case 'RawHtml':
				return rawHtml(elem);

			case 'Custom':
				return elem.render(elem.model);
		}
	}

	function updateAndReplace(node, curr, next)
	{
		var newNode = update(node, curr, next);
		if (newNode !== node)
		{
			node.parentNode.replaceChild(newNode, node);
		}
		return newNode;
	}


	// UPDATE

	function update(node, wrappedCurrent, wrappedNext)
	{
		var curr = wrappedCurrent._0;
		var next = wrappedNext._0;
		var rootNode = node;
		if (node.tagName === 'A')
		{
			node = node.firstChild;
		}
		if (curr.props.id === next.props.id)
		{
			updateProps(node, curr, next);
			return rootNode;
		}
		if (curr.element.ctor !== next.element.ctor)
		{
			return render(wrappedNext);
		}
		var nextE = next.element;
		var currE = curr.element;
		switch (nextE.ctor)
		{
			case 'Spacer':
				updateProps(node, curr, next);
				return rootNode;

			case 'RawHtml':
				if(currE.html.valueOf() !== nextE.html.valueOf())
				{
					node.innerHTML = nextE.html;
				}
				updateProps(node, curr, next);
				return rootNode;

			case 'Image':
				if (nextE._0.ctor === 'Plain')
				{
					if (nextE._3 !== currE._3)
					{
						node.src = nextE._3;
					}
				}
				else if (!Utils.eq(nextE, currE)
					|| next.props.width !== curr.props.width
					|| next.props.height !== curr.props.height)
				{
					return render(wrappedNext);
				}
				updateProps(node, curr, next);
				return rootNode;

			case 'Flow':
				var arr = List.toArray(nextE._1);
				for (var i = arr.length; i--; )
				{
					arr[i] = arr[i]._0.element.ctor;
				}
				if (nextE._0.ctor !== currE._0.ctor)
				{
					return render(wrappedNext);
				}
				var nexts = List.toArray(nextE._1);
				var kids = node.childNodes;
				if (nexts.length !== kids.length)
				{
					return render(wrappedNext);
				}
				var currs = List.toArray(currE._1);
				var dir = nextE._0.ctor;
				var goDir = directionTable[dir];
				var toReverse = needsReversal(dir);
				var len = kids.length;
				for (var i = len; i--; )
				{
					var subNode = kids[toReverse ? len - i - 1 : i];
					goDir(updateAndReplace(subNode, currs[i], nexts[i]));
				}
				updateProps(node, curr, next);
				return rootNode;

			case 'Container':
				var subNode = node.firstChild;
				var newSubNode = updateAndReplace(subNode, currE._1, nextE._1);
				setPos(nextE._0, nextE._1, newSubNode);
				updateProps(node, curr, next);
				return rootNode;

			case 'Custom':
				if (currE.type === nextE.type)
				{
					var updatedNode = nextE.update(node, currE.model, nextE.model);
					updateProps(updatedNode, curr, next);
					return updatedNode;
				}
				return render(wrappedNext);
		}
	}

	function updateProps(node, curr, next)
	{
		var nextProps = next.props;
		var currProps = curr.props;

		var element = next.element;
		var width = nextProps.width - (element.adjustWidth || 0);
		var height = nextProps.height - (element.adjustHeight || 0);
		if (width !== currProps.width)
		{
			node.style.width = (width | 0) + 'px';
		}
		if (height !== currProps.height)
		{
			node.style.height = (height | 0) + 'px';
		}

		if (nextProps.opacity !== currProps.opacity)
		{
			node.style.opacity = nextProps.opacity;
		}

		var nextColor = nextProps.color.ctor === 'Just'
			? Color.toCss(nextProps.color._0)
			: '';
		if (node.style.backgroundColor !== nextColor)
		{
			node.style.backgroundColor = nextColor;
		}

		if (nextProps.tag !== currProps.tag)
		{
			node.id = nextProps.tag;
		}

		if (nextProps.href !== currProps.href)
		{
			if (currProps.href === '')
			{
				// add a surrounding href
				var anchor = createNode('a');
				anchor.href = nextProps.href;
				anchor.style.display = 'block';
				anchor.style.pointerEvents = 'auto';

				node.parentNode.replaceChild(anchor, node);
				anchor.appendChild(node);
			}
			else if (nextProps.href === '')
			{
				// remove the surrounding href
				var anchor = node.parentNode;
				anchor.parentNode.replaceChild(node, anchor);
			}
			else
			{
				// just update the link
				node.parentNode.href = nextProps.href;
			}
		}

		// update click and hover handlers
		var removed = false;

		// update hover handlers
		if (currProps.hover.ctor === '_Tuple0')
		{
			if (nextProps.hover.ctor !== '_Tuple0')
			{
				addHover(node, nextProps.hover);
			}
		}
		else
		{
			if (nextProps.hover.ctor === '_Tuple0')
			{
				removed = true;
				removeHover(node);
			}
			else
			{
				node.elm_hover_handler = nextProps.hover;
			}
		}

		// update click handlers
		if (currProps.click.ctor === '_Tuple0')
		{
			if (nextProps.click.ctor !== '_Tuple0')
			{
				addClick(node, nextProps.click);
			}
		}
		else
		{
			if (nextProps.click.ctor === '_Tuple0')
			{
				removed = true;
				removeClick(node);
			}
			else
			{
				node.elm_click_handler = nextProps.click;
			}
		}

		// stop capturing clicks if
		if (removed
			&& nextProps.hover.ctor === '_Tuple0'
			&& nextProps.click.ctor === '_Tuple0')
		{
			node.style.pointerEvents = 'none';
		}
	}


	// TEXT

	function block(align)
	{
		return function(text)
		{
			var raw = {
				ctor: 'RawHtml',
				html: Text.renderHtml(text),
				align: align
			};
			var pos = htmlHeight(0, raw);
			return newElement(pos._0, pos._1, raw);
		};
	}

	function markdown(text)
	{
		var raw = {
			ctor: 'RawHtml',
			html: text,
			align: null
		};
		var pos = htmlHeight(0, raw);
		return newElement(pos._0, pos._1, raw);
	}

	var htmlHeight =
		typeof document !== 'undefined'
			? realHtmlHeight
			: function(a, b) { return Utils.Tuple2(0, 0); };

	function realHtmlHeight(width, rawHtml)
	{
		// create dummy node
		var temp = document.createElement('div');
		temp.innerHTML = rawHtml.html;
		if (width > 0)
		{
			temp.style.width = width + 'px';
		}
		temp.style.visibility = 'hidden';
		temp.style.styleFloat = 'left';
		temp.style.cssFloat = 'left';

		document.body.appendChild(temp);

		// get dimensions
		var style = window.getComputedStyle(temp, null);
		var w = Math.ceil(style.getPropertyValue('width').slice(0, -2) - 0);
		var h = Math.ceil(style.getPropertyValue('height').slice(0, -2) - 0);
		document.body.removeChild(temp);
		return Utils.Tuple2(w, h);
	}


	return localRuntime.Native.Graphics.Element.values = {
		render: render,
		update: update,
		updateAndReplace: updateAndReplace,

		createNode: createNode,
		newElement: F3(newElement),
		addTransform: addTransform,
		htmlHeight: F2(htmlHeight),
		guid: Utils.guid,

		block: block,
		markdown: markdown
	};
};

Elm.Native.Text = {};
Elm.Native.Text.make = function(localRuntime) {
	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Text = localRuntime.Native.Text || {};
	if (localRuntime.Native.Text.values)
	{
		return localRuntime.Native.Text.values;
	}

	var toCss = Elm.Native.Color.make(localRuntime).toCss;
	var List = Elm.Native.List.make(localRuntime);


	// CONSTRUCTORS

	function fromString(str)
	{
		return {
			ctor: 'Text:Text',
			_0: str
		};
	}

	function append(a, b)
	{
		return {
			ctor: 'Text:Append',
			_0: a,
			_1: b
		};
	}

	function addMeta(field, value, text)
	{
		var newProps = {};
		var newText = {
			ctor: 'Text:Meta',
			_0: newProps,
			_1: text
		};

		if (text.ctor === 'Text:Meta')
		{
			newText._1 = text._1;
			var props = text._0;
			for (var i = metaKeys.length; i--; )
			{
				var key = metaKeys[i];
				var val = props[key];
				if (val)
				{
					newProps[key] = val;
				}
			}
		}
		newProps[field] = value;
		return newText;
	}

	var metaKeys = [
		'font-size',
		'font-family',
		'font-style',
		'font-weight',
		'href',
		'text-decoration',
		'color'
	];


	// conversions from Elm values to CSS

	function toTypefaces(list)
	{
		var typefaces = List.toArray(list);
		for (var i = typefaces.length; i--; )
		{
			var typeface = typefaces[i];
			if (typeface.indexOf(' ') > -1)
			{
				typefaces[i] = "'" + typeface + "'";
			}
		}
		return typefaces.join(',');
	}

	function toLine(line)
	{
		var ctor = line.ctor;
		return ctor === 'Under'
			? 'underline'
			: ctor === 'Over'
				? 'overline'
				: 'line-through';
	}

	// setting styles of Text

	function style(style, text)
	{
		var newText = addMeta('color', toCss(style.color), text);
		var props = newText._0;

		if (style.typeface.ctor !== '[]')
		{
			props['font-family'] = toTypefaces(style.typeface);
		}
		if (style.height.ctor !== 'Nothing')
		{
			props['font-size'] = style.height._0 + 'px';
		}
		if (style.bold)
		{
			props['font-weight'] = 'bold';
		}
		if (style.italic)
		{
			props['font-style'] = 'italic';
		}
		if (style.line.ctor !== 'Nothing')
		{
			props['text-decoration'] = toLine(style.line._0);
		}
		return newText;
	}

	function height(px, text)
	{
		return addMeta('font-size', px + 'px', text);
	}

	function typeface(names, text)
	{
		return addMeta('font-family', toTypefaces(names), text);
	}

	function monospace(text)
	{
		return addMeta('font-family', 'monospace', text);
	}

	function italic(text)
	{
		return addMeta('font-style', 'italic', text);
	}

	function bold(text)
	{
		return addMeta('font-weight', 'bold', text);
	}

	function link(href, text)
	{
		return addMeta('href', href, text);
	}

	function line(line, text)
	{
		return addMeta('text-decoration', toLine(line), text);
	}

	function color(color, text)
	{
		return addMeta('color', toCss(color), text);
	}


	// RENDER

	function renderHtml(text)
	{
		var tag = text.ctor;
		if (tag === 'Text:Append')
		{
			return renderHtml(text._0) + renderHtml(text._1);
		}
		if (tag === 'Text:Text')
		{
			return properEscape(text._0);
		}
		if (tag === 'Text:Meta')
		{
			return renderMeta(text._0, renderHtml(text._1));
		}
	}

	function renderMeta(metas, string)
	{
		var href = metas.href;
		if (href)
		{
			string = '<a href="' + href + '">' + string + '</a>';
		}
		var styles = '';
		for (var key in metas)
		{
			if (key === 'href')
			{
				continue;
			}
			styles += key + ':' + metas[key] + ';';
		}
		if (styles)
		{
			string = '<span style="' + styles + '">' + string + '</span>';
		}
		return string;
	}

	function properEscape(str)
	{
		if (str.length === 0)
		{
			return str;
		}
		str = str //.replace(/&/g,  '&#38;')
			.replace(/"/g,  '&#34;')
			.replace(/'/g,  '&#39;')
			.replace(/</g,  '&#60;')
			.replace(/>/g,  '&#62;');
		var arr = str.split('\n');
		for (var i = arr.length; i--; )
		{
			arr[i] = makeSpaces(arr[i]);
		}
		return arr.join('<br/>');
	}

	function makeSpaces(s)
	{
		if (s.length === 0)
		{
			return s;
		}
		var arr = s.split('');
		if (arr[0] === ' ')
		{
			arr[0] = '&nbsp;';
		}
		for (var i = arr.length; --i; )
		{
			if (arr[i][0] === ' ' && arr[i - 1] === ' ')
			{
				arr[i - 1] = arr[i - 1] + arr[i];
				arr[i] = '';
			}
		}
		for (var i = arr.length; i--; )
		{
			if (arr[i].length > 1 && arr[i][0] === ' ')
			{
				var spaces = arr[i].split('');
				for (var j = spaces.length - 2; j >= 0; j -= 2)
				{
					spaces[j] = '&nbsp;';
				}
				arr[i] = spaces.join('');
			}
		}
		arr = arr.join('');
		if (arr[arr.length - 1] === ' ')
		{
			return arr.slice(0, -1) + '&nbsp;';
		}
		return arr;
	}


	return localRuntime.Native.Text.values = {
		fromString: fromString,
		append: F2(append),

		height: F2(height),
		italic: italic,
		bold: bold,
		line: F2(line),
		monospace: monospace,
		typeface: F2(typeface),
		color: F2(color),
		link: F2(link),
		style: F2(style),

		toTypefaces: toTypefaces,
		toLine: toLine,
		renderHtml: renderHtml
	};
};

Elm.Text = Elm.Text || {};
Elm.Text.make = function (_elm) {
   "use strict";
   _elm.Text = _elm.Text || {};
   if (_elm.Text.values) return _elm.Text.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Color = Elm.Color.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Native$Text = Elm.Native.Text.make(_elm);
   var _op = {};
   var line = $Native$Text.line;
   var italic = $Native$Text.italic;
   var bold = $Native$Text.bold;
   var color = $Native$Text.color;
   var height = $Native$Text.height;
   var link = $Native$Text.link;
   var monospace = $Native$Text.monospace;
   var typeface = $Native$Text.typeface;
   var style = $Native$Text.style;
   var append = $Native$Text.append;
   var fromString = $Native$Text.fromString;
   var empty = fromString("");
   var concat = function (texts) {
      return A3($List.foldr,append,empty,texts);
   };
   var join = F2(function (seperator,texts) {
      return concat(A2($List.intersperse,seperator,texts));
   });
   var defaultStyle = {typeface: _U.list([])
                      ,height: $Maybe.Nothing
                      ,color: $Color.black
                      ,bold: false
                      ,italic: false
                      ,line: $Maybe.Nothing};
   var Style = F6(function (a,b,c,d,e,f) {
      return {typeface: a
             ,height: b
             ,color: c
             ,bold: d
             ,italic: e
             ,line: f};
   });
   var Through = {ctor: "Through"};
   var Over = {ctor: "Over"};
   var Under = {ctor: "Under"};
   var Text = {ctor: "Text"};
   return _elm.Text.values = {_op: _op
                             ,fromString: fromString
                             ,empty: empty
                             ,append: append
                             ,concat: concat
                             ,join: join
                             ,link: link
                             ,style: style
                             ,defaultStyle: defaultStyle
                             ,typeface: typeface
                             ,monospace: monospace
                             ,height: height
                             ,color: color
                             ,bold: bold
                             ,italic: italic
                             ,line: line
                             ,Style: Style
                             ,Under: Under
                             ,Over: Over
                             ,Through: Through};
};
Elm.Graphics = Elm.Graphics || {};
Elm.Graphics.Element = Elm.Graphics.Element || {};
Elm.Graphics.Element.make = function (_elm) {
   "use strict";
   _elm.Graphics = _elm.Graphics || {};
   _elm.Graphics.Element = _elm.Graphics.Element || {};
   if (_elm.Graphics.Element.values)
   return _elm.Graphics.Element.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Color = Elm.Color.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Native$Graphics$Element = Elm.Native.Graphics.Element.make(_elm),
   $Text = Elm.Text.make(_elm);
   var _op = {};
   var DOut = {ctor: "DOut"};
   var outward = DOut;
   var DIn = {ctor: "DIn"};
   var inward = DIn;
   var DRight = {ctor: "DRight"};
   var right = DRight;
   var DLeft = {ctor: "DLeft"};
   var left = DLeft;
   var DDown = {ctor: "DDown"};
   var down = DDown;
   var DUp = {ctor: "DUp"};
   var up = DUp;
   var RawPosition = F4(function (a,b,c,d) {
      return {horizontal: a,vertical: b,x: c,y: d};
   });
   var Position = function (a) {
      return {ctor: "Position",_0: a};
   };
   var Relative = function (a) {
      return {ctor: "Relative",_0: a};
   };
   var relative = Relative;
   var Absolute = function (a) {
      return {ctor: "Absolute",_0: a};
   };
   var absolute = Absolute;
   var N = {ctor: "N"};
   var bottomLeft = Position({horizontal: N
                             ,vertical: N
                             ,x: Absolute(0)
                             ,y: Absolute(0)});
   var bottomLeftAt = F2(function (x,y) {
      return Position({horizontal: N,vertical: N,x: x,y: y});
   });
   var Z = {ctor: "Z"};
   var middle = Position({horizontal: Z
                         ,vertical: Z
                         ,x: Relative(0.5)
                         ,y: Relative(0.5)});
   var midLeft = Position({horizontal: N
                          ,vertical: Z
                          ,x: Absolute(0)
                          ,y: Relative(0.5)});
   var midBottom = Position({horizontal: Z
                            ,vertical: N
                            ,x: Relative(0.5)
                            ,y: Absolute(0)});
   var middleAt = F2(function (x,y) {
      return Position({horizontal: Z,vertical: Z,x: x,y: y});
   });
   var midLeftAt = F2(function (x,y) {
      return Position({horizontal: N,vertical: Z,x: x,y: y});
   });
   var midBottomAt = F2(function (x,y) {
      return Position({horizontal: Z,vertical: N,x: x,y: y});
   });
   var P = {ctor: "P"};
   var topLeft = Position({horizontal: N
                          ,vertical: P
                          ,x: Absolute(0)
                          ,y: Absolute(0)});
   var topRight = Position({horizontal: P
                           ,vertical: P
                           ,x: Absolute(0)
                           ,y: Absolute(0)});
   var bottomRight = Position({horizontal: P
                              ,vertical: N
                              ,x: Absolute(0)
                              ,y: Absolute(0)});
   var midRight = Position({horizontal: P
                           ,vertical: Z
                           ,x: Absolute(0)
                           ,y: Relative(0.5)});
   var midTop = Position({horizontal: Z
                         ,vertical: P
                         ,x: Relative(0.5)
                         ,y: Absolute(0)});
   var topLeftAt = F2(function (x,y) {
      return Position({horizontal: N,vertical: P,x: x,y: y});
   });
   var topRightAt = F2(function (x,y) {
      return Position({horizontal: P,vertical: P,x: x,y: y});
   });
   var bottomRightAt = F2(function (x,y) {
      return Position({horizontal: P,vertical: N,x: x,y: y});
   });
   var midRightAt = F2(function (x,y) {
      return Position({horizontal: P,vertical: Z,x: x,y: y});
   });
   var midTopAt = F2(function (x,y) {
      return Position({horizontal: Z,vertical: P,x: x,y: y});
   });
   var justified = $Native$Graphics$Element.block("justify");
   var centered = $Native$Graphics$Element.block("center");
   var rightAligned = $Native$Graphics$Element.block("right");
   var leftAligned = $Native$Graphics$Element.block("left");
   var show = function (value) {
      return leftAligned($Text.monospace($Text.fromString($Basics.toString(value))));
   };
   var Tiled = {ctor: "Tiled"};
   var Cropped = function (a) {
      return {ctor: "Cropped",_0: a};
   };
   var Fitted = {ctor: "Fitted"};
   var Plain = {ctor: "Plain"};
   var Custom = {ctor: "Custom"};
   var RawHtml = {ctor: "RawHtml"};
   var Spacer = {ctor: "Spacer"};
   var Flow = F2(function (a,b) {
      return {ctor: "Flow",_0: a,_1: b};
   });
   var Container = F2(function (a,b) {
      return {ctor: "Container",_0: a,_1: b};
   });
   var Image = F4(function (a,b,c,d) {
      return {ctor: "Image",_0: a,_1: b,_2: c,_3: d};
   });
   var newElement = $Native$Graphics$Element.newElement;
   var image = F3(function (w,h,src) {
      return A3(newElement,w,h,A4(Image,Plain,w,h,src));
   });
   var fittedImage = F3(function (w,h,src) {
      return A3(newElement,w,h,A4(Image,Fitted,w,h,src));
   });
   var croppedImage = F4(function (pos,w,h,src) {
      return A3(newElement,w,h,A4(Image,Cropped(pos),w,h,src));
   });
   var tiledImage = F3(function (w,h,src) {
      return A3(newElement,w,h,A4(Image,Tiled,w,h,src));
   });
   var container = F4(function (w,h,_p0,e) {
      var _p1 = _p0;
      return A3(newElement,w,h,A2(Container,_p1._0,e));
   });
   var spacer = F2(function (w,h) {
      return A3(newElement,w,h,Spacer);
   });
   var sizeOf = function (_p2) {
      var _p3 = _p2;
      var _p4 = _p3._0;
      return {ctor: "_Tuple2"
             ,_0: _p4.props.width
             ,_1: _p4.props.height};
   };
   var heightOf = function (_p5) {
      var _p6 = _p5;
      return _p6._0.props.height;
   };
   var widthOf = function (_p7) {
      var _p8 = _p7;
      return _p8._0.props.width;
   };
   var above = F2(function (hi,lo) {
      return A3(newElement,
      A2($Basics.max,widthOf(hi),widthOf(lo)),
      heightOf(hi) + heightOf(lo),
      A2(Flow,DDown,_U.list([hi,lo])));
   });
   var below = F2(function (lo,hi) {
      return A3(newElement,
      A2($Basics.max,widthOf(hi),widthOf(lo)),
      heightOf(hi) + heightOf(lo),
      A2(Flow,DDown,_U.list([hi,lo])));
   });
   var beside = F2(function (lft,rht) {
      return A3(newElement,
      widthOf(lft) + widthOf(rht),
      A2($Basics.max,heightOf(lft),heightOf(rht)),
      A2(Flow,right,_U.list([lft,rht])));
   });
   var layers = function (es) {
      var hs = A2($List.map,heightOf,es);
      var ws = A2($List.map,widthOf,es);
      return A3(newElement,
      A2($Maybe.withDefault,0,$List.maximum(ws)),
      A2($Maybe.withDefault,0,$List.maximum(hs)),
      A2(Flow,DOut,es));
   };
   var empty = A2(spacer,0,0);
   var flow = F2(function (dir,es) {
      var newFlow = F2(function (w,h) {
         return A3(newElement,w,h,A2(Flow,dir,es));
      });
      var maxOrZero = function (list) {
         return A2($Maybe.withDefault,0,$List.maximum(list));
      };
      var hs = A2($List.map,heightOf,es);
      var ws = A2($List.map,widthOf,es);
      if (_U.eq(es,_U.list([]))) return empty; else {
            var _p9 = dir;
            switch (_p9.ctor)
            {case "DUp": return A2(newFlow,maxOrZero(ws),$List.sum(hs));
               case "DDown": return A2(newFlow,maxOrZero(ws),$List.sum(hs));
               case "DLeft": return A2(newFlow,$List.sum(ws),maxOrZero(hs));
               case "DRight": return A2(newFlow,$List.sum(ws),maxOrZero(hs));
               case "DIn": return A2(newFlow,maxOrZero(ws),maxOrZero(hs));
               default: return A2(newFlow,maxOrZero(ws),maxOrZero(hs));}
         }
   });
   var Properties = F9(function (a,b,c,d,e,f,g,h,i) {
      return {id: a
             ,width: b
             ,height: c
             ,opacity: d
             ,color: e
             ,href: f
             ,tag: g
             ,hover: h
             ,click: i};
   });
   var Element_elm_builtin = function (a) {
      return {ctor: "Element_elm_builtin",_0: a};
   };
   var width = F2(function (newWidth,_p10) {
      var _p11 = _p10;
      var _p14 = _p11._0.props;
      var _p13 = _p11._0.element;
      var newHeight = function () {
         var _p12 = _p13;
         switch (_p12.ctor)
         {case "Image":
            return $Basics.round($Basics.toFloat(_p12._2) / $Basics.toFloat(_p12._1) * $Basics.toFloat(newWidth));
            case "RawHtml":
            return $Basics.snd(A2($Native$Graphics$Element.htmlHeight,
              newWidth,
              _p13));
            default: return _p14.height;}
      }();
      return Element_elm_builtin({element: _p13
                                 ,props: _U.update(_p14,{width: newWidth,height: newHeight})});
   });
   var height = F2(function (newHeight,_p15) {
      var _p16 = _p15;
      return Element_elm_builtin({element: _p16._0.element
                                 ,props: _U.update(_p16._0.props,{height: newHeight})});
   });
   var size = F3(function (w,h,e) {
      return A2(height,h,A2(width,w,e));
   });
   var opacity = F2(function (givenOpacity,_p17) {
      var _p18 = _p17;
      return Element_elm_builtin({element: _p18._0.element
                                 ,props: _U.update(_p18._0.props,{opacity: givenOpacity})});
   });
   var color = F2(function (clr,_p19) {
      var _p20 = _p19;
      return Element_elm_builtin({element: _p20._0.element
                                 ,props: _U.update(_p20._0.props,{color: $Maybe.Just(clr)})});
   });
   var tag = F2(function (name,_p21) {
      var _p22 = _p21;
      return Element_elm_builtin({element: _p22._0.element
                                 ,props: _U.update(_p22._0.props,{tag: name})});
   });
   var link = F2(function (href,_p23) {
      var _p24 = _p23;
      return Element_elm_builtin({element: _p24._0.element
                                 ,props: _U.update(_p24._0.props,{href: href})});
   });
   return _elm.Graphics.Element.values = {_op: _op
                                         ,image: image
                                         ,fittedImage: fittedImage
                                         ,croppedImage: croppedImage
                                         ,tiledImage: tiledImage
                                         ,leftAligned: leftAligned
                                         ,rightAligned: rightAligned
                                         ,centered: centered
                                         ,justified: justified
                                         ,show: show
                                         ,width: width
                                         ,height: height
                                         ,size: size
                                         ,color: color
                                         ,opacity: opacity
                                         ,link: link
                                         ,tag: tag
                                         ,widthOf: widthOf
                                         ,heightOf: heightOf
                                         ,sizeOf: sizeOf
                                         ,flow: flow
                                         ,up: up
                                         ,down: down
                                         ,left: left
                                         ,right: right
                                         ,inward: inward
                                         ,outward: outward
                                         ,layers: layers
                                         ,above: above
                                         ,below: below
                                         ,beside: beside
                                         ,empty: empty
                                         ,spacer: spacer
                                         ,container: container
                                         ,middle: middle
                                         ,midTop: midTop
                                         ,midBottom: midBottom
                                         ,midLeft: midLeft
                                         ,midRight: midRight
                                         ,topLeft: topLeft
                                         ,topRight: topRight
                                         ,bottomLeft: bottomLeft
                                         ,bottomRight: bottomRight
                                         ,absolute: absolute
                                         ,relative: relative
                                         ,middleAt: middleAt
                                         ,midTopAt: midTopAt
                                         ,midBottomAt: midBottomAt
                                         ,midLeftAt: midLeftAt
                                         ,midRightAt: midRightAt
                                         ,topLeftAt: topLeftAt
                                         ,topRightAt: topRightAt
                                         ,bottomLeftAt: bottomLeftAt
                                         ,bottomRightAt: bottomRightAt};
};
Elm.Graphics = Elm.Graphics || {};
Elm.Graphics.Collage = Elm.Graphics.Collage || {};
Elm.Graphics.Collage.make = function (_elm) {
   "use strict";
   _elm.Graphics = _elm.Graphics || {};
   _elm.Graphics.Collage = _elm.Graphics.Collage || {};
   if (_elm.Graphics.Collage.values)
   return _elm.Graphics.Collage.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Color = Elm.Color.make(_elm),
   $Graphics$Element = Elm.Graphics.Element.make(_elm),
   $List = Elm.List.make(_elm),
   $Native$Graphics$Collage = Elm.Native.Graphics.Collage.make(_elm),
   $Text = Elm.Text.make(_elm),
   $Transform2D = Elm.Transform2D.make(_elm);
   var _op = {};
   var Shape = function (a) {    return {ctor: "Shape",_0: a};};
   var polygon = function (points) {    return Shape(points);};
   var rect = F2(function (w,h) {
      var hh = h / 2;
      var hw = w / 2;
      return Shape(_U.list([{ctor: "_Tuple2",_0: 0 - hw,_1: 0 - hh}
                           ,{ctor: "_Tuple2",_0: 0 - hw,_1: hh}
                           ,{ctor: "_Tuple2",_0: hw,_1: hh}
                           ,{ctor: "_Tuple2",_0: hw,_1: 0 - hh}]));
   });
   var square = function (n) {    return A2(rect,n,n);};
   var oval = F2(function (w,h) {
      var hh = h / 2;
      var hw = w / 2;
      var n = 50;
      var t = 2 * $Basics.pi / n;
      var f = function (i) {
         return {ctor: "_Tuple2"
                ,_0: hw * $Basics.cos(t * i)
                ,_1: hh * $Basics.sin(t * i)};
      };
      return Shape(A2($List.map,f,_U.range(0,n - 1)));
   });
   var circle = function (r) {    return A2(oval,2 * r,2 * r);};
   var ngon = F2(function (n,r) {
      var m = $Basics.toFloat(n);
      var t = 2 * $Basics.pi / m;
      var f = function (i) {
         return {ctor: "_Tuple2"
                ,_0: r * $Basics.cos(t * i)
                ,_1: r * $Basics.sin(t * i)};
      };
      return Shape(A2($List.map,f,_U.range(0,m - 1)));
   });
   var Path = function (a) {    return {ctor: "Path",_0: a};};
   var path = function (ps) {    return Path(ps);};
   var segment = F2(function (p1,p2) {
      return Path(_U.list([p1,p2]));
   });
   var collage = $Native$Graphics$Collage.collage;
   var Fill = function (a) {    return {ctor: "Fill",_0: a};};
   var Line = function (a) {    return {ctor: "Line",_0: a};};
   var FGroup = F2(function (a,b) {
      return {ctor: "FGroup",_0: a,_1: b};
   });
   var FElement = function (a) {
      return {ctor: "FElement",_0: a};
   };
   var FImage = F4(function (a,b,c,d) {
      return {ctor: "FImage",_0: a,_1: b,_2: c,_3: d};
   });
   var FText = function (a) {    return {ctor: "FText",_0: a};};
   var FOutlinedText = F2(function (a,b) {
      return {ctor: "FOutlinedText",_0: a,_1: b};
   });
   var FShape = F2(function (a,b) {
      return {ctor: "FShape",_0: a,_1: b};
   });
   var FPath = F2(function (a,b) {
      return {ctor: "FPath",_0: a,_1: b};
   });
   var LineStyle = F6(function (a,b,c,d,e,f) {
      return {color: a
             ,width: b
             ,cap: c
             ,join: d
             ,dashing: e
             ,dashOffset: f};
   });
   var Clipped = {ctor: "Clipped"};
   var Sharp = function (a) {    return {ctor: "Sharp",_0: a};};
   var Smooth = {ctor: "Smooth"};
   var Padded = {ctor: "Padded"};
   var Round = {ctor: "Round"};
   var Flat = {ctor: "Flat"};
   var defaultLine = {color: $Color.black
                     ,width: 1
                     ,cap: Flat
                     ,join: Sharp(10)
                     ,dashing: _U.list([])
                     ,dashOffset: 0};
   var solid = function (clr) {
      return _U.update(defaultLine,{color: clr});
   };
   var dashed = function (clr) {
      return _U.update(defaultLine,
      {color: clr,dashing: _U.list([8,4])});
   };
   var dotted = function (clr) {
      return _U.update(defaultLine,
      {color: clr,dashing: _U.list([3,3])});
   };
   var Grad = function (a) {    return {ctor: "Grad",_0: a};};
   var Texture = function (a) {
      return {ctor: "Texture",_0: a};
   };
   var Solid = function (a) {    return {ctor: "Solid",_0: a};};
   var Form_elm_builtin = function (a) {
      return {ctor: "Form_elm_builtin",_0: a};
   };
   var form = function (f) {
      return Form_elm_builtin({theta: 0
                              ,scale: 1
                              ,x: 0
                              ,y: 0
                              ,alpha: 1
                              ,form: f});
   };
   var fill = F2(function (style,_p0) {
      var _p1 = _p0;
      return form(A2(FShape,Fill(style),_p1._0));
   });
   var filled = F2(function (color,shape) {
      return A2(fill,Solid(color),shape);
   });
   var textured = F2(function (src,shape) {
      return A2(fill,Texture(src),shape);
   });
   var gradient = F2(function (grad,shape) {
      return A2(fill,Grad(grad),shape);
   });
   var outlined = F2(function (style,_p2) {
      var _p3 = _p2;
      return form(A2(FShape,Line(style),_p3._0));
   });
   var traced = F2(function (style,_p4) {
      var _p5 = _p4;
      return form(A2(FPath,style,_p5._0));
   });
   var sprite = F4(function (w,h,pos,src) {
      return form(A4(FImage,w,h,pos,src));
   });
   var toForm = function (e) {    return form(FElement(e));};
   var group = function (fs) {
      return form(A2(FGroup,$Transform2D.identity,fs));
   };
   var groupTransform = F2(function (matrix,fs) {
      return form(A2(FGroup,matrix,fs));
   });
   var text = function (t) {    return form(FText(t));};
   var outlinedText = F2(function (ls,t) {
      return form(A2(FOutlinedText,ls,t));
   });
   var move = F2(function (_p7,_p6) {
      var _p8 = _p7;
      var _p9 = _p6;
      var _p10 = _p9._0;
      return Form_elm_builtin(_U.update(_p10,
      {x: _p10.x + _p8._0,y: _p10.y + _p8._1}));
   });
   var moveX = F2(function (x,_p11) {
      var _p12 = _p11;
      var _p13 = _p12._0;
      return Form_elm_builtin(_U.update(_p13,{x: _p13.x + x}));
   });
   var moveY = F2(function (y,_p14) {
      var _p15 = _p14;
      var _p16 = _p15._0;
      return Form_elm_builtin(_U.update(_p16,{y: _p16.y + y}));
   });
   var scale = F2(function (s,_p17) {
      var _p18 = _p17;
      var _p19 = _p18._0;
      return Form_elm_builtin(_U.update(_p19,
      {scale: _p19.scale * s}));
   });
   var rotate = F2(function (t,_p20) {
      var _p21 = _p20;
      var _p22 = _p21._0;
      return Form_elm_builtin(_U.update(_p22,
      {theta: _p22.theta + t}));
   });
   var alpha = F2(function (a,_p23) {
      var _p24 = _p23;
      return Form_elm_builtin(_U.update(_p24._0,{alpha: a}));
   });
   return _elm.Graphics.Collage.values = {_op: _op
                                         ,collage: collage
                                         ,toForm: toForm
                                         ,filled: filled
                                         ,textured: textured
                                         ,gradient: gradient
                                         ,outlined: outlined
                                         ,traced: traced
                                         ,text: text
                                         ,outlinedText: outlinedText
                                         ,move: move
                                         ,moveX: moveX
                                         ,moveY: moveY
                                         ,scale: scale
                                         ,rotate: rotate
                                         ,alpha: alpha
                                         ,group: group
                                         ,groupTransform: groupTransform
                                         ,rect: rect
                                         ,oval: oval
                                         ,square: square
                                         ,circle: circle
                                         ,ngon: ngon
                                         ,polygon: polygon
                                         ,segment: segment
                                         ,path: path
                                         ,solid: solid
                                         ,dashed: dashed
                                         ,dotted: dotted
                                         ,defaultLine: defaultLine
                                         ,LineStyle: LineStyle
                                         ,Flat: Flat
                                         ,Round: Round
                                         ,Padded: Padded
                                         ,Smooth: Smooth
                                         ,Sharp: Sharp
                                         ,Clipped: Clipped};
};
Elm.Native.Debug = {};
Elm.Native.Debug.make = function(localRuntime) {
	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Debug = localRuntime.Native.Debug || {};
	if (localRuntime.Native.Debug.values)
	{
		return localRuntime.Native.Debug.values;
	}

	var toString = Elm.Native.Utils.make(localRuntime).toString;

	function log(tag, value)
	{
		var msg = tag + ': ' + toString(value);
		var process = process || {};
		if (process.stdout)
		{
			process.stdout.write(msg);
		}
		else
		{
			console.log(msg);
		}
		return value;
	}

	function crash(message)
	{
		throw new Error(message);
	}

	function tracePath(tag, form)
	{
		if (localRuntime.debug)
		{
			return localRuntime.debug.trace(tag, form);
		}
		return form;
	}

	function watch(tag, value)
	{
		if (localRuntime.debug)
		{
			localRuntime.debug.watch(tag, value);
		}
		return value;
	}

	function watchSummary(tag, summarize, value)
	{
		if (localRuntime.debug)
		{
			localRuntime.debug.watch(tag, summarize(value));
		}
		return value;
	}

	return localRuntime.Native.Debug.values = {
		crash: crash,
		tracePath: F2(tracePath),
		log: F2(log),
		watch: F2(watch),
		watchSummary: F3(watchSummary)
	};
};

Elm.Debug = Elm.Debug || {};
Elm.Debug.make = function (_elm) {
   "use strict";
   _elm.Debug = _elm.Debug || {};
   if (_elm.Debug.values) return _elm.Debug.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Graphics$Collage = Elm.Graphics.Collage.make(_elm),
   $Native$Debug = Elm.Native.Debug.make(_elm);
   var _op = {};
   var trace = $Native$Debug.tracePath;
   var watchSummary = $Native$Debug.watchSummary;
   var watch = $Native$Debug.watch;
   var crash = $Native$Debug.crash;
   var log = $Native$Debug.log;
   return _elm.Debug.values = {_op: _op
                              ,log: log
                              ,crash: crash
                              ,watch: watch
                              ,watchSummary: watchSummary
                              ,trace: trace};
};
Elm.Result = Elm.Result || {};
Elm.Result.make = function (_elm) {
   "use strict";
   _elm.Result = _elm.Result || {};
   if (_elm.Result.values) return _elm.Result.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Maybe = Elm.Maybe.make(_elm);
   var _op = {};
   var toMaybe = function (result) {
      var _p0 = result;
      if (_p0.ctor === "Ok") {
            return $Maybe.Just(_p0._0);
         } else {
            return $Maybe.Nothing;
         }
   };
   var withDefault = F2(function (def,result) {
      var _p1 = result;
      if (_p1.ctor === "Ok") {
            return _p1._0;
         } else {
            return def;
         }
   });
   var Err = function (a) {    return {ctor: "Err",_0: a};};
   var andThen = F2(function (result,callback) {
      var _p2 = result;
      if (_p2.ctor === "Ok") {
            return callback(_p2._0);
         } else {
            return Err(_p2._0);
         }
   });
   var Ok = function (a) {    return {ctor: "Ok",_0: a};};
   var map = F2(function (func,ra) {
      var _p3 = ra;
      if (_p3.ctor === "Ok") {
            return Ok(func(_p3._0));
         } else {
            return Err(_p3._0);
         }
   });
   var map2 = F3(function (func,ra,rb) {
      var _p4 = {ctor: "_Tuple2",_0: ra,_1: rb};
      if (_p4._0.ctor === "Ok") {
            if (_p4._1.ctor === "Ok") {
                  return Ok(A2(func,_p4._0._0,_p4._1._0));
               } else {
                  return Err(_p4._1._0);
               }
         } else {
            return Err(_p4._0._0);
         }
   });
   var map3 = F4(function (func,ra,rb,rc) {
      var _p5 = {ctor: "_Tuple3",_0: ra,_1: rb,_2: rc};
      if (_p5._0.ctor === "Ok") {
            if (_p5._1.ctor === "Ok") {
                  if (_p5._2.ctor === "Ok") {
                        return Ok(A3(func,_p5._0._0,_p5._1._0,_p5._2._0));
                     } else {
                        return Err(_p5._2._0);
                     }
               } else {
                  return Err(_p5._1._0);
               }
         } else {
            return Err(_p5._0._0);
         }
   });
   var map4 = F5(function (func,ra,rb,rc,rd) {
      var _p6 = {ctor: "_Tuple4",_0: ra,_1: rb,_2: rc,_3: rd};
      if (_p6._0.ctor === "Ok") {
            if (_p6._1.ctor === "Ok") {
                  if (_p6._2.ctor === "Ok") {
                        if (_p6._3.ctor === "Ok") {
                              return Ok(A4(func,_p6._0._0,_p6._1._0,_p6._2._0,_p6._3._0));
                           } else {
                              return Err(_p6._3._0);
                           }
                     } else {
                        return Err(_p6._2._0);
                     }
               } else {
                  return Err(_p6._1._0);
               }
         } else {
            return Err(_p6._0._0);
         }
   });
   var map5 = F6(function (func,ra,rb,rc,rd,re) {
      var _p7 = {ctor: "_Tuple5"
                ,_0: ra
                ,_1: rb
                ,_2: rc
                ,_3: rd
                ,_4: re};
      if (_p7._0.ctor === "Ok") {
            if (_p7._1.ctor === "Ok") {
                  if (_p7._2.ctor === "Ok") {
                        if (_p7._3.ctor === "Ok") {
                              if (_p7._4.ctor === "Ok") {
                                    return Ok(A5(func,
                                    _p7._0._0,
                                    _p7._1._0,
                                    _p7._2._0,
                                    _p7._3._0,
                                    _p7._4._0));
                                 } else {
                                    return Err(_p7._4._0);
                                 }
                           } else {
                              return Err(_p7._3._0);
                           }
                     } else {
                        return Err(_p7._2._0);
                     }
               } else {
                  return Err(_p7._1._0);
               }
         } else {
            return Err(_p7._0._0);
         }
   });
   var formatError = F2(function (f,result) {
      var _p8 = result;
      if (_p8.ctor === "Ok") {
            return Ok(_p8._0);
         } else {
            return Err(f(_p8._0));
         }
   });
   var fromMaybe = F2(function (err,maybe) {
      var _p9 = maybe;
      if (_p9.ctor === "Just") {
            return Ok(_p9._0);
         } else {
            return Err(err);
         }
   });
   return _elm.Result.values = {_op: _op
                               ,withDefault: withDefault
                               ,map: map
                               ,map2: map2
                               ,map3: map3
                               ,map4: map4
                               ,map5: map5
                               ,andThen: andThen
                               ,toMaybe: toMaybe
                               ,fromMaybe: fromMaybe
                               ,formatError: formatError
                               ,Ok: Ok
                               ,Err: Err};
};
Elm.Native.Signal = {};

Elm.Native.Signal.make = function(localRuntime) {
	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Signal = localRuntime.Native.Signal || {};
	if (localRuntime.Native.Signal.values)
	{
		return localRuntime.Native.Signal.values;
	}


	var Task = Elm.Native.Task.make(localRuntime);
	var Utils = Elm.Native.Utils.make(localRuntime);


	function broadcastToKids(node, timestamp, update)
	{
		var kids = node.kids;
		for (var i = kids.length; i--; )
		{
			kids[i].notify(timestamp, update, node.id);
		}
	}


	// INPUT

	function input(name, base)
	{
		var node = {
			id: Utils.guid(),
			name: 'input-' + name,
			value: base,
			parents: [],
			kids: []
		};

		node.notify = function(timestamp, targetId, value) {
			var update = targetId === node.id;
			if (update)
			{
				node.value = value;
			}
			broadcastToKids(node, timestamp, update);
			return update;
		};

		localRuntime.inputs.push(node);

		return node;
	}

	function constant(value)
	{
		return input('constant', value);
	}


	// MAILBOX

	function mailbox(base)
	{
		var signal = input('mailbox', base);

		function send(value) {
			return Task.asyncFunction(function(callback) {
				localRuntime.setTimeout(function() {
					localRuntime.notify(signal.id, value);
				}, 0);
				callback(Task.succeed(Utils.Tuple0));
			});
		}

		return {
			signal: signal,
			address: {
				ctor: 'Address',
				_0: send
			}
		};
	}

	function sendMessage(message)
	{
		Task.perform(message._0);
	}


	// OUTPUT

	function output(name, handler, parent)
	{
		var node = {
			id: Utils.guid(),
			name: 'output-' + name,
			parents: [parent],
			isOutput: true
		};

		node.notify = function(timestamp, parentUpdate, parentID)
		{
			if (parentUpdate)
			{
				handler(parent.value);
			}
		};

		parent.kids.push(node);

		return node;
	}


	// MAP

	function mapMany(refreshValue, args)
	{
		var node = {
			id: Utils.guid(),
			name: 'map' + args.length,
			value: refreshValue(),
			parents: args,
			kids: []
		};

		var numberOfParents = args.length;
		var count = 0;
		var update = false;

		node.notify = function(timestamp, parentUpdate, parentID)
		{
			++count;

			update = update || parentUpdate;

			if (count === numberOfParents)
			{
				if (update)
				{
					node.value = refreshValue();
				}
				broadcastToKids(node, timestamp, update);
				update = false;
				count = 0;
			}
		};

		for (var i = numberOfParents; i--; )
		{
			args[i].kids.push(node);
		}

		return node;
	}


	function map(func, a)
	{
		function refreshValue()
		{
			return func(a.value);
		}
		return mapMany(refreshValue, [a]);
	}


	function map2(func, a, b)
	{
		function refreshValue()
		{
			return A2( func, a.value, b.value );
		}
		return mapMany(refreshValue, [a, b]);
	}


	function map3(func, a, b, c)
	{
		function refreshValue()
		{
			return A3( func, a.value, b.value, c.value );
		}
		return mapMany(refreshValue, [a, b, c]);
	}


	function map4(func, a, b, c, d)
	{
		function refreshValue()
		{
			return A4( func, a.value, b.value, c.value, d.value );
		}
		return mapMany(refreshValue, [a, b, c, d]);
	}


	function map5(func, a, b, c, d, e)
	{
		function refreshValue()
		{
			return A5( func, a.value, b.value, c.value, d.value, e.value );
		}
		return mapMany(refreshValue, [a, b, c, d, e]);
	}


	// FOLD

	function foldp(update, state, signal)
	{
		var node = {
			id: Utils.guid(),
			name: 'foldp',
			parents: [signal],
			kids: [],
			value: state
		};

		node.notify = function(timestamp, parentUpdate, parentID)
		{
			if (parentUpdate)
			{
				node.value = A2( update, signal.value, node.value );
			}
			broadcastToKids(node, timestamp, parentUpdate);
		};

		signal.kids.push(node);

		return node;
	}


	// TIME

	function timestamp(signal)
	{
		var node = {
			id: Utils.guid(),
			name: 'timestamp',
			value: Utils.Tuple2(localRuntime.timer.programStart, signal.value),
			parents: [signal],
			kids: []
		};

		node.notify = function(timestamp, parentUpdate, parentID)
		{
			if (parentUpdate)
			{
				node.value = Utils.Tuple2(timestamp, signal.value);
			}
			broadcastToKids(node, timestamp, parentUpdate);
		};

		signal.kids.push(node);

		return node;
	}


	function delay(time, signal)
	{
		var delayed = input('delay-input-' + time, signal.value);

		function handler(value)
		{
			setTimeout(function() {
				localRuntime.notify(delayed.id, value);
			}, time);
		}

		output('delay-output-' + time, handler, signal);

		return delayed;
	}


	// MERGING

	function genericMerge(tieBreaker, leftStream, rightStream)
	{
		var node = {
			id: Utils.guid(),
			name: 'merge',
			value: A2(tieBreaker, leftStream.value, rightStream.value),
			parents: [leftStream, rightStream],
			kids: []
		};

		var left = { touched: false, update: false, value: null };
		var right = { touched: false, update: false, value: null };

		node.notify = function(timestamp, parentUpdate, parentID)
		{
			if (parentID === leftStream.id)
			{
				left.touched = true;
				left.update = parentUpdate;
				left.value = leftStream.value;
			}
			if (parentID === rightStream.id)
			{
				right.touched = true;
				right.update = parentUpdate;
				right.value = rightStream.value;
			}

			if (left.touched && right.touched)
			{
				var update = false;
				if (left.update && right.update)
				{
					node.value = A2(tieBreaker, left.value, right.value);
					update = true;
				}
				else if (left.update)
				{
					node.value = left.value;
					update = true;
				}
				else if (right.update)
				{
					node.value = right.value;
					update = true;
				}
				left.touched = false;
				right.touched = false;

				broadcastToKids(node, timestamp, update);
			}
		};

		leftStream.kids.push(node);
		rightStream.kids.push(node);

		return node;
	}


	// FILTERING

	function filterMap(toMaybe, base, signal)
	{
		var maybe = toMaybe(signal.value);
		var node = {
			id: Utils.guid(),
			name: 'filterMap',
			value: maybe.ctor === 'Nothing' ? base : maybe._0,
			parents: [signal],
			kids: []
		};

		node.notify = function(timestamp, parentUpdate, parentID)
		{
			var update = false;
			if (parentUpdate)
			{
				var maybe = toMaybe(signal.value);
				if (maybe.ctor === 'Just')
				{
					update = true;
					node.value = maybe._0;
				}
			}
			broadcastToKids(node, timestamp, update);
		};

		signal.kids.push(node);

		return node;
	}


	// SAMPLING

	function sampleOn(ticker, signal)
	{
		var node = {
			id: Utils.guid(),
			name: 'sampleOn',
			value: signal.value,
			parents: [ticker, signal],
			kids: []
		};

		var signalTouch = false;
		var tickerTouch = false;
		var tickerUpdate = false;

		node.notify = function(timestamp, parentUpdate, parentID)
		{
			if (parentID === ticker.id)
			{
				tickerTouch = true;
				tickerUpdate = parentUpdate;
			}
			if (parentID === signal.id)
			{
				signalTouch = true;
			}

			if (tickerTouch && signalTouch)
			{
				if (tickerUpdate)
				{
					node.value = signal.value;
				}
				tickerTouch = false;
				signalTouch = false;

				broadcastToKids(node, timestamp, tickerUpdate);
			}
		};

		ticker.kids.push(node);
		signal.kids.push(node);

		return node;
	}


	// DROP REPEATS

	function dropRepeats(signal)
	{
		var node = {
			id: Utils.guid(),
			name: 'dropRepeats',
			value: signal.value,
			parents: [signal],
			kids: []
		};

		node.notify = function(timestamp, parentUpdate, parentID)
		{
			var update = false;
			if (parentUpdate && !Utils.eq(node.value, signal.value))
			{
				node.value = signal.value;
				update = true;
			}
			broadcastToKids(node, timestamp, update);
		};

		signal.kids.push(node);

		return node;
	}


	return localRuntime.Native.Signal.values = {
		input: input,
		constant: constant,
		mailbox: mailbox,
		sendMessage: sendMessage,
		output: output,
		map: F2(map),
		map2: F3(map2),
		map3: F4(map3),
		map4: F5(map4),
		map5: F6(map5),
		foldp: F3(foldp),
		genericMerge: F3(genericMerge),
		filterMap: F3(filterMap),
		sampleOn: F2(sampleOn),
		dropRepeats: dropRepeats,
		timestamp: timestamp,
		delay: F2(delay)
	};
};

Elm.Native.Task = {};

Elm.Native.Task.make = function(localRuntime) {
	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Task = localRuntime.Native.Task || {};
	if (localRuntime.Native.Task.values)
	{
		return localRuntime.Native.Task.values;
	}

	var Result = Elm.Result.make(localRuntime);
	var Signal;
	var Utils = Elm.Native.Utils.make(localRuntime);


	// CONSTRUCTORS

	function succeed(value)
	{
		return {
			tag: 'Succeed',
			value: value
		};
	}

	function fail(error)
	{
		return {
			tag: 'Fail',
			value: error
		};
	}

	function asyncFunction(func)
	{
		return {
			tag: 'Async',
			asyncFunction: func
		};
	}

	function andThen(task, callback)
	{
		return {
			tag: 'AndThen',
			task: task,
			callback: callback
		};
	}

	function catch_(task, callback)
	{
		return {
			tag: 'Catch',
			task: task,
			callback: callback
		};
	}


	// RUNNER

	function perform(task) {
		runTask({ task: task }, function() {});
	}

	function performSignal(name, signal)
	{
		var workQueue = [];

		function onComplete()
		{
			workQueue.shift();

			if (workQueue.length > 0)
			{
				var task = workQueue[0];

				setTimeout(function() {
					runTask(task, onComplete);
				}, 0);
			}
		}

		function register(task)
		{
			var root = { task: task };
			workQueue.push(root);
			if (workQueue.length === 1)
			{
				runTask(root, onComplete);
			}
		}

		if (!Signal)
		{
			Signal = Elm.Native.Signal.make(localRuntime);
		}
		Signal.output('perform-tasks-' + name, register, signal);

		register(signal.value);

		return signal;
	}

	function mark(status, task)
	{
		return { status: status, task: task };
	}

	function runTask(root, onComplete)
	{
		var result = mark('runnable', root.task);
		while (result.status === 'runnable')
		{
			result = stepTask(onComplete, root, result.task);
		}

		if (result.status === 'done')
		{
			root.task = result.task;
			onComplete();
		}

		if (result.status === 'blocked')
		{
			root.task = result.task;
		}
	}

	function stepTask(onComplete, root, task)
	{
		var tag = task.tag;

		if (tag === 'Succeed' || tag === 'Fail')
		{
			return mark('done', task);
		}

		if (tag === 'Async')
		{
			var placeHolder = {};
			var couldBeSync = true;
			var wasSync = false;

			task.asyncFunction(function(result) {
				placeHolder.tag = result.tag;
				placeHolder.value = result.value;
				if (couldBeSync)
				{
					wasSync = true;
				}
				else
				{
					runTask(root, onComplete);
				}
			});
			couldBeSync = false;
			return mark(wasSync ? 'done' : 'blocked', placeHolder);
		}

		if (tag === 'AndThen' || tag === 'Catch')
		{
			var result = mark('runnable', task.task);
			while (result.status === 'runnable')
			{
				result = stepTask(onComplete, root, result.task);
			}

			if (result.status === 'done')
			{
				var activeTask = result.task;
				var activeTag = activeTask.tag;

				var succeedChain = activeTag === 'Succeed' && tag === 'AndThen';
				var failChain = activeTag === 'Fail' && tag === 'Catch';

				return (succeedChain || failChain)
					? mark('runnable', task.callback(activeTask.value))
					: mark('runnable', activeTask);
			}
			if (result.status === 'blocked')
			{
				return mark('blocked', {
					tag: tag,
					task: result.task,
					callback: task.callback
				});
			}
		}
	}


	// THREADS

	function sleep(time) {
		return asyncFunction(function(callback) {
			setTimeout(function() {
				callback(succeed(Utils.Tuple0));
			}, time);
		});
	}

	function spawn(task) {
		return asyncFunction(function(callback) {
			var id = setTimeout(function() {
				perform(task);
			}, 0);
			callback(succeed(id));
		});
	}


	return localRuntime.Native.Task.values = {
		succeed: succeed,
		fail: fail,
		asyncFunction: asyncFunction,
		andThen: F2(andThen),
		catch_: F2(catch_),
		perform: perform,
		performSignal: performSignal,
		spawn: spawn,
		sleep: sleep
	};
};

Elm.Task = Elm.Task || {};
Elm.Task.make = function (_elm) {
   "use strict";
   _elm.Task = _elm.Task || {};
   if (_elm.Task.values) return _elm.Task.values;
   var _U = Elm.Native.Utils.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Native$Task = Elm.Native.Task.make(_elm),
   $Result = Elm.Result.make(_elm);
   var _op = {};
   var sleep = $Native$Task.sleep;
   var spawn = $Native$Task.spawn;
   var ThreadID = function (a) {
      return {ctor: "ThreadID",_0: a};
   };
   var onError = $Native$Task.catch_;
   var andThen = $Native$Task.andThen;
   var fail = $Native$Task.fail;
   var mapError = F2(function (f,task) {
      return A2(onError,
      task,
      function (err) {
         return fail(f(err));
      });
   });
   var succeed = $Native$Task.succeed;
   var map = F2(function (func,taskA) {
      return A2(andThen,
      taskA,
      function (a) {
         return succeed(func(a));
      });
   });
   var map2 = F3(function (func,taskA,taskB) {
      return A2(andThen,
      taskA,
      function (a) {
         return A2(andThen,
         taskB,
         function (b) {
            return succeed(A2(func,a,b));
         });
      });
   });
   var map3 = F4(function (func,taskA,taskB,taskC) {
      return A2(andThen,
      taskA,
      function (a) {
         return A2(andThen,
         taskB,
         function (b) {
            return A2(andThen,
            taskC,
            function (c) {
               return succeed(A3(func,a,b,c));
            });
         });
      });
   });
   var map4 = F5(function (func,taskA,taskB,taskC,taskD) {
      return A2(andThen,
      taskA,
      function (a) {
         return A2(andThen,
         taskB,
         function (b) {
            return A2(andThen,
            taskC,
            function (c) {
               return A2(andThen,
               taskD,
               function (d) {
                  return succeed(A4(func,a,b,c,d));
               });
            });
         });
      });
   });
   var map5 = F6(function (func,taskA,taskB,taskC,taskD,taskE) {
      return A2(andThen,
      taskA,
      function (a) {
         return A2(andThen,
         taskB,
         function (b) {
            return A2(andThen,
            taskC,
            function (c) {
               return A2(andThen,
               taskD,
               function (d) {
                  return A2(andThen,
                  taskE,
                  function (e) {
                     return succeed(A5(func,a,b,c,d,e));
                  });
               });
            });
         });
      });
   });
   var andMap = F2(function (taskFunc,taskValue) {
      return A2(andThen,
      taskFunc,
      function (func) {
         return A2(andThen,
         taskValue,
         function (value) {
            return succeed(func(value));
         });
      });
   });
   var sequence = function (tasks) {
      var _p0 = tasks;
      if (_p0.ctor === "[]") {
            return succeed(_U.list([]));
         } else {
            return A3(map2,
            F2(function (x,y) {    return A2($List._op["::"],x,y);}),
            _p0._0,
            sequence(_p0._1));
         }
   };
   var toMaybe = function (task) {
      return A2(onError,
      A2(map,$Maybe.Just,task),
      function (_p1) {
         return succeed($Maybe.Nothing);
      });
   };
   var fromMaybe = F2(function ($default,maybe) {
      var _p2 = maybe;
      if (_p2.ctor === "Just") {
            return succeed(_p2._0);
         } else {
            return fail($default);
         }
   });
   var toResult = function (task) {
      return A2(onError,
      A2(map,$Result.Ok,task),
      function (msg) {
         return succeed($Result.Err(msg));
      });
   };
   var fromResult = function (result) {
      var _p3 = result;
      if (_p3.ctor === "Ok") {
            return succeed(_p3._0);
         } else {
            return fail(_p3._0);
         }
   };
   var Task = {ctor: "Task"};
   return _elm.Task.values = {_op: _op
                             ,succeed: succeed
                             ,fail: fail
                             ,map: map
                             ,map2: map2
                             ,map3: map3
                             ,map4: map4
                             ,map5: map5
                             ,andMap: andMap
                             ,sequence: sequence
                             ,andThen: andThen
                             ,onError: onError
                             ,mapError: mapError
                             ,toMaybe: toMaybe
                             ,fromMaybe: fromMaybe
                             ,toResult: toResult
                             ,fromResult: fromResult
                             ,spawn: spawn
                             ,sleep: sleep};
};
Elm.Signal = Elm.Signal || {};
Elm.Signal.make = function (_elm) {
   "use strict";
   _elm.Signal = _elm.Signal || {};
   if (_elm.Signal.values) return _elm.Signal.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Native$Signal = Elm.Native.Signal.make(_elm),
   $Task = Elm.Task.make(_elm);
   var _op = {};
   var send = F2(function (_p0,value) {
      var _p1 = _p0;
      return A2($Task.onError,
      _p1._0(value),
      function (_p2) {
         return $Task.succeed({ctor: "_Tuple0"});
      });
   });
   var Message = function (a) {
      return {ctor: "Message",_0: a};
   };
   var message = F2(function (_p3,value) {
      var _p4 = _p3;
      return Message(_p4._0(value));
   });
   var mailbox = $Native$Signal.mailbox;
   var Address = function (a) {
      return {ctor: "Address",_0: a};
   };
   var forwardTo = F2(function (_p5,f) {
      var _p6 = _p5;
      return Address(function (x) {    return _p6._0(f(x));});
   });
   var Mailbox = F2(function (a,b) {
      return {address: a,signal: b};
   });
   var sampleOn = $Native$Signal.sampleOn;
   var dropRepeats = $Native$Signal.dropRepeats;
   var filterMap = $Native$Signal.filterMap;
   var filter = F3(function (isOk,base,signal) {
      return A3(filterMap,
      function (value) {
         return isOk(value) ? $Maybe.Just(value) : $Maybe.Nothing;
      },
      base,
      signal);
   });
   var merge = F2(function (left,right) {
      return A3($Native$Signal.genericMerge,
      $Basics.always,
      left,
      right);
   });
   var mergeMany = function (signalList) {
      var _p7 = $List.reverse(signalList);
      if (_p7.ctor === "[]") {
            return _U.crashCase("Signal",
            {start: {line: 184,column: 3},end: {line: 189,column: 40}},
            _p7)("mergeMany was given an empty list!");
         } else {
            return A3($List.foldl,merge,_p7._0,_p7._1);
         }
   };
   var foldp = $Native$Signal.foldp;
   var map5 = $Native$Signal.map5;
   var map4 = $Native$Signal.map4;
   var map3 = $Native$Signal.map3;
   var map2 = $Native$Signal.map2;
   var map = $Native$Signal.map;
   var constant = $Native$Signal.constant;
   var Signal = {ctor: "Signal"};
   return _elm.Signal.values = {_op: _op
                               ,merge: merge
                               ,mergeMany: mergeMany
                               ,map: map
                               ,map2: map2
                               ,map3: map3
                               ,map4: map4
                               ,map5: map5
                               ,constant: constant
                               ,dropRepeats: dropRepeats
                               ,filter: filter
                               ,filterMap: filterMap
                               ,sampleOn: sampleOn
                               ,foldp: foldp
                               ,mailbox: mailbox
                               ,send: send
                               ,message: message
                               ,forwardTo: forwardTo
                               ,Mailbox: Mailbox};
};
Elm.Native.String = {};

Elm.Native.String.make = function(localRuntime) {
	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.String = localRuntime.Native.String || {};
	if (localRuntime.Native.String.values)
	{
		return localRuntime.Native.String.values;
	}
	if ('values' in Elm.Native.String)
	{
		return localRuntime.Native.String.values = Elm.Native.String.values;
	}


	var Char = Elm.Char.make(localRuntime);
	var List = Elm.Native.List.make(localRuntime);
	var Maybe = Elm.Maybe.make(localRuntime);
	var Result = Elm.Result.make(localRuntime);
	var Utils = Elm.Native.Utils.make(localRuntime);

	function isEmpty(str)
	{
		return str.length === 0;
	}
	function cons(chr, str)
	{
		return chr + str;
	}
	function uncons(str)
	{
		var hd = str[0];
		if (hd)
		{
			return Maybe.Just(Utils.Tuple2(Utils.chr(hd), str.slice(1)));
		}
		return Maybe.Nothing;
	}
	function append(a, b)
	{
		return a + b;
	}
	function concat(strs)
	{
		return List.toArray(strs).join('');
	}
	function length(str)
	{
		return str.length;
	}
	function map(f, str)
	{
		var out = str.split('');
		for (var i = out.length; i--; )
		{
			out[i] = f(Utils.chr(out[i]));
		}
		return out.join('');
	}
	function filter(pred, str)
	{
		return str.split('').map(Utils.chr).filter(pred).join('');
	}
	function reverse(str)
	{
		return str.split('').reverse().join('');
	}
	function foldl(f, b, str)
	{
		var len = str.length;
		for (var i = 0; i < len; ++i)
		{
			b = A2(f, Utils.chr(str[i]), b);
		}
		return b;
	}
	function foldr(f, b, str)
	{
		for (var i = str.length; i--; )
		{
			b = A2(f, Utils.chr(str[i]), b);
		}
		return b;
	}
	function split(sep, str)
	{
		return List.fromArray(str.split(sep));
	}
	function join(sep, strs)
	{
		return List.toArray(strs).join(sep);
	}
	function repeat(n, str)
	{
		var result = '';
		while (n > 0)
		{
			if (n & 1)
			{
				result += str;
			}
			n >>= 1, str += str;
		}
		return result;
	}
	function slice(start, end, str)
	{
		return str.slice(start, end);
	}
	function left(n, str)
	{
		return n < 1 ? '' : str.slice(0, n);
	}
	function right(n, str)
	{
		return n < 1 ? '' : str.slice(-n);
	}
	function dropLeft(n, str)
	{
		return n < 1 ? str : str.slice(n);
	}
	function dropRight(n, str)
	{
		return n < 1 ? str : str.slice(0, -n);
	}
	function pad(n, chr, str)
	{
		var half = (n - str.length) / 2;
		return repeat(Math.ceil(half), chr) + str + repeat(half | 0, chr);
	}
	function padRight(n, chr, str)
	{
		return str + repeat(n - str.length, chr);
	}
	function padLeft(n, chr, str)
	{
		return repeat(n - str.length, chr) + str;
	}

	function trim(str)
	{
		return str.trim();
	}
	function trimLeft(str)
	{
		return str.replace(/^\s+/, '');
	}
	function trimRight(str)
	{
		return str.replace(/\s+$/, '');
	}

	function words(str)
	{
		return List.fromArray(str.trim().split(/\s+/g));
	}
	function lines(str)
	{
		return List.fromArray(str.split(/\r\n|\r|\n/g));
	}

	function toUpper(str)
	{
		return str.toUpperCase();
	}
	function toLower(str)
	{
		return str.toLowerCase();
	}

	function any(pred, str)
	{
		for (var i = str.length; i--; )
		{
			if (pred(Utils.chr(str[i])))
			{
				return true;
			}
		}
		return false;
	}
	function all(pred, str)
	{
		for (var i = str.length; i--; )
		{
			if (!pred(Utils.chr(str[i])))
			{
				return false;
			}
		}
		return true;
	}

	function contains(sub, str)
	{
		return str.indexOf(sub) > -1;
	}
	function startsWith(sub, str)
	{
		return str.indexOf(sub) === 0;
	}
	function endsWith(sub, str)
	{
		return str.length >= sub.length &&
			str.lastIndexOf(sub) === str.length - sub.length;
	}
	function indexes(sub, str)
	{
		var subLen = sub.length;
		var i = 0;
		var is = [];
		while ((i = str.indexOf(sub, i)) > -1)
		{
			is.push(i);
			i = i + subLen;
		}
		return List.fromArray(is);
	}

	function toInt(s)
	{
		var len = s.length;
		if (len === 0)
		{
			return Result.Err("could not convert string '" + s + "' to an Int" );
		}
		var start = 0;
		if (s[0] === '-')
		{
			if (len === 1)
			{
				return Result.Err("could not convert string '" + s + "' to an Int" );
			}
			start = 1;
		}
		for (var i = start; i < len; ++i)
		{
			if (!Char.isDigit(s[i]))
			{
				return Result.Err("could not convert string '" + s + "' to an Int" );
			}
		}
		return Result.Ok(parseInt(s, 10));
	}

	function toFloat(s)
	{
		var len = s.length;
		if (len === 0)
		{
			return Result.Err("could not convert string '" + s + "' to a Float" );
		}
		var start = 0;
		if (s[0] === '-')
		{
			if (len === 1)
			{
				return Result.Err("could not convert string '" + s + "' to a Float" );
			}
			start = 1;
		}
		var dotCount = 0;
		for (var i = start; i < len; ++i)
		{
			if (Char.isDigit(s[i]))
			{
				continue;
			}
			if (s[i] === '.')
			{
				dotCount += 1;
				if (dotCount <= 1)
				{
					continue;
				}
			}
			return Result.Err("could not convert string '" + s + "' to a Float" );
		}
		return Result.Ok(parseFloat(s));
	}

	function toList(str)
	{
		return List.fromArray(str.split('').map(Utils.chr));
	}
	function fromList(chars)
	{
		return List.toArray(chars).join('');
	}

	return Elm.Native.String.values = {
		isEmpty: isEmpty,
		cons: F2(cons),
		uncons: uncons,
		append: F2(append),
		concat: concat,
		length: length,
		map: F2(map),
		filter: F2(filter),
		reverse: reverse,
		foldl: F3(foldl),
		foldr: F3(foldr),

		split: F2(split),
		join: F2(join),
		repeat: F2(repeat),

		slice: F3(slice),
		left: F2(left),
		right: F2(right),
		dropLeft: F2(dropLeft),
		dropRight: F2(dropRight),

		pad: F3(pad),
		padLeft: F3(padLeft),
		padRight: F3(padRight),

		trim: trim,
		trimLeft: trimLeft,
		trimRight: trimRight,

		words: words,
		lines: lines,

		toUpper: toUpper,
		toLower: toLower,

		any: F2(any),
		all: F2(all),

		contains: F2(contains),
		startsWith: F2(startsWith),
		endsWith: F2(endsWith),
		indexes: F2(indexes),

		toInt: toInt,
		toFloat: toFloat,
		toList: toList,
		fromList: fromList
	};
};

Elm.Native.Char = {};
Elm.Native.Char.make = function(localRuntime) {
	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Char = localRuntime.Native.Char || {};
	if (localRuntime.Native.Char.values)
	{
		return localRuntime.Native.Char.values;
	}

	var Utils = Elm.Native.Utils.make(localRuntime);

	return localRuntime.Native.Char.values = {
		fromCode: function(c) { return Utils.chr(String.fromCharCode(c)); },
		toCode: function(c) { return c.charCodeAt(0); },
		toUpper: function(c) { return Utils.chr(c.toUpperCase()); },
		toLower: function(c) { return Utils.chr(c.toLowerCase()); },
		toLocaleUpper: function(c) { return Utils.chr(c.toLocaleUpperCase()); },
		toLocaleLower: function(c) { return Utils.chr(c.toLocaleLowerCase()); }
	};
};

Elm.Char = Elm.Char || {};
Elm.Char.make = function (_elm) {
   "use strict";
   _elm.Char = _elm.Char || {};
   if (_elm.Char.values) return _elm.Char.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Native$Char = Elm.Native.Char.make(_elm);
   var _op = {};
   var fromCode = $Native$Char.fromCode;
   var toCode = $Native$Char.toCode;
   var toLocaleLower = $Native$Char.toLocaleLower;
   var toLocaleUpper = $Native$Char.toLocaleUpper;
   var toLower = $Native$Char.toLower;
   var toUpper = $Native$Char.toUpper;
   var isBetween = F3(function (low,high,$char) {
      var code = toCode($char);
      return _U.cmp(code,toCode(low)) > -1 && _U.cmp(code,
      toCode(high)) < 1;
   });
   var isUpper = A2(isBetween,_U.chr("A"),_U.chr("Z"));
   var isLower = A2(isBetween,_U.chr("a"),_U.chr("z"));
   var isDigit = A2(isBetween,_U.chr("0"),_U.chr("9"));
   var isOctDigit = A2(isBetween,_U.chr("0"),_U.chr("7"));
   var isHexDigit = function ($char) {
      return isDigit($char) || (A3(isBetween,
      _U.chr("a"),
      _U.chr("f"),
      $char) || A3(isBetween,_U.chr("A"),_U.chr("F"),$char));
   };
   return _elm.Char.values = {_op: _op
                             ,isUpper: isUpper
                             ,isLower: isLower
                             ,isDigit: isDigit
                             ,isOctDigit: isOctDigit
                             ,isHexDigit: isHexDigit
                             ,toUpper: toUpper
                             ,toLower: toLower
                             ,toLocaleUpper: toLocaleUpper
                             ,toLocaleLower: toLocaleLower
                             ,toCode: toCode
                             ,fromCode: fromCode};
};
Elm.String = Elm.String || {};
Elm.String.make = function (_elm) {
   "use strict";
   _elm.String = _elm.String || {};
   if (_elm.String.values) return _elm.String.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Native$String = Elm.Native.String.make(_elm),
   $Result = Elm.Result.make(_elm);
   var _op = {};
   var fromList = $Native$String.fromList;
   var toList = $Native$String.toList;
   var toFloat = $Native$String.toFloat;
   var toInt = $Native$String.toInt;
   var indices = $Native$String.indexes;
   var indexes = $Native$String.indexes;
   var endsWith = $Native$String.endsWith;
   var startsWith = $Native$String.startsWith;
   var contains = $Native$String.contains;
   var all = $Native$String.all;
   var any = $Native$String.any;
   var toLower = $Native$String.toLower;
   var toUpper = $Native$String.toUpper;
   var lines = $Native$String.lines;
   var words = $Native$String.words;
   var trimRight = $Native$String.trimRight;
   var trimLeft = $Native$String.trimLeft;
   var trim = $Native$String.trim;
   var padRight = $Native$String.padRight;
   var padLeft = $Native$String.padLeft;
   var pad = $Native$String.pad;
   var dropRight = $Native$String.dropRight;
   var dropLeft = $Native$String.dropLeft;
   var right = $Native$String.right;
   var left = $Native$String.left;
   var slice = $Native$String.slice;
   var repeat = $Native$String.repeat;
   var join = $Native$String.join;
   var split = $Native$String.split;
   var foldr = $Native$String.foldr;
   var foldl = $Native$String.foldl;
   var reverse = $Native$String.reverse;
   var filter = $Native$String.filter;
   var map = $Native$String.map;
   var length = $Native$String.length;
   var concat = $Native$String.concat;
   var append = $Native$String.append;
   var uncons = $Native$String.uncons;
   var cons = $Native$String.cons;
   var fromChar = function ($char) {    return A2(cons,$char,"");};
   var isEmpty = $Native$String.isEmpty;
   return _elm.String.values = {_op: _op
                               ,isEmpty: isEmpty
                               ,length: length
                               ,reverse: reverse
                               ,repeat: repeat
                               ,cons: cons
                               ,uncons: uncons
                               ,fromChar: fromChar
                               ,append: append
                               ,concat: concat
                               ,split: split
                               ,join: join
                               ,words: words
                               ,lines: lines
                               ,slice: slice
                               ,left: left
                               ,right: right
                               ,dropLeft: dropLeft
                               ,dropRight: dropRight
                               ,contains: contains
                               ,startsWith: startsWith
                               ,endsWith: endsWith
                               ,indexes: indexes
                               ,indices: indices
                               ,toInt: toInt
                               ,toFloat: toFloat
                               ,toList: toList
                               ,fromList: fromList
                               ,toUpper: toUpper
                               ,toLower: toLower
                               ,pad: pad
                               ,padLeft: padLeft
                               ,padRight: padRight
                               ,trim: trim
                               ,trimLeft: trimLeft
                               ,trimRight: trimRight
                               ,map: map
                               ,filter: filter
                               ,foldl: foldl
                               ,foldr: foldr
                               ,any: any
                               ,all: all};
};
Elm.Dict = Elm.Dict || {};
Elm.Dict.make = function (_elm) {
   "use strict";
   _elm.Dict = _elm.Dict || {};
   if (_elm.Dict.values) return _elm.Dict.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Native$Debug = Elm.Native.Debug.make(_elm),
   $String = Elm.String.make(_elm);
   var _op = {};
   var foldr = F3(function (f,acc,t) {
      foldr: while (true) {
         var _p0 = t;
         if (_p0.ctor === "RBEmpty_elm_builtin") {
               return acc;
            } else {
               var _v1 = f,
               _v2 = A3(f,_p0._1,_p0._2,A3(foldr,f,acc,_p0._4)),
               _v3 = _p0._3;
               f = _v1;
               acc = _v2;
               t = _v3;
               continue foldr;
            }
      }
   });
   var keys = function (dict) {
      return A3(foldr,
      F3(function (key,value,keyList) {
         return A2($List._op["::"],key,keyList);
      }),
      _U.list([]),
      dict);
   };
   var values = function (dict) {
      return A3(foldr,
      F3(function (key,value,valueList) {
         return A2($List._op["::"],value,valueList);
      }),
      _U.list([]),
      dict);
   };
   var toList = function (dict) {
      return A3(foldr,
      F3(function (key,value,list) {
         return A2($List._op["::"],
         {ctor: "_Tuple2",_0: key,_1: value},
         list);
      }),
      _U.list([]),
      dict);
   };
   var foldl = F3(function (f,acc,dict) {
      foldl: while (true) {
         var _p1 = dict;
         if (_p1.ctor === "RBEmpty_elm_builtin") {
               return acc;
            } else {
               var _v5 = f,
               _v6 = A3(f,_p1._1,_p1._2,A3(foldl,f,acc,_p1._3)),
               _v7 = _p1._4;
               f = _v5;
               acc = _v6;
               dict = _v7;
               continue foldl;
            }
      }
   });
   var reportRemBug = F4(function (msg,c,lgot,rgot) {
      return $Native$Debug.crash($String.concat(_U.list(["Internal red-black tree invariant violated, expected "
                                                        ,msg
                                                        ," and got "
                                                        ,$Basics.toString(c)
                                                        ,"/"
                                                        ,lgot
                                                        ,"/"
                                                        ,rgot
                                                        ,"\nPlease report this bug to <https://github.com/elm-lang/core/issues>"])));
   });
   var isBBlack = function (dict) {
      var _p2 = dict;
      _v8_2: do {
         if (_p2.ctor === "RBNode_elm_builtin") {
               if (_p2._0.ctor === "BBlack") {
                     return true;
                  } else {
                     break _v8_2;
                  }
            } else {
               if (_p2._0.ctor === "LBBlack") {
                     return true;
                  } else {
                     break _v8_2;
                  }
            }
      } while (false);
      return false;
   };
   var Same = {ctor: "Same"};
   var Remove = {ctor: "Remove"};
   var Insert = {ctor: "Insert"};
   var sizeHelp = F2(function (n,dict) {
      sizeHelp: while (true) {
         var _p3 = dict;
         if (_p3.ctor === "RBEmpty_elm_builtin") {
               return n;
            } else {
               var _v10 = A2(sizeHelp,n + 1,_p3._4),_v11 = _p3._3;
               n = _v10;
               dict = _v11;
               continue sizeHelp;
            }
      }
   });
   var size = function (dict) {    return A2(sizeHelp,0,dict);};
   var get = F2(function (targetKey,dict) {
      get: while (true) {
         var _p4 = dict;
         if (_p4.ctor === "RBEmpty_elm_builtin") {
               return $Maybe.Nothing;
            } else {
               var _p5 = A2($Basics.compare,targetKey,_p4._1);
               switch (_p5.ctor)
               {case "LT": var _v14 = targetKey,_v15 = _p4._3;
                    targetKey = _v14;
                    dict = _v15;
                    continue get;
                  case "EQ": return $Maybe.Just(_p4._2);
                  default: var _v16 = targetKey,_v17 = _p4._4;
                    targetKey = _v16;
                    dict = _v17;
                    continue get;}
            }
      }
   });
   var member = F2(function (key,dict) {
      var _p6 = A2(get,key,dict);
      if (_p6.ctor === "Just") {
            return true;
         } else {
            return false;
         }
   });
   var maxWithDefault = F3(function (k,v,r) {
      maxWithDefault: while (true) {
         var _p7 = r;
         if (_p7.ctor === "RBEmpty_elm_builtin") {
               return {ctor: "_Tuple2",_0: k,_1: v};
            } else {
               var _v20 = _p7._1,_v21 = _p7._2,_v22 = _p7._4;
               k = _v20;
               v = _v21;
               r = _v22;
               continue maxWithDefault;
            }
      }
   });
   var RBEmpty_elm_builtin = function (a) {
      return {ctor: "RBEmpty_elm_builtin",_0: a};
   };
   var RBNode_elm_builtin = F5(function (a,b,c,d,e) {
      return {ctor: "RBNode_elm_builtin"
             ,_0: a
             ,_1: b
             ,_2: c
             ,_3: d
             ,_4: e};
   });
   var LBBlack = {ctor: "LBBlack"};
   var LBlack = {ctor: "LBlack"};
   var empty = RBEmpty_elm_builtin(LBlack);
   var isEmpty = function (dict) {    return _U.eq(dict,empty);};
   var map = F2(function (f,dict) {
      var _p8 = dict;
      if (_p8.ctor === "RBEmpty_elm_builtin") {
            return RBEmpty_elm_builtin(LBlack);
         } else {
            var _p9 = _p8._1;
            return A5(RBNode_elm_builtin,
            _p8._0,
            _p9,
            A2(f,_p9,_p8._2),
            A2(map,f,_p8._3),
            A2(map,f,_p8._4));
         }
   });
   var NBlack = {ctor: "NBlack"};
   var BBlack = {ctor: "BBlack"};
   var Black = {ctor: "Black"};
   var ensureBlackRoot = function (dict) {
      var _p10 = dict;
      if (_p10.ctor === "RBNode_elm_builtin" && _p10._0.ctor === "Red")
      {
            return A5(RBNode_elm_builtin,
            Black,
            _p10._1,
            _p10._2,
            _p10._3,
            _p10._4);
         } else {
            return dict;
         }
   };
   var blackish = function (t) {
      var _p11 = t;
      if (_p11.ctor === "RBNode_elm_builtin") {
            var _p12 = _p11._0;
            return _U.eq(_p12,Black) || _U.eq(_p12,BBlack);
         } else {
            return true;
         }
   };
   var blacken = function (t) {
      var _p13 = t;
      if (_p13.ctor === "RBEmpty_elm_builtin") {
            return RBEmpty_elm_builtin(LBlack);
         } else {
            return A5(RBNode_elm_builtin,
            Black,
            _p13._1,
            _p13._2,
            _p13._3,
            _p13._4);
         }
   };
   var Red = {ctor: "Red"};
   var moreBlack = function (color) {
      var _p14 = color;
      switch (_p14.ctor)
      {case "Black": return BBlack;
         case "Red": return Black;
         case "NBlack": return Red;
         default:
         return $Native$Debug.crash("Can\'t make a double black node more black!");}
   };
   var lessBlack = function (color) {
      var _p15 = color;
      switch (_p15.ctor)
      {case "BBlack": return Black;
         case "Black": return Red;
         case "Red": return NBlack;
         default:
         return $Native$Debug.crash("Can\'t make a negative black node less black!");}
   };
   var lessBlackTree = function (dict) {
      var _p16 = dict;
      if (_p16.ctor === "RBNode_elm_builtin") {
            return A5(RBNode_elm_builtin,
            lessBlack(_p16._0),
            _p16._1,
            _p16._2,
            _p16._3,
            _p16._4);
         } else {
            return RBEmpty_elm_builtin(LBlack);
         }
   };
   var balancedTree = function (col) {
      return function (xk) {
         return function (xv) {
            return function (yk) {
               return function (yv) {
                  return function (zk) {
                     return function (zv) {
                        return function (a) {
                           return function (b) {
                              return function (c) {
                                 return function (d) {
                                    return A5(RBNode_elm_builtin,
                                    lessBlack(col),
                                    yk,
                                    yv,
                                    A5(RBNode_elm_builtin,Black,xk,xv,a,b),
                                    A5(RBNode_elm_builtin,Black,zk,zv,c,d));
                                 };
                              };
                           };
                        };
                     };
                  };
               };
            };
         };
      };
   };
   var redden = function (t) {
      var _p17 = t;
      if (_p17.ctor === "RBEmpty_elm_builtin") {
            return $Native$Debug.crash("can\'t make a Leaf red");
         } else {
            return A5(RBNode_elm_builtin,
            Red,
            _p17._1,
            _p17._2,
            _p17._3,
            _p17._4);
         }
   };
   var balanceHelp = function (tree) {
      var _p18 = tree;
      _v31_6: do {
         _v31_5: do {
            _v31_4: do {
               _v31_3: do {
                  _v31_2: do {
                     _v31_1: do {
                        _v31_0: do {
                           if (_p18.ctor === "RBNode_elm_builtin") {
                                 if (_p18._3.ctor === "RBNode_elm_builtin") {
                                       if (_p18._4.ctor === "RBNode_elm_builtin") {
                                             switch (_p18._3._0.ctor)
                                             {case "Red": switch (_p18._4._0.ctor)
                                                  {case "Red":
                                                     if (_p18._3._3.ctor === "RBNode_elm_builtin" && _p18._3._3._0.ctor === "Red")
                                                       {
                                                             break _v31_0;
                                                          } else {
                                                             if (_p18._3._4.ctor === "RBNode_elm_builtin" && _p18._3._4._0.ctor === "Red")
                                                             {
                                                                   break _v31_1;
                                                                } else {
                                                                   if (_p18._4._3.ctor === "RBNode_elm_builtin" && _p18._4._3._0.ctor === "Red")
                                                                   {
                                                                         break _v31_2;
                                                                      } else {
                                                                         if (_p18._4._4.ctor === "RBNode_elm_builtin" && _p18._4._4._0.ctor === "Red")
                                                                         {
                                                                               break _v31_3;
                                                                            } else {
                                                                               break _v31_6;
                                                                            }
                                                                      }
                                                                }
                                                          }
                                                     case "NBlack":
                                                     if (_p18._3._3.ctor === "RBNode_elm_builtin" && _p18._3._3._0.ctor === "Red")
                                                       {
                                                             break _v31_0;
                                                          } else {
                                                             if (_p18._3._4.ctor === "RBNode_elm_builtin" && _p18._3._4._0.ctor === "Red")
                                                             {
                                                                   break _v31_1;
                                                                } else {
                                                                   if (_p18._0.ctor === "BBlack" && _p18._4._3.ctor === "RBNode_elm_builtin" && _p18._4._3._0.ctor === "Black" && _p18._4._4.ctor === "RBNode_elm_builtin" && _p18._4._4._0.ctor === "Black")
                                                                   {
                                                                         break _v31_4;
                                                                      } else {
                                                                         break _v31_6;
                                                                      }
                                                                }
                                                          }
                                                     default:
                                                     if (_p18._3._3.ctor === "RBNode_elm_builtin" && _p18._3._3._0.ctor === "Red")
                                                       {
                                                             break _v31_0;
                                                          } else {
                                                             if (_p18._3._4.ctor === "RBNode_elm_builtin" && _p18._3._4._0.ctor === "Red")
                                                             {
                                                                   break _v31_1;
                                                                } else {
                                                                   break _v31_6;
                                                                }
                                                          }}
                                                case "NBlack": switch (_p18._4._0.ctor)
                                                  {case "Red":
                                                     if (_p18._4._3.ctor === "RBNode_elm_builtin" && _p18._4._3._0.ctor === "Red")
                                                       {
                                                             break _v31_2;
                                                          } else {
                                                             if (_p18._4._4.ctor === "RBNode_elm_builtin" && _p18._4._4._0.ctor === "Red")
                                                             {
                                                                   break _v31_3;
                                                                } else {
                                                                   if (_p18._0.ctor === "BBlack" && _p18._3._3.ctor === "RBNode_elm_builtin" && _p18._3._3._0.ctor === "Black" && _p18._3._4.ctor === "RBNode_elm_builtin" && _p18._3._4._0.ctor === "Black")
                                                                   {
                                                                         break _v31_5;
                                                                      } else {
                                                                         break _v31_6;
                                                                      }
                                                                }
                                                          }
                                                     case "NBlack": if (_p18._0.ctor === "BBlack") {
                                                             if (_p18._4._3.ctor === "RBNode_elm_builtin" && _p18._4._3._0.ctor === "Black" && _p18._4._4.ctor === "RBNode_elm_builtin" && _p18._4._4._0.ctor === "Black")
                                                             {
                                                                   break _v31_4;
                                                                } else {
                                                                   if (_p18._3._3.ctor === "RBNode_elm_builtin" && _p18._3._3._0.ctor === "Black" && _p18._3._4.ctor === "RBNode_elm_builtin" && _p18._3._4._0.ctor === "Black")
                                                                   {
                                                                         break _v31_5;
                                                                      } else {
                                                                         break _v31_6;
                                                                      }
                                                                }
                                                          } else {
                                                             break _v31_6;
                                                          }
                                                     default:
                                                     if (_p18._0.ctor === "BBlack" && _p18._3._3.ctor === "RBNode_elm_builtin" && _p18._3._3._0.ctor === "Black" && _p18._3._4.ctor === "RBNode_elm_builtin" && _p18._3._4._0.ctor === "Black")
                                                       {
                                                             break _v31_5;
                                                          } else {
                                                             break _v31_6;
                                                          }}
                                                default: switch (_p18._4._0.ctor)
                                                  {case "Red":
                                                     if (_p18._4._3.ctor === "RBNode_elm_builtin" && _p18._4._3._0.ctor === "Red")
                                                       {
                                                             break _v31_2;
                                                          } else {
                                                             if (_p18._4._4.ctor === "RBNode_elm_builtin" && _p18._4._4._0.ctor === "Red")
                                                             {
                                                                   break _v31_3;
                                                                } else {
                                                                   break _v31_6;
                                                                }
                                                          }
                                                     case "NBlack":
                                                     if (_p18._0.ctor === "BBlack" && _p18._4._3.ctor === "RBNode_elm_builtin" && _p18._4._3._0.ctor === "Black" && _p18._4._4.ctor === "RBNode_elm_builtin" && _p18._4._4._0.ctor === "Black")
                                                       {
                                                             break _v31_4;
                                                          } else {
                                                             break _v31_6;
                                                          }
                                                     default: break _v31_6;}}
                                          } else {
                                             switch (_p18._3._0.ctor)
                                             {case "Red":
                                                if (_p18._3._3.ctor === "RBNode_elm_builtin" && _p18._3._3._0.ctor === "Red")
                                                  {
                                                        break _v31_0;
                                                     } else {
                                                        if (_p18._3._4.ctor === "RBNode_elm_builtin" && _p18._3._4._0.ctor === "Red")
                                                        {
                                                              break _v31_1;
                                                           } else {
                                                              break _v31_6;
                                                           }
                                                     }
                                                case "NBlack":
                                                if (_p18._0.ctor === "BBlack" && _p18._3._3.ctor === "RBNode_elm_builtin" && _p18._3._3._0.ctor === "Black" && _p18._3._4.ctor === "RBNode_elm_builtin" && _p18._3._4._0.ctor === "Black")
                                                  {
                                                        break _v31_5;
                                                     } else {
                                                        break _v31_6;
                                                     }
                                                default: break _v31_6;}
                                          }
                                    } else {
                                       if (_p18._4.ctor === "RBNode_elm_builtin") {
                                             switch (_p18._4._0.ctor)
                                             {case "Red":
                                                if (_p18._4._3.ctor === "RBNode_elm_builtin" && _p18._4._3._0.ctor === "Red")
                                                  {
                                                        break _v31_2;
                                                     } else {
                                                        if (_p18._4._4.ctor === "RBNode_elm_builtin" && _p18._4._4._0.ctor === "Red")
                                                        {
                                                              break _v31_3;
                                                           } else {
                                                              break _v31_6;
                                                           }
                                                     }
                                                case "NBlack":
                                                if (_p18._0.ctor === "BBlack" && _p18._4._3.ctor === "RBNode_elm_builtin" && _p18._4._3._0.ctor === "Black" && _p18._4._4.ctor === "RBNode_elm_builtin" && _p18._4._4._0.ctor === "Black")
                                                  {
                                                        break _v31_4;
                                                     } else {
                                                        break _v31_6;
                                                     }
                                                default: break _v31_6;}
                                          } else {
                                             break _v31_6;
                                          }
                                    }
                              } else {
                                 break _v31_6;
                              }
                        } while (false);
                        return balancedTree(_p18._0)(_p18._3._3._1)(_p18._3._3._2)(_p18._3._1)(_p18._3._2)(_p18._1)(_p18._2)(_p18._3._3._3)(_p18._3._3._4)(_p18._3._4)(_p18._4);
                     } while (false);
                     return balancedTree(_p18._0)(_p18._3._1)(_p18._3._2)(_p18._3._4._1)(_p18._3._4._2)(_p18._1)(_p18._2)(_p18._3._3)(_p18._3._4._3)(_p18._3._4._4)(_p18._4);
                  } while (false);
                  return balancedTree(_p18._0)(_p18._1)(_p18._2)(_p18._4._3._1)(_p18._4._3._2)(_p18._4._1)(_p18._4._2)(_p18._3)(_p18._4._3._3)(_p18._4._3._4)(_p18._4._4);
               } while (false);
               return balancedTree(_p18._0)(_p18._1)(_p18._2)(_p18._4._1)(_p18._4._2)(_p18._4._4._1)(_p18._4._4._2)(_p18._3)(_p18._4._3)(_p18._4._4._3)(_p18._4._4._4);
            } while (false);
            return A5(RBNode_elm_builtin,
            Black,
            _p18._4._3._1,
            _p18._4._3._2,
            A5(RBNode_elm_builtin,
            Black,
            _p18._1,
            _p18._2,
            _p18._3,
            _p18._4._3._3),
            A5(balance,
            Black,
            _p18._4._1,
            _p18._4._2,
            _p18._4._3._4,
            redden(_p18._4._4)));
         } while (false);
         return A5(RBNode_elm_builtin,
         Black,
         _p18._3._4._1,
         _p18._3._4._2,
         A5(balance,
         Black,
         _p18._3._1,
         _p18._3._2,
         redden(_p18._3._3),
         _p18._3._4._3),
         A5(RBNode_elm_builtin,
         Black,
         _p18._1,
         _p18._2,
         _p18._3._4._4,
         _p18._4));
      } while (false);
      return tree;
   };
   var balance = F5(function (c,k,v,l,r) {
      var tree = A5(RBNode_elm_builtin,c,k,v,l,r);
      return blackish(tree) ? balanceHelp(tree) : tree;
   });
   var bubble = F5(function (c,k,v,l,r) {
      return isBBlack(l) || isBBlack(r) ? A5(balance,
      moreBlack(c),
      k,
      v,
      lessBlackTree(l),
      lessBlackTree(r)) : A5(RBNode_elm_builtin,c,k,v,l,r);
   });
   var removeMax = F5(function (c,k,v,l,r) {
      var _p19 = r;
      if (_p19.ctor === "RBEmpty_elm_builtin") {
            return A3(rem,c,l,r);
         } else {
            return A5(bubble,
            c,
            k,
            v,
            l,
            A5(removeMax,_p19._0,_p19._1,_p19._2,_p19._3,_p19._4));
         }
   });
   var rem = F3(function (c,l,r) {
      var _p20 = {ctor: "_Tuple2",_0: l,_1: r};
      if (_p20._0.ctor === "RBEmpty_elm_builtin") {
            if (_p20._1.ctor === "RBEmpty_elm_builtin") {
                  var _p21 = c;
                  switch (_p21.ctor)
                  {case "Red": return RBEmpty_elm_builtin(LBlack);
                     case "Black": return RBEmpty_elm_builtin(LBBlack);
                     default:
                     return $Native$Debug.crash("cannot have bblack or nblack nodes at this point");}
               } else {
                  var _p24 = _p20._1._0;
                  var _p23 = _p20._0._0;
                  var _p22 = {ctor: "_Tuple3",_0: c,_1: _p23,_2: _p24};
                  if (_p22.ctor === "_Tuple3" && _p22._0.ctor === "Black" && _p22._1.ctor === "LBlack" && _p22._2.ctor === "Red")
                  {
                        return A5(RBNode_elm_builtin,
                        Black,
                        _p20._1._1,
                        _p20._1._2,
                        _p20._1._3,
                        _p20._1._4);
                     } else {
                        return A4(reportRemBug,
                        "Black/LBlack/Red",
                        c,
                        $Basics.toString(_p23),
                        $Basics.toString(_p24));
                     }
               }
         } else {
            if (_p20._1.ctor === "RBEmpty_elm_builtin") {
                  var _p27 = _p20._1._0;
                  var _p26 = _p20._0._0;
                  var _p25 = {ctor: "_Tuple3",_0: c,_1: _p26,_2: _p27};
                  if (_p25.ctor === "_Tuple3" && _p25._0.ctor === "Black" && _p25._1.ctor === "Red" && _p25._2.ctor === "LBlack")
                  {
                        return A5(RBNode_elm_builtin,
                        Black,
                        _p20._0._1,
                        _p20._0._2,
                        _p20._0._3,
                        _p20._0._4);
                     } else {
                        return A4(reportRemBug,
                        "Black/Red/LBlack",
                        c,
                        $Basics.toString(_p26),
                        $Basics.toString(_p27));
                     }
               } else {
                  var _p31 = _p20._0._2;
                  var _p30 = _p20._0._4;
                  var _p29 = _p20._0._1;
                  var l$ = A5(removeMax,_p20._0._0,_p29,_p31,_p20._0._3,_p30);
                  var _p28 = A3(maxWithDefault,_p29,_p31,_p30);
                  var k = _p28._0;
                  var v = _p28._1;
                  return A5(bubble,c,k,v,l$,r);
               }
         }
   });
   var update = F3(function (k,alter,dict) {
      var up = function (dict) {
         var _p32 = dict;
         if (_p32.ctor === "RBEmpty_elm_builtin") {
               var _p33 = alter($Maybe.Nothing);
               if (_p33.ctor === "Nothing") {
                     return {ctor: "_Tuple2",_0: Same,_1: empty};
                  } else {
                     return {ctor: "_Tuple2"
                            ,_0: Insert
                            ,_1: A5(RBNode_elm_builtin,Red,k,_p33._0,empty,empty)};
                  }
            } else {
               var _p44 = _p32._2;
               var _p43 = _p32._4;
               var _p42 = _p32._3;
               var _p41 = _p32._1;
               var _p40 = _p32._0;
               var _p34 = A2($Basics.compare,k,_p41);
               switch (_p34.ctor)
               {case "EQ": var _p35 = alter($Maybe.Just(_p44));
                    if (_p35.ctor === "Nothing") {
                          return {ctor: "_Tuple2"
                                 ,_0: Remove
                                 ,_1: A3(rem,_p40,_p42,_p43)};
                       } else {
                          return {ctor: "_Tuple2"
                                 ,_0: Same
                                 ,_1: A5(RBNode_elm_builtin,_p40,_p41,_p35._0,_p42,_p43)};
                       }
                  case "LT": var _p36 = up(_p42);
                    var flag = _p36._0;
                    var newLeft = _p36._1;
                    var _p37 = flag;
                    switch (_p37.ctor)
                    {case "Same": return {ctor: "_Tuple2"
                                         ,_0: Same
                                         ,_1: A5(RBNode_elm_builtin,_p40,_p41,_p44,newLeft,_p43)};
                       case "Insert": return {ctor: "_Tuple2"
                                             ,_0: Insert
                                             ,_1: A5(balance,_p40,_p41,_p44,newLeft,_p43)};
                       default: return {ctor: "_Tuple2"
                                       ,_0: Remove
                                       ,_1: A5(bubble,_p40,_p41,_p44,newLeft,_p43)};}
                  default: var _p38 = up(_p43);
                    var flag = _p38._0;
                    var newRight = _p38._1;
                    var _p39 = flag;
                    switch (_p39.ctor)
                    {case "Same": return {ctor: "_Tuple2"
                                         ,_0: Same
                                         ,_1: A5(RBNode_elm_builtin,_p40,_p41,_p44,_p42,newRight)};
                       case "Insert": return {ctor: "_Tuple2"
                                             ,_0: Insert
                                             ,_1: A5(balance,_p40,_p41,_p44,_p42,newRight)};
                       default: return {ctor: "_Tuple2"
                                       ,_0: Remove
                                       ,_1: A5(bubble,_p40,_p41,_p44,_p42,newRight)};}}
            }
      };
      var _p45 = up(dict);
      var flag = _p45._0;
      var updatedDict = _p45._1;
      var _p46 = flag;
      switch (_p46.ctor)
      {case "Same": return updatedDict;
         case "Insert": return ensureBlackRoot(updatedDict);
         default: return blacken(updatedDict);}
   });
   var insert = F3(function (key,value,dict) {
      return A3(update,
      key,
      $Basics.always($Maybe.Just(value)),
      dict);
   });
   var singleton = F2(function (key,value) {
      return A3(insert,key,value,empty);
   });
   var union = F2(function (t1,t2) {
      return A3(foldl,insert,t2,t1);
   });
   var fromList = function (assocs) {
      return A3($List.foldl,
      F2(function (_p47,dict) {
         var _p48 = _p47;
         return A3(insert,_p48._0,_p48._1,dict);
      }),
      empty,
      assocs);
   };
   var filter = F2(function (predicate,dictionary) {
      var add = F3(function (key,value,dict) {
         return A2(predicate,key,value) ? A3(insert,
         key,
         value,
         dict) : dict;
      });
      return A3(foldl,add,empty,dictionary);
   });
   var intersect = F2(function (t1,t2) {
      return A2(filter,
      F2(function (k,_p49) {    return A2(member,k,t2);}),
      t1);
   });
   var partition = F2(function (predicate,dict) {
      var add = F3(function (key,value,_p50) {
         var _p51 = _p50;
         var _p53 = _p51._1;
         var _p52 = _p51._0;
         return A2(predicate,key,value) ? {ctor: "_Tuple2"
                                          ,_0: A3(insert,key,value,_p52)
                                          ,_1: _p53} : {ctor: "_Tuple2"
                                                       ,_0: _p52
                                                       ,_1: A3(insert,key,value,_p53)};
      });
      return A3(foldl,add,{ctor: "_Tuple2",_0: empty,_1: empty},dict);
   });
   var remove = F2(function (key,dict) {
      return A3(update,key,$Basics.always($Maybe.Nothing),dict);
   });
   var diff = F2(function (t1,t2) {
      return A3(foldl,
      F3(function (k,v,t) {    return A2(remove,k,t);}),
      t1,
      t2);
   });
   return _elm.Dict.values = {_op: _op
                             ,empty: empty
                             ,singleton: singleton
                             ,insert: insert
                             ,update: update
                             ,isEmpty: isEmpty
                             ,get: get
                             ,remove: remove
                             ,member: member
                             ,size: size
                             ,filter: filter
                             ,partition: partition
                             ,foldl: foldl
                             ,foldr: foldr
                             ,map: map
                             ,union: union
                             ,intersect: intersect
                             ,diff: diff
                             ,keys: keys
                             ,values: values
                             ,toList: toList
                             ,fromList: fromList};
};
Elm.Set = Elm.Set || {};
Elm.Set.make = function (_elm) {
   "use strict";
   _elm.Set = _elm.Set || {};
   if (_elm.Set.values) return _elm.Set.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Dict = Elm.Dict.make(_elm),
   $List = Elm.List.make(_elm);
   var _op = {};
   var foldr = F3(function (f,b,_p0) {
      var _p1 = _p0;
      return A3($Dict.foldr,
      F3(function (k,_p2,b) {    return A2(f,k,b);}),
      b,
      _p1._0);
   });
   var foldl = F3(function (f,b,_p3) {
      var _p4 = _p3;
      return A3($Dict.foldl,
      F3(function (k,_p5,b) {    return A2(f,k,b);}),
      b,
      _p4._0);
   });
   var toList = function (_p6) {
      var _p7 = _p6;
      return $Dict.keys(_p7._0);
   };
   var size = function (_p8) {
      var _p9 = _p8;
      return $Dict.size(_p9._0);
   };
   var member = F2(function (k,_p10) {
      var _p11 = _p10;
      return A2($Dict.member,k,_p11._0);
   });
   var isEmpty = function (_p12) {
      var _p13 = _p12;
      return $Dict.isEmpty(_p13._0);
   };
   var Set_elm_builtin = function (a) {
      return {ctor: "Set_elm_builtin",_0: a};
   };
   var empty = Set_elm_builtin($Dict.empty);
   var singleton = function (k) {
      return Set_elm_builtin(A2($Dict.singleton,
      k,
      {ctor: "_Tuple0"}));
   };
   var insert = F2(function (k,_p14) {
      var _p15 = _p14;
      return Set_elm_builtin(A3($Dict.insert,
      k,
      {ctor: "_Tuple0"},
      _p15._0));
   });
   var fromList = function (xs) {
      return A3($List.foldl,insert,empty,xs);
   };
   var map = F2(function (f,s) {
      return fromList(A2($List.map,f,toList(s)));
   });
   var remove = F2(function (k,_p16) {
      var _p17 = _p16;
      return Set_elm_builtin(A2($Dict.remove,k,_p17._0));
   });
   var union = F2(function (_p19,_p18) {
      var _p20 = _p19;
      var _p21 = _p18;
      return Set_elm_builtin(A2($Dict.union,_p20._0,_p21._0));
   });
   var intersect = F2(function (_p23,_p22) {
      var _p24 = _p23;
      var _p25 = _p22;
      return Set_elm_builtin(A2($Dict.intersect,_p24._0,_p25._0));
   });
   var diff = F2(function (_p27,_p26) {
      var _p28 = _p27;
      var _p29 = _p26;
      return Set_elm_builtin(A2($Dict.diff,_p28._0,_p29._0));
   });
   var filter = F2(function (p,_p30) {
      var _p31 = _p30;
      return Set_elm_builtin(A2($Dict.filter,
      F2(function (k,_p32) {    return p(k);}),
      _p31._0));
   });
   var partition = F2(function (p,_p33) {
      var _p34 = _p33;
      var _p35 = A2($Dict.partition,
      F2(function (k,_p36) {    return p(k);}),
      _p34._0);
      var p1 = _p35._0;
      var p2 = _p35._1;
      return {ctor: "_Tuple2"
             ,_0: Set_elm_builtin(p1)
             ,_1: Set_elm_builtin(p2)};
   });
   return _elm.Set.values = {_op: _op
                            ,empty: empty
                            ,singleton: singleton
                            ,insert: insert
                            ,remove: remove
                            ,isEmpty: isEmpty
                            ,member: member
                            ,size: size
                            ,foldl: foldl
                            ,foldr: foldr
                            ,map: map
                            ,filter: filter
                            ,partition: partition
                            ,union: union
                            ,intersect: intersect
                            ,diff: diff
                            ,toList: toList
                            ,fromList: fromList};
};
Elm.List = Elm.List || {};
Elm.List.Extra = Elm.List.Extra || {};
Elm.List.Extra.make = function (_elm) {
   "use strict";
   _elm.List = _elm.List || {};
   _elm.List.Extra = _elm.List.Extra || {};
   if (_elm.List.Extra.values) return _elm.List.Extra.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Set = Elm.Set.make(_elm),
   $Signal = Elm.Signal.make(_elm);
   var _op = {};
   var zip5 = $List.map5(F5(function (v0,v1,v2,v3,v4) {
      return {ctor: "_Tuple5",_0: v0,_1: v1,_2: v2,_3: v3,_4: v4};
   }));
   var zip4 = $List.map4(F4(function (v0,v1,v2,v3) {
      return {ctor: "_Tuple4",_0: v0,_1: v1,_2: v2,_3: v3};
   }));
   var zip3 = $List.map3(F3(function (v0,v1,v2) {
      return {ctor: "_Tuple3",_0: v0,_1: v1,_2: v2};
   }));
   var zip = $List.map2(F2(function (v0,v1) {
      return {ctor: "_Tuple2",_0: v0,_1: v1};
   }));
   var isPrefixOf = function (prefix) {
      return function (_p0) {
         return A2($List.all,
         $Basics.identity,
         A3($List.map2,
         F2(function (x,y) {    return _U.eq(x,y);}),
         prefix,
         _p0));
      };
   };
   var isSuffixOf = F2(function (suffix,xs) {
      return A2(isPrefixOf,
      $List.reverse(suffix),
      $List.reverse(xs));
   });
   var selectSplit = function (xs) {
      var _p1 = xs;
      if (_p1.ctor === "[]") {
            return _U.list([]);
         } else {
            var _p5 = _p1._1;
            var _p4 = _p1._0;
            return A2($List._op["::"],
            {ctor: "_Tuple3",_0: _U.list([]),_1: _p4,_2: _p5},
            A2($List.map,
            function (_p2) {
               var _p3 = _p2;
               return {ctor: "_Tuple3"
                      ,_0: A2($List._op["::"],_p4,_p3._0)
                      ,_1: _p3._1
                      ,_2: _p3._2};
            },
            selectSplit(_p5)));
         }
   };
   var select = function (xs) {
      var _p6 = xs;
      if (_p6.ctor === "[]") {
            return _U.list([]);
         } else {
            var _p10 = _p6._1;
            var _p9 = _p6._0;
            return A2($List._op["::"],
            {ctor: "_Tuple2",_0: _p9,_1: _p10},
            A2($List.map,
            function (_p7) {
               var _p8 = _p7;
               return {ctor: "_Tuple2"
                      ,_0: _p8._0
                      ,_1: A2($List._op["::"],_p9,_p8._1)};
            },
            select(_p10)));
         }
   };
   var tailsHelp = F2(function (e,list) {
      var _p11 = list;
      if (_p11.ctor === "::") {
            var _p12 = _p11._0;
            return A2($List._op["::"],
            A2($List._op["::"],e,_p12),
            A2($List._op["::"],_p12,_p11._1));
         } else {
            return _U.list([]);
         }
   });
   var tails = A2($List.foldr,tailsHelp,_U.list([_U.list([])]));
   var isInfixOf = F2(function (infix,xs) {
      return A2($List.any,isPrefixOf(infix),tails(xs));
   });
   var inits = A2($List.foldr,
   F2(function (e,acc) {
      return A2($List._op["::"],
      _U.list([]),
      A2($List.map,
      F2(function (x,y) {    return A2($List._op["::"],x,y);})(e),
      acc));
   }),
   _U.list([_U.list([])]));
   var groupByTransitive = F2(function (cmp,xs$) {
      var _p13 = xs$;
      if (_p13.ctor === "[]") {
            return _U.list([]);
         } else {
            if (_p13._1.ctor === "[]") {
                  return _U.list([_U.list([_p13._0])]);
               } else {
                  var _p15 = _p13._0;
                  var _p14 = A2(groupByTransitive,cmp,_p13._1);
                  if (_p14.ctor === "::") {
                        return A2(cmp,_p15,_p13._1._0) ? A2($List._op["::"],
                        A2($List._op["::"],_p15,_p14._0),
                        _p14._1) : A2($List._op["::"],_U.list([_p15]),_p14);
                     } else {
                        return _U.list([]);
                     }
               }
         }
   });
   var stripPrefix = F2(function (prefix,xs) {
      var step = F2(function (e,m) {
         var _p16 = m;
         if (_p16.ctor === "Nothing") {
               return $Maybe.Nothing;
            } else {
               if (_p16._0.ctor === "[]") {
                     return $Maybe.Nothing;
                  } else {
                     return _U.eq(e,
                     _p16._0._0) ? $Maybe.Just(_p16._0._1) : $Maybe.Nothing;
                  }
            }
      });
      return A3($List.foldl,step,$Maybe.Just(xs),prefix);
   });
   var dropWhileEnd = function (p) {
      return A2($List.foldr,
      F2(function (x,xs) {
         return p(x) && $List.isEmpty(xs) ? _U.list([]) : A2($List._op["::"],
         x,
         xs);
      }),
      _U.list([]));
   };
   var takeWhileEnd = function (p) {
      var step = F2(function (x,_p17) {
         var _p18 = _p17;
         var _p19 = _p18._0;
         return p(x) && _p18._1 ? {ctor: "_Tuple2"
                                  ,_0: A2($List._op["::"],x,_p19)
                                  ,_1: true} : {ctor: "_Tuple2",_0: _p19,_1: false};
      });
      return function (_p20) {
         return $Basics.fst(A3($List.foldr,
         step,
         {ctor: "_Tuple2",_0: _U.list([]),_1: true},
         _p20));
      };
   };
   var splitAt = F2(function (n,xs) {
      return {ctor: "_Tuple2"
             ,_0: A2($List.take,n,xs)
             ,_1: A2($List.drop,n,xs)};
   });
   var unfoldr = F2(function (f,seed) {
      var _p21 = f(seed);
      if (_p21.ctor === "Nothing") {
            return _U.list([]);
         } else {
            return A2($List._op["::"],
            _p21._0._0,
            A2(unfoldr,f,_p21._0._1));
         }
   });
   var scanr1 = F2(function (f,xs$) {
      var _p22 = xs$;
      if (_p22.ctor === "[]") {
            return _U.list([]);
         } else {
            if (_p22._1.ctor === "[]") {
                  return _U.list([_p22._0]);
               } else {
                  var _p23 = A2(scanr1,f,_p22._1);
                  if (_p23.ctor === "::") {
                        return A2($List._op["::"],A2(f,_p22._0,_p23._0),_p23);
                     } else {
                        return _U.list([]);
                     }
               }
         }
   });
   var scanr = F3(function (f,acc,xs$) {
      var _p24 = xs$;
      if (_p24.ctor === "[]") {
            return _U.list([acc]);
         } else {
            var _p25 = A3(scanr,f,acc,_p24._1);
            if (_p25.ctor === "::") {
                  return A2($List._op["::"],A2(f,_p24._0,_p25._0),_p25);
               } else {
                  return _U.list([]);
               }
         }
   });
   var scanl1 = F2(function (f,xs$) {
      var _p26 = xs$;
      if (_p26.ctor === "[]") {
            return _U.list([]);
         } else {
            return A3($List.scanl,f,_p26._0,_p26._1);
         }
   });
   var foldr1 = F2(function (f,xs) {
      var mf = F2(function (x,m) {
         return $Maybe.Just(function () {
            var _p27 = m;
            if (_p27.ctor === "Nothing") {
                  return x;
               } else {
                  return A2(f,x,_p27._0);
               }
         }());
      });
      return A3($List.foldr,mf,$Maybe.Nothing,xs);
   });
   var foldl1 = F2(function (f,xs) {
      var mf = F2(function (x,m) {
         return $Maybe.Just(function () {
            var _p28 = m;
            if (_p28.ctor === "Nothing") {
                  return x;
               } else {
                  return A2(f,_p28._0,x);
               }
         }());
      });
      return A3($List.foldl,mf,$Maybe.Nothing,xs);
   });
   var uniqueHelp = F2(function (existing,remaining) {
      uniqueHelp: while (true) {
         var _p29 = remaining;
         if (_p29.ctor === "[]") {
               return _U.list([]);
            } else {
               var _p31 = _p29._1;
               var _p30 = _p29._0;
               if (A2($Set.member,_p30,existing)) {
                     var _v18 = existing,_v19 = _p31;
                     existing = _v18;
                     remaining = _v19;
                     continue uniqueHelp;
                  } else return A2($List._op["::"],
                  _p30,
                  A2(uniqueHelp,A2($Set.insert,_p30,existing),_p31));
            }
      }
   });
   var unique = function (list) {
      return A2(uniqueHelp,$Set.empty,list);
   };
   var interweaveHelp = F3(function (l1,l2,acc) {
      interweaveHelp: while (true) {
         var _p32 = {ctor: "_Tuple2",_0: l1,_1: l2};
         _v20_1: do {
            if (_p32._0.ctor === "::") {
                  if (_p32._1.ctor === "::") {
                        var _v21 = _p32._0._1,
                        _v22 = _p32._1._1,
                        _v23 = A2($Basics._op["++"],
                        acc,
                        _U.list([_p32._0._0,_p32._1._0]));
                        l1 = _v21;
                        l2 = _v22;
                        acc = _v23;
                        continue interweaveHelp;
                     } else {
                        break _v20_1;
                     }
               } else {
                  if (_p32._1.ctor === "[]") {
                        break _v20_1;
                     } else {
                        return A2($Basics._op["++"],acc,_p32._1);
                     }
               }
         } while (false);
         return A2($Basics._op["++"],acc,_p32._0);
      }
   });
   var interweave = F2(function (l1,l2) {
      return A3(interweaveHelp,l1,l2,_U.list([]));
   });
   var permutations = function (xs$) {
      var _p33 = xs$;
      if (_p33.ctor === "[]") {
            return _U.list([_U.list([])]);
         } else {
            var f = function (_p34) {
               var _p35 = _p34;
               return A2($List.map,
               F2(function (x,y) {
                  return A2($List._op["::"],x,y);
               })(_p35._0),
               permutations(_p35._1));
            };
            return A2($List.concatMap,f,select(_p33));
         }
   };
   var isPermutationOf = F2(function (permut,xs) {
      return A2($List.member,permut,permutations(xs));
   });
   var subsequencesNonEmpty = function (xs) {
      var _p36 = xs;
      if (_p36.ctor === "[]") {
            return _U.list([]);
         } else {
            var _p37 = _p36._0;
            var f = F2(function (ys,r) {
               return A2($List._op["::"],
               ys,
               A2($List._op["::"],A2($List._op["::"],_p37,ys),r));
            });
            return A2($List._op["::"],
            _U.list([_p37]),
            A3($List.foldr,f,_U.list([]),subsequencesNonEmpty(_p36._1)));
         }
   };
   var subsequences = function (xs) {
      return A2($List._op["::"],
      _U.list([]),
      subsequencesNonEmpty(xs));
   };
   var isSubsequenceOf = F2(function (subseq,xs) {
      return A2($List.member,subseq,subsequences(xs));
   });
   var transpose = function (ll) {
      transpose: while (true) {
         var _p38 = ll;
         if (_p38.ctor === "[]") {
               return _U.list([]);
            } else {
               if (_p38._0.ctor === "[]") {
                     var _v28 = _p38._1;
                     ll = _v28;
                     continue transpose;
                  } else {
                     var _p39 = _p38._1;
                     var tails = A2($List.filterMap,$List.tail,_p39);
                     var heads = A2($List.filterMap,$List.head,_p39);
                     return A2($List._op["::"],
                     A2($List._op["::"],_p38._0._0,heads),
                     transpose(A2($List._op["::"],_p38._0._1,tails)));
                  }
            }
      }
   };
   var intercalate = function (xs) {
      return function (_p40) {
         return $List.concat(A2($List.intersperse,xs,_p40));
      };
   };
   var removeWhen = F2(function (pred,list) {
      return A2($List.filter,
      function (_p41) {
         return $Basics.not(pred(_p41));
      },
      list);
   });
   var singleton = function (x) {    return _U.list([x]);};
   var replaceIf = F3(function (predicate,replacement,list) {
      return A2($List.map,
      function (item) {
         return predicate(item) ? replacement : item;
      },
      list);
   });
   var findIndices = function (p) {
      return function (_p42) {
         return A2($List.map,
         $Basics.fst,
         A2($List.filter,
         function (_p43) {
            var _p44 = _p43;
            return p(_p44._1);
         },
         A2($List.indexedMap,
         F2(function (v0,v1) {
            return {ctor: "_Tuple2",_0: v0,_1: v1};
         }),
         _p42)));
      };
   };
   var findIndex = function (p) {
      return function (_p45) {
         return $List.head(A2(findIndices,p,_p45));
      };
   };
   var elemIndices = function (x) {
      return findIndices(F2(function (x,y) {
         return _U.eq(x,y);
      })(x));
   };
   var elemIndex = function (x) {
      return findIndex(F2(function (x,y) {
         return _U.eq(x,y);
      })(x));
   };
   var find = F2(function (predicate,list) {
      find: while (true) {
         var _p46 = list;
         if (_p46.ctor === "[]") {
               return $Maybe.Nothing;
            } else {
               var _p47 = _p46._0;
               if (predicate(_p47)) return $Maybe.Just(_p47); else {
                     var _v31 = predicate,_v32 = _p46._1;
                     predicate = _v31;
                     list = _v32;
                     continue find;
                  }
            }
      }
   });
   var notMember = function (x) {
      return function (_p48) {
         return $Basics.not(A2($List.member,x,_p48));
      };
   };
   var andThen = $Basics.flip($List.concatMap);
   var lift2 = F3(function (f,la,lb) {
      return A2(andThen,
      la,
      function (a) {
         return A2(andThen,
         lb,
         function (b) {
            return _U.list([A2(f,a,b)]);
         });
      });
   });
   var lift3 = F4(function (f,la,lb,lc) {
      return A2(andThen,
      la,
      function (a) {
         return A2(andThen,
         lb,
         function (b) {
            return A2(andThen,
            lc,
            function (c) {
               return _U.list([A3(f,a,b,c)]);
            });
         });
      });
   });
   var lift4 = F5(function (f,la,lb,lc,ld) {
      return A2(andThen,
      la,
      function (a) {
         return A2(andThen,
         lb,
         function (b) {
            return A2(andThen,
            lc,
            function (c) {
               return A2(andThen,
               ld,
               function (d) {
                  return _U.list([A4(f,a,b,c,d)]);
               });
            });
         });
      });
   });
   var andMap = F2(function (fl,l) {
      return A3($List.map2,
      F2(function (x,y) {    return x(y);}),
      fl,
      l);
   });
   var dropDuplicates = function (list) {
      var step = F2(function (next,_p49) {
         var _p50 = _p49;
         var _p52 = _p50._0;
         var _p51 = _p50._1;
         return A2($Set.member,next,_p52) ? {ctor: "_Tuple2"
                                            ,_0: _p52
                                            ,_1: _p51} : {ctor: "_Tuple2"
                                                         ,_0: A2($Set.insert,next,_p52)
                                                         ,_1: A2($List._op["::"],next,_p51)};
      });
      return $List.reverse($Basics.snd(A3($List.foldl,
      step,
      {ctor: "_Tuple2",_0: $Set.empty,_1: _U.list([])},
      list)));
   };
   var dropWhile = F2(function (predicate,list) {
      dropWhile: while (true) {
         var _p53 = list;
         if (_p53.ctor === "[]") {
               return _U.list([]);
            } else {
               if (predicate(_p53._0)) {
                     var _v35 = predicate,_v36 = _p53._1;
                     predicate = _v35;
                     list = _v36;
                     continue dropWhile;
                  } else return list;
            }
      }
   });
   var takeWhile = F2(function (predicate,list) {
      var _p54 = list;
      if (_p54.ctor === "[]") {
            return _U.list([]);
         } else {
            var _p55 = _p54._0;
            return predicate(_p55) ? A2($List._op["::"],
            _p55,
            A2(takeWhile,predicate,_p54._1)) : _U.list([]);
         }
   });
   var span = F2(function (p,xs) {
      return {ctor: "_Tuple2"
             ,_0: A2(takeWhile,p,xs)
             ,_1: A2(dropWhile,p,xs)};
   });
   var $break = function (p) {
      return span(function (_p56) {
         return $Basics.not(p(_p56));
      });
   };
   var groupBy = F2(function (eq,xs$) {
      var _p57 = xs$;
      if (_p57.ctor === "[]") {
            return _U.list([]);
         } else {
            var _p59 = _p57._0;
            var _p58 = A2(span,eq(_p59),_p57._1);
            var ys = _p58._0;
            var zs = _p58._1;
            return A2($List._op["::"],
            A2($List._op["::"],_p59,ys),
            A2(groupBy,eq,zs));
         }
   });
   var group = groupBy(F2(function (x,y) {
      return _U.eq(x,y);
   }));
   var minimumBy = F2(function (f,ls) {
      var minBy = F2(function (x,_p60) {
         var _p61 = _p60;
         var _p62 = _p61._1;
         var fx = f(x);
         return _U.cmp(fx,_p62) < 0 ? {ctor: "_Tuple2"
                                      ,_0: x
                                      ,_1: fx} : {ctor: "_Tuple2",_0: _p61._0,_1: _p62};
      });
      var _p63 = ls;
      if (_p63.ctor === "::") {
            if (_p63._1.ctor === "[]") {
                  return $Maybe.Just(_p63._0);
               } else {
                  var _p64 = _p63._0;
                  return $Maybe.Just($Basics.fst(A3($List.foldl,
                  minBy,
                  {ctor: "_Tuple2",_0: _p64,_1: f(_p64)},
                  _p63._1)));
               }
         } else {
            return $Maybe.Nothing;
         }
   });
   var maximumBy = F2(function (f,ls) {
      var maxBy = F2(function (x,_p65) {
         var _p66 = _p65;
         var _p67 = _p66._1;
         var fx = f(x);
         return _U.cmp(fx,_p67) > 0 ? {ctor: "_Tuple2"
                                      ,_0: x
                                      ,_1: fx} : {ctor: "_Tuple2",_0: _p66._0,_1: _p67};
      });
      var _p68 = ls;
      if (_p68.ctor === "::") {
            if (_p68._1.ctor === "[]") {
                  return $Maybe.Just(_p68._0);
               } else {
                  var _p69 = _p68._0;
                  return $Maybe.Just($Basics.fst(A3($List.foldl,
                  maxBy,
                  {ctor: "_Tuple2",_0: _p69,_1: f(_p69)},
                  _p68._1)));
               }
         } else {
            return $Maybe.Nothing;
         }
   });
   var uncons = function (xs) {
      var _p70 = xs;
      if (_p70.ctor === "[]") {
            return $Maybe.Nothing;
         } else {
            return $Maybe.Just({ctor: "_Tuple2"
                               ,_0: _p70._0
                               ,_1: _p70._1});
         }
   };
   var iterate = F2(function (f,x) {
      var _p71 = f(x);
      if (_p71.ctor === "Just") {
            return A2($List._op["::"],x,A2(iterate,f,_p71._0));
         } else {
            return _U.list([x]);
         }
   });
   var getAt = F2(function (xs,idx) {
      return $List.head(A2($List.drop,idx,xs));
   });
   _op["!!"] = getAt;
   var init = function () {
      var maybe = F2(function (d,f) {
         return function (_p72) {
            return A2($Maybe.withDefault,d,A2($Maybe.map,f,_p72));
         };
      });
      return A2($List.foldr,
      function (_p73) {
         return A2(F2(function (x,y) {
            return function (_p74) {
               return x(y(_p74));
            };
         }),
         $Maybe.Just,
         A2(maybe,
         _U.list([]),
         F2(function (x,y) {
            return A2($List._op["::"],x,y);
         })(_p73)));
      },
      $Maybe.Nothing);
   }();
   var last = foldl1($Basics.flip($Basics.always));
   return _elm.List.Extra.values = {_op: _op
                                   ,last: last
                                   ,init: init
                                   ,getAt: getAt
                                   ,uncons: uncons
                                   ,minimumBy: minimumBy
                                   ,maximumBy: maximumBy
                                   ,andMap: andMap
                                   ,andThen: andThen
                                   ,takeWhile: takeWhile
                                   ,dropWhile: dropWhile
                                   ,dropDuplicates: dropDuplicates
                                   ,replaceIf: replaceIf
                                   ,singleton: singleton
                                   ,removeWhen: removeWhen
                                   ,iterate: iterate
                                   ,intercalate: intercalate
                                   ,transpose: transpose
                                   ,subsequences: subsequences
                                   ,permutations: permutations
                                   ,interweave: interweave
                                   ,unique: unique
                                   ,foldl1: foldl1
                                   ,foldr1: foldr1
                                   ,scanl1: scanl1
                                   ,scanr: scanr
                                   ,scanr1: scanr1
                                   ,unfoldr: unfoldr
                                   ,splitAt: splitAt
                                   ,takeWhileEnd: takeWhileEnd
                                   ,dropWhileEnd: dropWhileEnd
                                   ,span: span
                                   ,$break: $break
                                   ,stripPrefix: stripPrefix
                                   ,group: group
                                   ,groupBy: groupBy
                                   ,groupByTransitive: groupByTransitive
                                   ,inits: inits
                                   ,tails: tails
                                   ,select: select
                                   ,selectSplit: selectSplit
                                   ,isPrefixOf: isPrefixOf
                                   ,isSuffixOf: isSuffixOf
                                   ,isInfixOf: isInfixOf
                                   ,isSubsequenceOf: isSubsequenceOf
                                   ,isPermutationOf: isPermutationOf
                                   ,notMember: notMember
                                   ,find: find
                                   ,elemIndex: elemIndex
                                   ,elemIndices: elemIndices
                                   ,findIndex: findIndex
                                   ,findIndices: findIndices
                                   ,zip: zip
                                   ,zip3: zip3
                                   ,zip4: zip4
                                   ,zip5: zip5
                                   ,lift2: lift2
                                   ,lift3: lift3
                                   ,lift4: lift4};
};
Elm.Native.Bitwise = {};
Elm.Native.Bitwise.make = function(localRuntime) {
	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Bitwise = localRuntime.Native.Bitwise || {};
	if (localRuntime.Native.Bitwise.values)
	{
		return localRuntime.Native.Bitwise.values;
	}

	function and(a, b) { return a & b; }
	function or(a, b) { return a | b; }
	function xor(a, b) { return a ^ b; }
	function not(a) { return ~a; }
	function sll(a, offset) { return a << offset; }
	function sra(a, offset) { return a >> offset; }
	function srl(a, offset) { return a >>> offset; }

	return localRuntime.Native.Bitwise.values = {
		and: F2(and),
		or: F2(or),
		xor: F2(xor),
		complement: not,
		shiftLeft: F2(sll),
		shiftRightArithmatic: F2(sra),
		shiftRightLogical: F2(srl)
	};
};

Elm.Bitwise = Elm.Bitwise || {};
Elm.Bitwise.make = function (_elm) {
   "use strict";
   _elm.Bitwise = _elm.Bitwise || {};
   if (_elm.Bitwise.values) return _elm.Bitwise.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Native$Bitwise = Elm.Native.Bitwise.make(_elm);
   var _op = {};
   var shiftRightLogical = $Native$Bitwise.shiftRightLogical;
   var shiftRight = $Native$Bitwise.shiftRightArithmatic;
   var shiftLeft = $Native$Bitwise.shiftLeft;
   var complement = $Native$Bitwise.complement;
   var xor = $Native$Bitwise.xor;
   var or = $Native$Bitwise.or;
   var and = $Native$Bitwise.and;
   return _elm.Bitwise.values = {_op: _op
                                ,and: and
                                ,or: or
                                ,xor: xor
                                ,complement: complement
                                ,shiftLeft: shiftLeft
                                ,shiftRight: shiftRight
                                ,shiftRightLogical: shiftRightLogical};
};
Elm.Native.Array = {};
Elm.Native.Array.make = function(localRuntime) {

	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Array = localRuntime.Native.Array || {};
	if (localRuntime.Native.Array.values)
	{
		return localRuntime.Native.Array.values;
	}
	if ('values' in Elm.Native.Array)
	{
		return localRuntime.Native.Array.values = Elm.Native.Array.values;
	}

	var List = Elm.Native.List.make(localRuntime);

	// A RRB-Tree has two distinct data types.
	// Leaf -> "height"  is always 0
	//         "table"   is an array of elements
	// Node -> "height"  is always greater than 0
	//         "table"   is an array of child nodes
	//         "lengths" is an array of accumulated lengths of the child nodes

	// M is the maximal table size. 32 seems fast. E is the allowed increase
	// of search steps when concatting to find an index. Lower values will
	// decrease balancing, but will increase search steps.
	var M = 32;
	var E = 2;

	// An empty array.
	var empty = {
		ctor: '_Array',
		height: 0,
		table: []
	};


	function get(i, array)
	{
		if (i < 0 || i >= length(array))
		{
			throw new Error(
				'Index ' + i + ' is out of range. Check the length of ' +
				'your array first or use getMaybe or getWithDefault.');
		}
		return unsafeGet(i, array);
	}


	function unsafeGet(i, array)
	{
		for (var x = array.height; x > 0; x--)
		{
			var slot = i >> (x * 5);
			while (array.lengths[slot] <= i)
			{
				slot++;
			}
			if (slot > 0)
			{
				i -= array.lengths[slot - 1];
			}
			array = array.table[slot];
		}
		return array.table[i];
	}


	// Sets the value at the index i. Only the nodes leading to i will get
	// copied and updated.
	function set(i, item, array)
	{
		if (i < 0 || length(array) <= i)
		{
			return array;
		}
		return unsafeSet(i, item, array);
	}


	function unsafeSet(i, item, array)
	{
		array = nodeCopy(array);

		if (array.height === 0)
		{
			array.table[i] = item;
		}
		else
		{
			var slot = getSlot(i, array);
			if (slot > 0)
			{
				i -= array.lengths[slot - 1];
			}
			array.table[slot] = unsafeSet(i, item, array.table[slot]);
		}
		return array;
	}


	function initialize(len, f)
	{
		if (len <= 0)
		{
			return empty;
		}
		var h = Math.floor( Math.log(len) / Math.log(M) );
		return initialize_(f, h, 0, len);
	}

	function initialize_(f, h, from, to)
	{
		if (h === 0)
		{
			var table = new Array((to - from) % (M + 1));
			for (var i = 0; i < table.length; i++)
			{
			  table[i] = f(from + i);
			}
			return {
				ctor: '_Array',
				height: 0,
				table: table
			};
		}

		var step = Math.pow(M, h);
		var table = new Array(Math.ceil((to - from) / step));
		var lengths = new Array(table.length);
		for (var i = 0; i < table.length; i++)
		{
			table[i] = initialize_(f, h - 1, from + (i * step), Math.min(from + ((i + 1) * step), to));
			lengths[i] = length(table[i]) + (i > 0 ? lengths[i-1] : 0);
		}
		return {
			ctor: '_Array',
			height: h,
			table: table,
			lengths: lengths
		};
	}

	function fromList(list)
	{
		if (list === List.Nil)
		{
			return empty;
		}

		// Allocate M sized blocks (table) and write list elements to it.
		var table = new Array(M);
		var nodes = [];
		var i = 0;

		while (list.ctor !== '[]')
		{
			table[i] = list._0;
			list = list._1;
			i++;

			// table is full, so we can push a leaf containing it into the
			// next node.
			if (i === M)
			{
				var leaf = {
					ctor: '_Array',
					height: 0,
					table: table
				};
				fromListPush(leaf, nodes);
				table = new Array(M);
				i = 0;
			}
		}

		// Maybe there is something left on the table.
		if (i > 0)
		{
			var leaf = {
				ctor: '_Array',
				height: 0,
				table: table.splice(0, i)
			};
			fromListPush(leaf, nodes);
		}

		// Go through all of the nodes and eventually push them into higher nodes.
		for (var h = 0; h < nodes.length - 1; h++)
		{
			if (nodes[h].table.length > 0)
			{
				fromListPush(nodes[h], nodes);
			}
		}

		var head = nodes[nodes.length - 1];
		if (head.height > 0 && head.table.length === 1)
		{
			return head.table[0];
		}
		else
		{
			return head;
		}
	}

	// Push a node into a higher node as a child.
	function fromListPush(toPush, nodes)
	{
		var h = toPush.height;

		// Maybe the node on this height does not exist.
		if (nodes.length === h)
		{
			var node = {
				ctor: '_Array',
				height: h + 1,
				table: [],
				lengths: []
			};
			nodes.push(node);
		}

		nodes[h].table.push(toPush);
		var len = length(toPush);
		if (nodes[h].lengths.length > 0)
		{
			len += nodes[h].lengths[nodes[h].lengths.length - 1];
		}
		nodes[h].lengths.push(len);

		if (nodes[h].table.length === M)
		{
			fromListPush(nodes[h], nodes);
			nodes[h] = {
				ctor: '_Array',
				height: h + 1,
				table: [],
				lengths: []
			};
		}
	}

	// Pushes an item via push_ to the bottom right of a tree.
	function push(item, a)
	{
		var pushed = push_(item, a);
		if (pushed !== null)
		{
			return pushed;
		}

		var newTree = create(item, a.height);
		return siblise(a, newTree);
	}

	// Recursively tries to push an item to the bottom-right most
	// tree possible. If there is no space left for the item,
	// null will be returned.
	function push_(item, a)
	{
		// Handle resursion stop at leaf level.
		if (a.height === 0)
		{
			if (a.table.length < M)
			{
				var newA = {
					ctor: '_Array',
					height: 0,
					table: a.table.slice()
				};
				newA.table.push(item);
				return newA;
			}
			else
			{
			  return null;
			}
		}

		// Recursively push
		var pushed = push_(item, botRight(a));

		// There was space in the bottom right tree, so the slot will
		// be updated.
		if (pushed !== null)
		{
			var newA = nodeCopy(a);
			newA.table[newA.table.length - 1] = pushed;
			newA.lengths[newA.lengths.length - 1]++;
			return newA;
		}

		// When there was no space left, check if there is space left
		// for a new slot with a tree which contains only the item
		// at the bottom.
		if (a.table.length < M)
		{
			var newSlot = create(item, a.height - 1);
			var newA = nodeCopy(a);
			newA.table.push(newSlot);
			newA.lengths.push(newA.lengths[newA.lengths.length - 1] + length(newSlot));
			return newA;
		}
		else
		{
			return null;
		}
	}

	// Converts an array into a list of elements.
	function toList(a)
	{
		return toList_(List.Nil, a);
	}

	function toList_(list, a)
	{
		for (var i = a.table.length - 1; i >= 0; i--)
		{
			list =
				a.height === 0
					? List.Cons(a.table[i], list)
					: toList_(list, a.table[i]);
		}
		return list;
	}

	// Maps a function over the elements of an array.
	function map(f, a)
	{
		var newA = {
			ctor: '_Array',
			height: a.height,
			table: new Array(a.table.length)
		};
		if (a.height > 0)
		{
			newA.lengths = a.lengths;
		}
		for (var i = 0; i < a.table.length; i++)
		{
			newA.table[i] =
				a.height === 0
					? f(a.table[i])
					: map(f, a.table[i]);
		}
		return newA;
	}

	// Maps a function over the elements with their index as first argument.
	function indexedMap(f, a)
	{
		return indexedMap_(f, a, 0);
	}

	function indexedMap_(f, a, from)
	{
		var newA = {
			ctor: '_Array',
			height: a.height,
			table: new Array(a.table.length)
		};
		if (a.height > 0)
		{
			newA.lengths = a.lengths;
		}
		for (var i = 0; i < a.table.length; i++)
		{
			newA.table[i] =
				a.height === 0
					? A2(f, from + i, a.table[i])
					: indexedMap_(f, a.table[i], i == 0 ? from : from + a.lengths[i - 1]);
		}
		return newA;
	}

	function foldl(f, b, a)
	{
		if (a.height === 0)
		{
			for (var i = 0; i < a.table.length; i++)
			{
				b = A2(f, a.table[i], b);
			}
		}
		else
		{
			for (var i = 0; i < a.table.length; i++)
			{
				b = foldl(f, b, a.table[i]);
			}
		}
		return b;
	}

	function foldr(f, b, a)
	{
		if (a.height === 0)
		{
			for (var i = a.table.length; i--; )
			{
				b = A2(f, a.table[i], b);
			}
		}
		else
		{
			for (var i = a.table.length; i--; )
			{
				b = foldr(f, b, a.table[i]);
			}
		}
		return b;
	}

	// TODO: currently, it slices the right, then the left. This can be
	// optimized.
	function slice(from, to, a)
	{
		if (from < 0)
		{
			from += length(a);
		}
		if (to < 0)
		{
			to += length(a);
		}
		return sliceLeft(from, sliceRight(to, a));
	}

	function sliceRight(to, a)
	{
		if (to === length(a))
		{
			return a;
		}

		// Handle leaf level.
		if (a.height === 0)
		{
			var newA = { ctor:'_Array', height:0 };
			newA.table = a.table.slice(0, to);
			return newA;
		}

		// Slice the right recursively.
		var right = getSlot(to, a);
		var sliced = sliceRight(to - (right > 0 ? a.lengths[right - 1] : 0), a.table[right]);

		// Maybe the a node is not even needed, as sliced contains the whole slice.
		if (right === 0)
		{
			return sliced;
		}

		// Create new node.
		var newA = {
			ctor: '_Array',
			height: a.height,
			table: a.table.slice(0, right),
			lengths: a.lengths.slice(0, right)
		};
		if (sliced.table.length > 0)
		{
			newA.table[right] = sliced;
			newA.lengths[right] = length(sliced) + (right > 0 ? newA.lengths[right - 1] : 0);
		}
		return newA;
	}

	function sliceLeft(from, a)
	{
		if (from === 0)
		{
			return a;
		}

		// Handle leaf level.
		if (a.height === 0)
		{
			var newA = { ctor:'_Array', height:0 };
			newA.table = a.table.slice(from, a.table.length + 1);
			return newA;
		}

		// Slice the left recursively.
		var left = getSlot(from, a);
		var sliced = sliceLeft(from - (left > 0 ? a.lengths[left - 1] : 0), a.table[left]);

		// Maybe the a node is not even needed, as sliced contains the whole slice.
		if (left === a.table.length - 1)
		{
			return sliced;
		}

		// Create new node.
		var newA = {
			ctor: '_Array',
			height: a.height,
			table: a.table.slice(left, a.table.length + 1),
			lengths: new Array(a.table.length - left)
		};
		newA.table[0] = sliced;
		var len = 0;
		for (var i = 0; i < newA.table.length; i++)
		{
			len += length(newA.table[i]);
			newA.lengths[i] = len;
		}

		return newA;
	}

	// Appends two trees.
	function append(a,b)
	{
		if (a.table.length === 0)
		{
			return b;
		}
		if (b.table.length === 0)
		{
			return a;
		}

		var c = append_(a, b);

		// Check if both nodes can be crunshed together.
		if (c[0].table.length + c[1].table.length <= M)
		{
			if (c[0].table.length === 0)
			{
				return c[1];
			}
			if (c[1].table.length === 0)
			{
				return c[0];
			}

			// Adjust .table and .lengths
			c[0].table = c[0].table.concat(c[1].table);
			if (c[0].height > 0)
			{
				var len = length(c[0]);
				for (var i = 0; i < c[1].lengths.length; i++)
				{
					c[1].lengths[i] += len;
				}
				c[0].lengths = c[0].lengths.concat(c[1].lengths);
			}

			return c[0];
		}

		if (c[0].height > 0)
		{
			var toRemove = calcToRemove(a, b);
			if (toRemove > E)
			{
				c = shuffle(c[0], c[1], toRemove);
			}
		}

		return siblise(c[0], c[1]);
	}

	// Returns an array of two nodes; right and left. One node _may_ be empty.
	function append_(a, b)
	{
		if (a.height === 0 && b.height === 0)
		{
			return [a, b];
		}

		if (a.height !== 1 || b.height !== 1)
		{
			if (a.height === b.height)
			{
				a = nodeCopy(a);
				b = nodeCopy(b);
				var appended = append_(botRight(a), botLeft(b));

				insertRight(a, appended[1]);
				insertLeft(b, appended[0]);
			}
			else if (a.height > b.height)
			{
				a = nodeCopy(a);
				var appended = append_(botRight(a), b);

				insertRight(a, appended[0]);
				b = parentise(appended[1], appended[1].height + 1);
			}
			else
			{
				b = nodeCopy(b);
				var appended = append_(a, botLeft(b));

				var left = appended[0].table.length === 0 ? 0 : 1;
				var right = left === 0 ? 1 : 0;
				insertLeft(b, appended[left]);
				a = parentise(appended[right], appended[right].height + 1);
			}
		}

		// Check if balancing is needed and return based on that.
		if (a.table.length === 0 || b.table.length === 0)
		{
			return [a, b];
		}

		var toRemove = calcToRemove(a, b);
		if (toRemove <= E)
		{
			return [a, b];
		}
		return shuffle(a, b, toRemove);
	}

	// Helperfunctions for append_. Replaces a child node at the side of the parent.
	function insertRight(parent, node)
	{
		var index = parent.table.length - 1;
		parent.table[index] = node;
		parent.lengths[index] = length(node);
		parent.lengths[index] += index > 0 ? parent.lengths[index - 1] : 0;
	}

	function insertLeft(parent, node)
	{
		if (node.table.length > 0)
		{
			parent.table[0] = node;
			parent.lengths[0] = length(node);

			var len = length(parent.table[0]);
			for (var i = 1; i < parent.lengths.length; i++)
			{
				len += length(parent.table[i]);
				parent.lengths[i] = len;
			}
		}
		else
		{
			parent.table.shift();
			for (var i = 1; i < parent.lengths.length; i++)
			{
				parent.lengths[i] = parent.lengths[i] - parent.lengths[0];
			}
			parent.lengths.shift();
		}
	}

	// Returns the extra search steps for E. Refer to the paper.
	function calcToRemove(a, b)
	{
		var subLengths = 0;
		for (var i = 0; i < a.table.length; i++)
		{
			subLengths += a.table[i].table.length;
		}
		for (var i = 0; i < b.table.length; i++)
		{
			subLengths += b.table[i].table.length;
		}

		var toRemove = a.table.length + b.table.length;
		return toRemove - (Math.floor((subLengths - 1) / M) + 1);
	}

	// get2, set2 and saveSlot are helpers for accessing elements over two arrays.
	function get2(a, b, index)
	{
		return index < a.length
			? a[index]
			: b[index - a.length];
	}

	function set2(a, b, index, value)
	{
		if (index < a.length)
		{
			a[index] = value;
		}
		else
		{
			b[index - a.length] = value;
		}
	}

	function saveSlot(a, b, index, slot)
	{
		set2(a.table, b.table, index, slot);

		var l = (index === 0 || index === a.lengths.length)
			? 0
			: get2(a.lengths, a.lengths, index - 1);

		set2(a.lengths, b.lengths, index, l + length(slot));
	}

	// Creates a node or leaf with a given length at their arrays for perfomance.
	// Is only used by shuffle.
	function createNode(h, length)
	{
		if (length < 0)
		{
			length = 0;
		}
		var a = {
			ctor: '_Array',
			height: h,
			table: new Array(length)
		};
		if (h > 0)
		{
			a.lengths = new Array(length);
		}
		return a;
	}

	// Returns an array of two balanced nodes.
	function shuffle(a, b, toRemove)
	{
		var newA = createNode(a.height, Math.min(M, a.table.length + b.table.length - toRemove));
		var newB = createNode(a.height, newA.table.length - (a.table.length + b.table.length - toRemove));

		// Skip the slots with size M. More precise: copy the slot references
		// to the new node
		var read = 0;
		while (get2(a.table, b.table, read).table.length % M === 0)
		{
			set2(newA.table, newB.table, read, get2(a.table, b.table, read));
			set2(newA.lengths, newB.lengths, read, get2(a.lengths, b.lengths, read));
			read++;
		}

		// Pulling items from left to right, caching in a slot before writing
		// it into the new nodes.
		var write = read;
		var slot = new createNode(a.height - 1, 0);
		var from = 0;

		// If the current slot is still containing data, then there will be at
		// least one more write, so we do not break this loop yet.
		while (read - write - (slot.table.length > 0 ? 1 : 0) < toRemove)
		{
			// Find out the max possible items for copying.
			var source = get2(a.table, b.table, read);
			var to = Math.min(M - slot.table.length, source.table.length);

			// Copy and adjust size table.
			slot.table = slot.table.concat(source.table.slice(from, to));
			if (slot.height > 0)
			{
				var len = slot.lengths.length;
				for (var i = len; i < len + to - from; i++)
				{
					slot.lengths[i] = length(slot.table[i]);
					slot.lengths[i] += (i > 0 ? slot.lengths[i - 1] : 0);
				}
			}

			from += to;

			// Only proceed to next slots[i] if the current one was
			// fully copied.
			if (source.table.length <= to)
			{
				read++; from = 0;
			}

			// Only create a new slot if the current one is filled up.
			if (slot.table.length === M)
			{
				saveSlot(newA, newB, write, slot);
				slot = createNode(a.height - 1, 0);
				write++;
			}
		}

		// Cleanup after the loop. Copy the last slot into the new nodes.
		if (slot.table.length > 0)
		{
			saveSlot(newA, newB, write, slot);
			write++;
		}

		// Shift the untouched slots to the left
		while (read < a.table.length + b.table.length )
		{
			saveSlot(newA, newB, write, get2(a.table, b.table, read));
			read++;
			write++;
		}

		return [newA, newB];
	}

	// Navigation functions
	function botRight(a)
	{
		return a.table[a.table.length - 1];
	}
	function botLeft(a)
	{
		return a.table[0];
	}

	// Copies a node for updating. Note that you should not use this if
	// only updating only one of "table" or "lengths" for performance reasons.
	function nodeCopy(a)
	{
		var newA = {
			ctor: '_Array',
			height: a.height,
			table: a.table.slice()
		};
		if (a.height > 0)
		{
			newA.lengths = a.lengths.slice();
		}
		return newA;
	}

	// Returns how many items are in the tree.
	function length(array)
	{
		if (array.height === 0)
		{
			return array.table.length;
		}
		else
		{
			return array.lengths[array.lengths.length - 1];
		}
	}

	// Calculates in which slot of "table" the item probably is, then
	// find the exact slot via forward searching in  "lengths". Returns the index.
	function getSlot(i, a)
	{
		var slot = i >> (5 * a.height);
		while (a.lengths[slot] <= i)
		{
			slot++;
		}
		return slot;
	}

	// Recursively creates a tree with a given height containing
	// only the given item.
	function create(item, h)
	{
		if (h === 0)
		{
			return {
				ctor: '_Array',
				height: 0,
				table: [item]
			};
		}
		return {
			ctor: '_Array',
			height: h,
			table: [create(item, h - 1)],
			lengths: [1]
		};
	}

	// Recursively creates a tree that contains the given tree.
	function parentise(tree, h)
	{
		if (h === tree.height)
		{
			return tree;
		}

		return {
			ctor: '_Array',
			height: h,
			table: [parentise(tree, h - 1)],
			lengths: [length(tree)]
		};
	}

	// Emphasizes blood brotherhood beneath two trees.
	function siblise(a, b)
	{
		return {
			ctor: '_Array',
			height: a.height + 1,
			table: [a, b],
			lengths: [length(a), length(a) + length(b)]
		};
	}

	function toJSArray(a)
	{
		var jsArray = new Array(length(a));
		toJSArray_(jsArray, 0, a);
		return jsArray;
	}

	function toJSArray_(jsArray, i, a)
	{
		for (var t = 0; t < a.table.length; t++)
		{
			if (a.height === 0)
			{
				jsArray[i + t] = a.table[t];
			}
			else
			{
				var inc = t === 0 ? 0 : a.lengths[t - 1];
				toJSArray_(jsArray, i + inc, a.table[t]);
			}
		}
	}

	function fromJSArray(jsArray)
	{
		if (jsArray.length === 0)
		{
			return empty;
		}
		var h = Math.floor(Math.log(jsArray.length) / Math.log(M));
		return fromJSArray_(jsArray, h, 0, jsArray.length);
	}

	function fromJSArray_(jsArray, h, from, to)
	{
		if (h === 0)
		{
			return {
				ctor: '_Array',
				height: 0,
				table: jsArray.slice(from, to)
			};
		}

		var step = Math.pow(M, h);
		var table = new Array(Math.ceil((to - from) / step));
		var lengths = new Array(table.length);
		for (var i = 0; i < table.length; i++)
		{
			table[i] = fromJSArray_(jsArray, h - 1, from + (i * step), Math.min(from + ((i + 1) * step), to));
			lengths[i] = length(table[i]) + (i > 0 ? lengths[i - 1] : 0);
		}
		return {
			ctor: '_Array',
			height: h,
			table: table,
			lengths: lengths
		};
	}

	Elm.Native.Array.values = {
		empty: empty,
		fromList: fromList,
		toList: toList,
		initialize: F2(initialize),
		append: F2(append),
		push: F2(push),
		slice: F3(slice),
		get: F2(get),
		set: F3(set),
		map: F2(map),
		indexedMap: F2(indexedMap),
		foldl: F3(foldl),
		foldr: F3(foldr),
		length: length,

		toJSArray: toJSArray,
		fromJSArray: fromJSArray
	};

	return localRuntime.Native.Array.values = Elm.Native.Array.values;
};

Elm.Array = Elm.Array || {};
Elm.Array.make = function (_elm) {
   "use strict";
   _elm.Array = _elm.Array || {};
   if (_elm.Array.values) return _elm.Array.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Native$Array = Elm.Native.Array.make(_elm);
   var _op = {};
   var append = $Native$Array.append;
   var length = $Native$Array.length;
   var isEmpty = function (array) {
      return _U.eq(length(array),0);
   };
   var slice = $Native$Array.slice;
   var set = $Native$Array.set;
   var get = F2(function (i,array) {
      return _U.cmp(0,i) < 1 && _U.cmp(i,
      $Native$Array.length(array)) < 0 ? $Maybe.Just(A2($Native$Array.get,
      i,
      array)) : $Maybe.Nothing;
   });
   var push = $Native$Array.push;
   var empty = $Native$Array.empty;
   var filter = F2(function (isOkay,arr) {
      var update = F2(function (x,xs) {
         return isOkay(x) ? A2($Native$Array.push,x,xs) : xs;
      });
      return A3($Native$Array.foldl,update,$Native$Array.empty,arr);
   });
   var foldr = $Native$Array.foldr;
   var foldl = $Native$Array.foldl;
   var indexedMap = $Native$Array.indexedMap;
   var map = $Native$Array.map;
   var toIndexedList = function (array) {
      return A3($List.map2,
      F2(function (v0,v1) {
         return {ctor: "_Tuple2",_0: v0,_1: v1};
      }),
      _U.range(0,$Native$Array.length(array) - 1),
      $Native$Array.toList(array));
   };
   var toList = $Native$Array.toList;
   var fromList = $Native$Array.fromList;
   var initialize = $Native$Array.initialize;
   var repeat = F2(function (n,e) {
      return A2(initialize,n,$Basics.always(e));
   });
   var Array = {ctor: "Array"};
   return _elm.Array.values = {_op: _op
                              ,empty: empty
                              ,repeat: repeat
                              ,initialize: initialize
                              ,fromList: fromList
                              ,isEmpty: isEmpty
                              ,length: length
                              ,push: push
                              ,append: append
                              ,get: get
                              ,set: set
                              ,slice: slice
                              ,toList: toList
                              ,toIndexedList: toIndexedList
                              ,map: map
                              ,indexedMap: indexedMap
                              ,filter: filter
                              ,foldl: foldl
                              ,foldr: foldr};
};
Elm.Native.Json = {};

Elm.Native.Json.make = function(localRuntime) {
	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Json = localRuntime.Native.Json || {};
	if (localRuntime.Native.Json.values) {
		return localRuntime.Native.Json.values;
	}

	var ElmArray = Elm.Native.Array.make(localRuntime);
	var List = Elm.Native.List.make(localRuntime);
	var Maybe = Elm.Maybe.make(localRuntime);
	var Result = Elm.Result.make(localRuntime);
	var Utils = Elm.Native.Utils.make(localRuntime);


	function crash(expected, actual) {
		throw new Error(
			'expecting ' + expected + ' but got ' + JSON.stringify(actual)
		);
	}


	// PRIMITIVE VALUES

	function decodeNull(successValue) {
		return function(value) {
			if (value === null) {
				return successValue;
			}
			crash('null', value);
		};
	}


	function decodeString(value) {
		if (typeof value === 'string' || value instanceof String) {
			return value;
		}
		crash('a String', value);
	}


	function decodeFloat(value) {
		if (typeof value === 'number') {
			return value;
		}
		crash('a Float', value);
	}


	function decodeInt(value) {
		if (typeof value !== 'number') {
			crash('an Int', value);
		}

		if (value < 2147483647 && value > -2147483647 && (value | 0) === value) {
			return value;
		}

		if (isFinite(value) && !(value % 1)) {
			return value;
		}

		crash('an Int', value);
	}


	function decodeBool(value) {
		if (typeof value === 'boolean') {
			return value;
		}
		crash('a Bool', value);
	}


	// ARRAY

	function decodeArray(decoder) {
		return function(value) {
			if (value instanceof Array) {
				var len = value.length;
				var array = new Array(len);
				for (var i = len; i--; ) {
					array[i] = decoder(value[i]);
				}
				return ElmArray.fromJSArray(array);
			}
			crash('an Array', value);
		};
	}


	// LIST

	function decodeList(decoder) {
		return function(value) {
			if (value instanceof Array) {
				var len = value.length;
				var list = List.Nil;
				for (var i = len; i--; ) {
					list = List.Cons( decoder(value[i]), list );
				}
				return list;
			}
			crash('a List', value);
		};
	}


	// MAYBE

	function decodeMaybe(decoder) {
		return function(value) {
			try {
				return Maybe.Just(decoder(value));
			} catch(e) {
				return Maybe.Nothing;
			}
		};
	}


	// FIELDS

	function decodeField(field, decoder) {
		return function(value) {
			var subValue = value[field];
			if (subValue !== undefined) {
				return decoder(subValue);
			}
			crash("an object with field '" + field + "'", value);
		};
	}


	// OBJECTS

	function decodeKeyValuePairs(decoder) {
		return function(value) {
			var isObject =
				typeof value === 'object'
					&& value !== null
					&& !(value instanceof Array);

			if (isObject) {
				var keyValuePairs = List.Nil;
				for (var key in value)
				{
					var elmValue = decoder(value[key]);
					var pair = Utils.Tuple2(key, elmValue);
					keyValuePairs = List.Cons(pair, keyValuePairs);
				}
				return keyValuePairs;
			}

			crash('an object', value);
		};
	}

	function decodeObject1(f, d1) {
		return function(value) {
			return f(d1(value));
		};
	}

	function decodeObject2(f, d1, d2) {
		return function(value) {
			return A2( f, d1(value), d2(value) );
		};
	}

	function decodeObject3(f, d1, d2, d3) {
		return function(value) {
			return A3( f, d1(value), d2(value), d3(value) );
		};
	}

	function decodeObject4(f, d1, d2, d3, d4) {
		return function(value) {
			return A4( f, d1(value), d2(value), d3(value), d4(value) );
		};
	}

	function decodeObject5(f, d1, d2, d3, d4, d5) {
		return function(value) {
			return A5( f, d1(value), d2(value), d3(value), d4(value), d5(value) );
		};
	}

	function decodeObject6(f, d1, d2, d3, d4, d5, d6) {
		return function(value) {
			return A6( f,
				d1(value),
				d2(value),
				d3(value),
				d4(value),
				d5(value),
				d6(value)
			);
		};
	}

	function decodeObject7(f, d1, d2, d3, d4, d5, d6, d7) {
		return function(value) {
			return A7( f,
				d1(value),
				d2(value),
				d3(value),
				d4(value),
				d5(value),
				d6(value),
				d7(value)
			);
		};
	}

	function decodeObject8(f, d1, d2, d3, d4, d5, d6, d7, d8) {
		return function(value) {
			return A8( f,
				d1(value),
				d2(value),
				d3(value),
				d4(value),
				d5(value),
				d6(value),
				d7(value),
				d8(value)
			);
		};
	}


	// TUPLES

	function decodeTuple1(f, d1) {
		return function(value) {
			if ( !(value instanceof Array) || value.length !== 1 ) {
				crash('a Tuple of length 1', value);
			}
			return f( d1(value[0]) );
		};
	}

	function decodeTuple2(f, d1, d2) {
		return function(value) {
			if ( !(value instanceof Array) || value.length !== 2 ) {
				crash('a Tuple of length 2', value);
			}
			return A2( f, d1(value[0]), d2(value[1]) );
		};
	}

	function decodeTuple3(f, d1, d2, d3) {
		return function(value) {
			if ( !(value instanceof Array) || value.length !== 3 ) {
				crash('a Tuple of length 3', value);
			}
			return A3( f, d1(value[0]), d2(value[1]), d3(value[2]) );
		};
	}


	function decodeTuple4(f, d1, d2, d3, d4) {
		return function(value) {
			if ( !(value instanceof Array) || value.length !== 4 ) {
				crash('a Tuple of length 4', value);
			}
			return A4( f, d1(value[0]), d2(value[1]), d3(value[2]), d4(value[3]) );
		};
	}


	function decodeTuple5(f, d1, d2, d3, d4, d5) {
		return function(value) {
			if ( !(value instanceof Array) || value.length !== 5 ) {
				crash('a Tuple of length 5', value);
			}
			return A5( f,
				d1(value[0]),
				d2(value[1]),
				d3(value[2]),
				d4(value[3]),
				d5(value[4])
			);
		};
	}


	function decodeTuple6(f, d1, d2, d3, d4, d5, d6) {
		return function(value) {
			if ( !(value instanceof Array) || value.length !== 6 ) {
				crash('a Tuple of length 6', value);
			}
			return A6( f,
				d1(value[0]),
				d2(value[1]),
				d3(value[2]),
				d4(value[3]),
				d5(value[4]),
				d6(value[5])
			);
		};
	}

	function decodeTuple7(f, d1, d2, d3, d4, d5, d6, d7) {
		return function(value) {
			if ( !(value instanceof Array) || value.length !== 7 ) {
				crash('a Tuple of length 7', value);
			}
			return A7( f,
				d1(value[0]),
				d2(value[1]),
				d3(value[2]),
				d4(value[3]),
				d5(value[4]),
				d6(value[5]),
				d7(value[6])
			);
		};
	}


	function decodeTuple8(f, d1, d2, d3, d4, d5, d6, d7, d8) {
		return function(value) {
			if ( !(value instanceof Array) || value.length !== 8 ) {
				crash('a Tuple of length 8', value);
			}
			return A8( f,
				d1(value[0]),
				d2(value[1]),
				d3(value[2]),
				d4(value[3]),
				d5(value[4]),
				d6(value[5]),
				d7(value[6]),
				d8(value[7])
			);
		};
	}


	// CUSTOM DECODERS

	function decodeValue(value) {
		return value;
	}

	function runDecoderValue(decoder, value) {
		try {
			return Result.Ok(decoder(value));
		} catch(e) {
			return Result.Err(e.message);
		}
	}

	function customDecoder(decoder, callback) {
		return function(value) {
			var result = callback(decoder(value));
			if (result.ctor === 'Err') {
				throw new Error('custom decoder failed: ' + result._0);
			}
			return result._0;
		};
	}

	function andThen(decode, callback) {
		return function(value) {
			var result = decode(value);
			return callback(result)(value);
		};
	}

	function fail(msg) {
		return function(value) {
			throw new Error(msg);
		};
	}

	function succeed(successValue) {
		return function(value) {
			return successValue;
		};
	}


	// ONE OF MANY

	function oneOf(decoders) {
		return function(value) {
			var errors = [];
			var temp = decoders;
			while (temp.ctor !== '[]') {
				try {
					return temp._0(value);
				} catch(e) {
					errors.push(e.message);
				}
				temp = temp._1;
			}
			throw new Error('expecting one of the following:\n    ' + errors.join('\n    '));
		};
	}

	function get(decoder, value) {
		try {
			return Result.Ok(decoder(value));
		} catch(e) {
			return Result.Err(e.message);
		}
	}


	// ENCODE / DECODE

	function runDecoderString(decoder, string) {
		try {
			return Result.Ok(decoder(JSON.parse(string)));
		} catch(e) {
			return Result.Err(e.message);
		}
	}

	function encode(indentLevel, value) {
		return JSON.stringify(value, null, indentLevel);
	}

	function identity(value) {
		return value;
	}

	function encodeObject(keyValuePairs) {
		var obj = {};
		while (keyValuePairs.ctor !== '[]') {
			var pair = keyValuePairs._0;
			obj[pair._0] = pair._1;
			keyValuePairs = keyValuePairs._1;
		}
		return obj;
	}

	return localRuntime.Native.Json.values = {
		encode: F2(encode),
		runDecoderString: F2(runDecoderString),
		runDecoderValue: F2(runDecoderValue),

		get: F2(get),
		oneOf: oneOf,

		decodeNull: decodeNull,
		decodeInt: decodeInt,
		decodeFloat: decodeFloat,
		decodeString: decodeString,
		decodeBool: decodeBool,

		decodeMaybe: decodeMaybe,

		decodeList: decodeList,
		decodeArray: decodeArray,

		decodeField: F2(decodeField),

		decodeObject1: F2(decodeObject1),
		decodeObject2: F3(decodeObject2),
		decodeObject3: F4(decodeObject3),
		decodeObject4: F5(decodeObject4),
		decodeObject5: F6(decodeObject5),
		decodeObject6: F7(decodeObject6),
		decodeObject7: F8(decodeObject7),
		decodeObject8: F9(decodeObject8),
		decodeKeyValuePairs: decodeKeyValuePairs,

		decodeTuple1: F2(decodeTuple1),
		decodeTuple2: F3(decodeTuple2),
		decodeTuple3: F4(decodeTuple3),
		decodeTuple4: F5(decodeTuple4),
		decodeTuple5: F6(decodeTuple5),
		decodeTuple6: F7(decodeTuple6),
		decodeTuple7: F8(decodeTuple7),
		decodeTuple8: F9(decodeTuple8),

		andThen: F2(andThen),
		decodeValue: decodeValue,
		customDecoder: F2(customDecoder),
		fail: fail,
		succeed: succeed,

		identity: identity,
		encodeNull: null,
		encodeArray: ElmArray.toJSArray,
		encodeList: List.toArray,
		encodeObject: encodeObject

	};
};

Elm.Json = Elm.Json || {};
Elm.Json.Encode = Elm.Json.Encode || {};
Elm.Json.Encode.make = function (_elm) {
   "use strict";
   _elm.Json = _elm.Json || {};
   _elm.Json.Encode = _elm.Json.Encode || {};
   if (_elm.Json.Encode.values) return _elm.Json.Encode.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Array = Elm.Array.make(_elm),
   $Native$Json = Elm.Native.Json.make(_elm);
   var _op = {};
   var list = $Native$Json.encodeList;
   var array = $Native$Json.encodeArray;
   var object = $Native$Json.encodeObject;
   var $null = $Native$Json.encodeNull;
   var bool = $Native$Json.identity;
   var $float = $Native$Json.identity;
   var $int = $Native$Json.identity;
   var string = $Native$Json.identity;
   var encode = $Native$Json.encode;
   var Value = {ctor: "Value"};
   return _elm.Json.Encode.values = {_op: _op
                                    ,encode: encode
                                    ,string: string
                                    ,$int: $int
                                    ,$float: $float
                                    ,bool: bool
                                    ,$null: $null
                                    ,list: list
                                    ,array: array
                                    ,object: object};
};
Elm.Json = Elm.Json || {};
Elm.Json.Decode = Elm.Json.Decode || {};
Elm.Json.Decode.make = function (_elm) {
   "use strict";
   _elm.Json = _elm.Json || {};
   _elm.Json.Decode = _elm.Json.Decode || {};
   if (_elm.Json.Decode.values) return _elm.Json.Decode.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Array = Elm.Array.make(_elm),
   $Dict = Elm.Dict.make(_elm),
   $Json$Encode = Elm.Json.Encode.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Native$Json = Elm.Native.Json.make(_elm),
   $Result = Elm.Result.make(_elm);
   var _op = {};
   var tuple8 = $Native$Json.decodeTuple8;
   var tuple7 = $Native$Json.decodeTuple7;
   var tuple6 = $Native$Json.decodeTuple6;
   var tuple5 = $Native$Json.decodeTuple5;
   var tuple4 = $Native$Json.decodeTuple4;
   var tuple3 = $Native$Json.decodeTuple3;
   var tuple2 = $Native$Json.decodeTuple2;
   var tuple1 = $Native$Json.decodeTuple1;
   var succeed = $Native$Json.succeed;
   var fail = $Native$Json.fail;
   var andThen = $Native$Json.andThen;
   var customDecoder = $Native$Json.customDecoder;
   var decodeValue = $Native$Json.runDecoderValue;
   var value = $Native$Json.decodeValue;
   var maybe = $Native$Json.decodeMaybe;
   var $null = $Native$Json.decodeNull;
   var array = $Native$Json.decodeArray;
   var list = $Native$Json.decodeList;
   var bool = $Native$Json.decodeBool;
   var $int = $Native$Json.decodeInt;
   var $float = $Native$Json.decodeFloat;
   var string = $Native$Json.decodeString;
   var oneOf = $Native$Json.oneOf;
   var keyValuePairs = $Native$Json.decodeKeyValuePairs;
   var object8 = $Native$Json.decodeObject8;
   var object7 = $Native$Json.decodeObject7;
   var object6 = $Native$Json.decodeObject6;
   var object5 = $Native$Json.decodeObject5;
   var object4 = $Native$Json.decodeObject4;
   var object3 = $Native$Json.decodeObject3;
   var object2 = $Native$Json.decodeObject2;
   var object1 = $Native$Json.decodeObject1;
   _op[":="] = $Native$Json.decodeField;
   var at = F2(function (fields,decoder) {
      return A3($List.foldr,
      F2(function (x,y) {    return A2(_op[":="],x,y);}),
      decoder,
      fields);
   });
   var decodeString = $Native$Json.runDecoderString;
   var map = $Native$Json.decodeObject1;
   var dict = function (decoder) {
      return A2(map,$Dict.fromList,keyValuePairs(decoder));
   };
   var Decoder = {ctor: "Decoder"};
   return _elm.Json.Decode.values = {_op: _op
                                    ,decodeString: decodeString
                                    ,decodeValue: decodeValue
                                    ,string: string
                                    ,$int: $int
                                    ,$float: $float
                                    ,bool: bool
                                    ,$null: $null
                                    ,list: list
                                    ,array: array
                                    ,tuple1: tuple1
                                    ,tuple2: tuple2
                                    ,tuple3: tuple3
                                    ,tuple4: tuple4
                                    ,tuple5: tuple5
                                    ,tuple6: tuple6
                                    ,tuple7: tuple7
                                    ,tuple8: tuple8
                                    ,at: at
                                    ,object1: object1
                                    ,object2: object2
                                    ,object3: object3
                                    ,object4: object4
                                    ,object5: object5
                                    ,object6: object6
                                    ,object7: object7
                                    ,object8: object8
                                    ,keyValuePairs: keyValuePairs
                                    ,dict: dict
                                    ,maybe: maybe
                                    ,oneOf: oneOf
                                    ,map: map
                                    ,fail: fail
                                    ,succeed: succeed
                                    ,andThen: andThen
                                    ,value: value
                                    ,customDecoder: customDecoder};
};
Elm.Random = Elm.Random || {};
Elm.Random.PCG = Elm.Random.PCG || {};
Elm.Random.PCG.make = function (_elm) {
   "use strict";
   _elm.Random = _elm.Random || {};
   _elm.Random.PCG = _elm.Random.PCG || {};
   if (_elm.Random.PCG.values) return _elm.Random.PCG.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Bitwise = Elm.Bitwise.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $Json$Decode = Elm.Json.Decode.make(_elm),
   $Json$Encode = Elm.Json.Encode.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm);
   var _op = {};
   var toJson = function (_p0) {
      var _p1 = _p0;
      return $Json$Encode.list(A2($List.map,
      $Json$Encode.$int,
      _U.list([_p1._0._0,_p1._0._1,_p1._1._0,_p1._1._1])));
   };
   var listHelp = F4(function (list,n,generate,seed) {
      listHelp: while (true) if (_U.cmp(n,1) < 0)
      return {ctor: "_Tuple2",_0: $List.reverse(list),_1: seed};
      else {
            var _p2 = generate(seed);
            var value = _p2._0;
            var newSeed = _p2._1;
            var _v1 = A2($List._op["::"],value,list),
            _v2 = n - 1,
            _v3 = generate,
            _v4 = newSeed;
            list = _v1;
            n = _v2;
            generate = _v3;
            seed = _v4;
            continue listHelp;
         }
   });
   var minInt = 0;
   var maxInt = -1;
   var bit27 = 1.34217728e8;
   var bit53 = 9.007199254740992e15;
   var Seed = F2(function (a,b) {
      return {ctor: "Seed",_0: a,_1: b};
   });
   var generate = F2(function (_p3,seed) {
      var _p4 = _p3;
      return _p4._0(seed);
   });
   var Generator = function (a) {
      return {ctor: "Generator",_0: a};
   };
   var list = F2(function (n,_p5) {
      var _p6 = _p5;
      return Generator(function (seed) {
         return A4(listHelp,_U.list([]),n,_p6._0,seed);
      });
   });
   var constant = function (value) {
      return Generator(function (seed) {
         return {ctor: "_Tuple2",_0: value,_1: seed};
      });
   };
   var map = F2(function (func,_p7) {
      var _p8 = _p7;
      return Generator(function (seed0) {
         var _p9 = _p8._0(seed0);
         var a = _p9._0;
         var seed1 = _p9._1;
         return {ctor: "_Tuple2",_0: func(a),_1: seed1};
      });
   });
   var map2 = F3(function (func,_p11,_p10) {
      var _p12 = _p11;
      var _p13 = _p10;
      return Generator(function (seed0) {
         var _p14 = _p12._0(seed0);
         var a = _p14._0;
         var seed1 = _p14._1;
         var _p15 = _p13._0(seed1);
         var b = _p15._0;
         var seed2 = _p15._1;
         return {ctor: "_Tuple2",_0: A2(func,a,b),_1: seed2};
      });
   });
   var pair = F2(function (genA,genB) {
      return A3(map2,
      F2(function (v0,v1) {
         return {ctor: "_Tuple2",_0: v0,_1: v1};
      }),
      genA,
      genB);
   });
   var andMap = map2(F2(function (x,y) {    return x(y);}));
   var map3 = F4(function (func,_p18,_p17,_p16) {
      var _p19 = _p18;
      var _p20 = _p17;
      var _p21 = _p16;
      return Generator(function (seed0) {
         var _p22 = _p19._0(seed0);
         var a = _p22._0;
         var seed1 = _p22._1;
         var _p23 = _p20._0(seed1);
         var b = _p23._0;
         var seed2 = _p23._1;
         var _p24 = _p21._0(seed2);
         var c = _p24._0;
         var seed3 = _p24._1;
         return {ctor: "_Tuple2",_0: A3(func,a,b,c),_1: seed3};
      });
   });
   var map4 = F5(function (func,_p28,_p27,_p26,_p25) {
      var _p29 = _p28;
      var _p30 = _p27;
      var _p31 = _p26;
      var _p32 = _p25;
      return Generator(function (seed0) {
         var _p33 = _p29._0(seed0);
         var a = _p33._0;
         var seed1 = _p33._1;
         var _p34 = _p30._0(seed1);
         var b = _p34._0;
         var seed2 = _p34._1;
         var _p35 = _p31._0(seed2);
         var c = _p35._0;
         var seed3 = _p35._1;
         var _p36 = _p32._0(seed3);
         var d = _p36._0;
         var seed4 = _p36._1;
         return {ctor: "_Tuple2",_0: A4(func,a,b,c,d),_1: seed4};
      });
   });
   var map5 = F6(function (func,_p41,_p40,_p39,_p38,_p37) {
      var _p42 = _p41;
      var _p43 = _p40;
      var _p44 = _p39;
      var _p45 = _p38;
      var _p46 = _p37;
      return Generator(function (seed0) {
         var _p47 = _p42._0(seed0);
         var a = _p47._0;
         var seed1 = _p47._1;
         var _p48 = _p43._0(seed1);
         var b = _p48._0;
         var seed2 = _p48._1;
         var _p49 = _p44._0(seed2);
         var c = _p49._0;
         var seed3 = _p49._1;
         var _p50 = _p45._0(seed3);
         var d = _p50._0;
         var seed4 = _p50._1;
         var _p51 = _p46._0(seed4);
         var e = _p51._0;
         var seed5 = _p51._1;
         return {ctor: "_Tuple2",_0: A5(func,a,b,c,d,e),_1: seed5};
      });
   });
   var andThen = F2(function (_p52,callback) {
      var _p53 = _p52;
      return Generator(function (seed) {
         var _p54 = _p53._0(seed);
         var result = _p54._0;
         var newSeed = _p54._1;
         var _p55 = callback(result);
         var generateB = _p55._0;
         return generateB(newSeed);
      });
   });
   var filter = F2(function (predicate,generator) {
      return A2(andThen,
      generator,
      function (a) {
         return predicate(a) ? constant(a) : A2(filter,
         predicate,
         generator);
      });
   });
   var maybe = F2(function (genBool,genA) {
      return A2(andThen,
      genBool,
      function (b) {
         return b ? A2(map,
         $Maybe.Just,
         genA) : constant($Maybe.Nothing);
      });
   });
   var Int64 = F2(function (a,b) {
      return {ctor: "Int64",_0: a,_1: b};
   });
   var magicFactor = A2(Int64,1481765933,1284865837);
   _op[">>>"] = $Bitwise.shiftRightLogical;
   var add64 = F2(function (_p57,_p56) {
      var _p58 = _p57;
      var _p60 = _p58._1;
      var _p59 = _p56;
      var lo = A2(_op[">>>"],_p60 + _p59._1,0);
      var hi = A2(_op[">>>"],_p58._0 + _p59._0,0);
      var hi$ = _U.cmp(A2(_op[">>>"],lo,0),
      A2(_op[">>>"],_p60,0)) < 0 ? A2($Bitwise.or,hi + 1,0) : hi;
      return A2(Int64,hi$,lo);
   });
   _op["<<"] = $Bitwise.shiftLeft;
   _op["&"] = $Bitwise.and;
   var peel = function (_p61) {
      var _p62 = _p61;
      var _p64 = _p62._0._1;
      var _p63 = _p62._0._0;
      var rot = A2(_op[">>>"],_p63,27);
      var rot2 = A2(_op[">>>"],
      A2(_op["&"],A2(_op[">>>"],0 - rot,0),31),
      0);
      var xsLo = A2(_op[">>>"],
      A2($Bitwise.or,A2(_op[">>>"],_p64,18),A2(_op["<<"],_p63,14)),
      0);
      var xsLo$ = A2(_op[">>>"],A2($Bitwise.xor,xsLo,_p64),0);
      var xsHi = A2(_op[">>>"],_p63,18);
      var xsHi$ = A2(_op[">>>"],A2($Bitwise.xor,xsHi,_p63),0);
      var xorshifted = A2(_op[">>>"],
      A2($Bitwise.or,A2(_op[">>>"],xsLo$,27),A2(_op["<<"],xsHi$,5)),
      0);
      return A2(_op[">>>"],
      A2($Bitwise.or,
      A2(_op[">>>"],xorshifted,rot),
      A2(_op["<<"],xorshifted,rot2)),
      0);
   };
   var mul32 = F2(function (a,b) {
      var bl = A2(_op["&"],b,65535);
      var bh = A2(_op["&"],A2(_op[">>>"],b,16),65535);
      var al = A2(_op["&"],a,65535);
      var ah = A2(_op["&"],A2(_op[">>>"],a,16),65535);
      return A2($Bitwise.or,
      0,
      al * bl + A2(_op[">>>"],A2(_op["<<"],ah * bl + al * bh,16),0));
   });
   var mul64 = F2(function (_p66,_p65) {
      var _p67 = _p66;
      var _p70 = _p67._1;
      var _p68 = _p65;
      var _p69 = _p68._1;
      var lo = A2(_op[">>>"],
      A2(_op["&"],_p70,65535) * A2(_op["&"],_p69,65535),
      0);
      var c0 = A2(_op["&"],_p70,65535) * A2(_op[">>>"],
      A2(_op[">>>"],_p69,16),
      0);
      var c0$ = A2(_op[">>>"],A2(_op["<<"],c0,16),0);
      var lo$ = A2(_op[">>>"],lo + c0$,0);
      var c1 = A2(_op[">>>"],_p70,16) * A2(_op[">>>"],
      A2(_op["&"],_p69,65535),
      0);
      var hi = A2(_op[">>>"],_p70,16) * A2(_op[">>>"],
      _p69,
      16) + A2(_op[">>>"],
      A2(_op[">>>"],c0,16) + A2(_op[">>>"],c1,16),
      0);
      var hi$ = _U.cmp(A2(_op[">>>"],lo$,0),
      A2(_op[">>>"],c0$,0)) < 0 ? A2(_op[">>>"],hi + 1,0) : hi;
      var c1$ = A2(_op[">>>"],A2(_op["<<"],c1,16),0);
      var lo$$ = A2(_op[">>>"],lo$ + c1$,0);
      var hi$$ = _U.cmp(A2(_op[">>>"],lo$$,0),
      A2(_op[">>>"],c1$,0)) < 0 ? A2(_op[">>>"],hi$ + 1,0) : hi$;
      var hi$$$ = A2(_op[">>>"],hi$$ + A2(mul32,_p70,_p68._0),0);
      var hi$$$$ = A2(_op[">>>"],hi$$$ + A2(mul32,_p67._0,_p69),0);
      return A2(Int64,hi$$$$,lo$$);
   });
   var next = function (_p71) {
      var _p72 = _p71;
      var _p73 = _p72._1;
      var state1 = A2(mul64,_p72._0,magicFactor);
      var state2 = A2(add64,state1,_p73);
      return A2(Seed,state2,_p73);
   };
   var initialSeed2 = F2(function (stateHi,stateLo) {
      var incr = A2(Int64,335903614,-144211633);
      var zero = A2(Int64,0,0);
      var seed0 = A2(Seed,zero,incr);
      var _p74 = next(seed0);
      var state1 = _p74._0;
      var state2 = A2(add64,
      state1,
      A2(Int64,A2(_op[">>>"],stateHi,0),A2(_op[">>>"],stateLo,0)));
      return next(A2(Seed,state2,incr));
   });
   var initialSeed = initialSeed2(0);
   var fromJson = $Json$Decode.oneOf(_U.list([A5($Json$Decode.tuple4,
                                             F4(function (a,b,c,d) {
                                                return A2(Seed,A2(Int64,a,b),A2(Int64,c,d));
                                             }),
                                             $Json$Decode.$int,
                                             $Json$Decode.$int,
                                             $Json$Decode.$int,
                                             $Json$Decode.$int)
                                             ,A3($Json$Decode.tuple2,
                                             initialSeed2,
                                             $Json$Decode.$int,
                                             $Json$Decode.$int)
                                             ,A2($Json$Decode.tuple1,initialSeed,$Json$Decode.$int)
                                             ,A2($Json$Decode.map,initialSeed,$Json$Decode.$int)]));
   var integer = F2(function (max,seed0) {
      if (_U.eq(A2(_op["&"],max,max - 1),0))
      return {ctor: "_Tuple2"
             ,_0: A2(_op[">>>"],A2(_op["&"],peel(seed0),max - 1),0)
             ,_1: next(seed0)}; else {
            var threshhold = A2(_op[">>>"],
            A2($Basics._op["%"],A2(_op[">>>"],0 - max,0),max),
            0);
            var accountForBias = function (seed) {
               accountForBias: while (true) {
                  var seedN = next(seed);
                  var x = peel(seed);
                  if (_U.cmp(x,threshhold) < 0) {
                        var _v29 = seedN;
                        seed = _v29;
                        continue accountForBias;
                     } else return {ctor: "_Tuple2"
                                   ,_0: A2($Basics._op["%"],x,max)
                                   ,_1: seedN};
               }
            };
            return accountForBias(seed0);
         }
   });
   var $int = F2(function (min,max) {
      return Generator(function (seed0) {
         if (_U.eq(min,max)) return {ctor: "_Tuple2"
                                    ,_0: min
                                    ,_1: seed0}; else {
               var range = $Basics.abs(max - min) + 1;
               var _p75 = A2(integer,range,seed0);
               var i = _p75._0;
               var seed1 = _p75._1;
               return {ctor: "_Tuple2",_0: i + min,_1: seed1};
            }
      });
   });
   var bool = A2(map,
   F2(function (x,y) {    return _U.eq(x,y);})(1),
   A2($int,0,1));
   var choice = F2(function (x,y) {
      return A2(map,function (b) {    return b ? x : y;},bool);
   });
   var oneIn = function (n) {
      return A2(map,
      F2(function (x,y) {    return _U.eq(x,y);})(1),
      A2($int,1,n));
   };
   var $float = F2(function (min,max) {
      return Generator(function (seed0) {
         var range = $Basics.abs(max - min);
         var n0 = peel(seed0);
         var hi = $Basics.toFloat(A2(_op["&"],n0,67108863)) * 1.0;
         var seed1 = next(seed0);
         var n1 = peel(seed1);
         var lo = $Basics.toFloat(A2(_op["&"],n1,134217727)) * 1.0;
         var val = (hi * bit27 + lo) / bit53;
         var scaled = val * range + min;
         return {ctor: "_Tuple2",_0: scaled,_1: next(seed1)};
      });
   });
   var independentSeed = Generator(function (seed0) {
      var gen1 = A2($int,minInt,maxInt);
      var gen4 = A5(map4,
      F4(function (v0,v1,v2,v3) {
         return {ctor: "_Tuple4",_0: v0,_1: v1,_2: v2,_3: v3};
      }),
      gen1,
      gen1,
      gen1,
      gen1);
      var _p76 = A2(generate,gen4,seed0);
      var a = _p76._0._0;
      var b = _p76._0._1;
      var c = _p76._0._2;
      var d = _p76._0._3;
      var seed1 = _p76._1;
      var dOdd = A2(_op[">>>"],A2($Bitwise.or,d,1),0);
      var seed2 = A2(Seed,A2(Int64,a,b),A2(Int64,c,dOdd));
      return {ctor: "_Tuple2",_0: next(seed2),_1: next(seed1)};
   });
   var split = generate(independentSeed);
   var fastForward = F2(function (delta0,_p77) {
      var _p78 = _p77;
      var _p80 = _p78._1;
      var zero = A2(Int64,0,0);
      var one = A2(Int64,0,1);
      var helper = F6(function (accMult,
      accPlus,
      curMult,
      curPlus,
      delta,
      repeat) {
         helper: while (true) {
            var newDelta = A2(_op[">>>"],delta,1);
            var curMult$ = A2(mul64,curMult,curMult);
            var curPlus$ = A2(mul64,A2(add64,curMult,one),curPlus);
            var deltaOdd = _U.eq(A2(_op["&"],delta,1),1);
            var accMult$ = deltaOdd ? A2(mul64,accMult,curMult) : accMult;
            var accPlus$ = deltaOdd ? A2(add64,
            A2(mul64,accPlus,curMult),
            curPlus) : accPlus;
            if (_U.eq(newDelta,0)) if (_U.cmp(delta0,0) < 0 && repeat) {
                     var _v31 = accMult$,
                     _v32 = accPlus$,
                     _v33 = curMult$,
                     _v34 = curPlus$,
                     _v35 = -1,
                     _v36 = false;
                     accMult = _v31;
                     accPlus = _v32;
                     curMult = _v33;
                     curPlus = _v34;
                     delta = _v35;
                     repeat = _v36;
                     continue helper;
                  } else return {ctor: "_Tuple2",_0: accMult$,_1: accPlus$};
            else {
                  var _v37 = accMult$,
                  _v38 = accPlus$,
                  _v39 = curMult$,
                  _v40 = curPlus$,
                  _v41 = newDelta,
                  _v42 = repeat;
                  accMult = _v37;
                  accPlus = _v38;
                  curMult = _v39;
                  curPlus = _v40;
                  delta = _v41;
                  repeat = _v42;
                  continue helper;
               }
         }
      });
      var _p79 = A6(helper,one,zero,magicFactor,_p80,delta0,true);
      var accMultFinal = _p79._0;
      var accPlusFinal = _p79._1;
      var state1 = A2(add64,
      accPlusFinal,
      A2(mul64,accMultFinal,_p78._0));
      return A2(Seed,state1,_p80);
   });
   return _elm.Random.PCG.values = {_op: _op
                                   ,bool: bool
                                   ,$int: $int
                                   ,$float: $float
                                   ,oneIn: oneIn
                                   ,pair: pair
                                   ,list: list
                                   ,maybe: maybe
                                   ,choice: choice
                                   ,map: map
                                   ,map2: map2
                                   ,map3: map3
                                   ,map4: map4
                                   ,map5: map5
                                   ,andMap: andMap
                                   ,filter: filter
                                   ,constant: constant
                                   ,andThen: andThen
                                   ,minInt: minInt
                                   ,maxInt: maxInt
                                   ,generate: generate
                                   ,initialSeed2: initialSeed2
                                   ,initialSeed: initialSeed
                                   ,split: split
                                   ,independentSeed: independentSeed
                                   ,fastForward: fastForward
                                   ,toJson: toJson
                                   ,fromJson: fromJson};
};
Elm.Native.Regex = {};
Elm.Native.Regex.make = function(localRuntime) {
	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Regex = localRuntime.Native.Regex || {};
	if (localRuntime.Native.Regex.values)
	{
		return localRuntime.Native.Regex.values;
	}
	if ('values' in Elm.Native.Regex)
	{
		return localRuntime.Native.Regex.values = Elm.Native.Regex.values;
	}

	var List = Elm.Native.List.make(localRuntime);
	var Maybe = Elm.Maybe.make(localRuntime);

	function escape(str)
	{
		return str.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
	}
	function caseInsensitive(re)
	{
		return new RegExp(re.source, 'gi');
	}
	function regex(raw)
	{
		return new RegExp(raw, 'g');
	}

	function contains(re, string)
	{
		return string.match(re) !== null;
	}

	function find(n, re, str)
	{
		n = n.ctor === 'All' ? Infinity : n._0;
		var out = [];
		var number = 0;
		var string = str;
		var lastIndex = re.lastIndex;
		var prevLastIndex = -1;
		var result;
		while (number++ < n && (result = re.exec(string)))
		{
			if (prevLastIndex === re.lastIndex) break;
			var i = result.length - 1;
			var subs = new Array(i);
			while (i > 0)
			{
				var submatch = result[i];
				subs[--i] = submatch === undefined
					? Maybe.Nothing
					: Maybe.Just(submatch);
			}
			out.push({
				match: result[0],
				submatches: List.fromArray(subs),
				index: result.index,
				number: number
			});
			prevLastIndex = re.lastIndex;
		}
		re.lastIndex = lastIndex;
		return List.fromArray(out);
	}

	function replace(n, re, replacer, string)
	{
		n = n.ctor === 'All' ? Infinity : n._0;
		var count = 0;
		function jsReplacer(match)
		{
			if (count++ >= n)
			{
				return match;
			}
			var i = arguments.length - 3;
			var submatches = new Array(i);
			while (i > 0)
			{
				var submatch = arguments[i];
				submatches[--i] = submatch === undefined
					? Maybe.Nothing
					: Maybe.Just(submatch);
			}
			return replacer({
				match: match,
				submatches: List.fromArray(submatches),
				index: arguments[i - 1],
				number: count
			});
		}
		return string.replace(re, jsReplacer);
	}

	function split(n, re, str)
	{
		n = n.ctor === 'All' ? Infinity : n._0;
		if (n === Infinity)
		{
			return List.fromArray(str.split(re));
		}
		var string = str;
		var result;
		var out = [];
		var start = re.lastIndex;
		while (n--)
		{
			if (!(result = re.exec(string))) break;
			out.push(string.slice(start, result.index));
			start = re.lastIndex;
		}
		out.push(string.slice(start));
		return List.fromArray(out);
	}

	return Elm.Native.Regex.values = {
		regex: regex,
		caseInsensitive: caseInsensitive,
		escape: escape,

		contains: F2(contains),
		find: F3(find),
		replace: F4(replace),
		split: F3(split)
	};
};

Elm.Regex = Elm.Regex || {};
Elm.Regex.make = function (_elm) {
   "use strict";
   _elm.Regex = _elm.Regex || {};
   if (_elm.Regex.values) return _elm.Regex.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Native$Regex = Elm.Native.Regex.make(_elm);
   var _op = {};
   var split = $Native$Regex.split;
   var replace = $Native$Regex.replace;
   var find = $Native$Regex.find;
   var AtMost = function (a) {    return {ctor: "AtMost",_0: a};};
   var All = {ctor: "All"};
   var Match = F4(function (a,b,c,d) {
      return {match: a,submatches: b,index: c,number: d};
   });
   var contains = $Native$Regex.contains;
   var caseInsensitive = $Native$Regex.caseInsensitive;
   var regex = $Native$Regex.regex;
   var escape = $Native$Regex.escape;
   var Regex = {ctor: "Regex"};
   return _elm.Regex.values = {_op: _op
                              ,regex: regex
                              ,escape: escape
                              ,caseInsensitive: caseInsensitive
                              ,contains: contains
                              ,find: find
                              ,replace: replace
                              ,split: split
                              ,Match: Match
                              ,All: All
                              ,AtMost: AtMost};
};
Elm.Uuid = Elm.Uuid || {};
Elm.Uuid.Barebones = Elm.Uuid.Barebones || {};
Elm.Uuid.Barebones.make = function (_elm) {
   "use strict";
   _elm.Uuid = _elm.Uuid || {};
   _elm.Uuid.Barebones = _elm.Uuid.Barebones || {};
   if (_elm.Uuid.Barebones.values)
   return _elm.Uuid.Barebones.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Array = Elm.Array.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Bitwise = Elm.Bitwise.make(_elm),
   $Char = Elm.Char.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Random$PCG = Elm.Random.PCG.make(_elm),
   $Regex = Elm.Regex.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $String = Elm.String.make(_elm);
   var _op = {};
   var hexGenerator = A2($Random$PCG.$int,0,15);
   var hexDigits = function () {
      var mapChars = F2(function (offset,digit) {
         return $Char.fromCode(digit + offset);
      });
      return $Array.fromList(A2($Basics._op["++"],
      A2($List.map,mapChars(48),_U.range(0,9)),
      A2($List.map,mapChars(97),_U.range(0,5))));
   }();
   var mapToHex = function (index) {
      var maybeResult = A2($Basics.flip,
      $Array.get,
      hexDigits)(index);
      var _p0 = maybeResult;
      if (_p0.ctor === "Nothing") {
            return _U.chr("x");
         } else {
            return _p0._0;
         }
   };
   var uuidRegex = $Regex.regex("^[0-9A-Fa-f]{8,8}-[0-9A-Fa-f]{4,4}-[1-5][0-9A-Fa-f]{3,3}-[8-9A-Ba-b][0-9A-Fa-f]{3,3}-[0-9A-Fa-f]{12,12}$");
   var limitDigitRange8ToB = function (digit) {
      return A2($Bitwise.or,A2($Bitwise.and,digit,3),8);
   };
   var toUuidString = function (thirtyOneHexDigits) {
      return $String.concat(_U.list([$String.fromList(A2($List.map,
                                    mapToHex,
                                    A2($List.take,8,thirtyOneHexDigits)))
                                    ,"-"
                                    ,$String.fromList(A2($List.map,
                                    mapToHex,
                                    A2($List.take,4,A2($List.drop,8,thirtyOneHexDigits))))
                                    ,"-"
                                    ,"4"
                                    ,$String.fromList(A2($List.map,
                                    mapToHex,
                                    A2($List.take,3,A2($List.drop,12,thirtyOneHexDigits))))
                                    ,"-"
                                    ,$String.fromList(A2($List.map,
                                    mapToHex,
                                    A2($List.map,
                                    limitDigitRange8ToB,
                                    A2($List.take,1,A2($List.drop,15,thirtyOneHexDigits)))))
                                    ,$String.fromList(A2($List.map,
                                    mapToHex,
                                    A2($List.take,3,A2($List.drop,16,thirtyOneHexDigits))))
                                    ,"-"
                                    ,$String.fromList(A2($List.map,
                                    mapToHex,
                                    A2($List.take,12,A2($List.drop,19,thirtyOneHexDigits))))]));
   };
   var isValidUuid = function (uuidAsString) {
      return A2($Regex.contains,uuidRegex,uuidAsString);
   };
   var uuidStringGenerator = A2($Random$PCG.map,
   toUuidString,
   A2($Random$PCG.list,31,hexGenerator));
   return _elm.Uuid.Barebones.values = {_op: _op
                                       ,uuidStringGenerator: uuidStringGenerator
                                       ,isValidUuid: isValidUuid};
};
Elm.Uuid = Elm.Uuid || {};
Elm.Uuid.make = function (_elm) {
   "use strict";
   _elm.Uuid = _elm.Uuid || {};
   if (_elm.Uuid.values) return _elm.Uuid.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Random$PCG = Elm.Random.PCG.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $String = Elm.String.make(_elm),
   $Uuid$Barebones = Elm.Uuid.Barebones.make(_elm);
   var _op = {};
   var toString = function (_p0) {
      var _p1 = _p0;
      return _p1._0;
   };
   var Uuid = function (a) {    return {ctor: "Uuid",_0: a};};
   var fromString = function (text) {
      return $Uuid$Barebones.isValidUuid(text) ? $Maybe.Just(Uuid($String.toLower(text))) : $Maybe.Nothing;
   };
   var uuidGenerator = A2($Random$PCG.map,
   Uuid,
   $Uuid$Barebones.uuidStringGenerator);
   return _elm.Uuid.values = {_op: _op
                             ,toString: toString
                             ,fromString: fromString
                             ,uuidGenerator: uuidGenerator};
};
(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){

},{}],2:[function(require,module,exports){
(function (global){
var topLevel = typeof global !== 'undefined' ? global :
    typeof window !== 'undefined' ? window : {}
var minDoc = require('min-document');

if (typeof document !== 'undefined') {
    module.exports = document;
} else {
    var doccy = topLevel['__GLOBAL_DOCUMENT_CACHE@4'];

    if (!doccy) {
        doccy = topLevel['__GLOBAL_DOCUMENT_CACHE@4'] = minDoc;
    }

    module.exports = doccy;
}

}).call(this,typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
},{"min-document":1}],3:[function(require,module,exports){
"use strict";

module.exports = function isObject(x) {
	return typeof x === "object" && x !== null;
};

},{}],4:[function(require,module,exports){
var nativeIsArray = Array.isArray
var toString = Object.prototype.toString

module.exports = nativeIsArray || isArray

function isArray(obj) {
    return toString.call(obj) === "[object Array]"
}

},{}],5:[function(require,module,exports){
var isObject = require("is-object")
var isHook = require("../vnode/is-vhook.js")

module.exports = applyProperties

function applyProperties(node, props, previous) {
    for (var propName in props) {
        var propValue = props[propName]

        if (propValue === undefined) {
            removeProperty(node, propName, propValue, previous);
        } else if (isHook(propValue)) {
            removeProperty(node, propName, propValue, previous)
            if (propValue.hook) {
                propValue.hook(node,
                    propName,
                    previous ? previous[propName] : undefined)
            }
        } else {
            if (isObject(propValue)) {
                patchObject(node, props, previous, propName, propValue);
            } else {
                node[propName] = propValue
            }
        }
    }
}

function removeProperty(node, propName, propValue, previous) {
    if (previous) {
        var previousValue = previous[propName]

        if (!isHook(previousValue)) {
            if (propName === "attributes") {
                for (var attrName in previousValue) {
                    node.removeAttribute(attrName)
                }
            } else if (propName === "style") {
                for (var i in previousValue) {
                    node.style[i] = ""
                }
            } else if (typeof previousValue === "string") {
                node[propName] = ""
            } else {
                node[propName] = null
            }
        } else if (previousValue.unhook) {
            previousValue.unhook(node, propName, propValue)
        }
    }
}

function patchObject(node, props, previous, propName, propValue) {
    var previousValue = previous ? previous[propName] : undefined

    // Set attributes
    if (propName === "attributes") {
        for (var attrName in propValue) {
            var attrValue = propValue[attrName]

            if (attrValue === undefined) {
                node.removeAttribute(attrName)
            } else {
                node.setAttribute(attrName, attrValue)
            }
        }

        return
    }

    if(previousValue && isObject(previousValue) &&
        getPrototype(previousValue) !== getPrototype(propValue)) {
        node[propName] = propValue
        return
    }

    if (!isObject(node[propName])) {
        node[propName] = {}
    }

    var replacer = propName === "style" ? "" : undefined

    for (var k in propValue) {
        var value = propValue[k]
        node[propName][k] = (value === undefined) ? replacer : value
    }
}

function getPrototype(value) {
    if (Object.getPrototypeOf) {
        return Object.getPrototypeOf(value)
    } else if (value.__proto__) {
        return value.__proto__
    } else if (value.constructor) {
        return value.constructor.prototype
    }
}

},{"../vnode/is-vhook.js":13,"is-object":3}],6:[function(require,module,exports){
var document = require("global/document")

var applyProperties = require("./apply-properties")

var isVNode = require("../vnode/is-vnode.js")
var isVText = require("../vnode/is-vtext.js")
var isWidget = require("../vnode/is-widget.js")
var handleThunk = require("../vnode/handle-thunk.js")

module.exports = createElement

function createElement(vnode, opts) {
    var doc = opts ? opts.document || document : document
    var warn = opts ? opts.warn : null

    vnode = handleThunk(vnode).a

    if (isWidget(vnode)) {
        return vnode.init()
    } else if (isVText(vnode)) {
        return doc.createTextNode(vnode.text)
    } else if (!isVNode(vnode)) {
        if (warn) {
            warn("Item is not a valid virtual dom node", vnode)
        }
        return null
    }

    var node = (vnode.namespace === null) ?
        doc.createElement(vnode.tagName) :
        doc.createElementNS(vnode.namespace, vnode.tagName)

    var props = vnode.properties
    applyProperties(node, props)

    var children = vnode.children

    for (var i = 0; i < children.length; i++) {
        var childNode = createElement(children[i], opts)
        if (childNode) {
            node.appendChild(childNode)
        }
    }

    return node
}

},{"../vnode/handle-thunk.js":11,"../vnode/is-vnode.js":14,"../vnode/is-vtext.js":15,"../vnode/is-widget.js":16,"./apply-properties":5,"global/document":2}],7:[function(require,module,exports){
// Maps a virtual DOM tree onto a real DOM tree in an efficient manner.
// We don't want to read all of the DOM nodes in the tree so we use
// the in-order tree indexing to eliminate recursion down certain branches.
// We only recurse into a DOM node if we know that it contains a child of
// interest.

var noChild = {}

module.exports = domIndex

function domIndex(rootNode, tree, indices, nodes) {
    if (!indices || indices.length === 0) {
        return {}
    } else {
        indices.sort(ascending)
        return recurse(rootNode, tree, indices, nodes, 0)
    }
}

function recurse(rootNode, tree, indices, nodes, rootIndex) {
    nodes = nodes || {}


    if (rootNode) {
        if (indexInRange(indices, rootIndex, rootIndex)) {
            nodes[rootIndex] = rootNode
        }

        var vChildren = tree.children

        if (vChildren) {

            var childNodes = rootNode.childNodes

            for (var i = 0; i < tree.children.length; i++) {
                rootIndex += 1

                var vChild = vChildren[i] || noChild
                var nextIndex = rootIndex + (vChild.count || 0)

                // skip recursion down the tree if there are no nodes down here
                if (indexInRange(indices, rootIndex, nextIndex)) {
                    recurse(childNodes[i], vChild, indices, nodes, rootIndex)
                }

                rootIndex = nextIndex
            }
        }
    }

    return nodes
}

// Binary search for an index in the interval [left, right]
function indexInRange(indices, left, right) {
    if (indices.length === 0) {
        return false
    }

    var minIndex = 0
    var maxIndex = indices.length - 1
    var currentIndex
    var currentItem

    while (minIndex <= maxIndex) {
        currentIndex = ((maxIndex + minIndex) / 2) >> 0
        currentItem = indices[currentIndex]

        if (minIndex === maxIndex) {
            return currentItem >= left && currentItem <= right
        } else if (currentItem < left) {
            minIndex = currentIndex + 1
        } else  if (currentItem > right) {
            maxIndex = currentIndex - 1
        } else {
            return true
        }
    }

    return false;
}

function ascending(a, b) {
    return a > b ? 1 : -1
}

},{}],8:[function(require,module,exports){
var applyProperties = require("./apply-properties")

var isWidget = require("../vnode/is-widget.js")
var VPatch = require("../vnode/vpatch.js")

var render = require("./create-element")
var updateWidget = require("./update-widget")

module.exports = applyPatch

function applyPatch(vpatch, domNode, renderOptions) {
    var type = vpatch.type
    var vNode = vpatch.vNode
    var patch = vpatch.patch

    switch (type) {
        case VPatch.REMOVE:
            return removeNode(domNode, vNode)
        case VPatch.INSERT:
            return insertNode(domNode, patch, renderOptions)
        case VPatch.VTEXT:
            return stringPatch(domNode, vNode, patch, renderOptions)
        case VPatch.WIDGET:
            return widgetPatch(domNode, vNode, patch, renderOptions)
        case VPatch.VNODE:
            return vNodePatch(domNode, vNode, patch, renderOptions)
        case VPatch.ORDER:
            reorderChildren(domNode, patch)
            return domNode
        case VPatch.PROPS:
            applyProperties(domNode, patch, vNode.properties)
            return domNode
        case VPatch.THUNK:
            return replaceRoot(domNode,
                renderOptions.patch(domNode, patch, renderOptions))
        default:
            return domNode
    }
}

function removeNode(domNode, vNode) {
    var parentNode = domNode.parentNode

    if (parentNode) {
        parentNode.removeChild(domNode)
    }

    destroyWidget(domNode, vNode);

    return null
}

function insertNode(parentNode, vNode, renderOptions) {
    var newNode = render(vNode, renderOptions)

    if (parentNode) {
        parentNode.appendChild(newNode)
    }

    return parentNode
}

function stringPatch(domNode, leftVNode, vText, renderOptions) {
    var newNode

    if (domNode.nodeType === 3) {
        domNode.replaceData(0, domNode.length, vText.text)
        newNode = domNode
    } else {
        var parentNode = domNode.parentNode
        newNode = render(vText, renderOptions)

        if (parentNode && newNode !== domNode) {
            parentNode.replaceChild(newNode, domNode)
        }
    }

    return newNode
}

function widgetPatch(domNode, leftVNode, widget, renderOptions) {
    var updating = updateWidget(leftVNode, widget)
    var newNode

    if (updating) {
        newNode = widget.update(leftVNode, domNode) || domNode
    } else {
        newNode = render(widget, renderOptions)
    }

    var parentNode = domNode.parentNode

    if (parentNode && newNode !== domNode) {
        parentNode.replaceChild(newNode, domNode)
    }

    if (!updating) {
        destroyWidget(domNode, leftVNode)
    }

    return newNode
}

function vNodePatch(domNode, leftVNode, vNode, renderOptions) {
    var parentNode = domNode.parentNode
    var newNode = render(vNode, renderOptions)

    if (parentNode && newNode !== domNode) {
        parentNode.replaceChild(newNode, domNode)
    }

    return newNode
}

function destroyWidget(domNode, w) {
    if (typeof w.destroy === "function" && isWidget(w)) {
        w.destroy(domNode)
    }
}

function reorderChildren(domNode, moves) {
    var childNodes = domNode.childNodes
    var keyMap = {}
    var node
    var remove
    var insert

    for (var i = 0; i < moves.removes.length; i++) {
        remove = moves.removes[i]
        node = childNodes[remove.from]
        if (remove.key) {
            keyMap[remove.key] = node
        }
        domNode.removeChild(node)
    }

    var length = childNodes.length
    for (var j = 0; j < moves.inserts.length; j++) {
        insert = moves.inserts[j]
        node = keyMap[insert.key]
        // this is the weirdest bug i've ever seen in webkit
        domNode.insertBefore(node, insert.to >= length++ ? null : childNodes[insert.to])
    }
}

function replaceRoot(oldRoot, newRoot) {
    if (oldRoot && newRoot && oldRoot !== newRoot && oldRoot.parentNode) {
        oldRoot.parentNode.replaceChild(newRoot, oldRoot)
    }

    return newRoot;
}

},{"../vnode/is-widget.js":16,"../vnode/vpatch.js":19,"./apply-properties":5,"./create-element":6,"./update-widget":10}],9:[function(require,module,exports){
var document = require("global/document")
var isArray = require("x-is-array")

var domIndex = require("./dom-index")
var patchOp = require("./patch-op")
module.exports = patch

function patch(rootNode, patches) {
    return patchRecursive(rootNode, patches)
}

function patchRecursive(rootNode, patches, renderOptions) {
    var indices = patchIndices(patches)

    if (indices.length === 0) {
        return rootNode
    }

    var index = domIndex(rootNode, patches.a, indices)
    var ownerDocument = rootNode.ownerDocument

    if (!renderOptions) {
        renderOptions = { patch: patchRecursive }
        if (ownerDocument !== document) {
            renderOptions.document = ownerDocument
        }
    }

    for (var i = 0; i < indices.length; i++) {
        var nodeIndex = indices[i]
        rootNode = applyPatch(rootNode,
            index[nodeIndex],
            patches[nodeIndex],
            renderOptions)
    }

    return rootNode
}

function applyPatch(rootNode, domNode, patchList, renderOptions) {
    if (!domNode) {
        return rootNode
    }

    var newNode

    if (isArray(patchList)) {
        for (var i = 0; i < patchList.length; i++) {
            newNode = patchOp(patchList[i], domNode, renderOptions)

            if (domNode === rootNode) {
                rootNode = newNode
            }
        }
    } else {
        newNode = patchOp(patchList, domNode, renderOptions)

        if (domNode === rootNode) {
            rootNode = newNode
        }
    }

    return rootNode
}

function patchIndices(patches) {
    var indices = []

    for (var key in patches) {
        if (key !== "a") {
            indices.push(Number(key))
        }
    }

    return indices
}

},{"./dom-index":7,"./patch-op":8,"global/document":2,"x-is-array":4}],10:[function(require,module,exports){
var isWidget = require("../vnode/is-widget.js")

module.exports = updateWidget

function updateWidget(a, b) {
    if (isWidget(a) && isWidget(b)) {
        if ("name" in a && "name" in b) {
            return a.id === b.id
        } else {
            return a.init === b.init
        }
    }

    return false
}

},{"../vnode/is-widget.js":16}],11:[function(require,module,exports){
var isVNode = require("./is-vnode")
var isVText = require("./is-vtext")
var isWidget = require("./is-widget")
var isThunk = require("./is-thunk")

module.exports = handleThunk

function handleThunk(a, b) {
    var renderedA = a
    var renderedB = b

    if (isThunk(b)) {
        renderedB = renderThunk(b, a)
    }

    if (isThunk(a)) {
        renderedA = renderThunk(a, null)
    }

    return {
        a: renderedA,
        b: renderedB
    }
}

function renderThunk(thunk, previous) {
    var renderedThunk = thunk.vnode

    if (!renderedThunk) {
        renderedThunk = thunk.vnode = thunk.render(previous)
    }

    if (!(isVNode(renderedThunk) ||
            isVText(renderedThunk) ||
            isWidget(renderedThunk))) {
        throw new Error("thunk did not return a valid node");
    }

    return renderedThunk
}

},{"./is-thunk":12,"./is-vnode":14,"./is-vtext":15,"./is-widget":16}],12:[function(require,module,exports){
module.exports = isThunk

function isThunk(t) {
    return t && t.type === "Thunk"
}

},{}],13:[function(require,module,exports){
module.exports = isHook

function isHook(hook) {
    return hook &&
      (typeof hook.hook === "function" && !hook.hasOwnProperty("hook") ||
       typeof hook.unhook === "function" && !hook.hasOwnProperty("unhook"))
}

},{}],14:[function(require,module,exports){
var version = require("./version")

module.exports = isVirtualNode

function isVirtualNode(x) {
    return x && x.type === "VirtualNode" && x.version === version
}

},{"./version":17}],15:[function(require,module,exports){
var version = require("./version")

module.exports = isVirtualText

function isVirtualText(x) {
    return x && x.type === "VirtualText" && x.version === version
}

},{"./version":17}],16:[function(require,module,exports){
module.exports = isWidget

function isWidget(w) {
    return w && w.type === "Widget"
}

},{}],17:[function(require,module,exports){
module.exports = "2"

},{}],18:[function(require,module,exports){
var version = require("./version")
var isVNode = require("./is-vnode")
var isWidget = require("./is-widget")
var isThunk = require("./is-thunk")
var isVHook = require("./is-vhook")

module.exports = VirtualNode

var noProperties = {}
var noChildren = []

function VirtualNode(tagName, properties, children, key, namespace) {
    this.tagName = tagName
    this.properties = properties || noProperties
    this.children = children || noChildren
    this.key = key != null ? String(key) : undefined
    this.namespace = (typeof namespace === "string") ? namespace : null

    var count = (children && children.length) || 0
    var descendants = 0
    var hasWidgets = false
    var hasThunks = false
    var descendantHooks = false
    var hooks

    for (var propName in properties) {
        if (properties.hasOwnProperty(propName)) {
            var property = properties[propName]
            if (isVHook(property) && property.unhook) {
                if (!hooks) {
                    hooks = {}
                }

                hooks[propName] = property
            }
        }
    }

    for (var i = 0; i < count; i++) {
        var child = children[i]
        if (isVNode(child)) {
            descendants += child.count || 0

            if (!hasWidgets && child.hasWidgets) {
                hasWidgets = true
            }

            if (!hasThunks && child.hasThunks) {
                hasThunks = true
            }

            if (!descendantHooks && (child.hooks || child.descendantHooks)) {
                descendantHooks = true
            }
        } else if (!hasWidgets && isWidget(child)) {
            if (typeof child.destroy === "function") {
                hasWidgets = true
            }
        } else if (!hasThunks && isThunk(child)) {
            hasThunks = true;
        }
    }

    this.count = count + descendants
    this.hasWidgets = hasWidgets
    this.hasThunks = hasThunks
    this.hooks = hooks
    this.descendantHooks = descendantHooks
}

VirtualNode.prototype.version = version
VirtualNode.prototype.type = "VirtualNode"

},{"./is-thunk":12,"./is-vhook":13,"./is-vnode":14,"./is-widget":16,"./version":17}],19:[function(require,module,exports){
var version = require("./version")

VirtualPatch.NONE = 0
VirtualPatch.VTEXT = 1
VirtualPatch.VNODE = 2
VirtualPatch.WIDGET = 3
VirtualPatch.PROPS = 4
VirtualPatch.ORDER = 5
VirtualPatch.INSERT = 6
VirtualPatch.REMOVE = 7
VirtualPatch.THUNK = 8

module.exports = VirtualPatch

function VirtualPatch(type, vNode, patch) {
    this.type = Number(type)
    this.vNode = vNode
    this.patch = patch
}

VirtualPatch.prototype.version = version
VirtualPatch.prototype.type = "VirtualPatch"

},{"./version":17}],20:[function(require,module,exports){
var version = require("./version")

module.exports = VirtualText

function VirtualText(text) {
    this.text = String(text)
}

VirtualText.prototype.version = version
VirtualText.prototype.type = "VirtualText"

},{"./version":17}],21:[function(require,module,exports){
var isObject = require("is-object")
var isHook = require("../vnode/is-vhook")

module.exports = diffProps

function diffProps(a, b) {
    var diff

    for (var aKey in a) {
        if (!(aKey in b)) {
            diff = diff || {}
            diff[aKey] = undefined
        }

        var aValue = a[aKey]
        var bValue = b[aKey]

        if (aValue === bValue) {
            continue
        } else if (isObject(aValue) && isObject(bValue)) {
            if (getPrototype(bValue) !== getPrototype(aValue)) {
                diff = diff || {}
                diff[aKey] = bValue
            } else if (isHook(bValue)) {
                 diff = diff || {}
                 diff[aKey] = bValue
            } else {
                var objectDiff = diffProps(aValue, bValue)
                if (objectDiff) {
                    diff = diff || {}
                    diff[aKey] = objectDiff
                }
            }
        } else {
            diff = diff || {}
            diff[aKey] = bValue
        }
    }

    for (var bKey in b) {
        if (!(bKey in a)) {
            diff = diff || {}
            diff[bKey] = b[bKey]
        }
    }

    return diff
}

function getPrototype(value) {
  if (Object.getPrototypeOf) {
    return Object.getPrototypeOf(value)
  } else if (value.__proto__) {
    return value.__proto__
  } else if (value.constructor) {
    return value.constructor.prototype
  }
}

},{"../vnode/is-vhook":13,"is-object":3}],22:[function(require,module,exports){
var isArray = require("x-is-array")

var VPatch = require("../vnode/vpatch")
var isVNode = require("../vnode/is-vnode")
var isVText = require("../vnode/is-vtext")
var isWidget = require("../vnode/is-widget")
var isThunk = require("../vnode/is-thunk")
var handleThunk = require("../vnode/handle-thunk")

var diffProps = require("./diff-props")

module.exports = diff

function diff(a, b) {
    var patch = { a: a }
    walk(a, b, patch, 0)
    return patch
}

function walk(a, b, patch, index) {
    if (a === b) {
        return
    }

    var apply = patch[index]
    var applyClear = false

    if (isThunk(a) || isThunk(b)) {
        thunks(a, b, patch, index)
    } else if (b == null) {

        // If a is a widget we will add a remove patch for it
        // Otherwise any child widgets/hooks must be destroyed.
        // This prevents adding two remove patches for a widget.
        if (!isWidget(a)) {
            clearState(a, patch, index)
            apply = patch[index]
        }

        apply = appendPatch(apply, new VPatch(VPatch.REMOVE, a, b))
    } else if (isVNode(b)) {
        if (isVNode(a)) {
            if (a.tagName === b.tagName &&
                a.namespace === b.namespace &&
                a.key === b.key) {
                var propsPatch = diffProps(a.properties, b.properties)
                if (propsPatch) {
                    apply = appendPatch(apply,
                        new VPatch(VPatch.PROPS, a, propsPatch))
                }
                apply = diffChildren(a, b, patch, apply, index)
            } else {
                apply = appendPatch(apply, new VPatch(VPatch.VNODE, a, b))
                applyClear = true
            }
        } else {
            apply = appendPatch(apply, new VPatch(VPatch.VNODE, a, b))
            applyClear = true
        }
    } else if (isVText(b)) {
        if (!isVText(a)) {
            apply = appendPatch(apply, new VPatch(VPatch.VTEXT, a, b))
            applyClear = true
        } else if (a.text !== b.text) {
            apply = appendPatch(apply, new VPatch(VPatch.VTEXT, a, b))
        }
    } else if (isWidget(b)) {
        if (!isWidget(a)) {
            applyClear = true
        }

        apply = appendPatch(apply, new VPatch(VPatch.WIDGET, a, b))
    }

    if (apply) {
        patch[index] = apply
    }

    if (applyClear) {
        clearState(a, patch, index)
    }
}

function diffChildren(a, b, patch, apply, index) {
    var aChildren = a.children
    var orderedSet = reorder(aChildren, b.children)
    var bChildren = orderedSet.children

    var aLen = aChildren.length
    var bLen = bChildren.length
    var len = aLen > bLen ? aLen : bLen

    for (var i = 0; i < len; i++) {
        var leftNode = aChildren[i]
        var rightNode = bChildren[i]
        index += 1

        if (!leftNode) {
            if (rightNode) {
                // Excess nodes in b need to be added
                apply = appendPatch(apply,
                    new VPatch(VPatch.INSERT, null, rightNode))
            }
        } else {
            walk(leftNode, rightNode, patch, index)
        }

        if (isVNode(leftNode) && leftNode.count) {
            index += leftNode.count
        }
    }

    if (orderedSet.moves) {
        // Reorder nodes last
        apply = appendPatch(apply, new VPatch(
            VPatch.ORDER,
            a,
            orderedSet.moves
        ))
    }

    return apply
}

function clearState(vNode, patch, index) {
    // TODO: Make this a single walk, not two
    unhook(vNode, patch, index)
    destroyWidgets(vNode, patch, index)
}

// Patch records for all destroyed widgets must be added because we need
// a DOM node reference for the destroy function
function destroyWidgets(vNode, patch, index) {
    if (isWidget(vNode)) {
        if (typeof vNode.destroy === "function") {
            patch[index] = appendPatch(
                patch[index],
                new VPatch(VPatch.REMOVE, vNode, null)
            )
        }
    } else if (isVNode(vNode) && (vNode.hasWidgets || vNode.hasThunks)) {
        var children = vNode.children
        var len = children.length
        for (var i = 0; i < len; i++) {
            var child = children[i]
            index += 1

            destroyWidgets(child, patch, index)

            if (isVNode(child) && child.count) {
                index += child.count
            }
        }
    } else if (isThunk(vNode)) {
        thunks(vNode, null, patch, index)
    }
}

// Create a sub-patch for thunks
function thunks(a, b, patch, index) {
    var nodes = handleThunk(a, b)
    var thunkPatch = diff(nodes.a, nodes.b)
    if (hasPatches(thunkPatch)) {
        patch[index] = new VPatch(VPatch.THUNK, null, thunkPatch)
    }
}

function hasPatches(patch) {
    for (var index in patch) {
        if (index !== "a") {
            return true
        }
    }

    return false
}

// Execute hooks when two nodes are identical
function unhook(vNode, patch, index) {
    if (isVNode(vNode)) {
        if (vNode.hooks) {
            patch[index] = appendPatch(
                patch[index],
                new VPatch(
                    VPatch.PROPS,
                    vNode,
                    undefinedKeys(vNode.hooks)
                )
            )
        }

        if (vNode.descendantHooks || vNode.hasThunks) {
            var children = vNode.children
            var len = children.length
            for (var i = 0; i < len; i++) {
                var child = children[i]
                index += 1

                unhook(child, patch, index)

                if (isVNode(child) && child.count) {
                    index += child.count
                }
            }
        }
    } else if (isThunk(vNode)) {
        thunks(vNode, null, patch, index)
    }
}

function undefinedKeys(obj) {
    var result = {}

    for (var key in obj) {
        result[key] = undefined
    }

    return result
}

// List diff, naive left to right reordering
function reorder(aChildren, bChildren) {
    // O(M) time, O(M) memory
    var bChildIndex = keyIndex(bChildren)
    var bKeys = bChildIndex.keys
    var bFree = bChildIndex.free

    if (bFree.length === bChildren.length) {
        return {
            children: bChildren,
            moves: null
        }
    }

    // O(N) time, O(N) memory
    var aChildIndex = keyIndex(aChildren)
    var aKeys = aChildIndex.keys
    var aFree = aChildIndex.free

    if (aFree.length === aChildren.length) {
        return {
            children: bChildren,
            moves: null
        }
    }

    // O(MAX(N, M)) memory
    var newChildren = []

    var freeIndex = 0
    var freeCount = bFree.length
    var deletedItems = 0

    // Iterate through a and match a node in b
    // O(N) time,
    for (var i = 0 ; i < aChildren.length; i++) {
        var aItem = aChildren[i]
        var itemIndex

        if (aItem.key) {
            if (bKeys.hasOwnProperty(aItem.key)) {
                // Match up the old keys
                itemIndex = bKeys[aItem.key]
                newChildren.push(bChildren[itemIndex])

            } else {
                // Remove old keyed items
                itemIndex = i - deletedItems++
                newChildren.push(null)
            }
        } else {
            // Match the item in a with the next free item in b
            if (freeIndex < freeCount) {
                itemIndex = bFree[freeIndex++]
                newChildren.push(bChildren[itemIndex])
            } else {
                // There are no free items in b to match with
                // the free items in a, so the extra free nodes
                // are deleted.
                itemIndex = i - deletedItems++
                newChildren.push(null)
            }
        }
    }

    var lastFreeIndex = freeIndex >= bFree.length ?
        bChildren.length :
        bFree[freeIndex]

    // Iterate through b and append any new keys
    // O(M) time
    for (var j = 0; j < bChildren.length; j++) {
        var newItem = bChildren[j]

        if (newItem.key) {
            if (!aKeys.hasOwnProperty(newItem.key)) {
                // Add any new keyed items
                // We are adding new items to the end and then sorting them
                // in place. In future we should insert new items in place.
                newChildren.push(newItem)
            }
        } else if (j >= lastFreeIndex) {
            // Add any leftover non-keyed items
            newChildren.push(newItem)
        }
    }

    var simulate = newChildren.slice()
    var simulateIndex = 0
    var removes = []
    var inserts = []
    var simulateItem

    for (var k = 0; k < bChildren.length;) {
        var wantedItem = bChildren[k]
        simulateItem = simulate[simulateIndex]

        // remove items
        while (simulateItem === null && simulate.length) {
            removes.push(remove(simulate, simulateIndex, null))
            simulateItem = simulate[simulateIndex]
        }

        if (!simulateItem || simulateItem.key !== wantedItem.key) {
            // if we need a key in this position...
            if (wantedItem.key) {
                if (simulateItem && simulateItem.key) {
                    // if an insert doesn't put this key in place, it needs to move
                    if (bKeys[simulateItem.key] !== k + 1) {
                        removes.push(remove(simulate, simulateIndex, simulateItem.key))
                        simulateItem = simulate[simulateIndex]
                        // if the remove didn't put the wanted item in place, we need to insert it
                        if (!simulateItem || simulateItem.key !== wantedItem.key) {
                            inserts.push({key: wantedItem.key, to: k})
                        }
                        // items are matching, so skip ahead
                        else {
                            simulateIndex++
                        }
                    }
                    else {
                        inserts.push({key: wantedItem.key, to: k})
                    }
                }
                else {
                    inserts.push({key: wantedItem.key, to: k})
                }
                k++
            }
            // a key in simulate has no matching wanted key, remove it
            else if (simulateItem && simulateItem.key) {
                removes.push(remove(simulate, simulateIndex, simulateItem.key))
            }
        }
        else {
            simulateIndex++
            k++
        }
    }

    // remove all the remaining nodes from simulate
    while(simulateIndex < simulate.length) {
        simulateItem = simulate[simulateIndex]
        removes.push(remove(simulate, simulateIndex, simulateItem && simulateItem.key))
    }

    // If the only moves we have are deletes then we can just
    // let the delete patch remove these items.
    if (removes.length === deletedItems && !inserts.length) {
        return {
            children: newChildren,
            moves: null
        }
    }

    return {
        children: newChildren,
        moves: {
            removes: removes,
            inserts: inserts
        }
    }
}

function remove(arr, index, key) {
    arr.splice(index, 1)

    return {
        from: index,
        key: key
    }
}

function keyIndex(children) {
    var keys = {}
    var free = []
    var length = children.length

    for (var i = 0; i < length; i++) {
        var child = children[i]

        if (child.key) {
            keys[child.key] = i
        } else {
            free.push(i)
        }
    }

    return {
        keys: keys,     // A hash of key name to index
        free: free,     // An array of unkeyed item indices
    }
}

function appendPatch(apply, patch) {
    if (apply) {
        if (isArray(apply)) {
            apply.push(patch)
        } else {
            apply = [apply, patch]
        }

        return apply
    } else {
        return patch
    }
}

},{"../vnode/handle-thunk":11,"../vnode/is-thunk":12,"../vnode/is-vnode":14,"../vnode/is-vtext":15,"../vnode/is-widget":16,"../vnode/vpatch":19,"./diff-props":21,"x-is-array":4}],23:[function(require,module,exports){
var VNode = require('virtual-dom/vnode/vnode');
var VText = require('virtual-dom/vnode/vtext');
var diff = require('virtual-dom/vtree/diff');
var patch = require('virtual-dom/vdom/patch');
var createElement = require('virtual-dom/vdom/create-element');
var isHook = require("virtual-dom/vnode/is-vhook");


Elm.Native.VirtualDom = {};
Elm.Native.VirtualDom.make = function(elm)
{
	elm.Native = elm.Native || {};
	elm.Native.VirtualDom = elm.Native.VirtualDom || {};
	if (elm.Native.VirtualDom.values)
	{
		return elm.Native.VirtualDom.values;
	}

	var Element = Elm.Native.Graphics.Element.make(elm);
	var Json = Elm.Native.Json.make(elm);
	var List = Elm.Native.List.make(elm);
	var Signal = Elm.Native.Signal.make(elm);
	var Utils = Elm.Native.Utils.make(elm);

	var ATTRIBUTE_KEY = 'UniqueNameThatOthersAreVeryUnlikelyToUse';



	// VIRTUAL DOM NODES


	function text(string)
	{
		return new VText(string);
	}

	function node(name)
	{
		return F2(function(propertyList, contents) {
			return makeNode(name, propertyList, contents);
		});
	}


	// BUILD VIRTUAL DOME NODES


	function makeNode(name, propertyList, contents)
	{
		var props = listToProperties(propertyList);

		var key, namespace;
		// support keys
		if (props.key !== undefined)
		{
			key = props.key;
			props.key = undefined;
		}

		// support namespace
		if (props.namespace !== undefined)
		{
			namespace = props.namespace;
			props.namespace = undefined;
		}

		// ensure that setting text of an input does not move the cursor
		var useSoftSet =
			(name === 'input' || name === 'textarea')
			&& props.value !== undefined
			&& !isHook(props.value);

		if (useSoftSet)
		{
			props.value = SoftSetHook(props.value);
		}

		return new VNode(name, props, List.toArray(contents), key, namespace);
	}

	function listToProperties(list)
	{
		var object = {};
		while (list.ctor !== '[]')
		{
			var entry = list._0;
			if (entry.key === ATTRIBUTE_KEY)
			{
				object.attributes = object.attributes || {};
				object.attributes[entry.value.attrKey] = entry.value.attrValue;
			}
			else
			{
				object[entry.key] = entry.value;
			}
			list = list._1;
		}
		return object;
	}



	// PROPERTIES AND ATTRIBUTES


	function property(key, value)
	{
		return {
			key: key,
			value: value
		};
	}

	function attribute(key, value)
	{
		return {
			key: ATTRIBUTE_KEY,
			value: {
				attrKey: key,
				attrValue: value
			}
		};
	}



	// NAMESPACED ATTRIBUTES


	function attributeNS(namespace, key, value)
	{
		return {
			key: key,
			value: new AttributeHook(namespace, key, value)
		};
	}

	function AttributeHook(namespace, key, value)
	{
		if (!(this instanceof AttributeHook))
		{
			return new AttributeHook(namespace, key, value);
		}

		this.namespace = namespace;
		this.key = key;
		this.value = value;
	}

	AttributeHook.prototype.hook = function (node, prop, prev)
	{
		if (prev
			&& prev.type === 'AttributeHook'
			&& prev.value === this.value
			&& prev.namespace === this.namespace)
		{
			return;
		}

		node.setAttributeNS(this.namespace, prop, this.value);
	};

	AttributeHook.prototype.unhook = function (node, prop, next)
	{
		if (next
			&& next.type === 'AttributeHook'
			&& next.namespace === this.namespace)
		{
			return;
		}

		node.removeAttributeNS(this.namespace, this.key);
	};

	AttributeHook.prototype.type = 'AttributeHook';



	// EVENTS


	function on(name, options, decoder, createMessage)
	{
		function eventHandler(event)
		{
			var value = A2(Json.runDecoderValue, decoder, event);
			if (value.ctor === 'Ok')
			{
				if (options.stopPropagation)
				{
					event.stopPropagation();
				}
				if (options.preventDefault)
				{
					event.preventDefault();
				}
				Signal.sendMessage(createMessage(value._0));
			}
		}
		return property('on' + name, eventHandler);
	}

	function SoftSetHook(value)
	{
		if (!(this instanceof SoftSetHook))
		{
			return new SoftSetHook(value);
		}

		this.value = value;
	}

	SoftSetHook.prototype.hook = function (node, propertyName)
	{
		if (node[propertyName] !== this.value)
		{
			node[propertyName] = this.value;
		}
	};



	// INTEGRATION WITH ELEMENTS


	function ElementWidget(element)
	{
		this.element = element;
	}

	ElementWidget.prototype.type = "Widget";

	ElementWidget.prototype.init = function init()
	{
		return Element.render(this.element);
	};

	ElementWidget.prototype.update = function update(previous, node)
	{
		return Element.update(node, previous.element, this.element);
	};

	function fromElement(element)
	{
		return new ElementWidget(element);
	}

	function toElement(width, height, html)
	{
		return A3(Element.newElement, width, height, {
			ctor: 'Custom',
			type: 'evancz/elm-html',
			render: render,
			update: update,
			model: html
		});
	}



	// RENDER AND UPDATE


	function render(model)
	{
		var element = Element.createNode('div');
		element.appendChild(createElement(model));
		return element;
	}

	function update(node, oldModel, newModel)
	{
		updateAndReplace(node.firstChild, oldModel, newModel);
		return node;
	}

	function updateAndReplace(node, oldModel, newModel)
	{
		var patches = diff(oldModel, newModel);
		var newNode = patch(node, patches);
		return newNode;
	}



	// LAZINESS


	function lazyRef(fn, a)
	{
		function thunk()
		{
			return fn(a);
		}
		return new Thunk(fn, [a], thunk);
	}

	function lazyRef2(fn, a, b)
	{
		function thunk()
		{
			return A2(fn, a, b);
		}
		return new Thunk(fn, [a,b], thunk);
	}

	function lazyRef3(fn, a, b, c)
	{
		function thunk()
		{
			return A3(fn, a, b, c);
		}
		return new Thunk(fn, [a,b,c], thunk);
	}

	function Thunk(fn, args, thunk)
	{
		/* public (used by VirtualDom.js) */
		this.vnode = null;
		this.key = undefined;

		/* private */
		this.fn = fn;
		this.args = args;
		this.thunk = thunk;
	}

	Thunk.prototype.type = "Thunk";
	Thunk.prototype.render = renderThunk;

	function shouldUpdate(current, previous)
	{
		if (current.fn !== previous.fn)
		{
			return true;
		}

		// if it's the same function, we know the number of args must match
		var cargs = current.args;
		var pargs = previous.args;

		for (var i = cargs.length; i--; )
		{
			if (cargs[i] !== pargs[i])
			{
				return true;
			}
		}

		return false;
	}

	function renderThunk(previous)
	{
		if (previous == null || shouldUpdate(this, previous))
		{
			return this.thunk();
		}
		else
		{
			return previous.vnode;
		}
	}


	return elm.Native.VirtualDom.values = Elm.Native.VirtualDom.values = {
		node: node,
		text: text,
		on: F4(on),

		property: F2(property),
		attribute: F2(attribute),
		attributeNS: F3(attributeNS),

		lazy: F2(lazyRef),
		lazy2: F3(lazyRef2),
		lazy3: F4(lazyRef3),

		toElement: F3(toElement),
		fromElement: fromElement,

		render: createElement,
		updateAndReplace: updateAndReplace
	};
};

},{"virtual-dom/vdom/create-element":6,"virtual-dom/vdom/patch":9,"virtual-dom/vnode/is-vhook":13,"virtual-dom/vnode/vnode":18,"virtual-dom/vnode/vtext":20,"virtual-dom/vtree/diff":22}]},{},[23]);

Elm.VirtualDom = Elm.VirtualDom || {};
Elm.VirtualDom.make = function (_elm) {
   "use strict";
   _elm.VirtualDom = _elm.VirtualDom || {};
   if (_elm.VirtualDom.values) return _elm.VirtualDom.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $Graphics$Element = Elm.Graphics.Element.make(_elm),
   $Json$Decode = Elm.Json.Decode.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Native$VirtualDom = Elm.Native.VirtualDom.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm);
   var _op = {};
   var lazy3 = $Native$VirtualDom.lazy3;
   var lazy2 = $Native$VirtualDom.lazy2;
   var lazy = $Native$VirtualDom.lazy;
   var defaultOptions = {stopPropagation: false
                        ,preventDefault: false};
   var Options = F2(function (a,b) {
      return {stopPropagation: a,preventDefault: b};
   });
   var onWithOptions = $Native$VirtualDom.on;
   var on = F3(function (eventName,decoder,toMessage) {
      return A4($Native$VirtualDom.on,
      eventName,
      defaultOptions,
      decoder,
      toMessage);
   });
   var attributeNS = $Native$VirtualDom.attributeNS;
   var attribute = $Native$VirtualDom.attribute;
   var property = $Native$VirtualDom.property;
   var Property = {ctor: "Property"};
   var fromElement = $Native$VirtualDom.fromElement;
   var toElement = $Native$VirtualDom.toElement;
   var text = $Native$VirtualDom.text;
   var node = $Native$VirtualDom.node;
   var Node = {ctor: "Node"};
   return _elm.VirtualDom.values = {_op: _op
                                   ,text: text
                                   ,node: node
                                   ,toElement: toElement
                                   ,fromElement: fromElement
                                   ,property: property
                                   ,attribute: attribute
                                   ,attributeNS: attributeNS
                                   ,on: on
                                   ,onWithOptions: onWithOptions
                                   ,defaultOptions: defaultOptions
                                   ,lazy: lazy
                                   ,lazy2: lazy2
                                   ,lazy3: lazy3
                                   ,Options: Options};
};
Elm.Html = Elm.Html || {};
Elm.Html.make = function (_elm) {
   "use strict";
   _elm.Html = _elm.Html || {};
   if (_elm.Html.values) return _elm.Html.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $Graphics$Element = Elm.Graphics.Element.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $VirtualDom = Elm.VirtualDom.make(_elm);
   var _op = {};
   var fromElement = $VirtualDom.fromElement;
   var toElement = $VirtualDom.toElement;
   var text = $VirtualDom.text;
   var node = $VirtualDom.node;
   var body = node("body");
   var section = node("section");
   var nav = node("nav");
   var article = node("article");
   var aside = node("aside");
   var h1 = node("h1");
   var h2 = node("h2");
   var h3 = node("h3");
   var h4 = node("h4");
   var h5 = node("h5");
   var h6 = node("h6");
   var header = node("header");
   var footer = node("footer");
   var address = node("address");
   var main$ = node("main");
   var p = node("p");
   var hr = node("hr");
   var pre = node("pre");
   var blockquote = node("blockquote");
   var ol = node("ol");
   var ul = node("ul");
   var li = node("li");
   var dl = node("dl");
   var dt = node("dt");
   var dd = node("dd");
   var figure = node("figure");
   var figcaption = node("figcaption");
   var div = node("div");
   var a = node("a");
   var em = node("em");
   var strong = node("strong");
   var small = node("small");
   var s = node("s");
   var cite = node("cite");
   var q = node("q");
   var dfn = node("dfn");
   var abbr = node("abbr");
   var time = node("time");
   var code = node("code");
   var $var = node("var");
   var samp = node("samp");
   var kbd = node("kbd");
   var sub = node("sub");
   var sup = node("sup");
   var i = node("i");
   var b = node("b");
   var u = node("u");
   var mark = node("mark");
   var ruby = node("ruby");
   var rt = node("rt");
   var rp = node("rp");
   var bdi = node("bdi");
   var bdo = node("bdo");
   var span = node("span");
   var br = node("br");
   var wbr = node("wbr");
   var ins = node("ins");
   var del = node("del");
   var img = node("img");
   var iframe = node("iframe");
   var embed = node("embed");
   var object = node("object");
   var param = node("param");
   var video = node("video");
   var audio = node("audio");
   var source = node("source");
   var track = node("track");
   var canvas = node("canvas");
   var svg = node("svg");
   var math = node("math");
   var table = node("table");
   var caption = node("caption");
   var colgroup = node("colgroup");
   var col = node("col");
   var tbody = node("tbody");
   var thead = node("thead");
   var tfoot = node("tfoot");
   var tr = node("tr");
   var td = node("td");
   var th = node("th");
   var form = node("form");
   var fieldset = node("fieldset");
   var legend = node("legend");
   var label = node("label");
   var input = node("input");
   var button = node("button");
   var select = node("select");
   var datalist = node("datalist");
   var optgroup = node("optgroup");
   var option = node("option");
   var textarea = node("textarea");
   var keygen = node("keygen");
   var output = node("output");
   var progress = node("progress");
   var meter = node("meter");
   var details = node("details");
   var summary = node("summary");
   var menuitem = node("menuitem");
   var menu = node("menu");
   return _elm.Html.values = {_op: _op
                             ,node: node
                             ,text: text
                             ,toElement: toElement
                             ,fromElement: fromElement
                             ,body: body
                             ,section: section
                             ,nav: nav
                             ,article: article
                             ,aside: aside
                             ,h1: h1
                             ,h2: h2
                             ,h3: h3
                             ,h4: h4
                             ,h5: h5
                             ,h6: h6
                             ,header: header
                             ,footer: footer
                             ,address: address
                             ,main$: main$
                             ,p: p
                             ,hr: hr
                             ,pre: pre
                             ,blockquote: blockquote
                             ,ol: ol
                             ,ul: ul
                             ,li: li
                             ,dl: dl
                             ,dt: dt
                             ,dd: dd
                             ,figure: figure
                             ,figcaption: figcaption
                             ,div: div
                             ,a: a
                             ,em: em
                             ,strong: strong
                             ,small: small
                             ,s: s
                             ,cite: cite
                             ,q: q
                             ,dfn: dfn
                             ,abbr: abbr
                             ,time: time
                             ,code: code
                             ,$var: $var
                             ,samp: samp
                             ,kbd: kbd
                             ,sub: sub
                             ,sup: sup
                             ,i: i
                             ,b: b
                             ,u: u
                             ,mark: mark
                             ,ruby: ruby
                             ,rt: rt
                             ,rp: rp
                             ,bdi: bdi
                             ,bdo: bdo
                             ,span: span
                             ,br: br
                             ,wbr: wbr
                             ,ins: ins
                             ,del: del
                             ,img: img
                             ,iframe: iframe
                             ,embed: embed
                             ,object: object
                             ,param: param
                             ,video: video
                             ,audio: audio
                             ,source: source
                             ,track: track
                             ,canvas: canvas
                             ,svg: svg
                             ,math: math
                             ,table: table
                             ,caption: caption
                             ,colgroup: colgroup
                             ,col: col
                             ,tbody: tbody
                             ,thead: thead
                             ,tfoot: tfoot
                             ,tr: tr
                             ,td: td
                             ,th: th
                             ,form: form
                             ,fieldset: fieldset
                             ,legend: legend
                             ,label: label
                             ,input: input
                             ,button: button
                             ,select: select
                             ,datalist: datalist
                             ,optgroup: optgroup
                             ,option: option
                             ,textarea: textarea
                             ,keygen: keygen
                             ,output: output
                             ,progress: progress
                             ,meter: meter
                             ,details: details
                             ,summary: summary
                             ,menuitem: menuitem
                             ,menu: menu};
};
Elm.Svg = Elm.Svg || {};
Elm.Svg.make = function (_elm) {
   "use strict";
   _elm.Svg = _elm.Svg || {};
   if (_elm.Svg.values) return _elm.Svg.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $Html = Elm.Html.make(_elm),
   $Json$Encode = Elm.Json.Encode.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $VirtualDom = Elm.VirtualDom.make(_elm);
   var _op = {};
   var text = $VirtualDom.text;
   var svgNamespace = A2($VirtualDom.property,
   "namespace",
   $Json$Encode.string("http://www.w3.org/2000/svg"));
   var node = F3(function (name,attributes,children) {
      return A3($VirtualDom.node,
      name,
      A2($List._op["::"],svgNamespace,attributes),
      children);
   });
   var svg = node("svg");
   var foreignObject = node("foreignObject");
   var animate = node("animate");
   var animateColor = node("animateColor");
   var animateMotion = node("animateMotion");
   var animateTransform = node("animateTransform");
   var mpath = node("mpath");
   var set = node("set");
   var a = node("a");
   var defs = node("defs");
   var g = node("g");
   var marker = node("marker");
   var mask = node("mask");
   var missingGlyph = node("missingGlyph");
   var pattern = node("pattern");
   var $switch = node("switch");
   var symbol = node("symbol");
   var desc = node("desc");
   var metadata = node("metadata");
   var title = node("title");
   var feBlend = node("feBlend");
   var feColorMatrix = node("feColorMatrix");
   var feComponentTransfer = node("feComponentTransfer");
   var feComposite = node("feComposite");
   var feConvolveMatrix = node("feConvolveMatrix");
   var feDiffuseLighting = node("feDiffuseLighting");
   var feDisplacementMap = node("feDisplacementMap");
   var feFlood = node("feFlood");
   var feFuncA = node("feFuncA");
   var feFuncB = node("feFuncB");
   var feFuncG = node("feFuncG");
   var feFuncR = node("feFuncR");
   var feGaussianBlur = node("feGaussianBlur");
   var feImage = node("feImage");
   var feMerge = node("feMerge");
   var feMergeNode = node("feMergeNode");
   var feMorphology = node("feMorphology");
   var feOffset = node("feOffset");
   var feSpecularLighting = node("feSpecularLighting");
   var feTile = node("feTile");
   var feTurbulence = node("feTurbulence");
   var font = node("font");
   var fontFace = node("fontFace");
   var fontFaceFormat = node("fontFaceFormat");
   var fontFaceName = node("fontFaceName");
   var fontFaceSrc = node("fontFaceSrc");
   var fontFaceUri = node("fontFaceUri");
   var hkern = node("hkern");
   var vkern = node("vkern");
   var linearGradient = node("linearGradient");
   var radialGradient = node("radialGradient");
   var stop = node("stop");
   var circle = node("circle");
   var ellipse = node("ellipse");
   var image = node("image");
   var line = node("line");
   var path = node("path");
   var polygon = node("polygon");
   var polyline = node("polyline");
   var rect = node("rect");
   var use = node("use");
   var feDistantLight = node("feDistantLight");
   var fePointLight = node("fePointLight");
   var feSpotLight = node("feSpotLight");
   var altGlyph = node("altGlyph");
   var altGlyphDef = node("altGlyphDef");
   var altGlyphItem = node("altGlyphItem");
   var glyph = node("glyph");
   var glyphRef = node("glyphRef");
   var textPath = node("textPath");
   var text$ = node("text");
   var tref = node("tref");
   var tspan = node("tspan");
   var clipPath = node("clipPath");
   var colorProfile = node("colorProfile");
   var cursor = node("cursor");
   var filter = node("filter");
   var script = node("script");
   var style = node("style");
   var view = node("view");
   return _elm.Svg.values = {_op: _op
                            ,text: text
                            ,node: node
                            ,svg: svg
                            ,foreignObject: foreignObject
                            ,circle: circle
                            ,ellipse: ellipse
                            ,image: image
                            ,line: line
                            ,path: path
                            ,polygon: polygon
                            ,polyline: polyline
                            ,rect: rect
                            ,use: use
                            ,animate: animate
                            ,animateColor: animateColor
                            ,animateMotion: animateMotion
                            ,animateTransform: animateTransform
                            ,mpath: mpath
                            ,set: set
                            ,desc: desc
                            ,metadata: metadata
                            ,title: title
                            ,a: a
                            ,defs: defs
                            ,g: g
                            ,marker: marker
                            ,mask: mask
                            ,missingGlyph: missingGlyph
                            ,pattern: pattern
                            ,$switch: $switch
                            ,symbol: symbol
                            ,altGlyph: altGlyph
                            ,altGlyphDef: altGlyphDef
                            ,altGlyphItem: altGlyphItem
                            ,glyph: glyph
                            ,glyphRef: glyphRef
                            ,textPath: textPath
                            ,text$: text$
                            ,tref: tref
                            ,tspan: tspan
                            ,font: font
                            ,fontFace: fontFace
                            ,fontFaceFormat: fontFaceFormat
                            ,fontFaceName: fontFaceName
                            ,fontFaceSrc: fontFaceSrc
                            ,fontFaceUri: fontFaceUri
                            ,hkern: hkern
                            ,vkern: vkern
                            ,linearGradient: linearGradient
                            ,radialGradient: radialGradient
                            ,stop: stop
                            ,feBlend: feBlend
                            ,feColorMatrix: feColorMatrix
                            ,feComponentTransfer: feComponentTransfer
                            ,feComposite: feComposite
                            ,feConvolveMatrix: feConvolveMatrix
                            ,feDiffuseLighting: feDiffuseLighting
                            ,feDisplacementMap: feDisplacementMap
                            ,feFlood: feFlood
                            ,feFuncA: feFuncA
                            ,feFuncB: feFuncB
                            ,feFuncG: feFuncG
                            ,feFuncR: feFuncR
                            ,feGaussianBlur: feGaussianBlur
                            ,feImage: feImage
                            ,feMerge: feMerge
                            ,feMergeNode: feMergeNode
                            ,feMorphology: feMorphology
                            ,feOffset: feOffset
                            ,feSpecularLighting: feSpecularLighting
                            ,feTile: feTile
                            ,feTurbulence: feTurbulence
                            ,feDistantLight: feDistantLight
                            ,fePointLight: fePointLight
                            ,feSpotLight: feSpotLight
                            ,clipPath: clipPath
                            ,colorProfile: colorProfile
                            ,cursor: cursor
                            ,filter: filter
                            ,script: script
                            ,style: style
                            ,view: view};
};
Elm.Svg = Elm.Svg || {};
Elm.Svg.Attributes = Elm.Svg.Attributes || {};
Elm.Svg.Attributes.make = function (_elm) {
   "use strict";
   _elm.Svg = _elm.Svg || {};
   _elm.Svg.Attributes = _elm.Svg.Attributes || {};
   if (_elm.Svg.Attributes.values)
   return _elm.Svg.Attributes.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $Svg = Elm.Svg.make(_elm),
   $VirtualDom = Elm.VirtualDom.make(_elm);
   var _op = {};
   var writingMode = $VirtualDom.attribute("writing-mode");
   var wordSpacing = $VirtualDom.attribute("word-spacing");
   var visibility = $VirtualDom.attribute("visibility");
   var unicodeBidi = $VirtualDom.attribute("unicode-bidi");
   var textRendering = $VirtualDom.attribute("text-rendering");
   var textDecoration = $VirtualDom.attribute("text-decoration");
   var textAnchor = $VirtualDom.attribute("text-anchor");
   var stroke = $VirtualDom.attribute("stroke");
   var strokeWidth = $VirtualDom.attribute("stroke-width");
   var strokeOpacity = $VirtualDom.attribute("stroke-opacity");
   var strokeMiterlimit = $VirtualDom.attribute("stroke-miterlimit");
   var strokeLinejoin = $VirtualDom.attribute("stroke-linejoin");
   var strokeLinecap = $VirtualDom.attribute("stroke-linecap");
   var strokeDashoffset = $VirtualDom.attribute("stroke-dashoffset");
   var strokeDasharray = $VirtualDom.attribute("stroke-dasharray");
   var stopOpacity = $VirtualDom.attribute("stop-opacity");
   var stopColor = $VirtualDom.attribute("stop-color");
   var shapeRendering = $VirtualDom.attribute("shape-rendering");
   var pointerEvents = $VirtualDom.attribute("pointer-events");
   var overflow = $VirtualDom.attribute("overflow");
   var opacity = $VirtualDom.attribute("opacity");
   var mask = $VirtualDom.attribute("mask");
   var markerStart = $VirtualDom.attribute("marker-start");
   var markerMid = $VirtualDom.attribute("marker-mid");
   var markerEnd = $VirtualDom.attribute("marker-end");
   var lightingColor = $VirtualDom.attribute("lighting-color");
   var letterSpacing = $VirtualDom.attribute("letter-spacing");
   var kerning = $VirtualDom.attribute("kerning");
   var imageRendering = $VirtualDom.attribute("image-rendering");
   var glyphOrientationVertical = $VirtualDom.attribute("glyph-orientation-vertical");
   var glyphOrientationHorizontal = $VirtualDom.attribute("glyph-orientation-horizontal");
   var fontWeight = $VirtualDom.attribute("font-weight");
   var fontVariant = $VirtualDom.attribute("font-variant");
   var fontStyle = $VirtualDom.attribute("font-style");
   var fontStretch = $VirtualDom.attribute("font-stretch");
   var fontSize = $VirtualDom.attribute("font-size");
   var fontSizeAdjust = $VirtualDom.attribute("font-size-adjust");
   var fontFamily = $VirtualDom.attribute("font-family");
   var floodOpacity = $VirtualDom.attribute("flood-opacity");
   var floodColor = $VirtualDom.attribute("flood-color");
   var filter = $VirtualDom.attribute("filter");
   var fill = $VirtualDom.attribute("fill");
   var fillRule = $VirtualDom.attribute("fill-rule");
   var fillOpacity = $VirtualDom.attribute("fill-opacity");
   var enableBackground = $VirtualDom.attribute("enable-background");
   var dominantBaseline = $VirtualDom.attribute("dominant-baseline");
   var display = $VirtualDom.attribute("display");
   var direction = $VirtualDom.attribute("direction");
   var cursor = $VirtualDom.attribute("cursor");
   var color = $VirtualDom.attribute("color");
   var colorRendering = $VirtualDom.attribute("color-rendering");
   var colorProfile = $VirtualDom.attribute("color-profile");
   var colorInterpolation = $VirtualDom.attribute("color-interpolation");
   var colorInterpolationFilters = $VirtualDom.attribute("color-interpolation-filters");
   var clip = $VirtualDom.attribute("clip");
   var clipRule = $VirtualDom.attribute("clip-rule");
   var clipPath = $VirtualDom.attribute("clip-path");
   var baselineShift = $VirtualDom.attribute("baseline-shift");
   var alignmentBaseline = $VirtualDom.attribute("alignment-baseline");
   var zoomAndPan = $VirtualDom.attribute("zoomAndPan");
   var z = $VirtualDom.attribute("z");
   var yChannelSelector = $VirtualDom.attribute("yChannelSelector");
   var y2 = $VirtualDom.attribute("y2");
   var y1 = $VirtualDom.attribute("y1");
   var y = $VirtualDom.attribute("y");
   var xmlSpace = A2($VirtualDom.attributeNS,
   "http://www.w3.org/XML/1998/namespace",
   "xml:space");
   var xmlLang = A2($VirtualDom.attributeNS,
   "http://www.w3.org/XML/1998/namespace",
   "xml:lang");
   var xmlBase = A2($VirtualDom.attributeNS,
   "http://www.w3.org/XML/1998/namespace",
   "xml:base");
   var xlinkType = A2($VirtualDom.attributeNS,
   "http://www.w3.org/1999/xlink",
   "xlink:type");
   var xlinkTitle = A2($VirtualDom.attributeNS,
   "http://www.w3.org/1999/xlink",
   "xlink:title");
   var xlinkShow = A2($VirtualDom.attributeNS,
   "http://www.w3.org/1999/xlink",
   "xlink:show");
   var xlinkRole = A2($VirtualDom.attributeNS,
   "http://www.w3.org/1999/xlink",
   "xlink:role");
   var xlinkHref = A2($VirtualDom.attributeNS,
   "http://www.w3.org/1999/xlink",
   "xlink:href");
   var xlinkArcrole = A2($VirtualDom.attributeNS,
   "http://www.w3.org/1999/xlink",
   "xlink:arcrole");
   var xlinkActuate = A2($VirtualDom.attributeNS,
   "http://www.w3.org/1999/xlink",
   "xlink:actuate");
   var xChannelSelector = $VirtualDom.attribute("xChannelSelector");
   var x2 = $VirtualDom.attribute("x2");
   var x1 = $VirtualDom.attribute("x1");
   var xHeight = $VirtualDom.attribute("x-height");
   var x = $VirtualDom.attribute("x");
   var widths = $VirtualDom.attribute("widths");
   var width = $VirtualDom.attribute("width");
   var viewTarget = $VirtualDom.attribute("viewTarget");
   var viewBox = $VirtualDom.attribute("viewBox");
   var vertOriginY = $VirtualDom.attribute("vert-origin-y");
   var vertOriginX = $VirtualDom.attribute("vert-origin-x");
   var vertAdvY = $VirtualDom.attribute("vert-adv-y");
   var version = $VirtualDom.attribute("version");
   var values = $VirtualDom.attribute("values");
   var vMathematical = $VirtualDom.attribute("v-mathematical");
   var vIdeographic = $VirtualDom.attribute("v-ideographic");
   var vHanging = $VirtualDom.attribute("v-hanging");
   var vAlphabetic = $VirtualDom.attribute("v-alphabetic");
   var unitsPerEm = $VirtualDom.attribute("units-per-em");
   var unicodeRange = $VirtualDom.attribute("unicode-range");
   var unicode = $VirtualDom.attribute("unicode");
   var underlineThickness = $VirtualDom.attribute("underline-thickness");
   var underlinePosition = $VirtualDom.attribute("underline-position");
   var u2 = $VirtualDom.attribute("u2");
   var u1 = $VirtualDom.attribute("u1");
   var type$ = $VirtualDom.attribute("type");
   var transform = $VirtualDom.attribute("transform");
   var to = $VirtualDom.attribute("to");
   var title = $VirtualDom.attribute("title");
   var textLength = $VirtualDom.attribute("textLength");
   var targetY = $VirtualDom.attribute("targetY");
   var targetX = $VirtualDom.attribute("targetX");
   var target = $VirtualDom.attribute("target");
   var tableValues = $VirtualDom.attribute("tableValues");
   var systemLanguage = $VirtualDom.attribute("systemLanguage");
   var surfaceScale = $VirtualDom.attribute("surfaceScale");
   var style = $VirtualDom.attribute("style");
   var string = $VirtualDom.attribute("string");
   var strikethroughThickness = $VirtualDom.attribute("strikethrough-thickness");
   var strikethroughPosition = $VirtualDom.attribute("strikethrough-position");
   var stitchTiles = $VirtualDom.attribute("stitchTiles");
   var stemv = $VirtualDom.attribute("stemv");
   var stemh = $VirtualDom.attribute("stemh");
   var stdDeviation = $VirtualDom.attribute("stdDeviation");
   var startOffset = $VirtualDom.attribute("startOffset");
   var spreadMethod = $VirtualDom.attribute("spreadMethod");
   var speed = $VirtualDom.attribute("speed");
   var specularExponent = $VirtualDom.attribute("specularExponent");
   var specularConstant = $VirtualDom.attribute("specularConstant");
   var spacing = $VirtualDom.attribute("spacing");
   var slope = $VirtualDom.attribute("slope");
   var seed = $VirtualDom.attribute("seed");
   var scale = $VirtualDom.attribute("scale");
   var ry = $VirtualDom.attribute("ry");
   var rx = $VirtualDom.attribute("rx");
   var rotate = $VirtualDom.attribute("rotate");
   var result = $VirtualDom.attribute("result");
   var restart = $VirtualDom.attribute("restart");
   var requiredFeatures = $VirtualDom.attribute("requiredFeatures");
   var requiredExtensions = $VirtualDom.attribute("requiredExtensions");
   var repeatDur = $VirtualDom.attribute("repeatDur");
   var repeatCount = $VirtualDom.attribute("repeatCount");
   var renderingIntent = $VirtualDom.attribute("rendering-intent");
   var refY = $VirtualDom.attribute("refY");
   var refX = $VirtualDom.attribute("refX");
   var radius = $VirtualDom.attribute("radius");
   var r = $VirtualDom.attribute("r");
   var primitiveUnits = $VirtualDom.attribute("primitiveUnits");
   var preserveAspectRatio = $VirtualDom.attribute("preserveAspectRatio");
   var preserveAlpha = $VirtualDom.attribute("preserveAlpha");
   var pointsAtZ = $VirtualDom.attribute("pointsAtZ");
   var pointsAtY = $VirtualDom.attribute("pointsAtY");
   var pointsAtX = $VirtualDom.attribute("pointsAtX");
   var points = $VirtualDom.attribute("points");
   var pointOrder = $VirtualDom.attribute("point-order");
   var patternUnits = $VirtualDom.attribute("patternUnits");
   var patternTransform = $VirtualDom.attribute("patternTransform");
   var patternContentUnits = $VirtualDom.attribute("patternContentUnits");
   var pathLength = $VirtualDom.attribute("pathLength");
   var path = $VirtualDom.attribute("path");
   var panose1 = $VirtualDom.attribute("panose-1");
   var overlineThickness = $VirtualDom.attribute("overline-thickness");
   var overlinePosition = $VirtualDom.attribute("overline-position");
   var origin = $VirtualDom.attribute("origin");
   var orientation = $VirtualDom.attribute("orientation");
   var orient = $VirtualDom.attribute("orient");
   var order = $VirtualDom.attribute("order");
   var operator = $VirtualDom.attribute("operator");
   var offset = $VirtualDom.attribute("offset");
   var numOctaves = $VirtualDom.attribute("numOctaves");
   var name = $VirtualDom.attribute("name");
   var mode = $VirtualDom.attribute("mode");
   var min = $VirtualDom.attribute("min");
   var method = $VirtualDom.attribute("method");
   var media = $VirtualDom.attribute("media");
   var max = $VirtualDom.attribute("max");
   var mathematical = $VirtualDom.attribute("mathematical");
   var maskUnits = $VirtualDom.attribute("maskUnits");
   var maskContentUnits = $VirtualDom.attribute("maskContentUnits");
   var markerWidth = $VirtualDom.attribute("markerWidth");
   var markerUnits = $VirtualDom.attribute("markerUnits");
   var markerHeight = $VirtualDom.attribute("markerHeight");
   var local = $VirtualDom.attribute("local");
   var limitingConeAngle = $VirtualDom.attribute("limitingConeAngle");
   var lengthAdjust = $VirtualDom.attribute("lengthAdjust");
   var lang = $VirtualDom.attribute("lang");
   var keyTimes = $VirtualDom.attribute("keyTimes");
   var keySplines = $VirtualDom.attribute("keySplines");
   var keyPoints = $VirtualDom.attribute("keyPoints");
   var kernelUnitLength = $VirtualDom.attribute("kernelUnitLength");
   var kernelMatrix = $VirtualDom.attribute("kernelMatrix");
   var k4 = $VirtualDom.attribute("k4");
   var k3 = $VirtualDom.attribute("k3");
   var k2 = $VirtualDom.attribute("k2");
   var k1 = $VirtualDom.attribute("k1");
   var k = $VirtualDom.attribute("k");
   var intercept = $VirtualDom.attribute("intercept");
   var in2 = $VirtualDom.attribute("in2");
   var in$ = $VirtualDom.attribute("in");
   var ideographic = $VirtualDom.attribute("ideographic");
   var id = $VirtualDom.attribute("id");
   var horizOriginY = $VirtualDom.attribute("horiz-origin-y");
   var horizOriginX = $VirtualDom.attribute("horiz-origin-x");
   var horizAdvX = $VirtualDom.attribute("horiz-adv-x");
   var height = $VirtualDom.attribute("height");
   var hanging = $VirtualDom.attribute("hanging");
   var gradientUnits = $VirtualDom.attribute("gradientUnits");
   var gradientTransform = $VirtualDom.attribute("gradientTransform");
   var glyphRef = $VirtualDom.attribute("glyphRef");
   var glyphName = $VirtualDom.attribute("glyph-name");
   var g2 = $VirtualDom.attribute("g2");
   var g1 = $VirtualDom.attribute("g1");
   var fy = $VirtualDom.attribute("fy");
   var fx = $VirtualDom.attribute("fx");
   var from = $VirtualDom.attribute("from");
   var format = $VirtualDom.attribute("format");
   var filterUnits = $VirtualDom.attribute("filterUnits");
   var filterRes = $VirtualDom.attribute("filterRes");
   var externalResourcesRequired = $VirtualDom.attribute("externalResourcesRequired");
   var exponent = $VirtualDom.attribute("exponent");
   var end = $VirtualDom.attribute("end");
   var elevation = $VirtualDom.attribute("elevation");
   var edgeMode = $VirtualDom.attribute("edgeMode");
   var dy = $VirtualDom.attribute("dy");
   var dx = $VirtualDom.attribute("dx");
   var dur = $VirtualDom.attribute("dur");
   var divisor = $VirtualDom.attribute("divisor");
   var diffuseConstant = $VirtualDom.attribute("diffuseConstant");
   var descent = $VirtualDom.attribute("descent");
   var decelerate = $VirtualDom.attribute("decelerate");
   var d = $VirtualDom.attribute("d");
   var cy = $VirtualDom.attribute("cy");
   var cx = $VirtualDom.attribute("cx");
   var contentStyleType = $VirtualDom.attribute("contentStyleType");
   var contentScriptType = $VirtualDom.attribute("contentScriptType");
   var clipPathUnits = $VirtualDom.attribute("clipPathUnits");
   var $class = $VirtualDom.attribute("class");
   var capHeight = $VirtualDom.attribute("cap-height");
   var calcMode = $VirtualDom.attribute("calcMode");
   var by = $VirtualDom.attribute("by");
   var bias = $VirtualDom.attribute("bias");
   var begin = $VirtualDom.attribute("begin");
   var bbox = $VirtualDom.attribute("bbox");
   var baseProfile = $VirtualDom.attribute("baseProfile");
   var baseFrequency = $VirtualDom.attribute("baseFrequency");
   var azimuth = $VirtualDom.attribute("azimuth");
   var autoReverse = $VirtualDom.attribute("autoReverse");
   var attributeType = $VirtualDom.attribute("attributeType");
   var attributeName = $VirtualDom.attribute("attributeName");
   var ascent = $VirtualDom.attribute("ascent");
   var arabicForm = $VirtualDom.attribute("arabic-form");
   var amplitude = $VirtualDom.attribute("amplitude");
   var allowReorder = $VirtualDom.attribute("allowReorder");
   var alphabetic = $VirtualDom.attribute("alphabetic");
   var additive = $VirtualDom.attribute("additive");
   var accumulate = $VirtualDom.attribute("accumulate");
   var accelerate = $VirtualDom.attribute("accelerate");
   var accentHeight = $VirtualDom.attribute("accent-height");
   return _elm.Svg.Attributes.values = {_op: _op
                                       ,accentHeight: accentHeight
                                       ,accelerate: accelerate
                                       ,accumulate: accumulate
                                       ,additive: additive
                                       ,alphabetic: alphabetic
                                       ,allowReorder: allowReorder
                                       ,amplitude: amplitude
                                       ,arabicForm: arabicForm
                                       ,ascent: ascent
                                       ,attributeName: attributeName
                                       ,attributeType: attributeType
                                       ,autoReverse: autoReverse
                                       ,azimuth: azimuth
                                       ,baseFrequency: baseFrequency
                                       ,baseProfile: baseProfile
                                       ,bbox: bbox
                                       ,begin: begin
                                       ,bias: bias
                                       ,by: by
                                       ,calcMode: calcMode
                                       ,capHeight: capHeight
                                       ,$class: $class
                                       ,clipPathUnits: clipPathUnits
                                       ,contentScriptType: contentScriptType
                                       ,contentStyleType: contentStyleType
                                       ,cx: cx
                                       ,cy: cy
                                       ,d: d
                                       ,decelerate: decelerate
                                       ,descent: descent
                                       ,diffuseConstant: diffuseConstant
                                       ,divisor: divisor
                                       ,dur: dur
                                       ,dx: dx
                                       ,dy: dy
                                       ,edgeMode: edgeMode
                                       ,elevation: elevation
                                       ,end: end
                                       ,exponent: exponent
                                       ,externalResourcesRequired: externalResourcesRequired
                                       ,filterRes: filterRes
                                       ,filterUnits: filterUnits
                                       ,format: format
                                       ,from: from
                                       ,fx: fx
                                       ,fy: fy
                                       ,g1: g1
                                       ,g2: g2
                                       ,glyphName: glyphName
                                       ,glyphRef: glyphRef
                                       ,gradientTransform: gradientTransform
                                       ,gradientUnits: gradientUnits
                                       ,hanging: hanging
                                       ,height: height
                                       ,horizAdvX: horizAdvX
                                       ,horizOriginX: horizOriginX
                                       ,horizOriginY: horizOriginY
                                       ,id: id
                                       ,ideographic: ideographic
                                       ,in$: in$
                                       ,in2: in2
                                       ,intercept: intercept
                                       ,k: k
                                       ,k1: k1
                                       ,k2: k2
                                       ,k3: k3
                                       ,k4: k4
                                       ,kernelMatrix: kernelMatrix
                                       ,kernelUnitLength: kernelUnitLength
                                       ,keyPoints: keyPoints
                                       ,keySplines: keySplines
                                       ,keyTimes: keyTimes
                                       ,lang: lang
                                       ,lengthAdjust: lengthAdjust
                                       ,limitingConeAngle: limitingConeAngle
                                       ,local: local
                                       ,markerHeight: markerHeight
                                       ,markerUnits: markerUnits
                                       ,markerWidth: markerWidth
                                       ,maskContentUnits: maskContentUnits
                                       ,maskUnits: maskUnits
                                       ,mathematical: mathematical
                                       ,max: max
                                       ,media: media
                                       ,method: method
                                       ,min: min
                                       ,mode: mode
                                       ,name: name
                                       ,numOctaves: numOctaves
                                       ,offset: offset
                                       ,operator: operator
                                       ,order: order
                                       ,orient: orient
                                       ,orientation: orientation
                                       ,origin: origin
                                       ,overlinePosition: overlinePosition
                                       ,overlineThickness: overlineThickness
                                       ,panose1: panose1
                                       ,path: path
                                       ,pathLength: pathLength
                                       ,patternContentUnits: patternContentUnits
                                       ,patternTransform: patternTransform
                                       ,patternUnits: patternUnits
                                       ,pointOrder: pointOrder
                                       ,points: points
                                       ,pointsAtX: pointsAtX
                                       ,pointsAtY: pointsAtY
                                       ,pointsAtZ: pointsAtZ
                                       ,preserveAlpha: preserveAlpha
                                       ,preserveAspectRatio: preserveAspectRatio
                                       ,primitiveUnits: primitiveUnits
                                       ,r: r
                                       ,radius: radius
                                       ,refX: refX
                                       ,refY: refY
                                       ,renderingIntent: renderingIntent
                                       ,repeatCount: repeatCount
                                       ,repeatDur: repeatDur
                                       ,requiredExtensions: requiredExtensions
                                       ,requiredFeatures: requiredFeatures
                                       ,restart: restart
                                       ,result: result
                                       ,rotate: rotate
                                       ,rx: rx
                                       ,ry: ry
                                       ,scale: scale
                                       ,seed: seed
                                       ,slope: slope
                                       ,spacing: spacing
                                       ,specularConstant: specularConstant
                                       ,specularExponent: specularExponent
                                       ,speed: speed
                                       ,spreadMethod: spreadMethod
                                       ,startOffset: startOffset
                                       ,stdDeviation: stdDeviation
                                       ,stemh: stemh
                                       ,stemv: stemv
                                       ,stitchTiles: stitchTiles
                                       ,strikethroughPosition: strikethroughPosition
                                       ,strikethroughThickness: strikethroughThickness
                                       ,string: string
                                       ,style: style
                                       ,surfaceScale: surfaceScale
                                       ,systemLanguage: systemLanguage
                                       ,tableValues: tableValues
                                       ,target: target
                                       ,targetX: targetX
                                       ,targetY: targetY
                                       ,textLength: textLength
                                       ,title: title
                                       ,to: to
                                       ,transform: transform
                                       ,type$: type$
                                       ,u1: u1
                                       ,u2: u2
                                       ,underlinePosition: underlinePosition
                                       ,underlineThickness: underlineThickness
                                       ,unicode: unicode
                                       ,unicodeRange: unicodeRange
                                       ,unitsPerEm: unitsPerEm
                                       ,vAlphabetic: vAlphabetic
                                       ,vHanging: vHanging
                                       ,vIdeographic: vIdeographic
                                       ,vMathematical: vMathematical
                                       ,values: values
                                       ,version: version
                                       ,vertAdvY: vertAdvY
                                       ,vertOriginX: vertOriginX
                                       ,vertOriginY: vertOriginY
                                       ,viewBox: viewBox
                                       ,viewTarget: viewTarget
                                       ,width: width
                                       ,widths: widths
                                       ,x: x
                                       ,xHeight: xHeight
                                       ,x1: x1
                                       ,x2: x2
                                       ,xChannelSelector: xChannelSelector
                                       ,xlinkActuate: xlinkActuate
                                       ,xlinkArcrole: xlinkArcrole
                                       ,xlinkHref: xlinkHref
                                       ,xlinkRole: xlinkRole
                                       ,xlinkShow: xlinkShow
                                       ,xlinkTitle: xlinkTitle
                                       ,xlinkType: xlinkType
                                       ,xmlBase: xmlBase
                                       ,xmlLang: xmlLang
                                       ,xmlSpace: xmlSpace
                                       ,y: y
                                       ,y1: y1
                                       ,y2: y2
                                       ,yChannelSelector: yChannelSelector
                                       ,z: z
                                       ,zoomAndPan: zoomAndPan
                                       ,alignmentBaseline: alignmentBaseline
                                       ,baselineShift: baselineShift
                                       ,clipPath: clipPath
                                       ,clipRule: clipRule
                                       ,clip: clip
                                       ,colorInterpolationFilters: colorInterpolationFilters
                                       ,colorInterpolation: colorInterpolation
                                       ,colorProfile: colorProfile
                                       ,colorRendering: colorRendering
                                       ,color: color
                                       ,cursor: cursor
                                       ,direction: direction
                                       ,display: display
                                       ,dominantBaseline: dominantBaseline
                                       ,enableBackground: enableBackground
                                       ,fillOpacity: fillOpacity
                                       ,fillRule: fillRule
                                       ,fill: fill
                                       ,filter: filter
                                       ,floodColor: floodColor
                                       ,floodOpacity: floodOpacity
                                       ,fontFamily: fontFamily
                                       ,fontSizeAdjust: fontSizeAdjust
                                       ,fontSize: fontSize
                                       ,fontStretch: fontStretch
                                       ,fontStyle: fontStyle
                                       ,fontVariant: fontVariant
                                       ,fontWeight: fontWeight
                                       ,glyphOrientationHorizontal: glyphOrientationHorizontal
                                       ,glyphOrientationVertical: glyphOrientationVertical
                                       ,imageRendering: imageRendering
                                       ,kerning: kerning
                                       ,letterSpacing: letterSpacing
                                       ,lightingColor: lightingColor
                                       ,markerEnd: markerEnd
                                       ,markerMid: markerMid
                                       ,markerStart: markerStart
                                       ,mask: mask
                                       ,opacity: opacity
                                       ,overflow: overflow
                                       ,pointerEvents: pointerEvents
                                       ,shapeRendering: shapeRendering
                                       ,stopColor: stopColor
                                       ,stopOpacity: stopOpacity
                                       ,strokeDasharray: strokeDasharray
                                       ,strokeDashoffset: strokeDashoffset
                                       ,strokeLinecap: strokeLinecap
                                       ,strokeLinejoin: strokeLinejoin
                                       ,strokeMiterlimit: strokeMiterlimit
                                       ,strokeOpacity: strokeOpacity
                                       ,strokeWidth: strokeWidth
                                       ,stroke: stroke
                                       ,textAnchor: textAnchor
                                       ,textDecoration: textDecoration
                                       ,textRendering: textRendering
                                       ,unicodeBidi: unicodeBidi
                                       ,visibility: visibility
                                       ,wordSpacing: wordSpacing
                                       ,writingMode: writingMode};
};
Elm.Material = Elm.Material || {};
Elm.Material.Icons = Elm.Material.Icons || {};
Elm.Material.Icons.Internal = Elm.Material.Icons.Internal || {};
Elm.Material.Icons.Internal.make = function (_elm) {
   "use strict";
   _elm.Material = _elm.Material || {};
   _elm.Material.Icons = _elm.Material.Icons || {};
   _elm.Material.Icons.Internal = _elm.Material.Icons.Internal || {};
   if (_elm.Material.Icons.Internal.values)
   return _elm.Material.Icons.Internal.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Color = Elm.Color.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $Svg = Elm.Svg.make(_elm),
   $Svg$Attributes = Elm.Svg.Attributes.make(_elm);
   var _op = {};
   var toRgbaString = function (color) {
      var _p0 = $Color.toRgb(color);
      var red = _p0.red;
      var green = _p0.green;
      var blue = _p0.blue;
      var alpha = _p0.alpha;
      return A2($Basics._op["++"],
      "rgba(",
      A2($Basics._op["++"],
      $Basics.toString(red),
      A2($Basics._op["++"],
      ",",
      A2($Basics._op["++"],
      $Basics.toString(green),
      A2($Basics._op["++"],
      ",",
      A2($Basics._op["++"],
      $Basics.toString(blue),
      A2($Basics._op["++"],
      ",",
      A2($Basics._op["++"],$Basics.toString(alpha),")"))))))));
   };
   var icon = F3(function (path,color,size) {
      var stringColor = toRgbaString(color);
      var stringSize = $Basics.toString(size);
      return A2($Svg.svg,
      _U.list([$Svg$Attributes.width(stringSize)
              ,$Svg$Attributes.height(stringSize)
              ,$Svg$Attributes.viewBox("0 0 24 24")]),
      _U.list([A2($Svg.path,
      _U.list([$Svg$Attributes.d(path)
              ,$Svg$Attributes.fill(stringColor)]),
      _U.list([]))]));
   });
   return _elm.Material.Icons.Internal.values = {_op: _op
                                                ,icon: icon
                                                ,toRgbaString: toRgbaString};
};
Elm.Material = Elm.Material || {};
Elm.Material.Icons = Elm.Material.Icons || {};
Elm.Material.Icons.Editor = Elm.Material.Icons.Editor || {};
Elm.Material.Icons.Editor.make = function (_elm) {
   "use strict";
   _elm.Material = _elm.Material || {};
   _elm.Material.Icons = _elm.Material.Icons || {};
   _elm.Material.Icons.Editor = _elm.Material.Icons.Editor || {};
   if (_elm.Material.Icons.Editor.values)
   return _elm.Material.Icons.Editor.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Color = Elm.Color.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $List = Elm.List.make(_elm),
   $Material$Icons$Internal = Elm.Material.Icons.Internal.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $Svg = Elm.Svg.make(_elm),
   $Svg$Attributes = Elm.Svg.Attributes.make(_elm);
   var _op = {};
   var wrap_text = $Material$Icons$Internal.icon("M4 19h6v-2H4v2zM20 5H4v2h16V5zm-3 6H4v2h13.25c1.1 0 2 .9 2 2s-.9 2-2 2H15v-2l-3 3 3 3v-2h2c2.21 0 4-1.79 4-4s-1.79-4-4-4z");
   var vertical_align_top = $Material$Icons$Internal.icon("M8 11h3v10h2V11h3l-4-4-4 4zM4 3v2h16V3H4z");
   var vertical_align_center = $Material$Icons$Internal.icon("M8 19h3v4h2v-4h3l-4-4-4 4zm8-14h-3V1h-2v4H8l4 4 4-4zM4 11v2h16v-2H4z");
   var vertical_align_bottom = $Material$Icons$Internal.icon("M16 13h-3V3h-2v10H8l4 4 4-4zM4 19v2h16v-2H4z");
   var strikethrough_s = $Material$Icons$Internal.icon("M5.9 10h6.3c-.8-.3-1.5-.6-2-.9-.7-.4-1-1-1-1.6 0-.3.1-.6.2-.9.1-.3.3-.5.6-.7.3-.2.6-.4 1-.5.4-.1.8-.2 1.4-.2.5 0 1 .1 1.4.2.4.1.7.3 1 .6.3.2.5.5.6.9.1.3.2.7.2 1.1h4c0-.9-.2-1.7-.5-2.4s-.8-1.4-1.4-1.9c-.6-.5-1.4-1-2.3-1.2-1-.4-2-.5-3.1-.5s-2 .1-2.9.4c-.9.3-1.6.6-2.3 1.1-.6.5-1.1 1-1.4 1.7-.4.7-.6 1.4-.6 2.2 0 .8.2 1.6.5 2.2.1.2.2.3.3.4zM23 12H1v2h11.9c.2.1.5.2.7.3.5.2.9.5 1.2.7.3.2.5.5.6.8.1.3.1.6.1.9 0 .3-.1.6-.2.9-.1.3-.3.5-.6.7-.2.2-.6.3-.9.5-.4.1-.8.2-1.4.2-.6 0-1.1-.1-1.6-.2s-.9-.3-1.2-.6c-.3-.3-.6-.6-.8-1-.2-.4-.3-1-.3-1.6h-4c0 .7.1 1.5.3 2.1.2.6.5 1.1.9 1.6s.8.9 1.3 1.2c.5.3 1 .6 1.6.9.6.2 1.2.4 1.8.5.6.1 1.3.2 1.9.2 1.1 0 2-.1 2.9-.4.9-.2 1.6-.6 2.2-1.1.6-.5 1.1-1 1.4-1.7.3-.7.5-1.4.5-2.3 0-.8-.1-1.5-.4-2.2-.1-.2-.1-.3-.2-.4H23v-2z");
   var space_bar = $Material$Icons$Internal.icon("M18 9v4H6V9H4v6h16V9z");
   var publish = $Material$Icons$Internal.icon("M5 4v2h14V4H5zm0 10h4v6h6v-6h4l-7-7-7 7z");
   var money_off = $Material$Icons$Internal.icon("M12.5 6.9c1.78 0 2.44.85 2.5 2.1h2.21c-.07-1.72-1.12-3.3-3.21-3.81V3h-3v2.16c-.53.12-1.03.3-1.48.54l1.47 1.47c.41-.17.91-.27 1.51-.27zM5.33 4.06L4.06 5.33 7.5 8.77c0 2.08 1.56 3.21 3.91 3.91l3.51 3.51c-.34.48-1.05.91-2.42.91-2.06 0-2.87-.92-2.98-2.1h-2.2c.12 2.19 1.76 3.42 3.68 3.83V21h3v-2.15c.96-.18 1.82-.55 2.45-1.12l2.22 2.22 1.27-1.27L5.33 4.06z");
   var mode_edit = $Material$Icons$Internal.icon("M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34c-.39-.39-1.02-.39-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z");
   var mode_comment = $Material$Icons$Internal.icon("M21.99 4c0-1.1-.89-2-1.99-2H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h14l4 4-.01-18z");
   var merge_type = $Material$Icons$Internal.icon("M17 20.41L18.41 19 15 15.59 13.59 17 17 20.41zM7.5 8H11v5.59L5.59 19 7 20.41l6-6V8h3.5L12 3.5 7.5 8z");
   var insert_photo = $Material$Icons$Internal.icon("M21 19V5c0-1.1-.9-2-2-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2zM8.5 13.5l2.5 3.01L14.5 12l4.5 6H5l3.5-4.5z");
   var insert_link = $Material$Icons$Internal.icon("M3.9 12c0-1.71 1.39-3.1 3.1-3.1h4V7H7c-2.76 0-5 2.24-5 5s2.24 5 5 5h4v-1.9H7c-1.71 0-3.1-1.39-3.1-3.1zM8 13h8v-2H8v2zm9-6h-4v1.9h4c1.71 0 3.1 1.39 3.1 3.1s-1.39 3.1-3.1 3.1h-4V17h4c2.76 0 5-2.24 5-5s-2.24-5-5-5z");
   var insert_invitation = $Material$Icons$Internal.icon("M17 12h-5v5h5v-5zM16 1v2H8V1H6v2H5c-1.11 0-1.99.9-1.99 2L3 19c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2h-1V1h-2zm3 18H5V8h14v11z");
   var insert_emoticon = $Material$Icons$Internal.icon("M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8zm3.5-9c.83 0 1.5-.67 1.5-1.5S16.33 8 15.5 8 14 8.67 14 9.5s.67 1.5 1.5 1.5zm-7 0c.83 0 1.5-.67 1.5-1.5S9.33 8 8.5 8 7 8.67 7 9.5 7.67 11 8.5 11zm3.5 6.5c2.33 0 4.31-1.46 5.11-3.5H6.89c.8 2.04 2.78 3.5 5.11 3.5z");
   var insert_drive_file = $Material$Icons$Internal.icon("M6 2c-1.1 0-1.99.9-1.99 2L4 20c0 1.1.89 2 1.99 2H18c1.1 0 2-.9 2-2V8l-6-6H6zm7 7V3.5L18.5 9H13z");
   var insert_comment = $Material$Icons$Internal.icon("M20 2H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h14l4 4V4c0-1.1-.9-2-2-2zm-2 12H6v-2h12v2zm0-3H6V9h12v2zm0-3H6V6h12v2z");
   var insert_chart = $Material$Icons$Internal.icon("M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zM9 17H7v-7h2v7zm4 0h-2V7h2v10zm4 0h-2v-4h2v4z");
   var functions = $Material$Icons$Internal.icon("M18 4H6v2l6.5 6L6 18v2h12v-3h-7l5-5-5-5h7z");
   var format_underlined = $Material$Icons$Internal.icon("M12 17c3.31 0 6-2.69 6-6V3h-2.5v8c0 1.93-1.57 3.5-3.5 3.5S8.5 12.93 8.5 11V3H6v8c0 3.31 2.69 6 6 6zm-7 2v2h14v-2H5z");
   var format_textdirection_r_to_l = $Material$Icons$Internal.icon("M10 10v5h2V4h2v11h2V4h2V2h-8C7.79 2 6 3.79 6 6s1.79 4 4 4zm-2 7v-3l-4 4 4 4v-3h12v-2H8z");
   var format_textdirection_l_to_r = $Material$Icons$Internal.icon("M9 10v5h2V4h2v11h2V4h2V2H9C6.79 2 5 3.79 5 6s1.79 4 4 4zm12 8l-4-4v3H5v2h12v3l4-4z");
   var format_strikethrough = $Material$Icons$Internal.icon("M10 19h4v-3h-4v3zM5 4v3h5v3h4V7h5V4H5zM3 14h18v-2H3v2z");
   var format_size = $Material$Icons$Internal.icon("M9 4v3h5v12h3V7h5V4H9zm-6 8h3v7h3v-7h3V9H3v3z");
   var format_quote = $Material$Icons$Internal.icon("M6 17h3l2-4V7H5v6h3zm8 0h3l2-4V7h-6v6h3z");
   var format_paint = $Material$Icons$Internal.icon("M18 4V3c0-.55-.45-1-1-1H5c-.55 0-1 .45-1 1v4c0 .55.45 1 1 1h12c.55 0 1-.45 1-1V6h1v4H9v11c0 .55.45 1 1 1h2c.55 0 1-.45 1-1v-9h8V4h-3z");
   var format_list_numbered = $Material$Icons$Internal.icon("M2 17h2v.5H3v1h1v.5H2v1h3v-4H2v1zm1-9h1V4H2v1h1v3zm-1 3h1.8L2 13.1v.9h3v-1H3.2L5 10.9V10H2v1zm5-6v2h14V5H7zm0 14h14v-2H7v2zm0-6h14v-2H7v2z");
   var format_list_bulleted = $Material$Icons$Internal.icon("M4 10.5c-.83 0-1.5.67-1.5 1.5s.67 1.5 1.5 1.5 1.5-.67 1.5-1.5-.67-1.5-1.5-1.5zm0-6c-.83 0-1.5.67-1.5 1.5S3.17 7.5 4 7.5 5.5 6.83 5.5 6 4.83 4.5 4 4.5zm0 12.17c-.74 0-1.33.6-1.33 1.33s.6 1.33 1.33 1.33 1.33-.6 1.33-1.33-.59-1.33-1.33-1.33zM7 19h14v-2H7v2zm0-6h14v-2H7v2zm0-8v2h14V5H7z");
   var format_line_spacing = $Material$Icons$Internal.icon("M6 7h2.5L5 3.5 1.5 7H4v10H1.5L5 20.5 8.5 17H6V7zm4-2v2h12V5H10zm0 14h12v-2H10v2zm0-6h12v-2H10v2z");
   var format_italic = $Material$Icons$Internal.icon("M10 4v3h2.21l-3.42 8H6v3h8v-3h-2.21l3.42-8H18V4z");
   var format_indent_increase = $Material$Icons$Internal.icon("M3 21h18v-2H3v2zM3 8v8l4-4-4-4zm8 9h10v-2H11v2zM3 3v2h18V3H3zm8 6h10V7H11v2zm0 4h10v-2H11v2z");
   var format_indent_decrease = $Material$Icons$Internal.icon("M11 17h10v-2H11v2zm-8-5l4 4V8l-4 4zm0 9h18v-2H3v2zM3 3v2h18V3H3zm8 6h10V7H11v2zm0 4h10v-2H11v2z");
   var format_color_text = F2(function (color,size) {
      var stringSize = $Basics.toString(size);
      var stringColor = $Material$Icons$Internal.toRgbaString(color);
      return A2($Svg.svg,
      _U.list([$Svg$Attributes.width(stringSize)
              ,$Svg$Attributes.height(stringSize)
              ,$Svg$Attributes.viewBox("0 0 24 24")]),
      _U.list([A2($Svg.path,
              _U.list([$Svg$Attributes.d("M0 20h24v4H0z")
                      ,$Svg$Attributes.fill(stringColor)
                      ,$Svg$Attributes.fillOpacity(".36")]),
              _U.list([]))
              ,A2($Svg.path,
              _U.list([$Svg$Attributes.d("M11 3L5.5 17h2.25l1.12-3h6.25l1.12 3h2.25L13 3h-2zm-1.38 9L12 5.67 14.38 12H9.62z")
                      ,$Svg$Attributes.fill(stringColor)]),
              _U.list([]))]));
   });
   var format_color_reset = $Material$Icons$Internal.icon("M18 14c0-4-6-10.8-6-10.8s-1.33 1.51-2.73 3.52l8.59 8.59c.09-.42.14-.86.14-1.31zm-.88 3.12L12.5 12.5 5.27 5.27 4 6.55l3.32 3.32C6.55 11.32 6 12.79 6 14c0 3.31 2.69 6 6 6 1.52 0 2.9-.57 3.96-1.5l2.63 2.63 1.27-1.27-2.74-2.74z");
   var format_color_fill = F2(function (color,size) {
      var stringSize = $Basics.toString(size);
      var stringColor = $Material$Icons$Internal.toRgbaString(color);
      return A2($Svg.svg,
      _U.list([$Svg$Attributes.width(stringSize)
              ,$Svg$Attributes.height(stringSize)
              ,$Svg$Attributes.viewBox("0 0 24 24")]),
      _U.list([A2($Svg.path,
              _U.list([$Svg$Attributes.d("M16.56 8.94L7.62 0 6.21 1.41l2.38 2.38-5.15 5.15c-.59.59-.59 1.54 0 2.12l5.5 5.5c.29.29.68.44 1.06.44s.77-.15 1.06-.44l5.5-5.5c.59-.58.59-1.53 0-2.12zM5.21 10L10 5.21 14.79 10H5.21zM19 11.5s-2 2.17-2 3.5c0 1.1.9 2 2 2s2-.9 2-2c0-1.33-2-3.5-2-3.5z")
                      ,$Svg$Attributes.fill(stringColor)]),
              _U.list([]))
              ,A2($Svg.path,
              _U.list([$Svg$Attributes.fillOpacity(".36")
                      ,$Svg$Attributes.d("M0 20h24v4H0z")
                      ,$Svg$Attributes.fill(stringColor)]),
              _U.list([]))]));
   });
   var format_clear = $Material$Icons$Internal.icon("M3.27 5L2 6.27l6.97 6.97L6.5 19h3l1.57-3.66L16.73 21 18 19.73 3.55 5.27 3.27 5zM6 5v.18L8.82 8h2.4l-.72 1.68 2.1 2.1L14.21 8H20V5H6z");
   var format_bold = $Material$Icons$Internal.icon("M15.6 10.79c.97-.67 1.65-1.77 1.65-2.79 0-2.26-1.75-4-4-4H7v14h7.04c2.09 0 3.71-1.7 3.71-3.79 0-1.52-.86-2.82-2.15-3.42zM10 6.5h3c.83 0 1.5.67 1.5 1.5s-.67 1.5-1.5 1.5h-3v-3zm3.5 9H10v-3h3.5c.83 0 1.5.67 1.5 1.5s-.67 1.5-1.5 1.5z");
   var format_align_right = $Material$Icons$Internal.icon("M3 21h18v-2H3v2zm6-4h12v-2H9v2zm-6-4h18v-2H3v2zm6-4h12V7H9v2zM3 3v2h18V3H3z");
   var format_align_left = $Material$Icons$Internal.icon("M15 15H3v2h12v-2zm0-8H3v2h12V7zM3 13h18v-2H3v2zm0 8h18v-2H3v2zM3 3v2h18V3H3z");
   var format_align_justify = $Material$Icons$Internal.icon("M3 21h18v-2H3v2zm0-4h18v-2H3v2zm0-4h18v-2H3v2zm0-4h18V7H3v2zm0-6v2h18V3H3z");
   var format_align_center = $Material$Icons$Internal.icon("M7 15v2h10v-2H7zm-4 6h18v-2H3v2zm0-8h18v-2H3v2zm4-6v2h10V7H7zM3 3v2h18V3H3z");
   var border_vertical = $Material$Icons$Internal.icon("M3 9h2V7H3v2zm0-4h2V3H3v2zm4 16h2v-2H7v2zm0-8h2v-2H7v2zm-4 0h2v-2H3v2zm0 8h2v-2H3v2zm0-4h2v-2H3v2zM7 5h2V3H7v2zm12 12h2v-2h-2v2zm-8 4h2V3h-2v18zm8 0h2v-2h-2v2zm0-8h2v-2h-2v2zm0-10v2h2V3h-2zm0 6h2V7h-2v2zm-4-4h2V3h-2v2zm0 16h2v-2h-2v2zm0-8h2v-2h-2v2z");
   var border_top = $Material$Icons$Internal.icon("M7 21h2v-2H7v2zm0-8h2v-2H7v2zm4 0h2v-2h-2v2zm0 8h2v-2h-2v2zm-8-4h2v-2H3v2zm0 4h2v-2H3v2zm0-8h2v-2H3v2zm0-4h2V7H3v2zm8 8h2v-2h-2v2zm8-8h2V7h-2v2zm0 4h2v-2h-2v2zM3 3v2h18V3H3zm16 14h2v-2h-2v2zm-4 4h2v-2h-2v2zM11 9h2V7h-2v2zm8 12h2v-2h-2v2zm-4-8h2v-2h-2v2z");
   var border_style = $Material$Icons$Internal.icon("M15 21h2v-2h-2v2zm4 0h2v-2h-2v2zM7 21h2v-2H7v2zm4 0h2v-2h-2v2zm8-4h2v-2h-2v2zm0-4h2v-2h-2v2zM3 3v18h2V5h16V3H3zm16 6h2V7h-2v2z");
   var border_right = $Material$Icons$Internal.icon("M7 21h2v-2H7v2zM3 5h2V3H3v2zm4 0h2V3H7v2zm0 8h2v-2H7v2zm-4 8h2v-2H3v2zm8 0h2v-2h-2v2zm-8-8h2v-2H3v2zm0 4h2v-2H3v2zm0-8h2V7H3v2zm8 8h2v-2h-2v2zm4-4h2v-2h-2v2zm4-10v18h2V3h-2zm-4 18h2v-2h-2v2zm0-16h2V3h-2v2zm-4 8h2v-2h-2v2zm0-8h2V3h-2v2zm0 4h2V7h-2v2z");
   var border_outer = $Material$Icons$Internal.icon("M13 7h-2v2h2V7zm0 4h-2v2h2v-2zm4 0h-2v2h2v-2zM3 3v18h18V3H3zm16 16H5V5h14v14zm-6-4h-2v2h2v-2zm-4-4H7v2h2v-2z");
   var border_left = $Material$Icons$Internal.icon("M11 21h2v-2h-2v2zm0-4h2v-2h-2v2zm0-12h2V3h-2v2zm0 4h2V7h-2v2zm0 4h2v-2h-2v2zm-4 8h2v-2H7v2zM7 5h2V3H7v2zm0 8h2v-2H7v2zm-4 8h2V3H3v18zM19 9h2V7h-2v2zm-4 12h2v-2h-2v2zm4-4h2v-2h-2v2zm0-14v2h2V3h-2zm0 10h2v-2h-2v2zm0 8h2v-2h-2v2zm-4-8h2v-2h-2v2zm0-8h2V3h-2v2z");
   var border_inner = $Material$Icons$Internal.icon("M3 21h2v-2H3v2zm4 0h2v-2H7v2zM5 7H3v2h2V7zM3 17h2v-2H3v2zM9 3H7v2h2V3zM5 3H3v2h2V3zm12 0h-2v2h2V3zm2 6h2V7h-2v2zm0-6v2h2V3h-2zm-4 18h2v-2h-2v2zM13 3h-2v8H3v2h8v8h2v-8h8v-2h-8V3zm6 18h2v-2h-2v2zm0-4h2v-2h-2v2z");
   var border_horizontal = $Material$Icons$Internal.icon("M3 21h2v-2H3v2zM5 7H3v2h2V7zM3 17h2v-2H3v2zm4 4h2v-2H7v2zM5 3H3v2h2V3zm4 0H7v2h2V3zm8 0h-2v2h2V3zm-4 4h-2v2h2V7zm0-4h-2v2h2V3zm6 14h2v-2h-2v2zm-8 4h2v-2h-2v2zm-8-8h18v-2H3v2zM19 3v2h2V3h-2zm0 6h2V7h-2v2zm-8 8h2v-2h-2v2zm4 4h2v-2h-2v2zm4 0h2v-2h-2v2z");
   var border_color = F2(function (color,size) {
      var stringSize = $Basics.toString(size);
      var stringColor = $Material$Icons$Internal.toRgbaString(color);
      return A2($Svg.svg,
      _U.list([$Svg$Attributes.width(stringSize)
              ,$Svg$Attributes.height(stringSize)
              ,$Svg$Attributes.viewBox("0 0 24 24")]),
      _U.list([A2($Svg.path,
              _U.list([$Svg$Attributes.d("M17.75 7L14 3.25l-10 10V17h3.75l10-10zm2.96-2.96c.39-.39.39-1.02 0-1.41L18.37.29c-.39-.39-1.02-.39-1.41 0L15 2.25 18.75 6l1.96-1.96z")
                      ,$Svg$Attributes.fill(stringColor)]),
              _U.list([]))
              ,A2($Svg.path,
              _U.list([$Svg$Attributes.fillOpacity(".36")
                      ,$Svg$Attributes.d("M0 20h24v4H0z")
                      ,$Svg$Attributes.fill(stringColor)]),
              _U.list([]))]));
   });
   var border_clear = $Material$Icons$Internal.icon("M7 5h2V3H7v2zm0 8h2v-2H7v2zm0 8h2v-2H7v2zm4-4h2v-2h-2v2zm0 4h2v-2h-2v2zm-8 0h2v-2H3v2zm0-4h2v-2H3v2zm0-4h2v-2H3v2zm0-4h2V7H3v2zm0-4h2V3H3v2zm8 8h2v-2h-2v2zm8 4h2v-2h-2v2zm0-4h2v-2h-2v2zm0 8h2v-2h-2v2zm0-12h2V7h-2v2zm-8 0h2V7h-2v2zm8-6v2h2V3h-2zm-8 2h2V3h-2v2zm4 16h2v-2h-2v2zm0-8h2v-2h-2v2zm0-8h2V3h-2v2z");
   var border_bottom = $Material$Icons$Internal.icon("M9 11H7v2h2v-2zm4 4h-2v2h2v-2zM9 3H7v2h2V3zm4 8h-2v2h2v-2zM5 3H3v2h2V3zm8 4h-2v2h2V7zm4 4h-2v2h2v-2zm-4-8h-2v2h2V3zm4 0h-2v2h2V3zm2 10h2v-2h-2v2zm0 4h2v-2h-2v2zM5 7H3v2h2V7zm14-4v2h2V3h-2zm0 6h2V7h-2v2zM5 11H3v2h2v-2zM3 21h18v-2H3v2zm2-6H3v2h2v-2z");
   var border_all = $Material$Icons$Internal.icon("M3 3v18h18V3H3zm8 16H5v-6h6v6zm0-8H5V5h6v6zm8 8h-6v-6h6v6zm0-8h-6V5h6v6z");
   var attach_money = $Material$Icons$Internal.icon("M11.8 10.9c-2.27-.59-3-1.2-3-2.15 0-1.09 1.01-1.85 2.7-1.85 1.78 0 2.44.85 2.5 2.1h2.21c-.07-1.72-1.12-3.3-3.21-3.81V3h-3v2.16c-1.94.42-3.5 1.68-3.5 3.61 0 2.31 1.91 3.46 4.7 4.13 2.5.6 3 1.48 3 2.41 0 .69-.49 1.79-2.7 1.79-2.06 0-2.87-.92-2.98-2.1h-2.2c.12 2.19 1.76 3.42 3.68 3.83V21h3v-2.15c1.95-.37 3.5-1.5 3.5-3.55 0-2.84-2.43-3.81-4.7-4.4z");
   var attach_file = $Material$Icons$Internal.icon("M16.5 6v11.5c0 2.21-1.79 4-4 4s-4-1.79-4-4V5c0-1.38 1.12-2.5 2.5-2.5s2.5 1.12 2.5 2.5v10.5c0 .55-.45 1-1 1s-1-.45-1-1V6H10v9.5c0 1.38 1.12 2.5 2.5 2.5s2.5-1.12 2.5-2.5V5c0-2.21-1.79-4-4-4S7 2.79 7 5v12.5c0 3.04 2.46 5.5 5.5 5.5s5.5-2.46 5.5-5.5V6h-1.5z");
   return _elm.Material.Icons.Editor.values = {_op: _op
                                              ,attach_file: attach_file
                                              ,attach_money: attach_money
                                              ,border_all: border_all
                                              ,border_bottom: border_bottom
                                              ,border_clear: border_clear
                                              ,border_color: border_color
                                              ,border_horizontal: border_horizontal
                                              ,border_inner: border_inner
                                              ,border_left: border_left
                                              ,border_outer: border_outer
                                              ,border_right: border_right
                                              ,border_style: border_style
                                              ,border_top: border_top
                                              ,border_vertical: border_vertical
                                              ,format_align_center: format_align_center
                                              ,format_align_justify: format_align_justify
                                              ,format_align_left: format_align_left
                                              ,format_align_right: format_align_right
                                              ,format_bold: format_bold
                                              ,format_clear: format_clear
                                              ,format_color_fill: format_color_fill
                                              ,format_color_reset: format_color_reset
                                              ,format_color_text: format_color_text
                                              ,format_indent_decrease: format_indent_decrease
                                              ,format_indent_increase: format_indent_increase
                                              ,format_italic: format_italic
                                              ,format_line_spacing: format_line_spacing
                                              ,format_list_bulleted: format_list_bulleted
                                              ,format_list_numbered: format_list_numbered
                                              ,format_paint: format_paint
                                              ,format_quote: format_quote
                                              ,format_size: format_size
                                              ,format_strikethrough: format_strikethrough
                                              ,format_textdirection_l_to_r: format_textdirection_l_to_r
                                              ,format_textdirection_r_to_l: format_textdirection_r_to_l
                                              ,format_underlined: format_underlined
                                              ,functions: functions
                                              ,insert_chart: insert_chart
                                              ,insert_comment: insert_comment
                                              ,insert_drive_file: insert_drive_file
                                              ,insert_emoticon: insert_emoticon
                                              ,insert_invitation: insert_invitation
                                              ,insert_link: insert_link
                                              ,insert_photo: insert_photo
                                              ,merge_type: merge_type
                                              ,mode_comment: mode_comment
                                              ,mode_edit: mode_edit
                                              ,money_off: money_off
                                              ,publish: publish
                                              ,space_bar: space_bar
                                              ,strikethrough_s: strikethrough_s
                                              ,vertical_align_bottom: vertical_align_bottom
                                              ,vertical_align_center: vertical_align_center
                                              ,vertical_align_top: vertical_align_top
                                              ,wrap_text: wrap_text};
};
Elm.Material = Elm.Material || {};
Elm.Material.Icons = Elm.Material.Icons || {};
Elm.Material.Icons.Image = Elm.Material.Icons.Image || {};
Elm.Material.Icons.Image.make = function (_elm) {
   "use strict";
   _elm.Material = _elm.Material || {};
   _elm.Material.Icons = _elm.Material.Icons || {};
   _elm.Material.Icons.Image = _elm.Material.Icons.Image || {};
   if (_elm.Material.Icons.Image.values)
   return _elm.Material.Icons.Image.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Color = Elm.Color.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $List = Elm.List.make(_elm),
   $Material$Icons$Internal = Elm.Material.Icons.Internal.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $Svg = Elm.Svg.make(_elm),
   $Svg$Attributes = Elm.Svg.Attributes.make(_elm);
   var _op = {};
   var wb_sunny = $Material$Icons$Internal.icon("M6.76 4.84l-1.8-1.79-1.41 1.41 1.79 1.79 1.42-1.41zM4 10.5H1v2h3v-2zm9-9.95h-2V3.5h2V.55zm7.45 3.91l-1.41-1.41-1.79 1.79 1.41 1.41 1.79-1.79zm-3.21 13.7l1.79 1.8 1.41-1.41-1.8-1.79-1.4 1.4zM20 10.5v2h3v-2h-3zm-8-5c-3.31 0-6 2.69-6 6s2.69 6 6 6 6-2.69 6-6-2.69-6-6-6zm-1 16.95h2V19.5h-2v2.95zm-7.45-3.91l1.41 1.41 1.79-1.8-1.41-1.41-1.79 1.8z");
   var wb_iridescent = $Material$Icons$Internal.icon("M5 14.5h14v-6H5v6zM11 .55V3.5h2V.55h-2zm8.04 2.5l-1.79 1.79 1.41 1.41 1.8-1.79-1.42-1.41zM13 22.45V19.5h-2v2.95h2zm7.45-3.91l-1.8-1.79-1.41 1.41 1.79 1.8 1.42-1.42zM3.55 4.46l1.79 1.79 1.41-1.41-1.79-1.79-1.41 1.41zm1.41 15.49l1.79-1.8-1.41-1.41-1.79 1.79 1.41 1.42z");
   var wb_incandescent = $Material$Icons$Internal.icon("M3.55 18.54l1.41 1.41 1.79-1.8-1.41-1.41-1.79 1.8zM11 22.45h2V19.5h-2v2.95zM4 10.5H1v2h3v-2zm11-4.19V1.5H9v4.81C7.21 7.35 6 9.28 6 11.5c0 3.31 2.69 6 6 6s6-2.69 6-6c0-2.22-1.21-4.15-3-5.19zm5 4.19v2h3v-2h-3zm-2.76 7.66l1.79 1.8 1.41-1.41-1.8-1.79-1.4 1.4z");
   var wb_cloudy = $Material$Icons$Internal.icon("M19.36 10.04C18.67 6.59 15.64 4 12 4 9.11 4 6.6 5.64 5.35 8.04 2.34 8.36 0 10.91 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.64-4.96z");
   var wb_auto = $Material$Icons$Internal.icon("M6.85 12.65h2.3L8 9l-1.15 3.65zM22 7l-1.2 6.29L19.3 7h-1.6l-1.49 6.29L15 7h-.76C12.77 5.17 10.53 4 8 4c-4.42 0-8 3.58-8 8s3.58 8 8 8c3.13 0 5.84-1.81 7.15-4.43l.1.43H17l1.5-6.1L20 16h1.75l2.05-9H22zm-11.7 9l-.7-2H6.4l-.7 2H3.8L7 7h2l3.2 9h-1.9z");
   var vignette = $Material$Icons$Internal.icon("M21 3H3c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h18c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-9 15c-4.42 0-8-2.69-8-6s3.58-6 8-6 8 2.69 8 6-3.58 6-8 6z");
   var view_compact = $Material$Icons$Internal.icon("M3 19h6v-7H3v7zm7 0h12v-7H10v7zM3 5v6h19V5H3z");
   var view_comfy = $Material$Icons$Internal.icon("M3 9h4V5H3v4zm0 5h4v-4H3v4zm5 0h4v-4H8v4zm5 0h4v-4h-4v4zM8 9h4V5H8v4zm5-4v4h4V5h-4zm5 9h4v-4h-4v4zM3 19h4v-4H3v4zm5 0h4v-4H8v4zm5 0h4v-4h-4v4zm5 0h4v-4h-4v4zm0-14v4h4V5h-4z");
   var tune = $Material$Icons$Internal.icon("M3 17v2h6v-2H3zM3 5v2h10V5H3zm10 16v-2h8v-2h-8v-2h-2v6h2zM7 9v2H3v2h4v2h2V9H7zm14 4v-2H11v2h10zm-6-4h2V7h4V5h-4V3h-2v6z");
   var transform = $Material$Icons$Internal.icon("M22 18v-2H8V4h2L7 1 4 4h2v2H2v2h4v8c0 1.1.9 2 2 2h8v2h-2l3 3 3-3h-2v-2h4zM10 8h6v6h2V8c0-1.1-.9-2-2-2h-6v2z");
   var tonality = $Material$Icons$Internal.icon("M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.94-.49-7-3.85-7-7.93s3.05-7.44 7-7.93v15.86zm2-15.86c1.03.13 2 .45 2.87.93H13v-.93zM13 7h5.24c.25.31.48.65.68 1H13V7zm0 3h6.74c.08.33.15.66.19 1H13v-1zm0 9.93V19h2.87c-.87.48-1.84.8-2.87.93zM18.24 17H13v-1h5.92c-.2.35-.43.69-.68 1zm1.5-3H13v-1h6.93c-.04.34-.11.67-.19 1z");
   var timer_off = $Material$Icons$Internal.icon("M19.04 4.55l-1.42 1.42C16.07 4.74 14.12 4 12 4c-1.83 0-3.53.55-4.95 1.48l1.46 1.46C9.53 6.35 10.73 6 12 6c3.87 0 7 3.13 7 7 0 1.27-.35 2.47-.94 3.49l1.45 1.45C20.45 16.53 21 14.83 21 13c0-2.12-.74-4.07-1.97-5.61l1.42-1.42-1.41-1.42zM15 1H9v2h6V1zm-4 8.44l2 2V8h-2v1.44zM3.02 4L1.75 5.27 4.5 8.03C3.55 9.45 3 11.16 3 13c0 4.97 4.02 9 9 9 1.84 0 3.55-.55 4.98-1.5l2.5 2.5 1.27-1.27-7.71-7.71L3.02 4zM12 20c-3.87 0-7-3.13-7-7 0-1.28.35-2.48.95-3.52l9.56 9.56c-1.03.61-2.23.96-3.51.96z");
   var timer_3 = $Material$Icons$Internal.icon("M11.61 12.97c-.16-.24-.36-.46-.62-.65-.25-.19-.56-.35-.93-.48.3-.14.57-.3.8-.5.23-.2.42-.41.57-.64.15-.23.27-.46.34-.71.08-.24.11-.49.11-.73 0-.55-.09-1.04-.28-1.46-.18-.42-.44-.77-.78-1.06-.33-.28-.73-.5-1.2-.64-.45-.13-.97-.2-1.53-.2-.55 0-1.06.08-1.52.24-.47.17-.87.4-1.2.69-.33.29-.6.63-.78 1.03-.2.39-.29.83-.29 1.29h1.98c0-.26.05-.49.14-.69.09-.2.22-.38.38-.52.17-.14.36-.25.58-.33.22-.08.46-.12.73-.12.61 0 1.06.16 1.36.47.3.31.44.75.44 1.32 0 .27-.04.52-.12.74-.08.22-.21.41-.38.57-.17.16-.38.28-.63.37-.25.09-.55.13-.89.13H6.72v1.57H7.9c.34 0 .64.04.91.11.27.08.5.19.69.35.19.16.34.36.44.61.1.24.16.54.16.87 0 .62-.18 1.09-.53 1.42-.35.33-.84.49-1.45.49-.29 0-.56-.04-.8-.13-.24-.08-.44-.2-.61-.36-.17-.16-.3-.34-.39-.56-.09-.22-.14-.46-.14-.72H4.19c0 .55.11 1.03.32 1.45.21.42.5.77.86 1.05s.77.49 1.24.63.96.21 1.48.21c.57 0 1.09-.08 1.58-.23.49-.15.91-.38 1.26-.68.36-.3.64-.66.84-1.1.2-.43.3-.93.3-1.48 0-.29-.04-.58-.11-.86-.08-.25-.19-.51-.35-.76zm9.26 1.4c-.14-.28-.35-.53-.63-.74-.28-.21-.61-.39-1.01-.53s-.85-.27-1.35-.38c-.35-.07-.64-.15-.87-.23-.23-.08-.41-.16-.55-.25-.14-.09-.23-.19-.28-.3-.05-.11-.08-.24-.08-.39s.03-.28.09-.41c.06-.13.15-.25.27-.34.12-.1.27-.18.45-.24s.4-.09.64-.09c.25 0 .47.04.66.11.19.07.35.17.48.29.13.12.22.26.29.42.06.16.1.32.1.49h1.95c0-.39-.08-.75-.24-1.09-.16-.34-.39-.63-.69-.88-.3-.25-.66-.44-1.09-.59-.43-.15-.92-.22-1.46-.22-.51 0-.98.07-1.39.21-.41.14-.77.33-1.06.57-.29.24-.51.52-.67.84-.16.32-.23.65-.23 1.01s.08.68.23.96c.15.28.37.52.64.73.27.21.6.38.98.53.38.14.81.26 1.27.36.39.08.71.17.95.26s.43.19.57.29c.13.1.22.22.27.34.05.12.07.25.07.39 0 .32-.13.57-.4.77-.27.2-.66.29-1.17.29-.22 0-.43-.02-.64-.08-.21-.05-.4-.13-.56-.24-.17-.11-.3-.26-.41-.44-.11-.18-.17-.41-.18-.67h-1.89c0 .36.08.71.24 1.05.16.34.39.65.7.93.31.27.69.49 1.15.66.46.17.98.25 1.58.25.53 0 1.01-.06 1.44-.19.43-.13.8-.31 1.11-.54.31-.23.54-.51.71-.83.17-.32.25-.67.25-1.06-.02-.4-.09-.74-.24-1.02z");
   var timer = $Material$Icons$Internal.icon("M15 1H9v2h6V1zm-4 13h2V8h-2v6zm8.03-6.61l1.42-1.42c-.43-.51-.9-.99-1.41-1.41l-1.42 1.42C16.07 4.74 14.12 4 12 4c-4.97 0-9 4.03-9 9s4.02 9 9 9 9-4.03 9-9c0-2.12-.74-4.07-1.97-5.61zM12 20c-3.87 0-7-3.13-7-7s3.13-7 7-7 7 3.13 7 7-3.13 7-7 7z");
   var timer_10 = $Material$Icons$Internal.icon("M0 7.72V9.4l3-1V18h2V6h-.25L0 7.72zm23.78 6.65c-.14-.28-.35-.53-.63-.74-.28-.21-.61-.39-1.01-.53s-.85-.27-1.35-.38c-.35-.07-.64-.15-.87-.23-.23-.08-.41-.16-.55-.25-.14-.09-.23-.19-.28-.3-.05-.11-.08-.24-.08-.39 0-.14.03-.28.09-.41.06-.13.15-.25.27-.34.12-.1.27-.18.45-.24s.4-.09.64-.09c.25 0 .47.04.66.11.19.07.35.17.48.29.13.12.22.26.29.42.06.16.1.32.1.49h1.95c0-.39-.08-.75-.24-1.09-.16-.34-.39-.63-.69-.88-.3-.25-.66-.44-1.09-.59C21.49 9.07 21 9 20.46 9c-.51 0-.98.07-1.39.21-.41.14-.77.33-1.06.57-.29.24-.51.52-.67.84-.16.32-.23.65-.23 1.01s.08.69.23.96c.15.28.36.52.64.73.27.21.6.38.98.53.38.14.81.26 1.27.36.39.08.71.17.95.26s.43.19.57.29c.13.1.22.22.27.34.05.12.07.25.07.39 0 .32-.13.57-.4.77-.27.2-.66.29-1.17.29-.22 0-.43-.02-.64-.08-.21-.05-.4-.13-.56-.24-.17-.11-.3-.26-.41-.44-.11-.18-.17-.41-.18-.67h-1.89c0 .36.08.71.24 1.05.16.34.39.65.7.93.31.27.69.49 1.15.66.46.17.98.25 1.58.25.53 0 1.01-.06 1.44-.19.43-.13.8-.31 1.11-.54.31-.23.54-.51.71-.83.17-.32.25-.67.25-1.06-.02-.4-.09-.74-.24-1.02zm-9.96-7.32c-.34-.4-.75-.7-1.23-.88-.47-.18-1.01-.27-1.59-.27-.58 0-1.11.09-1.59.27-.48.18-.89.47-1.23.88-.34.41-.6.93-.79 1.59-.18.65-.28 1.45-.28 2.39v1.92c0 .94.09 1.74.28 2.39.19.66.45 1.19.8 1.6.34.41.75.71 1.23.89.48.18 1.01.28 1.59.28.59 0 1.12-.09 1.59-.28.48-.18.88-.48 1.22-.89.34-.41.6-.94.78-1.6.18-.65.28-1.45.28-2.39v-1.92c0-.94-.09-1.74-.28-2.39-.18-.66-.44-1.19-.78-1.59zm-.92 6.17c0 .6-.04 1.11-.12 1.53-.08.42-.2.76-.36 1.02-.16.26-.36.45-.59.57-.23.12-.51.18-.82.18-.3 0-.58-.06-.82-.18s-.44-.31-.6-.57c-.16-.26-.29-.6-.38-1.02-.09-.42-.13-.93-.13-1.53v-2.5c0-.6.04-1.11.13-1.52.09-.41.21-.74.38-1 .16-.25.36-.43.6-.55.24-.11.51-.17.81-.17.31 0 .58.06.81.17.24.11.44.29.6.55.16.25.29.58.37.99.08.41.13.92.13 1.52v2.51z");
   var timelapse = $Material$Icons$Internal.icon("M16.24 7.76C15.07 6.59 13.54 6 12 6v6l-4.24 4.24c2.34 2.34 6.14 2.34 8.49 0 2.34-2.34 2.34-6.14-.01-8.48zM12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8z");
   var texture = $Material$Icons$Internal.icon("M19.51 3.08L3.08 19.51c.09.34.27.65.51.9.25.24.56.42.9.51L20.93 4.49c-.19-.69-.73-1.23-1.42-1.41zM11.88 3L3 11.88v2.83L14.71 3h-2.83zM5 3c-1.1 0-2 .9-2 2v2l4-4H5zm14 18c.55 0 1.05-.22 1.41-.59.37-.36.59-.86.59-1.41v-2l-4 4h2zm-9.71 0h2.83L21 12.12V9.29L9.29 21z");
   var tag_faces = $Material$Icons$Internal.icon("M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8zm3.5-9c.83 0 1.5-.67 1.5-1.5S16.33 8 15.5 8 14 8.67 14 9.5s.67 1.5 1.5 1.5zm-7 0c.83 0 1.5-.67 1.5-1.5S9.33 8 8.5 8 7 8.67 7 9.5 7.67 11 8.5 11zm3.5 6.5c2.33 0 4.31-1.46 5.11-3.5H6.89c.8 2.04 2.78 3.5 5.11 3.5z");
   var switch_video = $Material$Icons$Internal.icon("M18 9.5V6c0-.55-.45-1-1-1H3c-.55 0-1 .45-1 1v12c0 .55.45 1 1 1h14c.55 0 1-.45 1-1v-3.5l4 4v-13l-4 4zm-5 6V13H7v2.5L3.5 12 7 8.5V11h6V8.5l3.5 3.5-3.5 3.5z");
   var switch_camera = $Material$Icons$Internal.icon("M20 4h-3.17L15 2H9L7.17 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm-5 11.5V13H9v2.5L5.5 12 9 8.5V11h6V8.5l3.5 3.5-3.5 3.5z");
   var style = $Material$Icons$Internal.icon("M2.53 19.65l1.34.56v-9.03l-2.43 5.86c-.41 1.02.08 2.19 1.09 2.61zm19.5-3.7L17.07 3.98c-.31-.75-1.04-1.21-1.81-1.23-.26 0-.53.04-.79.15L7.1 5.95c-.75.31-1.21 1.03-1.23 1.8-.01.27.04.54.15.8l4.96 11.97c.31.76 1.05 1.22 1.83 1.23.26 0 .52-.05.77-.15l7.36-3.05c1.02-.42 1.51-1.59 1.09-2.6zM7.88 8.75c-.55 0-1-.45-1-1s.45-1 1-1 1 .45 1 1-.45 1-1 1zm-2 11c0 1.1.9 2 2 2h1.45l-3.45-8.34v6.34z");
   var straighten = $Material$Icons$Internal.icon("M21 6H3c-1.1 0-2 .9-2 2v8c0 1.1.9 2 2 2h18c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2zm0 10H3V8h2v4h2V8h2v4h2V8h2v4h2V8h2v4h2V8h2v8z");
   var slideshow = $Material$Icons$Internal.icon("M10 8v8l5-4-5-4zm9-5H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V5h14v14z");
   var rotate_right = $Material$Icons$Internal.icon("M15.55 5.55L11 1v3.07C7.06 4.56 4 7.92 4 12s3.05 7.44 7 7.93v-2.02c-2.84-.48-5-2.94-5-5.91s2.16-5.43 5-5.91V10l4.55-4.45zM19.93 11c-.17-1.39-.72-2.73-1.62-3.89l-1.42 1.42c.54.75.88 1.6 1.02 2.47h2.02zM13 17.9v2.02c1.39-.17 2.74-.71 3.9-1.61l-1.44-1.44c-.75.54-1.59.89-2.46 1.03zm3.89-2.42l1.42 1.41c.9-1.16 1.45-2.5 1.62-3.89h-2.02c-.14.87-.48 1.72-1.02 2.48z");
   var rotate_left = $Material$Icons$Internal.icon("M7.11 8.53L5.7 7.11C4.8 8.27 4.24 9.61 4.07 11h2.02c.14-.87.49-1.72 1.02-2.47zM6.09 13H4.07c.17 1.39.72 2.73 1.62 3.89l1.41-1.42c-.52-.75-.87-1.59-1.01-2.47zm1.01 5.32c1.16.9 2.51 1.44 3.9 1.61V17.9c-.87-.15-1.71-.49-2.46-1.03L7.1 18.32zM13 4.07V1L8.45 5.55 13 10V6.09c2.84.48 5 2.94 5 5.91s-2.16 5.43-5 5.91v2.02c3.95-.49 7-3.85 7-7.93s-3.05-7.44-7-7.93z");
   var rotate_90_degrees_ccw = $Material$Icons$Internal.icon("M7.34 6.41L.86 12.9l6.49 6.48 6.49-6.48-6.5-6.49zM3.69 12.9l3.66-3.66L11 12.9l-3.66 3.66-3.65-3.66zm15.67-6.26C17.61 4.88 15.3 4 13 4V.76L8.76 5 13 9.24V6c1.79 0 3.58.68 4.95 2.05 2.73 2.73 2.73 7.17 0 9.9C16.58 19.32 14.79 20 13 20c-.97 0-1.94-.21-2.84-.61l-1.49 1.49C10.02 21.62 11.51 22 13 22c2.3 0 4.61-.88 6.36-2.64 3.52-3.51 3.52-9.21 0-12.72z");
   var remove_red_eye = $Material$Icons$Internal.icon("M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z");
   var portrait = $Material$Icons$Internal.icon("M12 12.25c1.24 0 2.25-1.01 2.25-2.25S13.24 7.75 12 7.75 9.75 8.76 9.75 10s1.01 2.25 2.25 2.25zm4.5 4c0-1.5-3-2.25-4.5-2.25s-4.5.75-4.5 2.25V17h9v-.75zM19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V5h14v14z");
   var picture_as_pdf = $Material$Icons$Internal.icon("M20 2H8c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-8.5 7.5c0 .83-.67 1.5-1.5 1.5H9v2H7.5V7H10c.83 0 1.5.67 1.5 1.5v1zm5 2c0 .83-.67 1.5-1.5 1.5h-2.5V7H15c.83 0 1.5.67 1.5 1.5v3zm4-3H19v1h1.5V11H19v2h-1.5V7h3v1.5zM9 9.5h1v-1H9v1zM4 6H2v14c0 1.1.9 2 2 2h14v-2H4V6zm10 5.5h1v-3h-1v3z");
   var photo_size_select_small = $Material$Icons$Internal.icon("M23 15h-2v2h2v-2zm0-4h-2v2h2v-2zm0 8h-2v2c1 0 2-1 2-2zM15 3h-2v2h2V3zm8 4h-2v2h2V7zm-2-4v2h2c0-1-1-2-2-2zM3 21h8v-6H1v4c0 1.1.9 2 2 2zM3 7H1v2h2V7zm12 12h-2v2h2v-2zm4-16h-2v2h2V3zm0 16h-2v2h2v-2zM3 3C2 3 1 4 1 5h2V3zm0 8H1v2h2v-2zm8-8H9v2h2V3zM7 3H5v2h2V3z");
   var photo_size_select_large = $Material$Icons$Internal.icon("M21 15h2v2h-2v-2zm0-4h2v2h-2v-2zm2 8h-2v2c1 0 2-1 2-2zM13 3h2v2h-2V3zm8 4h2v2h-2V7zm0-4v2h2c0-1-1-2-2-2zM1 7h2v2H1V7zm16-4h2v2h-2V3zm0 16h2v2h-2v-2zM3 3C2 3 1 4 1 5h2V3zm6 0h2v2H9V3zM5 3h2v2H5V3zm-4 8v8c0 1.1.9 2 2 2h12V11H1zm2 8l2.5-3.21 1.79 2.15 2.5-3.22L13 19H3z");
   var photo_size_select_actual = $Material$Icons$Internal.icon("M21 3H3C2 3 1 4 1 5v14c0 1.1.9 2 2 2h18c1 0 2-1 2-2V5c0-1-1-2-2-2zM5 17l3.5-4.5 2.5 3.01L14.5 11l4.5 6H5z");
   var photo_library = $Material$Icons$Internal.icon("M22 16V4c0-1.1-.9-2-2-2H8c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2zm-11-4l2.03 2.71L16 11l4 5H8l3-4zM2 6v14c0 1.1.9 2 2 2h14v-2H4V6H2z");
   var photo_camera = F2(function (color,size) {
      var stringSize = $Basics.toString(size);
      var stringColor = $Material$Icons$Internal.toRgbaString(color);
      return A2($Svg.svg,
      _U.list([$Svg$Attributes.width(stringSize)
              ,$Svg$Attributes.height(stringSize)
              ,$Svg$Attributes.viewBox("0 0 24 24")]),
      _U.list([A2($Svg.circle,
              _U.list([$Svg$Attributes.cx("12")
                      ,$Svg$Attributes.cy("12")
                      ,$Svg$Attributes.r("3.2")
                      ,$Svg$Attributes.fill(stringColor)]),
              _U.list([]))
              ,A2($Svg.path,
              _U.list([$Svg$Attributes.d("M9 2L7.17 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2h-3.17L15 2H9zm3 15c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5z")
                      ,$Svg$Attributes.fill(stringColor)]),
              _U.list([]))]));
   });
   var photo_album = $Material$Icons$Internal.icon("M18 2H6c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zM6 4h5v8l-2.5-1.5L6 12V4zm0 15l3-3.86 2.14 2.58 3-3.86L18 19H6z");
   var photo = $Material$Icons$Internal.icon("M21 19V5c0-1.1-.9-2-2-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2zM8.5 13.5l2.5 3.01L14.5 12l4.5 6H5l3.5-4.5z");
   var panorama_wide_angle = $Material$Icons$Internal.icon("M12 6c2.45 0 4.71.2 7.29.64.47 1.78.71 3.58.71 5.36 0 1.78-.24 3.58-.71 5.36-2.58.44-4.84.64-7.29.64s-4.71-.2-7.29-.64C4.24 15.58 4 13.78 4 12c0-1.78.24-3.58.71-5.36C7.29 6.2 9.55 6 12 6m0-2c-2.73 0-5.22.24-7.95.72l-.93.16-.25.9C2.29 7.85 2 9.93 2 12s.29 4.15.87 6.22l.25.89.93.16c2.73.49 5.22.73 7.95.73s5.22-.24 7.95-.72l.93-.16.25-.89c.58-2.08.87-4.16.87-6.23s-.29-4.15-.87-6.22l-.25-.89-.93-.16C17.22 4.24 14.73 4 12 4z");
   var panorama_vertical = $Material$Icons$Internal.icon("M19.94 21.12c-1.1-2.94-1.64-6.03-1.64-9.12 0-3.09.55-6.18 1.64-9.12.04-.11.06-.22.06-.31 0-.34-.23-.57-.63-.57H4.63c-.4 0-.63.23-.63.57 0 .1.02.2.06.31C5.16 5.82 5.71 8.91 5.71 12c0 3.09-.55 6.18-1.64 9.12-.05.11-.07.22-.07.31 0 .33.23.57.63.57h14.75c.39 0 .63-.24.63-.57-.01-.1-.03-.2-.07-.31zM6.54 20c.77-2.6 1.16-5.28 1.16-8 0-2.72-.39-5.4-1.16-8h10.91c-.77 2.6-1.16 5.28-1.16 8 0 2.72.39 5.4 1.16 8H6.54z");
   var panorama_horizontal = $Material$Icons$Internal.icon("M20 6.54v10.91c-2.6-.77-5.28-1.16-8-1.16-2.72 0-5.4.39-8 1.16V6.54c2.6.77 5.28 1.16 8 1.16 2.72.01 5.4-.38 8-1.16M21.43 4c-.1 0-.2.02-.31.06C18.18 5.16 15.09 5.7 12 5.7c-3.09 0-6.18-.55-9.12-1.64-.11-.04-.22-.06-.31-.06-.34 0-.57.23-.57.63v14.75c0 .39.23.62.57.62.1 0 .2-.02.31-.06 2.94-1.1 6.03-1.64 9.12-1.64 3.09 0 6.18.55 9.12 1.64.11.04.21.06.31.06.33 0 .57-.23.57-.63V4.63c0-.4-.24-.63-.57-.63z");
   var panorama_fish_eye = $Material$Icons$Internal.icon("M12 2C6.47 2 2 6.47 2 12s4.47 10 10 10 10-4.47 10-10S17.53 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z");
   var panorama = $Material$Icons$Internal.icon("M23 18V6c0-1.1-.9-2-2-2H3c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h18c1.1 0 2-.9 2-2zM8.5 12.5l2.5 3.01L14.5 11l4.5 6H5l3.5-4.5z");
   var palette = $Material$Icons$Internal.icon("M12 3c-4.97 0-9 4.03-9 9s4.03 9 9 9c.83 0 1.5-.67 1.5-1.5 0-.39-.15-.74-.39-1.01-.23-.26-.38-.61-.38-.99 0-.83.67-1.5 1.5-1.5H16c2.76 0 5-2.24 5-5 0-4.42-4.03-8-9-8zm-5.5 9c-.83 0-1.5-.67-1.5-1.5S5.67 9 6.5 9 8 9.67 8 10.5 7.33 12 6.5 12zm3-4C8.67 8 8 7.33 8 6.5S8.67 5 9.5 5s1.5.67 1.5 1.5S10.33 8 9.5 8zm5 0c-.83 0-1.5-.67-1.5-1.5S13.67 5 14.5 5s1.5.67 1.5 1.5S15.33 8 14.5 8zm3 4c-.83 0-1.5-.67-1.5-1.5S16.67 9 17.5 9s1.5.67 1.5 1.5-.67 1.5-1.5 1.5z");
   var navigate_next = $Material$Icons$Internal.icon("M10 6L8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z");
   var navigate_before = $Material$Icons$Internal.icon("M15.41 7.41L14 6l-6 6 6 6 1.41-1.41L10.83 12z");
   var nature_people = $Material$Icons$Internal.icon("M22.17 9.17c0-3.87-3.13-7-7-7s-7 3.13-7 7c0 3.47 2.52 6.34 5.83 6.89V20H6v-3h1v-4c0-.55-.45-1-1-1H3c-.55 0-1 .45-1 1v4h1v5h16v-2h-3v-3.88c3.47-.41 6.17-3.36 6.17-6.95zM4.5 11c.83 0 1.5-.67 1.5-1.5S5.33 8 4.5 8 3 8.67 3 9.5 3.67 11 4.5 11z");
   var nature = $Material$Icons$Internal.icon("M13 16.12c3.47-.41 6.17-3.36 6.17-6.95 0-3.87-3.13-7-7-7s-7 3.13-7 7c0 3.47 2.52 6.34 5.83 6.89V20H5v2h14v-2h-6v-3.88z");
   var music_note = $Material$Icons$Internal.icon("M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z");
   var movie_creation = $Material$Icons$Internal.icon("M18 4l2 4h-3l-2-4h-2l2 4h-3l-2-4H8l2 4H7L5 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V4h-4z");
   var monochrome_photos = $Material$Icons$Internal.icon("M20 5h-3.2L15 3H9L7.2 5H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V7c0-1.1-.9-2-2-2zm0 14h-8v-1c-2.8 0-5-2.2-5-5s2.2-5 5-5V7h8v12zm-3-6c0-2.8-2.2-5-5-5v1.8c1.8 0 3.2 1.4 3.2 3.2s-1.4 3.2-3.2 3.2V18c2.8 0 5-2.2 5-5zm-8.2 0c0 1.8 1.4 3.2 3.2 3.2V9.8c-1.8 0-3.2 1.4-3.2 3.2z");
   var loupe = $Material$Icons$Internal.icon("M13 7h-2v4H7v2h4v4h2v-4h4v-2h-4V7zm-1-5C6.49 2 2 6.49 2 12s4.49 10 10 10h8c1.1 0 2-.9 2-2v-8c0-5.51-4.49-10-10-10zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z");
   var looks_two = $Material$Icons$Internal.icon("M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-4 8c0 1.11-.9 2-2 2h-2v2h4v2H9v-4c0-1.11.9-2 2-2h2V9H9V7h4c1.1 0 2 .89 2 2v2z");
   var looks_one = $Material$Icons$Internal.icon("M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-5 14h-2V9h-2V7h4v10z");
   var looks_6 = $Material$Icons$Internal.icon("M11 15h2v-2h-2v2zm8-12H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-4 6h-4v2h2c1.1 0 2 .89 2 2v2c0 1.11-.9 2-2 2h-2c-1.1 0-2-.89-2-2V9c0-1.11.9-2 2-2h4v2z");
   var looks_5 = $Material$Icons$Internal.icon("M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-4 6h-4v2h2c1.1 0 2 .89 2 2v2c0 1.11-.9 2-2 2H9v-2h4v-2H9V7h6v2z");
   var looks_4 = $Material$Icons$Internal.icon("M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-4 14h-2v-4H9V7h2v4h2V7h2v10z");
   var looks_3 = $Material$Icons$Internal.icon("M19.01 3h-14c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-4 7.5c0 .83-.67 1.5-1.5 1.5.83 0 1.5.67 1.5 1.5V15c0 1.11-.9 2-2 2h-4v-2h4v-2h-2v-2h2V9h-4V7h4c1.1 0 2 .89 2 2v1.5z");
   var looks = $Material$Icons$Internal.icon("M12 10c-3.86 0-7 3.14-7 7h2c0-2.76 2.24-5 5-5s5 2.24 5 5h2c0-3.86-3.14-7-7-7zm0-4C5.93 6 1 10.93 1 17h2c0-4.96 4.04-9 9-9s9 4.04 9 9h2c0-6.07-4.93-11-11-11z");
   var lens = $Material$Icons$Internal.icon("M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2z");
   var leak_remove = $Material$Icons$Internal.icon("M10 3H8c0 .37-.04.72-.12 1.06l1.59 1.59C9.81 4.84 10 3.94 10 3zM3 4.27l2.84 2.84C5.03 7.67 4.06 8 3 8v2c1.61 0 3.09-.55 4.27-1.46L8.7 9.97C7.14 11.24 5.16 12 3 12v2c2.71 0 5.19-.99 7.11-2.62l2.5 2.5C10.99 15.81 10 18.29 10 21h2c0-2.16.76-4.14 2.03-5.69l1.43 1.43C14.55 17.91 14 19.39 14 21h2c0-1.06.33-2.03.89-2.84L19.73 21 21 19.73 4.27 3 3 4.27zM14 3h-2c0 1.5-.37 2.91-1.02 4.16l1.46 1.46C13.42 6.98 14 5.06 14 3zm5.94 13.12c.34-.08.69-.12 1.06-.12v-2c-.94 0-1.84.19-2.66.52l1.6 1.6zm-4.56-4.56l1.46 1.46C18.09 12.37 19.5 12 21 12v-2c-2.06 0-3.98.58-5.62 1.56z");
   var leak_add = $Material$Icons$Internal.icon("M6 3H3v3c1.66 0 3-1.34 3-3zm8 0h-2c0 4.97-4.03 9-9 9v2c6.08 0 11-4.93 11-11zm-4 0H8c0 2.76-2.24 5-5 5v2c3.87 0 7-3.13 7-7zm0 18h2c0-4.97 4.03-9 9-9v-2c-6.07 0-11 4.93-11 11zm8 0h3v-3c-1.66 0-3 1.34-3 3zm-4 0h2c0-2.76 2.24-5 5-5v-2c-3.87 0-7 3.13-7 7z");
   var landscape = $Material$Icons$Internal.icon("M14 6l-3.75 5 2.85 3.8-1.6 1.2C9.81 13.75 7 10 7 10l-6 8h22L14 6z");
   var iso = $Material$Icons$Internal.icon("M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zM5.5 7.5h2v-2H9v2h2V9H9v2H7.5V9h-2V7.5zM19 19H5L19 5v14zm-2-2v-1.5h-5V17h5z");
   var image_aspect_ratio = $Material$Icons$Internal.icon("M16 10h-2v2h2v-2zm0 4h-2v2h2v-2zm-8-4H6v2h2v-2zm4 0h-2v2h2v-2zm8-6H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 14H4V6h16v12z");
   var image = $Material$Icons$Internal.icon("M21 19V5c0-1.1-.9-2-2-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2zM8.5 13.5l2.5 3.01L14.5 12l4.5 6H5l3.5-4.5z");
   var healing = $Material$Icons$Internal.icon("M17.73 12.02l3.98-3.98c.39-.39.39-1.02 0-1.41l-4.34-4.34c-.39-.39-1.02-.39-1.41 0l-3.98 3.98L8 2.29C7.8 2.1 7.55 2 7.29 2c-.25 0-.51.1-.7.29L2.25 6.63c-.39.39-.39 1.02 0 1.41l3.98 3.98L2.25 16c-.39.39-.39 1.02 0 1.41l4.34 4.34c.39.39 1.02.39 1.41 0l3.98-3.98 3.98 3.98c.2.2.45.29.71.29.26 0 .51-.1.71-.29l4.34-4.34c.39-.39.39-1.02 0-1.41l-3.99-3.98zM12 9c.55 0 1 .45 1 1s-.45 1-1 1-1-.45-1-1 .45-1 1-1zm-4.71 1.96L3.66 7.34l3.63-3.63 3.62 3.62-3.62 3.63zM10 13c-.55 0-1-.45-1-1s.45-1 1-1 1 .45 1 1-.45 1-1 1zm2 2c-.55 0-1-.45-1-1s.45-1 1-1 1 .45 1 1-.45 1-1 1zm2-4c.55 0 1 .45 1 1s-.45 1-1 1-1-.45-1-1 .45-1 1-1zm2.66 9.34l-3.63-3.62 3.63-3.63 3.62 3.62-3.62 3.63z");
   var hdr_weak = $Material$Icons$Internal.icon("M5 8c-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4-1.79-4-4-4zm12-2c-3.31 0-6 2.69-6 6s2.69 6 6 6 6-2.69 6-6-2.69-6-6-6zm0 10c-2.21 0-4-1.79-4-4s1.79-4 4-4 4 1.79 4 4-1.79 4-4 4z");
   var hdr_strong = $Material$Icons$Internal.icon("M17 6c-3.31 0-6 2.69-6 6s2.69 6 6 6 6-2.69 6-6-2.69-6-6-6zM5 8c-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4-1.79-4-4-4zm0 6c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2z");
   var hdr_on = $Material$Icons$Internal.icon("M21 11.5v-1c0-.8-.7-1.5-1.5-1.5H16v6h1.5v-2h1.1l.9 2H21l-.9-2.1c.5-.3.9-.8.9-1.4zm-1.5 0h-2v-1h2v1zm-13-.5h-2V9H3v6h1.5v-2.5h2V15H8V9H6.5v2zM13 9H9.5v6H13c.8 0 1.5-.7 1.5-1.5v-3c0-.8-.7-1.5-1.5-1.5zm0 4.5h-2v-3h2v3z");
   var hdr_off = $Material$Icons$Internal.icon("M17.5 15v-2h1.1l.9 2H21l-.9-2.1c.5-.2.9-.8.9-1.4v-1c0-.8-.7-1.5-1.5-1.5H16v4.9l1.1 1.1h.4zm0-4.5h2v1h-2v-1zm-4.5 0v.4l1.5 1.5v-1.9c0-.8-.7-1.5-1.5-1.5h-1.9l1.5 1.5h.4zm-3.5-1l-7-7-1.1 1L6.9 9h-.4v2h-2V9H3v6h1.5v-2.5h2V15H8v-4.9l1.5 1.5V15h3.4l7.6 7.6 1.1-1.1-12.1-12z");
   var grid_on = $Material$Icons$Internal.icon("M20 2H4c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zM8 20H4v-4h4v4zm0-6H4v-4h4v4zm0-6H4V4h4v4zm6 12h-4v-4h4v4zm0-6h-4v-4h4v4zm0-6h-4V4h4v4zm6 12h-4v-4h4v4zm0-6h-4v-4h4v4zm0-6h-4V4h4v4z");
   var grid_off = $Material$Icons$Internal.icon("M8 4v1.45l2 2V4h4v4h-3.45l2 2H14v1.45l2 2V10h4v4h-3.45l2 2H20v1.45l2 2V4c0-1.1-.9-2-2-2H4.55l2 2H8zm8 0h4v4h-4V4zM1.27 1.27L0 2.55l2 2V20c0 1.1.9 2 2 2h15.46l2 2 1.27-1.27L1.27 1.27zM10 12.55L11.45 14H10v-1.45zm-6-6L5.45 8H4V6.55zM8 20H4v-4h4v4zm0-6H4v-4h3.45l.55.55V14zm6 6h-4v-4h3.45l.55.54V20zm2 0v-1.46L17.46 20H16z");
   var grain = $Material$Icons$Internal.icon("M10 12c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zM6 8c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 8c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm12-8c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm-4 8c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm4-4c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm-4-4c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm-4-4c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z");
   var gradient = $Material$Icons$Internal.icon("M11 9h2v2h-2zm-2 2h2v2H9zm4 0h2v2h-2zm2-2h2v2h-2zM7 9h2v2H7zm12-6H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zM9 18H7v-2h2v2zm4 0h-2v-2h2v2zm4 0h-2v-2h2v2zm2-7h-2v2h2v2h-2v-2h-2v2h-2v-2h-2v2H9v-2H7v2H5v-2h2v-2H5V5h14v6z");
   var flip = $Material$Icons$Internal.icon("M15 21h2v-2h-2v2zm4-12h2V7h-2v2zM3 5v14c0 1.1.9 2 2 2h4v-2H5V5h4V3H5c-1.1 0-2 .9-2 2zm16-2v2h2c0-1.1-.9-2-2-2zm-8 20h2V1h-2v22zm8-6h2v-2h-2v2zM15 5h2V3h-2v2zm4 8h2v-2h-2v2zm0 8c1.1 0 2-.9 2-2h-2v2z");
   var flash_on = $Material$Icons$Internal.icon("M7 2v11h3v9l7-12h-4l4-8z");
   var flash_off = $Material$Icons$Internal.icon("M3.27 3L2 4.27l5 5V13h3v9l3.58-6.14L17.73 20 19 18.73 3.27 3zM17 10h-4l4-8H7v2.18l8.46 8.46L17 10z");
   var flash_auto = $Material$Icons$Internal.icon("M3 2v12h3v9l7-12H9l4-9H3zm16 0h-2l-3.2 9h1.9l.7-2h3.2l.7 2h1.9L19 2zm-2.15 5.65L18 4l1.15 3.65h-2.3z");
   var flare = $Material$Icons$Internal.icon("M7 11H1v2h6v-2zm2.17-3.24L7.05 5.64 5.64 7.05l2.12 2.12 1.41-1.41zM13 1h-2v6h2V1zm5.36 6.05l-1.41-1.41-2.12 2.12 1.41 1.41 2.12-2.12zM17 11v2h6v-2h-6zm-5-2c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3zm2.83 7.24l2.12 2.12 1.41-1.41-2.12-2.12-1.41 1.41zm-9.19.71l1.41 1.41 2.12-2.12-1.41-1.41-2.12 2.12zM11 23h2v-6h-2v6z");
   var filter_vintage = $Material$Icons$Internal.icon("M18.7 12.4c-.28-.16-.57-.29-.86-.4.29-.11.58-.24.86-.4 1.92-1.11 2.99-3.12 3-5.19-1.79-1.03-4.07-1.11-6 0-.28.16-.54.35-.78.54.05-.31.08-.63.08-.95 0-2.22-1.21-4.15-3-5.19C10.21 1.85 9 3.78 9 6c0 .32.03.64.08.95-.24-.2-.5-.39-.78-.55-1.92-1.11-4.2-1.03-6 0 0 2.07 1.07 4.08 3 5.19.28.16.57.29.86.4-.29.11-.58.24-.86.4-1.92 1.11-2.99 3.12-3 5.19 1.79 1.03 4.07 1.11 6 0 .28-.16.54-.35.78-.54-.05.32-.08.64-.08.96 0 2.22 1.21 4.15 3 5.19 1.79-1.04 3-2.97 3-5.19 0-.32-.03-.64-.08-.95.24.2.5.38.78.54 1.92 1.11 4.2 1.03 6 0-.01-2.07-1.08-4.08-3-5.19zM12 16c-2.21 0-4-1.79-4-4s1.79-4 4-4 4 1.79 4 4-1.79 4-4 4z");
   var filter_tilt_shift = $Material$Icons$Internal.icon("M11 4.07V2.05c-2.01.2-3.84 1-5.32 2.21L7.1 5.69c1.11-.86 2.44-1.44 3.9-1.62zm7.32.19C16.84 3.05 15.01 2.25 13 2.05v2.02c1.46.18 2.79.76 3.9 1.62l1.42-1.43zM19.93 11h2.02c-.2-2.01-1-3.84-2.21-5.32L18.31 7.1c.86 1.11 1.44 2.44 1.62 3.9zM5.69 7.1L4.26 5.68C3.05 7.16 2.25 8.99 2.05 11h2.02c.18-1.46.76-2.79 1.62-3.9zM4.07 13H2.05c.2 2.01 1 3.84 2.21 5.32l1.43-1.43c-.86-1.1-1.44-2.43-1.62-3.89zM15 12c0-1.66-1.34-3-3-3s-3 1.34-3 3 1.34 3 3 3 3-1.34 3-3zm3.31 4.9l1.43 1.43c1.21-1.48 2.01-3.32 2.21-5.32h-2.02c-.18 1.45-.76 2.78-1.62 3.89zM13 19.93v2.02c2.01-.2 3.84-1 5.32-2.21l-1.43-1.43c-1.1.86-2.43 1.44-3.89 1.62zm-7.32-.19C7.16 20.95 9 21.75 11 21.95v-2.02c-1.46-.18-2.79-.76-3.9-1.62l-1.42 1.43z");
   var filter_none = $Material$Icons$Internal.icon("M3 5H1v16c0 1.1.9 2 2 2h16v-2H3V5zm18-4H7c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V3c0-1.1-.9-2-2-2zm0 16H7V3h14v14z");
   var filter_hdr = $Material$Icons$Internal.icon("M14 6l-3.75 5 2.85 3.8-1.6 1.2C9.81 13.75 7 10 7 10l-6 8h22L14 6z");
   var filter_frames = $Material$Icons$Internal.icon("M20 4h-4l-4-4-4 4H4c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 16H4V6h4.52l3.52-3.5L15.52 6H20v14zM18 8H6v10h12");
   var filter_drama = $Material$Icons$Internal.icon("M19.35 10.04C18.67 6.59 15.64 4 12 4 9.11 4 6.61 5.64 5.36 8.04 2.35 8.36 0 10.9 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.65-4.96zM19 18H6c-2.21 0-4-1.79-4-4s1.79-4 4-4 4 1.79 4 4h2c0-2.76-1.86-5.08-4.4-5.78C8.61 6.88 10.2 6 12 6c3.03 0 5.5 2.47 5.5 5.5v.5H19c1.65 0 3 1.35 3 3s-1.35 3-3 3z");
   var filter_center_focus = $Material$Icons$Internal.icon("M5 15H3v4c0 1.1.9 2 2 2h4v-2H5v-4zM5 5h4V3H5c-1.1 0-2 .9-2 2v4h2V5zm14-2h-4v2h4v4h2V5c0-1.1-.9-2-2-2zm0 16h-4v2h4c1.1 0 2-.9 2-2v-4h-2v4zM12 9c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z");
   var filter_b_and_w = $Material$Icons$Internal.icon("M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16l-7-8v8H5l7-8V5h7v14z");
   var filter_9_plus = $Material$Icons$Internal.icon("M3 5H1v16c0 1.1.9 2 2 2h16v-2H3V5zm11 7V8c0-1.11-.9-2-2-2h-1c-1.1 0-2 .89-2 2v1c0 1.11.9 2 2 2h1v1H9v2h3c1.1 0 2-.89 2-2zm-3-3V8h1v1h-1zm10-8H7c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V3c0-1.1-.9-2-2-2zm0 8h-2V7h-2v2h-2v2h2v2h2v-2h2v6H7V3h14v6z");
   var filter_9 = $Material$Icons$Internal.icon("M3 5H1v16c0 1.1.9 2 2 2h16v-2H3V5zm18-4H7c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V3c0-1.1-.9-2-2-2zm0 16H7V3h14v14zM15 5h-2c-1.1 0-2 .89-2 2v2c0 1.11.9 2 2 2h2v2h-4v2h4c1.1 0 2-.89 2-2V7c0-1.11-.9-2-2-2zm0 4h-2V7h2v2z");
   var filter_8 = $Material$Icons$Internal.icon("M3 5H1v16c0 1.1.9 2 2 2h16v-2H3V5zm18-4H7c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V3c0-1.1-.9-2-2-2zm0 16H7V3h14v14zm-8-2h2c1.1 0 2-.89 2-2v-1.5c0-.83-.67-1.5-1.5-1.5.83 0 1.5-.67 1.5-1.5V7c0-1.11-.9-2-2-2h-2c-1.1 0-2 .89-2 2v1.5c0 .83.67 1.5 1.5 1.5-.83 0-1.5.67-1.5 1.5V13c0 1.11.9 2 2 2zm0-8h2v2h-2V7zm0 4h2v2h-2v-2z");
   var filter_7 = $Material$Icons$Internal.icon("M3 5H1v16c0 1.1.9 2 2 2h16v-2H3V5zm18-4H7c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V3c0-1.1-.9-2-2-2zm0 16H7V3h14v14zm-8-2l4-8V5h-6v2h4l-4 8h2z");
   var filter_6 = $Material$Icons$Internal.icon("M3 5H1v16c0 1.1.9 2 2 2h16v-2H3V5zm18-4H7c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V3c0-1.1-.9-2-2-2zm0 16H7V3h14v14zm-8-2h2c1.1 0 2-.89 2-2v-2c0-1.11-.9-2-2-2h-2V7h4V5h-4c-1.1 0-2 .89-2 2v6c0 1.11.9 2 2 2zm0-4h2v2h-2v-2z");
   var filter_5 = $Material$Icons$Internal.icon("M21 1H7c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V3c0-1.1-.9-2-2-2zm0 16H7V3h14v14zM3 5H1v16c0 1.1.9 2 2 2h16v-2H3V5zm14 8v-2c0-1.11-.9-2-2-2h-2V7h4V5h-6v6h4v2h-4v2h4c1.1 0 2-.89 2-2z");
   var filter_4 = $Material$Icons$Internal.icon("M3 5H1v16c0 1.1.9 2 2 2h16v-2H3V5zm12 10h2V5h-2v4h-2V5h-2v6h4v4zm6-14H7c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V3c0-1.1-.9-2-2-2zm0 16H7V3h14v14z");
   var filter_3 = $Material$Icons$Internal.icon("M21 1H7c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V3c0-1.1-.9-2-2-2zm0 16H7V3h14v14zM3 5H1v16c0 1.1.9 2 2 2h16v-2H3V5zm14 8v-1.5c0-.83-.67-1.5-1.5-1.5.83 0 1.5-.67 1.5-1.5V7c0-1.11-.9-2-2-2h-4v2h4v2h-2v2h2v2h-4v2h4c1.1 0 2-.89 2-2z");
   var filter_2 = $Material$Icons$Internal.icon("M3 5H1v16c0 1.1.9 2 2 2h16v-2H3V5zm18-4H7c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V3c0-1.1-.9-2-2-2zm0 16H7V3h14v14zm-4-4h-4v-2h2c1.1 0 2-.89 2-2V7c0-1.11-.9-2-2-2h-4v2h4v2h-2c-1.1 0-2 .89-2 2v4h6v-2z");
   var filter_1 = $Material$Icons$Internal.icon("M3 5H1v16c0 1.1.9 2 2 2h16v-2H3V5zm11 10h2V5h-4v2h2v8zm7-14H7c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V3c0-1.1-.9-2-2-2zm0 16H7V3h14v14z");
   var filter = $Material$Icons$Internal.icon("M15.96 10.29l-2.75 3.54-1.96-2.36L8.5 15h11l-3.54-4.71zM3 5H1v16c0 1.1.9 2 2 2h16v-2H3V5zm18-4H7c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V3c0-1.1-.9-2-2-2zm0 16H7V3h14v14z");
   var exposure_zero = $Material$Icons$Internal.icon("M16.14 12.5c0 1-.1 1.85-.3 2.55-.2.7-.48 1.27-.83 1.7-.36.44-.79.75-1.3.95-.51.2-1.07.3-1.7.3-.62 0-1.18-.1-1.69-.3-.51-.2-.95-.51-1.31-.95-.36-.44-.65-1.01-.85-1.7-.2-.7-.3-1.55-.3-2.55v-2.04c0-1 .1-1.85.3-2.55.2-.7.48-1.26.84-1.69.36-.43.8-.74 1.31-.93C10.81 5.1 11.38 5 12 5c.63 0 1.19.1 1.7.29.51.19.95.5 1.31.93.36.43.64.99.84 1.69.2.7.3 1.54.3 2.55v2.04zm-2.11-2.36c0-.64-.05-1.18-.13-1.62-.09-.44-.22-.79-.4-1.06-.17-.27-.39-.46-.64-.58-.25-.13-.54-.19-.86-.19-.32 0-.61.06-.86.18s-.47.31-.64.58c-.17.27-.31.62-.4 1.06s-.13.98-.13 1.62v2.67c0 .64.05 1.18.14 1.62.09.45.23.81.4 1.09s.39.48.64.61.54.19.87.19c.33 0 .62-.06.87-.19s.46-.33.63-.61c.17-.28.3-.64.39-1.09.09-.45.13-.99.13-1.62v-2.66z");
   var exposure_plus_2 = $Material$Icons$Internal.icon("M16.05 16.29l2.86-3.07c.38-.39.72-.79 1.04-1.18.32-.39.59-.78.82-1.17.23-.39.41-.78.54-1.17.13-.39.19-.79.19-1.18 0-.53-.09-1.02-.27-1.46-.18-.44-.44-.81-.78-1.11-.34-.31-.77-.54-1.26-.71-.51-.16-1.08-.24-1.72-.24-.69 0-1.31.11-1.85.32-.54.21-1 .51-1.36.88-.37.37-.65.8-.84 1.3-.18.47-.27.97-.28 1.5h2.14c.01-.31.05-.6.13-.87.09-.29.23-.54.4-.75.18-.21.41-.37.68-.49.27-.12.6-.18.96-.18.31 0 .58.05.81.15.23.1.43.25.59.43.16.18.28.4.37.65.08.25.13.52.13.81 0 .22-.03.43-.08.65-.06.22-.15.45-.29.7-.14.25-.32.53-.56.83-.23.3-.52.65-.88 1.03l-4.17 4.55V18H22v-1.71h-5.95zM8 7H6v4H2v2h4v4h2v-4h4v-2H8V7z");
   var exposure_plus_1 = $Material$Icons$Internal.icon("M10 7H8v4H4v2h4v4h2v-4h4v-2h-4V7zm10 11h-2V7.38L15 8.4V6.7L19.7 5h.3v13z");
   var exposure_neg_2 = $Material$Icons$Internal.icon("M15.05 16.29l2.86-3.07c.38-.39.72-.79 1.04-1.18.32-.39.59-.78.82-1.17.23-.39.41-.78.54-1.17s.19-.79.19-1.18c0-.53-.09-1.02-.27-1.46-.18-.44-.44-.81-.78-1.11-.34-.31-.77-.54-1.26-.71-.51-.16-1.08-.24-1.72-.24-.69 0-1.31.11-1.85.32-.54.21-1 .51-1.36.88-.37.37-.65.8-.84 1.3-.18.47-.27.97-.28 1.5h2.14c.01-.31.05-.6.13-.87.09-.29.23-.54.4-.75.18-.21.41-.37.68-.49.27-.12.6-.18.96-.18.31 0 .58.05.81.15.23.1.43.25.59.43.16.18.28.4.37.65.08.25.13.52.13.81 0 .22-.03.43-.08.65-.06.22-.15.45-.29.7-.14.25-.32.53-.56.83-.23.3-.52.65-.88 1.03l-4.17 4.55V18H21v-1.71h-5.95zM2 11v2h8v-2H2z");
   var exposure_neg_1 = $Material$Icons$Internal.icon("M4 11v2h8v-2H4zm15 7h-2V7.38L14 8.4V6.7L18.7 5h.3v13z");
   var exposure = $Material$Icons$Internal.icon("M15 17v2h2v-2h2v-2h-2v-2h-2v2h-2v2h2zm5-15H4c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zM5 5h6v2H5V5zm15 15H4L20 4v16z");
   var edit = $Material$Icons$Internal.icon("M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34c-.39-.39-1.02-.39-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z");
   var details = $Material$Icons$Internal.icon("M3 4l9 16 9-16H3zm3.38 2h11.25L12 16 6.38 6z");
   var dehaze = $Material$Icons$Internal.icon("M2 15.5v2h20v-2H2zm0-5v2h20v-2H2zm0-5v2h20v-2H2z");
   var crop_square = $Material$Icons$Internal.icon("M18 4H6c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 14H6V6h12v12z");
   var crop_portrait = $Material$Icons$Internal.icon("M17 3H7c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h10c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H7V5h10v14z");
   var crop_original = $Material$Icons$Internal.icon("M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V5h14v14zm-5.04-6.71l-2.75 3.54-1.96-2.36L6.5 17h11l-3.54-4.71z");
   var crop_landscape = $Material$Icons$Internal.icon("M19 5H5c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V7c0-1.1-.9-2-2-2zm0 12H5V7h14v10z");
   var crop_free = $Material$Icons$Internal.icon("M3 5v4h2V5h4V3H5c-1.1 0-2 .9-2 2zm2 10H3v4c0 1.1.9 2 2 2h4v-2H5v-4zm14 4h-4v2h4c1.1 0 2-.9 2-2v-4h-2v4zm0-16h-4v2h4v4h2V5c0-1.1-.9-2-2-2z");
   var crop_din = $Material$Icons$Internal.icon("M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V5h14v14z");
   var crop_7_5 = $Material$Icons$Internal.icon("M19 7H5c-1.1 0-2 .9-2 2v6c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V9c0-1.1-.9-2-2-2zm0 8H5V9h14v6z");
   var crop_5_4 = $Material$Icons$Internal.icon("M19 5H5c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V7c0-1.1-.9-2-2-2zm0 12H5V7h14v10z");
   var crop_3_2 = $Material$Icons$Internal.icon("M19 4H5c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 14H5V6h14v12z");
   var crop = $Material$Icons$Internal.icon("M17 15h2V7c0-1.1-.9-2-2-2H9v2h8v8zM7 17V1H5v4H1v2h4v10c0 1.1.9 2 2 2h10v4h2v-4h4v-2H7z");
   var crop_16_9 = $Material$Icons$Internal.icon("M19 6H5c-1.1 0-2 .9-2 2v8c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2zm0 10H5V8h14v8z");
   var control_point_duplicate = $Material$Icons$Internal.icon("M16 8h-2v3h-3v2h3v3h2v-3h3v-2h-3zM2 12c0-2.79 1.64-5.2 4.01-6.32V3.52C2.52 4.76 0 8.09 0 12s2.52 7.24 6.01 8.48v-2.16C3.64 17.2 2 14.79 2 12zm13-9c-4.96 0-9 4.04-9 9s4.04 9 9 9 9-4.04 9-9-4.04-9-9-9zm0 16c-3.86 0-7-3.14-7-7s3.14-7 7-7 7 3.14 7 7-3.14 7-7 7z");
   var control_point = $Material$Icons$Internal.icon("M13 7h-2v4H7v2h4v4h2v-4h4v-2h-4V7zm-1-5C6.49 2 2 6.49 2 12s4.49 10 10 10 10-4.49 10-10S17.51 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z");
   var compare = $Material$Icons$Internal.icon("M10 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h5v2h2V1h-2v2zm0 15H5l5-6v6zm9-15h-5v2h5v13l-5-6v9h5c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2z");
   var colorize = $Material$Icons$Internal.icon("M20.71 5.63l-2.34-2.34c-.39-.39-1.02-.39-1.41 0l-3.12 3.12-1.93-1.91-1.41 1.41 1.42 1.42L3 16.25V21h4.75l8.92-8.92 1.42 1.42 1.41-1.41-1.92-1.92 3.12-3.12c.4-.4.4-1.03.01-1.42zM6.92 19L5 17.08l8.06-8.06 1.92 1.92L6.92 19z");
   var color_lens = $Material$Icons$Internal.icon("M12 3c-4.97 0-9 4.03-9 9s4.03 9 9 9c.83 0 1.5-.67 1.5-1.5 0-.39-.15-.74-.39-1.01-.23-.26-.38-.61-.38-.99 0-.83.67-1.5 1.5-1.5H16c2.76 0 5-2.24 5-5 0-4.42-4.03-8-9-8zm-5.5 9c-.83 0-1.5-.67-1.5-1.5S5.67 9 6.5 9 8 9.67 8 10.5 7.33 12 6.5 12zm3-4C8.67 8 8 7.33 8 6.5S8.67 5 9.5 5s1.5.67 1.5 1.5S10.33 8 9.5 8zm5 0c-.83 0-1.5-.67-1.5-1.5S13.67 5 14.5 5s1.5.67 1.5 1.5S15.33 8 14.5 8zm3 4c-.83 0-1.5-.67-1.5-1.5S16.67 9 17.5 9s1.5.67 1.5 1.5-.67 1.5-1.5 1.5z");
   var collections_bookmark = $Material$Icons$Internal.icon("M4 6H2v14c0 1.1.9 2 2 2h14v-2H4V6zM20 2H8c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm0 10l-2.5-1.5L15 12V4h5v8z");
   var collections = $Material$Icons$Internal.icon("M22 16V4c0-1.1-.9-2-2-2H8c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2zm-11-4l2.03 2.71L16 11l4 5H8l3-4zM2 6v14c0 1.1.9 2 2 2h14v-2H4V6H2z");
   var center_focus_weak = $Material$Icons$Internal.icon("M5 15H3v4c0 1.1.9 2 2 2h4v-2H5v-4zM5 5h4V3H5c-1.1 0-2 .9-2 2v4h2V5zm14-2h-4v2h4v4h2V5c0-1.1-.9-2-2-2zm0 16h-4v2h4c1.1 0 2-.9 2-2v-4h-2v4zM12 8c-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4-1.79-4-4-4zm0 6c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2z");
   var center_focus_strong = $Material$Icons$Internal.icon("M12 8c-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4-1.79-4-4-4zm-7 7H3v4c0 1.1.9 2 2 2h4v-2H5v-4zM5 5h4V3H5c-1.1 0-2 .9-2 2v4h2V5zm14-2h-4v2h4v4h2V5c0-1.1-.9-2-2-2zm0 16h-4v2h4c1.1 0 2-.9 2-2v-4h-2v4z");
   var camera_roll = $Material$Icons$Internal.icon("M14 5c0-1.1-.9-2-2-2h-1V2c0-.55-.45-1-1-1H6c-.55 0-1 .45-1 1v1H4c-1.1 0-2 .9-2 2v15c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2h8V5h-8zm-2 13h-2v-2h2v2zm0-9h-2V7h2v2zm4 9h-2v-2h2v2zm0-9h-2V7h2v2zm4 9h-2v-2h2v2zm0-9h-2V7h2v2z");
   var camera_rear = $Material$Icons$Internal.icon("M10 20H5v2h5v2l3-3-3-3v2zm4 0v2h5v-2h-5zm3-20H7C5.9 0 5 .9 5 2v14c0 1.1.9 2 2 2h10c1.1 0 2-.9 2-2V2c0-1.1-.9-2-2-2zm-5 6c-1.11 0-2-.9-2-2s.89-2 1.99-2 2 .9 2 2C14 5.1 13.1 6 12 6z");
   var camera_front = $Material$Icons$Internal.icon("M10 20H5v2h5v2l3-3-3-3v2zm4 0v2h5v-2h-5zM12 8c1.1 0 2-.9 2-2s-.9-2-2-2-1.99.9-1.99 2S10.9 8 12 8zm5-8H7C5.9 0 5 .9 5 2v14c0 1.1.9 2 2 2h10c1.1 0 2-.9 2-2V2c0-1.1-.9-2-2-2zM7 2h10v10.5c0-1.67-3.33-2.5-5-2.5s-5 .83-5 2.5V2z");
   var camera_alt = F2(function (color,size) {
      var stringSize = $Basics.toString(size);
      var stringColor = $Material$Icons$Internal.toRgbaString(color);
      return A2($Svg.svg,
      _U.list([$Svg$Attributes.width(stringSize)
              ,$Svg$Attributes.height(stringSize)
              ,$Svg$Attributes.viewBox("0 0 24 24")]),
      _U.list([A2($Svg.circle,
              _U.list([$Svg$Attributes.cx("12")
                      ,$Svg$Attributes.cy("12")
                      ,$Svg$Attributes.r("3.5")
                      ,$Svg$Attributes.fill(stringColor)]),
              _U.list([]))
              ,A2($Svg.path,
              _U.list([$Svg$Attributes.d("M9 2L7.17 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2h-3.17L15 2H9zm3 15c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5z")
                      ,$Svg$Attributes.fill(stringColor)]),
              _U.list([]))]));
   });
   var camera = $Material$Icons$Internal.icon("M9.4 10.5l4.77-8.26C13.47 2.09 12.75 2 12 2c-2.4 0-4.6.85-6.32 2.25l3.66 6.35.06-.1zM21.54 9c-.92-2.92-3.15-5.26-6-6.34L11.88 9h9.66zm.26 1h-7.49l.29.5 4.76 8.25C21 16.97 22 14.61 22 12c0-.69-.07-1.35-.2-2zM8.54 12l-3.9-6.75C3.01 7.03 2 9.39 2 12c0 .69.07 1.35.2 2h7.49l-1.15-2zm-6.08 3c.92 2.92 3.15 5.26 6 6.34L12.12 15H2.46zm11.27 0l-3.9 6.76c.7.15 1.42.24 2.17.24 2.4 0 4.6-.85 6.32-2.25l-3.66-6.35-.93 1.6z");
   var brush = $Material$Icons$Internal.icon("M7 14c-1.66 0-3 1.34-3 3 0 1.31-1.16 2-2 2 .92 1.22 2.49 2 4 2 2.21 0 4-1.79 4-4 0-1.66-1.34-3-3-3zm13.71-9.37l-1.34-1.34c-.39-.39-1.02-.39-1.41 0L9 12.25 11.75 15l8.96-8.96c.39-.39.39-1.02 0-1.41z");
   var broken_image = $Material$Icons$Internal.icon("M21 5v6.59l-3-3.01-4 4.01-4-4-4 4-3-3.01V5c0-1.1.9-2 2-2h14c1.1 0 2 .9 2 2zm-3 6.42l3 3.01V19c0 1.1-.9 2-2 2H5c-1.1 0-2-.9-2-2v-6.58l3 2.99 4-4 4 4 4-3.99z");
   var brightness_7 = $Material$Icons$Internal.icon("M20 8.69V4h-4.69L12 .69 8.69 4H4v4.69L.69 12 4 15.31V20h4.69L12 23.31 15.31 20H20v-4.69L23.31 12 20 8.69zM12 18c-3.31 0-6-2.69-6-6s2.69-6 6-6 6 2.69 6 6-2.69 6-6 6zm0-10c-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4-1.79-4-4-4z");
   var brightness_6 = $Material$Icons$Internal.icon("M20 15.31L23.31 12 20 8.69V4h-4.69L12 .69 8.69 4H4v4.69L.69 12 4 15.31V20h4.69L12 23.31 15.31 20H20v-4.69zM12 18V6c3.31 0 6 2.69 6 6s-2.69 6-6 6z");
   var brightness_5 = $Material$Icons$Internal.icon("M20 15.31L23.31 12 20 8.69V4h-4.69L12 .69 8.69 4H4v4.69L.69 12 4 15.31V20h4.69L12 23.31 15.31 20H20v-4.69zM12 18c-3.31 0-6-2.69-6-6s2.69-6 6-6 6 2.69 6 6-2.69 6-6 6z");
   var brightness_4 = $Material$Icons$Internal.icon("M20 8.69V4h-4.69L12 .69 8.69 4H4v4.69L.69 12 4 15.31V20h4.69L12 23.31 15.31 20H20v-4.69L23.31 12 20 8.69zM12 18c-.89 0-1.74-.2-2.5-.55C11.56 16.5 13 14.42 13 12s-1.44-4.5-3.5-5.45C10.26 6.2 11.11 6 12 6c3.31 0 6 2.69 6 6s-2.69 6-6 6z");
   var brightness_3 = $Material$Icons$Internal.icon("M9 2c-1.05 0-2.05.16-3 .46 4.06 1.27 7 5.06 7 9.54 0 4.48-2.94 8.27-7 9.54.95.3 1.95.46 3 .46 5.52 0 10-4.48 10-10S14.52 2 9 2z");
   var brightness_2 = $Material$Icons$Internal.icon("M10 2c-1.82 0-3.53.5-5 1.35C7.99 5.08 10 8.3 10 12s-2.01 6.92-5 8.65C6.47 21.5 8.18 22 10 22c5.52 0 10-4.48 10-10S15.52 2 10 2z");
   var brightness_1 = F2(function (color,size) {
      var stringSize = $Basics.toString(size);
      var stringColor = $Material$Icons$Internal.toRgbaString(color);
      return A2($Svg.svg,
      _U.list([$Svg$Attributes.width(stringSize)
              ,$Svg$Attributes.height(stringSize)
              ,$Svg$Attributes.viewBox("0 0 24 24")]),
      _U.list([A2($Svg.circle,
      _U.list([$Svg$Attributes.cx("12")
              ,$Svg$Attributes.cy("12")
              ,$Svg$Attributes.r("10")
              ,$Svg$Attributes.fill(stringColor)]),
      _U.list([]))]));
   });
   var blur_on = $Material$Icons$Internal.icon("M6 13c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1zm0 4c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1zm0-8c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1zm-3 .5c-.28 0-.5.22-.5.5s.22.5.5.5.5-.22.5-.5-.22-.5-.5-.5zM6 5c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1zm15 5.5c.28 0 .5-.22.5-.5s-.22-.5-.5-.5-.5.22-.5.5.22.5.5.5zM14 7c.55 0 1-.45 1-1s-.45-1-1-1-1 .45-1 1 .45 1 1 1zm0-3.5c.28 0 .5-.22.5-.5s-.22-.5-.5-.5-.5.22-.5.5.22.5.5.5zm-11 10c-.28 0-.5.22-.5.5s.22.5.5.5.5-.22.5-.5-.22-.5-.5-.5zm7 7c-.28 0-.5.22-.5.5s.22.5.5.5.5-.22.5-.5-.22-.5-.5-.5zm0-17c.28 0 .5-.22.5-.5s-.22-.5-.5-.5-.5.22-.5.5.22.5.5.5zM10 7c.55 0 1-.45 1-1s-.45-1-1-1-1 .45-1 1 .45 1 1 1zm0 5.5c-.83 0-1.5.67-1.5 1.5s.67 1.5 1.5 1.5 1.5-.67 1.5-1.5-.67-1.5-1.5-1.5zm8 .5c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1zm0 4c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1zm0-8c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1zm0-4c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1zm3 8.5c-.28 0-.5.22-.5.5s.22.5.5.5.5-.22.5-.5-.22-.5-.5-.5zM14 17c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1zm0 3.5c-.28 0-.5.22-.5.5s.22.5.5.5.5-.22.5-.5-.22-.5-.5-.5zm-4-12c-.83 0-1.5.67-1.5 1.5s.67 1.5 1.5 1.5 1.5-.67 1.5-1.5-.67-1.5-1.5-1.5zm0 8.5c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1zm4-4.5c-.83 0-1.5.67-1.5 1.5s.67 1.5 1.5 1.5 1.5-.67 1.5-1.5-.67-1.5-1.5-1.5zm0-4c-.83 0-1.5.67-1.5 1.5s.67 1.5 1.5 1.5 1.5-.67 1.5-1.5-.67-1.5-1.5-1.5z");
   var blur_off = $Material$Icons$Internal.icon("M14 7c.55 0 1-.45 1-1s-.45-1-1-1-1 .45-1 1 .45 1 1 1zm-.2 4.48l.2.02c.83 0 1.5-.67 1.5-1.5s-.67-1.5-1.5-1.5-1.5.67-1.5 1.5l.02.2c.09.67.61 1.19 1.28 1.28zM14 3.5c.28 0 .5-.22.5-.5s-.22-.5-.5-.5-.5.22-.5.5.22.5.5.5zm-4 0c.28 0 .5-.22.5-.5s-.22-.5-.5-.5-.5.22-.5.5.22.5.5.5zm11 7c.28 0 .5-.22.5-.5s-.22-.5-.5-.5-.5.22-.5.5.22.5.5.5zM10 7c.55 0 1-.45 1-1s-.45-1-1-1-1 .45-1 1 .45 1 1 1zm8 8c.55 0 1-.45 1-1s-.45-1-1-1-1 .45-1 1 .45 1 1 1zm0-4c.55 0 1-.45 1-1s-.45-1-1-1-1 .45-1 1 .45 1 1 1zm0-4c.55 0 1-.45 1-1s-.45-1-1-1-1 .45-1 1 .45 1 1 1zm-4 13.5c-.28 0-.5.22-.5.5s.22.5.5.5.5-.22.5-.5-.22-.5-.5-.5zM2.5 5.27l3.78 3.78L6 9c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1c0-.1-.03-.19-.06-.28l2.81 2.81c-.71.11-1.25.73-1.25 1.47 0 .83.67 1.5 1.5 1.5.74 0 1.36-.54 1.47-1.25l2.81 2.81c-.09-.03-.18-.06-.28-.06-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1c0-.1-.03-.19-.06-.28l3.78 3.78L20 20.23 3.77 4 2.5 5.27zM10 17c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1zm11-3.5c-.28 0-.5.22-.5.5s.22.5.5.5.5-.22.5-.5-.22-.5-.5-.5zM6 13c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1zM3 9.5c-.28 0-.5.22-.5.5s.22.5.5.5.5-.22.5-.5-.22-.5-.5-.5zm7 11c-.28 0-.5.22-.5.5s.22.5.5.5.5-.22.5-.5-.22-.5-.5-.5zM6 17c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1zm-3-3.5c-.28 0-.5.22-.5.5s.22.5.5.5.5-.22.5-.5-.22-.5-.5-.5z");
   var blur_linear = $Material$Icons$Internal.icon("M5 17.5c.83 0 1.5-.67 1.5-1.5s-.67-1.5-1.5-1.5-1.5.67-1.5 1.5.67 1.5 1.5 1.5zM9 13c.55 0 1-.45 1-1s-.45-1-1-1-1 .45-1 1 .45 1 1 1zm0-4c.55 0 1-.45 1-1s-.45-1-1-1-1 .45-1 1 .45 1 1 1zM3 21h18v-2H3v2zM5 9.5c.83 0 1.5-.67 1.5-1.5S5.83 6.5 5 6.5 3.5 7.17 3.5 8 4.17 9.5 5 9.5zm0 4c.83 0 1.5-.67 1.5-1.5s-.67-1.5-1.5-1.5-1.5.67-1.5 1.5.67 1.5 1.5 1.5zM9 17c.55 0 1-.45 1-1s-.45-1-1-1-1 .45-1 1 .45 1 1 1zm8-.5c.28 0 .5-.22.5-.5s-.22-.5-.5-.5-.5.22-.5.5.22.5.5.5zM3 3v2h18V3H3zm14 5.5c.28 0 .5-.22.5-.5s-.22-.5-.5-.5-.5.22-.5.5.22.5.5.5zm0 4c.28 0 .5-.22.5-.5s-.22-.5-.5-.5-.5.22-.5.5.22.5.5.5zM13 9c.55 0 1-.45 1-1s-.45-1-1-1-1 .45-1 1 .45 1 1 1zm0 4c.55 0 1-.45 1-1s-.45-1-1-1-1 .45-1 1 .45 1 1 1zm0 4c.55 0 1-.45 1-1s-.45-1-1-1-1 .45-1 1 .45 1 1 1z");
   var blur_circular = $Material$Icons$Internal.icon("M10 9c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1zm0 4c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1zM7 9.5c-.28 0-.5.22-.5.5s.22.5.5.5.5-.22.5-.5-.22-.5-.5-.5zm3 7c-.28 0-.5.22-.5.5s.22.5.5.5.5-.22.5-.5-.22-.5-.5-.5zm-3-3c-.28 0-.5.22-.5.5s.22.5.5.5.5-.22.5-.5-.22-.5-.5-.5zm3-6c.28 0 .5-.22.5-.5s-.22-.5-.5-.5-.5.22-.5.5.22.5.5.5zM14 9c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1zm0-1.5c.28 0 .5-.22.5-.5s-.22-.5-.5-.5-.5.22-.5.5.22.5.5.5zm3 6c-.28 0-.5.22-.5.5s.22.5.5.5.5-.22.5-.5-.22-.5-.5-.5zm0-4c-.28 0-.5.22-.5.5s.22.5.5.5.5-.22.5-.5-.22-.5-.5-.5zM12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8zm2-3.5c-.28 0-.5.22-.5.5s.22.5.5.5.5-.22.5-.5-.22-.5-.5-.5zm0-3.5c-.55 0-1 .45-1 1s.45 1 1 1 1-.45 1-1-.45-1-1-1z");
   var audiotrack = $Material$Icons$Internal.icon("M12 3v9.28c-.47-.17-.97-.28-1.5-.28C8.01 12 6 14.01 6 16.5S8.01 21 10.5 21c2.31 0 4.2-1.75 4.45-4H15V6h4V3h-7z");
   var assistant_photo = $Material$Icons$Internal.icon("M14.4 6L14 4H5v17h2v-7h5.6l.4 2h7V6z");
   var assistant = $Material$Icons$Internal.icon("M19 2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h4l3 3 3-3h4c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-5.12 10.88L12 17l-1.88-4.12L6 11l4.12-1.88L12 5l1.88 4.12L18 11l-4.12 1.88z");
   var adjust = $Material$Icons$Internal.icon("M12 2C6.49 2 2 6.49 2 12s4.49 10 10 10 10-4.49 10-10S17.51 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm3-8c0 1.66-1.34 3-3 3s-3-1.34-3-3 1.34-3 3-3 3 1.34 3 3z");
   var add_to_photos = $Material$Icons$Internal.icon("M4 6H2v14c0 1.1.9 2 2 2h14v-2H4V6zm16-4H8c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-1 9h-4v4h-2v-4H9V9h4V5h2v4h4v2z");
   return _elm.Material.Icons.Image.values = {_op: _op
                                             ,add_to_photos: add_to_photos
                                             ,adjust: adjust
                                             ,assistant: assistant
                                             ,assistant_photo: assistant_photo
                                             ,audiotrack: audiotrack
                                             ,blur_circular: blur_circular
                                             ,blur_linear: blur_linear
                                             ,blur_off: blur_off
                                             ,blur_on: blur_on
                                             ,brightness_1: brightness_1
                                             ,brightness_2: brightness_2
                                             ,brightness_3: brightness_3
                                             ,brightness_4: brightness_4
                                             ,brightness_5: brightness_5
                                             ,brightness_6: brightness_6
                                             ,brightness_7: brightness_7
                                             ,broken_image: broken_image
                                             ,brush: brush
                                             ,camera: camera
                                             ,camera_alt: camera_alt
                                             ,camera_front: camera_front
                                             ,camera_rear: camera_rear
                                             ,camera_roll: camera_roll
                                             ,center_focus_strong: center_focus_strong
                                             ,center_focus_weak: center_focus_weak
                                             ,collections: collections
                                             ,collections_bookmark: collections_bookmark
                                             ,color_lens: color_lens
                                             ,colorize: colorize
                                             ,compare: compare
                                             ,control_point: control_point
                                             ,control_point_duplicate: control_point_duplicate
                                             ,crop_16_9: crop_16_9
                                             ,crop: crop
                                             ,crop_3_2: crop_3_2
                                             ,crop_5_4: crop_5_4
                                             ,crop_7_5: crop_7_5
                                             ,crop_din: crop_din
                                             ,crop_free: crop_free
                                             ,crop_landscape: crop_landscape
                                             ,crop_original: crop_original
                                             ,crop_portrait: crop_portrait
                                             ,crop_square: crop_square
                                             ,dehaze: dehaze
                                             ,details: details
                                             ,edit: edit
                                             ,exposure: exposure
                                             ,exposure_neg_1: exposure_neg_1
                                             ,exposure_neg_2: exposure_neg_2
                                             ,exposure_plus_1: exposure_plus_1
                                             ,exposure_plus_2: exposure_plus_2
                                             ,exposure_zero: exposure_zero
                                             ,filter: filter
                                             ,filter_1: filter_1
                                             ,filter_2: filter_2
                                             ,filter_3: filter_3
                                             ,filter_4: filter_4
                                             ,filter_5: filter_5
                                             ,filter_6: filter_6
                                             ,filter_7: filter_7
                                             ,filter_8: filter_8
                                             ,filter_9: filter_9
                                             ,filter_9_plus: filter_9_plus
                                             ,filter_b_and_w: filter_b_and_w
                                             ,filter_center_focus: filter_center_focus
                                             ,filter_drama: filter_drama
                                             ,filter_frames: filter_frames
                                             ,filter_hdr: filter_hdr
                                             ,filter_none: filter_none
                                             ,filter_tilt_shift: filter_tilt_shift
                                             ,filter_vintage: filter_vintage
                                             ,flare: flare
                                             ,flash_auto: flash_auto
                                             ,flash_off: flash_off
                                             ,flash_on: flash_on
                                             ,flip: flip
                                             ,gradient: gradient
                                             ,grain: grain
                                             ,grid_off: grid_off
                                             ,grid_on: grid_on
                                             ,hdr_off: hdr_off
                                             ,hdr_on: hdr_on
                                             ,hdr_strong: hdr_strong
                                             ,hdr_weak: hdr_weak
                                             ,healing: healing
                                             ,image: image
                                             ,image_aspect_ratio: image_aspect_ratio
                                             ,iso: iso
                                             ,landscape: landscape
                                             ,leak_add: leak_add
                                             ,leak_remove: leak_remove
                                             ,lens: lens
                                             ,looks: looks
                                             ,looks_3: looks_3
                                             ,looks_4: looks_4
                                             ,looks_5: looks_5
                                             ,looks_6: looks_6
                                             ,looks_one: looks_one
                                             ,looks_two: looks_two
                                             ,loupe: loupe
                                             ,monochrome_photos: monochrome_photos
                                             ,movie_creation: movie_creation
                                             ,music_note: music_note
                                             ,nature: nature
                                             ,nature_people: nature_people
                                             ,navigate_before: navigate_before
                                             ,navigate_next: navigate_next
                                             ,palette: palette
                                             ,panorama: panorama
                                             ,panorama_fish_eye: panorama_fish_eye
                                             ,panorama_horizontal: panorama_horizontal
                                             ,panorama_vertical: panorama_vertical
                                             ,panorama_wide_angle: panorama_wide_angle
                                             ,photo: photo
                                             ,photo_album: photo_album
                                             ,photo_camera: photo_camera
                                             ,photo_library: photo_library
                                             ,photo_size_select_actual: photo_size_select_actual
                                             ,photo_size_select_large: photo_size_select_large
                                             ,photo_size_select_small: photo_size_select_small
                                             ,picture_as_pdf: picture_as_pdf
                                             ,portrait: portrait
                                             ,remove_red_eye: remove_red_eye
                                             ,rotate_90_degrees_ccw: rotate_90_degrees_ccw
                                             ,rotate_left: rotate_left
                                             ,rotate_right: rotate_right
                                             ,slideshow: slideshow
                                             ,straighten: straighten
                                             ,style: style
                                             ,switch_camera: switch_camera
                                             ,switch_video: switch_video
                                             ,tag_faces: tag_faces
                                             ,texture: texture
                                             ,timelapse: timelapse
                                             ,timer_10: timer_10
                                             ,timer: timer
                                             ,timer_3: timer_3
                                             ,timer_off: timer_off
                                             ,tonality: tonality
                                             ,transform: transform
                                             ,tune: tune
                                             ,view_comfy: view_comfy
                                             ,view_compact: view_compact
                                             ,vignette: vignette
                                             ,wb_auto: wb_auto
                                             ,wb_cloudy: wb_cloudy
                                             ,wb_incandescent: wb_incandescent
                                             ,wb_iridescent: wb_iridescent
                                             ,wb_sunny: wb_sunny};
};
Elm.Native.Time = {};

Elm.Native.Time.make = function(localRuntime)
{
	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Time = localRuntime.Native.Time || {};
	if (localRuntime.Native.Time.values)
	{
		return localRuntime.Native.Time.values;
	}

	var NS = Elm.Native.Signal.make(localRuntime);
	var Maybe = Elm.Maybe.make(localRuntime);


	// FRAMES PER SECOND

	function fpsWhen(desiredFPS, isOn)
	{
		var msPerFrame = 1000 / desiredFPS;
		var ticker = NS.input('fps-' + desiredFPS, null);

		function notifyTicker()
		{
			localRuntime.notify(ticker.id, null);
		}

		function firstArg(x, y)
		{
			return x;
		}

		// input fires either when isOn changes, or when ticker fires.
		// Its value is a tuple with the current timestamp, and the state of isOn
		var input = NS.timestamp(A3(NS.map2, F2(firstArg), NS.dropRepeats(isOn), ticker));

		var initialState = {
			isOn: false,
			time: localRuntime.timer.programStart,
			delta: 0
		};

		var timeoutId;

		function update(input, state)
		{
			var currentTime = input._0;
			var isOn = input._1;
			var wasOn = state.isOn;
			var previousTime = state.time;

			if (isOn)
			{
				timeoutId = localRuntime.setTimeout(notifyTicker, msPerFrame);
			}
			else if (wasOn)
			{
				clearTimeout(timeoutId);
			}

			return {
				isOn: isOn,
				time: currentTime,
				delta: (isOn && !wasOn) ? 0 : currentTime - previousTime
			};
		}

		return A2(
			NS.map,
			function(state) { return state.delta; },
			A3(NS.foldp, F2(update), update(input.value, initialState), input)
		);
	}


	// EVERY

	function every(t)
	{
		var ticker = NS.input('every-' + t, null);
		function tellTime()
		{
			localRuntime.notify(ticker.id, null);
		}
		var clock = A2(NS.map, fst, NS.timestamp(ticker));
		setInterval(tellTime, t);
		return clock;
	}


	function fst(pair)
	{
		return pair._0;
	}


	function read(s)
	{
		var t = Date.parse(s);
		return isNaN(t) ? Maybe.Nothing : Maybe.Just(t);
	}

	return localRuntime.Native.Time.values = {
		fpsWhen: F2(fpsWhen),
		every: every,
		toDate: function(t) { return new Date(t); },
		read: read
	};
};

Elm.Time = Elm.Time || {};
Elm.Time.make = function (_elm) {
   "use strict";
   _elm.Time = _elm.Time || {};
   if (_elm.Time.values) return _elm.Time.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Native$Signal = Elm.Native.Signal.make(_elm),
   $Native$Time = Elm.Native.Time.make(_elm),
   $Signal = Elm.Signal.make(_elm);
   var _op = {};
   var delay = $Native$Signal.delay;
   var since = F2(function (time,signal) {
      var stop = A2($Signal.map,
      $Basics.always(-1),
      A2(delay,time,signal));
      var start = A2($Signal.map,$Basics.always(1),signal);
      var delaydiff = A3($Signal.foldp,
      F2(function (x,y) {    return x + y;}),
      0,
      A2($Signal.merge,start,stop));
      return A2($Signal.map,
      F2(function (x,y) {    return !_U.eq(x,y);})(0),
      delaydiff);
   });
   var timestamp = $Native$Signal.timestamp;
   var every = $Native$Time.every;
   var fpsWhen = $Native$Time.fpsWhen;
   var fps = function (targetFrames) {
      return A2(fpsWhen,targetFrames,$Signal.constant(true));
   };
   var inMilliseconds = function (t) {    return t;};
   var millisecond = 1;
   var second = 1000 * millisecond;
   var minute = 60 * second;
   var hour = 60 * minute;
   var inHours = function (t) {    return t / hour;};
   var inMinutes = function (t) {    return t / minute;};
   var inSeconds = function (t) {    return t / second;};
   return _elm.Time.values = {_op: _op
                             ,millisecond: millisecond
                             ,second: second
                             ,minute: minute
                             ,hour: hour
                             ,inMilliseconds: inMilliseconds
                             ,inSeconds: inSeconds
                             ,inMinutes: inMinutes
                             ,inHours: inHours
                             ,fps: fps
                             ,fpsWhen: fpsWhen
                             ,every: every
                             ,timestamp: timestamp
                             ,delay: delay
                             ,since: since};
};
Elm.Native.Keyboard = {};

Elm.Native.Keyboard.make = function(localRuntime) {
	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Keyboard = localRuntime.Native.Keyboard || {};
	if (localRuntime.Native.Keyboard.values)
	{
		return localRuntime.Native.Keyboard.values;
	}

	var NS = Elm.Native.Signal.make(localRuntime);


	function keyEvent(event)
	{
		return {
			alt: event.altKey,
			meta: event.metaKey,
			keyCode: event.keyCode
		};
	}


	function keyStream(node, eventName, handler)
	{
		var stream = NS.input(eventName, { alt: false, meta: false, keyCode: 0 });

		localRuntime.addListener([stream.id], node, eventName, function(e) {
			localRuntime.notify(stream.id, handler(e));
		});

		return stream;
	}

	var downs = keyStream(document, 'keydown', keyEvent);
	var ups = keyStream(document, 'keyup', keyEvent);
	var presses = keyStream(document, 'keypress', keyEvent);
	var blurs = keyStream(window, 'blur', function() { return null; });


	return localRuntime.Native.Keyboard.values = {
		downs: downs,
		ups: ups,
		blurs: blurs,
		presses: presses
	};
};

Elm.Keyboard = Elm.Keyboard || {};
Elm.Keyboard.make = function (_elm) {
   "use strict";
   _elm.Keyboard = _elm.Keyboard || {};
   if (_elm.Keyboard.values) return _elm.Keyboard.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Char = Elm.Char.make(_elm),
   $Native$Keyboard = Elm.Native.Keyboard.make(_elm),
   $Set = Elm.Set.make(_elm),
   $Signal = Elm.Signal.make(_elm);
   var _op = {};
   var presses = A2($Signal.map,
   function (_) {
      return _.keyCode;
   },
   $Native$Keyboard.presses);
   var toXY = F2(function (_p0,keyCodes) {
      var _p1 = _p0;
      var is = function (keyCode) {
         return A2($Set.member,keyCode,keyCodes) ? 1 : 0;
      };
      return {x: is(_p1.right) - is(_p1.left)
             ,y: is(_p1.up) - is(_p1.down)};
   });
   var Directions = F4(function (a,b,c,d) {
      return {up: a,down: b,left: c,right: d};
   });
   var dropMap = F2(function (f,signal) {
      return $Signal.dropRepeats(A2($Signal.map,f,signal));
   });
   var EventInfo = F3(function (a,b,c) {
      return {alt: a,meta: b,keyCode: c};
   });
   var Blur = {ctor: "Blur"};
   var Down = function (a) {    return {ctor: "Down",_0: a};};
   var Up = function (a) {    return {ctor: "Up",_0: a};};
   var rawEvents = $Signal.mergeMany(_U.list([A2($Signal.map,
                                             Up,
                                             $Native$Keyboard.ups)
                                             ,A2($Signal.map,Down,$Native$Keyboard.downs)
                                             ,A2($Signal.map,$Basics.always(Blur),$Native$Keyboard.blurs)]));
   var empty = {alt: false,meta: false,keyCodes: $Set.empty};
   var update = F2(function (event,model) {
      var _p2 = event;
      switch (_p2.ctor)
      {case "Down": var _p3 = _p2._0;
           return {alt: _p3.alt
                  ,meta: _p3.meta
                  ,keyCodes: A2($Set.insert,_p3.keyCode,model.keyCodes)};
         case "Up": var _p4 = _p2._0;
           return {alt: _p4.alt
                  ,meta: _p4.meta
                  ,keyCodes: A2($Set.remove,_p4.keyCode,model.keyCodes)};
         default: return empty;}
   });
   var model = A3($Signal.foldp,update,empty,rawEvents);
   var alt = A2(dropMap,function (_) {    return _.alt;},model);
   var meta = A2(dropMap,function (_) {    return _.meta;},model);
   var keysDown = A2(dropMap,
   function (_) {
      return _.keyCodes;
   },
   model);
   var arrows = A2(dropMap,
   toXY({up: 38,down: 40,left: 37,right: 39}),
   keysDown);
   var wasd = A2(dropMap,
   toXY({up: 87,down: 83,left: 65,right: 68}),
   keysDown);
   var isDown = function (keyCode) {
      return A2(dropMap,$Set.member(keyCode),keysDown);
   };
   var ctrl = isDown(17);
   var shift = isDown(16);
   var space = isDown(32);
   var enter = isDown(13);
   var Model = F3(function (a,b,c) {
      return {alt: a,meta: b,keyCodes: c};
   });
   return _elm.Keyboard.values = {_op: _op
                                 ,arrows: arrows
                                 ,wasd: wasd
                                 ,enter: enter
                                 ,space: space
                                 ,ctrl: ctrl
                                 ,shift: shift
                                 ,alt: alt
                                 ,meta: meta
                                 ,isDown: isDown
                                 ,keysDown: keysDown
                                 ,presses: presses};
};
Elm.Native = Elm.Native || {};
Elm.Native.Window = {};
Elm.Native.Window.make = function make(localRuntime) {
	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Window = localRuntime.Native.Window || {};
	if (localRuntime.Native.Window.values)
	{
		return localRuntime.Native.Window.values;
	}

	var NS = Elm.Native.Signal.make(localRuntime);
	var Tuple2 = Elm.Native.Utils.make(localRuntime).Tuple2;


	function getWidth()
	{
		return localRuntime.node.clientWidth;
	}


	function getHeight()
	{
		if (localRuntime.isFullscreen())
		{
			return window.innerHeight;
		}
		return localRuntime.node.clientHeight;
	}


	var dimensions = NS.input('Window.dimensions', Tuple2(getWidth(), getHeight()));


	function resizeIfNeeded()
	{
		// Do not trigger event if the dimensions have not changed.
		// This should be most of the time.
		var w = getWidth();
		var h = getHeight();
		if (dimensions.value._0 === w && dimensions.value._1 === h)
		{
			return;
		}

		setTimeout(function() {
			// Check again to see if the dimensions have changed.
			// It is conceivable that the dimensions have changed
			// again while some other event was being processed.
			w = getWidth();
			h = getHeight();
			if (dimensions.value._0 === w && dimensions.value._1 === h)
			{
				return;
			}
			localRuntime.notify(dimensions.id, Tuple2(w, h));
		}, 0);
	}


	localRuntime.addListener([dimensions.id], window, 'resize', resizeIfNeeded);


	return localRuntime.Native.Window.values = {
		dimensions: dimensions,
		resizeIfNeeded: resizeIfNeeded
	};
};

Elm.Window = Elm.Window || {};
Elm.Window.make = function (_elm) {
   "use strict";
   _elm.Window = _elm.Window || {};
   if (_elm.Window.values) return _elm.Window.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Native$Window = Elm.Native.Window.make(_elm),
   $Signal = Elm.Signal.make(_elm);
   var _op = {};
   var dimensions = $Native$Window.dimensions;
   var width = A2($Signal.map,$Basics.fst,dimensions);
   var height = A2($Signal.map,$Basics.snd,dimensions);
   return _elm.Window.values = {_op: _op
                               ,dimensions: dimensions
                               ,width: width
                               ,height: height};
};
Elm.Native.Effects = {};
Elm.Native.Effects.make = function(localRuntime) {

	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Effects = localRuntime.Native.Effects || {};
	if (localRuntime.Native.Effects.values)
	{
		return localRuntime.Native.Effects.values;
	}

	var Task = Elm.Native.Task.make(localRuntime);
	var Utils = Elm.Native.Utils.make(localRuntime);
	var Signal = Elm.Signal.make(localRuntime);
	var List = Elm.Native.List.make(localRuntime);


	// polyfill so things will work even if rAF is not available for some reason
	var _requestAnimationFrame =
		typeof requestAnimationFrame !== 'undefined'
			? requestAnimationFrame
			: function(cb) { setTimeout(cb, 1000 / 60); }
			;


	// batchedSending and sendCallback implement a small state machine in order
	// to schedule only one send(time) call per animation frame.
	//
	// Invariants:
	// 1. In the NO_REQUEST state, there is never a scheduled sendCallback.
	// 2. In the PENDING_REQUEST and EXTRA_REQUEST states, there is always exactly
	//    one scheduled sendCallback.
	var NO_REQUEST = 0;
	var PENDING_REQUEST = 1;
	var EXTRA_REQUEST = 2;
	var state = NO_REQUEST;
	var messageArray = [];


	function batchedSending(address, tickMessages)
	{
		// insert ticks into the messageArray
		var foundAddress = false;

		for (var i = messageArray.length; i--; )
		{
			if (messageArray[i].address === address)
			{
				foundAddress = true;
				messageArray[i].tickMessages = A3(List.foldl, List.cons, messageArray[i].tickMessages, tickMessages);
				break;
			}
		}

		if (!foundAddress)
		{
			messageArray.push({ address: address, tickMessages: tickMessages });
		}

		// do the appropriate state transition
		switch (state)
		{
			case NO_REQUEST:
				_requestAnimationFrame(sendCallback);
				state = PENDING_REQUEST;
				break;
			case PENDING_REQUEST:
				state = PENDING_REQUEST;
				break;
			case EXTRA_REQUEST:
				state = PENDING_REQUEST;
				break;
		}
	}


	function sendCallback(time)
	{
		switch (state)
		{
			case NO_REQUEST:
				// This state should not be possible. How can there be no
				// request, yet somehow we are actively fulfilling a
				// request?
				throw new Error(
					'Unexpected send callback.\n' +
					'Please report this to <https://github.com/evancz/elm-effects/issues>.'
				);

			case PENDING_REQUEST:
				// At this point, we do not *know* that another frame is
				// needed, but we make an extra request to rAF just in
				// case. It's possible to drop a frame if rAF is called
				// too late, so we just do it preemptively.
				_requestAnimationFrame(sendCallback);
				state = EXTRA_REQUEST;

				// There's also stuff we definitely need to send.
				send(time);
				return;

			case EXTRA_REQUEST:
				// Turns out the extra request was not needed, so we will
				// stop calling rAF. No reason to call it all the time if
				// no one needs it.
				state = NO_REQUEST;
				return;
		}
	}


	function send(time)
	{
		for (var i = messageArray.length; i--; )
		{
			var messages = A3(
				List.foldl,
				F2( function(toAction, list) { return List.Cons(toAction(time), list); } ),
				List.Nil,
				messageArray[i].tickMessages
			);
			Task.perform( A2(Signal.send, messageArray[i].address, messages) );
		}
		messageArray = [];
	}


	function requestTickSending(address, tickMessages)
	{
		return Task.asyncFunction(function(callback) {
			batchedSending(address, tickMessages);
			callback(Task.succeed(Utils.Tuple0));
		});
	}


	return localRuntime.Native.Effects.values = {
		requestTickSending: F2(requestTickSending)
	};

};

Elm.Effects = Elm.Effects || {};
Elm.Effects.make = function (_elm) {
   "use strict";
   _elm.Effects = _elm.Effects || {};
   if (_elm.Effects.values) return _elm.Effects.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Native$Effects = Elm.Native.Effects.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $Task = Elm.Task.make(_elm),
   $Time = Elm.Time.make(_elm);
   var _op = {};
   var ignore = function (task) {
      return A2($Task.map,$Basics.always({ctor: "_Tuple0"}),task);
   };
   var requestTickSending = $Native$Effects.requestTickSending;
   var toTaskHelp = F3(function (address,effect,_p0) {
      var _p1 = _p0;
      var _p5 = _p1._1;
      var _p4 = _p1;
      var _p3 = _p1._0;
      var _p2 = effect;
      switch (_p2.ctor)
      {case "Task": var reporter = A2($Task.andThen,
           _p2._0,
           function (answer) {
              return A2($Signal.send,address,_U.list([answer]));
           });
           return {ctor: "_Tuple2"
                  ,_0: A2($Task.andThen,
                  _p3,
                  $Basics.always(ignore($Task.spawn(reporter))))
                  ,_1: _p5};
         case "Tick": return {ctor: "_Tuple2"
                             ,_0: _p3
                             ,_1: A2($List._op["::"],_p2._0,_p5)};
         case "None": return _p4;
         default: return A3($List.foldl,toTaskHelp(address),_p4,_p2._0);}
   });
   var toTask = F2(function (address,effect) {
      var _p6 = A3(toTaskHelp,
      address,
      effect,
      {ctor: "_Tuple2"
      ,_0: $Task.succeed({ctor: "_Tuple0"})
      ,_1: _U.list([])});
      var combinedTask = _p6._0;
      var tickMessages = _p6._1;
      return $List.isEmpty(tickMessages) ? combinedTask : A2($Task.andThen,
      combinedTask,
      $Basics.always(A2(requestTickSending,address,tickMessages)));
   });
   var Never = function (a) {    return {ctor: "Never",_0: a};};
   var Batch = function (a) {    return {ctor: "Batch",_0: a};};
   var batch = Batch;
   var None = {ctor: "None"};
   var none = None;
   var Tick = function (a) {    return {ctor: "Tick",_0: a};};
   var tick = Tick;
   var Task = function (a) {    return {ctor: "Task",_0: a};};
   var task = Task;
   var map = F2(function (func,effect) {
      var _p7 = effect;
      switch (_p7.ctor)
      {case "Task": return Task(A2($Task.map,func,_p7._0));
         case "Tick": return Tick(function (_p8) {
              return func(_p7._0(_p8));
           });
         case "None": return None;
         default: return Batch(A2($List.map,map(func),_p7._0));}
   });
   return _elm.Effects.values = {_op: _op
                                ,none: none
                                ,task: task
                                ,tick: tick
                                ,map: map
                                ,batch: batch
                                ,toTask: toTask};
};
Elm.Html = Elm.Html || {};
Elm.Html.Attributes = Elm.Html.Attributes || {};
Elm.Html.Attributes.make = function (_elm) {
   "use strict";
   _elm.Html = _elm.Html || {};
   _elm.Html.Attributes = _elm.Html.Attributes || {};
   if (_elm.Html.Attributes.values)
   return _elm.Html.Attributes.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $Html = Elm.Html.make(_elm),
   $Json$Encode = Elm.Json.Encode.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $String = Elm.String.make(_elm),
   $VirtualDom = Elm.VirtualDom.make(_elm);
   var _op = {};
   var attribute = $VirtualDom.attribute;
   var contextmenu = function (value) {
      return A2(attribute,"contextmenu",value);
   };
   var property = $VirtualDom.property;
   var stringProperty = F2(function (name,string) {
      return A2(property,name,$Json$Encode.string(string));
   });
   var $class = function (name) {
      return A2(stringProperty,"className",name);
   };
   var id = function (name) {
      return A2(stringProperty,"id",name);
   };
   var title = function (name) {
      return A2(stringProperty,"title",name);
   };
   var accesskey = function ($char) {
      return A2(stringProperty,
      "accessKey",
      $String.fromChar($char));
   };
   var dir = function (value) {
      return A2(stringProperty,"dir",value);
   };
   var draggable = function (value) {
      return A2(stringProperty,"draggable",value);
   };
   var dropzone = function (value) {
      return A2(stringProperty,"dropzone",value);
   };
   var itemprop = function (value) {
      return A2(stringProperty,"itemprop",value);
   };
   var lang = function (value) {
      return A2(stringProperty,"lang",value);
   };
   var tabindex = function (n) {
      return A2(stringProperty,"tabIndex",$Basics.toString(n));
   };
   var charset = function (value) {
      return A2(stringProperty,"charset",value);
   };
   var content = function (value) {
      return A2(stringProperty,"content",value);
   };
   var httpEquiv = function (value) {
      return A2(stringProperty,"httpEquiv",value);
   };
   var language = function (value) {
      return A2(stringProperty,"language",value);
   };
   var src = function (value) {
      return A2(stringProperty,"src",value);
   };
   var height = function (value) {
      return A2(stringProperty,"height",$Basics.toString(value));
   };
   var width = function (value) {
      return A2(stringProperty,"width",$Basics.toString(value));
   };
   var alt = function (value) {
      return A2(stringProperty,"alt",value);
   };
   var preload = function (value) {
      return A2(stringProperty,"preload",value);
   };
   var poster = function (value) {
      return A2(stringProperty,"poster",value);
   };
   var kind = function (value) {
      return A2(stringProperty,"kind",value);
   };
   var srclang = function (value) {
      return A2(stringProperty,"srclang",value);
   };
   var sandbox = function (value) {
      return A2(stringProperty,"sandbox",value);
   };
   var srcdoc = function (value) {
      return A2(stringProperty,"srcdoc",value);
   };
   var type$ = function (value) {
      return A2(stringProperty,"type",value);
   };
   var value = function (value) {
      return A2(stringProperty,"value",value);
   };
   var placeholder = function (value) {
      return A2(stringProperty,"placeholder",value);
   };
   var accept = function (value) {
      return A2(stringProperty,"accept",value);
   };
   var acceptCharset = function (value) {
      return A2(stringProperty,"acceptCharset",value);
   };
   var action = function (value) {
      return A2(stringProperty,"action",value);
   };
   var autocomplete = function (bool) {
      return A2(stringProperty,"autocomplete",bool ? "on" : "off");
   };
   var autosave = function (value) {
      return A2(stringProperty,"autosave",value);
   };
   var enctype = function (value) {
      return A2(stringProperty,"enctype",value);
   };
   var formaction = function (value) {
      return A2(stringProperty,"formAction",value);
   };
   var list = function (value) {
      return A2(stringProperty,"list",value);
   };
   var minlength = function (n) {
      return A2(stringProperty,"minLength",$Basics.toString(n));
   };
   var maxlength = function (n) {
      return A2(stringProperty,"maxLength",$Basics.toString(n));
   };
   var method = function (value) {
      return A2(stringProperty,"method",value);
   };
   var name = function (value) {
      return A2(stringProperty,"name",value);
   };
   var pattern = function (value) {
      return A2(stringProperty,"pattern",value);
   };
   var size = function (n) {
      return A2(stringProperty,"size",$Basics.toString(n));
   };
   var $for = function (value) {
      return A2(stringProperty,"htmlFor",value);
   };
   var form = function (value) {
      return A2(stringProperty,"form",value);
   };
   var max = function (value) {
      return A2(stringProperty,"max",value);
   };
   var min = function (value) {
      return A2(stringProperty,"min",value);
   };
   var step = function (n) {
      return A2(stringProperty,"step",n);
   };
   var cols = function (n) {
      return A2(stringProperty,"cols",$Basics.toString(n));
   };
   var rows = function (n) {
      return A2(stringProperty,"rows",$Basics.toString(n));
   };
   var wrap = function (value) {
      return A2(stringProperty,"wrap",value);
   };
   var usemap = function (value) {
      return A2(stringProperty,"useMap",value);
   };
   var shape = function (value) {
      return A2(stringProperty,"shape",value);
   };
   var coords = function (value) {
      return A2(stringProperty,"coords",value);
   };
   var challenge = function (value) {
      return A2(stringProperty,"challenge",value);
   };
   var keytype = function (value) {
      return A2(stringProperty,"keytype",value);
   };
   var align = function (value) {
      return A2(stringProperty,"align",value);
   };
   var cite = function (value) {
      return A2(stringProperty,"cite",value);
   };
   var href = function (value) {
      return A2(stringProperty,"href",value);
   };
   var target = function (value) {
      return A2(stringProperty,"target",value);
   };
   var downloadAs = function (value) {
      return A2(stringProperty,"download",value);
   };
   var hreflang = function (value) {
      return A2(stringProperty,"hreflang",value);
   };
   var media = function (value) {
      return A2(stringProperty,"media",value);
   };
   var ping = function (value) {
      return A2(stringProperty,"ping",value);
   };
   var rel = function (value) {
      return A2(stringProperty,"rel",value);
   };
   var datetime = function (value) {
      return A2(stringProperty,"datetime",value);
   };
   var pubdate = function (value) {
      return A2(stringProperty,"pubdate",value);
   };
   var start = function (n) {
      return A2(stringProperty,"start",$Basics.toString(n));
   };
   var colspan = function (n) {
      return A2(stringProperty,"colSpan",$Basics.toString(n));
   };
   var headers = function (value) {
      return A2(stringProperty,"headers",value);
   };
   var rowspan = function (n) {
      return A2(stringProperty,"rowSpan",$Basics.toString(n));
   };
   var scope = function (value) {
      return A2(stringProperty,"scope",value);
   };
   var manifest = function (value) {
      return A2(stringProperty,"manifest",value);
   };
   var boolProperty = F2(function (name,bool) {
      return A2(property,name,$Json$Encode.bool(bool));
   });
   var hidden = function (bool) {
      return A2(boolProperty,"hidden",bool);
   };
   var contenteditable = function (bool) {
      return A2(boolProperty,"contentEditable",bool);
   };
   var spellcheck = function (bool) {
      return A2(boolProperty,"spellcheck",bool);
   };
   var async = function (bool) {
      return A2(boolProperty,"async",bool);
   };
   var defer = function (bool) {
      return A2(boolProperty,"defer",bool);
   };
   var scoped = function (bool) {
      return A2(boolProperty,"scoped",bool);
   };
   var autoplay = function (bool) {
      return A2(boolProperty,"autoplay",bool);
   };
   var controls = function (bool) {
      return A2(boolProperty,"controls",bool);
   };
   var loop = function (bool) {
      return A2(boolProperty,"loop",bool);
   };
   var $default = function (bool) {
      return A2(boolProperty,"default",bool);
   };
   var seamless = function (bool) {
      return A2(boolProperty,"seamless",bool);
   };
   var checked = function (bool) {
      return A2(boolProperty,"checked",bool);
   };
   var selected = function (bool) {
      return A2(boolProperty,"selected",bool);
   };
   var autofocus = function (bool) {
      return A2(boolProperty,"autofocus",bool);
   };
   var disabled = function (bool) {
      return A2(boolProperty,"disabled",bool);
   };
   var multiple = function (bool) {
      return A2(boolProperty,"multiple",bool);
   };
   var novalidate = function (bool) {
      return A2(boolProperty,"noValidate",bool);
   };
   var readonly = function (bool) {
      return A2(boolProperty,"readOnly",bool);
   };
   var required = function (bool) {
      return A2(boolProperty,"required",bool);
   };
   var ismap = function (value) {
      return A2(boolProperty,"isMap",value);
   };
   var download = function (bool) {
      return A2(boolProperty,"download",bool);
   };
   var reversed = function (bool) {
      return A2(boolProperty,"reversed",bool);
   };
   var classList = function (list) {
      return $class(A2($String.join,
      " ",
      A2($List.map,$Basics.fst,A2($List.filter,$Basics.snd,list))));
   };
   var style = function (props) {
      return A2(property,
      "style",
      $Json$Encode.object(A2($List.map,
      function (_p0) {
         var _p1 = _p0;
         return {ctor: "_Tuple2"
                ,_0: _p1._0
                ,_1: $Json$Encode.string(_p1._1)};
      },
      props)));
   };
   var key = function (k) {    return A2(stringProperty,"key",k);};
   return _elm.Html.Attributes.values = {_op: _op
                                        ,key: key
                                        ,style: style
                                        ,$class: $class
                                        ,classList: classList
                                        ,id: id
                                        ,title: title
                                        ,hidden: hidden
                                        ,type$: type$
                                        ,value: value
                                        ,checked: checked
                                        ,placeholder: placeholder
                                        ,selected: selected
                                        ,accept: accept
                                        ,acceptCharset: acceptCharset
                                        ,action: action
                                        ,autocomplete: autocomplete
                                        ,autofocus: autofocus
                                        ,autosave: autosave
                                        ,disabled: disabled
                                        ,enctype: enctype
                                        ,formaction: formaction
                                        ,list: list
                                        ,maxlength: maxlength
                                        ,minlength: minlength
                                        ,method: method
                                        ,multiple: multiple
                                        ,name: name
                                        ,novalidate: novalidate
                                        ,pattern: pattern
                                        ,readonly: readonly
                                        ,required: required
                                        ,size: size
                                        ,$for: $for
                                        ,form: form
                                        ,max: max
                                        ,min: min
                                        ,step: step
                                        ,cols: cols
                                        ,rows: rows
                                        ,wrap: wrap
                                        ,href: href
                                        ,target: target
                                        ,download: download
                                        ,downloadAs: downloadAs
                                        ,hreflang: hreflang
                                        ,media: media
                                        ,ping: ping
                                        ,rel: rel
                                        ,ismap: ismap
                                        ,usemap: usemap
                                        ,shape: shape
                                        ,coords: coords
                                        ,src: src
                                        ,height: height
                                        ,width: width
                                        ,alt: alt
                                        ,autoplay: autoplay
                                        ,controls: controls
                                        ,loop: loop
                                        ,preload: preload
                                        ,poster: poster
                                        ,$default: $default
                                        ,kind: kind
                                        ,srclang: srclang
                                        ,sandbox: sandbox
                                        ,seamless: seamless
                                        ,srcdoc: srcdoc
                                        ,reversed: reversed
                                        ,start: start
                                        ,align: align
                                        ,colspan: colspan
                                        ,rowspan: rowspan
                                        ,headers: headers
                                        ,scope: scope
                                        ,async: async
                                        ,charset: charset
                                        ,content: content
                                        ,defer: defer
                                        ,httpEquiv: httpEquiv
                                        ,language: language
                                        ,scoped: scoped
                                        ,accesskey: accesskey
                                        ,contenteditable: contenteditable
                                        ,contextmenu: contextmenu
                                        ,dir: dir
                                        ,draggable: draggable
                                        ,dropzone: dropzone
                                        ,itemprop: itemprop
                                        ,lang: lang
                                        ,spellcheck: spellcheck
                                        ,tabindex: tabindex
                                        ,challenge: challenge
                                        ,keytype: keytype
                                        ,cite: cite
                                        ,datetime: datetime
                                        ,pubdate: pubdate
                                        ,manifest: manifest
                                        ,property: property
                                        ,attribute: attribute};
};
Elm.Html = Elm.Html || {};
Elm.Html.Events = Elm.Html.Events || {};
Elm.Html.Events.make = function (_elm) {
   "use strict";
   _elm.Html = _elm.Html || {};
   _elm.Html.Events = _elm.Html.Events || {};
   if (_elm.Html.Events.values) return _elm.Html.Events.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $Html = Elm.Html.make(_elm),
   $Json$Decode = Elm.Json.Decode.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $VirtualDom = Elm.VirtualDom.make(_elm);
   var _op = {};
   var keyCode = A2($Json$Decode._op[":="],
   "keyCode",
   $Json$Decode.$int);
   var targetChecked = A2($Json$Decode.at,
   _U.list(["target","checked"]),
   $Json$Decode.bool);
   var targetValue = A2($Json$Decode.at,
   _U.list(["target","value"]),
   $Json$Decode.string);
   var defaultOptions = $VirtualDom.defaultOptions;
   var Options = F2(function (a,b) {
      return {stopPropagation: a,preventDefault: b};
   });
   var onWithOptions = $VirtualDom.onWithOptions;
   var on = $VirtualDom.on;
   var messageOn = F3(function (name,addr,msg) {
      return A3(on,
      name,
      $Json$Decode.value,
      function (_p0) {
         return A2($Signal.message,addr,msg);
      });
   });
   var onClick = messageOn("click");
   var onDoubleClick = messageOn("dblclick");
   var onMouseMove = messageOn("mousemove");
   var onMouseDown = messageOn("mousedown");
   var onMouseUp = messageOn("mouseup");
   var onMouseEnter = messageOn("mouseenter");
   var onMouseLeave = messageOn("mouseleave");
   var onMouseOver = messageOn("mouseover");
   var onMouseOut = messageOn("mouseout");
   var onBlur = messageOn("blur");
   var onFocus = messageOn("focus");
   var onSubmit = messageOn("submit");
   var onKey = F3(function (name,addr,handler) {
      return A3(on,
      name,
      keyCode,
      function (code) {
         return A2($Signal.message,addr,handler(code));
      });
   });
   var onKeyUp = onKey("keyup");
   var onKeyDown = onKey("keydown");
   var onKeyPress = onKey("keypress");
   return _elm.Html.Events.values = {_op: _op
                                    ,onBlur: onBlur
                                    ,onFocus: onFocus
                                    ,onSubmit: onSubmit
                                    ,onKeyUp: onKeyUp
                                    ,onKeyDown: onKeyDown
                                    ,onKeyPress: onKeyPress
                                    ,onClick: onClick
                                    ,onDoubleClick: onDoubleClick
                                    ,onMouseMove: onMouseMove
                                    ,onMouseDown: onMouseDown
                                    ,onMouseUp: onMouseUp
                                    ,onMouseEnter: onMouseEnter
                                    ,onMouseLeave: onMouseLeave
                                    ,onMouseOver: onMouseOver
                                    ,onMouseOut: onMouseOut
                                    ,on: on
                                    ,onWithOptions: onWithOptions
                                    ,defaultOptions: defaultOptions
                                    ,targetValue: targetValue
                                    ,targetChecked: targetChecked
                                    ,keyCode: keyCode
                                    ,Options: Options};
};
Elm.Native.Http = {};
Elm.Native.Http.make = function(localRuntime) {

	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Http = localRuntime.Native.Http || {};
	if (localRuntime.Native.Http.values)
	{
		return localRuntime.Native.Http.values;
	}

	var Dict = Elm.Dict.make(localRuntime);
	var List = Elm.List.make(localRuntime);
	var Maybe = Elm.Maybe.make(localRuntime);
	var Task = Elm.Native.Task.make(localRuntime);


	function send(settings, request)
	{
		return Task.asyncFunction(function(callback) {
			var req = new XMLHttpRequest();

			// start
			if (settings.onStart.ctor === 'Just')
			{
				req.addEventListener('loadStart', function() {
					var task = settings.onStart._0;
					Task.spawn(task);
				});
			}

			// progress
			if (settings.onProgress.ctor === 'Just')
			{
				req.addEventListener('progress', function(event) {
					var progress = !event.lengthComputable
						? Maybe.Nothing
						: Maybe.Just({
							_: {},
							loaded: event.loaded,
							total: event.total
						});
					var task = settings.onProgress._0(progress);
					Task.spawn(task);
				});
			}

			// end
			req.addEventListener('error', function() {
				return callback(Task.fail({ ctor: 'RawNetworkError' }));
			});

			req.addEventListener('timeout', function() {
				return callback(Task.fail({ ctor: 'RawTimeout' }));
			});

			req.addEventListener('load', function() {
				return callback(Task.succeed(toResponse(req)));
			});

			req.open(request.verb, request.url, true);

			// set all the headers
			function setHeader(pair) {
				req.setRequestHeader(pair._0, pair._1);
			}
			A2(List.map, setHeader, request.headers);

			// set the timeout
			req.timeout = settings.timeout;

			// enable this withCredentials thing
			req.withCredentials = settings.withCredentials;

			// ask for a specific MIME type for the response
			if (settings.desiredResponseType.ctor === 'Just')
			{
				req.overrideMimeType(settings.desiredResponseType._0);
			}

			// actuall send the request
			if(request.body.ctor === "BodyFormData")
			{
				req.send(request.body.formData)
			}
			else
			{
				req.send(request.body._0);
			}
		});
	}


	// deal with responses

	function toResponse(req)
	{
		var tag = req.responseType === 'blob' ? 'Blob' : 'Text'
		var response = tag === 'Blob' ? req.response : req.responseText;
		return {
			_: {},
			status: req.status,
			statusText: req.statusText,
			headers: parseHeaders(req.getAllResponseHeaders()),
			url: req.responseURL,
			value: { ctor: tag, _0: response }
		};
	}


	function parseHeaders(rawHeaders)
	{
		var headers = Dict.empty;

		if (!rawHeaders)
		{
			return headers;
		}

		var headerPairs = rawHeaders.split('\u000d\u000a');
		for (var i = headerPairs.length; i--; )
		{
			var headerPair = headerPairs[i];
			var index = headerPair.indexOf('\u003a\u0020');
			if (index > 0)
			{
				var key = headerPair.substring(0, index);
				var value = headerPair.substring(index + 2);

				headers = A3(Dict.update, key, function(oldValue) {
					if (oldValue.ctor === 'Just')
					{
						return Maybe.Just(value + ', ' + oldValue._0);
					}
					return Maybe.Just(value);
				}, headers);
			}
		}

		return headers;
	}


	function multipart(dataList)
	{
		var formData = new FormData();

		while (dataList.ctor !== '[]')
		{
			var data = dataList._0;
			if (data.ctor === 'StringData')
			{
				formData.append(data._0, data._1);
			}
			else
			{
				var fileName = data._1.ctor === 'Nothing'
					? undefined
					: data._1._0;
				formData.append(data._0, data._2, fileName);
			}
			dataList = dataList._1;
		}

		return { ctor: 'BodyFormData', formData: formData };
	}


	function uriEncode(string)
	{
		return encodeURIComponent(string);
	}

	function uriDecode(string)
	{
		return decodeURIComponent(string);
	}

	return localRuntime.Native.Http.values = {
		send: F2(send),
		multipart: multipart,
		uriEncode: uriEncode,
		uriDecode: uriDecode
	};
};

Elm.Http = Elm.Http || {};
Elm.Http.make = function (_elm) {
   "use strict";
   _elm.Http = _elm.Http || {};
   if (_elm.Http.values) return _elm.Http.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $Dict = Elm.Dict.make(_elm),
   $Json$Decode = Elm.Json.Decode.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Native$Http = Elm.Native.Http.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $String = Elm.String.make(_elm),
   $Task = Elm.Task.make(_elm),
   $Time = Elm.Time.make(_elm);
   var _op = {};
   var send = $Native$Http.send;
   var BadResponse = F2(function (a,b) {
      return {ctor: "BadResponse",_0: a,_1: b};
   });
   var UnexpectedPayload = function (a) {
      return {ctor: "UnexpectedPayload",_0: a};
   };
   var handleResponse = F2(function (handle,response) {
      if (_U.cmp(200,
      response.status) < 1 && _U.cmp(response.status,300) < 0) {
            var _p0 = response.value;
            if (_p0.ctor === "Text") {
                  return handle(_p0._0);
               } else {
                  return $Task.fail(UnexpectedPayload("Response body is a blob, expecting a string."));
               }
         } else return $Task.fail(A2(BadResponse,
         response.status,
         response.statusText));
   });
   var NetworkError = {ctor: "NetworkError"};
   var Timeout = {ctor: "Timeout"};
   var promoteError = function (rawError) {
      var _p1 = rawError;
      if (_p1.ctor === "RawTimeout") {
            return Timeout;
         } else {
            return NetworkError;
         }
   };
   var fromJson = F2(function (decoder,response) {
      var decode = function (str) {
         var _p2 = A2($Json$Decode.decodeString,decoder,str);
         if (_p2.ctor === "Ok") {
               return $Task.succeed(_p2._0);
            } else {
               return $Task.fail(UnexpectedPayload(_p2._0));
            }
      };
      return A2($Task.andThen,
      A2($Task.mapError,promoteError,response),
      handleResponse(decode));
   });
   var RawNetworkError = {ctor: "RawNetworkError"};
   var RawTimeout = {ctor: "RawTimeout"};
   var Blob = function (a) {    return {ctor: "Blob",_0: a};};
   var Text = function (a) {    return {ctor: "Text",_0: a};};
   var Response = F5(function (a,b,c,d,e) {
      return {status: a,statusText: b,headers: c,url: d,value: e};
   });
   var defaultSettings = {timeout: 0
                         ,onStart: $Maybe.Nothing
                         ,onProgress: $Maybe.Nothing
                         ,desiredResponseType: $Maybe.Nothing
                         ,withCredentials: false};
   var post = F3(function (decoder,url,body) {
      var request = {verb: "POST"
                    ,headers: _U.list([])
                    ,url: url
                    ,body: body};
      return A2(fromJson,decoder,A2(send,defaultSettings,request));
   });
   var Settings = F5(function (a,b,c,d,e) {
      return {timeout: a
             ,onStart: b
             ,onProgress: c
             ,desiredResponseType: d
             ,withCredentials: e};
   });
   var multipart = $Native$Http.multipart;
   var FileData = F3(function (a,b,c) {
      return {ctor: "FileData",_0: a,_1: b,_2: c};
   });
   var BlobData = F3(function (a,b,c) {
      return {ctor: "BlobData",_0: a,_1: b,_2: c};
   });
   var blobData = BlobData;
   var StringData = F2(function (a,b) {
      return {ctor: "StringData",_0: a,_1: b};
   });
   var stringData = StringData;
   var BodyBlob = function (a) {
      return {ctor: "BodyBlob",_0: a};
   };
   var BodyFormData = {ctor: "BodyFormData"};
   var ArrayBuffer = {ctor: "ArrayBuffer"};
   var BodyString = function (a) {
      return {ctor: "BodyString",_0: a};
   };
   var string = BodyString;
   var Empty = {ctor: "Empty"};
   var empty = Empty;
   var getString = function (url) {
      var request = {verb: "GET"
                    ,headers: _U.list([])
                    ,url: url
                    ,body: empty};
      return A2($Task.andThen,
      A2($Task.mapError,
      promoteError,
      A2(send,defaultSettings,request)),
      handleResponse($Task.succeed));
   };
   var get = F2(function (decoder,url) {
      var request = {verb: "GET"
                    ,headers: _U.list([])
                    ,url: url
                    ,body: empty};
      return A2(fromJson,decoder,A2(send,defaultSettings,request));
   });
   var Request = F4(function (a,b,c,d) {
      return {verb: a,headers: b,url: c,body: d};
   });
   var uriDecode = $Native$Http.uriDecode;
   var uriEncode = $Native$Http.uriEncode;
   var queryEscape = function (string) {
      return A2($String.join,
      "+",
      A2($String.split,"%20",uriEncode(string)));
   };
   var queryPair = function (_p3) {
      var _p4 = _p3;
      return A2($Basics._op["++"],
      queryEscape(_p4._0),
      A2($Basics._op["++"],"=",queryEscape(_p4._1)));
   };
   var url = F2(function (baseUrl,args) {
      var _p5 = args;
      if (_p5.ctor === "[]") {
            return baseUrl;
         } else {
            return A2($Basics._op["++"],
            baseUrl,
            A2($Basics._op["++"],
            "?",
            A2($String.join,"&",A2($List.map,queryPair,args))));
         }
   });
   var TODO_implement_file_in_another_library = {ctor: "TODO_implement_file_in_another_library"};
   var TODO_implement_blob_in_another_library = {ctor: "TODO_implement_blob_in_another_library"};
   return _elm.Http.values = {_op: _op
                             ,getString: getString
                             ,get: get
                             ,post: post
                             ,send: send
                             ,url: url
                             ,uriEncode: uriEncode
                             ,uriDecode: uriDecode
                             ,empty: empty
                             ,string: string
                             ,multipart: multipart
                             ,stringData: stringData
                             ,defaultSettings: defaultSettings
                             ,fromJson: fromJson
                             ,Request: Request
                             ,Settings: Settings
                             ,Response: Response
                             ,Text: Text
                             ,Blob: Blob
                             ,Timeout: Timeout
                             ,NetworkError: NetworkError
                             ,UnexpectedPayload: UnexpectedPayload
                             ,BadResponse: BadResponse
                             ,RawTimeout: RawTimeout
                             ,RawNetworkError: RawNetworkError};
};
Elm.StartApp = Elm.StartApp || {};
Elm.StartApp.make = function (_elm) {
   "use strict";
   _elm.StartApp = _elm.StartApp || {};
   if (_elm.StartApp.values) return _elm.StartApp.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $Effects = Elm.Effects.make(_elm),
   $Html = Elm.Html.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $Task = Elm.Task.make(_elm);
   var _op = {};
   var start = function (config) {
      var updateStep = F2(function (action,_p0) {
         var _p1 = _p0;
         var _p2 = A2(config.update,action,_p1._0);
         var newModel = _p2._0;
         var additionalEffects = _p2._1;
         return {ctor: "_Tuple2"
                ,_0: newModel
                ,_1: $Effects.batch(_U.list([_p1._1,additionalEffects]))};
      });
      var update = F2(function (actions,_p3) {
         var _p4 = _p3;
         return A3($List.foldl,
         updateStep,
         {ctor: "_Tuple2",_0: _p4._0,_1: $Effects.none},
         actions);
      });
      var messages = $Signal.mailbox(_U.list([]));
      var singleton = function (action) {
         return _U.list([action]);
      };
      var address = A2($Signal.forwardTo,messages.address,singleton);
      var inputs = $Signal.mergeMany(A2($List._op["::"],
      messages.signal,
      A2($List.map,$Signal.map(singleton),config.inputs)));
      var effectsAndModel = A3($Signal.foldp,
      update,
      config.init,
      inputs);
      var model = A2($Signal.map,$Basics.fst,effectsAndModel);
      return {html: A2($Signal.map,config.view(address),model)
             ,model: model
             ,tasks: A2($Signal.map,
             function (_p5) {
                return A2($Effects.toTask,messages.address,$Basics.snd(_p5));
             },
             effectsAndModel)};
   };
   var App = F3(function (a,b,c) {
      return {html: a,model: b,tasks: c};
   });
   var Config = F4(function (a,b,c,d) {
      return {init: a,update: b,view: c,inputs: d};
   });
   return _elm.StartApp.values = {_op: _op
                                 ,start: start
                                 ,Config: Config
                                 ,App: App};
};
Elm.Equipments = Elm.Equipments || {};
Elm.Equipments.make = function (_elm) {
   "use strict";
   _elm.Equipments = _elm.Equipments || {};
   if (_elm.Equipments.values) return _elm.Equipments.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm);
   var _op = {};
   var position = function (equipment) {
      var _p0 = equipment;
      return {ctor: "_Tuple2",_0: _p0._1._0,_1: _p0._1._1};
   };
   var Desk = F4(function (a,b,c,d) {
      return {ctor: "Desk",_0: a,_1: b,_2: c,_3: d};
   });
   var init = Desk;
   var copy = F3(function (newId,_p1,equipment) {
      var _p2 = _p1;
      var _p3 = equipment;
      return A4(Desk,
      newId,
      {ctor: "_Tuple4"
      ,_0: _p2._0
      ,_1: _p2._1
      ,_2: _p3._1._2
      ,_3: _p3._1._3},
      _p3._2,
      _p3._3);
   });
   return _elm.Equipments.values = {_op: _op
                                   ,init: init
                                   ,copy: copy
                                   ,position: position
                                   ,Desk: Desk};
};
Elm.Util = Elm.Util || {};
Elm.Util.ListUtil = Elm.Util.ListUtil || {};
Elm.Util.ListUtil.make = function (_elm) {
   "use strict";
   _elm.Util = _elm.Util || {};
   _elm.Util.ListUtil = _elm.Util.ListUtil || {};
   if (_elm.Util.ListUtil.values) return _elm.Util.ListUtil.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $List = Elm.List.make(_elm),
   $List$Extra = Elm.List.Extra.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm);
   var _op = {};
   var getAt = F2(function (index,list) {
      return A2($List$Extra.getAt,list,index);
   });
   var zipWithIndexFrom = F2(function (index,list) {
      var _p0 = list;
      if (_p0.ctor === "::") {
            return A2($List._op["::"],
            {ctor: "_Tuple2",_0: _p0._0,_1: index},
            A2(zipWithIndexFrom,index + 1,_p0._1));
         } else {
            return _U.list([]);
         }
   });
   var zipWithIndex = zipWithIndexFrom(0);
   var findBy = F2(function (f,list) {
      return $List.head(A2($List.filter,f,list));
   });
   return _elm.Util.ListUtil.values = {_op: _op
                                      ,findBy: findBy
                                      ,zipWithIndex: zipWithIndex
                                      ,zipWithIndexFrom: zipWithIndexFrom
                                      ,getAt: getAt};
};
Elm.EquipmentsOperation = Elm.EquipmentsOperation || {};
Elm.EquipmentsOperation.make = function (_elm) {
   "use strict";
   _elm.EquipmentsOperation = _elm.EquipmentsOperation || {};
   if (_elm.EquipmentsOperation.values)
   return _elm.EquipmentsOperation.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $Equipments = Elm.Equipments.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $Util$ListUtil = Elm.Util.ListUtil.make(_elm);
   var _op = {};
   var colorOf = function (_p0) {    var _p1 = _p0;return _p1._2;};
   var colorProperty = function (equipments) {
      var _p2 = $List.head(equipments);
      if (_p2.ctor === "Just") {
            var firstColor = colorOf(_p2._0);
            return A3($List.foldl,
            F2(function (e,maybeColor) {
               var color = colorOf(e);
               var _p3 = maybeColor;
               if (_p3.ctor === "Just") {
                     return _U.eq(color,
                     _p3._0) ? $Maybe.Just(color) : $Maybe.Nothing;
                  } else {
                     return $Maybe.Nothing;
                  }
            }),
            $Maybe.Just(firstColor),
            equipments);
         } else {
            return $Maybe.Nothing;
         }
   };
   var nameOf = function (_p4) {    var _p5 = _p4;return _p5._3;};
   var idOf = function (_p6) {    var _p7 = _p6;return _p7._0;};
   var changeName = F2(function (name,_p8) {
      var _p9 = _p8;
      return A4($Equipments.Desk,_p9._0,_p9._1,_p9._2,name);
   });
   var changeColor = F2(function (color,_p10) {
      var _p11 = _p10;
      return A4($Equipments.Desk,_p11._0,_p11._1,color,_p11._3);
   });
   var fitToGrid = F2(function (gridSize,_p12) {
      var _p13 = _p12;
      return {ctor: "_Tuple2"
             ,_0: (_p13._0 / gridSize | 0) * gridSize
             ,_1: (_p13._1 / gridSize | 0) * gridSize};
   });
   var findEquipmentById = F2(function (equipments,id) {
      return A2($Util$ListUtil.findBy,
      function (equipment) {
         return _U.eq(id,idOf(equipment));
      },
      equipments);
   });
   var rotate = function (_p14) {
      var _p15 = _p14;
      return A4($Equipments.Desk,
      _p15._0,
      {ctor: "_Tuple4"
      ,_0: _p15._1._0
      ,_1: _p15._1._1
      ,_2: _p15._1._3
      ,_3: _p15._1._2},
      _p15._2,
      _p15._3);
   };
   var partiallyChange = F3(function (f,ids,equipments) {
      return A2($List.map,
      function (e) {
         return A2($List.member,idOf(e),ids) ? f(e) : e;
      },
      equipments);
   });
   var moveEquipments = F4(function (gridSize,
   _p16,
   ids,
   equipments) {
      var _p17 = _p16;
      return A3(partiallyChange,
      function (_p18) {
         var _p19 = _p18;
         var _p20 = A2(fitToGrid,
         gridSize,
         {ctor: "_Tuple2"
         ,_0: _p19._1._0 + _p17._0
         ,_1: _p19._1._1 + _p17._1});
         var newX = _p20._0;
         var newY = _p20._1;
         return A4($Equipments.Desk,
         _p19._0,
         {ctor: "_Tuple4"
         ,_0: newX
         ,_1: newY
         ,_2: _p19._1._2
         ,_3: _p19._1._3},
         _p19._2,
         _p19._3);
      },
      ids,
      equipments);
   });
   var commitInputName = F2(function (_p21,equipments) {
      var _p22 = _p21;
      return A3(partiallyChange,
      changeName(_p22._1),
      _U.list([_p22._0]),
      equipments);
   });
   var pasteEquipments = F3(function (_p23,
   copiedWithNewIds,
   allEquipments) {
      var _p24 = _p23;
      var _p25 = A3($List.foldl,
      F2(function (_p27,_p26) {
         var _p28 = _p27;
         var _p29 = _p26;
         var _p30 = $Equipments.position(_p28._0);
         var x = _p30._0;
         var y = _p30._1;
         return {ctor: "_Tuple2"
                ,_0: A2($Basics.min,_p29._0,x)
                ,_1: A2($Basics.min,_p29._1,y)};
      }),
      {ctor: "_Tuple2",_0: 99999,_1: 99999},
      copiedWithNewIds);
      var minX = _p25._0;
      var minY = _p25._1;
      var newEquipments = A2($List.map,
      function (_p31) {
         var _p32 = _p31;
         var _p34 = _p32._0;
         var _p33 = $Equipments.position(_p34);
         var x = _p33._0;
         var y = _p33._1;
         return A3($Equipments.copy,
         _p32._1,
         {ctor: "_Tuple2"
         ,_0: _p24._0 + (x - minX)
         ,_1: _p24._1 + (y - minY)},
         _p34);
      },
      copiedWithNewIds);
      return newEquipments;
   });
   var Down = {ctor: "Down"};
   var Right = {ctor: "Right"};
   var Left = {ctor: "Left"};
   var Up = {ctor: "Up"};
   var opposite = function (direction) {
      var _p35 = direction;
      switch (_p35.ctor)
      {case "Left": return Right;
         case "Right": return Left;
         case "Up": return Down;
         default: return Up;}
   };
   var linked = F2(function (_p37,_p36) {
      var _p38 = _p37;
      var _p43 = _p38._1;
      var _p42 = _p38._0;
      var _p39 = _p36;
      var _p41 = _p39._1;
      var _p40 = _p39._0;
      return _U.cmp(_p42,_p40 + _p39._2) < 1 && (_U.cmp(_p40,
      _p42 + _p38._2) < 1 && (_U.cmp(_p43,
      _p41 + _p39._3) < 1 && _U.cmp(_p41,_p43 + _p38._3) < 1));
   });
   var rect = function (_p44) {
      var _p45 = _p44;
      return _p45._1;
   };
   var rectFloat = function (e) {
      var _p46 = rect(e);
      var x = _p46._0;
      var y = _p46._1;
      var w = _p46._2;
      var h = _p46._3;
      return {ctor: "_Tuple4"
             ,_0: $Basics.toFloat(x)
             ,_1: $Basics.toFloat(y)
             ,_2: $Basics.toFloat(w)
             ,_3: $Basics.toFloat(h)};
   };
   var center = function (e) {
      var _p47 = rectFloat(e);
      var x = _p47._0;
      var y = _p47._1;
      var w = _p47._2;
      var h = _p47._3;
      return {ctor: "_Tuple2",_0: x + w / 2,_1: y + h / 2};
   };
   var compareBy = F3(function (direction,from,$new) {
      var _p48 = center($new);
      var newCenterX = _p48._0;
      var newCenterY = _p48._1;
      var _p49 = center(from);
      var centerX = _p49._0;
      var centerY = _p49._1;
      if (_U.eq({ctor: "_Tuple2",_0: centerX,_1: centerY},
      {ctor: "_Tuple2",_0: newCenterX,_1: newCenterY}))
      return $Basics.EQ; else {
            var greater = function () {
               var _p50 = direction;
               switch (_p50.ctor)
               {case "Up": return _U.cmp(newCenterX,
                    centerX) < 0 || _U.eq(newCenterX,centerX) && _U.cmp(newCenterY,
                    centerY) < 0;
                  case "Down": return _U.cmp(newCenterX,
                    centerX) > 0 || _U.eq(newCenterX,centerX) && _U.cmp(newCenterY,
                    centerY) > 0;
                  case "Left": return _U.cmp(newCenterY,
                    centerY) < 0 || _U.eq(newCenterY,centerY) && _U.cmp(newCenterX,
                    centerX) < 0;
                  default: return _U.cmp(newCenterY,
                    centerY) > 0 || _U.eq(newCenterY,centerY) && _U.cmp(newCenterX,
                    centerX) > 0;}
            }();
            return greater ? $Basics.GT : $Basics.LT;
         }
   });
   var lessBy = F3(function (direction,from,$new) {
      return _U.eq(A3(compareBy,direction,from,$new),$Basics.LT);
   });
   var minimumBy = F2(function (direction,list) {
      var f = F2(function (e1,memo) {
         var _p51 = memo;
         if (_p51.ctor === "Just") {
               var _p52 = _p51._0;
               return A3(lessBy,
               direction,
               _p52,
               e1) ? $Maybe.Just(e1) : $Maybe.Just(_p52);
            } else {
               return $Maybe.Just(e1);
            }
      });
      return A3($List.foldl,f,$Maybe.Nothing,list);
   });
   var greaterBy = F3(function (direction,from,$new) {
      return _U.eq(A3(compareBy,direction,from,$new),$Basics.GT);
   });
   var filterCandidate = F3(function (direction,from,$new) {
      return A3(greaterBy,direction,from,$new);
   });
   var nearest = F3(function (direction,from,list) {
      var filtered = A2($List.filter,
      A2(filterCandidate,direction,from),
      list);
      return $List.isEmpty(filtered) ? A2(minimumBy,
      direction,
      list) : A2(minimumBy,direction,filtered);
   });
   var withinRange = F2(function (range,list) {
      var _p53 = range;
      var start = _p53._0;
      var end = _p53._1;
      var _p54 = center(start);
      var startX = _p54._0;
      var startY = _p54._1;
      var _p55 = center(end);
      var endX = _p55._0;
      var endY = _p55._1;
      var left = A2($Basics.min,startX,endX);
      var right = A2($Basics.max,startX,endX);
      var top = A2($Basics.min,startY,endY);
      var bottom = A2($Basics.max,startY,endY);
      var isContained = function (e) {
         var _p56 = center(e);
         var centerX = _p56._0;
         var centerY = _p56._1;
         return _U.cmp(centerX,left) > -1 && (_U.cmp(centerX,
         right) < 1 && (_U.cmp(centerY,top) > -1 && _U.cmp(centerY,
         bottom) < 1));
      };
      return A2($List.filter,isContained,list);
   });
   var linkedByAnyOf = F2(function (list,newEquipment) {
      return A2($List.any,
      function (e) {
         return A2(linked,rect(e),rect(newEquipment));
      },
      list);
   });
   var island = F2(function (current,rest) {
      island: while (true) {
         var _p57 = A2($List.partition,linkedByAnyOf(current),rest);
         var newEquipments = _p57._0;
         var rest$ = _p57._1;
         if ($List.isEmpty(newEquipments)) return A2($Basics._op["++"],
            current,
            newEquipments); else {
               var _v22 = A2($Basics._op["++"],current,newEquipments),
               _v23 = rest$;
               current = _v22;
               rest = _v23;
               continue island;
            }
      }
   });
   var bounds = function (list) {
      var f = F2(function (e1,memo) {
         var _p58 = rect(e1);
         var x1 = _p58._0;
         var y1 = _p58._1;
         var w1 = _p58._2;
         var h1 = _p58._3;
         var right1 = x1 + w1;
         var bottom1 = y1 + h1;
         var _p59 = memo;
         if (_p59.ctor === "Just") {
               return $Maybe.Just({ctor: "_Tuple4"
                                  ,_0: A2($Basics.min,_p59._0._0,x1)
                                  ,_1: A2($Basics.min,_p59._0._1,y1)
                                  ,_2: A2($Basics.max,_p59._0._2,right1)
                                  ,_3: A2($Basics.max,_p59._0._3,bottom1)});
            } else {
               return $Maybe.Just({ctor: "_Tuple4"
                                  ,_0: x1
                                  ,_1: y1
                                  ,_2: right1
                                  ,_3: bottom1});
            }
      });
      return A3($List.foldl,f,$Maybe.Nothing,list);
   };
   var bound = F2(function (direction,equipment) {
      var _p60 = rect(equipment);
      var left = _p60._0;
      var top = _p60._1;
      var w = _p60._2;
      var h = _p60._3;
      var right = left + w;
      var bottom = top + h;
      var _p61 = direction;
      switch (_p61.ctor)
      {case "Up": return top;
         case "Down": return bottom;
         case "Left": return left;
         default: return right;}
   });
   var compareBoundBy = F3(function (direction,e1,e2) {
      var _p62 = rect(e2);
      var left2 = _p62._0;
      var top2 = _p62._1;
      var w2 = _p62._2;
      var h2 = _p62._3;
      var right2 = left2 + w2;
      var bottom2 = top2 + h2;
      var _p63 = rect(e1);
      var left1 = _p63._0;
      var top1 = _p63._1;
      var w1 = _p63._2;
      var h1 = _p63._3;
      var right1 = left1 + w1;
      var bottom1 = top1 + h1;
      var _p64 = direction;
      switch (_p64.ctor)
      {case "Up": return _U.eq(top1,top2) ? $Basics.EQ : _U.cmp(top1,
           top2) < 0 ? $Basics.GT : $Basics.LT;
         case "Down": return _U.eq(bottom1,
           bottom2) ? $Basics.EQ : _U.cmp(bottom1,
           bottom2) > 0 ? $Basics.GT : $Basics.LT;
         case "Left": return _U.eq(left1,
           left2) ? $Basics.EQ : _U.cmp(left1,
           left2) < 0 ? $Basics.GT : $Basics.LT;
         default: return _U.eq(right1,
           right2) ? $Basics.EQ : _U.cmp(right1,
           right2) > 0 ? $Basics.GT : $Basics.LT;}
   });
   var minimumPartsOf = F2(function (direction,list) {
      var f = F2(function (e,memo) {
         var _p65 = memo;
         if (_p65.ctor === "::") {
               var _p66 = A3(compareBoundBy,direction,e,_p65._0);
               switch (_p66.ctor)
               {case "LT": return _U.list([e]);
                  case "EQ": return A2($List._op["::"],e,memo);
                  default: return memo;}
            } else {
               return _U.list([e]);
            }
      });
      return A3($List.foldl,f,_U.list([]),list);
   });
   var restOfMinimumPartsOf = F2(function (direction,list) {
      var minimumParts = A2(minimumPartsOf,direction,list);
      return A2($List.filter,
      function (e) {
         return $Basics.not(A2($List.member,e,minimumParts));
      },
      list);
   });
   var maximumPartsOf = F2(function (direction,list) {
      var f = F2(function (e,memo) {
         var _p67 = memo;
         if (_p67.ctor === "::") {
               var _p68 = A3(compareBoundBy,direction,e,_p67._0);
               switch (_p68.ctor)
               {case "LT": return memo;
                  case "EQ": return A2($List._op["::"],e,memo);
                  default: return _U.list([e]);}
            } else {
               return _U.list([e]);
            }
      });
      return A3($List.foldl,f,_U.list([]),list);
   });
   var restOfMaximumPartsOf = F2(function (direction,list) {
      var maximumParts = A2(maximumPartsOf,direction,list);
      return A2($List.filter,
      function (e) {
         return $Basics.not(A2($List.member,e,maximumParts));
      },
      list);
   });
   var expandOrShrink = F4(function (direction,
   primary,
   current,
   all) {
      var _p69 = rect(primary);
      var left0 = _p69._0;
      var top0 = _p69._1;
      var w0 = _p69._2;
      var h0 = _p69._3;
      var right0 = left0 + w0;
      var bottom0 = top0 + h0;
      var _p70 = A2($Maybe.withDefault,
      {ctor: "_Tuple4",_0: left0,_1: top0,_2: right0,_3: bottom0},
      bounds(current));
      var left = _p70._0;
      var top = _p70._1;
      var right = _p70._2;
      var bottom = _p70._3;
      var isExpand = function () {
         var _p71 = direction;
         switch (_p71.ctor)
         {case "Up": return _U.eq(bottom,bottom0) && _U.cmp(top,
              top0) < 1;
            case "Down": return _U.eq(top,top0) && _U.cmp(bottom,
              bottom0) > -1;
            case "Left": return _U.eq(right,right0) && _U.cmp(left,
              left0) < 1;
            default: return _U.eq(left,left0) && _U.cmp(right,right0) > -1;}
      }();
      if (isExpand) {
            var filter = function (e1) {
               var _p72 = rect(e1);
               var left1 = _p72._0;
               var top1 = _p72._1;
               var w1 = _p72._2;
               var h1 = _p72._3;
               var right1 = left1 + w1;
               var bottom1 = top1 + h1;
               var _p73 = direction;
               switch (_p73.ctor)
               {case "Up": return _U.cmp(left1,left) > -1 && (_U.cmp(right1,
                    right) < 1 && _U.cmp(top1,top) < 0);
                  case "Down": return _U.cmp(left1,left) > -1 && (_U.cmp(right1,
                    right) < 1 && _U.cmp(bottom1,bottom) > 0);
                  case "Left": return _U.cmp(top1,top) > -1 && (_U.cmp(bottom1,
                    bottom) < 1 && _U.cmp(left1,left) < 0);
                  default: return _U.cmp(top1,top) > -1 && (_U.cmp(bottom1,
                    bottom) < 1 && _U.cmp(right1,right) > 0);}
            };
            var filtered = A2($List.filter,filter,all);
            return A2($Basics._op["++"],
            current,
            A2(minimumPartsOf,direction,filtered));
         } else return A2(restOfMaximumPartsOf,
         opposite(direction),
         current);
   });
   return _elm.EquipmentsOperation.values = {_op: _op
                                            ,rect: rect
                                            ,rectFloat: rectFloat
                                            ,center: center
                                            ,linked: linked
                                            ,linkedByAnyOf: linkedByAnyOf
                                            ,island: island
                                            ,Up: Up
                                            ,Left: Left
                                            ,Right: Right
                                            ,Down: Down
                                            ,opposite: opposite
                                            ,compareBy: compareBy
                                            ,lessBy: lessBy
                                            ,greaterBy: greaterBy
                                            ,minimumBy: minimumBy
                                            ,filterCandidate: filterCandidate
                                            ,nearest: nearest
                                            ,withinRange: withinRange
                                            ,bounds: bounds
                                            ,bound: bound
                                            ,compareBoundBy: compareBoundBy
                                            ,minimumPartsOf: minimumPartsOf
                                            ,maximumPartsOf: maximumPartsOf
                                            ,restOfMinimumPartsOf: restOfMinimumPartsOf
                                            ,restOfMaximumPartsOf: restOfMaximumPartsOf
                                            ,expandOrShrink: expandOrShrink
                                            ,pasteEquipments: pasteEquipments
                                            ,partiallyChange: partiallyChange
                                            ,rotate: rotate
                                            ,moveEquipments: moveEquipments
                                            ,findEquipmentById: findEquipmentById
                                            ,fitToGrid: fitToGrid
                                            ,changeColor: changeColor
                                            ,changeName: changeName
                                            ,idOf: idOf
                                            ,nameOf: nameOf
                                            ,colorOf: colorOf
                                            ,commitInputName: commitInputName
                                            ,colorProperty: colorProperty};
};
Elm.Util = Elm.Util || {};
Elm.Util.HtmlEvent = Elm.Util.HtmlEvent || {};
Elm.Util.HtmlEvent.make = function (_elm) {
   "use strict";
   _elm.Util = _elm.Util || {};
   _elm.Util.HtmlEvent = _elm.Util.HtmlEvent || {};
   if (_elm.Util.HtmlEvent.values)
   return _elm.Util.HtmlEvent.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $Json$Decode = Elm.Json.Decode.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm);
   var _op = {};
   var decodeKeyboardEvent = A4($Json$Decode.object3,
   F3(function (keyCode,ctrlKey,shiftKey) {
      return {keyCode: keyCode
             ,ctrlKey: ctrlKey
             ,shiftKey: shiftKey};
   }),
   A2($Json$Decode._op[":="],"keyCode",$Json$Decode.$int),
   A2($Json$Decode._op[":="],"ctrlKey",$Json$Decode.bool),
   A2($Json$Decode._op[":="],"shiftKey",$Json$Decode.bool));
   var decodeMousePosition = A7($Json$Decode.object6,
   F6(function (clientX,clientY,layerX,layerY,ctrl,shift) {
      return {clientX: clientX
             ,clientY: clientY
             ,layerX: layerX
             ,layerY: layerY
             ,ctrlKey: ctrl
             ,shiftKey: shift};
   }),
   A2($Json$Decode._op[":="],"clientX",$Json$Decode.$int),
   A2($Json$Decode._op[":="],"clientY",$Json$Decode.$int),
   A2($Json$Decode._op[":="],"layerX",$Json$Decode.$int),
   A2($Json$Decode._op[":="],"layerY",$Json$Decode.$int),
   A2($Json$Decode._op[":="],"ctrlKey",$Json$Decode.bool),
   A2($Json$Decode._op[":="],"shiftKey",$Json$Decode.bool));
   var KeyboardEvent = F3(function (a,b,c) {
      return {keyCode: a,ctrlKey: b,shiftKey: c};
   });
   var MouseEvent = F6(function (a,b,c,d,e,f) {
      return {clientX: a
             ,clientY: b
             ,layerX: c
             ,layerY: d
             ,ctrlKey: e
             ,shiftKey: f};
   });
   return _elm.Util.HtmlEvent.values = {_op: _op
                                       ,MouseEvent: MouseEvent
                                       ,KeyboardEvent: KeyboardEvent
                                       ,decodeMousePosition: decodeMousePosition
                                       ,decodeKeyboardEvent: decodeKeyboardEvent};
};
Elm.Native.HtmlUtil = {};

Elm.Native.HtmlUtil.make = function(localRuntime) {
    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.HtmlUtil = localRuntime.Native.HtmlUtil || {};
    if (localRuntime.Native.HtmlUtil.values) return localRuntime.Native.HtmlUtil.values;

    var Task = Elm.Native.Task.make(localRuntime);
    var Utils = Elm.Native.Utils.make(localRuntime);
    var Signal = Elm.Native.Signal.make(localRuntime);

    function focus(id) {
      return Task.asyncFunction(function(callback) {
        localRuntime.setTimeout(function() {
          var el = document.getElementById(id);
          if(el) {
            el.focus();
            return callback(Task.succeed(Utils.Tuple0));
          } else {
            return callback(Task.fail(Utils.Tuple0));
          }
        }, 100);
      });
    }
    function blur(id) {
      return Task.asyncFunction(function(callback) {
        localRuntime.setTimeout(function() {
          var el = document.getElementById(id);
          if(el) {
            el.blur();
            return callback(Task.succeed(Utils.Tuple0));
          } else {
            return callback(Task.fail(Utils.Tuple0));
          }
        }, 100);
      });
    }
    function readAsDataURL(fileList) {
      return Task.asyncFunction(function(callback) {
        var reader = new FileReader();
        reader.readAsDataURL(fileList[0]);
        reader.onload = function() {
          var dataUrl = reader.result;
          callback(Task.succeed(dataUrl));
        };
        reader.onerror = function() {
          callback(Task.succeed(""));//TODO
        };
      });
    }
    function getWidthAndHeightOfImage(dataUrl) {
      var image = new Image();
      image.src = dataUrl;
      return Utils.Tuple2(image.width, image.height);
    }
    var locationHash = Task.asyncFunction(function(callback) {
      console.log();
      callback(Task.succeed(window.location.hash));
    });
    var locationHash = Signal.input('locationHash', window.location.hash);
    window.addEventListener('hashchange', function() {
      var hash = window.location.hash;
      localRuntime.notify(locationHash.id, hash);
    });

    return localRuntime.Native.HtmlUtil.values = {
        focus: focus,
        blur: blur,
        readAsDataURL : readAsDataURL,
        getWidthAndHeightOfImage: getWidthAndHeightOfImage,
        locationHash: locationHash
    };
};

Elm.Util = Elm.Util || {};
Elm.Util.HtmlUtil = Elm.Util.HtmlUtil || {};
Elm.Util.HtmlUtil.make = function (_elm) {
   "use strict";
   _elm.Util = _elm.Util || {};
   _elm.Util.HtmlUtil = _elm.Util.HtmlUtil || {};
   if (_elm.Util.HtmlUtil.values) return _elm.Util.HtmlUtil.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $Html = Elm.Html.make(_elm),
   $Html$Attributes = Elm.Html.Attributes.make(_elm),
   $Html$Events = Elm.Html.Events.make(_elm),
   $Json$Decode = Elm.Json.Decode.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Native$HtmlUtil = Elm.Native.HtmlUtil.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $Task = Elm.Task.make(_elm),
   $Util$HtmlEvent = Elm.Util.HtmlEvent.make(_elm);
   var _op = {};
   var getWidthAndHeightOfImage = $Native$HtmlUtil.getWidthAndHeightOfImage;
   var decodeWheelEvent = A2($Json$Decode.andThen,
   A8($Json$Decode.object7,
   F7(function (clientX,clientY,layerX,layerY,ctrl,shift,value) {
      return {clientX: clientX
             ,clientY: clientY
             ,layerX: layerX
             ,layerY: layerY
             ,ctrlKey: ctrl
             ,shiftKey: shift
             ,value: value};
   }),
   A2($Json$Decode._op[":="],"clientX",$Json$Decode.$int),
   A2($Json$Decode._op[":="],"clientY",$Json$Decode.$int),
   A2($Json$Decode._op[":="],"layerX",$Json$Decode.$int),
   A2($Json$Decode._op[":="],"layerY",$Json$Decode.$int),
   A2($Json$Decode._op[":="],"ctrlKey",$Json$Decode.bool),
   A2($Json$Decode._op[":="],"shiftKey",$Json$Decode.bool),
   $Json$Decode.oneOf(_U.list([A2($Json$Decode.at,
                              _U.list(["deltaY"]),
                              $Json$Decode.$float)
                              ,A2($Json$Decode.map,
                              function (v) {
                                 return 0 - v;
                              },
                              A2($Json$Decode.at,
                              _U.list(["wheelDelta"]),
                              $Json$Decode.$float))]))),
   function (e) {
      return !_U.eq(e.value,
      0) ? $Json$Decode.succeed(e) : $Json$Decode.fail("Wheel of 0");
   });
   var decodeMousePosition = A7($Json$Decode.object6,
   F6(function (clientX,clientY,layerX,layerY,ctrl,shift) {
      return {clientX: clientX
             ,clientY: clientY
             ,layerX: layerX
             ,layerY: layerY
             ,ctrlKey: ctrl
             ,shiftKey: shift};
   }),
   A2($Json$Decode._op[":="],"clientX",$Json$Decode.$int),
   A2($Json$Decode._op[":="],"clientY",$Json$Decode.$int),
   A2($Json$Decode._op[":="],"layerX",$Json$Decode.$int),
   A2($Json$Decode._op[":="],"layerY",$Json$Decode.$int),
   A2($Json$Decode._op[":="],"ctrlKey",$Json$Decode.bool),
   A2($Json$Decode._op[":="],"shiftKey",$Json$Decode.bool));
   var onMouseWheel = F2(function (address,toAction) {
      var handler = function (v) {
         return A2($Signal.message,address,toAction(v));
      };
      return A4($Html$Events.onWithOptions,
      "wheel",
      {stopPropagation: true,preventDefault: true},
      decodeWheelEvent,
      handler);
   });
   var onContextMenu$ = function (address) {
      return A4($Html$Events.onWithOptions,
      "contextmenu",
      {stopPropagation: true,preventDefault: true},
      decodeMousePosition,
      $Signal.message(address));
   };
   var onKeyDown$$ = function (address) {
      return A3($Html$Events.on,
      "keydown",
      $Util$HtmlEvent.decodeKeyboardEvent,
      $Signal.message(address));
   };
   var onKeyDown$ = function (address) {
      return A4($Html$Events.onWithOptions,
      "keydown",
      {stopPropagation: true,preventDefault: true},
      $Util$HtmlEvent.decodeKeyboardEvent,
      $Signal.message(address));
   };
   var onChange$ = function (address) {
      return A4($Html$Events.onWithOptions,
      "change",
      {stopPropagation: true,preventDefault: true},
      $Html$Events.targetValue,
      $Signal.message(address));
   };
   var onInput$ = function (address) {
      return A4($Html$Events.onWithOptions,
      "input",
      {stopPropagation: true,preventDefault: true},
      $Html$Events.targetValue,
      $Signal.message(address));
   };
   var onClick$ = function (address) {
      return A4($Html$Events.onWithOptions,
      "click",
      {stopPropagation: true,preventDefault: true},
      decodeMousePosition,
      $Signal.message(address));
   };
   var onDblClick$ = function (address) {
      return A4($Html$Events.onWithOptions,
      "dblclick",
      {stopPropagation: true,preventDefault: true},
      decodeMousePosition,
      $Signal.message(address));
   };
   var onMouseDown$ = function (address) {
      return A4($Html$Events.onWithOptions,
      "mousedown",
      {stopPropagation: true,preventDefault: true},
      decodeMousePosition,
      $Signal.message(address));
   };
   var mouseDownDefence = F2(function (address,noOp) {
      return onMouseDown$(A2($Signal.forwardTo,
      address,
      $Basics.always(noOp)));
   });
   var onMouseUp$ = function (address) {
      return A3($Html$Events.on,
      "mouseup",
      decodeMousePosition,
      $Signal.message(address));
   };
   var onMouseLeave$ = function (address) {
      return A4($Html$Events.onWithOptions,
      "mouseleave",
      {stopPropagation: true,preventDefault: true},
      decodeMousePosition,
      $Signal.message(address));
   };
   var onMouseEnter$ = function (address) {
      return A4($Html$Events.onWithOptions,
      "mouseenter",
      {stopPropagation: true,preventDefault: true},
      decodeMousePosition,
      $Signal.message(address));
   };
   var onMouseMove$ = function (address) {
      return A4($Html$Events.onWithOptions,
      "mousemove",
      {stopPropagation: true,preventDefault: true},
      decodeMousePosition,
      $Signal.message(address));
   };
   var locationHash = $Native$HtmlUtil.locationHash;
   var FileList = function (a) {
      return {ctor: "FileList",_0: a};
   };
   var decodeFile = A2($Json$Decode.map,
   FileList,
   A2($Json$Decode.at,
   _U.list(["target","files"]),
   $Json$Decode.value));
   var fileLoadButton = function (address) {
      return A2($Html.input,
      _U.list([$Html$Attributes.type$("file")
              ,A3($Html$Events.on,
              "change",
              decodeFile,
              $Signal.message(address))]),
      _U.list([]));
   };
   var MouseWheelEvent = F7(function (a,b,c,d,e,f,g) {
      return {clientX: a
             ,clientY: b
             ,layerX: c
             ,layerY: d
             ,ctrlKey: e
             ,shiftKey: f
             ,value: g};
   });
   var Unexpected = function (a) {
      return {ctor: "Unexpected",_0: a};
   };
   var readFirstAsDataURL = function (_p0) {
      var _p1 = _p0;
      var _p2 = _p1._0;
      return A2($Task.mapError,
      $Basics.always(Unexpected($Basics.toString(_p2))),
      $Native$HtmlUtil.readAsDataURL(_p2));
   };
   var IdNotFound = function (a) {
      return {ctor: "IdNotFound",_0: a};
   };
   var focus = function (id) {
      return A2($Task.mapError,
      $Basics.always(IdNotFound(id)),
      $Native$HtmlUtil.focus(id));
   };
   var blur = function (id) {
      return A2($Task.mapError,
      $Basics.always(IdNotFound(id)),
      $Native$HtmlUtil.blur(id));
   };
   return _elm.Util.HtmlUtil.values = {_op: _op
                                      ,IdNotFound: IdNotFound
                                      ,Unexpected: Unexpected
                                      ,MouseWheelEvent: MouseWheelEvent
                                      ,FileList: FileList
                                      ,focus: focus
                                      ,blur: blur
                                      ,locationHash: locationHash
                                      ,onMouseMove$: onMouseMove$
                                      ,onMouseEnter$: onMouseEnter$
                                      ,onMouseLeave$: onMouseLeave$
                                      ,onMouseUp$: onMouseUp$
                                      ,onMouseDown$: onMouseDown$
                                      ,onDblClick$: onDblClick$
                                      ,onClick$: onClick$
                                      ,onInput$: onInput$
                                      ,onChange$: onChange$
                                      ,onKeyDown$: onKeyDown$
                                      ,onKeyDown$$: onKeyDown$$
                                      ,onContextMenu$: onContextMenu$
                                      ,onMouseWheel: onMouseWheel
                                      ,mouseDownDefence: mouseDownDefence
                                      ,decodeMousePosition: decodeMousePosition
                                      ,decodeWheelEvent: decodeWheelEvent
                                      ,readFirstAsDataURL: readFirstAsDataURL
                                      ,getWidthAndHeightOfImage: getWidthAndHeightOfImage
                                      ,fileLoadButton: fileLoadButton
                                      ,decodeFile: decodeFile};
};
Elm.Floor = Elm.Floor || {};
Elm.Floor.make = function (_elm) {
   "use strict";
   _elm.Floor = _elm.Floor || {};
   if (_elm.Floor.values) return _elm.Floor.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $Equipments = Elm.Equipments.make(_elm),
   $EquipmentsOperation = Elm.EquipmentsOperation.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $Util$HtmlUtil = Elm.Util.HtmlUtil.make(_elm);
   var _op = {};
   var src = function (model) {
      var _p0 = model.imageSource;
      switch (_p0.ctor)
      {case "LocalFile": return $Maybe.Just(_p0._2);
         case "URL": return $Maybe.Just(A2($Basics._op["++"],
           "/images/",
           _p0._0));
         default: return $Maybe.Nothing;}
   };
   var setEquipments = F2(function (equipments,model) {
      return _U.update(model,{equipments: equipments});
   });
   var addEquipments = F2(function (equipments,model) {
      return A2(setEquipments,
      A2($Basics._op["++"],model.equipments,equipments),
      model);
   });
   var equipments = function (model) {
      return model.equipments;
   };
   var pixelToReal = function (pixel) {
      return $Basics.floor($Basics.toFloat(pixel) / 80);
   };
   var realSize = function (model) {
      var _p1 = model.realSize;
      if (_p1.ctor === "Just") {
            return {ctor: "_Tuple2",_0: _p1._0._0,_1: _p1._0._1};
         } else {
            return {ctor: "_Tuple2"
                   ,_0: pixelToReal(model.width)
                   ,_1: pixelToReal(model.height)};
         }
   };
   var realToPixel = function (real) {
      return $Basics.floor($Basics.toFloat(real) * 80);
   };
   var size = function (model) {
      var _p2 = model.realSize;
      if (_p2.ctor === "Just") {
            return {ctor: "_Tuple2"
                   ,_0: realToPixel(_p2._0._0)
                   ,_1: realToPixel(_p2._0._1)};
         } else {
            return {ctor: "_Tuple2",_0: model.width,_1: model.height};
         }
   };
   var width = function (model) {
      return $Basics.fst(size(model));
   };
   var height = function (model) {
      return $Basics.snd(size(model));
   };
   var UseURL = {ctor: "UseURL"};
   var useURL = UseURL;
   var ChangeRealHeight = function (a) {
      return {ctor: "ChangeRealHeight",_0: a};
   };
   var changeRealHeight = ChangeRealHeight;
   var ChangeRealWidth = function (a) {
      return {ctor: "ChangeRealWidth",_0: a};
   };
   var changeRealWidth = ChangeRealWidth;
   var SetLocalFile = F3(function (a,b,c) {
      return {ctor: "SetLocalFile",_0: a,_1: b,_2: c};
   });
   var setLocalFile = SetLocalFile;
   var ChangeName = function (a) {
      return {ctor: "ChangeName",_0: a};
   };
   var changeName = ChangeName;
   var ChangeEquipmentName = F2(function (a,b) {
      return {ctor: "ChangeEquipmentName",_0: a,_1: b};
   });
   var changeEquipmentName = ChangeEquipmentName;
   var ChangeEquipmentColor = F2(function (a,b) {
      return {ctor: "ChangeEquipmentColor",_0: a,_1: b};
   });
   var changeEquipmentColor = ChangeEquipmentColor;
   var Rotate = function (a) {    return {ctor: "Rotate",_0: a};};
   var rotate = Rotate;
   var Delete = function (a) {    return {ctor: "Delete",_0: a};};
   var $delete = Delete;
   var Paste = F2(function (a,b) {
      return {ctor: "Paste",_0: a,_1: b};
   });
   var paste = Paste;
   var Move = F3(function (a,b,c) {
      return {ctor: "Move",_0: a,_1: b,_2: c};
   });
   var move = Move;
   var Create = function (a) {    return {ctor: "Create",_0: a};};
   var create = Create;
   var None = {ctor: "None"};
   var init = function (id) {
      return {id: id
             ,name: "1F"
             ,equipments: _U.list([])
             ,width: 800
             ,height: 600
             ,realSize: $Maybe.Nothing
             ,imageSource: None};
   };
   var URL = function (a) {    return {ctor: "URL",_0: a};};
   var LocalFile = F3(function (a,b,c) {
      return {ctor: "LocalFile",_0: a,_1: b,_2: c};
   });
   var setLocalFile$ = F4(function (id,fileList,dataURL,model) {
      var _p3 = $Util$HtmlUtil.getWidthAndHeightOfImage(dataURL);
      var width = _p3._0;
      var height = _p3._1;
      return _U.update(model,
      {width: width
      ,height: height
      ,imageSource: A3(LocalFile,id,fileList,dataURL)});
   });
   var update = F2(function (action,model) {
      var _p4 = action;
      switch (_p4.ctor)
      {case "Create": var create = function (_p5) {
              var _p6 = _p5;
              return A4($Equipments.init,
              _p6._0,
              {ctor: "_Tuple4"
              ,_0: _p6._1._0
              ,_1: _p6._1._1
              ,_2: _p6._1._2
              ,_3: _p6._1._3},
              _p6._2,
              _p6._3);
           };
           return A2(addEquipments,A2($List.map,create,_p4._0),model);
         case "Move": return A2(setEquipments,
           A4($EquipmentsOperation.moveEquipments,
           _p4._1,
           {ctor: "_Tuple2",_0: _p4._2._0,_1: _p4._2._1},
           _p4._0,
           equipments(model)),
           model);
         case "Paste": return A2(setEquipments,
           A2($Basics._op["++"],
           model.equipments,
           A3($EquipmentsOperation.pasteEquipments,
           {ctor: "_Tuple2",_0: _p4._1._0,_1: _p4._1._1},
           _p4._0,
           equipments(model))),
           model);
         case "Delete": return A2(setEquipments,
           A2($List.filter,
           function (equipment) {
              return $Basics.not(A2($List.member,
              $EquipmentsOperation.idOf(equipment),
              _p4._0));
           },
           equipments(model)),
           model);
         case "Rotate": return A2(setEquipments,
           A3($EquipmentsOperation.partiallyChange,
           $EquipmentsOperation.rotate,
           _U.list([_p4._0]),
           equipments(model)),
           model);
         case "ChangeEquipmentColor":
         var newEquipments = A3($EquipmentsOperation.partiallyChange,
           $EquipmentsOperation.changeColor(_p4._1),
           _p4._0,
           equipments(model));
           return A2(setEquipments,newEquipments,model);
         case "ChangeEquipmentName": return A2(setEquipments,
           A2($EquipmentsOperation.commitInputName,
           {ctor: "_Tuple2",_0: _p4._0,_1: _p4._1},
           equipments(model)),
           model);
         case "ChangeName": return _U.update(model,{name: _p4._0});
         case "SetLocalFile": return A4(setLocalFile$,
           _p4._0,
           _p4._1,
           _p4._2,
           model);
         case "ChangeRealWidth": var _p8 = _p4._0;
           var newRealSize = function () {
              var _p7 = model.realSize;
              if (_p7.ctor === "Just") {
                    return $Maybe.Just({ctor: "_Tuple2",_0: _p8,_1: _p7._0._1});
                 } else {
                    return $Maybe.Just({ctor: "_Tuple2"
                                       ,_0: _p8
                                       ,_1: pixelToReal(model.height)});
                 }
           }();
           return _U.update(model,{realSize: newRealSize});
         case "ChangeRealHeight": var _p10 = _p4._0;
           var newRealSize = function () {
              var _p9 = model.realSize;
              if (_p9.ctor === "Just") {
                    return $Maybe.Just({ctor: "_Tuple2",_0: _p9._0._0,_1: _p10});
                 } else {
                    return $Maybe.Just({ctor: "_Tuple2"
                                       ,_0: pixelToReal(model.width)
                                       ,_1: _p10});
                 }
           }();
           return _U.update(model,{realSize: newRealSize});
         default: return _U.update(model,
           {imageSource: function () {
              var _p11 = model.imageSource;
              if (_p11.ctor === "LocalFile") {
                    return URL(_p11._0);
                 } else {
                    return model.imageSource;
                 }
           }()});}
   });
   var Model = F7(function (a,b,c,d,e,f,g) {
      return {id: a
             ,name: b
             ,equipments: c
             ,width: d
             ,height: e
             ,realSize: f
             ,imageSource: g};
   });
   return _elm.Floor.values = {_op: _op
                              ,Model: Model
                              ,LocalFile: LocalFile
                              ,URL: URL
                              ,None: None
                              ,init: init
                              ,Create: Create
                              ,Move: Move
                              ,Paste: Paste
                              ,Delete: Delete
                              ,Rotate: Rotate
                              ,ChangeEquipmentColor: ChangeEquipmentColor
                              ,ChangeEquipmentName: ChangeEquipmentName
                              ,ChangeName: ChangeName
                              ,SetLocalFile: SetLocalFile
                              ,ChangeRealWidth: ChangeRealWidth
                              ,ChangeRealHeight: ChangeRealHeight
                              ,UseURL: UseURL
                              ,create: create
                              ,move: move
                              ,paste: paste
                              ,$delete: $delete
                              ,rotate: rotate
                              ,changeEquipmentColor: changeEquipmentColor
                              ,changeEquipmentName: changeEquipmentName
                              ,changeName: changeName
                              ,setLocalFile: setLocalFile
                              ,changeRealWidth: changeRealWidth
                              ,changeRealHeight: changeRealHeight
                              ,useURL: useURL
                              ,update: update
                              ,realToPixel: realToPixel
                              ,pixelToReal: pixelToReal
                              ,size: size
                              ,width: width
                              ,height: height
                              ,realSize: realSize
                              ,equipments: equipments
                              ,setEquipments: setEquipments
                              ,addEquipments: addEquipments
                              ,setLocalFile$: setLocalFile$
                              ,src: src};
};
Elm.Native.HttpUtil = {};

Elm.Native.HttpUtil.make = function(localRuntime) {
    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.HttpUtil = localRuntime.Native.HttpUtil || {};
    if (localRuntime.Native.HttpUtil.values) return localRuntime.Native.HttpUtil.values;

    var Task = Elm.Native.Task.make(localRuntime);
    var Utils = Elm.Native.Utils.make(localRuntime);

    function putFile(url, filelist) {
      console.log('putFile', url, filelist)
      return Task.asyncFunction(function(callback) {
        var xhr = new XMLHttpRequest();
        xhr.open('PUT', url, true);
        var formData = new FormData();
        formData.append("uploads", filelist[0]);
        xhr.onload = function(e) {
          if (this.status == 200) {
            callback(Task.succeed(Utils.tuple0))
          } else {
            callback(Task.fail("")) //TODO
          }
        };
        xhr.send(filelist[0]);
      });
    }
    return localRuntime.Native.HttpUtil.values = {
        putFile: F2(putFile)
    };
};

Elm.Util = Elm.Util || {};
Elm.Util.HttpUtil = Elm.Util.HttpUtil || {};
Elm.Util.HttpUtil.make = function (_elm) {
   "use strict";
   _elm.Util = _elm.Util || {};
   _elm.Util.HttpUtil = _elm.Util.HttpUtil || {};
   if (_elm.Util.HttpUtil.values) return _elm.Util.HttpUtil.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Native$HttpUtil = Elm.Native.HttpUtil.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $Task = Elm.Task.make(_elm),
   $Util$HtmlUtil = Elm.Util.HtmlUtil.make(_elm);
   var _op = {};
   var putFile = F2(function (url,_p0) {
      var _p1 = _p0;
      return A2($Native$HttpUtil.putFile,url,_p1._0);
   });
   return _elm.Util.HttpUtil.values = {_op: _op,putFile: putFile};
};
Elm.API = Elm.API || {};
Elm.API.make = function (_elm) {
   "use strict";
   _elm.API = _elm.API || {};
   if (_elm.API.values) return _elm.API.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $Equipments = Elm.Equipments.make(_elm),
   $Floor = Elm.Floor.make(_elm),
   $Http = Elm.Http.make(_elm),
   $Json$Decode = Elm.Json.Decode.make(_elm),
   $Json$Encode = Elm.Json.Encode.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $Task = Elm.Task.make(_elm),
   $Util$HtmlUtil = Elm.Util.HtmlUtil.make(_elm),
   $Util$HttpUtil = Elm.Util.HttpUtil.make(_elm);
   var _op = {};
   var saveEditingImage = F2(function (id,filelist) {
      return A2($Util$HttpUtil.putFile,
      A2($Basics._op["++"],"/api/v1/image/",id),
      filelist);
   });
   var decodeEquipment = A8($Json$Decode.object7,
   F7(function (id,x,y,width,height,color,name) {
      return A4($Equipments.Desk,
      id,
      {ctor: "_Tuple4",_0: x,_1: y,_2: width,_3: height},
      color,
      name);
   }),
   A2($Json$Decode._op[":="],"id",$Json$Decode.string),
   A2($Json$Decode._op[":="],"x",$Json$Decode.$int),
   A2($Json$Decode._op[":="],"y",$Json$Decode.$int),
   A2($Json$Decode._op[":="],"width",$Json$Decode.$int),
   A2($Json$Decode._op[":="],"height",$Json$Decode.$int),
   A2($Json$Decode._op[":="],"color",$Json$Decode.string),
   A2($Json$Decode._op[":="],"name",$Json$Decode.string));
   var decodeFloor = A9($Json$Decode.object8,
   F8(function (id,
   name,
   equipments,
   width,
   height,
   realWidth,
   realHeight,
   src) {
      return {id: id
             ,name: name
             ,equipments: equipments
             ,width: width
             ,height: height
             ,imageSource: A2($Maybe.withDefault,
             $Floor.None,
             A2($Maybe.map,$Floor.URL,src))
             ,realSize: A2($Maybe.andThen,
             realWidth,
             function (w) {
                return A2($Maybe.andThen,
                realHeight,
                function (h) {
                   return $Maybe.Just({ctor: "_Tuple2",_0: w,_1: h});
                });
             })};
   }),
   A2($Json$Decode._op[":="],"id",$Json$Decode.string),
   A2($Json$Decode._op[":="],"name",$Json$Decode.string),
   A2($Json$Decode._op[":="],
   "equipments",
   $Json$Decode.list(decodeEquipment)),
   A2($Json$Decode._op[":="],"width",$Json$Decode.$int),
   A2($Json$Decode._op[":="],"height",$Json$Decode.$int),
   $Json$Decode.maybe(A2($Json$Decode._op[":="],
   "realWidth",
   $Json$Decode.$int)),
   $Json$Decode.maybe(A2($Json$Decode._op[":="],
   "realHeight",
   $Json$Decode.$int)),
   $Json$Decode.maybe(A2($Json$Decode._op[":="],
   "src",
   $Json$Decode.string)));
   var getEditingFloor = function (id) {
      return A2($Http.get,
      decodeFloor,
      A2($Basics._op["++"],
      "/api/v1/floor/",
      A2($Basics._op["++"],id,"/edit")));
   };
   var getFloor = function (id) {
      return A2($Http.get,
      decodeFloor,
      A2($Basics._op["++"],"/api/v1/floor/",id));
   };
   var encodeEquipment = function (_p0) {
      var _p1 = _p0;
      return $Json$Encode.object(_U.list([{ctor: "_Tuple2"
                                          ,_0: "id"
                                          ,_1: $Json$Encode.string(_p1._0)}
                                         ,{ctor: "_Tuple2",_0: "type",_1: $Json$Encode.string("desk")}
                                         ,{ctor: "_Tuple2",_0: "x",_1: $Json$Encode.$int(_p1._1._0)}
                                         ,{ctor: "_Tuple2",_0: "y",_1: $Json$Encode.$int(_p1._1._1)}
                                         ,{ctor: "_Tuple2",_0: "width",_1: $Json$Encode.$int(_p1._1._2)}
                                         ,{ctor: "_Tuple2",_0: "height",_1: $Json$Encode.$int(_p1._1._3)}
                                         ,{ctor: "_Tuple2",_0: "color",_1: $Json$Encode.string(_p1._2)}
                                         ,{ctor: "_Tuple2"
                                          ,_0: "name"
                                          ,_1: $Json$Encode.string(_p1._3)}]));
   };
   var encodeFloor = function (floor) {
      var src = function () {
         var _p2 = floor.imageSource;
         switch (_p2.ctor)
         {case "LocalFile": return $Json$Encode.string(_p2._0);
            case "URL": return $Json$Encode.string(_p2._0);
            default: return $Json$Encode.$null;}
      }();
      return $Json$Encode.object(_U.list([{ctor: "_Tuple2"
                                          ,_0: "id"
                                          ,_1: $Json$Encode.string(floor.id)}
                                         ,{ctor: "_Tuple2"
                                          ,_0: "name"
                                          ,_1: $Json$Encode.string(floor.name)}
                                         ,{ctor: "_Tuple2"
                                          ,_0: "equipments"
                                          ,_1: $Json$Encode.list(A2($List.map,
                                          encodeEquipment,
                                          floor.equipments))}
                                         ,{ctor: "_Tuple2"
                                          ,_0: "width"
                                          ,_1: $Json$Encode.$int(floor.width)}
                                         ,{ctor: "_Tuple2"
                                          ,_0: "height"
                                          ,_1: $Json$Encode.$int(floor.height)}
                                         ,{ctor: "_Tuple2",_0: "src",_1: src}]));
   };
   var serializeFloor = function (floor) {
      return A2($Json$Encode.encode,0,encodeFloor(floor));
   };
   var put = F3(function (decoder,url,body) {
      var request = {verb: "PUT"
                    ,headers: _U.list([{ctor: "_Tuple2"
                                       ,_0: "Content-Type"
                                       ,_1: "application/json; charset=utf-8"}])
                    ,url: url
                    ,body: body};
      return A2($Http.fromJson,
      decoder,
      A2($Http.send,$Http.defaultSettings,request));
   });
   var saveEditingFloor = function (floor) {
      return A3(put,
      A2($Json$Decode.map,
      $Basics.always({ctor: "_Tuple0"}),
      $Json$Decode.value),
      A2($Basics._op["++"],
      "/api/v1/floor/",
      A2($Basics._op["++"],floor.id,"/edit")),
      $Http.string(serializeFloor(floor)));
   };
   return _elm.API.values = {_op: _op
                            ,saveEditingFloor: saveEditingFloor
                            ,getEditingFloor: getEditingFloor
                            ,getFloor: getFloor
                            ,saveEditingImage: saveEditingImage};
};
Elm.Icons = Elm.Icons || {};
Elm.Icons.make = function (_elm) {
   "use strict";
   _elm.Icons = _elm.Icons || {};
   if (_elm.Icons.values) return _elm.Icons.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Color = Elm.Color.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $List = Elm.List.make(_elm),
   $Material$Icons$Editor = Elm.Material.Icons.Editor.make(_elm),
   $Material$Icons$Image = Elm.Material.Icons.Image.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $Svg = Elm.Svg.make(_elm);
   var _op = {};
   var stampMode = function (selected) {
      return A2($Material$Icons$Editor.border_all,
      selected ? $Color.white : A3($Color.rgb,80,80,80),
      24);
   };
   var penMode = function (selected) {
      return A2($Material$Icons$Editor.mode_edit,
      selected ? $Color.white : A3($Color.rgb,80,80,80),
      24);
   };
   var selectMode = function (selected) {
      return A2($Material$Icons$Image.crop_square,
      selected ? $Color.white : A3($Color.rgb,80,80,80),
      24);
   };
   return _elm.Icons.values = {_op: _op
                              ,selectMode: selectMode
                              ,penMode: penMode
                              ,stampMode: stampMode};
};
Elm.Util = Elm.Util || {};
Elm.Util.UndoRedo = Elm.Util.UndoRedo || {};
Elm.Util.UndoRedo.make = function (_elm) {
   "use strict";
   _elm.Util = _elm.Util || {};
   _elm.Util.UndoRedo = _elm.Util.UndoRedo || {};
   if (_elm.Util.UndoRedo.values) return _elm.Util.UndoRedo.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm);
   var _op = {};
   var replay = F3(function (update,commitsAsc,original) {
      return A3($List.foldl,update,original,commitsAsc);
   });
   var commitsUntil = F2(function (cursor,commits) {
      return A2($List.drop,cursor,commits);
   });
   var canRedo = function (model) {
      return _U.cmp(model.cursor,0) > 0;
   };
   var canUndo = function (model) {
      return $Basics.not($List.isEmpty(A2(commitsUntil,
      model.cursor,
      model.commits)));
   };
   var dataAt = F2(function (cursor,model) {
      return A3(replay,
      model.update,
      $List.reverse(A2(commitsUntil,cursor,model.commits)),
      model.original);
   });
   var data = function (model) {    return model.cursorDataCache;};
   var updateByCursorShift = F2(function (cursor,model) {
      return _U.update(model,
      {cursor: cursor,cursorDataCache: A2(dataAt,cursor,model)});
   });
   var commit = F2(function (model,commit) {
      var model$ = _U.update(model,
      {commits: A2($List._op["::"],
      commit,
      A2($List.drop,model.cursor,model.commits))});
      return A2(updateByCursorShift,0,model$);
   });
   var redo = function (model) {
      return canRedo(model) ? A2(updateByCursorShift,
      model.cursor - 1,
      model) : model;
   };
   var undo = function (model) {
      return canUndo(model) ? A2(updateByCursorShift,
      model.cursor + 1,
      model) : model;
   };
   var init = function (_p0) {
      var _p1 = _p0;
      var _p2 = _p1.data;
      return {cursor: 0
             ,original: _p2
             ,commits: _U.list([])
             ,update: _p1.update
             ,cursorDataCache: _p2};
   };
   var Model = F5(function (a,b,c,d,e) {
      return {cursor: a
             ,original: b
             ,commits: c
             ,update: d
             ,cursorDataCache: e};
   });
   return _elm.Util.UndoRedo.values = {_op: _op
                                      ,init: init
                                      ,undo: undo
                                      ,redo: redo
                                      ,commit: commit
                                      ,canUndo: canUndo
                                      ,canRedo: canRedo
                                      ,data: data
                                      ,Model: Model};
};
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

Elm.Util = Elm.Util || {};
Elm.Util.Keys = Elm.Util.Keys || {};
Elm.Util.Keys.make = function (_elm) {
   "use strict";
   _elm.Util = _elm.Util || {};
   _elm.Util.Keys = _elm.Util.Keys || {};
   if (_elm.Util.Keys.values) return _elm.Util.Keys.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Char = Elm.Char.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $Json$Decode = Elm.Json.Decode.make(_elm),
   $Keyboard = Elm.Keyboard.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Native$Keys = Elm.Native.Keys.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $Util$HtmlEvent = Elm.Util.HtmlEvent.make(_elm);
   var _op = {};
   var initKeyboardEvent = {keyCode: -1
                           ,ctrlKey: false
                           ,shiftKey: false};
   var downs_ = $Native$Keys.downs;
   var downs = A3($Signal.filterMap,
   function (value) {
      var _p0 = A2($Json$Decode.decodeValue,
      $Util$HtmlEvent.decodeKeyboardEvent,
      value);
      if (_p0.ctor === "Ok") {
            return $Maybe.Just(_p0._0);
         } else {
            return $Maybe.Nothing;
         }
   },
   initKeyboardEvent,
   downs_);
   var update = F2(function (action,model) {
      var _p1 = action;
      switch (_p1.ctor)
      {case "KeyCtrl": return _U.update(model,{ctrl: _p1._0});
         case "KeyShift": return _U.update(model,{shift: _p1._0});
         default: return model;}
   });
   var init = {ctrl: false,shift: false};
   var Model = F2(function (a,b) {    return {ctrl: a,shift: b};});
   var Other = {ctor: "Other"};
   var KeyDownArrow = {ctor: "KeyDownArrow"};
   var KeyRightArrow = {ctor: "KeyRightArrow"};
   var KeyUpArrow = {ctor: "KeyUpArrow"};
   var KeyLeftArrow = {ctor: "KeyLeftArrow"};
   var KeyZ = {ctor: "KeyZ"};
   var KeyY = {ctor: "KeyY"};
   var KeyX = function (a) {    return {ctor: "KeyX",_0: a};};
   var KeyV = function (a) {    return {ctor: "KeyV",_0: a};};
   var KeyC = function (a) {    return {ctor: "KeyC",_0: a};};
   var KeyDel = function (a) {    return {ctor: "KeyDel",_0: a};};
   var KeyShift = function (a) {
      return {ctor: "KeyShift",_0: a};
   };
   var KeyCtrl = function (a) {
      return {ctor: "KeyCtrl",_0: a};
   };
   var inputs = _U.list([A2($Signal.map,KeyCtrl,$Keyboard.ctrl)
                        ,A2($Signal.map,KeyShift,$Keyboard.shift)
                        ,A2($Signal.map,KeyDel,$Keyboard.isDown(46))
                        ,A2($Signal.map,
                        KeyC,
                        $Keyboard.isDown($Char.toCode(_U.chr("C"))))
                        ,A2($Signal.map,
                        KeyV,
                        $Keyboard.isDown($Char.toCode(_U.chr("V"))))
                        ,A2($Signal.map,
                        KeyX,
                        $Keyboard.isDown($Char.toCode(_U.chr("X"))))
                        ,A2($Signal.map,
                        function (e) {
                           return _U.eq(e.keyCode,
                           $Char.toCode(_U.chr("Y"))) ? KeyY : _U.eq(e.keyCode,
                           $Char.toCode(_U.chr("Z"))) ? KeyZ : _U.eq(e.keyCode,
                           37) ? KeyLeftArrow : _U.eq(e.keyCode,
                           38) ? KeyUpArrow : _U.eq(e.keyCode,
                           39) ? KeyRightArrow : _U.eq(e.keyCode,
                           40) ? KeyDownArrow : Other;
                        },
                        downs)]);
   return _elm.Util.Keys.values = {_op: _op
                                  ,KeyCtrl: KeyCtrl
                                  ,KeyShift: KeyShift
                                  ,KeyDel: KeyDel
                                  ,KeyC: KeyC
                                  ,KeyV: KeyV
                                  ,KeyX: KeyX
                                  ,KeyY: KeyY
                                  ,KeyZ: KeyZ
                                  ,KeyLeftArrow: KeyLeftArrow
                                  ,KeyUpArrow: KeyUpArrow
                                  ,KeyRightArrow: KeyRightArrow
                                  ,KeyDownArrow: KeyDownArrow
                                  ,Other: Other
                                  ,Model: Model
                                  ,init: init
                                  ,inputs: inputs
                                  ,update: update
                                  ,downs_: downs_
                                  ,downs: downs
                                  ,initKeyboardEvent: initKeyboardEvent};
};
Elm.Util = Elm.Util || {};
Elm.Util.EffectsUtil = Elm.Util.EffectsUtil || {};
Elm.Util.EffectsUtil.make = function (_elm) {
   "use strict";
   _elm.Util = _elm.Util || {};
   _elm.Util.EffectsUtil = _elm.Util.EffectsUtil || {};
   if (_elm.Util.EffectsUtil.values)
   return _elm.Util.EffectsUtil.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $Effects = Elm.Effects.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $Task = Elm.Task.make(_elm);
   var _op = {};
   var fromTaskWithNoError = F2(function (f,task) {
      return $Effects.task(A2($Task.map,f,task));
   });
   var fromTask = F3(function (g,f,task) {
      return $Effects.task(A2($Task.onError,
      A2($Task.andThen,
      task,
      function (a) {
         return $Task.succeed(f(a));
      }),
      function (e) {
         return $Task.succeed(g(e));
      }));
   });
   return _elm.Util.EffectsUtil.values = {_op: _op
                                         ,fromTask: fromTask
                                         ,fromTaskWithNoError: fromTaskWithNoError};
};
Elm.Util = Elm.Util || {};
Elm.Util.IdGenerator = Elm.Util.IdGenerator || {};
Elm.Util.IdGenerator.make = function (_elm) {
   "use strict";
   _elm.Util = _elm.Util || {};
   _elm.Util.IdGenerator = _elm.Util.IdGenerator || {};
   if (_elm.Util.IdGenerator.values)
   return _elm.Util.IdGenerator.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Random$PCG = Elm.Random.PCG.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $Uuid = Elm.Uuid.make(_elm);
   var _op = {};
   var Seed = function (a) {    return {ctor: "Seed",_0: a};};
   var init = function (randomSeed) {
      return Seed(A2($Basics.uncurry,
      $Random$PCG.initialSeed2,
      randomSeed));
   };
   var $new = function (_p0) {
      var _p1 = _p0;
      var _p2 = A2($Random$PCG.generate,$Uuid.uuidGenerator,_p1._0);
      var newUuid = _p2._0;
      var newSeed = _p2._1;
      return {ctor: "_Tuple2"
             ,_0: $Uuid.toString(newUuid)
             ,_1: Seed(newSeed)};
   };
   var zipWithNewIds = F2(function (seed,list) {
      return A3($List.foldr,
      F2(function (a,_p3) {
         var _p4 = _p3;
         var _p5 = $new(_p4._1);
         var newId = _p5._0;
         var newSeed = _p5._1;
         return {ctor: "_Tuple2"
                ,_0: A2($List._op["::"],
                {ctor: "_Tuple2",_0: a,_1: newId},
                _p4._0)
                ,_1: newSeed};
      }),
      {ctor: "_Tuple2",_0: _U.list([]),_1: seed},
      list);
   });
   return _elm.Util.IdGenerator.values = {_op: _op
                                         ,Seed: Seed
                                         ,init: init
                                         ,$new: $new
                                         ,zipWithNewIds: zipWithNewIds};
};
Elm.Scale = Elm.Scale || {};
Elm.Scale.make = function (_elm) {
   "use strict";
   _elm.Scale = _elm.Scale || {};
   if (_elm.Scale.values) return _elm.Scale.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm);
   var _op = {};
   var ratio = F2(function (old,$new) {
      return $Basics.toFloat(Math.pow(2,
      old.scaleDown)) / $Basics.toFloat(Math.pow(2,$new.scaleDown));
   });
   var imageToScreen = F2(function (model,screenLength) {
      return screenLength / Math.pow(2,model.scaleDown) | 0;
   });
   var screenToImage = F2(function (model,imageLength) {
      return imageLength * Math.pow(2,model.scaleDown);
   });
   var screenToImageForRect = F2(function (model,_p0) {
      var _p1 = _p0;
      return {ctor: "_Tuple4"
             ,_0: A2(screenToImage,model,_p1._0)
             ,_1: A2(screenToImage,model,_p1._1)
             ,_2: A2(screenToImage,model,_p1._2)
             ,_3: A2(screenToImage,model,_p1._3)};
   });
   var imageToScreenForRect = F2(function (model,_p2) {
      var _p3 = _p2;
      return {ctor: "_Tuple4"
             ,_0: A2(imageToScreen,model,_p3._0)
             ,_1: A2(imageToScreen,model,_p3._1)
             ,_2: A2(imageToScreen,model,_p3._2)
             ,_3: A2(imageToScreen,model,_p3._3)};
   });
   var screenToImageForPosition = F2(function (model,_p4) {
      var _p5 = _p4;
      return {ctor: "_Tuple2"
             ,_0: A2(screenToImage,model,_p5._0)
             ,_1: A2(screenToImage,model,_p5._1)};
   });
   var update = F2(function (action,model) {
      var _p6 = action;
      if (_p6.ctor === "ScaleUp") {
            return _U.update(model,
            {scaleDown: A2($Basics.max,0,model.scaleDown - 1)});
         } else {
            return _U.update(model,
            {scaleDown: A2($Basics.min,2,model.scaleDown + 1)});
         }
   });
   var init = {scaleDown: 0};
   var Model = function (a) {    return {scaleDown: a};};
   var ScaleDown = {ctor: "ScaleDown"};
   var ScaleUp = {ctor: "ScaleUp"};
   return _elm.Scale.values = {_op: _op
                              ,ScaleUp: ScaleUp
                              ,ScaleDown: ScaleDown
                              ,Model: Model
                              ,init: init
                              ,update: update
                              ,screenToImageForPosition: screenToImageForPosition
                              ,imageToScreenForRect: imageToScreenForRect
                              ,screenToImageForRect: screenToImageForRect
                              ,screenToImage: screenToImage
                              ,imageToScreen: imageToScreen
                              ,ratio: ratio};
};
Elm.Prototypes = Elm.Prototypes || {};
Elm.Prototypes.make = function (_elm) {
   "use strict";
   _elm.Prototypes = _elm.Prototypes || {};
   if (_elm.Prototypes.values) return _elm.Prototypes.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $EquipmentsOperation = Elm.EquipmentsOperation.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $Util$ListUtil = Elm.Util.ListUtil.make(_elm);
   var _op = {};
   var generateAllCandidatePosition = F3(function (_p2,_p1,_p0) {
      var _p3 = _p2;
      var _p4 = _p1;
      var _p5 = _p0;
      var tops = A2($List.map,
      function (index) {
         return _p4._1 + _p3._1 * index;
      },
      _p5._1);
      var lefts = A2($List.map,
      function (index) {
         return _p4._0 + _p3._0 * index;
      },
      _p5._0);
      return A2($List.concatMap,
      function (left) {
         return A2($List.map,
         function (top) {
            return {ctor: "_Tuple2",_0: left,_1: top};
         },
         tops);
      },
      lefts);
   });
   var stampIndices = F4(function (horizontal,_p8,_p7,_p6) {
      var _p9 = _p8;
      var _p18 = _p9._0;
      var _p17 = _p9._1;
      var _p10 = _p7;
      var _p16 = _p10._1;
      var _p15 = _p10._0;
      var _p11 = _p6;
      var _p14 = _p11._1;
      var _p13 = _p11._0;
      var _p12 = function () {
         if (horizontal) {
               var amountY = _U.cmp($Basics.abs(_p14 - _p16),
               _p17 / 2 | 0) > 0 ? 1 : 0;
               var amountX = ($Basics.abs(_p13 - _p15) + (_p18 / 2 | 0)) / _p18 | 0;
               return {ctor: "_Tuple2",_0: amountX,_1: amountY};
            } else {
               var amountY = ($Basics.abs(_p14 - _p16) + (_p17 / 2 | 0)) / _p17 | 0;
               var amountX = _U.cmp($Basics.abs(_p13 - _p15),
               _p18 / 2 | 0) > 0 ? 1 : 0;
               return {ctor: "_Tuple2",_0: amountX,_1: amountY};
            }
      }();
      var amountX = _p12._0;
      var amountY = _p12._1;
      return {ctor: "_Tuple2"
             ,_0: A2($List.map,
             function (i) {
                return _U.cmp(_p13,_p15) > 0 ? i : 0 - i;
             },
             _U.range(0,amountX))
             ,_1: A2($List.map,
             function (i) {
                return _U.cmp(_p14,_p16) > 0 ? i : 0 - i;
             },
             _U.range(0,amountY))};
   });
   var stampCandidatesOnDragging = F4(function (gridSize,
   prototype,
   _p20,
   _p19) {
      var _p21 = _p20;
      var _p34 = _p21._1;
      var _p33 = _p21._0;
      var _p22 = _p19;
      var _p32 = _p22._1;
      var _p31 = _p22._0;
      var horizontal = _U.cmp($Basics.abs(_p31 - _p33),
      $Basics.abs(_p32 - _p34)) > 0;
      var flip = function (_p23) {
         var _p24 = _p23;
         return {ctor: "_Tuple2",_0: _p24._1,_1: _p24._0};
      };
      var _p25 = prototype;
      var prototypeId = _p25._0;
      var color = _p25._1;
      var name = _p25._2;
      var deskSize = _p25._3;
      var _p26 = horizontal ? flip(deskSize) : deskSize;
      var deskWidth = _p26._0;
      var deskHeight = _p26._1;
      var _p27 = A4(stampIndices,
      horizontal,
      {ctor: "_Tuple2",_0: deskWidth,_1: deskHeight},
      {ctor: "_Tuple2",_0: _p33,_1: _p34},
      {ctor: "_Tuple2",_0: _p31,_1: _p32});
      var indicesX = _p27._0;
      var indicesY = _p27._1;
      var _p28 = A2($EquipmentsOperation.fitToGrid,
      gridSize,
      {ctor: "_Tuple2"
      ,_0: _p33 - ($Basics.fst(deskSize) / 2 | 0)
      ,_1: _p34 - ($Basics.snd(deskSize) / 2 | 0)});
      var centerLeft = _p28._0;
      var centerTop = _p28._1;
      var all = A3(generateAllCandidatePosition,
      {ctor: "_Tuple2",_0: deskWidth,_1: deskHeight},
      {ctor: "_Tuple2",_0: centerLeft,_1: centerTop},
      {ctor: "_Tuple2",_0: indicesX,_1: indicesY});
      return A2($List.map,
      function (_p29) {
         var _p30 = _p29;
         return {ctor: "_Tuple2"
                ,_0: {ctor: "_Tuple4"
                     ,_0: prototypeId
                     ,_1: color
                     ,_2: name
                     ,_3: {ctor: "_Tuple2",_0: deskWidth,_1: deskHeight}}
                ,_1: {ctor: "_Tuple2",_0: _p30._0,_1: _p30._1}};
      },
      all);
   });
   var prototypes = function (model) {
      return A2($List.indexedMap,
      F2(function (index,prototype) {
         return {ctor: "_Tuple2"
                ,_0: prototype
                ,_1: _U.eq(model.selected,index)};
      }),
      model.data);
   };
   var findPrototypeByIndex = F2(function (index,list) {
      var _p35 = A2($Util$ListUtil.getAt,index,list);
      if (_p35.ctor === "Just") {
            return _p35._0;
         } else {
            var _p36 = $List.head(list);
            if (_p36.ctor === "Just") {
                  return _p36._0;
               } else {
                  return _U.crashCase("Prototypes",
                  {start: {line: 75,column: 7},end: {line: 77,column: 53}},
                  _p36)("no prototypes found");
               }
         }
   });
   var selectedPrototype = function (model) {
      return A2(findPrototypeByIndex,model.selected,model.data);
   };
   var register = F2(function (prototype,model) {
      var newPrototypes = A2($Basics._op["++"],
      model.data,
      _U.list([prototype]));
      return _U.update(model,
      {data: newPrototypes
      ,selected: $List.length(newPrototypes) - 1});
   });
   var update = F2(function (action,model) {
      var _p38 = action;
      if (_p38.ctor === "SelectPrev") {
            return _U.update(model,
            {selected: A2($Basics.max,0,model.selected - 1)});
         } else {
            return _U.update(model,
            {selected: A2($Basics.min,
            $List.length(model.data) - 1,
            model.selected + 1)});
         }
   });
   var SelectNext = {ctor: "SelectNext"};
   var next = SelectNext;
   var SelectPrev = {ctor: "SelectPrev"};
   var prev = SelectPrev;
   var gridSize = 8;
   var init = {data: _U.list([{ctor: "_Tuple4"
                              ,_0: "1"
                              ,_1: "#ed9"
                              ,_2: ""
                              ,_3: {ctor: "_Tuple2",_0: gridSize * 6,_1: gridSize * 10}}
                             ,{ctor: "_Tuple4"
                              ,_0: "2"
                              ,_1: "#8bd"
                              ,_2: "foo"
                              ,_3: {ctor: "_Tuple2",_0: gridSize * 7,_1: gridSize * 12}}])
              ,selected: 0};
   var Model = F2(function (a,b) {
      return {data: a,selected: b};
   });
   return _elm.Prototypes.values = {_op: _op
                                   ,Model: Model
                                   ,gridSize: gridSize
                                   ,init: init
                                   ,SelectPrev: SelectPrev
                                   ,SelectNext: SelectNext
                                   ,prev: prev
                                   ,next: next
                                   ,update: update
                                   ,register: register
                                   ,selectedPrototype: selectedPrototype
                                   ,findPrototypeByIndex: findPrototypeByIndex
                                   ,prototypes: prototypes
                                   ,stampIndices: stampIndices
                                   ,generateAllCandidatePosition: generateAllCandidatePosition
                                   ,stampCandidatesOnDragging: stampCandidatesOnDragging};
};
Elm.Model = Elm.Model || {};
Elm.Model.make = function (_elm) {
   "use strict";
   _elm.Model = _elm.Model || {};
   if (_elm.Model.values) return _elm.Model.values;
   var _U = Elm.Native.Utils.make(_elm),
   $API = Elm.API.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $Effects = Elm.Effects.make(_elm),
   $Equipments = Elm.Equipments.make(_elm),
   $EquipmentsOperation = Elm.EquipmentsOperation.make(_elm),
   $Floor = Elm.Floor.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Prototypes = Elm.Prototypes.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Scale = Elm.Scale.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $String = Elm.String.make(_elm),
   $Task = Elm.Task.make(_elm),
   $Util$EffectsUtil = Elm.Util.EffectsUtil.make(_elm),
   $Util$HtmlUtil = Elm.Util.HtmlUtil.make(_elm),
   $Util$IdGenerator = Elm.Util.IdGenerator.make(_elm),
   $Util$Keys = Elm.Util.Keys.make(_elm),
   $Util$UndoRedo = Elm.Util.UndoRedo.make(_elm),
   $Window = Elm.Window.make(_elm);
   var _op = {};
   var stampCandidates = function (model) {
      var _p0 = model.editMode;
      if (_p0.ctor === "Stamp") {
            var _p1 = A2($Maybe.withDefault,
            {ctor: "_Tuple2",_0: 0,_1: 0},
            model.pos);
            var x2 = _p1._0;
            var y2 = _p1._1;
            var _p2 = model.offset;
            var offsetX = _p2._0;
            var offsetY = _p2._1;
            var _p3 = {ctor: "_Tuple2"
                      ,_0: A2($Scale.screenToImage,model.scale,x2) - offsetX
                      ,_1: A2($Scale.screenToImage,model.scale,y2) - offsetY};
            var x2$ = _p3._0;
            var y2$ = _p3._1;
            var prototype = $Prototypes.selectedPrototype(model.prototypes);
            var _p4 = prototype;
            var prototypeId = _p4._0;
            var color = _p4._1;
            var name = _p4._2;
            var deskSize = _p4._3;
            var _p5 = model.draggingContext;
            if (_p5.ctor === "StampScreenPos" && _p5._0.ctor === "_Tuple2")
            {
                  var _p6 = {ctor: "_Tuple2"
                            ,_0: A2($Scale.screenToImage,model.scale,_p5._0._0) - offsetX
                            ,_1: A2($Scale.screenToImage,model.scale,_p5._0._1) - offsetY};
                  var x1$ = _p6._0;
                  var y1$ = _p6._1;
                  return A4($Prototypes.stampCandidatesOnDragging,
                  model.gridSize,
                  prototype,
                  {ctor: "_Tuple2",_0: x1$,_1: y1$},
                  {ctor: "_Tuple2",_0: x2$,_1: y2$});
               } else {
                  var _p7 = deskSize;
                  var deskWidth = _p7._0;
                  var deskHeight = _p7._1;
                  var _p8 = A2($EquipmentsOperation.fitToGrid,
                  model.gridSize,
                  {ctor: "_Tuple2"
                  ,_0: x2$ - (deskWidth / 2 | 0)
                  ,_1: y2$ - (deskHeight / 2 | 0)});
                  var left = _p8._0;
                  var top = _p8._1;
                  return _U.list([{ctor: "_Tuple2"
                                  ,_0: {ctor: "_Tuple4"
                                       ,_0: prototypeId
                                       ,_1: color
                                       ,_2: name
                                       ,_3: {ctor: "_Tuple2",_0: deskWidth,_1: deskHeight}}
                                  ,_1: {ctor: "_Tuple2",_0: left,_1: top}}]);
               }
         } else {
            return _U.list([]);
         }
   };
   var selectedEquipments = function (model) {
      return A2($List.filterMap,
      function (id) {
         return A2($EquipmentsOperation.findEquipmentById,
         $Util$UndoRedo.data(model.floor).equipments,
         id);
      },
      model.selectedEquipments);
   };
   var primarySelectedEquipment = function (model) {
      var _p9 = model.selectedEquipments;
      if (_p9.ctor === "::") {
            return A2($EquipmentsOperation.findEquipmentById,
            $Floor.equipments($Util$UndoRedo.data(model.floor)),
            _p9._0);
         } else {
            return $Maybe.Nothing;
         }
   };
   var isSelected = F2(function (model,equipment) {
      return A2($List.member,
      $EquipmentsOperation.idOf(equipment),
      model.selectedEquipments);
   });
   var shiftSelectionToward = F2(function (direction,model) {
      var selected = selectedEquipments(model);
      var floor = $Util$UndoRedo.data(model.floor);
      var _p10 = selected;
      if (_p10.ctor === "::") {
            var _p12 = _p10._0;
            var toBeSelected = function () {
               if (model.keys.shift) return A2($List.map,
                  $EquipmentsOperation.idOf,
                  A4($EquipmentsOperation.expandOrShrink,
                  direction,
                  _p12,
                  selected,
                  floor.equipments)); else {
                     var _p11 = A3($EquipmentsOperation.nearest,
                     direction,
                     _p12,
                     floor.equipments);
                     if (_p11.ctor === "Just") {
                           var newEquipments = _U.list([_p11._0]);
                           return A2($List.map,$EquipmentsOperation.idOf,newEquipments);
                        } else {
                           return model.selectedEquipments;
                        }
                  }
            }();
            return _U.update(model,{selectedEquipments: toBeSelected});
         } else {
            return model;
         }
   });
   var updateByMoveEquipmentEnd = F6(function (id,
   _p14,
   _p13,
   ctrlKey,
   shiftKey,
   model) {
      var _p15 = _p14;
      var _p16 = _p13;
      var shift = A2($Scale.screenToImageForPosition,
      model.scale,
      {ctor: "_Tuple2",_0: _p16._0 - _p15._0,_1: _p16._1 - _p15._1});
      return !_U.eq(shift,
      {ctor: "_Tuple2",_0: 0,_1: 0}) ? _U.update(model,
      {floor: A2($Util$UndoRedo.commit,
      model.floor,
      A3($Floor.move,
      model.selectedEquipments,
      model.gridSize,
      shift))}) : $Basics.not(ctrlKey) && $Basics.not(shiftKey) ? _U.update(model,
      {selectedEquipments: _U.list([id])}) : model;
   });
   var updateByKeyAction = F2(function (action,model) {
      var _p17 = {ctor: "_Tuple2",_0: model.keys.ctrl,_1: action};
      _v7_10: do {
         if (_p17.ctor === "_Tuple2") {
               switch (_p17._1.ctor)
               {case "KeyC": if (_p17._0 === true && _p17._1._0 === true) {
                          var newModel = _U.update(model,
                          {copiedEquipments: selectedEquipments(model)});
                          return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
                       } else {
                          break _v7_10;
                       }
                  case "KeyV": if (_p17._0 === true && _p17._1._0 === true) {
                          var _p18 = A2($Util$IdGenerator.zipWithNewIds,
                          model.seed,
                          model.copiedEquipments);
                          var copiedIdsWithNewIds = _p18._0;
                          var newSeed = _p18._1;
                          var selected = A2($List.map,$Basics.snd,copiedIdsWithNewIds);
                          var base = function () {
                             var _p19 = model.selectorRect;
                             if (_p19.ctor === "Just") {
                                   return {ctor: "_Tuple2",_0: _p19._0._0,_1: _p19._0._1};
                                } else {
                                   return {ctor: "_Tuple2",_0: 0,_1: 0};
                                }
                          }();
                          var model$ = _U.update(model,
                          {floor: A2($Util$UndoRedo.commit,
                          model.floor,
                          A2($Floor.paste,copiedIdsWithNewIds,base))
                          ,seed: newSeed});
                          var newModel = _U.update(model$,
                          {selectedEquipments: selected,selectorRect: $Maybe.Nothing});
                          return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
                       } else {
                          break _v7_10;
                       }
                  case "KeyX": if (_p17._0 === true && _p17._1._0 === true) {
                          var newModel = _U.update(model,
                          {floor: A2($Util$UndoRedo.commit,
                          model.floor,
                          $Floor.$delete(model.selectedEquipments))
                          ,copiedEquipments: selectedEquipments(model)
                          ,selectedEquipments: _U.list([])});
                          return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
                       } else {
                          break _v7_10;
                       }
                  case "KeyY": if (_p17._0 === true) {
                          var newModel = _U.update(model,
                          {floor: $Util$UndoRedo.redo(model.floor)});
                          return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
                       } else {
                          break _v7_10;
                       }
                  case "KeyZ": if (_p17._0 === true) {
                          var newModel = _U.update(model,
                          {floor: $Util$UndoRedo.undo(model.floor)});
                          return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
                       } else {
                          break _v7_10;
                       }
                  case "KeyUpArrow": var newModel = A2(shiftSelectionToward,
                    $EquipmentsOperation.Up,
                    model);
                    return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
                  case "KeyDownArrow": var newModel = A2(shiftSelectionToward,
                    $EquipmentsOperation.Down,
                    model);
                    return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
                  case "KeyLeftArrow": var newModel = A2(shiftSelectionToward,
                    $EquipmentsOperation.Left,
                    model);
                    return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
                  case "KeyRightArrow": var newModel = A2(shiftSelectionToward,
                    $EquipmentsOperation.Right,
                    model);
                    return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
                  case "KeyDel": if (_p17._1._0 === true) {
                          var newModel = _U.update(model,
                          {floor: A2($Util$UndoRedo.commit,
                          model.floor,
                          $Floor.$delete(model.selectedEquipments))});
                          return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
                       } else {
                          break _v7_10;
                       }
                  default: break _v7_10;}
            } else {
               break _v7_10;
            }
      } while (false);
      return {ctor: "_Tuple2",_0: model,_1: $Effects.none};
   });
   var debug = false;
   var debugAction = function (action) {
      if (debug) {
            var _p20 = action;
            switch (_p20.ctor)
            {case "MoveOnCanvas": return action;
               case "GotDataURL": return action;
               default: return A2($Debug.log,"action",action);}
         } else return action;
   };
   var Error = function (a) {    return {ctor: "Error",_0: a};};
   var Rotate = function (a) {    return {ctor: "Rotate",_0: a};};
   var InputFloorRealHeight = function (a) {
      return {ctor: "InputFloorRealHeight",_0: a};
   };
   var InputFloorRealWidth = function (a) {
      return {ctor: "InputFloorRealWidth",_0: a};
   };
   var InputFloorName = function (a) {
      return {ctor: "InputFloorName",_0: a};
   };
   var RegisterPrototype = function (a) {
      return {ctor: "RegisterPrototype",_0: a};
   };
   var PrototypesAction = function (a) {
      return {ctor: "PrototypesAction",_0: a};
   };
   var ScaleEnd = {ctor: "ScaleEnd"};
   var GotDataURL = F3(function (a,b,c) {
      return {ctor: "GotDataURL",_0: a,_1: b,_2: c};
   });
   var LoadFile = function (a) {
      return {ctor: "LoadFile",_0: a};
   };
   var ChangeMode = function (a) {
      return {ctor: "ChangeMode",_0: a};
   };
   var MouseWheel = function (a) {
      return {ctor: "MouseWheel",_0: a};
   };
   var WindowDimensions = function (a) {
      return {ctor: "WindowDimensions",_0: a};
   };
   var SelectIsland = F2(function (a,b) {
      return {ctor: "SelectIsland",_0: a,_1: b};
   });
   var ShowContextMenuOnEquipment = F2(function (a,b) {
      return {ctor: "ShowContextMenuOnEquipment",_0: a,_1: b};
   });
   var KeydownOnNameInput = function (a) {
      return {ctor: "KeydownOnNameInput",_0: a};
   };
   var InputName = F2(function (a,b) {
      return {ctor: "InputName",_0: a,_1: b};
   });
   var SelectColor = F2(function (a,b) {
      return {ctor: "SelectColor",_0: a,_1: b};
   });
   var KeysAction = function (a) {
      return {ctor: "KeysAction",_0: a};
   };
   var StartEditEquipment = F2(function (a,b) {
      return {ctor: "StartEditEquipment",_0: a,_1: b};
   });
   var MouseDownOnEquipment = F2(function (a,b) {
      return {ctor: "MouseDownOnEquipment",_0: a,_1: b};
   });
   var MouseDownOnCanvas = function (a) {
      return {ctor: "MouseDownOnCanvas",_0: a};
   };
   var MouseUpOnCanvas = function (a) {
      return {ctor: "MouseUpOnCanvas",_0: a};
   };
   var LeaveCanvas = {ctor: "LeaveCanvas"};
   var EnterCanvas = {ctor: "EnterCanvas"};
   var MoveOnCanvas = function (a) {
      return {ctor: "MoveOnCanvas",_0: a};
   };
   var FloorSaved = {ctor: "FloorSaved"};
   var FloorLoaded = function (a) {
      return {ctor: "FloorLoaded",_0: a};
   };
   var loadFloorEffects = function (hash) {
      var floorId = A2($String.dropLeft,1,hash);
      var task = _U.cmp($String.length(floorId),
      0) > 0 ? A2($Task.onError,
      $API.getEditingFloor(floorId),
      function (e) {
         return $Task.succeed($Floor.init(floorId));
      }) : $Task.succeed($Floor.init("-1"));
      return A2($Util$EffectsUtil.fromTaskWithNoError,
      FloorLoaded,
      task);
   };
   var HashChange = function (a) {
      return {ctor: "HashChange",_0: a};
   };
   var Init = {ctor: "Init"};
   var NoOp = {ctor: "NoOp"};
   var gridSize = 8;
   var inputs = A2($Basics._op["++"],
   A2($List.map,$Signal.map(KeysAction),$Util$Keys.inputs),
   _U.list([A2($Signal.map,WindowDimensions,$Window.dimensions)
           ,A2($Signal.map,HashChange,$Util$HtmlUtil.locationHash)]));
   var StampScreenPos = function (a) {
      return {ctor: "StampScreenPos",_0: a};
   };
   var ShiftOffsetPrevScreenPos = {ctor: "ShiftOffsetPrevScreenPos"};
   var Selector = {ctor: "Selector"};
   var MoveEquipment = F2(function (a,b) {
      return {ctor: "MoveEquipment",_0: a,_1: b};
   });
   var None = {ctor: "None"};
   var Stamp = {ctor: "Stamp"};
   var Pen = {ctor: "Pen"};
   var Select = {ctor: "Select"};
   var Equipment = F2(function (a,b) {
      return {ctor: "Equipment",_0: a,_1: b};
   });
   var NoContextMenu = {ctor: "NoContextMenu"};
   var init = F3(function (randomSeed,initialSize,initialHash) {
      return {ctor: "_Tuple2"
             ,_0: {seed: $Util$IdGenerator.init(randomSeed)
                  ,pos: $Maybe.Nothing
                  ,draggingContext: None
                  ,selectedEquipments: _U.list([])
                  ,copiedEquipments: _U.list([])
                  ,editingEquipment: $Maybe.Nothing
                  ,gridSize: gridSize
                  ,selectorRect: $Maybe.Nothing
                  ,keys: $Util$Keys.init
                  ,editMode: Select
                  ,colorPalette: _U.list(["#ed9"
                                         ,"#b8f"
                                         ,"#fa9"
                                         ,"#8bd"
                                         ,"#af6"
                                         ,"#6df"])
                  ,contextMenu: NoContextMenu
                  ,floor: $Util$UndoRedo.init({data: $Floor.init("-1")
                                              ,update: $Floor.update})
                  ,windowDimensions: initialSize
                  ,scale: $Scale.init
                  ,offset: {ctor: "_Tuple2",_0: 35,_1: 35}
                  ,scaling: false
                  ,prototypes: $Prototypes.init
                  ,errors: _U.list([])
                  ,hash: initialHash
                  ,inputFloorRealWidth: ""
                  ,inputFloorRealHeight: ""}
             ,_1: $Effects.task($Task.succeed(Init))};
   });
   var HtmlError = function (a) {
      return {ctor: "HtmlError",_0: a};
   };
   var focusEffect = function (id) {
      return A3($Util$EffectsUtil.fromTask,
      function (_p21) {
         return Error(HtmlError(_p21));
      },
      $Basics.always(NoOp),
      $Util$HtmlUtil.focus(id));
   };
   var blurEffect = function (id) {
      return A3($Util$EffectsUtil.fromTask,
      function (_p22) {
         return Error(HtmlError(_p22));
      },
      $Basics.always(NoOp),
      $Util$HtmlUtil.blur(id));
   };
   var APIError = function (a) {
      return {ctor: "APIError",_0: a};
   };
   var saveFloorEffects = function (floor) {
      var secondTask = $API.saveEditingFloor(floor);
      var firstTask = function () {
         var _p23 = floor.imageSource;
         if (_p23.ctor === "LocalFile") {
               return A2($API.saveEditingImage,_p23._0,_p23._1);
            } else {
               return $Task.succeed({ctor: "_Tuple0"});
            }
      }();
      return A3($Util$EffectsUtil.fromTask,
      function (_p24) {
         return Error(APIError(_p24));
      },
      $Basics.always(FloorSaved),
      A2($Task.andThen,firstTask,$Basics.always(secondTask)));
   };
   var update = F2(function (action,model) {
      var _p25 = debugAction(action);
      switch (_p25.ctor)
      {case "NoOp": return {ctor: "_Tuple2"
                           ,_0: model
                           ,_1: $Effects.none};
         case "HashChange": var _p26 = _p25._0;
           return {ctor: "_Tuple2"
                  ,_0: _U.update(model,{hash: _p26})
                  ,_1: loadFloorEffects(_p26)};
         case "Init": return {ctor: "_Tuple2"
                             ,_0: model
                             ,_1: loadFloorEffects(model.hash)};
         case "FloorLoaded": var _p28 = _p25._0;
           var _p27 = $Floor.realSize(_p28);
           var realWidth = _p27._0;
           var realHeight = _p27._1;
           var newModel = _U.update(model,
           {floor: $Util$UndoRedo.init({data: _p28,update: $Floor.update})
           ,inputFloorRealWidth: $Basics.toString(realWidth)
           ,inputFloorRealHeight: $Basics.toString(realHeight)});
           return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
         case "FloorSaved": var newModel = _U.update(model,
           {floor: A2($Util$UndoRedo.commit,model.floor,$Floor.useURL)});
           return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
         case "MoveOnCanvas": var _p33 = _p25._0;
           var _p29 = {ctor: "_Tuple2"
                      ,_0: _p33.clientX
                      ,_1: _p33.clientY - 37};
           var x = _p29._0;
           var y = _p29._1;
           var model$ = _U.update(model,
           {pos: $Maybe.Just({ctor: "_Tuple2",_0: x,_1: y})});
           var newModel = function () {
              var _p30 = {ctor: "_Tuple2"
                         ,_0: model.draggingContext
                         ,_1: model.pos};
              if (_p30.ctor === "_Tuple2" && _p30._0.ctor === "ShiftOffsetPrevScreenPos" && _p30._1.ctor === "Just" && _p30._1._0.ctor === "_Tuple2")
              {
                    return _U.update(model$,
                    {offset: function () {
                       var _p31 = {ctor: "_Tuple2"
                                  ,_0: x - _p30._1._0._0
                                  ,_1: y - _p30._1._0._1};
                       var dx = _p31._0;
                       var dy = _p31._1;
                       var _p32 = model.offset;
                       var offsetX = _p32._0;
                       var offsetY = _p32._1;
                       return {ctor: "_Tuple2"
                              ,_0: offsetX + A2($Scale.screenToImage,model.scale,dx)
                              ,_1: offsetY + A2($Scale.screenToImage,model.scale,dy)};
                    }()});
                 } else {
                    return model$;
                 }
           }();
           return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
         case "EnterCanvas": return {ctor: "_Tuple2"
                                    ,_0: model
                                    ,_1: $Effects.none};
         case "LeaveCanvas": var newModel = _U.update(model,
           {draggingContext: function () {
              var _p34 = model.draggingContext;
              if (_p34.ctor === "ShiftOffsetPrevScreenPos") {
                    return None;
                 } else {
                    return model.draggingContext;
                 }
           }()});
           return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
         case "MouseDownOnEquipment": var _p38 = _p25._0;
           var _p37 = _p25._1;
           var newModel = _U.update(model,
           {selectedEquipments: function () {
              if (_p37.ctrlKey) return A2($List.member,
                 _p38,
                 model.selectedEquipments) ? A2($List.filter,
                 F2(function (x,y) {    return !_U.eq(x,y);})(_p38),
                 model.selectedEquipments) : A2($List._op["::"],
                 _p38,
                 model.selectedEquipments); else if (_p37.shiftKey) {
                       var allEquipments = $Util$UndoRedo.data(model.floor).equipments;
                       var equipmentsExcept = function (target) {
                          return A2($List.filter,
                          function (e) {
                             return !_U.eq($EquipmentsOperation.idOf(e),
                             $EquipmentsOperation.idOf(target));
                          },
                          allEquipments);
                       };
                       var _p35 = {ctor: "_Tuple2"
                                  ,_0: A2($EquipmentsOperation.findEquipmentById,
                                  allEquipments,
                                  _p38)
                                  ,_1: primarySelectedEquipment(model)};
                       if (_p35.ctor === "_Tuple2" && _p35._0.ctor === "Just" && _p35._1.ctor === "Just")
                       {
                             var _p36 = _p35._1._0;
                             return A2($List.map,
                             $EquipmentsOperation.idOf,
                             A2($List._op["::"],
                             _p36,
                             A2($EquipmentsOperation.withinRange,
                             {ctor: "_Tuple2",_0: _p36,_1: _p35._0._0},
                             equipmentsExcept(_p36))));
                          } else {
                             return _U.list([_p38]);
                          }
                    } else if (A2($List.member,_p38,model.selectedEquipments))
                    return model.selectedEquipments; else return _U.list([_p38]);
           }()
           ,draggingContext: A2(MoveEquipment,
           _p38,
           {ctor: "_Tuple2",_0: _p37.clientX,_1: _p37.clientY - 37})
           ,selectorRect: $Maybe.Nothing});
           return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
         case "MouseUpOnCanvas": var _p48 = _p25._0;
           var _p39 = function () {
              var _p40 = model.draggingContext;
              _v15_3: do {
                 switch (_p40.ctor)
                 {case "MoveEquipment": if (_p40._1.ctor === "_Tuple2") {
                            var newModel = A6(updateByMoveEquipmentEnd,
                            _p40._0,
                            {ctor: "_Tuple2",_0: _p40._1._0,_1: _p40._1._1},
                            {ctor: "_Tuple2",_0: _p48.clientX,_1: _p48.clientY - 37},
                            _p48.ctrlKey,
                            _p48.shiftKey,
                            model);
                            var effects = saveFloorEffects($Util$UndoRedo.data(newModel.floor));
                            return {ctor: "_Tuple2",_0: newModel,_1: effects};
                         } else {
                            break _v15_3;
                         }
                    case "Selector": return {ctor: "_Tuple2"
                                            ,_0: _U.update(model,
                                            {selectorRect: function () {
                                               var _p41 = model.selectorRect;
                                               if (_p41.ctor === "Just" && _p41._0.ctor === "_Tuple4") {
                                                     var _p44 = _p41._0._1;
                                                     var _p43 = _p41._0._0;
                                                     var _p42 = {ctor: "_Tuple2"
                                                                ,_0: A2($Scale.screenToImage,model.scale,_p48.clientX) - _p43
                                                                ,_1: A2($Scale.screenToImage,
                                                                model.scale,
                                                                _p48.clientY) - 37 - _p44};
                                                     var w = _p42._0;
                                                     var h = _p42._1;
                                                     return $Maybe.Just({ctor: "_Tuple4"
                                                                        ,_0: _p43
                                                                        ,_1: _p44
                                                                        ,_2: w
                                                                        ,_3: h});
                                                  } else {
                                                     return model.selectorRect;
                                                  }
                                            }()})
                                            ,_1: $Effects.none};
                    case "StampScreenPos":
                    var _p45 = A2($Util$IdGenerator.zipWithNewIds,
                      model.seed,
                      stampCandidates(model));
                      var candidatesWithNewIds = _p45._0;
                      var newSeed = _p45._1;
                      var candidatesWithNewIds$ = A2($List.map,
                      function (_p46) {
                         var _p47 = _p46;
                         return {ctor: "_Tuple4"
                                ,_0: _p47._1
                                ,_1: {ctor: "_Tuple4"
                                     ,_0: _p47._0._1._0
                                     ,_1: _p47._0._1._1
                                     ,_2: _p47._0._0._3._0
                                     ,_3: _p47._0._0._3._1}
                                ,_2: _p47._0._0._1
                                ,_3: _p47._0._0._2};
                      },
                      candidatesWithNewIds);
                      var newFloor = A2($Util$UndoRedo.commit,
                      model.floor,
                      $Floor.create(candidatesWithNewIds$));
                      var effects = saveFloorEffects($Util$UndoRedo.data(newFloor));
                      return {ctor: "_Tuple2"
                             ,_0: _U.update(model,{seed: newSeed,floor: newFloor})
                             ,_1: effects};
                    default: break _v15_3;}
              } while (false);
              return {ctor: "_Tuple2",_0: model,_1: $Effects.none};
           }();
           var model$ = _p39._0;
           var effects = _p39._1;
           var newModel = _U.update(model$,{draggingContext: None});
           return {ctor: "_Tuple2",_0: newModel,_1: effects};
         case "MouseDownOnCanvas": var _p53 = _p25._0;
           var draggingContext = function () {
              var _p49 = model.editMode;
              switch (_p49.ctor)
              {case "Stamp": return StampScreenPos({ctor: "_Tuple2"
                                                   ,_0: _p53.clientX
                                                   ,_1: _p53.clientY - 37});
                 case "Pen": return None;
                 default: return ShiftOffsetPrevScreenPos;}
           }();
           var selectorRect = function () {
              var _p50 = model.editMode;
              if (_p50.ctor === "Select") {
                    var _p51 = A2($EquipmentsOperation.fitToGrid,
                    model.gridSize,
                    A2($Scale.screenToImageForPosition,
                    model.scale,
                    {ctor: "_Tuple2",_0: _p53.layerX,_1: _p53.layerY}));
                    var x = _p51._0;
                    var y = _p51._1;
                    return $Maybe.Just({ctor: "_Tuple4"
                                       ,_0: x
                                       ,_1: y
                                       ,_2: model.gridSize
                                       ,_3: model.gridSize});
                 } else {
                    return model.selectorRect;
                 }
           }();
           var model$ = function () {
              var _p52 = model.editingEquipment;
              if (_p52.ctor === "Just") {
                    return _U.update(model,
                    {floor: A2($Util$UndoRedo.commit,
                    model.floor,
                    A2($Floor.changeEquipmentName,_p52._0._0,_p52._0._1))});
                 } else {
                    return model;
                 }
           }();
           var newModel = _U.update(model$,
           {selectedEquipments: _U.list([])
           ,selectorRect: selectorRect
           ,editingEquipment: $Maybe.Nothing
           ,contextMenu: NoContextMenu
           ,draggingContext: draggingContext});
           return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
         case "StartEditEquipment":
         var _p54 = A2($EquipmentsOperation.findEquipmentById,
           $Util$UndoRedo.data(model.floor).equipments,
           _p25._0);
           if (_p54.ctor === "Just") {
                 var _p55 = _p54._0;
                 var newModel = _U.update(model,
                 {editingEquipment: $Maybe.Just({ctor: "_Tuple2"
                                                ,_0: $EquipmentsOperation.idOf(_p55)
                                                ,_1: $EquipmentsOperation.nameOf(_p55)})
                 ,contextMenu: NoContextMenu});
                 return {ctor: "_Tuple2"
                        ,_0: newModel
                        ,_1: focusEffect("name-input")};
              } else {
                 return {ctor: "_Tuple2",_0: model,_1: $Effects.none};
              }
         case "SelectColor": var newModel = _U.update(model,
           {floor: A2($Util$UndoRedo.commit,
           model.floor,
           A2($Floor.changeEquipmentColor,
           model.selectedEquipments,
           _p25._0))});
           return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
         case "InputName": var _p58 = _p25._0;
           var newModel = _U.update(model,
           {editingEquipment: function () {
              var _p56 = model.editingEquipment;
              if (_p56.ctor === "Just") {
                    var _p57 = _p56._0._0;
                    return _U.eq(_p58,_p57) ? $Maybe.Just({ctor: "_Tuple2"
                                                          ,_0: _p58
                                                          ,_1: _p25._1}) : $Maybe.Just({ctor: "_Tuple2"
                                                                                       ,_0: _p57
                                                                                       ,_1: _p56._0._1});
                 } else {
                    return $Maybe.Nothing;
                 }
           }()});
           return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
         case "KeydownOnNameInput": var _p67 = _p25._0;
           var _p59 = function () {
              if (_U.eq(_p67.keyCode,13) && $Basics.not(_p67.ctrlKey)) {
                    var newModel = function () {
                       var _p60 = model.editingEquipment;
                       if (_p60.ctor === "Just") {
                             var _p65 = _p60._0._0;
                             var allEquipments = $Util$UndoRedo.data(model.floor).equipments;
                             var editingEquipment = function () {
                                var _p61 = A2($EquipmentsOperation.findEquipmentById,
                                allEquipments,
                                _p65);
                                if (_p61.ctor === "Just") {
                                      var _p64 = _p61._0;
                                      var island$ = A2($EquipmentsOperation.island,
                                      _U.list([_p64]),
                                      A2($List.filter,
                                      function (e) {
                                         return !_U.eq($EquipmentsOperation.idOf(e),_p65);
                                      },
                                      allEquipments));
                                      var _p62 = A3($EquipmentsOperation.nearest,
                                      $EquipmentsOperation.Down,
                                      _p64,
                                      island$);
                                      if (_p62.ctor === "Just") {
                                            var _p63 = _p62._0;
                                            return $Maybe.Just({ctor: "_Tuple2"
                                                               ,_0: $EquipmentsOperation.idOf(_p63)
                                                               ,_1: $EquipmentsOperation.nameOf(_p63)});
                                         } else {
                                            return $Maybe.Nothing;
                                         }
                                   } else {
                                      return $Maybe.Nothing;
                                   }
                             }();
                             return _U.update(model,
                             {floor: A2($Util$UndoRedo.commit,
                             model.floor,
                             A2($Floor.changeEquipmentName,_p65,_p60._0._1))
                             ,editingEquipment: editingEquipment});
                          } else {
                             return model;
                          }
                    }();
                    return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
                 } else if (_U.eq(_p67.keyCode,13)) {
                       var newModel = _U.update(model,
                       {editingEquipment: function () {
                          var _p66 = model.editingEquipment;
                          if (_p66.ctor === "Just") {
                                return $Maybe.Just({ctor: "_Tuple2"
                                                   ,_0: _p66._0._0
                                                   ,_1: A2($Basics._op["++"],_p66._0._1,"\n")});
                             } else {
                                return $Maybe.Nothing;
                             }
                       }()});
                       return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
                    } else return {ctor: "_Tuple2",_0: model,_1: $Effects.none};
           }();
           var newModel = _p59._0;
           var effects = _p59._1;
           return {ctor: "_Tuple2",_0: newModel,_1: effects};
         case "ShowContextMenuOnEquipment": var _p68 = _p25._1;
           var newModel = _U.update(model,
           {contextMenu: A2(Equipment,
           {ctor: "_Tuple2",_0: _p68.clientX,_1: _p68.clientY},
           _p25._0)});
           return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
         case "SelectIsland": var _p70 = _p25._0;
           var newModel = function () {
              var _p69 = A2($EquipmentsOperation.findEquipmentById,
              $Util$UndoRedo.data(model.floor).equipments,
              _p70);
              if (_p69.ctor === "Just") {
                    var island$ = A2($EquipmentsOperation.island,
                    _U.list([_p69._0]),
                    A2($List.filter,
                    function (e) {
                       return !_U.eq($EquipmentsOperation.idOf(e),_p70);
                    },
                    $Util$UndoRedo.data(model.floor).equipments));
                    return _U.update(model,
                    {selectedEquipments: A2($List.map,
                    $EquipmentsOperation.idOf,
                    island$)
                    ,contextMenu: NoContextMenu});
                 } else {
                    return model;
                 }
           }();
           return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
         case "KeysAction": var _p71 = _p25._0;
           var model$ = _U.update(model,
           {keys: A2($Util$Keys.update,_p71,model.keys)});
           return A2(updateByKeyAction,_p71,model$);
         case "MouseWheel": var _p73 = _p25._0;
           var effects = A2($Util$EffectsUtil.fromTaskWithNoError,
           $Basics.always(ScaleEnd),
           $Task.sleep(200.0));
           var _p72 = model.offset;
           var offsetX = _p72._0;
           var offsetY = _p72._1;
           var newScale = _U.cmp(_p73.value,0) < 0 ? A2($Scale.update,
           $Scale.ScaleUp,
           model.scale) : A2($Scale.update,$Scale.ScaleDown,model.scale);
           var ratio = A2($Scale.ratio,model.scale,newScale);
           var newOffset = function () {
              var y = A2($Scale.screenToImage,
              model.scale,
              _p73.clientY - 37);
              var x = A2($Scale.screenToImage,model.scale,_p73.clientX);
              return {ctor: "_Tuple2"
                     ,_0: $Basics.floor($Basics.toFloat(x - $Basics.floor(ratio * $Basics.toFloat(x - offsetX))) / ratio)
                     ,_1: $Basics.floor($Basics.toFloat(y - $Basics.floor(ratio * $Basics.toFloat(y - offsetY))) / ratio)};
           }();
           var newModel = _U.update(model,
           {scale: newScale,offset: newOffset,scaling: true});
           return {ctor: "_Tuple2",_0: newModel,_1: effects};
         case "ScaleEnd": var newModel = _U.update(model,
           {scaling: false});
           return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
         case "WindowDimensions": var newModel = _U.update(model,
           {windowDimensions: {ctor: "_Tuple2"
                              ,_0: _p25._0._0
                              ,_1: _p25._0._1}});
           return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
         case "ChangeMode": var newModel = _U.update(model,
           {editMode: _p25._0});
           return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
         case "LoadFile": var _p76 = _p25._0;
           var _p74 = $Util$IdGenerator.$new(model.seed);
           var id = _p74._0;
           var newSeed = _p74._1;
           var newModel = _U.update(model,{seed: newSeed});
           var effects = A3($Util$EffectsUtil.fromTask,
           function (_p75) {
              return Error(HtmlError(_p75));
           },
           A2(GotDataURL,id,_p76),
           $Util$HtmlUtil.readFirstAsDataURL(_p76));
           return {ctor: "_Tuple2",_0: model,_1: effects};
         case "GotDataURL": var newModel = _U.update(model,
           {floor: A2($Util$UndoRedo.commit,
           model.floor,
           A3($Floor.setLocalFile,_p25._0,_p25._1,_p25._2))});
           var effects = saveFloorEffects($Util$UndoRedo.data(newModel.floor));
           return {ctor: "_Tuple2",_0: newModel,_1: effects};
         case "PrototypesAction": var newModel = _U.update(model,
           {prototypes: A2($Prototypes.update,_p25._0,model.prototypes)});
           return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
         case "RegisterPrototype": var model$ = _U.update(model,
           {contextMenu: NoContextMenu});
           var equipment = A2($EquipmentsOperation.findEquipmentById,
           $Util$UndoRedo.data(model.floor).equipments,
           _p25._0);
           var newModel = function () {
              var _p77 = equipment;
              if (_p77.ctor === "Just") {
                    var _p80 = _p77._0;
                    var _p78 = $Util$IdGenerator.$new(model.seed);
                    var newId = _p78._0;
                    var seed = _p78._1;
                    var _p79 = $EquipmentsOperation.rect(_p80);
                    var w = _p79._2;
                    var h = _p79._3;
                    var newPrototypes = A2($Prototypes.register,
                    {ctor: "_Tuple4"
                    ,_0: newId
                    ,_1: $EquipmentsOperation.colorOf(_p80)
                    ,_2: $EquipmentsOperation.nameOf(_p80)
                    ,_3: {ctor: "_Tuple2",_0: w,_1: h}},
                    model.prototypes);
                    return _U.update(model$,{seed: seed,prototypes: newPrototypes});
                 } else {
                    return model$;
                 }
           }();
           return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
         case "InputFloorName": var newFloor = A2($Util$UndoRedo.commit,
           model.floor,
           $Floor.changeName(_p25._0));
           var effects = saveFloorEffects($Util$UndoRedo.data(newFloor));
           var newModel = _U.update(model,{floor: newFloor});
           return {ctor: "_Tuple2",_0: newModel,_1: effects};
         case "InputFloorRealWidth": var _p83 = _p25._0;
           var newFloor = function () {
              var _p81 = $String.toInt(_p83);
              if (_p81.ctor === "Err") {
                    return model.floor;
                 } else {
                    var _p82 = _p81._0;
                    return _U.cmp(_p82,0) > 0 ? A2($Util$UndoRedo.commit,
                    model.floor,
                    $Floor.changeRealWidth(_p82)) : model.floor;
                 }
           }();
           var newModel = _U.update(model,
           {floor: newFloor,inputFloorRealWidth: _p83});
           return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
         case "InputFloorRealHeight": var _p86 = _p25._0;
           var newFloor = function () {
              var _p84 = $String.toInt(_p86);
              if (_p84.ctor === "Err") {
                    return model.floor;
                 } else {
                    var _p85 = _p84._0;
                    return _U.cmp(_p85,0) > 0 ? A2($Util$UndoRedo.commit,
                    model.floor,
                    $Floor.changeRealHeight(_p85)) : model.floor;
                 }
           }();
           var newModel = _U.update(model,
           {floor: newFloor,inputFloorRealHeight: _p86});
           return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
         case "Rotate": var newFloor = A2($Util$UndoRedo.commit,
           model.floor,
           $Floor.rotate(_p25._0));
           var newModel = _U.update(model,
           {floor: newFloor,contextMenu: NoContextMenu});
           return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};
         default: var newModel = _U.update(model,
           {errors: A2($List._op["::"],_p25._0,model.errors)});
           return {ctor: "_Tuple2",_0: newModel,_1: $Effects.none};}
   });
   var Model = function (a) {
      return function (b) {
         return function (c) {
            return function (d) {
               return function (e) {
                  return function (f) {
                     return function (g) {
                        return function (h) {
                           return function (i) {
                              return function (j) {
                                 return function (k) {
                                    return function (l) {
                                       return function (m) {
                                          return function (n) {
                                             return function (o) {
                                                return function (p) {
                                                   return function (q) {
                                                      return function (r) {
                                                         return function (s) {
                                                            return function (t) {
                                                               return function (u) {
                                                                  return function (v) {
                                                                     return {seed: a
                                                                            ,pos: b
                                                                            ,draggingContext: c
                                                                            ,selectedEquipments: d
                                                                            ,copiedEquipments: e
                                                                            ,editingEquipment: f
                                                                            ,gridSize: g
                                                                            ,selectorRect: h
                                                                            ,keys: i
                                                                            ,editMode: j
                                                                            ,colorPalette: k
                                                                            ,contextMenu: l
                                                                            ,floor: m
                                                                            ,windowDimensions: n
                                                                            ,scale: o
                                                                            ,offset: p
                                                                            ,scaling: q
                                                                            ,prototypes: r
                                                                            ,errors: s
                                                                            ,hash: t
                                                                            ,inputFloorRealWidth: u
                                                                            ,inputFloorRealHeight: v};
                                                                  };
                                                               };
                                                            };
                                                         };
                                                      };
                                                   };
                                                };
                                             };
                                          };
                                       };
                                    };
                                 };
                              };
                           };
                        };
                     };
                  };
               };
            };
         };
      };
   };
   return _elm.Model.values = {_op: _op
                              ,Model: Model
                              ,APIError: APIError
                              ,HtmlError: HtmlError
                              ,NoContextMenu: NoContextMenu
                              ,Equipment: Equipment
                              ,Select: Select
                              ,Pen: Pen
                              ,Stamp: Stamp
                              ,None: None
                              ,MoveEquipment: MoveEquipment
                              ,Selector: Selector
                              ,ShiftOffsetPrevScreenPos: ShiftOffsetPrevScreenPos
                              ,StampScreenPos: StampScreenPos
                              ,inputs: inputs
                              ,gridSize: gridSize
                              ,init: init
                              ,NoOp: NoOp
                              ,Init: Init
                              ,HashChange: HashChange
                              ,FloorLoaded: FloorLoaded
                              ,FloorSaved: FloorSaved
                              ,MoveOnCanvas: MoveOnCanvas
                              ,EnterCanvas: EnterCanvas
                              ,LeaveCanvas: LeaveCanvas
                              ,MouseUpOnCanvas: MouseUpOnCanvas
                              ,MouseDownOnCanvas: MouseDownOnCanvas
                              ,MouseDownOnEquipment: MouseDownOnEquipment
                              ,StartEditEquipment: StartEditEquipment
                              ,KeysAction: KeysAction
                              ,SelectColor: SelectColor
                              ,InputName: InputName
                              ,KeydownOnNameInput: KeydownOnNameInput
                              ,ShowContextMenuOnEquipment: ShowContextMenuOnEquipment
                              ,SelectIsland: SelectIsland
                              ,WindowDimensions: WindowDimensions
                              ,MouseWheel: MouseWheel
                              ,ChangeMode: ChangeMode
                              ,LoadFile: LoadFile
                              ,GotDataURL: GotDataURL
                              ,ScaleEnd: ScaleEnd
                              ,PrototypesAction: PrototypesAction
                              ,RegisterPrototype: RegisterPrototype
                              ,InputFloorName: InputFloorName
                              ,InputFloorRealWidth: InputFloorRealWidth
                              ,InputFloorRealHeight: InputFloorRealHeight
                              ,Rotate: Rotate
                              ,Error: Error
                              ,debug: debug
                              ,debugAction: debugAction
                              ,update: update
                              ,saveFloorEffects: saveFloorEffects
                              ,updateByKeyAction: updateByKeyAction
                              ,updateByMoveEquipmentEnd: updateByMoveEquipmentEnd
                              ,shiftSelectionToward: shiftSelectionToward
                              ,loadFloorEffects: loadFloorEffects
                              ,focusEffect: focusEffect
                              ,blurEffect: blurEffect
                              ,isSelected: isSelected
                              ,primarySelectedEquipment: primarySelectedEquipment
                              ,selectedEquipments: selectedEquipments
                              ,stampCandidates: stampCandidates};
};
Elm.Styles = Elm.Styles || {};
Elm.Styles.make = function (_elm) {
   "use strict";
   _elm.Styles = _elm.Styles || {};
   if (_elm.Styles.values) return _elm.Styles.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm);
   var _op = {};
   var realSizeInput = _U.list([{ctor: "_Tuple2"
                                ,_0: "width"
                                ,_1: "30px"}]);
   var prototypePreviewScroll = _U.list([{ctor: "_Tuple2"
                                         ,_0: "width"
                                         ,_1: "30px"}
                                        ,{ctor: "_Tuple2",_0: "height",_1: "30px"}
                                        ,{ctor: "_Tuple2",_0: "font-size",_1: "large"}
                                        ,{ctor: "_Tuple2",_0: "font-weight",_1: "bold"}
                                        ,{ctor: "_Tuple2",_0: "line-height",_1: "30px"}
                                        ,{ctor: "_Tuple2",_0: "position",_1: "absolute"}
                                        ,{ctor: "_Tuple2",_0: "top",_1: "104px"}
                                        ,{ctor: "_Tuple2",_0: "border-radius",_1: "15px"}
                                        ,{ctor: "_Tuple2",_0: "text-align",_1: "center"}
                                        ,{ctor: "_Tuple2",_0: "color",_1: "#fff"}
                                        ,{ctor: "_Tuple2",_0: "background-color",_1: "#ccc"}
                                        ,{ctor: "_Tuple2",_0: "cursor",_1: "pointer"}]);
   var prototypePreviewViewInner = function (index) {
      return _U.list([{ctor: "_Tuple2",_0: "width",_1: "238px"}
                     ,{ctor: "_Tuple2",_0: "height",_1: "238px"}
                     ,{ctor: "_Tuple2",_0: "position",_1: "relative"}
                     ,{ctor: "_Tuple2",_0: "top",_1: "0"}
                     ,{ctor: "_Tuple2"
                      ,_0: "left"
                      ,_1: A2($Basics._op["++"],$Basics.toString(index * -238),"px")}
                     ,{ctor: "_Tuple2",_0: "transition-property",_1: "left"}
                     ,{ctor: "_Tuple2",_0: "transition-duration",_1: "0.2s"}]);
   };
   var prototypePreviewView = function (stampMode) {
      return _U.list([{ctor: "_Tuple2",_0: "width",_1: "238px"}
                     ,{ctor: "_Tuple2",_0: "height",_1: "238px"}
                     ,{ctor: "_Tuple2",_0: "position",_1: "relative"}
                     ,{ctor: "_Tuple2",_0: "border-style",_1: "solid"}
                     ,{ctor: "_Tuple2"
                      ,_0: "border-width"
                      ,_1: stampMode ? "2px" : "1px"}
                     ,{ctor: "_Tuple2"
                      ,_0: "border-color"
                      ,_1: stampMode ? "#69e" : "#666"}
                     ,{ctor: "_Tuple2",_0: "box-sizing",_1: "border-box"}
                     ,{ctor: "_Tuple2",_0: "margin-top",_1: "10px"}
                     ,{ctor: "_Tuple2",_0: "background-color",_1: "#fff"}
                     ,{ctor: "_Tuple2",_0: "overflow",_1: "hidden"}]);
   };
   var transition = function (disabled) {
      return disabled ? _U.list([]) : _U.list([{ctor: "_Tuple2"
                                               ,_0: "transition-property"
                                               ,_1: "width, height, top, left"}
                                              ,{ctor: "_Tuple2",_0: "transition-duration",_1: "0.2s"}]);
   };
   var selection = function (selected) {
      return _U.list([{ctor: "_Tuple2",_0: "cursor",_1: "pointer"}
                     ,{ctor: "_Tuple2",_0: "padding-top",_1: "8px"}
                     ,{ctor: "_Tuple2",_0: "padding-bottom",_1: "4px"}
                     ,{ctor: "_Tuple2",_0: "text-align",_1: "center"}
                     ,{ctor: "_Tuple2",_0: "box-sizing",_1: "border-box"}
                     ,{ctor: "_Tuple2",_0: "margin-right",_1: "-1px"}
                     ,{ctor: "_Tuple2",_0: "border",_1: "solid 1px #666"}
                     ,{ctor: "_Tuple2"
                      ,_0: "background-color"
                      ,_1: selected ? "#69e" : "inherit"}
                     ,{ctor: "_Tuple2"
                      ,_0: "color"
                      ,_1: selected ? "#fff" : "inherit"}]);
   };
   var shadow = _U.list([{ctor: "_Tuple2"
                         ,_0: "box-shadow"
                         ,_1: "0 2px 2px 0 rgba(0,0,0,.14),0 3px 1px -2px rgba(0,0,0,.2),0 1px 5px 0 rgba(0,0,0,.12)"}]);
   var card = A2($Basics._op["++"],
   _U.list([{ctor: "_Tuple2",_0: "margin",_1: "5px"}
           ,{ctor: "_Tuple2",_0: "padding",_1: "5px"}]),
   shadow);
   var nameLabel = function (ratio) {
      return _U.list([{ctor: "_Tuple2"
                      ,_0: "display"
                      ,_1: "table-cell"}
                     ,{ctor: "_Tuple2",_0: "vertical-align",_1: "middle"}
                     ,{ctor: "_Tuple2",_0: "text-align",_1: "center"}
                     ,{ctor: "_Tuple2",_0: "position",_1: "absolute"}
                     ,{ctor: "_Tuple2",_0: "cursor",_1: "default"}
                     ,{ctor: "_Tuple2"
                      ,_0: "font-size"
                      ,_1: A2($Basics._op["++"],$Basics.toString(ratio),"em")}]);
   };
   var canvasContainer = _U.list([{ctor: "_Tuple2"
                                  ,_0: "position"
                                  ,_1: "relative"}
                                 ,{ctor: "_Tuple2",_0: "overflow",_1: "hidden"}
                                 ,{ctor: "_Tuple2",_0: "background",_1: "#000"}
                                 ,{ctor: "_Tuple2",_0: "flex",_1: "1"}]);
   var contextMenuItem = _U.list([{ctor: "_Tuple2"
                                  ,_0: "padding"
                                  ,_1: "5px"}]);
   var colorProperty = F2(function (color,selected) {
      return _U.list([{ctor: "_Tuple2"
                      ,_0: "background-color"
                      ,_1: color}
                     ,{ctor: "_Tuple2",_0: "cursor",_1: "pointer"}
                     ,{ctor: "_Tuple2",_0: "width",_1: "30px"}
                     ,{ctor: "_Tuple2",_0: "height",_1: "30px"}
                     ,{ctor: "_Tuple2",_0: "box-sizing",_1: "border-box"}
                     ,{ctor: "_Tuple2",_0: "border-style",_1: "solid"}
                     ,{ctor: "_Tuple2",_0: "margin-right",_1: "2px"}
                     ,{ctor: "_Tuple2"
                      ,_0: "border-width"
                      ,_1: selected ? "2px" : "1px"}
                     ,{ctor: "_Tuple2"
                      ,_0: "border-color"
                      ,_1: selected ? "#69e" : "#666"}]);
   });
   var rect = function (_p0) {
      var _p1 = _p0;
      return _U.list([{ctor: "_Tuple2"
                      ,_0: "top"
                      ,_1: A2($Basics._op["++"],$Basics.toString(_p1._1),"px")}
                     ,{ctor: "_Tuple2"
                      ,_0: "left"
                      ,_1: A2($Basics._op["++"],$Basics.toString(_p1._0),"px")}
                     ,{ctor: "_Tuple2"
                      ,_0: "width"
                      ,_1: A2($Basics._op["++"],$Basics.toString(_p1._2),"px")}
                     ,{ctor: "_Tuple2"
                      ,_0: "height"
                      ,_1: A2($Basics._op["++"],$Basics.toString(_p1._3),"px")}]);
   };
   var absoluteRect = function (rect$) {
      return A2($List._op["::"],
      {ctor: "_Tuple2",_0: "position",_1: "absolute"},
      rect(rect$));
   };
   var canvasView = function (rect) {
      return A2($Basics._op["++"],
      absoluteRect(rect),
      _U.list([{ctor: "_Tuple2",_0: "background-color",_1: "#fff"}
              ,{ctor: "_Tuple2",_0: "overflow",_1: "hidden"}
              ,{ctor: "_Tuple2",_0: "font-family",_1: "default"}]));
   };
   var headerHeight = 37;
   var ul = _U.list([{ctor: "_Tuple2"
                     ,_0: "list-style-type"
                     ,_1: "none"}
                    ,{ctor: "_Tuple2",_0: "padding-left",_1: "0"}]);
   var flex = _U.list([{ctor: "_Tuple2"
                       ,_0: "display"
                       ,_1: "flex"}]);
   var noPadding = _U.list([{ctor: "_Tuple2"
                            ,_0: "padding"
                            ,_1: "0"}]);
   var noMargin = _U.list([{ctor: "_Tuple2"
                           ,_0: "margin"
                           ,_1: "0"}]);
   var h1 = A2($Basics._op["++"],
   noMargin,
   _U.list([{ctor: "_Tuple2",_0: "font-size",_1: "1.4em"}
           ,{ctor: "_Tuple2",_0: "font-weight",_1: "normal"}
           ,{ctor: "_Tuple2"
            ,_0: "line-height"
            ,_1: A2($Basics._op["++"],
            $Basics.toString(headerHeight),
            "px")}]));
   var header = A2($Basics._op["++"],
   noMargin,
   _U.list([{ctor: "_Tuple2"
            ,_0: "background"
            ,_1: "rgb(100, 180, 85)"}
           ,{ctor: "_Tuple2",_0: "color",_1: "#eee"}
           ,{ctor: "_Tuple2"
            ,_0: "height"
            ,_1: A2($Basics._op["++"],$Basics.toString(headerHeight),"px")}
           ,{ctor: "_Tuple2",_0: "padding-left",_1: "10px"}]));
   var zIndex = {selectedDesk: "100"
                ,deskInput: "200"
                ,selectorRect: "300"
                ,subMenu: "600"
                ,contextMenu: "800"};
   var deskInput = function (rect) {
      return A2($Basics._op["++"],
      absoluteRect(rect),
      A2($Basics._op["++"],
      noPadding,
      _U.list([{ctor: "_Tuple2",_0: "z-index",_1: zIndex.deskInput}
              ,{ctor: "_Tuple2",_0: "box-sizing",_1: "border-box"}])));
   };
   var desk = F4(function (rect,color,selected,alpha) {
      return A2($Basics._op["++"],
      absoluteRect(rect),
      _U.list([{ctor: "_Tuple2"
               ,_0: "opacity"
               ,_1: alpha ? "0.5" : "1.0"}
              ,{ctor: "_Tuple2",_0: "background-color",_1: color}
              ,{ctor: "_Tuple2",_0: "box-sizing",_1: "border-box"}
              ,{ctor: "_Tuple2"
               ,_0: "z-index"
               ,_1: selected ? zIndex.selectedDesk : ""}
              ,{ctor: "_Tuple2",_0: "border-style",_1: "solid"}
              ,{ctor: "_Tuple2"
               ,_0: "border-width"
               ,_1: selected ? "2px" : "1px"}
              ,{ctor: "_Tuple2"
               ,_0: "border-color"
               ,_1: selected ? "#69e" : "#666"}]));
   });
   var selectorRect = function (rect) {
      return A2($Basics._op["++"],
      absoluteRect(rect),
      _U.list([{ctor: "_Tuple2",_0: "z-index",_1: zIndex.selectorRect}
              ,{ctor: "_Tuple2",_0: "border-style",_1: "solid"}
              ,{ctor: "_Tuple2",_0: "border-width",_1: "2px"}
              ,{ctor: "_Tuple2",_0: "border-color",_1: "#69e"}]));
   };
   var subMenu = _U.list([{ctor: "_Tuple2"
                          ,_0: "z-index"
                          ,_1: zIndex.subMenu}
                         ,{ctor: "_Tuple2",_0: "width",_1: "300px"}
                         ,{ctor: "_Tuple2",_0: "overflow",_1: "hidden"}
                         ,{ctor: "_Tuple2",_0: "background",_1: "#eee"}]);
   var contextMenu = F3(function (_p3,_p2,rows) {
      var _p4 = _p3;
      var _p5 = _p2;
      var height = rows * 20;
      var y$ = A2($Basics.min,_p4._1,_p5._1 - height);
      var width = 200;
      var x$ = A2($Basics.min,_p4._0,_p5._0 - width);
      return _U.list([{ctor: "_Tuple2"
                      ,_0: "width"
                      ,_1: A2($Basics._op["++"],$Basics.toString(width),"px")}
                     ,{ctor: "_Tuple2"
                      ,_0: "left"
                      ,_1: A2($Basics._op["++"],$Basics.toString(x$),"px")}
                     ,{ctor: "_Tuple2"
                      ,_0: "top"
                      ,_1: A2($Basics._op["++"],$Basics.toString(y$),"px")}
                     ,{ctor: "_Tuple2",_0: "position",_1: "fixed"}
                     ,{ctor: "_Tuple2",_0: "z-index",_1: zIndex.contextMenu}
                     ,{ctor: "_Tuple2",_0: "background-color",_1: "#fff"}
                     ,{ctor: "_Tuple2",_0: "box-sizing",_1: "border-box"}
                     ,{ctor: "_Tuple2",_0: "border-style",_1: "solid"}
                     ,{ctor: "_Tuple2",_0: "border-width",_1: "1px"}
                     ,{ctor: "_Tuple2",_0: "border-color",_1: "#eee"}]);
   });
   return _elm.Styles.values = {_op: _op
                               ,zIndex: zIndex
                               ,noMargin: noMargin
                               ,noPadding: noPadding
                               ,flex: flex
                               ,h1: h1
                               ,ul: ul
                               ,headerHeight: headerHeight
                               ,header: header
                               ,rect: rect
                               ,absoluteRect: absoluteRect
                               ,deskInput: deskInput
                               ,desk: desk
                               ,selectorRect: selectorRect
                               ,colorProperty: colorProperty
                               ,subMenu: subMenu
                               ,contextMenu: contextMenu
                               ,contextMenuItem: contextMenuItem
                               ,canvasView: canvasView
                               ,canvasContainer: canvasContainer
                               ,nameLabel: nameLabel
                               ,shadow: shadow
                               ,card: card
                               ,selection: selection
                               ,transition: transition
                               ,prototypePreviewView: prototypePreviewView
                               ,prototypePreviewViewInner: prototypePreviewViewInner
                               ,prototypePreviewScroll: prototypePreviewScroll
                               ,realSizeInput: realSizeInput};
};
Elm.View = Elm.View || {};
Elm.View.make = function (_elm) {
   "use strict";
   _elm.View = _elm.View || {};
   if (_elm.View.values) return _elm.View.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $Equipments = Elm.Equipments.make(_elm),
   $EquipmentsOperation = Elm.EquipmentsOperation.make(_elm),
   $Floor = Elm.Floor.make(_elm),
   $Html = Elm.Html.make(_elm),
   $Html$Attributes = Elm.Html.Attributes.make(_elm),
   $Icons = Elm.Icons.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Model = Elm.Model.make(_elm),
   $Prototypes = Elm.Prototypes.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Scale = Elm.Scale.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $Styles = Elm.Styles.make(_elm),
   $Util$HtmlUtil = Elm.Util.HtmlUtil.make(_elm),
   $Util$ListUtil = Elm.Util.ListUtil.make(_elm),
   $Util$UndoRedo = Elm.Util.UndoRedo.make(_elm);
   var _op = {};
   var colorPropertyView = F2(function (address,model) {
      var match = function (color) {
         var _p0 = $EquipmentsOperation.colorProperty($Model.selectedEquipments(model));
         if (_p0.ctor === "Just") {
               return _U.eq(color,_p0._0);
            } else {
               return false;
            }
      };
      var viewForEach = function (color) {
         return A2($Html.li,
         _U.list([$Html$Attributes.style(A2($Styles.colorProperty,
                 color,
                 match(color)))
                 ,$Util$HtmlUtil.onMouseDown$(A2($Signal.forwardTo,
                 address,
                 $Model.SelectColor(color)))]),
         _U.list([]));
      };
      return A2($Html.ul,
      _U.list([$Html$Attributes.style(A2($Basics._op["++"],
      $Styles.ul,
      _U.list([{ctor: "_Tuple2",_0: "display",_1: "flex"}])))]),
      A2($List.map,viewForEach,model.colorPalette));
   });
   var debugView = F2(function (address,model) {
      return _U.list([$Html.text($Basics.toString(A2($List.map,
                     $EquipmentsOperation.idOf,
                     model.copiedEquipments)))
                     ,A2($Html.br,_U.list([]),_U.list([]))
                     ,$Html.text($Basics.toString(model.keys.ctrl))
                     ,A2($Html.br,_U.list([]),_U.list([]))
                     ,$Html.text($Basics.toString(model.editingEquipment))
                     ,A2($Html.br,_U.list([]),_U.list([]))]);
   });
   var propertyView = F2(function (address,model) {
      return _U.list([$Html.text("Properties")
                     ,A2(colorPropertyView,address,model)]);
   });
   var modeSelectionView = F2(function (address,model) {
      var widthStyle = _U.list([{ctor: "_Tuple2"
                                ,_0: "width"
                                ,_1: "80px"}]);
      var selection = A2($Html.div,
      _U.list([$Html$Attributes.style(A2($Basics._op["++"],
              $Styles.selection(_U.eq(model.editMode,$Model.Select)),
              widthStyle))
              ,$Util$HtmlUtil.onClick$(A2($Signal.forwardTo,
              address,
              $Basics.always($Model.ChangeMode($Model.Select))))]),
      _U.list([$Icons.selectMode(_U.eq(model.editMode,
      $Model.Select))]));
      var pen = A2($Html.div,
      _U.list([$Html$Attributes.style(A2($Basics._op["++"],
              $Styles.selection(_U.eq(model.editMode,$Model.Pen)),
              widthStyle))
              ,$Util$HtmlUtil.onClick$(A2($Signal.forwardTo,
              address,
              $Basics.always($Model.ChangeMode($Model.Pen))))]),
      _U.list([$Icons.penMode(_U.eq(model.editMode,$Model.Pen))]));
      var stamp = A2($Html.div,
      _U.list([$Html$Attributes.style(A2($Basics._op["++"],
              $Styles.selection(_U.eq(model.editMode,$Model.Stamp)),
              widthStyle))
              ,$Util$HtmlUtil.onClick$(A2($Signal.forwardTo,
              address,
              $Basics.always($Model.ChangeMode($Model.Stamp))))]),
      _U.list([$Icons.stampMode(_U.eq(model.editMode,
      $Model.Stamp))]));
      return A2($Html.div,
      _U.list([$Html$Attributes.style(A2($Basics._op["++"],
      $Styles.flex,
      _U.list([{ctor: "_Tuple2",_0: "margin-top",_1: "10px"}])))]),
      _U.list([selection,pen,stamp]));
   });
   var card = function (children) {
      return A2($Html.div,
      _U.list([$Html$Attributes.style(_U.list([{ctor: "_Tuple2"
                                               ,_0: "margin-bottom"
                                               ,_1: "20px"}
                                              ,{ctor: "_Tuple2",_0: "padding",_1: "20px"}]))]),
      children);
   };
   var inputAttributes = F5(function (address,
   toInputAction,
   toKeydownAction,
   value$,
   defence) {
      return A2($Basics._op["++"],
      _U.list([$Util$HtmlUtil.onInput$(A2($Signal.forwardTo,
              address,
              toInputAction))
              ,$Util$HtmlUtil.onKeyDown$$(A2($Signal.forwardTo,
              address,
              toKeydownAction))
              ,$Html$Attributes.value(value$)]),
      defence ? _U.list([$Util$HtmlUtil.onMouseDown$(A2($Signal.forwardTo,
      address,
      $Basics.always($Model.NoOp)))]) : _U.list([]));
   });
   var floorNameInputView = F2(function (address,model) {
      return A2($Html.input,
      A2($Basics._op["++"],
      _U.list([$Html$Attributes.id("floor-name-input")
              ,$Html$Attributes.type$("text")]),
      A5(inputAttributes,
      address,
      $Model.InputFloorName,
      $Basics.always($Model.NoOp),
      $Util$UndoRedo.data(model.floor).name,
      false)),
      _U.list([]));
   });
   var floorRealSizeInputView = F2(function (address,model) {
      var useReal = true;
      var widthInput = A2($Html.input,
      A2($Basics._op["++"],
      _U.list([$Html$Attributes.id("floor-real-width-input")
              ,$Html$Attributes.type$("text")
              ,$Html$Attributes.disabled($Basics.not(useReal))
              ,$Html$Attributes.style($Styles.realSizeInput)]),
      A5(inputAttributes,
      address,
      $Model.InputFloorRealWidth,
      $Basics.always($Model.NoOp),
      model.inputFloorRealWidth,
      false)),
      _U.list([]));
      var heightInput = A2($Html.input,
      A2($Basics._op["++"],
      _U.list([$Html$Attributes.id("floor-real-height-input")
              ,$Html$Attributes.type$("text")
              ,$Html$Attributes.disabled($Basics.not(useReal))
              ,$Html$Attributes.style($Styles.realSizeInput)]),
      A5(inputAttributes,
      address,
      $Model.InputFloorRealHeight,
      $Basics.always($Model.NoOp),
      model.inputFloorRealHeight,
      false)),
      _U.list([]));
      var floor = $Util$UndoRedo.data(model.floor);
      return A2($Html.div,
      _U.list([]),
      _U.list([widthInput,heightInput]));
   });
   var transitionDisabled = function (model) {
      return $Basics.not(model.scaling);
   };
   var nameInputView = F2(function (address,model) {
      var _p1 = model.editingEquipment;
      if (_p1.ctor === "Just") {
            var _p3 = _p1._0._1;
            var _p2 = A2($EquipmentsOperation.findEquipmentById,
            $Util$UndoRedo.data(model.floor).equipments,
            _p1._0._0);
            if (_p2.ctor === "Just") {
                  var styles = A2($Basics._op["++"],
                  $Styles.deskInput(A2($Scale.imageToScreenForRect,
                  model.scale,
                  _p2._0._1)),
                  $Styles.transition(transitionDisabled(model)));
                  return A2($Html.textarea,
                  A2($Basics._op["++"],
                  _U.list([$Html$Attributes.id("name-input")
                          ,$Html$Attributes.style(styles)]),
                  A5(inputAttributes,
                  address,
                  $Model.InputName(_p2._0._0),
                  $Model.KeydownOnNameInput,
                  _p3,
                  true)),
                  _U.list([$Html.text(_p3)]));
               } else {
                  return $Html.text("");
               }
         } else {
            return $Html.text("");
         }
   });
   var equipmentLabelView = F3(function (scale,
   disableTransition,
   name) {
      var styles = A2($Basics._op["++"],
      $Styles.nameLabel(1.0 / $Basics.toFloat(A2($Scale.screenToImage,
      scale,
      1))),
      $Styles.transition(disableTransition));
      return A2($Html.pre,
      _U.list([$Html$Attributes.style(styles)]),
      _U.list([$Html.text(name)]));
   });
   var equipmentView$ = F9(function (key$,
   rect,
   color,
   name,
   selected,
   alpha,
   eventHandlers,
   scale,
   disableTransition) {
      var screenRect = A2($Scale.imageToScreenForRect,scale,rect);
      var styles = A2($Basics._op["++"],
      A4($Styles.desk,screenRect,color,selected,alpha),
      A2($Basics._op["++"],
      _U.list([{ctor: "_Tuple2",_0: "display",_1: "table"}]),
      $Styles.transition(disableTransition)));
      return A2($Html.div,
      A2($Basics._op["++"],
      eventHandlers,
      _U.list([$Html$Attributes.key(key$)
              ,$Html$Attributes.style(styles)])),
      _U.list([A3(equipmentLabelView,scale,disableTransition,name)]));
   });
   var temporaryStampView = F3(function (scale,selected,_p4) {
      var _p5 = _p4;
      var _p9 = _p5._1._1;
      var _p8 = _p5._1._0;
      var _p7 = _p5._0._3._0;
      var _p6 = _p5._0._3._1;
      return A9(equipmentView$,
      A2($Basics._op["++"],
      "temporary_",
      A2($Basics._op["++"],
      $Basics.toString(_p8),
      A2($Basics._op["++"],
      "_",
      A2($Basics._op["++"],
      $Basics.toString(_p9),
      A2($Basics._op["++"],
      "_",
      A2($Basics._op["++"],
      $Basics.toString(_p7),
      A2($Basics._op["++"],"_",$Basics.toString(_p6)))))))),
      {ctor: "_Tuple4",_0: _p8,_1: _p9,_2: _p7,_3: _p6},
      _p5._0._1,
      _p5._0._2,
      selected,
      false,
      _U.list([]),
      scale,
      true);
   });
   var prototypePreviewView = F3(function (address,
   prototypes,
   stampMode) {
      var selectedIndex = A2($Maybe.withDefault,
      0,
      $List.head(A2($List.filterMap,
      function (_p10) {
         var _p11 = _p10;
         return _p11._0._1 ? $Maybe.Just(_p11._1) : $Maybe.Nothing;
      },
      $Util$ListUtil.zipWithIndex(prototypes))));
      var buttons = A2($List.map,
      function (label) {
         var position = {ctor: "_Tuple2"
                        ,_0: _U.eq(label,"<") ? "left" : "right"
                        ,_1: "3px"};
         return A2($Html.div,
         _U.list([$Html$Attributes.style(A2($List._op["::"],
                 position,
                 $Styles.prototypePreviewScroll))
                 ,$Util$HtmlUtil.onClick$(A2($Signal.forwardTo,
                 address,
                 $Basics.always(_U.eq(label,
                 "<") ? $Model.PrototypesAction($Prototypes.prev) : $Model.PrototypesAction($Prototypes.next))))]),
         _U.list([$Html.text(label)]));
      },
      A2($Basics._op["++"],
      _U.cmp(selectedIndex,0) > 0 ? _U.list(["<"]) : _U.list([]),
      _U.cmp(selectedIndex,
      $List.length(prototypes) - 1) < 0 ? _U.list([">"]) : _U.list([])));
      var height = 238;
      var width = 238;
      var each = F2(function (index,_p12) {
         var _p13 = _p12;
         var _p15 = _p13._0;
         var _p14 = _p15;
         var w = _p14._3._0;
         var h = _p14._3._1;
         var left = (width / 2 | 0) - (w / 2 | 0);
         var top = (height / 2 | 0) - (h / 2 | 0);
         return A3(temporaryStampView,
         $Scale.init,
         false,
         {ctor: "_Tuple2"
         ,_0: _p15
         ,_1: {ctor: "_Tuple2",_0: left + index * width,_1: top}});
      });
      var inner = A2($Html.div,
      _U.list([$Html$Attributes.style($Styles.prototypePreviewViewInner(selectedIndex))]),
      A2($List.indexedMap,each,prototypes));
      return A2($Html.div,
      _U.list([$Html$Attributes.style($Styles.prototypePreviewView(stampMode))]),
      A2($List._op["::"],inner,buttons));
   });
   var penView = F2(function (address,model) {
      var prototypes = $Prototypes.prototypes(model.prototypes);
      return _U.list([$Util$HtmlUtil.fileLoadButton(A2($Signal.forwardTo,
                     address,
                     $Model.LoadFile))
                     ,A2(floorNameInputView,address,model)
                     ,A2(floorRealSizeInputView,address,model)
                     ,A2(modeSelectionView,address,model)
                     ,A3(prototypePreviewView,
                     address,
                     prototypes,
                     _U.eq(model.editMode,$Model.Stamp))]);
   });
   var subView = F2(function (address,model) {
      return A2($Html.div,
      _U.list([$Html$Attributes.style($Styles.subMenu)]),
      _U.list([card(A2(penView,address,model))
              ,card(A2(propertyView,address,model))
              ,card(A2(debugView,address,model))]));
   });
   var temporaryStampsView = function (model) {
      return A2($List.map,
      A2(temporaryStampView,model.scale,false),
      $Model.stampCandidates(model));
   };
   var equipmentView = F8(function (address,
   model,
   moving,
   selected,
   alpha,
   equipment,
   contextMenuDisabled,
   disableTransition) {
      var _p16 = equipment;
      var _p22 = _p16._1._1;
      var _p21 = _p16._1._0;
      var _p20 = _p16._0;
      var contextMenu = contextMenuDisabled ? _U.list([]) : _U.list([$Util$HtmlUtil.onContextMenu$(A2($Signal.forwardTo,
      address,
      $Model.ShowContextMenuOnEquipment(_p20)))]);
      var eventHandlers = A2($Basics._op["++"],
      contextMenu,
      _U.list([$Util$HtmlUtil.onMouseDown$(A2($Signal.forwardTo,
              address,
              $Model.MouseDownOnEquipment(_p20)))
              ,$Util$HtmlUtil.onDblClick$(A2($Signal.forwardTo,
              address,
              $Model.StartEditEquipment(_p20)))]));
      var _p17 = function () {
         var _p18 = moving;
         if (_p18.ctor === "Just" && _p18._0.ctor === "_Tuple2" && _p18._0._0.ctor === "_Tuple2" && _p18._0._1.ctor === "_Tuple2")
         {
               var _p19 = A2($Scale.screenToImageForPosition,
               model.scale,
               {ctor: "_Tuple2"
               ,_0: _p18._0._1._0 - _p18._0._0._0
               ,_1: _p18._0._1._1 - _p18._0._0._1});
               var dx = _p19._0;
               var dy = _p19._1;
               return A2($EquipmentsOperation.fitToGrid,
               model.gridSize,
               {ctor: "_Tuple2",_0: _p21 + dx,_1: _p22 + dy});
            } else {
               return {ctor: "_Tuple2",_0: _p21,_1: _p22};
            }
      }();
      var x = _p17._0;
      var y = _p17._1;
      var movingBool = !_U.eq(moving,$Maybe.Nothing);
      return A9(equipmentView$,
      A2($Basics._op["++"],_p20,$Basics.toString(movingBool)),
      {ctor: "_Tuple4",_0: x,_1: y,_2: _p16._1._2,_3: _p16._1._3},
      _p16._2,
      _p16._3,
      selected,
      alpha,
      eventHandlers,
      model.scale,
      disableTransition);
   });
   var canvasView = F2(function (address,model) {
      var _p23 = model.offset;
      var offsetX = _p23._0;
      var offsetY = _p23._1;
      var temporaryStamps$ = temporaryStampsView(model);
      var isDragged = function (equipment) {
         return function () {
            var _p24 = model.draggingContext;
            if (_p24.ctor === "MoveEquipment") {
                  return true;
               } else {
                  return false;
               }
         }() && A2($List.member,
         $EquipmentsOperation.idOf(equipment),
         model.selectedEquipments);
      };
      var disableTransition = transitionDisabled(model);
      var selectorRect = function () {
         var _p25 = {ctor: "_Tuple2"
                    ,_0: model.editMode
                    ,_1: model.selectorRect};
         if (_p25.ctor === "_Tuple2" && _p25._0.ctor === "Select" && _p25._1.ctor === "Just")
         {
               return A2($Html.div,
               _U.list([$Html$Attributes.style(A2($Basics._op["++"],
               $Styles.selectorRect(A2($Scale.imageToScreenForRect,
               model.scale,
               _p25._1._0)),
               $Styles.transition(disableTransition)))]),
               _U.list([]));
            } else {
               return $Html.text("");
            }
      }();
      var floor = $Util$UndoRedo.data(model.floor);
      var nonDraggingEquipments = A2($List.map,
      function (equipment) {
         return A8(equipmentView,
         address,
         model,
         $Maybe.Nothing,
         A2($Model.isSelected,model,equipment),
         isDragged(equipment),
         equipment,
         model.keys.ctrl,
         disableTransition);
      },
      floor.equipments);
      var draggingEquipments = function () {
         if (function () {
            var _p26 = model.draggingContext;
            if (_p26.ctor === "MoveEquipment") {
                  return true;
               } else {
                  return false;
               }
         }()) {
               var moving = function () {
                  var _p27 = {ctor: "_Tuple2"
                             ,_0: model.draggingContext
                             ,_1: model.pos};
                  if (_p27.ctor === "_Tuple2" && _p27._0.ctor === "MoveEquipment" && _p27._0._1.ctor === "_Tuple2" && _p27._1.ctor === "Just" && _p27._1._0.ctor === "_Tuple2")
                  {
                        return $Maybe.Just({ctor: "_Tuple2"
                                           ,_0: {ctor: "_Tuple2",_0: _p27._0._1._0,_1: _p27._0._1._1}
                                           ,_1: {ctor: "_Tuple2",_0: _p27._1._0._0,_1: _p27._1._0._1}});
                     } else {
                        return $Maybe.Nothing;
                     }
               }();
               var equipments = A2($List.filter,isDragged,floor.equipments);
               return A2($List.map,
               function (equipment) {
                  return A8(equipmentView,
                  address,
                  model,
                  moving,
                  A2($Model.isSelected,model,equipment),
                  false,
                  equipment,
                  model.keys.ctrl,
                  disableTransition);
               },
               equipments);
            } else return _U.list([]);
      }();
      var equipments = A2($Basics._op["++"],
      draggingEquipments,
      nonDraggingEquipments);
      var rect = A2($Scale.imageToScreenForRect,
      model.scale,
      {ctor: "_Tuple4"
      ,_0: offsetX
      ,_1: offsetY
      ,_2: $Floor.width(floor)
      ,_3: $Floor.height(floor)});
      var image = A2($Html.img,
      _U.list([$Html$Attributes.style(_U.list([{ctor: "_Tuple2"
                                               ,_0: "width"
                                               ,_1: "100%"}
                                              ,{ctor: "_Tuple2",_0: "height",_1: "100%"}]))
              ,$Html$Attributes.src(A2($Maybe.withDefault,
              "",
              $Floor.src(floor)))]),
      _U.list([]));
      return A2($Html.div,
      _U.list([$Html$Attributes.style(A2($Basics._op["++"],
      $Styles.canvasView(rect),
      $Styles.transition(disableTransition)))]),
      A2($Basics._op["++"],
      A2($List._op["::"],
      image,
      A2($List._op["::"],
      A2(nameInputView,address,model),
      A2($List._op["::"],selectorRect,equipments))),
      temporaryStamps$));
   });
   var canvasContainerView = F2(function (address,model) {
      return A2($Html.div,
      _U.list([$Html$Attributes.style(A2($Basics._op["++"],
              $Styles.canvasContainer,
              _U.eq(model.editMode,$Model.Stamp) ? _U.list([]) : _U.list([])))
              ,$Util$HtmlUtil.onMouseMove$(A2($Signal.forwardTo,
              address,
              $Model.MoveOnCanvas))
              ,$Util$HtmlUtil.onMouseDown$(A2($Signal.forwardTo,
              address,
              $Model.MouseDownOnCanvas))
              ,$Util$HtmlUtil.onMouseUp$(A2($Signal.forwardTo,
              address,
              $Model.MouseUpOnCanvas))
              ,$Util$HtmlUtil.onMouseEnter$(A2($Signal.forwardTo,
              address,
              $Basics.always($Model.EnterCanvas)))
              ,$Util$HtmlUtil.onMouseLeave$(A2($Signal.forwardTo,
              address,
              $Basics.always($Model.LeaveCanvas)))
              ,A2($Util$HtmlUtil.onMouseWheel,address,$Model.MouseWheel)]),
      _U.list([A2(canvasView,address,model)]));
   });
   var mainView = F2(function (address,model) {
      var _p28 = model.windowDimensions;
      var windowWidth = _p28._0;
      var windowHeight = _p28._1;
      var height = windowHeight - $Styles.headerHeight;
      return A2($Html.main$,
      _U.list([$Html$Attributes.style(A2($Basics._op["++"],
      $Styles.flex,
      _U.list([{ctor: "_Tuple2"
               ,_0: "height"
               ,_1: A2($Basics._op["++"],$Basics.toString(height),"px")}])))]),
      _U.list([A2(canvasContainerView,address,model)
              ,A2(subView,address,model)]));
   });
   var contextMenuItemView = F3(function (address,action,text$) {
      return A2($Html.div,
      _U.list([$Html$Attributes.$class("hovarable")
              ,$Html$Attributes.style($Styles.contextMenuItem)
              ,$Util$HtmlUtil.onMouseDown$(A2($Signal.forwardTo,
              address,
              action))]),
      _U.list([$Html.text(text$)]));
   });
   var contextMenuView = F2(function (address,model) {
      var _p29 = model.contextMenu;
      if (_p29.ctor === "NoContextMenu") {
            return $Html.text("");
         } else {
            var _p30 = _p29._1;
            return A2($Html.div,
            _U.list([$Html$Attributes.style(A3($Styles.contextMenu,
            {ctor: "_Tuple2",_0: _p29._0._0,_1: _p29._0._1},
            {ctor: "_Tuple2"
            ,_0: $Basics.fst(model.windowDimensions)
            ,_1: $Basics.snd(model.windowDimensions)},
            2))]),
            _U.list([A3(contextMenuItemView,
                    address,
                    $Model.SelectIsland(_p30),
                    "Select Island")
                    ,A3(contextMenuItemView,
                    address,
                    $Basics.always($Model.RegisterPrototype(_p30)),
                    "Register as stamp")
                    ,A3(contextMenuItemView,
                    address,
                    $Basics.always($Model.Rotate(_p30)),
                    "Rotate")]));
         }
   });
   var headerView = F2(function (address,model) {
      return A2($Html.header,
      _U.list([$Html$Attributes.style($Styles.header)
              ,A2($Util$HtmlUtil.mouseDownDefence,address,$Model.NoOp)]),
      _U.list([A2($Html.h1,
      _U.list([$Html$Attributes.style($Styles.h1)]),
      _U.list([$Html.text("Office Maker")]))]));
   });
   var view = F2(function (address,model) {
      return A2($Html.div,
      _U.list([]),
      _U.list([A2(headerView,address,model)
              ,A2(mainView,address,model)
              ,A2(contextMenuView,address,model)]));
   });
   return _elm.View.values = {_op: _op,view: view};
};
Elm.Main = Elm.Main || {};
Elm.Main.make = function (_elm) {
   "use strict";
   _elm.Main = _elm.Main || {};
   if (_elm.Main.values) return _elm.Main.values;
   var _U = Elm.Native.Utils.make(_elm),
   $Basics = Elm.Basics.make(_elm),
   $Debug = Elm.Debug.make(_elm),
   $Effects = Elm.Effects.make(_elm),
   $Html = Elm.Html.make(_elm),
   $List = Elm.List.make(_elm),
   $Maybe = Elm.Maybe.make(_elm),
   $Model = Elm.Model.make(_elm),
   $Result = Elm.Result.make(_elm),
   $Signal = Elm.Signal.make(_elm),
   $StartApp = Elm.StartApp.make(_elm),
   $Task = Elm.Task.make(_elm),
   $View = Elm.View.make(_elm);
   var _op = {};
   var randomSeed = Elm.Native.Port.make(_elm).inbound("randomSeed",
   "( Int, Int )",
   function (v) {
      return typeof v === "object" && v instanceof Array ? {ctor: "_Tuple2"
                                                           ,_0: typeof v[0] === "number" && isFinite(v[0]) && Math.floor(v[0]) === v[0] ? v[0] : _U.badPort("an integer",
                                                           v[0])
                                                           ,_1: typeof v[1] === "number" && isFinite(v[1]) && Math.floor(v[1]) === v[1] ? v[1] : _U.badPort("an integer",
                                                           v[1])} : _U.badPort("an array",v);
   });
   var initialHash = Elm.Native.Port.make(_elm).inbound("initialHash",
   "String",
   function (v) {
      return typeof v === "string" || typeof v === "object" && v instanceof String ? v : _U.badPort("a string",
      v);
   });
   var initialSize = Elm.Native.Port.make(_elm).inbound("initialSize",
   "( Int, Int )",
   function (v) {
      return typeof v === "object" && v instanceof Array ? {ctor: "_Tuple2"
                                                           ,_0: typeof v[0] === "number" && isFinite(v[0]) && Math.floor(v[0]) === v[0] ? v[0] : _U.badPort("an integer",
                                                           v[0])
                                                           ,_1: typeof v[1] === "number" && isFinite(v[1]) && Math.floor(v[1]) === v[1] ? v[1] : _U.badPort("an integer",
                                                           v[1])} : _U.badPort("an array",v);
   });
   var app = $StartApp.start({init: A3($Model.init,
                             randomSeed,
                             initialSize,
                             initialHash)
                             ,view: $View.view
                             ,update: $Model.update
                             ,inputs: $Model.inputs});
   var main = app.html;
   var tasks = Elm.Native.Task.make(_elm).performSignal("tasks",
   app.tasks);
   return _elm.Main.values = {_op: _op,app: app,main: main};
};
