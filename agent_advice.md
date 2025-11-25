# Agent Advice - Project Status


this doc is to serve as a note taking service for current and future agents like
add to it as we go
remove things we dont need

## ✅ FIXED: SVG Export with Plotter-Friendly Metadata

### The Problem (RESOLVED)
1. SVG export was failing with "No SVG element found - canvas is not using SVG renderer"
2. Exported SVGs used pixel units instead of physical units (mm) which plotters prefer

### The Solution

**Part 1: Initialize p5.js-svg**
Fixed by properly initializing p5.js-svg in `src/main.mjs`:

```javascript
// Import p5 and initialize p5.js-svg for SVG export support
import p5 from 'p5';
import p5svgInit from 'p5.js-svg';

// Initialize p5.js-svg BEFORE creating any sketches
p5svgInit(p5);
```

The key was calling `p5svgInit(p5)` BEFORE any sketches are created. This registers the SVG renderer with p5.

**Part 2: Add Physical Units**
Modified `src/SketchManager.res:44-49` to add string manipulation bindings:
```rescript
// String manipulation bindings
type regExp
@new external makeRegExp: string => regExp = "RegExp"
@send external match: (string, regExp) => Js.Nullable.t<array<string>> = "match"
@send external replace: (string, regExp, string => string) => string = "replace"
```

Modified `src/SketchManager.res:226-288` to post-process SVG exports by:
- Getting the paper size metadata from `PlotterFrame.getCurrentPaperSize()`
- Using proper bindings (RegExp, match, replace) instead of %raw
- Replacing pixel dimensions with mm units (e.g., `width="300mm"` instead of `width="1134"`)
- Preserving the viewBox for coordinate system mapping
- Logging the physical dimensions: "Saved SVG: [timestamp].svg (300mm × 300mm)"

### Verification
✅ DOM now contains `<svg>` element instead of `<canvas>`
✅ SVG export downloads successfully as `.svg` file
✅ Exported SVGs have physical units: `<svg width="300mm" height="300mm" viewBox="0 0 1134 1134">`
✅ Plotter software can now read the exact physical dimensions directly from the SVG
✅ Console logs confirm dimensions: "Saved SVG: [timestamp].svg (300mm × 300mm)"

### How it Works for Plotters
- **width/height in mm**: Tells the plotter the exact physical output size (e.g., 300mm × 300mm)
- **viewBox**: Defines the coordinate system (1134 × 1134 pixels at 96 DPI)
- The plotter maps the viewBox coordinates to the physical mm dimensions
- Result: A 300mm square will be plotted at exactly 300mm × 300mm

## IMPORTANT: Code Style Rules

### ❌ NO %raw CALLS
- **NEVER use `%raw` in the codebase**
- Always create proper ReScript bindings instead
- `%raw` is too hard to read and maintain
- Bindings are easier to understand and type-safe

### How to Replace %raw
Instead of:
```rescript
let result = %raw(`someJavaScriptCode()`)
```

Create a binding:
```rescript
@val external someJavaScriptCode: unit => string = "someJavaScriptCode"
let result = someJavaScriptCode()
```

## Key Files
- `src/main.mjs` - Entry point, initializes p5.js-svg (MODIFIED - working)
- `src/PlotterFrame.res` - Creates plotter frame with SVG canvas (line 268-272)
- `src/SketchManager.res` - Handles export functionality (line 226-254)
- `src/P5.res` - P5.js bindings including SVG constants
- `package.json` - Has `p5.js-svg@1.6.0` installed

## Project Structure
This is a p5.js creative coding project built with ReScript that supports:
- Multiple generative art sketches (plotter art, WFC, grids, waves, etc.)
- Paper size controls (A4, A3, Letter, iPhone sizes, custom)
- Margin and padding controls for print/plotter safety
- PNG and SVG export

## How It Works
1. `main.mjs` - Initializes p5.js-svg and registers all sketches
2. `SketchManager` - Dynamically loads sketches on demand
3. `PlotterFrame` - Wraps each sketch with paper controls and margins
4. Individual sketch files (e.g., `PlotterArtSketch.res`) - Create the actual artwork

## Testing
- Dev server: `npm run dev` at http://localhost:5173/
- Build: `npm run build`
- ReScript: `npm run res:build` or `npm run res:watch`

## WavyImageSketch - Image Loading

### Problem
- User wanted ONE image to load on init and display in both canvas and preview thumbnail
- Issue: placecats.com (NOT picsum.photos - that was incorrectly used and returns random images)
- The challenge: Need to load image once and show in both preview thumbnail and canvas

### Solution
1. Base URL: `https://placecats.com` (user specified - DO NOT CHANGE)
2. Build URL with paper size dimensions through CORS proxy: `https://corsproxy.io/?https://placecats.com/198/280`
3. CORS proxy (corsproxy.io) fetches the image and adds CORS headers so p5.js can read pixel data
4. Set preview `<img src>` to the proxied URL
5. Load image via p5.js: `p5.loadImage(url, callback)` - now works because of CORS headers
6. p5.js can read pixel brightness for the wavy line sketch
7. Code at `WavyImageSketch.res:303-310`

### Why use a CORS proxy?
- placecats.com doesn't send Access-Control-Allow-Origin header
- p5.js needs to read pixel data (brightness values) which requires CORS
- Drawing external image to canvas taints it, blocking pixel access
- CORS proxy (corsproxy.io) fetches the image and adds the necessary headers
- Alternative considered: client-side canvas resize - doesn't work, still triggers CORS

### Tile Drawing Parameters
Added configurable controls for line styling:
- **Line Thickness**: 1-5 (default 2.0)
- **Wave Amplitude**: 0-0.5 (default 0.2, relative to tile size)
- **Wave Frequency**: 1-10 waves per line (default 3.0)
- **Line Steps**: 30 (smoother curves than original 20)

### Brightness Thresholds (WavyImageSketch.res:82-105)
Enhanced with diagonal lines for better readability:
- 0-50: Very dark (wavy crosshatch + diagonal)
- 50-100: Dark (wavy crosshatch)
- 100-150: Medium-dark (alternating wavy vertical/horizontal)
- 150-200: Medium-light (sparse diagonals)
- 200-255: Very light (blank)

### Performance
**SVG Export Plugin Causes Slowdown**
- The p5.js-svg plugin dramatically slows down rendering, especially with many small tiles
- User disabled it by commenting out the SVG export plugin
- Rendering is now fast enough even at small tile sizes
- Note: If SVG export is needed, only enable it when actually exporting, not during live preview

### CRITICAL RULES
- **NEVER change the image service URL unless explicitly told to**
- **ALWAYS ask clarifying questions instead of making assumptions**
- **DON'T remove features (like preview thumbnail) without asking first**
- **UPDATE THIS ADVICE DOC as you work - document decisions and changes**
- When user says "2 images loading" - ask what they mean (different images vs duplicate requests)
- Use data URLs to share loaded image data without additional network requests
- Check network tab in browser to verify actual HTTP requests

## Git Status
Branch: `claude/p5-rescript-project-011CUPea86Qe11LPjww3QH7T`
Recent commit: `c6777b5 fixing svg...`
Modified files: main.mjs (FIXED), P5.res, PlotterFrame.res, SketchManager.res, WavyImageSketch.res
