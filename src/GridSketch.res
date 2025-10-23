// Grid Sketch - tiles shapes across the paper
// Uses the PlotterFrame for UI and settings

// DOM bindings for controls
@val @scope("document")
external getElementById: string => Js.Nullable.t<Dom.element> = "getElementById"

@val @scope("document")
external createElement: string => Dom.element = "createElement"

@get external value: Dom.element => string = "value"
@set external setValue: (Dom.element, string) => unit = "value"
@set external setTextContent: (Dom.element, string) => unit = "textContent"
@set external setClassName: (Dom.element, string) => unit = "className"
@set external setInnerHTML: (Dom.element, string) => unit = "innerHTML"
@send external setAttribute: (Dom.element, string, string) => unit = "setAttribute"
@send external appendChild: (Dom.element, Dom.element) => unit = "appendChild"
@send
external addEventListener: (Dom.element, string, unit => unit) => unit = "addEventListener"

// State for grid controls
type gridState = {
  shapeType: int,
  shapeSize: float,
}

let state = ref({
  shapeType: 4, // square
  shapeSize: 30.0,
})

// Create controls for this sketch
let createControls = () => {
  let controlsDiv = getElementById("sketch-specific-controls")

  switch controlsDiv->Js.Nullable.toOption {
  | None => Console.log("Sketch-specific controls container not found")
  | Some(container) => {
      // Clear existing controls
      container->setInnerHTML("")
      container->setClassName("controls")

      // Shape type selector
      let shapeLabel = createElement("label")
      shapeLabel->setTextContent("Shape: ")
      shapeLabel->setAttribute("for", "shape-type")
      container->appendChild(shapeLabel)

      let shapeSelect = createElement("select")
      shapeSelect->setAttribute("id", "shape-type")

      let shapes = [
        ("square", "Square", 4),
        ("circle", "Circle", 0),
        ("triangle", "Triangle", 3),
        ("pentagon", "Pentagon", 5),
        ("hexagon", "Hexagon", 6),
        ("octagon", "Octagon", 8),
      ]

      shapes->Array.forEach(((value, label, _)) => {
        let option = createElement("option")
        option->setValue(value)
        option->setTextContent(label)
        shapeSelect->appendChild(option)
      })

      shapeSelect->addEventListener("change", () => {
        let value = shapeSelect->value
        let sides = shapes->Array.find(((v, _, _)) => v == value)->Option.map(((_, _, s)) => s)->Option.getOr(4)
        state := {...state.contents, shapeType: sides}
      })

      container->appendChild(shapeSelect)

      // Shape size input
      let sizeLabel = createElement("label")
      sizeLabel->setTextContent(" Size (px): ")
      sizeLabel->setAttribute("for", "shape-size")
      container->appendChild(sizeLabel)

      let sizeInput = createElement("input")
      sizeInput->setAttribute("type", "number")
      sizeInput->setAttribute("id", "shape-size")
      sizeInput->setValue("30")
      sizeInput->setAttribute("min", "5")
      sizeInput->setAttribute("max", "200")
      sizeInput->setAttribute("step", "1")

      sizeInput->addEventListener("input", () => {
        let value = sizeInput->value->Float.fromString->Option.getOr(30.0)
        state := {...state.contents, shapeSize: value}
      })

      container->appendChild(sizeInput)

      Console.log("Grid controls created")
    }
  }
}

// Draw a polygon with n sides
let drawPolygon = (p: P5.t, x: float, y: float, radius: float, sides: int) => {
  p->P5.noFill
  p->P5.stroke(0)
  p->P5.strokeWeight(1)

  if sides == 0 {
    // Circle
    p->P5.circle(x, y, radius *. 2.0)
  } else {
    // Regular polygon
    let angle = 2.0 *. Js.Math._PI /. float_of_int(sides)

    // Calculate vertices
    let vertices = Array.make(~length=sides, (0.0, 0.0))->Array.mapWithIndex((_, i) => {
      let a = float_of_int(i) *. angle -. Js.Math._PI /. 2.0
      let vx = x +. Js.Math.cos(a) *. radius
      let vy = y +. Js.Math.sin(a) *. radius
      (vx, vy)
    })

    // Draw the polygon using beginShape/endShape
    %raw(`(function(p) { p.beginShape(); })`)(p)
    vertices->Array.forEach(((vx, vy)) => {
      %raw(`(function(p, vx, vy) { p.vertex(vx, vy); })`)(p, vx, vy)
    })
    %raw(`(function(p) { p.endShape(p.CLOSE); })`)(p)
  }
}

// Main draw function
let draw = (p: P5.t, paperSize: PlotterFrame.paperSize) => {
  // Get shape parameters from state
  let sides = state.contents.shapeType
  let shapeSize = state.contents.shapeSize

  // Calculate grid layout
  let margin = 20.0
  let availableWidth = paperSize.width->Int.toFloat -. margin *. 2.0
  let availableHeight = paperSize.height->Int.toFloat -. margin *. 2.0

  // Number of shapes that fit
  let numCols = (availableWidth /. shapeSize)->Float.toInt
  let numRows = (availableHeight /. shapeSize)->Float.toInt

  // Calculate actual spacing to center the grid
  let actualWidth = float_of_int(numCols) *. shapeSize
  let actualHeight = float_of_int(numRows) *. shapeSize
  let startX = (paperSize.width->Int.toFloat -. actualWidth) /. 2.0
  let startY = (paperSize.height->Int.toFloat -. actualHeight) /. 2.0

  // Draw the grid
  for row in 0 to numRows - 1 {
    for col in 0 to numCols - 1 {
      let x = startX +. float_of_int(col) *. shapeSize +. shapeSize /. 2.0
      let y = startY +. float_of_int(row) *. shapeSize +. shapeSize /. 2.0
      let radius = shapeSize /. 2.0

      drawPolygon(p, x, y, radius, sides)
    }
  }

  // Draw info text in bottom margin
  p->P5.noStroke
  p->P5.fill(0)
  let shapeName = switch sides {
  | 0 => "circles"
  | 3 => "triangles"
  | 4 => "squares"
  | 5 => "pentagons"
  | 6 => "hexagons"
  | 8 => "octagons"
  | _ => "shapes"
  }

  let info = `${numCols->Int.toString} × ${numRows->Int.toString} ${shapeName} (${shapeSize->Float.toString}px each)`
  %raw(`(function(p) { p.textSize(10); })`)(p)
  %raw(`(function(p) { p.textAlign(p.CENTER); })`)(p)
  %raw(`(function(p, info) { p.text(info, p.width / 2, p.height - 5); })`)(p, info)
}

// Create the sketch - initialize controls when sketch loads
let createSketch = () => {
  createControls()
  PlotterFrame.createPlotterSketch(draw)()
}
