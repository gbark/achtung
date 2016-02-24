import {combineReducers} from 'redux-immutable'


import players from './modules/players'
import state from './modules/state'
import mode from './modules/mode'
import gamearea from './modules/gamearea'
import round from './modules/round'


export default combineReducers({
    players,
    state,
    mode,
    gamearea,
    round
})