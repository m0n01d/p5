# Sketch System

This project uses a sketch management system built entirely in ReScript that allows you to create multiple p5.js sketches and swap between them cleanly.

## How It Works

The `SketchManager` module handles the complete lifecycle of sketches:

1. **Registration**: Sketches are registered with a name and creation function
2. **State Management**: Maintains current sketch instance and list of available sketches
3. **Clean Transitions**: When switching sketches:
   - Calls `p5.remove()` on the current instance
   - Clears the DOM container with `innerHTML = ""`
   - Creates new p5 instance
   - Attaches to the container
   - Updates state

## Creating a New Sketch

1. Create a new `.res` file (e.g., `MySketch.res`)
2. Export a `createSketch` function:

```rescript
let createSketch = () => {
  (p: P5.t) => {
    p->P5.setSetup(() => {
      p->P5.createCanvas(800, 600)->ignore
    })

    p->P5.setDraw(() => {
      p->P5.background(255)
      // Your drawing code
    })
  }
}
```

3. Register it in `main.mjs`:

```javascript
import { createSketch as mySketch } from './MySketch.res.mjs';
registerSketch('My Sketch', mySketch);
```

## Current Sketches

### Plotter Art
A generative art sketch with:
- Concentric circles
- Mouse interaction
- Paper size controls
- SVG/PNG export

### Wave Function Collapse
A simple tile-based WFC implementation:
- 10x10 grid
- 4 tile types (blank, horizontal, vertical, cross)
- Adjacency constraints
- Step-by-step visualization
- Click to restart

## Controls

- **← Previous / Next →**: Switch between sketches
- **Arrow Keys**: (Planned) Navigate with keyboard
- The sketch name is displayed in the center

## Architecture

The system is built with:
- **ReScript**: Type-safe functional programming
- **p5.js**: Creative coding framework
- **Vite**: Fast bundler
- **Pure Functions**: Each sketch is created fresh on demand
- **Immutable State**: State transitions are explicit and predictable
