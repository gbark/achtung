import test from 'ava'
import reducer from '../src/game/reducer'
import { Map } from 'immutable'

import { testReducer } from './utils'

import {
    updateWaitingList
    , addPlayer
    , removePlayer
    , updateGame
    , setDirection
    , clearPositions
    , endCooldown
    , setRoundTripTime
    , cleanUp
} from '../src/game/action_creators'

test('reducer has an initial state', t => {
    const initial = undefined
    const expected = {
        waiting: [],
        waitingTime: 0,
        games: {}
    }

    t.pass(testReducer(t, reducer, initial, {}, expected))
})

test('reducer handles adding one player', t => {
    const playerId = 1
    const initial = {
        waiting: [],
        waitingTime: 0,
        games: {}
    }
    const expected = {
        waiting: [playerId],
        waitingTime: 0,
        games: {}
    }

    t.pass(testReducer(t, reducer, initial, addPlayer(playerId), expected))
})

test('reducer handles adding existing player', t => {
    const playerId = 1
    const initial = {
        waiting: [playerId],
        waitingTime: 0,
        games: {}
    }
    const expected = {
        waiting: [playerId],
        waitingTime: 0,
        games: {}
    }

    t.pass(testReducer(t, reducer, initial, addPlayer(playerId), expected))
})
