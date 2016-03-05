export const UPDATE = 'achtung/UPDATE'
export const ADD_PLAYER = 'achtung/ADD_PLAYER'
export const REMOVE_PLAYER = 'achtung/REMOVE_PLAYER'
export const SET_DIRECTION = 'achtung/SET_DIRECTION'



export function update(delta, gamearea) {
	return {
        type: UPDATE,
        delta,
        gamearea
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


export function setDirection(direction, id) {
	return {
        type: SET_DIRECTION,
        direction,
        id
    }
}