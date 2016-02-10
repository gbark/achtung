// Get babel config and register babel for runtime transpilation
var fs = require('fs');
var babelrc = fs.readFileSync('.babelrc');
require('babel-core/register')(JSON.parse(babelrc));

// Run actual code
require('./main');
