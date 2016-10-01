import Server from 'socket.io'

import { addPlayer
       , removePlayer
       , setDirection
       , setRoundTripTime
       } from './game/action_creators'

const PORT = 9000


export function startServer(store) {
    const io = new Server().attach(PORT)
    console.log('-- socket.io: server started on port ', PORT)

    io.on('connection', (socket) => {
        console.log('-- socket.io: client connected. id: ', socket.client.id)

        socket
            .on('playerOutput', (data) => {
                store.dispatch(setDirection(data.direction, socket.client.id, data.sequence))
            })
            .on('disconnect', () => {
                console.log('-- socket.io: client disconnected. id: ', socket.client.id)

                store.dispatch(removePlayer(socket.client.id))
            })
            .on('ho', () => {
                store.dispatch(setRoundTripTime(socket.client.id, Date.now() - startTime))
            })

        socket.emit('playerId', socket.client.id)

        store.dispatch(addPlayer(socket.client.id))
        detectRoundTripTime(io)
    })

    return io
}


let startTime = Date.now()
export function detectRoundTripTime(io) {
    startTime = Date.now()
    io.emit('hey')
}
