export const UPDATE_WAITING_LIST = 'achtung/UPDATE_WAITING_LIST'
export const ADD_PLAYER = 'achtung/ADD_PLAYER'
export const REMOVE_PLAYER = 'achtung/REMOVE_PLAYER'

export const UPDATE_GAME = 'achtung/UPDATE_GAME'
export const SET_DIRECTION = 'achtung/SET_DIRECTION'
export const CLEAR_POSITIONS = 'achtung/CLEAR_POSITIONS'
export const END_COOLDOWN = 'achtung/END_COOLDOWN'
export const SET_ROUND_TRIP_TIME = 'achtung/SET_ROUND_TRIP_TIME'
export const CLEAN_UP = 'achtung/CLEAN_UP'


export function updateWaitingList(secondsSinceLastUpdate) {
    return {
        type: UPDATE_WAITING_LIST,
        secondsSinceLastUpdate
    }
}


export function addPlayer(id) {
    return {
        type: ADD_PLAYER,
        id
    }
}


export function removePlayer(id) {
    return {
        type: REMOVE_PLAYER,
        id
    }
}


export function updateGame(delta) {
    return {
        type: UPDATE_GAME,
        delta
    }
}


export function setDirection(direction, id, sequence) {
    return {
        type: SET_DIRECTION,
        direction,
        id,
        sequence
    }
}


export function clearPositions(gameId) {
    return {
        type: CLEAR_POSITIONS,
        gameId
    }
}


export function endCooldown(gameId) {
    return {
        type: END_COOLDOWN,
        gameId
    }
}


export function setRoundTripTime(id, time) {
    return {
        type: SET_ROUND_TRIP_TIME,
        id,
        time
    }
}


export function cleanUp() {
    return {
        type: CLEAN_UP
    }
}