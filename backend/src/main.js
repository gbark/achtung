import startServer from './server';
import makeStore from './store';

const store = makeStore()

startServer(store);
