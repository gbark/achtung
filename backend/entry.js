// Register babel for runtime transpilation
require('babel-core/register')({
  "presets": ["es2015", "stage-0"]
});

// Run actual code
require('./main');
