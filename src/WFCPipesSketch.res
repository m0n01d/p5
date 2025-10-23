// WFC Pipes Sketch - Wave Function Collapse with 3D pipe rendering
// Creates connected pipe networks instead of flat lines

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

// State for pipe controls
type pipeState = {
  pipeThickness: float,
  gridSize: int,
  gapSize: float,
  numLayers: int,
  curviness: float,
  stretchiness: float, // How far pipes extend from center (1.0 = normal, >1 = stretched)
}

let state = ref({
  pipeThickness: 12.0,
  gridSize: 8,
  gapSize: 6.0,
  numLayers: 3,
  curviness: 0.5, // How much curves bend (0 = straight, 1 = very curvy)
  stretchiness: 1.0, // Default normal stretch
})

// Copy WFC types from WFCSketch
type direction = Up | Right | Down | Left

type socket = A | B | C

type tile = {
  id: int,
  edges: (socket, socket, socket, socket), // up, right, down, left
  connections: array<direction>,
}

type cell = {
  mutable collapsed: bool,
  mutable options: array<tile>,
}

// Define tile types with connections
let tiles = [
  // Straight pipes
  {id: 0, edges: (A, B, A, B), connections: [Up, Down]}, // vertical
  {id: 1, edges: (B, A, B, A), connections: [Left, Right]}, // horizontal
  // L-shaped corners
  {id: 2, edges: (A, A, B, B), connections: [Down, Right]},
  {id: 3, edges: (A, B, B, A), connections: [Down, Left]},
  {id: 4, edges: (B, A, A, B), connections: [Up, Right]},
  {id: 5, edges: (B, B, A, A), connections: [Up, Left]},
  // T-junctions
  {id: 6, edges: (A, A, A, B), connections: [Up, Down, Right]},
  {id: 7, edges: (A, B, A, A), connections: [Up, Down, Left]},
  {id: 8, edges: (B, A, A, A), connections: [Left, Right, Up]},
  {id: 9, edges: (A, A, B, A), connections: [Left, Right, Down]},
  // Cross
  {id: 10, edges: (A, A, A, A), connections: [Up, Down, Left, Right]},
]

// Create grid
let createGrid = (size: int) => {
  Array.make(~length=size * size, ())->Array.map(_ => {
    collapsed: false,
    options: tiles,
  })
}

// Check if two tiles can connect
let canConnect = (tile1: tile, dir1: direction, tile2: tile, dir2: direction) => {
  let (edge1, edge2) = switch (dir1, dir2) {
  | (Right, Left) => {
      let (_, r, _, _) = tile1.edges
      let (_, _, _, l) = tile2.edges
      (r, l)
    }
  | (Down, Up) => {
      let (_, _, d, _) = tile1.edges
      let (u, _, _, _) = tile2.edges
      (d, u)
    }
  | (Left, Right) => {
      let (_, _, _, l) = tile1.edges
      let (_, r, _, _) = tile2.edges
      (l, r)
    }
  | (Up, Down) => {
      let (u, _, _, _) = tile1.edges
      let (_, _, d, _) = tile2.edges
      (u, d)
    }
  | _ => (A, B) // Should never happen
  }
  edge1 == edge2
}

// Get valid options for a cell based on neighbors
let getValidOptions = (grid: array<cell>, x: int, y: int, gridSize: int) => {
  let index = y * gridSize + x
  let cell = grid[index]

  switch cell {
  | None => []
  | Some(c) =>
    if c.collapsed {
      c.options
    } else {
      c.options->Array.filter(tile => {
        // Check all four neighbors
        let validUp = if y > 0 {
          let neighborIndex = (y - 1) * gridSize + x
          switch grid[neighborIndex] {
          | None => true
          | Some(neighbor) =>
            if neighbor.collapsed {
              neighbor.options->Array.some(nTile => canConnect(tile, Up, nTile, Down))
            } else {
              true
            }
          }
        } else {
          true
        }

        let validRight = if x < gridSize - 1 {
          let neighborIndex = y * gridSize + (x + 1)
          switch grid[neighborIndex] {
          | None => true
          | Some(neighbor) =>
            if neighbor.collapsed {
              neighbor.options->Array.some(nTile => canConnect(tile, Right, nTile, Left))
            } else {
              true
            }
          }
        } else {
          true
        }

        let validDown = if y < gridSize - 1 {
          let neighborIndex = (y + 1) * gridSize + x
          switch grid[neighborIndex] {
          | None => true
          | Some(neighbor) =>
            if neighbor.collapsed {
              neighbor.options->Array.some(nTile => canConnect(tile, Down, nTile, Up))
            } else {
              true
            }
          }
        } else {
          true
        }

        let validLeft = if x > 0 {
          let neighborIndex = y * gridSize + (x - 1)
          switch grid[neighborIndex] {
          | None => true
          | Some(neighbor) =>
            if neighbor.collapsed {
              neighbor.options->Array.some(nTile => canConnect(tile, Left, nTile, Right))
            } else {
              true
            }
          }
        } else {
          true
        }

        validUp && validRight && validDown && validLeft
      })
    }
  }
}

