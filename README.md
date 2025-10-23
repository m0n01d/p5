# P5.js + ReScript Pen Plotter

A pen plotter simulation project using p5.js with ReScript, featuring type-safe bindings and functional programming patterns.

## Features

- **Type-Safe P5.js Bindings**: ReScript bindings for p5.js API
- **Latest ReScript**: Built with ReScript 11.1.4
- **ES Modules**: Modern JavaScript module system
- **Paper Size Selector**: Choose from common plotter paper sizes (A3, A4, A5, Letter, Legal, Tabloid, Square)
- **Custom Paper Sizes**: Define your own canvas dimensions in millimeters
- **Export to PNG/SVG**: Download your artwork at precise page dimensions
- **Interactive Drawing**: Real-time mouse interaction with concentric circle patterns
- **Pen Plotter Simulation**: White canvas with black line art mimicking pen plotter output

## Prerequisites

- Node.js (v14 or higher)
- npm or yarn

## Installation

```bash
npm install
```

## Development

### Quick Start

Start the development server with hot reload:

```bash
npm run dev
```

This will:
- Start a local server at `http://localhost:3000`
- Watch for ReScript file changes and auto-compile
- Automatically reload the browser when files change

### Other Commands

Build the project once:

```bash
npm run build
```

Watch mode only (no server):

```bash
npm run watch
```

Clean build artifacts:

```bash
npm run clean
```

## Paper Sizes

The application supports the following paper sizes:

- **A3**: 297 × 420 mm (1123 × 1587 px)
- **A4**: 210 × 297 mm (794 × 1123 px) - Default
- **A5**: 148 × 210 mm (559 × 794 px)
- **Letter**: 8.5 × 11 in (816 × 1056 px)
- **Legal**: 8.5 × 14 in (816 × 1344 px)
- **Tabloid**: 11 × 17 in (1056 × 1632 px)
- **Square**: 300 × 300 mm (1134 × 1134 px)
- **Custom**: Define your own dimensions (10-2000 mm)

Pixel dimensions are calculated at 96 DPI for screen display.

## Export Functionality

### PNG Export
- Exports the canvas as a high-quality PNG image
- Maintains the selected paper size dimensions
- Perfect for digital display or printing

### SVG Export
- Generates a vector SVG file with exact millimeter dimensions
- Includes `width` and `height` attributes in mm for accurate scaling
- Ideal for pen plotters and vector graphics software
- The SVG maintains proper aspect ratio and can be scaled infinitely

### How to Export

1. Select your desired paper size from the dropdown (or use Custom)
2. Choose the export format (PNG or SVG)
3. Click the "Download" button
4. The file will be saved as `plotter-art.png` or `plotter-art.svg`

### Custom Paper Sizes

1. Select "Custom Size" from the paper size dropdown
2. Enter your desired width and height in millimeters
3. Click "Apply" to resize the canvas
4. Create your artwork
5. Export using the format of your choice

## Project Structure

```
.
├── src/
│   ├── P5.res           # P5.js bindings for ReScript
│   ├── Sketch.res       # Main sketch code (pen plotter simulation)
│   └── *.res.js         # Generated JavaScript files
├── index.html           # HTML entry point with paper size controls
├── package.json         # Project dependencies
├── rescript.json        # ReScript configuration
└── README.md           # This file
```

## Extending the Bindings

The `P5.res` file contains ReScript bindings for common p5.js functions. To add more p5.js functions:

1. Open `src/P5.res`
2. Add external bindings using ReScript's `@send`, `@get`, etc. decorators
3. Rebuild the project

Example:
```rescript
@send external text: (t, string, float, float) => unit = "text"
```

## Resources

- [ReScript Documentation](https://rescript-lang.org/)
- [P5.js Reference](https://p5js.org/reference/)
- [P5.js Learn](https://p5js.org/learn/)

## License

MIT
