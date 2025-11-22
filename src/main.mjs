// Entry point for Vite bundler
console.log('Initializing sketches with lazy loading...');

// Import Tailwind CSS
import './style.css';

// Import p5 and initialize p5.js-svg for SVG export support
import p5 from 'p5';
import p5svgInit from 'p5.js-svg';

// Initialize p5.js-svg BEFORE creating any sketches
p5svgInit(p5);
console.log('p5.js-svg initialized');

// Import only the sketch manager
import { registerSketch, init } from './SketchManager.res.mjs';

// Register sketches with their import paths (they'll be loaded on demand)
registerSketch('Plotter Art - Circles', './PlotterArtSketch.res.mjs');
registerSketch('Wave Function Collapse - Lines', './WFCPlotterSketch.res.mjs');
registerSketch('Wave Function Collapse - Pipes', './WFCPipesSketch.res.mjs');
registerSketch('Wave Function Collapse - Wood Grain', './WFCWoodGrainSketch.res.mjs');
registerSketch('Grid - Tiled Shapes', './GridSketch.res.mjs');
registerSketch('Wavy Lines - Center Focus', './WavyLinesSketch.res.mjs');
registerSketch('Tiling Pattern', './TilingSketch.res.mjs');
registerSketch('Wavy Image Halftone', './WavyImageSketch.res.mjs');

// Initialize the sketch manager
init();

console.log('Sketch manager ready - sketches will load on demand');
