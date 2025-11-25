// Entry point for Vite bundler
console.log("Initializing sketches with lazy loading...");

// Import Tailwind CSS
import "./style.css";

// Import p5 and initialize p5.js-svg for SVG export support
import p5 from "p5";
// import p5svgInit from 'p5.js-svg';

// Initialize p5.js-svg BEFORE creating any sketches
// p5svgInit(p5);
// console.log('p5.js-svg initialized');

// Import only the sketch manager
import { registerSketch, init } from "./SketchManager.res.mjs";

// Create a map of sketch loaders (actual import functions)
const sketchLoaders = {
  "Plotter Art - Circles": () => import("./PlotterArtSketch.res.mjs"),
  "Wave Function Collapse - Lines": () => import("./WFCPlotterSketch.res.mjs"),
  "Wave Function Collapse - Pipes": () => import("./WFCPipesSketch.res.mjs"),
  "Wave Function Collapse - Wood Grain": () => import("./WFCWoodGrainSketch.res.mjs"),
  "Grid - Tiled Shapes": () => import("./GridSketch.res.mjs"),
  "Wavy Lines - Center Focus": () => import("./WavyLinesSketch.res.mjs"),
  "Tiling Pattern": () => import("./TilingSketch.res.mjs"),
  "Wavy Image Halftone": () => import("./WavyImageSketch.res.mjs"),
};

// Register sketches with loader functions
Object.keys(sketchLoaders).forEach(name => {
  registerSketch(name, sketchLoaders[name]);
});

// Initialize the sketch manager
init();

console.log("Sketch manager ready - sketches will load on demand");
