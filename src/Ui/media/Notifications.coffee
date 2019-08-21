class Notifications
	constructor: (dom) ->
		@elem = document.createElement("div")
		@elem.className = "notifications"
		dom.appendChild @elem

	test: ->
		setTimeout (=>
			@add("connection", "error", "Connection lost to <b>UiServer</b> on <b>localhost</b>!")
			@add("message-Anyone", "info", "New  from <b>Anyone</b>.")
		), 1000
		setTimeout (=>
			@add("connection rec", "done", "<b>UiServer</b> connection recovered.", 5000)
		), 3000


	add: (id, type, body, timeout=0) ->
		type = type.replace(/[^a-z]/g, "")

		id = id.replace(/[^A-Za-z0-9-]/g, "")
		# Close notifications with same id
		for elem in @elem.querySelectorAll(".notification-#{id}")
			@close elem

		# Create element
		elem = document.createElement("div")
		elem.className = "notification notification-#{type} notification-#{id}"
		elem.innerHTML = """
			<span class="notification-icon">!</span>
			<span class="body">Test notification</span>
			<a class="close" href="#Close">&times;</a>
			<div style="clear: both"></div>
		"""
		if type == "progress"
			elem.classList.add "notification-done"

		# Update text
		icon = elem.querySelector(".notification-icon")
		if type == "error"
			icon.innerHTML = "!"
		else if type == "done"
			icon.innerHTML = "<div class='icon-success'></div>"
		else if type == "progress"
			icon.innerHTML = "<div class='icon-success'></div>"
		else if type == "ask"
			icon.innerHTML = "?"
		else
			icon.innerHTML = "i"

		if typeof body == "string"
			elem.querySelector(".body").innerHTML = "<div class='message'><span class='multiline'>" + body + "</span></div>"
		else
			elem.querySelector(".body").innerHTML = ""
			elem.querySelector(".body").appendChild body

		@elem.appendChild elem

		setTimeout ( ->
			elem.scrollLeft = 0
		), 30

		# Timeout
		if timeout
			elem.removeChild elem.querySelector(".close") # No need of close button
			setTimeout ( =>
				@close elem
			), timeout

		width = Math.min(elem.offsetWidth, 580)
		if not timeout
			width += 20 # Add space for close button
		if elem.offsetHeight > 55
			elem.classList.add "long"
		elem.querySelector(".body").style.width = (width - 80) + "px"

		# Animate
		elem.style.height = elem.offsetHeight + "px"
		elem.style.width = "50px"
		elem.style.transform = "scale(0.01)"
		setTimeout ( ->
			elem.style.transition = "transform 0.4s cubic-bezier(.17,3.11,.51,.36)"
			elem.style.transform = "scale(1)"
			setTimeout ( ->
				elem.style.transition = "width 0.7s ease-in-out"
				elem.style.width = width + "px"
			), 800
		), 30
		setTimeout ( ->
			elem.style.boxShadow = "0px 0px 5px rgba(0,0,0,0.1)"
		), 1000

		# Close button or Confirm button
		for button in elem.querySelectorAll(".close, .button")
			button.addEventListener "click", =>
				@close elem
				return false

		# Select list
		select = elem.querySelector(".select")
		if select
			select.addEventListener "click", =>
				@close elem

		# Input enter
		input = elem.querySelector("input")
		if input
			input.addEventListener "keyup", (e) =>
				if e.keyCode == 13
					@close elem

		return elem


	close: (elem) ->
		elem.style.transition = """
			width 0.7s ease-in-out,
			opacity 0.7s ease-in-out,
			height 0.3s ease-in-out,
			margin 0.3s ease-in-out,
			padding 0.3s ease-in-out
		"""
		elem.style.width = "0"
		elem.style.opacity = "0"
		elem.style.height = "0"
		elem.style.marginTop = "0"
		elem.style.marginBottom = "0"
		elem.style.paddingTop = "0"
		elem.style.paddingBottom = "0"
		setTimeout (->
			elem.parentNode.removeChild elem
		), 1000


	log: (args...) ->
		console.log "[Notifications]", args...


window.Notifications = Notifications
