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


async function updateIcon(tabId) {
	const tab = await new Promise(resolve => browser.tabs.get(tabId, resolve));
	const isZeroNet = /^(.*?):\/\/[^\/]+\.zeronet/.test(tab.url);
	browser.browserAction.setIcon({
		tabId: tabId,
		path: isZeroNet ? "logo.png" : "logo-inactive.png"
	});
}

browser.tabs.onCreated.addListener(tab => updateIcon(tab.id));
browser.tabs.onUpdated.addListener(updateIcon);