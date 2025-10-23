// Entry point for Vite bundler
// The sketch will import p5 directly from node_modules via P5.res bindings
console.log('Initializing sketch...');

// Import the sketch (which will import p5 and create the p5 instance)
import './Sketch.res.mjs';
