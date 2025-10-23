# P5.js + ReScript Project

A creative coding project using p5.js with ReScript, featuring type-safe bindings and functional programming patterns.

## Features

- **Type-Safe P5.js Bindings**: ReScript bindings for p5.js API
- **Latest ReScript**: Built with ReScript 11.1.4
- **ES Modules**: Modern JavaScript module system
- **Interactive Demo**: Animated circles with mouse interaction

## Prerequisites

- Node.js (v14 or higher)
- npm or yarn

## Installation

```bash
npm install
```

## Development

### Build the Project

Compile ReScript code to JavaScript:

```bash
npm run build
```

### Watch Mode

Automatically rebuild on file changes:

```bash
npm run dev
```

### Clean Build Artifacts

```bash
npm run clean
```

## Running the Project

1. Build the project: `npm run build`
2. Open `index.html` in a web browser
3. For local development, use a local server:
   ```bash
   # Using Python 3
   python -m http.server 8000

   # Using Node.js http-server
   npx http-server
   ```
4. Navigate to `http://localhost:8000` in your browser

## Project Structure

```
.
├── src/
│   ├── P5.res           # P5.js bindings for ReScript
│   ├── Sketch.res       # Main sketch code
│   └── *.res.js         # Generated JavaScript files
├── index.html           # HTML entry point
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
