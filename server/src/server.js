import { Server as WebSocketServer } from 'uws'
import { v4 as uuid } from 'uuid'

import { addPlayer
       , removePlayer
       , setDirection
       , setRoundTripTime
       } from './game/action_creators'

const HOST = 'localhost'
const PORT = 9000

export const WS_TOPIC = {
    PINGPONG: 'p',
    PLAYER_OUTPUT: 'o',
    PLAYER_ID: 'i',
    GAME_STATE: 's'
}

export function startServer(store) {
    const wss = new WebSocketServer({
        host: HOST,
        port: PORT,
        clientTracking: true,
        perMessageDeflate: false
    })

    console.log(`-- web socket: server started. listening on port ${PORT.toString()}`)


    wss.on('connection', (ws) => {
        ws.id = uuid()
        console.info(`-- web socket: client connected. id: ${ws.id}`)

        ws.on('message', string => {
            const { topic, data } = decode(string)

            switch (topic) {
                case WS_TOPIC.PLAYER_OUTPUT:
                    store.dispatch(setDirection(data.direction, ws.id, data.sequence))
                    break;
                case WS_TOPIC.PINGPONG:
                    console.log(`round trip time ${Date.now() - data}`)
                    store.dispatch(setRoundTripTime(ws.id, Date.now() - data))
                    break;

                default:
                    break;
            }
        })

        ws.on('unexpected-response', () => {
            console.log(`unexpected response from ${ws.id}`)
        })
        ws.on('error', () => {
            console.log(`websocket error from ${ws.id}`)
        })
        ws.on('close', req => {
            console.info(`-- web socket: client disconnected. id: ${ws.id}`)
            store.dispatch(removePlayer(ws.id))
        })

        store.dispatch(addPlayer(ws.id))
        ws.send(encode(WS_TOPIC.PLAYER_ID, ws.id))

        // @todo - boot non responding clients
    })

    return wss
}

export function sendToId(wss, id, topic, data) {
    let sent = false
    wss.clients.forEach(c => {
        if (c.id === id) {
            c.send(encode(topic, data))
            sent = true
        }
    })

    return sent
}

export function encode(topic, data) {
    if (typeof topic !== 'string' || topic.length !== 1) {
        throw new Error('Subprotocol Error - Topic invalid')
    }
    return topic + (typeof data === 'string' ? data : JSON.stringify(data))
}

export function decode(string) {
    const topic = string.charAt(0),
        data = string.slice(1, string.length),
        needsParsing = data.charAt(0) === '"' || data.charAt(0) === '{'

    return {
        topic,
        data: needsParsing ? JSON.parse(data) : data
    }
}