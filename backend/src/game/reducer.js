import { INITIAL_STATE
       , addPlayer
       , removePlayer
       , step 
       } from './core'

export default function reducer(state = INITIAL_STATE, action) {
    switch(action.type) {
        case 'STEP':
            return step(state, action.input)
            
        case 'ADD_PLAYER':
            return addPlayer(state, action.id)
            
        case 'REMOVE_PLAYER':
            return removePlayer(state, action.id)
            
    }

    return state
}