// WFC state with layer info
type wfcState = {
  grid: array<cell>,
  gridSize: int,
  cellSize: float,
  collapsed: bool,
  layers: array<int>, // Layer assignment for each cell
}

let wfcState = ref({
  grid: createGrid(8),
  gridSize: 8,
  cellSize: 0.0,
  collapsed: false,
  layers: Array.make(~length=64, 0),
})

// Regenerate function - resets WFC and restarts loop
let regenerate = () => {
  let totalCells = state.contents.gridSize * state.contents.gridSize
  wfcState := {
      grid: createGrid(state.contents.gridSize),
      gridSize: state.contents.gridSize,
      cellSize: 0.0,
      collapsed: false,
      layers: Array.make(~length=totalCells, 0),
    }
  // Restart drawing loop
  %raw(`(function() {
    const p = window.__currentP5Instance;
    if (p && !p.isLooping()) { p.loop(); }
  })`)()
  Console.log("Regenerating...")
}

// Create controls for this sketch
let createControls = () => {
  let controlsDiv = getElementById("sketch-specific-controls")

  switch controlsDiv->Js.Nullable.toOption {
  | None => Console.log("Sketch-specific controls container not found")
  | Some(container) => {
      container->setInnerHTML("")
      container->setClassName("controls")

      // Grid size control
      let gridLabel = createElement("label")
      gridLabel->setTextContent("Grid Size: ")
      gridLabel->setAttribute("for", "grid-size")
      container->appendChild(gridLabel)

      let gridInput = createElement("input")
      gridInput->setAttribute("type", "number")
      gridInput->setAttribute("id", "grid-size")
      gridInput->setValue("8")
      gridInput->setAttribute("min", "4")
      gridInput->setAttribute("max", "20")
      gridInput->setAttribute("step", "1")

      gridInput->addEventListener("input", () => {
        let value = gridInput->value->Int.fromString->Option.getOr(20)
        state := {...state.contents, gridSize: value}
        regenerate()
      })

      container->appendChild(gridInput)

      // Pipe thickness control
      let thicknessLabel = createElement("label")
      thicknessLabel->setTextContent(" Thickness: ")
      thicknessLabel->setAttribute("for", "pipe-thickness")
      container->appendChild(thicknessLabel)

      let thicknessInput = createElement("input")
      thicknessInput->setAttribute("type", "number")
      thicknessInput->setAttribute("id", "pipe-thickness")
      thicknessInput->setValue("12")
      thicknessInput->setAttribute("min", "4")
      thicknessInput->setAttribute("max", "30")
      thicknessInput->setAttribute("step", "2")

      thicknessInput->addEventListener("input", () => {
        let value = thicknessInput->value->Float.fromString->Option.getOr(8.0)
        state := {...state.contents, pipeThickness: value}
        %raw(`(function() {
          const p = window.__currentP5Instance;
          if (p) { p.redraw(); }
        })`)()
      })

      container->appendChild(thicknessInput)

      // Layers control
      let layersLabel = createElement("label")
      layersLabel->setTextContent(" Layers: ")
      layersLabel->setAttribute("for", "num-layers")
      container->appendChild(layersLabel)

      let layersInput = createElement("input")
      layersInput->setAttribute("type", "number")
      layersInput->setAttribute("id", "num-layers")
      layersInput->setValue("3")
      layersInput->setAttribute("min", "1")
      layersInput->setAttribute("max", "5")
      layersInput->setAttribute("step", "1")

      layersInput->addEventListener("input", () => {
        let value = layersInput->value->Int.fromString->Option.getOr(3)
        state := {...state.contents, numLayers: value}
        regenerate()
      })

      container->appendChild(layersInput)

      // Gap size control
      let gapLabel = createElement("label")
      gapLabel->setTextContent(" Gap: ")
      gapLabel->setAttribute("for", "gap-size")
      container->appendChild(gapLabel)

      let gapInput = createElement("input")
      gapInput->setAttribute("type", "number")
      gapInput->setAttribute("id", "gap-size")
      gapInput->setValue("6")
      gapInput->setAttribute("min", "0")
      gapInput->setAttribute("max", "20")
      gapInput->setAttribute("step", "1")

      gapInput->addEventListener("input", () => {
        let value = gapInput->value->Float.fromString->Option.getOr(4.0)
        state := {...state.contents, gapSize: value}
        %raw(`(function() {
          const p = window.__currentP5Instance;
          if (p) { p.redraw(); }
        })`)()
      })

      container->appendChild(gapInput)

      // Curviness control
      let curveLabel = createElement("label")
      curveLabel->setTextContent(" Curviness: ")
      curveLabel->setAttribute("for", "curviness")
      container->appendChild(curveLabel)

      let curveInput = createElement("input")
      curveInput->setAttribute("type", "number")
      curveInput->setAttribute("id", "curviness")
      curveInput->setValue("0.5")
      curveInput->setAttribute("min", "0")
      curveInput->setAttribute("max", "2")
      curveInput->setAttribute("step", "0.1")

      curveInput->addEventListener("input", () => {
        let value = curveInput->value->Float.fromString->Option.getOr(0.3)
        state := {...state.contents, curviness: value}
        %raw(`(function() {
          const p = window.__currentP5Instance;
          if (p) { p.redraw(); }
        })`)()
      })

      container->appendChild(curveInput)

      // Stretchiness control
      let stretchLabel = createElement("label")
      stretchLabel->setTextContent(" Stretchiness: ")
      stretchLabel->setAttribute("for", "stretchiness")
      container->appendChild(stretchLabel)

      let stretchInput = createElement("input")
      stretchInput->setAttribute("type", "number")
      stretchInput->setAttribute("id", "stretchiness")
      stretchInput->setValue("1.0")
      stretchInput->setAttribute("min", "0.5")
      stretchInput->setAttribute("max", "3.0")
      stretchInput->setAttribute("step", "0.1")

      stretchInput->addEventListener("input", () => {
        let value = stretchInput->value->Float.fromString->Option.getOr(1.0)
        state := {...state.contents, stretchiness: value}
        %raw(`(function() {
          const p = window.__currentP5Instance;
          if (p) { p.redraw(); }
        })`)()
      })

      container->appendChild(stretchInput)

      // Regenerate button
      let regenButton = createElement("button")
      regenButton->setTextContent("Regenerate")
      regenButton->setAttribute("id", "regenerate-btn")

      regenButton->addEventListener("click", () => {
        regenerate()
      })

      container->appendChild(regenButton)

      Console.log("WFC Pipes controls created")
    }
  }
}

