// Chrome/Firefox compatibility layer
async function getStorage(key) {
	if(globalThis.browser) {
		return (await browser.storage.local.get(key))[key];
	} else {
		return (await new Promise(resolve => chrome.storage.local.get(key, resolve)))[key];
	}
}
async function setStorage(key, value) {
	if(globalThis.browser) {
		await browser.storage.local.set({[key]: value});
	} else {
		await new Promise(resolve => chrome.storage.local.set({[key]: value}, resolve));
	}
}


async function getCurrentProxy() {
	return (await getStorage("proxy")) || "127.0.0.1:43110";
}
async function setProxy(proxy) {
	await setStorage("proxy", proxy || "127.0.0.1:43110");
}