import {List, Map, fromJS} from 'immutable'

const INITIAL_STATE = Map()
const PLAYERS_REQUIRED = 2


const STRAIGHT = 'Straight'
const LEFT = 'Left'
const RIGHT = 'Right'

const MAX_ANGLE_CHANGE = 5
const SPEED = 125
const SNAKE_WIDTH = 3
const SAFETY_MARGIN = 0


export const DEFAULT_PLAYER = Map({
	path: List(),
    lastPositions: List(),
	angle: 0,
	direction: STRAIGHT,
	alive: true,
	score: 0,
    color: null
})


export function update(delta, gamearea, game = Map()) {
	const nextState = updateState(game.get('players'), game.get('state')),
	
		  nextPlayers = updatePlayers(delta, gamearea, game.get('state'), nextState, game.get('players')),
		  
		  nextRound = updateRound(game.get('state'), nextState, game.get('round'))	
	
	
	return game.set('state', nextState)
			   .set('players', nextPlayers)
			   .set('round', nextRound)
}


export const STATE_WAITING_PLAYERS = 'WaitingPlayers' 
export const STATE_PLAY = 'Play'
export const STATE_ROUNDOVER = 'Roundover'


function updateState(players, state = STATE_WAITING_PLAYERS) {
	
	switch(state) {
        case STATE_WAITING_PLAYERS:
			if (enoughPlayers(players)) {
                console.log('Game on!!')
				return STATE_PLAY
			}
            
			return state
			
        case STATE_PLAY:
            if (typeof players === 'undefined') {
                // All players have disconnected
                return STATE_WAITING_PLAYERS
            }
            
			const alive = players.filter(p => {
				return p.get('alive') === true
			})
			if (alive.count() < 2) {
                console.log('Round over!!')
				return STATE_ROUNDOVER
			}
            
			return state
			
        case STATE_ROUNDOVER:
			// Set to PLAY straight away
			// MAY implement a short wait period
			// in between rounds
            
            if (enoughPlayers(players)) {
                console.log('Starting new round!')
				return STATE_PLAY
			}
            
			return STATE_WAITING_PLAYERS
		
	}
	
}


function updatePlayers(delta, gamearea, state, nextState, players = Map()) {
	
	switch(nextState) {
        case STATE_WAITING_PLAYERS:
			return players
			
        case STATE_PLAY:
            if (state === STATE_PLAY) {
                
                return players.map((player, id) => {
                    const opponents = players.delete(id)
                    return updatePlayer(delta, gamearea, opponents, player)
                })
                
            } else if (state === STATE_ROUNDOVER) {
                
                return players.map((player, id) => {
                    const opponents = players.delete(id)
                    const nextPlayer = updatePlayer(delta, gamearea, opponents, player)
                    return initPlayer(gamearea, nextPlayer)
                })
                
            } else {
                return players
            }
            
			
			
        case STATE_ROUNDOVER:
			return players
		
	}
	
	return players
}


function updateRound(state, nextState, round = 1) {
    
    if (state === STATE_PLAY && nextState === STATE_ROUNDOVER) {
        return round + 1
    }
    
    return round
    
}


function updatePlayer(delta, gamearea, opponents, player) {
    if (!player.get('alive')) {
        return player
    }
          
    if (player.get('path').first() === undefined) {
        return initPlayer(gamearea, player)
    }
    
    const nextPlayer = move(delta, player),
    
          position = nextPlayer.get('path').first()
        
        
    const paths = collisionPaths(nextPlayer, opponents),
    
          hs = paths.some(path => {
              return hitSnake(path, position)
          }),
          
          hw = hitWall(position, gamearea),
          
          winner = opponents.filter(p => { return p.get('alive') === true }).count() < 1
          
          
    if (hs) {
        // console.log('hs!')
        return nextPlayer.set('alive', false)
        
    } else if (hw) {
        // console.log('hw!')
        return nextPlayer.set('alive', false)
        
    } else if (winner) {
        // console.log('winner :D')
        return nextPlayer.set('alive', false)
                         .set('score', player.get('score') + 1)                    
    } 
    
    
    return nextPlayer
}


function move(delta, player) {
    const direction = player.get('direction')
    let angle = player.get('angle')
    if (direction == LEFT) {
        angle = angle + MAX_ANGLE_CHANGE
    } else if (direction == RIGHT) {
        angle = angle + -MAX_ANGLE_CHANGE
    }
    
    const vx = Math.cos(angle * Math.PI / 180),
          vy = Math.sin(angle * Math.PI / 180),
    
          position = player.get('path').first(), // position = { x = -2, y = 5, visible: true }
          
          nextX = position.x + vx * (delta * SPEED),
          nextY = position.y + vy * (delta * SPEED),
    
          holes = randomHole(),
          
          puncturedPath = puncture(player.get('path'), holes),
          
          nextPosition = { x: nextX, y: nextY, visible: true },
          
          path = puncturedPath.unshift(nextPosition)

    
    return player.set('angle', angle)
                 .set('path', path)
                 .set('puncture', holes)
                 .set('lastPositions', player.get('lastPositions').unshift(nextPosition))
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


function collisionPaths(player, opponents) {
    const opponentsPaths = opponents.reduce((acc, o) => {
              return acc.push(o.get('path'))
          }, List()),
        
          myPath = player.get('path').skip(10),
        
          combinedPaths = myPath.concat(opponentsPaths).flatten()
          
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
          path = List().push(randomPosition(gamearea))
          
    
    return player.set('angle', angle)
                 .set('path', path)
                 .set('alive', true)
}


function randomAngle() {
    const angle = Math.floor(Math.random() * 360) + 0
    return angle
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


function enoughPlayers(players) {
    if (players && players.count() >= PLAYERS_REQUIRED) {
        return true
    }
    
    return false
}