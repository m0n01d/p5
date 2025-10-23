// Wave Function Collapse Sketch - adapted for plotter output
// Uses the PlotterFrame for UI and settings

type tile = {
  index: int,
  options: array<int>,
}

type wfcState = {
  grid: array<array<tile>>,
  gridSize: int,
  cellSize: float,
  collapsed: bool,
}

// Tile patterns - simple 2x2 patterns
// 0 = blank, 1 = horizontal, 2 = vertical, 3 = cross
let tileColors = [(240, 240, 240), (100, 150, 255), (255, 100, 100), (100, 255, 150)] // blank - light gray // horizontal - blue // vertical - red // cross - green

// Adjacency rules - which tiles can be next to each other
// [top, right, bottom, left] for each tile type
let adjacencyRules = [
  [[0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3]], // blank - any
  [[0, 1, 3], [1, 3], [0, 1, 3], [1, 3]], // horizontal
  [[2, 3], [0, 2, 3], [2, 3], [0, 2, 3]], // vertical
  [[2, 3], [1, 3], [2, 3], [1, 3]], // cross
]

// Create initial grid with all possibilities
let createGrid = (gridSize: int): array<array<tile>> => {
  Array.make(~length=gridSize, ())->Array.map(_ =>
    Array.make(~length=gridSize, ())->Array.map(_ => {
      index: -1,
      options: [0, 1, 2, 3],
    })
  )
}

// Get tile with minimum entropy (fewest options)
let getMinEntropyTile = (grid: array<array<tile>>): option<(int, int)> => {
  let minEntropy = ref(999)
  let minPos = ref(None)

  grid->Array.forEachWithIndex((row, y) => {
    row->Array.forEachWithIndex((tile, x) => {
      if tile.index == -1 && Array.length(tile.options) > 0 {
        let entropy = Array.length(tile.options)
        if entropy < minEntropy.contents {
          minEntropy := entropy
          minPos := Some((x, y))
        }
      }
    })
  })

  minPos.contents
}

// Collapse a tile by choosing one of its options
let collapseTile = (tile: tile, p: P5.t): tile => {
  if Array.length(tile.options) == 0 {
    tile
  } else {
    let randomIndex = p->P5.random(float_of_int(Array.length(tile.options)))->Float.toInt
    let chosenOption = tile.options[randomIndex]->Option.getOr(0)
    {index: chosenOption, options: [chosenOption]}
  }
}

// Propagate constraints to neighbors
let propagateConstraints = (grid: array<array<tile>>, x: int, y: int): array<array<tile>> => {
  let newGrid = grid->Array.map(row => row->Array.map(tile => tile))
  let gridSize = Array.length(grid)

  // Get the collapsed tile
  let centerTile = grid[y]->Option.flatMap(row => row[x])

  switch centerTile {
  | None => newGrid
  | Some(tile) =>
    if tile.index == -1 {
      newGrid
    } else {
      let tileIndex = tile.index
      let rules = adjacencyRules[tileIndex]->Option.getOr([[0], [0], [0], [0]])

      // Update neighbors based on rules
      // Top
      if y > 0 {
        newGrid[y - 1]
        ->Option.map(row => {
          let neighbor = row[x]->Option.getOr({index: -1, options: []})
          if neighbor.index == -1 {
            row[x] = {
              ...neighbor,
              options: neighbor.options->Array.filter(opt =>
                rules[0]->Option.getOr([])->Array.includes(opt)
              ),
            }
          }
        })
        ->ignore
      }

      // Right
      if x < gridSize - 1 {
        newGrid[y]
        ->Option.map(row => {
          let neighbor = row[x + 1]->Option.getOr({index: -1, options: []})
          if neighbor.index == -1 {
            row[
              x + 1
            ] = {
              ...neighbor,
              options: neighbor.options->Array.filter(opt =>
                rules[1]->Option.getOr([])->Array.includes(opt)
              ),
            }
          }
        })
        ->ignore
      }

      // Bottom
      if y < gridSize - 1 {
        newGrid[y + 1]
        ->Option.map(row => {
          let neighbor = row[x]->Option.getOr({index: -1, options: []})
          if neighbor.index == -1 {
            row[x] = {
              ...neighbor,
              options: neighbor.options->Array.filter(opt =>
                rules[2]->Option.getOr([])->Array.includes(opt)
              ),
            }
          }
        })
        ->ignore
      }

      // Left
      if x > 0 {
        newGrid[y]
        ->Option.map(row => {
          let neighbor = row[x - 1]->Option.getOr({index: -1, options: []})
          if neighbor.index == -1 {
            row[
              x - 1
            ] = {
              ...neighbor,
              options: neighbor.options->Array.filter(opt =>
                rules[3]->Option.getOr([])->Array.includes(opt)
              ),
            }
          }
        })
        ->ignore
      }

      newGrid
    }
  }
}

