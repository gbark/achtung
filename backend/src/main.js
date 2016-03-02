import startServer from './server'
import makeStore from './store'
import {update} from './game/action_creators'


const store = makeStore()
const io = startServer(store)


// calculate physics and game state. loop at 15ms interval
let lastInv = +new Date()
function physicsUpdate() {
	const now = +new Date()
	const delta = (now - lastInv)/1000
	lastInv = now
	
	store.dispatch(update(delta, [500, 500]))
	
}


// push state to clients. loop at 45ms interval
let prevState = store.getState()
function serverUpdate() {
	const newState = store.getState()
	if (!newState.equals(prevState)) {
		io.emit('gameState', makeOutput(newState))
		prevState = newState
	}
}


function makeOutput(state) {
	let i = 1
	const players = state.get('players').map((v, k) => {
		return v
			.set('id', i++)
			.set('color', 'foo')
			.set('leftKey', 'foo')
			.set('rightKey', 'foo')
			.set('keyDesc', 'foo')
		// return v.set('id', k)
	}).toArray()
	
	return state
			.set('players', players)
			.set('mode', 'Online')
			.set('gamearea', [500, 500])
			.toJS()
	
}


setInterval(physicsUpdate, 15)
setInterval(serverUpdate, 45)