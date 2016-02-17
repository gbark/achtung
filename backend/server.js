import Server from 'socket.io'

const PORT = 9000

export default function startServer(store) {
    const io = new Server().attach(PORT)
    console.log('-- socket.io: server started on port ', PORT)

    let store = {};

    io.on('connection', (socket) => {
        console.log('-- socket.io: client connected. id: ', socket.client.id)

        socket.emit('connected', { id: socket.client.id })

        socket.on('updateState', (data) => {
            console.log('-- socket.io: update state')
            store = data;

            console.log('-- socket.io: emitted state')
            socket.emit('state', store)
        })

        socket.on('disconnect', () => {
            console.log('-- socket.io: client disconnected. id: ', socket.client.id)
        })
    })
}
