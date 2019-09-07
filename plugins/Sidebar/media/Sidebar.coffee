class Sidebar extends Class
	constructor: (@prefix) ->
		@opened = false
		@width = 410
		@console = new Console(@)
		@fixbutton = $(@prefix.dom.querySelector(".fixbutton"))
		@fixbutton_addx = 0
		@fixbutton_addy = 0
		@fixbutton_initx = 0
		@fixbutton_inity = 15
		@fixbutton_targetx = 0
		@move_lock = null
		@page_width = $(window).width()
		@page_height = $(window).height()
		@initFixbutton()
		@initTag()
		@dragStarted = 0


	initFixbutton: ->
		# Detect dragging
		@fixbutton.on "mousedown touchstart", (e) =>
			if e.button > 0  # Right or middle click
				return
			e.preventDefault()

			# Disable previous listeners
			@fixbutton.off "click touchend touchcancel"

			# Make sure its not a click
			@dragStarted = (+ new Date)

			$(window).one "mousemove touchmove", (e) =>
				mousex = e.pageX
				mousey = e.pageY
				mousex ?= e.originalEvent.touches[0].pageX
				mousey ?= e.originalEvent.touches[0].pageY

				@fixbutton_addx = @fixbutton.offset().left - mousex
				@fixbutton_addy = @fixbutton.offset().top - mousey
				@startDrag()

		@fixbutton.parent().on "click touchend touchcancel", (e) =>
			if (+ new Date) - @dragStarted < 100
				window.top.location = @fixbutton.find(".fixbutton-bg").attr("href")
			@stopDrag()
		@resized()
		$(window).on "resize", @resized


	initTag: ->
		@tag = $("""
			<div class="sidebar">
				<iframe src="/ZeroNet-Internal/Sidebar?wrapper_key=#{@prefix.wrapper_key}"></iframe>
			</div>
		""")
		$(@prefix.dom).append @tag


	resized: =>
		@page_width = $(window).width()
		@page_height = $(window).height()
		@fixbutton_initx = @page_width - 75  # Initial x position
		if @opened
			@fixbutton.css {left: @fixbutton_initx - @width}
		else
			@fixbutton.css {left: @fixbutton_initx}

	# Start dragging the fixbutton
	startDrag: ->
		@log "startDrag", @fixbutton_initx, @fixbutton_inity
		@fixbutton_targetx = @fixbutton_initx  # Fallback x position
		@fixbutton_targety = @fixbutton_inity  # Fallback y position

		@fixbutton.addClass "dragging"

		# Don't go to homepage
		@fixbutton.one "click", (e) =>
			@stopDrag()
			@fixbutton.removeClass "dragging"
			moved_x = Math.abs(@fixbutton.offset().left - @fixbutton_initx)
			moved_y = Math.abs(@fixbutton.offset().top - @fixbutton_inity)
			if moved_x > 5 or moved_y > 10
				# If moved more than some pixel the button then don't go to homepage
				e.preventDefault()

		# Animate drag
		$(window).on "mousemove touchmove", @animDrag
		$(window).on "mousemove touchmove", @waitMove

		# Disable pointer events on the contents
		@tag.css "pointer-events", "none"

		# Stop dragging listener
		$(window).one "mouseup touchend touchcancel", (e) =>
			e.preventDefault()
			@stopDrag()


	# Wait for moving the fixbutton
	waitMove: (e) =>
		moved_x = Math.abs(parseInt(@fixbutton[0].style.left) - @fixbutton_targetx)
		moved_y = Math.abs(parseInt(@fixbutton[0].style.top) - @fixbutton_targety)
		if moved_x > 5 and (+ new Date) - @dragStarted + moved_x > 50
			@moved("x")
			@fixbutton.stop().animate {"top": @fixbutton_inity}, 1000
			$(window).off "mousemove touchmove", @waitMove

		else if moved_y > 5 and (+ new Date) - @dragStarted + moved_y > 50
			@moved("y")
			$(window).off "mousemove touchmove", @waitMove

	moved: (direction) ->
		@log "Moved", direction
		@move_lock = direction
		if direction == "y"
			$(document.body).addClass "body-console"
			return
		$(document.body).addClass "body-sidebar"
		@tag.on "mousedown touchend touchcancel", (e) =>
			if e.target != e.currentTarget
				return true
			@log "closing"
			if $(document.body).hasClass("body-sidebar")
				@close()
				return true

		$(window).off "resize"
		$(window).on "resize", =>
			@resized()


	animDrag: (e) =>
		mousex = e.pageX
		mousey = e.pageY
		if not mousex and e.originalEvent.touches
			mousex = e.originalEvent.touches[0].pageX
			mousey = e.originalEvent.touches[0].pageY

		overdrag = @fixbutton_initx - @width - mousex
		if overdrag > 0  # Overdragged
			overdrag_percent = 1 + overdrag/300
			mousex = (mousex + (@fixbutton_initx-@width)*overdrag_percent)/(1+overdrag_percent)
		targetx = @fixbutton_initx - mousex - @fixbutton_addx
		targety = @fixbutton_inity - mousey - @fixbutton_addy

		if @move_lock == "x"
			targety = @fixbutton_inity
		else if @move_lock == "y"
			targetx = @fixbutton_initx

		if not @move_lock or @move_lock == "x"
			@fixbutton[0].style.left = (mousex + @fixbutton_addx) + "px"
			@tag[0].style.transform = "translateX(#{0 - targetx}px)"

		if not @move_lock or @move_lock == "y"
			@fixbutton[0].style.top = (mousey + @fixbutton_addy) + "px"
			if @console.tag
				@console.tag[0].style.transform = "translateY(#{0 - targety}px)"

		# Check if opened
		if (not @opened and targetx > @width/3) or (@opened and targetx > @width*0.9)
			@fixbutton_targetx = @fixbutton_initx - @width  # Make it opened
		else
			@fixbutton_targetx = @fixbutton_initx

		if (not @console.opened and 0 - targety > @page_height/10) or (@console.opened and 0 - targety > @page_height*0.8)
			@fixbutton_targety = @page_height - @fixbutton_inity - 50
		else
			@fixbutton_targety = @fixbutton_inity


	# Stop dragging the fixbutton
	stopDrag: ->
		$(window).off "mousemove touchmove"
		@fixbutton.off "mousemove touchmove"
		if not @fixbutton.hasClass("dragging")
			return
		@fixbutton.removeClass "dragging"

		# Move back to initial position
		if @fixbutton_targetx != @fixbutton.offset().left or @fixbutton_targety != @fixbutton.offset().top
			# Animate fixbutton
			if @move_lock == "y"
				top = @fixbutton_targety
				left = @fixbutton_initx
			if @move_lock == "x"
				top = @fixbutton_inity
				left = @fixbutton_targetx
			@fixbutton.stop().animate {"left": left, "top": top}, 500, "easeOutBack", =>
				$(".fixbutton-bg").trigger "mouseout"  # Switch fixbutton back to normal status

			@stopDragX()
			@console.stopDragY()
		@move_lock = null

		# Enable pointer events on the contents
		@tag.css "pointer-events", ""

	stopDragX: ->
		# Animate sidebar and iframe
		if @fixbutton_targetx == @fixbutton_initx or @move_lock == "y"
			# Closed
			targetx = 0
			@opened = false
		else
			# Opened
			targetx = @width
			@onOpened()
			@opened = true

		# Revent sidebar transitions
		@tag.css "transition", "0.4s ease-out"
		@tag.css("transform", "translateX(-#{targetx}px)").one transitionEnd, =>
			@tag.css "transition", ""

		# Revert body transformations
		@log "stopdrag", "opened:", @opened
		if not @opened
			@onClosed()

	onOpened: ->
		@log "Opened"

		# Close
		@tag.find(".close").off("click touchend").on "click touchend", (e) =>
			@close()
			return false

	close: ->
		@move_lock = "x"
		@startDrag()
		@stopDrag()


	onClosed: ->
		$(window).off "resize"
		$(window).on "resize", @resized
		$(document.body).removeClass "body-sidebar"


Prefix.plugins.push Sidebar

window.transitionEnd = 'transitionend webkitTransitionEnd oTransitionEnd otransitionend'
