import startServer from './server'
import makeStore from './store'
import {update, statePushed} from './game/action_creators'


const store = makeStore()
const io = startServer(store)


const GAMEAREA = [500, 500]


// calculate physics and game state. loop at same interval as clients
let lastInv = +new Date()
function physicsUpdate() {
	const now = +new Date()
	const delta = (now - lastInv)/1000
	lastInv = now
	
	store.dispatch(update(delta, GAMEAREA))
	
}


// push state to clients. loop at 45ms interval
let prevState = store.getState()
function serverUpdate() {
	const newState = store.getState()
	if (newState.get('players') && !newState.equals(prevState)) {
        let tmp = makeOutput(newState)
		// if (tmp.players[0]) {
		// 	console.log('data', JSON.stringify(tmp.players, null, 2))
		// }
        
		io.emit('gameState', tmp)
		store.dispatch(statePushed())
		prevState = newState
	}
}


function makeOutput(state) {
	const round = state.get('round')
	
	const players = state.get('players').map((v, k) => {
		// let pathBuffer = []
		
		// pathBuffer = v.get('pathBuffer').map((v, k) => {
		// 	return positionOnline(v, round)
		// })
		
		return v
			.set('id', k)
			// .set('pathBuffer', pathBuffer)
			.remove('path')
			.remove('direction')
	}).toArray()
	
	return state
			.set('players', players)
			.set('gamearea', GAMEAREA)
			.set('serverTime', +new Date())
			.toJS()
	
}


function positionOnline(pos, round) {
    return {
        position: pos
    }
}


setInterval(physicsUpdate, 1000/35) // 35 fps, same as on client
setInterval(serverUpdate, 45)