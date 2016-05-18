import { startServer, detectRoundTripTime } from './server'
import makeStore from './store'
import { update, clearPositions, endCooldown } from './game/action_creators'
import { STATE_COOLDOWN, STATE_PLAY } from './game/core'


const store = makeStore()
const io = startServer(store)
let prevState = store.getState()

export const PHYSICS_INTERVAL = 1000/35
const SERVER_INTERVAL = 50
const LATENCY_DETECTION_INTERVAL = 500
const ROUND_COOLDOWN_TIME = 2000

setInterval(physicsUpdate, STEP_INTERVAL) // 35 fps, same as on client
setInterval(serverUpdate, SERVER_INTERVAL)
setInterval(() => { detectRoundTripTime(io) }, LATENCY_DETECTION_INTERVAL)



// calculate physics and game state
let lastInv = +new Date()
function physicsUpdate() {
	const now = +new Date()
	const delta = (now - lastInv)/1000
	lastInv = now

	store.dispatch(update(delta))
}


// push state to clients
let updating = false
let seqAtLastUpdate = 0
function serverUpdate() {
	if (updating) {
		return false
	}
	updating = true

	const newState = store.getState()
	if (newState.get('players') && !newState.equals(prevState)) {
		// console.log('diff', (newState.get('sequence')-seqAtLastUpdate))
		seqAtLastUpdate = newState.get('sequence')
		io.emit('gameState', makeOutput(newState))
		store.dispatch(clearPositions())
		prevState = newState
	}

	updating = false

    return true
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
			.set('serverTime', +new Date())
			.toJS()
}


let countdown = null
function startNewRoundCountdown(state) {
    if (countdown === null) {
        if (state.get('state') === STATE_COOLDOWN) {
            countdown = setTimeout(() => {
                store.dispatch(endCooldown())
                countdown = null
            }, ROUND_COOLDOWN_TIME)
        }
    }
}

// Push state immediatly after a round has started to minimise
// delay between server and client update function
function forcePushStateAtRoundStart(state) {
	if (prevState.get('state') !== STATE_PLAY && state.get('state') === STATE_PLAY) {
		serverUpdate()
	}
}


store.subscribe(() => {
	const state = store.getState()
	startNewRoundCountdown(state)

    // Seems to cause race condition?
	forcePushStateAtRoundStart(state)
})