// Draw a tile in plotter style (black lines only)
let drawTile = (p: P5.t, tile: tile, x: float, y: float, size: float) => {
  p->P5.stroke(0)
  p->P5.strokeWeight(1)
  p->P5.noFill

  // Draw cell border
  p->P5.rect(x, y, size, size)

  if tile.index != -1 {
    // Draw pattern details - plotter style (black lines only)
    switch tile.index {
    | 1 =>
      // Horizontal line
      p->P5.line(x, y +. size /. 2.0, x +. size, y +. size /. 2.0)
    | 2 =>
      // Vertical line
      p->P5.line(x +. size /. 2.0, y, x +. size /. 2.0, y +. size)
    | 3 => {
        // Cross
        p->P5.line(x, y +. size /. 2.0, x +. size, y +. size /. 2.0)
        p->P5.line(x +. size /. 2.0, y, x +. size /. 2.0, y +. size)
      }
    | _ => () // blank - no pattern
    }
  }
}

// Global state for WFC
let wfcState = ref({
  grid: createGrid(20),
  gridSize: 20,
  cellSize: 0.0,
  collapsed: false,
})

// Create the WFC drawing function
let draw = (p: P5.t, paperSize: PlotterFrame.paperSize) => {
  // Calculate grid size to fit paper with margins
  let margin = 30.0
  let availableWidth = paperSize.width->Int.toFloat -. margin *. 2.0
  let availableHeight = paperSize.height->Int.toFloat -. margin *. 2.0
  let minDimension = Js.Math.min_float(availableWidth, availableHeight)

  let gridSize = 20 // 20x20 grid for plotter output
  let cellSize = minDimension /. float_of_int(gridSize)

  // Center the grid
  let startX = (paperSize.width->Int.toFloat -. cellSize *. float_of_int(gridSize)) /. 2.0
  let startY = (paperSize.height->Int.toFloat -. cellSize *. float_of_int(gridSize)) /. 2.0

  // Initialize grid if needed or if paper size changed
  if wfcState.contents.cellSize != cellSize {
    wfcState := {
        grid: createGrid(gridSize),
        gridSize,
        cellSize,
        collapsed: false,
      }
    p->P5.frameRate(1200.0)
  }

  let grid = wfcState.contents.grid

  // Draw all tiles
  grid->Array.forEachWithIndex((row, y) => {
    row->Array.forEachWithIndex((tile, x) => {
      let xPos = startX +. float_of_int(x) *. cellSize
      let yPos = startY +. float_of_int(y) *. cellSize
      drawTile(p, tile, xPos, yPos, cellSize)
    })
  })

  // Perform WFC step per frame
  if !wfcState.contents.collapsed {
    switch getMinEntropyTile(grid) {
    | None => {
        wfcState := {...wfcState.contents, collapsed: true}
        Console.log("WFC complete!")
      }
    | Some((x, y)) => {
        // Collapse the tile
        let tile =
          grid[y]
          ->Option.flatMap(row => row[x])
          ->Option.getOr({
            index: -1,
            options: [],
          })
        let newTile = collapseTile(tile, p)

        // Update grid
        let newGrid = grid->Array.mapWithIndex((row, rowY) =>
          if rowY == y {
            row->Array.mapWithIndex((t, colX) =>
              if colX == x {
                newTile
              } else {
                t
              }
            )
          } else {
            row
          }
        )

        // Propagate constraints
        let propagatedGrid = propagateConstraints(newGrid, x, y)
        wfcState := {...wfcState.contents, grid: propagatedGrid}
      }
    }
  }
}

// Create the sketch using the plotter frame
let createSketch = PlotterFrame.createPlotterSketch(draw)
