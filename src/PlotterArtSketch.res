// Plotter Art Sketch - concentric circles
// Uses the PlotterFrame for UI and settings

let draw = (p: P5.t, paperSize: PlotterFrame.paperSize) => {
  // Draw some example plotter art
  p->P5.stroke3(0, 0, 0)
  p->P5.strokeWeight(1)
  p->P5.noFill

  // Draw concentric circles in the center
  let centerX = paperSize.width->Int.toFloat /. 2.0
  let centerY = paperSize.height->Int.toFloat /. 2.0
  let maxRadius = Js.Math.min_float(centerX, centerY) -. 50.0

  let numCircles = 20
  for i in 1 to numCircles {
    let radius = maxRadius *. Int.toFloat(i) /. Int.toFloat(numCircles)
    p->P5.circle(centerX, centerY, radius *. 2.0)
  }

  // Get the current margin + padding offset
  let currentMarginMm = PlotterFrame.currentMarginMm.contents
  let currentPaddingMm = PlotterFrame.currentPaddingMm.contents
  let totalSpacePx = (currentMarginMm +. currentPaddingMm) *. 3.7795275591

  // Adjust mouse coordinates to account for the translate offset
  let adjustedMouseX = p->P5.mouseX -. totalSpacePx
  let adjustedMouseY = p->P5.mouseY -. totalSpacePx

  // Draw animated line art based on mouse position
  if adjustedMouseX > 0.0 && adjustedMouseY > 0.0 &&
     adjustedMouseX < paperSize.width->Int.toFloat &&
     adjustedMouseY < paperSize.height->Int.toFloat {
    p->P5.stroke3(100, 150, 255)
    p->P5.strokeWeight(1)
    p->P5.line(centerX, centerY, adjustedMouseX, adjustedMouseY)
    p->P5.circle(adjustedMouseX, adjustedMouseY, 20.0)
  }
}

// Create the sketch using the plotter frame
let createSketch = PlotterFrame.createPlotterSketch(draw)
