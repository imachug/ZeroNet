let currentProxy = null;


function setupProxy(hostname) {
	let [host, port] = hostname.split(":");
	if(port) {
		port = parseInt(port);
	} else {
		port = 80;
	}

	if(globalThis.browser) {
		// Firefox-compatible
		browser.proxy.onRequest.addListener(req => {
			return {
				type: "http",
				host,
				port
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
							return "PROXY ${host}:${port}";
						}
						return "DIRECT";
					}
				`
			}
		}});
	}
}


async function handleBootstrapRequest(tabId, url) {
	const hostname = url.match(/(?:.*?):\/\/(.*?)(\/|$)/)[1];
	if(!hostname || hostname === currentProxy) {
		return;
	}

	if(pendingGatewayUpdate === hostname) {
		// Being asked already
		return;
	}
	pendingGatewayUpdate = hostname;

	// Ask the user whether they want to change gateway
	const code = `
		confirm(
			"This site wants to change ZeroNet gateway to " +
			${JSON.stringify(hostname)} + ". Allow?"
		)
	`;
	let result;
	if(globalThis.browser) {
		result = (await browser.tabs.executeScript(tabId, {code}))[0];
	} else {
		result = (await new Promise(resolve => chrome.tabs.executeScript(tabId, {code}, resolve)))[0];
	}
	if(result) {
		// Change gateway and redirect this tab
		await setProxy(hostname);
		redirectTabs(true);
	}
	setTimeout(() => {
		pendingGatewayUpdate = null;
	}, 100);
	return !!result;
}


async function redirectTabs(force) {
	// Redirect all currently opened bootstrap pages
	let tabs;
	if(globalThis.browser) {
		tabs = await browser.tabs.query({});
	} else {
		tabs = await new Promise(resolve => chrome.tabs.query({}, resolve));
	}
	for(const tab of tabs) {
		if(tab.url.endsWith("/ZeroNet-Internal/Bootstrap")) {
			if(!force) {
				// Makes sense at the moment of installation
				if(await handleBootstrapRequest(tab.id, tab.url)) {
					// Doesn't make sense to redirect anymore
					return;
				}
			}
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
}


const browserChrome = globalThis.browser || globalThis.chrome;


// Set redirects
browserChrome.webRequest.onBeforeRequest.addListener(req => {
	if(req.url.endsWith("/ZeroNet-Internal/Bootstrap")) {
		// Get hostname
		const hostname = req.url.match(/(?:.*?):\/\/(.*?)(\/|$)/)[1];
		if(!hostname || hostname === currentProxy) {
			return {
				redirectUrl: "http://home.zeronet/ZeroNet-Internal/Index"
			};
		}
	}
}, {
	urls: ["*://*/ZeroNet-Internal/Bootstrap"]
}, ["blocking"]);


let pendingGatewayUpdate = null;
browserChrome.tabs.onUpdated.addListener(async tabId => {
	const tab = await new Promise(resolve => browserChrome.tabs.get(tabId, resolve));
	if(!tab.url.endsWith("/ZeroNet-Internal/Bootstrap")) {
		return;
	}
	await handleBootstrapRequest(tabId, tab.url);
});


browserChrome.storage.onChanged.addListener(async () => {
	// Update browser proxy settings
	currentProxy = await getCurrentProxy();
	setupProxy(currentProxy);
});


(async () => {
	// Set proxy on startup
	currentProxy = await getCurrentProxy();
	setupProxy(currentProxy);

	redirectTabs(false);
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