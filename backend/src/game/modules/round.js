import {PLAY, ROUNDOVER} from './state'


// ACTIONS


const UPDATE = 'achtung/round/UPDATE'


// CONSTANTS AND DEFAULTS


const INITIAL_STATE = 0


// REDUCER


export default function reducer(round = INITIAL_STATE, action) {
    switch(action.type) {
        case UPDATE:
            if (action.state == PLAY && action.nextState == ROUNDOVER) {
                return round + 1
            }
            
            return round
    }
    
    return round
}


// ACTION CREATORS


export function update(state, nextState) {
	return {
        type: UPDATE,
        state,
        nextState
    }
}


// PRIVATE