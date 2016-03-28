import startServer from './server'
import makeStore from './store'
import {update, clearBuffer, endCooldown} from './game/action_creators'
import {STATE_COOLDOWN} from './game/core'


const store = makeStore()
const io = startServer(store)


const GAMEAREA = [500, 500]
const COOLDOWN_TIME = 1500


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
		io.emit('gameState', makeOutput(newState))
		store.dispatch(clearBuffer())
		prevState = newState
	}
}

function makeOutput(state) {
	const players = state.get('players').map((v, k) => {
		return v
			.set('id', k)
			.remove('path')
			.remove('direction')
	}).toArray()
	
	return state
			.set('players', players)
			.set('gamearea', GAMEAREA)
			.set('serverTime', +new Date())
			.toJS()
}


let countdown = null
function startNewRoundCountdown() {
    if (countdown === null) {
        const state = store.getState()
        
        if (state.get('state') === STATE_COOLDOWN) {
            countdown = setTimeout(() => {
                store.dispatch(endCooldown())
                countdown = null
            }, COOLDOWN_TIME)
        }
    }
}

store.subscribe(startNewRoundCountdown)


setInterval(physicsUpdate, 1000/35) // 35 fps, same as on client
setInterval(serverUpdate, 45)