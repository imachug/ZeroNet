class WebsocketGate
	constructor: (dom) ->
		@dom = dom
		@iframe = null
		@next_message_id = 1
		@waiting_cb = {}
		window.onmessage = @onMessage
		@connect()


	connect: ->
		if @iframe
			@dom.removeChild @iframe
		@iframe = document.createElement("iframe")
		@iframe.src = "/ZeroNet-Internal/Gate"
		@iframe.onerror = @onErrorWebsocket
		@dom.appendChild @iframe
		@connected = false
		@message_queue = []


	onMessage: (e) =>
		if e.source != @iframe.contentWindow
			return
		message = e.data
		cmd = message.cmd
		if cmd == "wrapperGateOpenWebsocket"
			@onOpenWebsocket()
		else if cmd == "wrapperGateCloseWebsocket"
			@onCloseWebsocket()
		else if cmd == "response"
			if @waiting_cb[message.to]?
				@waiting_cb[message.to](message.result)
			else
				@log "Websocket callback not found:", message
		else if cmd == "ping"
			@response message.id, "pong"
		else
			@route cmd, message

	route: (cmd, message) =>
		@log "Unknown command", message


	response: (to, result) =>
		@send {"cmd": "response", "to": to, "result": result}


	cmd: (cmd, params={}, cb=null) ->
		@send {"cmd": cmd, "params": params}, cb


	send: (message, cb=null) ->
		if not message.id?
			message.id = @next_message_id
			@next_message_id += 1
		if @connected
			@iframe.contentWindow.postMessage message, "*"
		else
			@log "Not connected, adding message to queue"
			@message_queue.push(message)
		if cb
			@waiting_cb[message.id] = cb


	log: (args...) =>
		console.log "[ZeroWebsocket]", args...


	onOpenWebsocket: (e) =>
		@log "Open"
		@connected = true

		# Process messages sent before websocket opened
		for message in @message_queue
			@iframe.contentWindow.postMessage message, "*"
		@message_queue = []

		if @onOpen? then @onOpen(e)


	onErrorWebsocket: (e) =>
		@log "Error", e
		if @onError? then @onError(e)


	onCloseWebsocket: (e, reconnect=10000) =>
		@log "Closed", e
		@connected = false
		if e and e.code == 1000 and e.wasClean == false
			@log "Server error, please reload the page", e.wasClean
		else # Connection error
			setTimeout (=>
				@log "Reconnecting..."
				@connect()
			), reconnect
		if @onClose? then @onClose(e)


window.WebsocketGate = WebsocketGate
