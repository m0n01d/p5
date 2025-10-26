// Tiling Sketch - repeating pattern for printing

// Tile size in pixels
let tileSize = 50.0

// Draw a single tile at position (x, y)
let rec drawTile = (p: P5.t, x: float, y: float, size: float, l: int) => {
  Console.log(l)

  // Random 0 or 1: 0 = vertical, 1 = horizontal
  if l == 0 {
    let orientation = p->P5.random2(0.0, 2.0)->Float.toInt

    let centerX = x +. size /. 2.0
    let centerY = y +. size /. 2.0
    let lineLength = size *. 0.5

    p->P5.stroke(0)
    p->P5.strokeWeight(1)

    if orientation == 0 {
      // Vertical line
      let lineTop = centerY -. lineLength /. 2.0
      let lineBottom = centerY +. lineLength /. 2.0
      p->P5.line(centerX, lineTop, centerX, lineBottom)
    } else {
      // Horizontal line
      let lineLeft = centerX -. lineLength /. 2.0
      let lineRight = centerX +. lineLength /. 2.0
      p->P5.line(lineLeft, centerY, lineRight, centerY)
    }
  } else {
    let s = size /. 2.0
    let nextlevel = l - 1
    // Top-left quadrant
    drawTile(p, x, y, s, nextlevel)
    // Top-right quadrant
    drawTile(p, x +. s, y, s, nextlevel)
    // Bottom-left quadrant
    drawTile(p, x, y +. s, s, nextlevel)
    // Bottom-right quadrant
    drawTile(p, x +. s, y +. s, s, nextlevel)
  }
}

// Recursively tile the canvas
// Track if we've drawn once
let hasDrawn = ref(false)

let draw = (p: P5.t, paper: PlotterFrame.paperSize) => {
  if !hasDrawn.contents {
    let paperWidth = paper.width->Int.toFloat
    let paperHeight = paper.height->Int.toFloat
    // Use the smaller dimension to make a square tiling
    let size = paperWidth < paperHeight ? paperWidth : paperHeight
    drawTile(p, 0.0, 0.0, size, 1)

    // Fill entire canvas with tiles

    // Stop the loop after first draw
    p->P5.noLoop
    hasDrawn := true
  }
}

// Create the sketch
let createSketch = PlotterFrame.createPlotterSketch(draw)
