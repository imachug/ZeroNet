class Prefix
	constructor: (wrapper_key) ->
		@siteAddress = location.pathname.replace("/", "").split("/")[0]
		@postMessage = window.postMessage.bind(window)
		@open = window.open.bind(window)
		# Create ZeroNet UI node
		@node = document.createElement("zeronet-shadow-dom-ui")
		@node.style.display = "none"
		document.documentElement.appendChild @node
		# Attach shadow dom
		@load_event = new Promise((resolve) => @onLoad = resolve)
		@dom = @node.attachShadow({mode: "closed"})
		document.addEventListener "DOMContentLoaded", =>
			# Load styles
			node = document.createElement("link")
			node.rel = "stylesheet"
			node.type = "text/css"
			node.href = "/uimedia/all.css"
			node.onload = @watch
			@dom.appendChild(node)
		@notifications = new Notifications(@dom)
		@fixbutton = new Fixbutton(@dom)
		for Plugin in Prefix.plugins
			new Plugin(@)
		# Setup ZeroFrame command receiver
		@ws = new ZeroWebsocket(wrapper_key)
		@ws.route = @postMessage
		# Replace dangerous/overridden methods
		window.parent = {
			postMessage: @handleMessage
		}
		@initHistory()


	initHistory: ->
		oldPushState = history.pushState.bind(history)
		oldReplaceState = history.replaceState.bind(history)

		history.pushState = (state, title, url) =>
			if typeof url == "string" and url.startsWith("/")
				url = "/" + @siteAddress + url
			oldPushState(state, title, url)

		history.replaceState = (state, title, url) =>
			if typeof url == "string" and url.startsWith("/")
				url = "/" + @siteAddress + url
			oldReplaceState(state, title, url)


	watch: =>
		@onLoad()
		# Setup CSS
		@node.style.cssText = """
			position: fixed;
			left: 0;
			top: 0;
			width: 0;
			height: 0;
			overflow: visible;
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
		@load_event.then =>
			if message.cmd == "innerReady"
				# Doesn't make sense without an iframe, here just for completeness
				@postMessage {cmd: "wrapperOpenedWebsocket"}, "*"
			else if message.cmd == "innerLoaded" or message.cmd == "wrapperInnerLoaded"
				# The command name makes little sense without an iframe, but it's
				# still sometimes useful nevertheless
				# TODO: check whether this navigation way actually works
				location.hash = location.hash
			else if message.cmd == "wrapperNotification"
				@notifications.add(
					"notification-#{message.id}",
					message.params[0],
					"<span class='message'>" + @toHtmlSafe(message.params[1]) + "</span>",
					message.params[2]
				)
			else if message.cmd == "wrapperConfirm"
				captions = message.params[1]
				captions ?= "ok"
				@displayConfirm @toHtmlSafe(message.params[0]), captions, (res) =>
					@postMessage {cmd: "response", to: message.id, result: res}
					return false
			else if message.cmd == "wrapperPrompt"
				prompt = @toHtmlSafe(message.params[0])
				type = message.params[1]
				type ?= "text"
				caption = message.params[2]
				caption ?= "OK"
				placeholder = message.params[3]
				placeholder ?= ""

				@displayPrompt prompt, type, caption, placeholder, (res) =>
					@postMessage {"cmd": "response", "to": message.id, "result": res}
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
			else if message.cmd == "wrapperPushState"
				# For compatibility
				url = @toRelativeQuery(message.params[2])
				history.pushState message.params[0], message.params[1], url
			else if message.cmd == "wrapperReplaceState"
				# For compatibility
				url = @toRelativeQuery(message.params[2])
				history.replaceState message.params[0], message.params[1], url
			else if message.cmd == "wrapperGetState"
				# For compatibility
				@postMessage {cmd: "response", to: message.id, result: history.state}
			else if message.cmd == "wrapperOpenWindow"
				# For compatibility
				if typeof message.params == "string"
					@open(message.params)
				else
					@open(message.params[0], message.params[1], message.params[2])
			else if message.cmd == "wrapperRequestFullscreen"
				document.documentElement.requestFullscreen()
			else
				@ws.send message


	toRelativeQuery: (query) ->
		if not query.startsWith("#") and not query.startsWith("?")
			return "?" + query
		else
			return query


	toHtmlSafe: (values) ->
		if values instanceof Array
			for value, i in values
				values[i] = @toHtmlSafe(value)
		else
			# Escape dangerous characters
			value = String(value)
				.replace(/&/g, "&amp;")
				.replace(/</g, "&lt;")
				.replace(/>/g, "&gt;")
				.replace(/"/g, "&quot;")
				.replace(/"/g, "&apos;")
			# Unescape b, i, u, br tags
			value = value.replace(/&lt;(\/?(?:br|b|u|i|small))&gt;/g, "<$1>")
		return values


	displayConfirm: (body_text, captions, cb) =>
		if captions not instanceof Array
			captions = [captions]  # Convert to list if necessary
		body = document.createElement("span")
		body.className = "message-outer"
		body.innerHTML = "<span class='message'>" + body_text + "</span><span class='buttons'></span>"
		buttons = body.querySelector(".buttons")
		for caption, i in captions
			# Add confirm button
			button = document.createElement("a")
			button.href = "#" + caption
			button.className = "button button-confirm button-#{caption} button-#{i+1}"
			button.dataset.value = i + 1
			button.textContent = caption
			((button) =>
				button.addEventListener "click", (e) =>
					cb parseInt(e.currentTarget.dataset.value)
					return false
			)(button)
			buttons.appendChild button
		@notifications.add "notification-#{caption}", "ask", body

		buttons.firstChild.focus()


	displayPrompt: (message, type, caption, placeholder, cb) ->
		body = document.createElement("span")
		body.className = "message"
		body.innerHTML = message

		input = document.createElement("input")
		input.type = type
		input.className = "input button-#{type}"
		input.placeholder = placeholder
		input.addEventListener "keyup", (e) => # Send on enter
			if e.keyCode == 13
				cb input.value
		body.appendChild input

		button = document.createElement("a")
		button.href = "#" + caption
		button.className = "button button-#{caption}"
		button.textContent = caption
		button.addEventListener "click", (e) => # Response on button click
			cb input.value
			return false
		body.appendChild button

		@notifications.add "notification-#{message.id}", "ask", body

		input.focus()


Prefix.plugins = []

window.Prefix = Prefix
