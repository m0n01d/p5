// Tiling Sketch - repeating pattern for printing

// Tile size in pixels
let tileSize = 50.0

// Current recursion level (adjustable)
let currentLevel = ref(4)

// Debug grid toggle
let showDebugGrid = ref(false)

// Draw a single tile at position (x, y)
// canvasWidth and canvasHeight are the actual drawable area bounds
let rec drawTile = (
  p: P5.t,
  x: float,
  y: float,
  size: float,
  l: int,
  canvasWidth: float,
  canvasHeight: float,
) => {
  Console.log(l)

  // Early exit if tile is completely outside canvas bounds
  if x >= canvasWidth || y >= canvasHeight || x +. size <= 0.0 || y +. size <= 0.0 {
    ()
  } else {
    // DEBUG: Draw red quadrant borders - clipped to visible area
    if showDebugGrid.contents {
      let visibleLeft = x > 0.0 ? x : 0.0
      let visibleTop = y > 0.0 ? y : 0.0
      let visibleRight = x +. size < canvasWidth ? x +. size : canvasWidth
      let visibleBottom = y +. size < canvasHeight ? y +. size : canvasHeight
      let visibleWidth = visibleRight -. visibleLeft
      let visibleHeight = visibleBottom -. visibleTop

      p->P5.stroke3(255, 0, 0)
      p->P5.strokeWeight(1)
      p->P5.noFill
      p->P5.rect(visibleLeft, visibleTop, visibleWidth, visibleHeight)
    }

    if l == 0 {
      // Random 0 or 1: 0 = vertical, 1 = horizontal
      let orientation = p->P5.random2(0.0, 2.0)->Float.toInt

      p->P5.stroke(0)
      p->P5.strokeWeight(1)

    if orientation == 0 {
      // Vertical line - clipped to visible portion of tile
      // Clip tile boundaries to canvas
      let visibleLeft = x > 0.0 ? x : 0.0
      let visibleRight = x +. size < canvasWidth ? x +. size : canvasWidth
      let visibleTop = y > 0.0 ? y : 0.0
      let visibleBottom = y +. size < canvasHeight ? y +. size : canvasHeight

      // Center X based on visible width
      let centerX = (visibleLeft +. visibleRight) /. 2.0
      p->P5.line(centerX, visibleTop, centerX, visibleBottom)
    } else {
      // Horizontal line - clipped to visible portion of tile
      // Clip tile boundaries to canvas
      let visibleLeft = x > 0.0 ? x : 0.0
      let visibleRight = x +. size < canvasWidth ? x +. size : canvasWidth
      let visibleTop = y > 0.0 ? y : 0.0
      let visibleBottom = y +. size < canvasHeight ? y +. size : canvasHeight

      // Center Y based on visible height
      let centerY = (visibleTop +. visibleBottom) /. 2.0
      p->P5.line(visibleLeft, centerY, visibleRight, centerY)
    }
    } else {
    let s = size /. 2.0
    let nextlevel = l - 1
    // Top-left quadrant
    drawTile(p, x, y, s, nextlevel, canvasWidth, canvasHeight)
    // Top-right quadrant
    drawTile(p, x +. s, y, s, nextlevel, canvasWidth, canvasHeight)
    // Bottom-left quadrant
    drawTile(p, x, y +. s, s, nextlevel, canvasWidth, canvasHeight)
    // Bottom-right quadrant
    drawTile(p, x +. s, y +. s, s, nextlevel, canvasWidth, canvasHeight)
    }
  }
}

// Store p5 instance and paper size for redraws
let p5Instance: ref<option<P5.t>> = ref(None)
let paperSize: ref<option<PlotterFrame.paperSize>> = ref(None)

// Redraw function - redraws by triggering PlotterFrame's draw cycle ONCE
let redrawTiling = () => {
  switch p5Instance.contents {
  | Some(p) => {
      // Trigger one frame of the draw cycle
      p->P5.loop
      // PlotterFrame's draw will call drawWithControls which calls draw()
      // draw() will call noLoop again after drawing
    }
  | None => ()
  }
}

