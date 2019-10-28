const gatewayNode = document.querySelector("#gateway");


document.querySelector("#save").addEventListener("click", async () => {
	await setProxy(gatewayNode.value);
	gatewayNode.value = await getCurrentProxy(); // replace placeholder with actual content
});

document.querySelector("#cancel").addEventListener("click", async () => {
	gatewayNode.value = await getCurrentProxy();
});


(async () => {
	gatewayNode.value = await getCurrentProxy();
})();

(globalThis.browser || globalThis.chrome).storage.onChanged.addListener(async () => {
	gatewayNode.value = await getCurrentProxy();
});