import startServer from './server'
import makeStore from './store'
import {update} from './game/modules/players'

const store = makeStore()
const io = startServer(store)


// calculate physics and game state. loop at 15ms interval
let lastRan = +new Date()
function physicsUpdate() {
	const now = +new Date()
	const delta = now - lastRan
	lastRan = now
	
	store.dispatch(update(delta, [500, 500]))
}


// push state to clients. loop at 45ms interval
let prevState = store.getState()
function serverUpdate() {
	const newState = store.getState()
	if (!newState.equals(prevState)) {
		io.emit('gameState', newState.toJS())
		prevState = newState
	}
}


setInterval(physicsUpdate, 15)
setInterval(serverUpdate, 45)