import { List, Map } from 'immutable'

import { STATE_WAITING_PLAYERS
	   , STATE_PLAY
	   , STATE_ROUNDOVER
	   , DEFAULT_PLAYER
	   , update
       , STATE_COOLDOWN_OVER
       } from './core'

import { UPDATE
	   , ADD_PLAYER
	   , REMOVE_PLAYER
	   , ADD_INPUT
       , CLEAR_POSITIONS
       , END_COOLDOWN
       , SET_ROUND_TRIP_TIME
       } from './action_creators'


const DEFAULT_GAME = Map({
	players: Map(),
    sequence: 0,
    gamearea: List([500, 500]),
    state: STATE_WAITING_PLAYERS,
    round: 1
})


export default function reducer(state = DEFAULT_GAME, action) {
    switch(action.type) {
        case UPDATE:
            return update(action.delta, state)

        case ADD_PLAYER:
            if (state.get('state') === STATE_WAITING_PLAYERS) {
                return state.setIn(['players', action.id], DEFAULT_PLAYER.set('color', action.color))
            }

            return state

        case REMOVE_PLAYER:
			return state.deleteIn(['players'], action.id)

        case ADD_INPUT:
            if (!state.getIn(['players', action.id])) {
                return state
            }
            if (state.getIn(['players', action.id, 'direction']) === action.direction) {
                return state
            }
            if (state.get('sequence') < action.sequence) {
                console.log('Player ' + action.id + ' is trying to set direction for seq ' + action.sequence + ' which is in the future. Server is only at seq ' + state.get('sequence'))
                
                // Allow this if round is over.
                // This will avoid snakes from getting "frozen" in the last rounds direction
                if (state.get('state') === STATE_PLAY) {
                    return state
                }
            }
            
            const inputs = state.getIn(['players', action.id, 'inputs'])
            const input = {
                sequence: action.sequence,
                direction: action.direction,
                roundTripTime: state.getIn(['players', action.id, 'roundTripTime'])
            }

            return state.setIn(['players', action.id, 'inputs'], inputs.push(Map(input)))
            
            
        case CLEAR_POSITIONS:
            const players = state.get('players').map(p => {
                return p.set('latestPositions', List())
                        .set('puncture', 0)
            })

            return state.set('players', players)

        case END_COOLDOWN:
            return state.set('state', STATE_COOLDOWN_OVER)

        case SET_ROUND_TRIP_TIME:
            if (!state.getIn(['players', action.id])) {
                return state
            }
            // console.log('rtt for user ' + action.id + ' is ' + action.time)
            return state.setIn(['players', action.id, 'roundTripTime'], action.time)

        default:
            return state

    }
}