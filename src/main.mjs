// Entry point for Vite bundler
// Import p5 from node_modules and make it global before importing sketch
import p5 from 'p5';

// Make p5 available globally so our ReScript sketch can use it
window.p5 = p5;
globalThis.p5 = p5;

console.log('p5 loaded, initializing sketch...');

// Now import the sketch (which will execute and create the p5 instance)
import './Sketch.res.mjs';
