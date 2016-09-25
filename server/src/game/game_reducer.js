import { List, Map } from 'immutable'

import { update
       , STATE_COOLDOWN_OVER
       } from './core'

import { UPDATE_GAME
       , SET_DIRECTION
       , CLEAR_POSITIONS
       , END_COOLDOWN
       , SET_ROUND_TRIP_TIME
       } from './action_creators'


export default function reducer(game, action) {
    switch(action.type) {
        case UPDATE_GAME:
            return update(action.delta, game)

        case SET_DIRECTION:
            if (!game.getIn(['players', action.id])) {
                return game
            }
            if (game.getIn(['players', action.id, 'direction']) === action.direction) {
                return game
            }
            if (game.get('sequence') < action.sequence) {
                // console.log('Player ' + action.id + ' is trying to set direction for seq ' + action.sequence + ' which is in the future. Server is only at seq ' + game.get('sequence'))

                // Allow this if round is over to that snakes dont get "frozen" in the last rounds direction
                if (game.get('state') === STATE_PLAY) {
                    return game
                }
            }

            return game
                    .setIn(['players', action.id, 'sequence'], action.sequence)
                    .setIn(['players', action.id, 'direction'], action.direction)


        case CLEAR_POSITIONS:
            const players = game.get('players').map(p => {
                return p.set('latestPositions', List())
                        .set('puncture', 0)
            })

            return game.set('players', players)

        case END_COOLDOWN:
            return game.set('state', STATE_COOLDOWN_OVER)

        case SET_ROUND_TRIP_TIME:
            if (!game.getIn(['players', action.id])) {
                return game
            }
            // console.log('rtt for user ' + action.id + ' is ' + action.time)
            return game.setIn(['players', action.id, 'roundTripTime'], action.time)

        default:
            return game

    }
}