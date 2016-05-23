// Register babel for runtime transpilation
require("babel-core/register")({
  plugins: [
    "transform-es2015-modules-commonjs",
    "transform-object-rest-spread"
  ]
})

// Run actual code
require('./main')
