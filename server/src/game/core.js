import { List, Map } from 'immutable'


export const DEFAULT_PLAYER = Map({
	path: List(),
    latestPositions: List(),
	angle: 0,
	direction: STRAIGHT,
	alive: true,
	score: 0,
    color: null,
    sequence: -1,
    roundTripTime: null
})


export const STATE_WAITING_PLAYERS = 'WaitingPlayers' 
export const STATE_PLAY = 'Play'
export const STATE_ROUNDOVER = 'Roundover'
export const STATE_COOLDOWN = 'Cooldown'
export const STATE_COOLDOWN_OVER = 'CooldownOver'


export function update(delta, game) {
	const nextState = updateState(game),
          nextSequence = updateSequence(game, nextState)
    
	return game.set('state', nextState)
			   .set('round', updateRound(game, nextState))
               .set('sequence', nextSequence)
			   .set('players', updatePlayers(game, nextState, nextSequence, delta))
}


const STRAIGHT = 'Straight'
const LEFT = 'Left'
const RIGHT = 'Right'
const PLAYERS_REQUIRED = 2
const MAX_ANGLE_CHANGE = 5
const SPEED = 125
const SNAKE_WIDTH = 3
const SAFETY_MARGIN = 0


function updateState(game) {
    const state = game.get('state'),
          players = game.get('players')
	
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
            return STATE_COOLDOWN
            
            
        case STATE_COOLDOWN:
            if (enoughPlayers(players)) {
				return STATE_COOLDOWN
			}
            
			return STATE_WAITING_PLAYERS
            
            
        case STATE_COOLDOWN_OVER:
            if (enoughPlayers(players)) {
                console.log('Starting new round!')
				return STATE_PLAY
			}
            
			return STATE_WAITING_PLAYERS
		
	}
	
}


function updatePlayers(game, nextState, sequence, delta) {
    const players = game.get('players')
	
	switch(nextState) {
        case STATE_WAITING_PLAYERS:
			return players
			
        case STATE_PLAY:
            const nextPlayers = players.map((p, id) => {
                if (game.get('state') !== STATE_PLAY) {
                    p = initPlayer(game.get('gamearea'), p) 
                }
                
                return updatePlayer(delta, game.get('gamearea'), sequence, players.delete(id), p)
            })
            
            return nextPlayers.map((p, id) => {
                return awardWinner(nextPlayers.delete(id), p)
            })
			
        case STATE_ROUNDOVER:
			return players
			
        case STATE_COOLDOWN:
			return players
			
        case STATE_COOLDOWN_OVER:
			return players
		
	}
	
	return players
}


function updateRound(game, nextState) {
    if (game.get('state') === STATE_PLAY && nextState === STATE_ROUNDOVER) {
        return game.get('round') + 1
    }
    
    return game.get('round')
    
}


function updateSequence(game, nextState) {
    const sequence = game.get('sequence'),
          state = game.get('state')
          
    if (state !== STATE_PLAY && nextState === STATE_PLAY) {
        return 0
    } else if (nextState === STATE_PLAY) {
        return sequence + 1
    }
    
    return sequence
}


function updatePlayer(delta, gamearea, serverSequence, opponents, player) {
    if (!player.get('alive')) {
        return player
    }
        
    const nextPlayer = move(delta, serverSequence, player),
    
          position = nextPlayer.get('path').first(),
        
          paths = collisionPaths(nextPlayer, opponents),
    
          hs = paths.some(path => {
              return hitSnake(path, position)
          }),
          
          hw = hitWall(position, gamearea)
          
    if (hs || hw) {
        // console.log('im ded',  player.get('path').toJS())
        return nextPlayer.set('alive', false)
    }
    
    return nextPlayer
}

function awardWinner(opponents, player) {
    if (!player.get('alive')) {
        return player
    }
    
    const winner = opponents.filter(p => { 
                        return p.get('alive') === true 
                    }).count() < 1
          
    if (winner) {
        // console.log('i won',  player.get('path').toJS())
        return player.set('alive', false)
                     .set('score', player.get('score') + 1)                    
    }
    
    return player
}


function move(delta, serverSequence, player) {
    const direction = player.get('direction')
    let angle = player.get('angle')
    if (direction === LEFT) {
        angle = angle + MAX_ANGLE_CHANGE
    } else if (direction === RIGHT) {
        angle = angle + -MAX_ANGLE_CHANGE
    }
    
    // console.log('serverSequence: ' + serverSequence + ' playerSequence:' + player.get('sequence'))
    // console.log('serverSequence - playerSequence: ' + (serverSequence - player.get('sequence')))
    
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
                 .set('latestPositions', player.get('latestPositions').unshift(nextPosition))
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
                  ...p,
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
    
    const width = gamearea.get(0),
          height = gamearea.get(1)
    
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
                 .set('latestPositions', path)
                 .set('alive', true)
                 .set('sequence', 0)
}


function randomAngle() {
    const angle = Math.floor(Math.random() * 360) + 0
    return angle
}


function randomPosition(gamearea) {
    const width = gamearea.get(0) - SAFETY_MARGIN,
          height = gamearea.get(1) - SAFETY_MARGIN,
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
