import {combineReducers} from 'redux-immutable'


import players from './modules/players'
import state from './modules/state'
import round from './modules/round'


export default combineReducers({
    players,
    state,
    round
})