// Draw a curved pipe segment with bezier curves
let drawCurvedPipe = (
  p: P5.t,
  x1: float,
  y1: float,
  x2: float,
  y2: float,
  thickness: float,
  layer: int,
  gapSize: float,
  crossings: array<(float, float, int)>,
  numLayers: int,
  curviness: float,
) => {
  // Color pipes by layer
  let layerShade = 250.0 -. float_of_int(layer) /. float_of_int(numLayers) *. 200.0
  let shade = layerShade->Int.fromFloat

  p->P5.noFill
  p->P5.stroke3(shade, shade, shade)
  p->P5.strokeWeight(thickness->Int.fromFloat)

  %raw(`(function(p) { p.strokeCap(p.ROUND); })`)(p)

  // Calculate perpendicular offset for control points
  let dx = x2 -. x1
  let dy = y2 -. y1
  let length = Js.Math.sqrt(dx *. dx +. dy *. dy)

  // Perpendicular vector (rotated 90 degrees)
  let perpX = -.dy
  let perpY = dx

  // Normalize perpendicular
  let perpLen = Js.Math.sqrt(perpX *. perpX +. perpY *. perpY)
  let normPerpX = if perpLen > 0.0 {
    perpX /. perpLen
  } else {
    0.0
  }
  let normPerpY = if perpLen > 0.0 {
    perpY /. perpLen
  } else {
    0.0
  }

  // Create control points offset from the midpoint
  let midX = (x1 +. x2) /. 2.0
  let midY = (y1 +. y2) /. 2.0

  // Random offset to make curves more organic
  let randomOffset = %raw(`(Math.random() - 0.5) * 2.0`)
  let offset = length *. curviness *. randomOffset

  let cp1x = midX +. normPerpX *. offset
  let cp1y = midY +. normPerpY *. offset

  // Draw the bezier curve in segments to handle gaps
  let numSegments = 40

  for i in 0 to numSegments - 1 {
    let t1 = float_of_int(i) /. float_of_int(numSegments)
    let t2 = float_of_int(i + 1) /. float_of_int(numSegments)

    // Bezier curve formula: B(t) = (1-t)²P0 + 2(1-t)tP1 + t²P2 (quadratic)
    let getPoint = t => {
      let mt = 1.0 -. t
      let mt2 = mt *. mt
      let t2 = t *. t

      let x = mt2 *. x1 +. 2.0 *. mt *. t *. cp1x +. t2 *. x2
      let y = mt2 *. y1 +. 2.0 *. mt *. t *. cp1y +. t2 *. y2
      (x, y)
    }

    let (sx1, sy1) = getPoint(t1)
    let (sx2, sy2) = getPoint(t2)
    let smx = (sx1 +. sx2) /. 2.0
    let smy = (sy1 +. sy2) /. 2.0

    // Check crossings
    let crossingInfo = crossings->Array.reduce(None, (acc, (cx, cy, clayer)) => {
      let dist = Js.Math.sqrt((smx -. cx) *. (smx -. cx) +. (smy -. cy) *. (smy -. cy))
      if dist < gapSize *. 3.0 {
        Some((clayer, dist))
      } else {
        acc
      }
    })

    switch crossingInfo {
    | Some((clayer, _)) => if clayer > layer {
        // Goes under - skip
        ()
      } else if clayer < layer {
        // Goes over - draw bridge
        p->P5.stroke(255)
        p->P5.strokeWeight((thickness +. 4.0)->Int.fromFloat)
        p->P5.line(sx1, sy1, sx2, sy2)

        p->P5.stroke3(shade, shade, shade)
        p->P5.strokeWeight(thickness->Int.fromFloat)
        p->P5.line(sx1, sy1, sx2, sy2)
      } else {
        p->P5.line(sx1, sy1, sx2, sy2)
      }
    | None => p->P5.line(sx1, sy1, sx2, sy2)
    }
  }

  // Draw circles at connection points for "pipe joint" look
  // Use slightly lighter shade for joints
  let jointShade = Js.Math.min_float(layerShade +. 30.0, 255.0)->Int.fromFloat
  p->P5.fill3(jointShade, jointShade, jointShade)
  p->P5.stroke3(shade, shade, shade)
  p->P5.strokeWeight(2)
  p->P5.circle(x1, y1, thickness)
  p->P5.circle(x2, y2, thickness)
}

