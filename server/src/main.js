import gameloop from 'node-gameloop'

import { startServer, detectRoundTripTime } from './server'
import makeStore from './store'
import { updateGame
       , clearPositions
       , endCooldown
       , updateWaitingList
       } from './game/action_creators'
import { STATE_COOLDOWN, STATE_PLAY } from './game/core'


const COOLDOWN_TIME = 2000

const store = makeStore()
const io = startServer(store)
let prevState = store.getState()

gameloop.setGameLoop(lobbyUpdate, 1000)
gameloop.setGameLoop(physicsUpdate, 1000/35) // 35 fps, same as on client
gameloop.setGameLoop(serverUpdate, 50)
gameloop.setGameLoop(() => { detectRoundTripTime(io) }, 500)


function lobbyUpdate() {
    if (!store.getState().get('waiting')) {
        return false
    }

    store.dispatch(updateWaitingList(1000))
}

// calculate physics and game state
function physicsUpdate(delta) {
    if (!store.getState().get('games')) {
        return false
    }

    return store.dispatch(updateGame(delta))
}


// push state to clients
let updating = false
function serverUpdate() {
    if (updating) {
        return
    }
    updating = true

    const newState = store.getState()
    if (!newState.equals(prevState)) {

        newState.get('games').map(game => {

            game.get('players').map((p, id) => {

                io.to('/#' + id).emit('gameState', makeOutput(game))

            })

        })

        store.dispatch(clearPositions())
        prevState = newState
    }

    updating = false
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
            }, COOLDOWN_TIME)
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

    forcePushStateAtRoundStart(state)
})