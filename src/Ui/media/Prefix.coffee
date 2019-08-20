class Prefix
	constructor: ->
		# Create ZeroNet UI node
		@node = document.createElement("zeronet-shadow-dom-ui")
		document.documentElement.appendChild @node
		# Attach shadow dom
		@dom = @node.attachShadow({mode: "closed"})
		document.addEventListener "DOMContentLoaded", =>
			# Load styles
			node = document.createElement("link")
			node.rel = "stylesheet"
			node.type = "text/css"
			node.href = "/media/all.css"
			node.onload = @watch
			@dom.appendChild(node)
		# Setup ZeroFrame command receiver
		@gate = new WebsocketGate(@dom)
		window.parent = {
			postMessage: @handleMessage
		}


	watch: =>
		# Setup CSS
		@node.style.cssText = """
			position: fixed;
			left: 0;
			top: 0;
			right: 0;
			bottom: 0;
			width: 100%;
			height: 100%;
			display: block;
			visibility: visible;
			opacity: 1;
			pointer-events: all;
			z-index: 1000000; /* That should be enough */
		""".replace(/;/g, " !important;");  # Enforce these styles

		# Create an observer to make sure the node won't get removed (or made
		# invisible in any way)
		css_text = @node.style.cssText
		remove_iterator_start = 0
		times_removed = 0

		observer = new MutationObserver((mutations) =>
			for mutation in mutations
				css_changed = (
					mutation.attributeName == "style" and
					@node.style.cssText != css_text
				)
				if @node in mutation.removedNodes or css_changed
					# Bring the node back
					if Date.now() - removeIteratorStart > 1000
						removeIteratorStart = Date.now()
						timesRemoved = 0
					timesRemoved++
					if timesRemoved > 100
						# >100 remove/restore iterators per second. Sounds like
						# if there was an "edit war" like on Wikipedia. We don't
						# have moderators here, but we can make a cooldown.
						# Note: This is actually not to prevent malicious sites
						# from tricking the user. This is for the case when the
						# following code is used:
						# while(document.documentElement.firstChild) {
						#     document.documentElement.removeChild(
						#         document.documentElement.firstChild
						#     );
						#     await sleep(5); // optimize CPU usage
						# }
						# (assuming sleep(N) means "sleep for N ms")
						timesRemoved = 0
						setTimeout ( =>
							if @node.parentNode != document.documentElement
								document.documentElement.appendChild @node
							@node.style.cssText = css_text
						), 100
					else
						if @node.parentNode != document.documentElement
							document.documentElement.appendChild @node
						@node.style.cssText = css_text
		)
		observer.observe document.documentElement, {childList: true}
		observer.observe @node, {
			attributes: true,
			attributeOldValue: true,
			attributeFilter: ["style"]
		}


	handleMessage: (message) =>
		if message.cmd == "innerReady"
			# Doesn't make sense without an iframe, here just for completeness
			window.postMessage {cmd: "wrapperOpenedWebsocket"}, "*"
		else if message.cmd == "innerLoaded" or message.cmd == "wrapperInnerLoaded"
			# The command name makes little sense without an iframe, but it's
			# still sometimes useful nevertheless
			# TODO: check whether this navigation way actually works
			location.hash = location.hash
		else if message.cmd == "wrapperSetViewport"
			# For compatibility
			viewport = document.querySelector("meta[name=viewport]")
			if not viewport
				viewport = document.createElement("meta")
				viewport.name = "viewport"
				document.head.appendChild viewport
			viewport.content = message.params
		else if message.cmd == "wrapperSetTitle"
			# For compatibility
			document.title = message.params
		else if message.cmd == "wrapperReload"
			# For compatibility
			url = message.params[0]
			if url
				if location.href.toString().indexOf("?") > 0
					location.href += "&" + url
				else
					location.href += "?" + url
			else
				location.reload()
		else
			console.log message
			@gate.send message


window.Prefix = Prefix