// Draw function called by PlotterFrame
let draw = (p: P5.t, paper: PlotterFrame.paperSize) => {
  // Store references for later redraws
  p5Instance := Some(p)
  paperSize := Some(paper)

  // Draw the tiling pattern within the drawable area only
  // paper dimensions are already the safe area (margin/padding removed by PlotterFrame)
  let paperWidth = paper.width->Int.toFloat
  let paperHeight = paper.height->Int.toFloat

  // Use a SQUARE based on the larger dimension to create the recursive pattern
  // But it will be clipped to paperWidth x paperHeight
  let size = paperWidth > paperHeight ? paperWidth : paperHeight

  // Center the square pattern on the rectangular canvas
  let offsetX = (size -. paperWidth) /. 2.0
  let offsetY = (size -. paperHeight) /. 2.0

  // Start tiling from negative offset to center the square pattern
  // The square extends beyond bounds, but drawing is clipped to paperWidth x paperHeight
  drawTile(p, -.offsetX, -.offsetY, size, currentLevel.contents, paperWidth, paperHeight)

  // Stop the loop after this frame
  p->P5.noLoop
}

// Track if controls have been created
let controlsCreated = ref(false)

// Setup controls
let setupControls = (p: P5.t) => {
  if !controlsCreated.contents {
    controlsCreated := true

    // Get the controls container
    let controlsDiv = PlotterFrame.getElementById("paper-settings-controls")
    switch controlsDiv->Js.Nullable.toOption {
    | None => Console.log("Paper settings controls container not found")
    | Some(container) => {
        // Create level label
        let levelLabel = PlotterFrame.createElement("label")
        levelLabel->PlotterFrame.setTextContent("Recursion Level (0-8)")
        levelLabel->PlotterFrame.setAttribute("for", "recursion-level")
        levelLabel->PlotterFrame.setClassName("block text-sm font-medium text-zinc-300 mb-1 mt-3")
        container->PlotterFrame.appendChild(levelLabel)

        // Create level input
        let levelInput = PlotterFrame.createElement("input")
        levelInput->PlotterFrame.setAttribute("type", "number")
        levelInput->PlotterFrame.setAttribute("id", "recursion-level")
        levelInput->PlotterFrame.setValue("4")
        levelInput->PlotterFrame.setAttribute("min", "0")
        levelInput->PlotterFrame.setAttribute("max", "8")
        levelInput->PlotterFrame.setAttribute("step", "1")
        levelInput->PlotterFrame.setClassName(
          "w-full px-3 py-2 bg-zinc-700 border border-zinc-600 rounded-md text-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500",
        )

        // Add change handler for level input
        levelInput->PlotterFrame.addEventListener("input", () => {
          let value = levelInput->PlotterFrame.value->Float.fromString->Option.getOr(4.0)
          currentLevel := value->Float.toInt
          redrawTiling() // Directly redraw, no loop
        })

        container->PlotterFrame.appendChild(levelInput)

        // Debug grid toggle
        let debugLabel = PlotterFrame.createElement("label")
        debugLabel->PlotterFrame.setClassName("flex items-center mt-3 cursor-pointer")

        let debugCheckbox = PlotterFrame.createElement("input")
        debugCheckbox->PlotterFrame.setAttribute("type", "checkbox")
        debugCheckbox->PlotterFrame.setAttribute("id", "debug-grid")
        debugCheckbox->PlotterFrame.setClassName("mr-2")

        debugCheckbox->PlotterFrame.addEventListener("change", () => {
          showDebugGrid := !showDebugGrid.contents
          redrawTiling()
        })

        debugLabel->PlotterFrame.appendChild(debugCheckbox)

        let debugText = PlotterFrame.createElement("span")
        debugText->PlotterFrame.setTextContent("Show Debug Grid (red)")
        debugText->PlotterFrame.setClassName("text-sm text-zinc-300")
        debugLabel->PlotterFrame.appendChild(debugText)

        container->PlotterFrame.appendChild(debugLabel)

        // Create hint label
        let hintLabel = PlotterFrame.createElement("p")
        hintLabel->PlotterFrame.setTextContent("Click canvas to regenerate pattern")
        hintLabel->PlotterFrame.setClassName("text-xs text-zinc-400 mt-3 italic")
        container->PlotterFrame.appendChild(hintLabel)

        Console.log("Tiling controls created")
      }
    }

    // Add click handler to canvas
    let canvas = p->P5.canvas
    canvas->PlotterFrame.addEventListener("click", () => {
      // Change random seed and redraw directly
      switch p5Instance.contents {
      | Some(p) => {
          p->P5.randomSeed(Js.Date.now())
          redrawTiling() // Directly redraw, no loop
        }
      | None => ()
      }
    })
  }
}

// Enhanced draw with controls setup
let drawWithControls = (p: P5.t, paper: PlotterFrame.paperSize) => {
  setupControls(p)
  draw(p, paper)
}

// Create the sketch
let createSketch = PlotterFrame.createPlotterSketch(drawWithControls)
