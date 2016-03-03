import Elm from './Main'
import socket from 'socket.io-client'


const game = Elm.fullscreen(Elm.Main, {
	serverInput: null,
	serverIdInput: null
})


let ws = null


game.ports.playerOutput.subscribe((output) => {
	if (ws && ws.connected) {
		ws.emit('playerOutput', output)
	}
	
})


game.ports.onlineGame.subscribe(() => {
	if (ws) {
		ws.close()
	}
	
	ws = socket('http://localhost:9000')
	
	ws.on('gameState', (data) => {
		game.ports.serverInput.send(data)
	})
	
	ws.on('playerId', (id) => {
		game.ports.serverIdInput.send(id)
	})
	
})
