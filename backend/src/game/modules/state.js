// ACTIONS


const UPDATE = 'achtung/state/UPDATE'


// CONSTANTS AND DEFAULTS


export const SELECT = 'Select' // Change name to WAITING_PLAYERS ? 
export const START = 'Start'
export const PLAY = 'Play'
export const ROUNDOVER = 'Roundover'


const INITIAL_STATE = SELECT


const PLAYERS_REQUIRED = 2


// REDUCER


export default function reducer(state = INITIAL_STATE, action) {
     switch(action.type) {
        case UPDATE:
            switch(state) {
                case SELECT: 
                    if (action.players.count() >= PLAYERS_REQUIRED) {
                        return START
                    } else {
                        return SELECT
                    }
                
                case START: 
                    // This state only makes sense
                    // in Local mode so we set it to
                    // PLAY straight away
                    return PLAY
                
                
                case PLAY: 
                    const alive = action.players.filter(p => {
                        return p.alive === true
                    })
                    
                    if (alive.isEmpty()) {
                        return ROUNDOVER
                    } 
                    
                    return PLAY
                
                
                case ROUNDOVER: 
                    // Set to PLAY straight away
                    // MAY implement a short wait period
                    // in between rounds
                    return PLAY
                
                
            }
            
    }

    return state
}


// ACTION CREATORS


export function update(players) {
	return {
        type: UPDATE,
        players
    }
}


// PRIVATE