// Main draw function
let draw = (p: P5.t, paperSize: PlotterFrame.paperSize) => {
  let gridSize = state.contents.gridSize
  let pipeThickness = state.contents.pipeThickness
  let gapSize = state.contents.gapSize
  let numLayers = state.contents.numLayers
  let curviness = state.contents.curviness
  let stretchiness = state.contents.stretchiness

  // Calculate cell size
  let minDimension = Js.Math.min_float(paperSize.width->Int.toFloat, paperSize.height->Int.toFloat)
  let cellSize = minDimension /. float_of_int(gridSize)

  // Reinitialize if cell size or grid size changed
  if wfcState.contents.cellSize != cellSize || wfcState.contents.gridSize != gridSize {
    // Assign random layers to cells
    let totalCells = gridSize * gridSize
    let layers = Array.make(~length=totalCells, 0)->Array.mapWithIndex((_, i) => {
      %raw(`Math.floor(Math.random() * numLayers)`)
    })

    wfcState := {
        grid: createGrid(gridSize),
        gridSize,
        cellSize,
        collapsed: false,
        layers,
      }
  }

  // WFC algorithm step
  if !wfcState.contents.collapsed {
    // Find cell with minimum entropy
    let minEntropy = ref(999999)
    let minIndex = ref(-1)

    wfcState.contents.grid->Array.forEachWithIndex((cell, i) => {
      if !cell.collapsed && Array.length(cell.options) > 0 {
        let entropy = Array.length(cell.options)
        if entropy < minEntropy.contents {
          minEntropy := entropy
          minIndex := i
        }
      }
    })

    // Collapse the cell
    if minIndex.contents >= 0 {
      let cell = wfcState.contents.grid[minIndex.contents]
      switch cell {
      | Some(c) => {
          let x = mod(minIndex.contents, gridSize)
          let y = minIndex.contents / gridSize

          let validOptions = getValidOptions(wfcState.contents.grid, x, y, gridSize)

          if Array.length(validOptions) > 0 {
            let randomIndex = %raw(`Math.floor(Math.random() * validOptions.length)`)
            switch validOptions[randomIndex] {
            | Some(tile) => {
                c.options = [tile]
                c.collapsed = true
              }
            | None => {
                c.options = [
                  tiles[0]->Option.getOr({id: 0, edges: (A, B, A, B), connections: [Up, Down]}),
                ]
                c.collapsed = true
              }
            }
          } else {
            c.options = [
              tiles[0]->Option.getOr({id: 0, edges: (A, B, A, B), connections: [Up, Down]}),
            ]
            c.collapsed = true
          }
        }
      | None => ()
      }
    } else {
      wfcState := {...wfcState.contents, collapsed: true}
      // Stop drawing once generation is complete
      %raw(`(function(p) { p.noLoop(); })`)(p)
      Console.log("WFC generation complete - drawing stopped")
    }
  } else if wfcState.contents.collapsed {
    // Already collapsed, make sure we're not looping
    %raw(`(function(p) { p.noLoop(); })`)(p)
  }

  // Calculate centering offset
  let totalWidth = float_of_int(gridSize) *. cellSize
  let totalHeight = float_of_int(gridSize) *. cellSize
  let offsetX = (paperSize.width->Int.toFloat -. totalWidth) /. 2.0
  let offsetY = (paperSize.height->Int.toFloat -. totalHeight) /. 2.0

  // Collect all crossing points with layer info
  let crossings = []
  wfcState.contents.grid->Array.forEachWithIndex((cell, i) => {
    if cell.collapsed && Array.length(cell.options) > 0 {
      let x = mod(i, gridSize)
      let y = i / gridSize
      let cx = offsetX +. float_of_int(x) *. cellSize +. cellSize /. 2.0
      let cy = offsetY +. float_of_int(y) *. cellSize +. cellSize /. 2.0
      let layer = wfcState.contents.layers[i]->Option.getOr(0)

      %raw(`(function(arr, x, y, l) { arr.push([x, y, l]); })`)(crossings, cx, cy, layer)
    }
  })

  // Draw pipes with overlap effects - draw lower layers first
  for layer in 0 to numLayers - 1 {
    wfcState.contents.grid->Array.forEachWithIndex((cell, i) => {
      let cellLayer = wfcState.contents.layers[i]->Option.getOr(0)

      if cellLayer == layer && cell.collapsed && Array.length(cell.options) > 0 {
        let x = mod(i, gridSize)
        let y = i / gridSize

        let cx = offsetX +. float_of_int(x) *. cellSize +. cellSize /. 2.0
        let cy = offsetY +. float_of_int(y) *. cellSize +. cellSize /. 2.0

        switch cell.options[0] {
        | Some(tile) => // Draw pipes for each connection with gaps
          tile.connections->Array.forEach(dir => {
            let stretch = cellSize /. 2.0 *. stretchiness
            let (x2, y2) = switch dir {
            | Up => (cx, cy -. stretch)
            | Down => (cx, cy +. stretch)
            | Left => (cx -. stretch, cy)
            | Right => (cx +. stretch, cy)
            }

            drawCurvedPipe(
              p,
              cx,
              cy,
              x2,
              y2,
              pipeThickness,
              layer,
              gapSize,
              crossings,
              numLayers,
              curviness,
            )
          })
        | None => ()
        }
      }
    })
  }
}

// Create the sketch
let createSketch = () => {
  createControls()
  PlotterFrame.createPlotterSketch(draw)()
}
