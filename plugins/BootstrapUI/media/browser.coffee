window.BROWSERS = {
	firefox: {
		title: "Mozilla Firefox",
		linkText: "Install",
		link: "#",
		onclick: () ->
			InstallTrigger.install {"ZeroNet": "/uimedia/plugins/bootstrapui/zeronet.xpi"}
	},
	edge: {
		title: "Microsoft Edge",
		linkText: "Go to Microsoft Store",
		link: "#"
	},
	chrome: {
		title: "Google Chrome",
		linkText: "Go to Chrome Web Store",
		link: "#"
	},
	tor: {
		title: "Tor Browser",
		linkText: "Go to zeronet.io",
		link: "https://zeronet.io/plugin"
	}
}

window.detectBrowser = () ->
	# Feature-detect browser
	if window.InstallTrigger
		return "firefox"
	else if navigator.userAgent.indexOf("Edge/") > -1
		return "edge"
	else
		return "chrome"