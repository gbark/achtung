import { List, Map } from 'immutable'

import {STATE_WAITING_PLAYERS
	   , STATE_PLAY
	   , STATE_ROUNDOVER
	   , DEFAULT_PLAYER
	   , update
       , STATE_COOLDOWN_OVER } from './core'

import { UPDATE
	   , ADD_PLAYER
	   , REMOVE_PLAYER
	   , SET_DIRECTION
       , CLEAR_BUFFER
       , END_COOLDOWN } from './action_creators'

export default function reducer(state = Map(), action) {
    switch(action.type) {
        case UPDATE:
            return update(action.delta, action.gamearea, state)
            
        case ADD_PLAYER:
            if (state.get('state') === STATE_WAITING_PLAYERS) {
                return state.setIn(['players', action.id], DEFAULT_PLAYER.set('color', action.color))
            }
            
            return state
			            
        case REMOVE_PLAYER:
			return state.deleteIn(['players'], action.id)
            
        case SET_DIRECTION:
            if (state.get('state') === STATE_PLAY) {
                if (state.getIn(['players', action.id])) {
                    return state.setIn(['players', action.id, 'direction'], action.direction)
                }
            }
            
            return state
            
        case CLEAR_BUFFER:
            let players = state.get('players')
            if (players) {
                players = players.map(p => {
                    return p.set('pathBuffer', List())
                            .set('puncture', 0)
                })
                
                return state.set('players', players)
            }
            
            return state
            
        case END_COOLDOWN:
            return state.set('state', STATE_COOLDOWN_OVER)
            
        default:
            return state
            
    }
}