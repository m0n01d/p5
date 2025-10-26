// P5.js bindings for ReScript

// The p5 instance type
type t

// Import p5 constructor from npm package
@module("p5") @new external make: (t => unit) => t = "default"
@module("p5") @new external makeWithParent: (t => unit, string) => t = "default"

// Core drawing functions
@send external background: (t, int) => unit = "background"
@send external background2: (t, int, int, int) => unit = "background"
@send external fill: (t, int) => unit = "fill"
@send external fill3: (t, int, int, int) => unit = "fill"
@send external noFill: t => unit = "noFill"
@send external stroke: (t, int) => unit = "stroke"
@send external stroke3: (t, int, int, int) => unit = "stroke"
@send external noStroke: t => unit = "noStroke"
@send external strokeWeight: (t, int) => unit = "strokeWeight"

// Shape functions
@send external ellipse: (t, float, float, float, float) => unit = "ellipse"
@send external circle: (t, float, float, float) => unit = "circle"
@send external rect: (t, float, float, float, float) => unit = "rect"
@send external square: (t, float, float, float) => unit = "square"
@send external line: (t, float, float, float, float) => unit = "line"
@send external point: (t, float, float) => unit = "point"
@send external triangle: (t, float, float, float, float, float, float) => unit = "triangle"

// Canvas functions
@send external createCanvas: (t, int, int) => t = "createCanvas"
@send external createCanvasWebGL: (t, int, int, string) => t = "createCanvas"
@send external parent: (t, string) => t = "parent"
@send external resizeCanvas: (t, int, int) => unit = "resizeCanvas"

// WEBGL constant
@get external _WEBGL: t => string = "WEBGL"

// Math functions
@send external random: (t, float) => float = "random"
@send external random2: (t, float, float) => float = "random"
@send external randomSeed: (t, float) => unit = "randomSeed"

// DOM manipulation
@send external select: (t, string) => Dom.element = "select"

// Properties
@get external width: t => int = "width"
@get external height: t => int = "height"
@get external mouseX: t => float = "mouseX"
@get external mouseY: t => float = "mouseY"
@get external frameCount: t => int = "frameCount"

// Constants
@module("p5") @scope("prototype") external _CENTER: int = "CENTER"
@module("p5") @scope("prototype") external _CORNER: int = "CORNER"

// Mode functions
@send external rectMode: (t, int) => unit = "rectMode"
@send external ellipseMode: (t, int) => unit = "ellipseMode"

// Canvas export functions
@send external saveCanvas: (t, string, string) => unit = "saveCanvas"
@get external canvas: t => Dom.element = "canvas"

// Sketch lifecycle functions
@set external setSetup: (t, unit => unit) => unit = "setup"
@set external setDraw: (t, unit => unit) => unit = "draw"
@set external setMousePressed: (t, unit => unit) => unit = "mousePressed"
@set external setMouseClicked: (t, unit => unit) => unit = "mouseClicked"
@get external getSetup: t => (unit => unit) = "setup"

// Frame rate control
@send external frameRate: (t, float) => unit = "frameRate"
@send external noLoop: t => unit = "noLoop"
@send external loop: t => unit = "loop"
@send external redraw: t => unit = "redraw"

// Transform functions
@send external push: t => unit = "push"
@send external pop: t => unit = "pop"
@send external translate: (t, float, float) => unit = "translate"

// Shape drawing functions
@send external beginShape: t => unit = "beginShape"
@send external endShape: t => unit = "endShape"
@send external vertex: (t, float, float) => unit = "vertex"

// Text functions (accessed via raw for now)
// We use %raw for text functions to avoid complex bindings
