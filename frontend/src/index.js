import Elm from './Main'
import socket from 'socket.io-client'


const game = Elm.fullscreen(Elm.Main, {
	serverInput: null
})


let ws = null


game.ports.playerOutput.subscribe((output) => {
	// console.log('playerOutput', output)
	
	if (ws && ws.connected) {
		ws.emit('playerOutput', output)
	}
	
})


game.ports.onlineGame.subscribe(() => {
	console.log('onlineGame')
	
	if (ws) {
		ws.close()
	}
	
	ws = socket('http://localhost:9000')
	
	ws.on('gameState', (data) => {
		debugger
		console.log('gameState', data)
		// const data = JSON.parse(event.data)
		// game.ports.serverInput.send(data)
	})
	
})
