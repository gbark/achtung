const store = {}

export function pub(topic, data) {
    if (store[topic]) {
        store[topic].data = data

        for (let subscriber of store[topic].subscribers) {
            subscriber(store[topic].data)
        }
    }
}

export function sub(topic, cb) {
    let id = 0

    if (store[topic]) {
        id = store[topic].subscribers ? store[topic].subscribers.length : id
        store[topic].subscribers.push(cb)
    } else {
        store[topic] = {
            subscribers: [cb]
        }
    }

    return {
        unsub: unsub.bind(undefined, id, topic)
    }
}

function unsub(id, topic) {
    if (store[topic]) {
        store[topic].subscribers.splice(id, 1)
    }
}




let subscription = sub('asd', function (data) {
    console.log('asd was published', data)
})

pub('asd', 'hello')

subscription.unsub()