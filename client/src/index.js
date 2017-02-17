import Elm from './Main'


const game = Elm.fullscreen(Elm.Main, {
	serverInput: null,
	serverIdInput: null
})

const WS_TOPIC = {
	PINGPONG: 'p',
	PLAYER_OUTPUT: 'o',
	PLAYER_ID: 'i',
	GAME_STATE: 's'
}

const Socket = window.MozWebSocket || window.WebSocket

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

	ws = new Socket('ws://localhost:9000')
	ws.binaryType = 'arraybuffer'
	ws.onopen = onOpen
	ws.onclose = onClose
	ws.onmessage = onMessage
	ws.onerror = onError

})

function onOpen(event) {
	console.info('websocket opened', event)
}

function onClose(event) {
	console.info('websocket closed', event)
}

function onError(event) {
	console.log('websocket error', event)
	ws.close()
}

function onMessage(msg) {
	const { topic, data } = decode(msg.data)

	switch (topic) {
		case WS_TOPIC.GAME_STATE:
			game.ports.serverInput.send(data)
			break

		case WS_TOPIC.PLAYER_ID:
			game.ports.serverIdInput.send(data)
			break

		case WS_TOPIC.PINGPONG:
			ws.send(encode(WS_TOPIC.PINGPONG, data))
			break
	
		default:
			break
	}
}

function encode(topic, data) {
	if (typeof topic !== 'string' || topic.length !== 1) {
		throw new Error('Subprotocol Error - Topic invalid')
	}
	return topic + (typeof data === 'string' ? data : JSON.stringify(data))
}

function decode(string) {
	const topic = string.charAt(0),
		data = string.slice(1, string.length),
		needsParsing = data.charAt(0) === '"' || data.charAt(0) === '{'

	return {
		topic,
		data: needsParsing ? JSON.parse(data) : data
	}
}