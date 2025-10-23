// Entry point for Vite bundler
console.log('Initializing sketches...');

// Import all sketches
import { createSketch as createPlotterArtSketch } from './PlotterArtSketch.res.mjs';
import { createSketch as createWFCPlotterSketch } from './WFCPlotterSketch.res.mjs';
import { createSketch as createGridSketch } from './GridSketch.res.mjs';
import { registerSketch, init } from './SketchManager.res.mjs';

// Register all available sketches
registerSketch('Plotter Art - Circles', createPlotterArtSketch);
registerSketch('Wave Function Collapse', createWFCPlotterSketch);
registerSketch('Grid - Tiled Shapes', createGridSketch);

// Initialize the sketch manager
init();
