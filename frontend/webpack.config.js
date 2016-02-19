var webpack = require('webpack');

module.exports = {
	entry: [
		'./src/index.js',
		'webpack-hot-middleware/client'
	],
	
	output: {
		path: __dirname + '/../public/',
		filename: 'bundle.js'
	},
	
	resolve: {
		modulesDirectories: ['node_modules'],
		extensions: ['', '.js', '.elm']
	},
	
	module: {
		loaders: [
			{
				test: /\.js$/,
				exclude: /node_modules/,
				loader: 'babel',
				query: {
					presets: ['es2015']
				}
			},
			{
				test: /\.elm$/,
				exclude: [/elm-stuff/, /node_modules/],
				loader: 'elm-webpack'
			}
		],
		
		noParse: /\.elm$/
	},
	
	plugins: [
		new webpack.optimize.OccurenceOrderPlugin(),
		new webpack.HotModuleReplacementPlugin()
	]
};