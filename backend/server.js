import Server from 'socket.io'

const PORT = 9000

export default function startServer() {
    const io = new Server().attach(PORT)
    console.log('-- socket.io: server started on port ', PORT)

    io.on('connection', (socket) => {
        console.log('-- socket.io: client connected. id: ', socket.client.id)

        socket.emit('hello')

        socket.on('ping', () => {
            socket.emit('pong')
        })

        socket.on('disconnect', () => {
            console.log('-- socket.io: client disconnected. id: ', socket.client.id)
        })
    })
}