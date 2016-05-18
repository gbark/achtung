import Server from 'socket.io'

import { addPlayer
       , removePlayer
       , addInput
       , setRoundTripTime
       } from './game/action_creators'

const PORT = 9000

let colors = [
    'yellow',
    'red',
    'blue',
    'green',
    'purple',
    'orange',
    'white',
    'brown',
    'grey'
]

export function startServer(store) {
    const io = new Server().attach(PORT)
    console.log('-- socket.io: server started on port ', PORT)

    io.on('connection', (socket) => {
        const id = socket.client.id
        console.log('-- socket.io: client connected. id: ', id)
        
        socket
            .on('playerOutput', (data) => {
                store.dispatch(addInput(data.direction, id, data.sequence))
            })
            .on('disconnect', () => {
                console.log('-- socket.io: client disconnected. id: ', id)

                store.dispatch(removePlayer(id))
            })
            .on('ho', () => {
                store.dispatch(setRoundTripTime(id, Date.now() - startTime))
            })
            
        socket.emit('playerId', socket.client.id)
            
        store.dispatch(addPlayer(id, colors.shift()))
        detectRoundTripTime(io)
    })
    
    return io
}


let startTime = Date.now()
export function detectRoundTripTime(io) {
    startTime = Date.now()
    io.emit('hey')
} 
