import {List, Map, fromJS, Stack} from 'immutable'


// ACTIONS


const UPDATE = 'achtung/players/UPDATE'
const ADD_PLAYER = 'achtung/players/ADD_PLAYER'
const REMOVE_PLAYER = 'achtung/players/REMOVE_PLAYER'


// CONSTANTS AND DEFAULTS


const STRAIGHT = 'Straight'
const LEFT = 'Left'
const RIGHT = 'Right'


const DEFAULT_PLAYER = Map({
	id: null,
	path: Stack(),
	angle: null,
	direction: STRAIGHT,
	alive: true,
	score: 0
})


const MAX_ANGLE_CHANGE = 5
const SPEED = 125
const SNAKE_WIDTH = 3


const INITIAL_STATE = List()


// REDUCER


export default function reducer(players = INITIAL_STATE, action) {
    switch(action.type) {
        case UPDATE:
            let nextPlayers = players.map(p => {
                updatePlayer(action.delta, action.gamearea, action.time, players, p)
            })
            return nextPlayers
            
        case ADD_PLAYER:
            const newPlayer = DEFAULT_PLAYER.set('id', action.id)
			return players.push(newPlayer)
            
        case REMOVE_PLAYER:
            const idx = getPlayerIndex(players, action.id)
			return players.delete(idx)
            
    }

    return players
}


// ACTION CREATORS


export function update(delta, gamearea, time) {
	return {
        type: UPDATE,
        delta,
        gamearea,
        time
    }
}


export function addPlayer(id) {
	return {
        type: ADD_PLAYER,
        id
    }
}


export function removePlayer(state, id) {
	return {
        type: REMOVE_PLAYER,
        id
    }
}


// PRIVATE


function getPlayerIndex(players, id) {
	return players.findLastIndex((p) => {
		return p.id === id
	})
}


function updatePlayer(delta, gamearea, time, players, player) {
    if (!player.get('alive')) {
        return player
    }
    
    let nextPlayer = move(delta, player),
    
        position = nextPlayer.path.first(),
        
        paths = collisionPaths(nextPlayer, players),
    
        hs = paths.some(path => {
            return hitSnake(path, position)
        })
    
    return nextPlayer
}


function move(delta, player) {
    const position = player.get('path').first(); // position = { x = -2, y = 5, visible: true }
        
        
    let angle = player.angle
    if (player.direction == LEFT) {
        angle = player.angle + MAX_ANGLE_CHANGE
        
    } else if (player.direction == RIGHT) {
        angle = player.angle + -MAX_ANGLE_CHANGE
        
    }
    
    
    const vx = Math.cos(angle * Math.PI / 180),
          vy = Math.sin(angle * Math.PI / 180)
          
          
    const nextX = position.x + vx * (delta * SPEED),
          nextY = position.y + vy * (delta * SPEED)
          
    
    const holes = randomHole()
    const puncturedPath = puncture(player.path, holes)
    const path = puncturedPath.add({ x: nextX, y: nextY, visible: true })
    
    
    return player.set('angle', angle)
                 .set('path', path) 
}


function randomHole() {
    // Create hole 1 out of 150 times
    const hole = (Math.floor(Math.random() * 150) + 1) === 1 ? true : false
    
    if (hole) {
        // Hole is 2 to 5 wide
        return Math.floor(Math.random() * 5) + 2
    }
    
    return 0
}


function puncture(path, width) {
    if (width < 1) {
        return path
    }
    
    const withMargin = path.take(width + 1),
    
        margin = withMargin.take(1),
        
        toPuncture = withMargin.skip(1),
        
        rest = path.skip(width+1),
        
        punctured = toPuncture.map(p => {
            return {
                // Use ...p
                x: p.x,
                y: p.y,
                visible: false
            }
        })
        
    return margin.concat([punctured, rest])
}


function collisionPaths(player, players) {
    let opponents = players.filter(p => { return p.id !== player.id }),
    
        opponentsPaths = opponents.reduce((o, acc) => {
            acc.push(o.get('path'))
        }, []),
        
        myPath = player.get('path').skip(10),
        
        combinedPaths = myPath.concat([opponentsPaths])
        
    return combinedPaths.filter(p => {
        return p.visible === true
    })
}


function hitSnake(position1, position2) {
    
}



// near

// hitSnake

// hitWall

// initplayer

// randomAngle

// randomPosition