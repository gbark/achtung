import Server from 'socket.io'

import { addPlayer
       , removePlayer
       , setDirection
       } from './game/action_creators'

const PORT = 9000

export default function startServer(store) {
    const io = new Server().attach(PORT)
    console.log('-- socket.io: server started on port ', PORT)

    io.on('connection', (socket) => {
        const id = socket.client.id
        console.log('-- socket.io: client connected. id: ', id)
        
        socket.emit('playerId', socket.client.id)

        store.dispatch(addPlayer(id))

        socket.on('playerOutput', (data) => {
            store.dispatch(setDirection(data.direction, id))
        })

        socket.on('disconnect', () => {
            console.log('-- socket.io: client disconnected. id: ', id)

            store.dispatch(removePlayer(id))
        })
    })
    
    return io
}
