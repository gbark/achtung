import {createStore} from 'redux';
import reducer from './game/reducer';

export default function makeStore() {
    return createStore(reducer)
}
