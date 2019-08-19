class Prefix
	constructor: ->
		# Create ZeroNet UI node
		@node = document.createElement("zeronet-shadow-dom-ui")
		document.body.appendChild @node
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
						# while(document.body.firstChild) {
						#     document.body.removeChild(
						#         document.body.firstChild
						#     );
						#     await sleep(5); // optimize CPU usage
						# }
						# (assuming sleep(N) means "sleep for N ms")
						timesRemoved = 0
						setTimeout ( =>
							if @node.parentNode != document.body
								document.body.appendChild @node
							@node.style.cssText = css_text
						), 100
					else
						if @node.parentNode != document.body
							document.body.appendChild @node
						@node.style.cssText = css_text
		)
		observer.observe document.body, {childList: true}
		observer.observe @node, {
			attributes: true,
			attributeOldValue: true,
			attributeFilter: ["style"]
		}


prefix = new Prefix