var express = require('express');
var path = require('path');
var webpack = require('webpack');
var webpackConfig = require('./webpack.config');


var app = express();
var port = 3000;


var compiler = webpack(webpackConfig);
app.use(require("webpack-dev-middleware")(compiler, {
    noInfo: true, 
	publicPath: webpackConfig.output.publicPath
}));
app.use(require("webpack-hot-middleware")(compiler));


app.use('/', express.static(path.resolve(__dirname, '..', 'public')));
app.listen(port);


console.log('Dev server listening on port', port);