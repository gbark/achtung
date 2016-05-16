export const UPDATE = 'achtung/UPDATE'
export const ADD_PLAYER = 'achtung/ADD_PLAYER'
export const REMOVE_PLAYER = 'achtung/REMOVE_PLAYER'
export const SET_DIRECTION = 'achtung/SET_DIRECTION'
export const CLEAR_POSITIONS = 'achtung/CLEAR_POSITIONS'
export const END_COOLDOWN = 'achtung/END_COOLDOWN'
export const SET_ROUND_TRIP_TIME = 'achtung/SET_ROUND_TRIP_TIME'



export function update(delta) {
	return {
        type: UPDATE,
        delta
    }
}


export function addPlayer(id, color) {
	return {
        type: ADD_PLAYER,
        id,
        color
    }
}


export function removePlayer(id) {
	return {
        type: REMOVE_PLAYER,
        id
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


export function clearPositions() {
	return {
        type: CLEAR_POSITIONS
    }
}


export function endCooldown() {
	return {
        type: END_COOLDOWN,
    }
}


export function setRoundTripTime(id, time) {
	return {
        type: SET_ROUND_TRIP_TIME,
        id,
        time
    }
}