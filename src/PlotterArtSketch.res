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

  // Draw animated line art based on mouse position
  if p->P5.mouseX > 0.0 && p->P5.mouseY > 0.0 {
    p->P5.stroke3(100, 150, 255)
    p->P5.strokeWeight(1)
    p->P5.line(centerX, centerY, p->P5.mouseX, p->P5.mouseY)
    p->P5.circle(p->P5.mouseX, p->P5.mouseY, 20.0)
  }
}

// Create the sketch using the plotter frame
let createSketch = PlotterFrame.createPlotterSketch(draw)
