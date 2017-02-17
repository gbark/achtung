import gameloop from 'node-gameloop'

import { startServer, encode, sendToId, WS_TOPIC } from './server'
import makeStore from './store'
import { updateGame
       , clearPositions
       , endCooldown
       , updateWaitingList
       , cleanUp
       } from './game/action_creators'
import { STATE_COOLDOWN } from './game/core'


const ROUNDOVER_COOLDOWN_TIME = 2000

const LOBBY_UPDATE_INTERVAL = 1000
const COOLDOWN_UPDATE_INTERVAL = ROUNDOVER_COOLDOWN_TIME + 1 // Avoids running multiple timers per game without having to keep references to them
const PHYSICS_UPDATE_INTERVAL = 1000/35 // 35 fps, same as on client
const SERVER_UPDATE_INTERVAL = 50 // @todo Figure out if there is a better number to use
const RTT_DETECTION_INTERVAL = 500 // @todo Figure out if there is a better number to use


const store = makeStore()
const wss = startServer(store)


gameloop.setGameLoop(lobbyUpdate, LOBBY_UPDATE_INTERVAL)
gameloop.setGameLoop(cooldownUpdate, COOLDOWN_UPDATE_INTERVAL)
gameloop.setGameLoop(physicsUpdate, PHYSICS_UPDATE_INTERVAL)
gameloop.setGameLoop(serverUpdate, SERVER_UPDATE_INTERVAL)
gameloop.setGameLoop(() => { 
    wss.broadcast(encode(WS_TOPIC.PINGPONG, Date.now())) 
}, RTT_DETECTION_INTERVAL)


// Update lobby queue, start new games, and clean up stale game instances
function lobbyUpdate(delta) {
    const state = store.getState()

    if (state.get('games').size > 0) {
        store.dispatch(cleanUp())
    }

    if (state.get('waiting').size > 0) {
        store.dispatch(updateWaitingList(delta))
    }
}

// Finish game over cooldown period
function cooldownUpdate(delta) {
    store.getState().get('games').map((game, gameId) => {

        if (game.get('state') === STATE_COOLDOWN) {

            setTimeout(() => { store.dispatch(endCooldown(gameId)) }, ROUNDOVER_COOLDOWN_TIME)

        }

    })
}

// Calculate physics and game state
function physicsUpdate(delta) {
    if (store.getState().get('games').size < 1) {
        return false
    }

    return store.dispatch(updateGame(delta))
}


// Push state to clients
let updating = false
function serverUpdate() {
    if (updating) {
        return
    }
    updating = true

    store.getState().get('games').map((game, gameId) => {

        game.get('players').map((p, id) => {
            sendToId(wss, id, WS_TOPIC.GAME_STATE, makeOutput(game))
        })

        store.dispatch(clearPositions(gameId))

    })

    updating = false
}


function makeOutput(state) {
    const players = state.get('players').map((v, k) =>
            v.set('id', k)
             .remove('path')
             .remove('direction')
    ).toArray()

    return state
            .set('players', players)
            .set('serverTime', +new Date())
            .toJS()
}
