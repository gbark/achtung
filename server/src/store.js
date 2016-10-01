import {createStore} from 'redux';
import reducer from './game/reducer';

export default () => createStore(reducer)
