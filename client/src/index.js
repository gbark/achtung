import Elm from './Main'


const game = Elm.fullscreen(Elm.Main, {
	serverInput: null,
	serverIdInput: null
})


let ws = null


game.ports.playerOutput.subscribe(output => {
	if (ws && ws.readyState === ws.OPEN) {
		ws.send(encode('playerOutput', output))
	}

})


game.ports.onlineGame.subscribe(() => {
	if (ws) {
		ws.close()
	}

	ws = new WebSocket('ws://localhost:9000')
	ws.onopen = onOpen;
	ws.onclose = onClose;
	ws.onmessage = onMessage;
	ws.onerror = onError;

})

function onOpen(event) {
	console.info('websocket opened', event)
}

function onClose(event) {
	console.info('websocket closed', event)
}

function onError(event) {
	console.log('websocket error', event)
}

function onMessage(event) {
	const { topic, data } = decode(event.data)

	switch (topic) {
		case 'gameState':
			game.ports.serverInput.send(data)
			break;

		case 'playerId':
			game.ports.serverIdInput.send(data)
			break;

		case 'dtt':
			ws.send(encode('dtt', data))
			break;
	
		default:
			break;
	}
}

function encode(topic, data) {
	return JSON.stringify({
		t: topic,
		d: data
	})
}

function decode(string) {
	const obj = JSON.parse(string)
	return {
		topic: obj.t,
		data: obj.d
	}
}