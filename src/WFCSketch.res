// Wave Function Collapse Sketch
// A simple tile-based WFC implementation

type tile = {
  index: int,
  options: array<int>,
}

type wfcState = {
  grid: array<array<tile>>,
  gridSize: int,
  tileSize: int,
  collapsed: bool,
}

// Tile patterns - simple 2x2 patterns
// 0 = blank, 1 = horizontal, 2 = vertical, 3 = cross
let tileColors = [
  (240, 240, 240), // blank - light gray
  (100, 150, 255), // horizontal - blue
  (255, 100, 100), // vertical - red
  (100, 255, 150), // cross - green
]

// Adjacency rules - which tiles can be next to each other
// [top, right, bottom, left] for each tile type
let adjacencyRules = [
  [[0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3]], // blank - any
  [[0, 1, 3], [1, 3], [0, 1, 3], [1, 3]],                   // horizontal
  [[2, 3], [0, 2, 3], [2, 3], [0, 2, 3]],                   // vertical
  [[2, 3], [1, 3], [2, 3], [1, 3]],                         // cross
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
    let randomIndex = (p->P5.random(float_of_int(Array.length(tile.options))))->Float.toInt
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
              options: neighbor.options->Array.filter(opt => rules[0]->Option.getOr([])->Array.includes(opt)),
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
            row[x + 1] = {
              ...neighbor,
              options: neighbor.options->Array.filter(opt => rules[1]->Option.getOr([])->Array.includes(opt)),
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
              options: neighbor.options->Array.filter(opt => rules[2]->Option.getOr([])->Array.includes(opt)),
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
            row[x - 1] = {
              ...neighbor,
              options: neighbor.options->Array.filter(opt => rules[3]->Option.getOr([])->Array.includes(opt)),
            }
          }
        })
        ->ignore
      }

      newGrid
    }
  }
}

// Draw a tile
let drawTile = (p: P5.t, tile: tile, x: int, y: int, tileSize: int) => {
  let xPos = float_of_int(x * tileSize)
  let yPos = float_of_int(y * tileSize)
  let size = float_of_int(tileSize)

  if tile.index == -1 {
    // Uncollapsed - show as gray with entropy indicator
    let entropy = Array.length(tile.options)
    let grayValue = 200 - entropy * 30
    p->P5.fill(grayValue)
    p->P5.rect(xPos, yPos, size, size)
  } else {
    // Collapsed - draw the pattern
    let color = tileColors[tile.index]->Option.getOr((255, 255, 255))
    let (r, g, b) = color
    p->P5.fill3(r, g, b)
    p->P5.rect(xPos, yPos, size, size)

    // Draw pattern details
    p->P5.stroke(0)
    p->P5.strokeWeight(2)

    switch tile.index {
    | 1 => {
        // Horizontal line
        p->P5.line(xPos, yPos +. size /. 2.0, xPos +. size, yPos +. size /. 2.0)
      }
    | 2 => {
        // Vertical line
        p->P5.line(xPos +. size /. 2.0, yPos, xPos +. size /. 2.0, yPos +. size)
      }
    | 3 => {
        // Cross
        p->P5.line(xPos, yPos +. size /. 2.0, xPos +. size, yPos +. size /. 2.0)
        p->P5.line(xPos +. size /. 2.0, yPos, xPos +. size /. 2.0, yPos +. size)
      }
    | _ => ()
    }
  }

  // Grid lines
  p->P5.noFill
  p->P5.stroke(100)
  p->P5.strokeWeight(1)
  p->P5.rect(xPos, yPos, size, size)
}

// Main sketch function
let createSketch = () => {
  let state = ref({
    grid: createGrid(10),
    gridSize: 10,
    tileSize: 50,
    collapsed: false,
  })

  (p: P5.t) => {
    // Setup
    p->P5.setSetup(() => {
      let s = state.contents
      let canvas = p->P5.createCanvas(s.gridSize * s.tileSize, s.gridSize * s.tileSize)
      // Parent is already set by SketchManager, but createCanvas might create a duplicate
      // So we don't call parent here
      canvas->ignore
      p->P5.frameRate(10.0)
    })

    // Draw
    p->P5.setDraw(() => {
      let s = state.contents
      p->P5.background(255)

      // Draw all tiles
      s.grid->Array.forEachWithIndex((row, y) => {
        row->Array.forEachWithIndex((tile, x) => {
          drawTile(p, tile, x, y, s.tileSize)
        })
      })

      // Perform one WFC step per frame
      if !s.collapsed {
        switch getMinEntropyTile(s.grid) {
        | None => {
            state := {...s, collapsed: true}
            Console.log("WFC complete!")
          }
        | Some((x, y)) => {
            // Collapse the tile
            let tile = s.grid[y]->Option.flatMap(row => row[x])->Option.getOr({
              index: -1,
              options: [],
            })
            let newTile = collapseTile(tile, p)

            // Update grid
            let newGrid = s.grid->Array.mapWithIndex((row, rowY) =>
              if rowY == y {
                row->Array.mapWithIndex((t, colX) => if colX == x { newTile } else { t })
              } else {
                row
              }
            )

            // Propagate constraints
            let propagatedGrid = propagateConstraints(newGrid, x, y)
            state := {...s, grid: propagatedGrid}
          }
        }
      }
    })

    // Mouse click to restart
    p->P5.setMousePressed(() => {
      state := {
        grid: createGrid(state.contents.gridSize),
        gridSize: state.contents.gridSize,
        tileSize: state.contents.tileSize,
        collapsed: false,
      }
    })
  }
}
