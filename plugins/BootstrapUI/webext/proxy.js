// Set proxy
if(globalThis.browser) {
	// Firefox-compatible
	browser.proxy.onRequest.addListener(req => {
		return {
			type: "http",
			host: "127.0.0.1",
			port: 43110
		};
	}, {
		urls: ["*://*.zeronet/*"]
	});
} else {
	// Chrome-like
	chrome.proxy.settings.set({value: {
		mode: "pac_script",
		pacScript: {
			data: `
				function FindProxyForURL(url, host) {
					if(host.endsWith(".zeronet")) {
						return "PROXY 127.0.0.1:43110";
					}
					return "DIRECT";
				}
			`
		}
	}});
}



const browserChrome = globalThis.browser || globalThis.chrome;

browserChrome.webRequest.onBeforeRequest.addListener(req => {
	return {
		redirectUrl: "http://home.zeronet/ZeroNet-Internal/Index"
	};
}, {
	urls: ["*://*/zeronet-bootstrap"]
}, ["blocking"]);

// Redirect all currently opened zeronet-bootstrap pages
(async () => {
	let tabs;
	if(globalThis.browser) {
		tabs = await browser.tabs.query({});
	} else {
		tabs = await new Promise(resolve => chrome.tabs.query({}, resolve));
	}
	for(const tab of tabs) {
		if(tab.url.endsWith("/zeronet-bootstrap")) {
			if(globalThis.browser) {
				browser.tabs.update(tab.id, {
					url: "http://home.zeronet/ZeroNet-Internal/Index",
					loadReplace: true
				});
			} else {
				chrome.tabs.update(tab.id, {
					url: "http://home.zeronet/ZeroNet-Internal/Index"
				});
			}
		}
	}
})();


async function updateIcon(tabId) {
	const tab = await new Promise(resolve => browserChrome.tabs.get(tabId, resolve));
	const isZeroNet = /^(.*?):\/\/[^\/]+\.zeronet/.test(tab.url);
	browserChrome.browserAction.setIcon({
		tabId: tabId,
		path: isZeroNet ? {
			32: "logo32.png",
			48: "logo48.png",
			96: "logo96.png"
		} : {
			32: "logo-inactive32.png",
			48: "logo-inactive48.png",
			96: "logo-inactive96.png"
		}
	});
}

browserChrome.tabs.onCreated.addListener(tab => updateIcon(tab.id));
browserChrome.tabs.onUpdated.addListener(updateIcon);