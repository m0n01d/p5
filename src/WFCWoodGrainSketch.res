// WFC Wood Grain Sketch - Wave Function Collapse with flowing wood grain
// Creates organic wood grain patterns that flow across tiles

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

// State for wood grain controls
type grainState = {
  gridSize: int,
  grainDensity: int, // Number of lines per tile
  waviness: float, // How wavy the grain is
  lineWeight: float,
  knotFrequency: float, // 0-1, chance of knots
}

let state = ref({
  gridSize: 10,
  grainDensity: 8,
  waviness: 0.3,
  lineWeight: 1.0,
  knotFrequency: 0.05,
})

// WFC types
type direction = Up | Right | Down | Left

type socket = Horizontal | Vertical | CornerA | CornerB

type tile = {
  id: int,
  edges: (socket, socket, socket, socket), // up, right, down, left
  grainDirection: direction, // Primary grain flow direction
  hasKnot: bool,
}

type cell = {
  mutable collapsed: bool,
  mutable options: array<tile>,
}

// Define tile types - only vertical grain flow
let tiles = [
  // Vertical grain flowing up
  {id: 0, edges: (Vertical, Horizontal, Vertical, Horizontal), grainDirection: Up, hasKnot: false},
  // Vertical grain flowing down
  {id: 1, edges: (Vertical, Horizontal, Vertical, Horizontal), grainDirection: Down, hasKnot: false},
  // Knot with vertical grain passing through
  {id: 2, edges: (Vertical, Horizontal, Vertical, Horizontal), grainDirection: Up, hasKnot: true},
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
  | _ => (Horizontal, Vertical) // Should never happen
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

// WFC state
type wfcState = {
  grid: array<cell>,
  gridSize: int,
  cellSize: float,
  collapsed: bool,
}

let wfcState = ref({
  grid: createGrid(10),
  gridSize: 10,
  cellSize: 0.0,
  collapsed: false,
})

// Regenerate function
let regenerate = () => {
  wfcState := {
    grid: createGrid(state.contents.gridSize),
    gridSize: state.contents.gridSize,
    cellSize: 0.0,
    collapsed: false,
  }
  %raw(`(function() {
    const p = window.__currentP5Instance;
    if (p && !p.isLooping()) { p.loop(); }
  })`)()
  Console.log("Regenerating wood grain...")
}

// Create controls
let createControls = () => {
  let controlsDiv = getElementById("sketch-specific-controls")

  switch controlsDiv->Js.Nullable.toOption {
  | None => Console.log("Sketch-specific controls container not found")
  | Some(container) => {
      container->setInnerHTML("")
      container->setClassName("controls")

      // Grid size
      let gridLabel = createElement("label")
      gridLabel->setTextContent("Grid Size: ")
      gridLabel->setAttribute("for", "grid-size")
      container->appendChild(gridLabel)

      let gridInput = createElement("input")
      gridInput->setAttribute("type", "number")
      gridInput->setAttribute("id", "grid-size")
      gridInput->setValue("10")
      gridInput->setAttribute("min", "4")
      gridInput->setAttribute("max", "25")
      gridInput->setAttribute("step", "1")

      gridInput->addEventListener("input", () => {
        let value = gridInput->value->Int.fromString->Option.getOr(10)
        state := {...state.contents, gridSize: value}
        regenerate()
      })

      container->appendChild(gridInput)

      // Grain density
      let densityLabel = createElement("label")
      densityLabel->setTextContent(" Grain Lines: ")
      densityLabel->setAttribute("for", "grain-density")
      container->appendChild(densityLabel)

      let densityInput = createElement("input")
      densityInput->setAttribute("type", "number")
      densityInput->setAttribute("id", "grain-density")
      densityInput->setValue("8")
      densityInput->setAttribute("min", "3")
      densityInput->setAttribute("max", "20")
      densityInput->setAttribute("step", "1")

      densityInput->addEventListener("input", () => {
        let value = densityInput->value->Int.fromString->Option.getOr(8)
        state := {...state.contents, grainDensity: value}
        %raw(`(function() {
          const p = window.__currentP5Instance;
          if (p) { p.redraw(); }
        })`)()
      })

      container->appendChild(densityInput)

      // Waviness
      let wavinessLabel = createElement("label")
      wavinessLabel->setTextContent(" Waviness: ")
      wavinessLabel->setAttribute("for", "waviness")
      container->appendChild(wavinessLabel)

      let wavinessInput = createElement("input")
      wavinessInput->setAttribute("type", "number")
      wavinessInput->setAttribute("id", "waviness")
      wavinessInput->setValue("0.3")
      wavinessInput->setAttribute("min", "0")
      wavinessInput->setAttribute("max", "1.5")
      wavinessInput->setAttribute("step", "0.1")

      wavinessInput->addEventListener("input", () => {
        let value = wavinessInput->value->Float.fromString->Option.getOr(0.3)
        state := {...state.contents, waviness: value}
        %raw(`(function() {
          const p = window.__currentP5Instance;
          if (p) { p.redraw(); }
        })`)()
      })

      container->appendChild(wavinessInput)

      // Line weight
      let weightLabel = createElement("label")
      weightLabel->setTextContent(" Line Weight: ")
      weightLabel->setAttribute("for", "line-weight")
      container->appendChild(weightLabel)

      let weightInput = createElement("input")
      weightInput->setAttribute("type", "number")
      weightInput->setAttribute("id", "line-weight")
      weightInput->setValue("1.0")
      weightInput->setAttribute("min", "0.5")
      weightInput->setAttribute("max", "3.0")
      weightInput->setAttribute("step", "0.5")

      weightInput->addEventListener("input", () => {
        let value = weightInput->value->Float.fromString->Option.getOr(1.0)
        state := {...state.contents, lineWeight: value}
        %raw(`(function() {
          const p = window.__currentP5Instance;
          if (p) { p.redraw(); }
        })`)()
      })

      container->appendChild(weightInput)

      // Knot frequency
      let knotLabel = createElement("label")
      knotLabel->setTextContent(" Knots: ")
      knotLabel->setAttribute("for", "knot-freq")
      container->appendChild(knotLabel)

      let knotInput = createElement("input")
      knotInput->setAttribute("type", "number")
      knotInput->setAttribute("id", "knot-freq")
      knotInput->setValue("0.05")
      knotInput->setAttribute("min", "0")
      knotInput->setAttribute("max", "0.3")
      knotInput->setAttribute("step", "0.05")

      knotInput->addEventListener("input", () => {
        let value = knotInput->value->Float.fromString->Option.getOr(0.05)
        state := {...state.contents, knotFrequency: value}
        regenerate()
      })

      container->appendChild(knotInput)

      // Regenerate button
      let regenButton = createElement("button")
      regenButton->setTextContent("Regenerate")
      regenButton->setAttribute("id", "regenerate-btn")

      regenButton->addEventListener("click", () => {
        regenerate()
      })

      container->appendChild(regenButton)

      Console.log("Wood grain controls created")
    }
  }
}

// Draw wood grain lines for a tile
let drawWoodGrain = (
  p: P5.t,
  cx: float,
  cy: float,
  cellSize: float,
  tile: tile,
  density: int,
  waviness: float,
  weight: float,
) => {
  p->P5.stroke(0)
  p->P5.strokeWeight(weight->Int.fromFloat)
  p->P5.noFill

  if tile.hasKnot {
    // Draw vertical grain lines through the knot first
    let spacing = cellSize /. float_of_int(density + 1)

    for i in 1 to density {
      let offset = float_of_int(i) *. spacing -. cellSize /. 2.0
      let randomOffset = %raw(`(Math.random() - 0.5)`) *. spacing *. 0.5
      let lineOffset = offset +. randomOffset
      let freqVariation = 1.5 +. %raw(`Math.random()`) *. 1.5
      let phaseOffset = %raw(`Math.random()`) *. Js.Math._PI *. 2.0

      %raw(`(function(p) { p.beginShape(); })`)(p)

      // Draw vertical grain flowing through the knot
      let numPoints = 25
      for j in 0 to numPoints {
        let t = float_of_int(j) /. float_of_int(numPoints)
        let y = cy -. cellSize /. 2.0 +. t *. cellSize

        // Add wave and distortion - more distortion near the knot center
        let distFromCenter = Js.Math.abs_float((cy -. y) /. cellSize)
        let knotInfluence = 1.0 -. distFromCenter *. 2.0
        let knotPush = if knotInfluence > 0.0 {
          // Push the line away from knot center
          let pushAmount = knotInfluence *. cellSize *. 0.15
          if lineOffset > 0.0 { pushAmount } else { -.pushAmount }
        } else {
          0.0
        }

        let wave1 = Js.Math.sin(t *. Js.Math._PI *. freqVariation +. phaseOffset) *. waviness *. cellSize *. 0.08
        let wave2 = Js.Math.sin(t *. Js.Math._PI *. 5.0 +. phaseOffset *. 2.0) *. waviness *. cellSize *. 0.03
        let noise = %raw(`(Math.random() - 0.5)`) *. waviness *. 0.5
        let x = cx +. lineOffset +. wave1 +. wave2 +. noise +. knotPush
        %raw(`(function(p, x, y) { p.vertex(x, y); })`)(p, x, y)
      }
      %raw(`(function(p) { p.endShape(); })`)(p)
    }

    // Draw subtle knot rings (fewer and softer)
    let numRings = Js.Math.max_int(3, density / 3)
    let knotOffsetX = %raw(`(Math.random() - 0.5)`) *. cellSize *. 0.15
    let knotOffsetY = %raw(`(Math.random() - 0.5)`) *. cellSize *. 0.15

    // Make knots more subtle with lighter stroke
    let originalWeight = weight
    p->P5.strokeWeight((weight *. 0.5)->Int.fromFloat)

    for i in 1 to numRings {
      let baseRadius = (float_of_int(i) /. float_of_int(numRings)) *. cellSize *. 0.25
      let points = 40
      %raw(`(function(p) { p.beginShape(); })`)(p)
      for j in 0 to points {
        let angle = (float_of_int(j) /. float_of_int(points)) *. 2.0 *. Js.Math._PI
        // Gentle wave on the rings
        let noiseAmount = Js.Math.sin(angle *. 4.0 +. float_of_int(i)) *. waviness *. 1.5
        let r = baseRadius +. noiseAmount
        let x = cx +. knotOffsetX +. Js.Math.cos(angle) *. r
        let y = cy +. knotOffsetY +. Js.Math.sin(angle) *. r *. 0.8 // Slightly elliptical
        %raw(`(function(p, x, y) { p.vertex(x, y); })`)(p, x, y)
      }
      %raw(`(function(p) { p.endShape(p.CLOSE); })`)(p)
    }

    // Restore weight
    p->P5.strokeWeight(originalWeight->Int.fromFloat)
  } else {
    // Draw flowing grain lines based on direction
    let spacing = cellSize /. float_of_int(density + 1)

    for i in 1 to density {
      let offset = float_of_int(i) *. spacing -. cellSize /. 2.0
      // Random offset per line for more organic variation
      let randomOffset = %raw(`(Math.random() - 0.5)`) *. spacing *. 0.5
      let lineOffset = offset +. randomOffset

      // Random frequency variation per line
      let freqVariation = 1.5 +. %raw(`Math.random()`) *. 1.5 // 1.5 to 3.0
      // Random phase offset so lines aren't synchronized
      let phaseOffset = %raw(`Math.random()`) *. Js.Math._PI *. 2.0

      %raw(`(function(p) { p.beginShape(); })`)(p)

      // All grain flows vertically
      let numPoints = 25
      let (startY, endY) = switch tile.grainDirection {
      | Down => (cy -. cellSize /. 2.0, cy +. cellSize /. 2.0)
      | Up => (cy +. cellSize /. 2.0, cy -. cellSize /. 2.0)
      | _ => (cy -. cellSize /. 2.0, cy +. cellSize /. 2.0) // Default to down
      }

      for j in 0 to numPoints {
        let t = float_of_int(j) /. float_of_int(numPoints)
        let y = startY +. t *. (endY -. startY)
        // Multiple sine waves at different frequencies for organic noise
        let wave1 = Js.Math.sin(t *. Js.Math._PI *. freqVariation +. phaseOffset) *. waviness *. cellSize *. 0.08
        let wave2 = Js.Math.sin(t *. Js.Math._PI *. 5.0 +. phaseOffset *. 2.0) *. waviness *. cellSize *. 0.03
        let noise = %raw(`(Math.random() - 0.5)`) *. waviness *. 0.5
        let x = cx +. lineOffset +. wave1 +. wave2 +. noise
        %raw(`(function(p, x, y) { p.vertex(x, y); })`)(p, x, y)
      }

      %raw(`(function(p) { p.endShape(); })`)(p)
    }
  }
}

// Main draw function
let draw = (p: P5.t, paperSize: PlotterFrame.paperSize) => {
  let gridSize = state.contents.gridSize
  let grainDensity = state.contents.grainDensity
  let waviness = state.contents.waviness
  let lineWeight = state.contents.lineWeight
  let knotFrequency = state.contents.knotFrequency

  // Calculate cell size
  let minDimension = Js.Math.min_float(
    paperSize.width->Int.toFloat,
    paperSize.height->Int.toFloat,
  )
  let cellSize = minDimension /. float_of_int(gridSize)

  // Reinitialize if grid size changed
  if wfcState.contents.cellSize != cellSize || wfcState.contents.gridSize != gridSize {
    wfcState := {
      grid: createGrid(gridSize),
      gridSize,
      cellSize,
      collapsed: false,
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
            // Filter out knot tiles based on frequency
            let shouldHaveKnot = %raw(`Math.random()`) < knotFrequency
            let filteredOptions = if shouldHaveKnot {
              let knotOptions = validOptions->Array.filter(t => t.hasKnot)
              if Array.length(knotOptions) > 0 { knotOptions } else { validOptions }
            } else {
              validOptions->Array.filter(t => !t.hasKnot)
            }

            let optionsToUse = if Array.length(filteredOptions) > 0 {
              filteredOptions
            } else {
              validOptions
            }

            let randomIndex = %raw(`Math.floor(Math.random() * optionsToUse.length)`)
            switch optionsToUse[randomIndex] {
            | Some(tile) => {
                c.options = [tile]
                c.collapsed = true
              }
            | None => {
                c.options = [tiles[0]->Option.getOr({
                  id: 0,
                  edges: (Horizontal, Vertical, Horizontal, Vertical),
                  grainDirection: Right,
                  hasKnot: false,
                })]
                c.collapsed = true
              }
            }
          } else {
            c.options = [tiles[0]->Option.getOr({
              id: 0,
              edges: (Horizontal, Vertical, Horizontal, Vertical),
              grainDirection: Right,
              hasKnot: false,
            })]
            c.collapsed = true
          }
        }
      | None => ()
      }
    } else {
      wfcState := {...wfcState.contents, collapsed: true}
      %raw(`(function(p) { p.noLoop(); })`)(p)
      Console.log("Wood grain generation complete")
    }
  }

  // Calculate centering offset
  let totalWidth = float_of_int(gridSize) *. cellSize
  let totalHeight = float_of_int(gridSize) *. cellSize
  let offsetX = (paperSize.width->Int.toFloat -. totalWidth) /. 2.0
  let offsetY = (paperSize.height->Int.toFloat -. totalHeight) /. 2.0

  // Draw wood grain for each cell
  wfcState.contents.grid->Array.forEachWithIndex((cell, i) => {
    if cell.collapsed && Array.length(cell.options) > 0 {
      let x = mod(i, gridSize)
      let y = i / gridSize

      let cx = offsetX +. float_of_int(x) *. cellSize +. cellSize /. 2.0
      let cy = offsetY +. float_of_int(y) *. cellSize +. cellSize /. 2.0

      switch cell.options[0] {
      | Some(tile) => drawWoodGrain(p, cx, cy, cellSize, tile, grainDensity, waviness, lineWeight)
      | None => ()
      }
    }
  })
}

// Create the sketch
let createSketch = () => {
  createControls()
  PlotterFrame.createPlotterSketch(draw)()
}
