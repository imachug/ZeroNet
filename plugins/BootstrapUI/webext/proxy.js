browser.proxy.onRequest.addListener(req => {
	return {
		type: "http",
		host: "127.0.0.1",
		port: 43110
	};
}, {
	urls: ["*://*.zeronet/*"]
});


browser.webRequest.onBeforeRequest.addListener(req => {
	return {
		redirectUrl: "http://home.zeronet/ZeroNet-Internal/Index"
	};
}, {
	urls: ["*://*/zeronet-bootstrap"]
}, ["blocking"]);


// Redirect all currently opened zeronet-bootstrap pages
(async () => {
	for(const tab of await browser.tabs.query({})) {
		if(tab.url.endsWith("/zeronet-bootstrap")) {
			browser.tabs.update(tab.id, {
				url: "http://home.zeronet/ZeroNet-Internal/Index",
				loadReplace: true
			});
		}
	}
})();