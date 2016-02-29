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

        store.dispatch(addPlayer(id), store.getState().get('state'))

        socket.on('playerOutput', (data) => {
            store.dispatch(setDirection(data.direction, id, store.getState().get('state')))
            // console.log('-- socket.io: playerOutput', data.direction)
            // add incoming playerOutput to store 
            // for later processing in game loop 
        })

        socket.on('disconnect', () => {
            console.log('-- socket.io: client disconnected. id: ', id)

            store.dispatch(removePlayer(id), store.getState().get('state'))
        })
    })
    
    return io
}
