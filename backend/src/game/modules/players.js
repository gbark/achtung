import {List, Map, fromJS, Stack} from 'immutable'


// ACTIONS


const UPDATE = 'achtung/players/UPDATE'
const ADD_PLAYER = 'achtung/players/ADD_PLAYER'
const REMOVE_PLAYER = 'achtung/players/REMOVE_PLAYER'
const SET_DIRECTION = 'achtung/players/SET_DIRECTION'


// CONSTANTS AND DEFAULTS


const STRAIGHT = 'Straight'
const LEFT = 'Left'
const RIGHT = 'Right'


const DEFAULT_PLAYER = Map({
	path: Stack(),
	angle: null,
	direction: STRAIGHT,
	alive: true,
	score: 0
})


const MAX_ANGLE_CHANGE = 5
const SPEED = 125
const SNAKE_WIDTH = 3
const SAFETY_MARGIN = 200


const INITIAL_STATE = Map()


// REDUCER


export default function reducer(players = INITIAL_STATE, action) {
    switch(action.type) {
        case UPDATE:            
            return players.map((v, k) => {
                console.log('##### invoking updatePlayer', v)
                if (v) {
                    updatePlayer(action.delta, action.gamearea, players, v)
                }
                
            })
            
        case ADD_PLAYER:
			return players.set(action.id, DEFAULT_PLAYER)
            
        case REMOVE_PLAYER:
			return players.delete(action.id)
            
        case SET_DIRECTION:
            return players.setIn([action.id, 'direction'], action.direction)
            
    }

    return players
}


// ACTION CREATORS


export function update(delta, gamearea) {
	return {
        type: UPDATE,
        delta,
        gamearea
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


export function setDirection(direction, id) {
	return {
        type: SET_DIRECTION,
        direction,
        id
    }
}


// PRIVATE


function updatePlayer(delta, gamearea, players, player) {
    console.log('updatePlayer invoked')
    
    if (!player.get('alive')) {
        return player
    }
          
    
    if (player.position === undefined) {
        return initPlayer(gamearea, player)
    }
    
    
    const nextPlayer = move(delta, player),
    
          position = nextPlayer.path.get()
        
        
    const paths = collisionPaths(nextPlayer, players),
    
          hs = paths.some(path => {
              return hitSnake(path, position)
          }),
          
          hw = hitWall(position, gamearea),
          
          winner = players.filter(p => { return p.alive }).length < 2
          
    
    if (hs || hw) {
        return nextPlayer.set('alive', false)
    } else if (winner) {
        return nextPlayer.set('alive', false)
                         .set('score', player.get('score') + 1)
    }
    
    
    return nextPlayer
}


function move(delta, player) {
    let angle = player.angle
    if (player.direction == LEFT) {
        angle = player.angle + MAX_ANGLE_CHANGE
    } else if (player.direction == RIGHT) {
        angle = player.angle + -MAX_ANGLE_CHANGE
    }
    
    
    const vx = Math.cos(angle * Math.PI / 180),
          vy = Math.sin(angle * Math.PI / 180),
    
          position = player.get('path').first(), // position = { x = -2, y = 5, visible: true }
          
          nextX = position.x + vx * (delta * SPEED),
          nextY = position.y + vy * (delta * SPEED),
    
          holes = randomHole(),
          
          puncturedPath = puncture(player.path, holes),
          
          path = puncturedPath.unshift({ x: nextX, y: nextY, visible: true })

    
    return player.set('angle', angle)
                 .set('path', path)
}


function randomHole() {
    // Create hole 1 out of 150 times
    const hole = (Math.floor(Math.random() * 150) + 1) === 1
    
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
    
    const marginWidth = 1,
        
          withMargin = path.take(width + marginWidth),
    
          margin = withMargin.take(marginWidth),
        
          toPuncture = withMargin.skip(marginWidth),
        
          rest = path.skip(width+marginWidth),
        
          punctured = toPuncture.map(p => {
              return {
                  // Use ...p
                  x: p.x,
                  y: p.y,
                  visible: false
              }
          })
        
    return margin.concat(punctured, rest)
}


function collisionPaths(player, players) {
    const opponents = players.filter(p => { return p.id !== player.id }),
    
          opponentsPaths = opponents.reduce((o, acc) => {
              acc.push(o.get('path'))
          }, []),
        
          myPath = player.get('path').skip(10),
        
          combinedPaths = myPath.concat(opponentsPaths)
        
    return combinedPaths.filter(p => {
        return p.visible === true
    })
}


function near(n, c, m) {
    return m >= n-c && m <= n+c
}


function hitSnake(position1, position2) {
    return near(position1.x, SNAKE_WIDTH, position2.x) && 
           near(position1.y, SNAKE_WIDTH, position2.y)
}


function hitWall(position, gamearea) {
    if (!position.visible) {
        return false
    }
    
    const width = gamearea[0],
          height = gamearea[1]
    
    if (position.x >= (width / 2)) {
        return true
    } else if (position.x <= -(width / 2)) {
        return true
    } else if (position.y >= (height / 2)) {
        return true
    } else if (position.y <= -(height / 2)) {
        return true
    }
    
    return false
}


function initPlayer(gamearea, player) {
    const angle = randomAngle(),
          path = Stack().push(randomPosition(gamearea))
          
    
    return player.set('angle', angle)
                 .set('path', path)
                 .set('alive', true)
}


function randomAngle() {
    return Math.floor(Math.random() * 360) + 0
}


function randomPosition(gamearea) {
    const width = gamearea[0] - SAFETY_MARGIN,
          height = gamearea[1] - SAFETY_MARGIN,
          x = Math.floor(Math.random() * width/2) + -(width/2),
          y = Math.floor(Math.random() * height/2) + -(height/2)
          
          
    return {
        visible: true,
        x,
        y
    }
}
