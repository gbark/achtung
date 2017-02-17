import deepFreeze from 'deep-freeze'
import { fromJS } from 'immutable'

export function testReducer(t, reducer, initial, action, expected) {
    action && deepFreeze(action)
    initial = fromJS(initial)

    return t.deepEqual(reducer(initial, action).toJS(), expected)
}
