showBrowsers = (current, other) ->
	renderBrowser = (browser, node) ->
		node.innerHTML = "
			<img src='/uimedia/plugins/bootstrapui/imgs/#{browser}.png'>
			<h3>#{BROWSERS[browser].title}</h3>
			<a href='#{BROWSERS[browser].link}'>#{BROWSERS[browser].linkText}</a>
		"
		node.querySelector("a").onclick = BROWSERS[browser].onclick

	node = document.querySelector "#current-browser"
	renderBrowser current, node

	for browser in other
		node = document.createElement "div"
		node.className = "browser"
		renderBrowser browser, node
		document.querySelector("#other-browsers").appendChild node


window.addEventListener "load", () ->
	browser = detectBrowser()
	if browser == "firefox"
		showBrowsers("firefox", ["chrome", "tor", "edge"])
	else if browser == "edge"
		showBrowsers("edge", ["tor", "chrome", "firefox"])
	else if browser == "chrome"
		showBrowsers("chrome", ["tor", "edge", "firefox"])
	else if browser == "tor"
		showBrowsers("tor", ["chrome", "firefox", "edge"])
