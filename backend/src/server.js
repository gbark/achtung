import Server from 'socket.io'

import { addPlayer
       , removePlayer
       } from './game/modules/players'

const PORT = 9000

export default function startServer(store) {
    const io = new Server().attach(PORT)
    console.log('-- socket.io: server started on port ', PORT)

    io.on('connection', (socket) => {
        console.log('-- socket.io: client connected. id: ', socket.client.id)

        store.dispatch(addPlayer(socket.client.id))
        console.log('current state ', store.getState().toJS(), null, 2)

        socket.on('playerOutput', (data) => {
            // console.log('-- socket.io: playerOutput', data)
            // add incoming playerOutput to store 
            // for later processing in game loop 
        })

        socket.on('disconnect', () => {
            console.log('-- socket.io: client disconnected. id: ', socket.client.id)

            store.dispatch(removePlayer(socket.client.id))
        })
    })
}
