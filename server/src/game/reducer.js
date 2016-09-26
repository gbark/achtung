import { List, Map } from 'immutable'

import { UPDATE_WAITING_LIST
       , ADD_PLAYER
       , REMOVE_PLAYER
       , UPDATE_GAME
       , SET_DIRECTION
       , CLEAR_POSITIONS
       , END_COOLDOWN
       , SET_ROUND_TRIP_TIME
       } from './action_creators'


import { STATE_WAITING_PLAYERS
       , STRAIGHT
       } from './core'

import gameReducer from './game_reducer'


const INITIAL_STATE = Map({
    waiting: List(),
    waitingTime: 0,
    games: List()
})


const INITIAL_GAME = Map({
    players: Map(),
    sequence: 0,
    gamearea: List([500, 500]),
    state: STATE_WAITING_PLAYERS,
    round: 1
})


const INITAL_PLAYER = Map({
    path: List(),
    latestPositions: List(),
    angle: 0,
    direction: STRAIGHT,
    alive: true,
    score: 0,
    color: null,
    sequence: -1,
    roundTripTime: null
})


const MAX_WAITING_TIME = 25
const MIN_PLAYERS = 2
const MAX_PLAYERS = 3
const COLORS = List([
    'yellow',
    'red',
    'blue',
    'green',
    'purple',
    'orange',
    'white',
    'brown',
    'grey'
])


export default function reducer(state = INITIAL_STATE, action) {
    switch(action.type) {
        case UPDATE_WAITING_LIST:
            if (state.get('waiting').count() < 1) {
                console.log('No players in lobby')
                return state.set('waitingTime', 0)
            }

            if (state.get('waiting').count() < MIN_PLAYERS) {
                console.log('One player in lobby')
                return state.set('waitingTime', 0)
            }

            if (state.get('waiting').count() >= MAX_PLAYERS) {
                return createGame(state, action)
            }

            if (state.get('waitingTime') >= MAX_WAITING_TIME && state.get('waiting').count() >= MIN_PLAYERS) {
                return createGame(state, action)
            }

            const secondsLapsed = (state.get('waitingTime') + action.secondsSinceLastUpdate)
            const count = state.get('waiting').count()

            console.log(`${count} players have joined. Waiting for ${MAX_PLAYERS-count} more, or for ${(MAX_WAITING_TIME - secondsLapsed)} seconds to pass.`)


            return state.set('waitingTime', state.get('waitingTime') + action.secondsSinceLastUpdate)

        case ADD_PLAYER:
            const waitingList = state.get('waiting')
            console.log('ADD_PLAYER')

            // Already in waiting list?
            if (waitingList.find(id => id === action.id)) {
                return state
            }

            return state.set('waiting', waitingList.push(action.id))

        case REMOVE_PLAYER:
            const lessRemoved = state.get('waiting').reduce((acc, id) => {
                if (id === action.id) {
                    return acc
                }

                return acc.push(id)
            }, List())

            return state.set('waiting', lessRemoved)

        /**
         * @todo Refactor this to only run on the relevant game based on game id
         */
        case UPDATE_GAME:
        case SET_DIRECTION:
        case SET_ROUND_TRIP_TIME:
            return state.set('games', state.get('games').map(game => {
                return gameReducer(game, action)
            }))

        // These NEED to run on a specified game
        case CLEAR_POSITIONS:
        case END_COOLDOWN:
            return state.set('games', state.get('games').map(game => {
                return gameReducer(game, action)
            }))

    }

    return state
}


function createGame(state, action) {
    const players = state.get('waiting').reduce((acc, p, index) => {
        return acc.set(p, INITAL_PLAYER.set('color', COLORS.get(index)))
    }, Map())

    const newGame = INITIAL_GAME.set('players', players)

    console.log(`Starting game with ${players.count()} players`)

    return state
            .set('games', state.get('games').push(newGame))
            .set('waiting', state.get('waiting').skip(MAX_PLAYERS))
            .set('waitingTime', state.get('waitingTime') + action.secondsSinceLastUpdate)
}