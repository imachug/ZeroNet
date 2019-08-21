class Fixbutton
	constructor: (dom) ->
		fixbutton = document.createElement("div")
		fixbutton.className = "fixbutton"
		fixbutton.innerHTML = """
			<div class='fixbutton-text'>
				<img width=22 src='/uimedia/img/logo-white.png'/>
			</div>
			<div class='fixbutton-burger'>&#x2261;</div>
			<span class='fixbutton-bg'></span>
		"""
		dom.appendChild fixbutton

		fixbutton_bg = fixbutton.querySelector(".fixbutton-bg")
		fixbutton_burger = fixbutton.querySelector(".fixbutton-burger")
		fixbutton_text = fixbutton.querySelector(".fixbutton-text")

		@dragging = false
		fixbutton_bg.addEventListener "mouseover", ->
			fixbutton_bg.style.transition = "transform 0.4s cubic-bezier(.17,3.11,.51,.36)"
			fixbutton_bg.style.transform = "scale(0.7)"
			fixbutton_burger.style.transition = "opacity 0.3s ease-out, left 0.3s ease-out"
			fixbutton_burger.style.opacity = "1.5"
			fixbutton_burger.style.left = "0"
			fixbutton_text.style.transition = "opacity 0.3s ease-out, left 0.3s ease-out"
			fixbutton_text.style.opacity = "0"
			fixbutton_text.style.left = "20px"

		fixbutton_bg.addEventListener "mouseout", ->
			fixbutton_bg.style.transition = "transform 0.15s cubic-bezier(.17,3.11,.51,.36)"
			fixbutton_bg.style.transform = "scale(0.6)"
			fixbutton_burger.style.transition = """
				opacity 0.15s cubic-bezier(.17,3.11,.51,.36),
				left 0.15s cubic-bezier(.17,3.11,.51,.36)
			"""
			fixbutton_burger.style.opacity = "0"
			fixbutton_burger.style.left = "-20px"
			fixbutton_text.style.transition = "opacity 0.3s ease-out, left 0.3s ease-out"
			fixbutton_text.style.opacity = "0.9"
			fixbutton_text.style.left = "0"


window.Fixbutton = Fixbutton
