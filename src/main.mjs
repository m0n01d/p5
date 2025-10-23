// Entry point for Vite bundler
console.log('Initializing sketches...');

// Import all sketches
import { createSketch as createPlotterSketch } from './Sketch.res.mjs';
import { createSketch as createWFCSketch } from './WFCSketch.res.mjs';
import { registerSketch, init } from './SketchManager.res.mjs';

// Register all available sketches
registerSketch('Plotter Art', createPlotterSketch);
registerSketch('Wave Function Collapse', createWFCSketch);

// Initialize the sketch manager
init();
