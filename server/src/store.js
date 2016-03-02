import {applyMiddleware, createStore} from 'redux';
import {Map} from 'immutable';

import reducer from './game/reducer';

export default function makeStore() {
    return createStore(reducer, Map());
}
