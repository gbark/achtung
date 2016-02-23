import Server from 'socket.io'

const PORT = 9000

export default function startServer(store) {
    const io = new Server().attach(PORT)
    console.log('-- socket.io: server started on port ', PORT)

    io.on('connection', (socket) => {
        console.log('-- socket.io: client connected. id: ', socket.client.id)

        socket.emit('connected', { id: socket.client.id })

        socket.on('playerOutput', (data) => {
            console.log('-- socket.io: playerOutput', data)
            store = data;
        })

        socket.on('disconnect', () => {
            console.log('-- socket.io: client disconnected. id: ', socket.client.id)
        })
    })
}
