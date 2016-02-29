import {List, Map, fromJS, Stack} from 'immutable'

import {STATE_WAITING_PLAYERS
	   , STATE_PLAY
	   , STATE_ROUNDOVER
	   , DEFAULT_PLAYER
	   , update } from './core'

import { UPDATE
	   , ADD_PLAYER
	   , REMOVE_PLAYER
	   , SET_DIRECTION } from './action_creators'

export default function reducer(state = Map(), action) {
    switch(action.type) {
        case UPDATE:
            return update(action.delta, action.gamearea, state)
            
        case ADD_PLAYER:
            if (state.get('state') === STATE_WAITING_PLAYERS) {
                return state.setIn(['players', action.id], DEFAULT_PLAYER)
            }
            
            console.log('ADD_PLAYER DISMISSED')
            
            return state
			            
        case REMOVE_PLAYER:
			return state.deleteIn(['players', action.id])
            
        case SET_DIRECTION:
            if (state.get('state') === STATE_PLAY) {
                if (state.getIn(['players', action.id])) {
                    return state.setIn(['players', action.id, 'direction'], action.direction)
                }
            }
            
            return state
            
        default:
            return state
            
    }
}