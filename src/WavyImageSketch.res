// Wavy Image Sketch - Convert image to wavy line tiles based on brightness

// Tile size in pixels
let tileSize = ref(20)

// Line styling parameters
let lineThickness = ref(2.0)
let waveAmplitude = ref(0.2) // Relative to tile size
let waveFrequency = ref(3.0) // Number of waves per line
let lineSteps = ref(30) // Smoothness of curves

// Base image URL (without size parameters)
let imageBaseUrl = ref("https://placecats.com")

// Loaded image
let loadedImage: ref<option<P5.image>> = ref(None)

// Store p5 instance
let p5Instance: ref<option<P5.t>> = ref(None)
let paperSize: ref<option<PlotterFrame.paperSize>> = ref(None)

// Draw a wavy vertical line in a tile
let drawWavyVertical = (p: P5.t, x: float, y: float, size: float) => {
  let steps = lineSteps.contents
  let amplitude = size *. waveAmplitude.contents
  let centerX = x +. size /. 2.0

  for i in 0 to steps {
    if i > 0 {
      let t = Float.fromInt(i) /. Float.fromInt(steps)
      let prevT = Float.fromInt(i - 1) /. Float.fromInt(steps)

      let yPos = y +. t *. size
      let prevY = y +. prevT *. size

      let wave = Js.Math.sin(t *. 2.0 *. Js.Math._PI *. waveFrequency.contents) *. amplitude
      let prevWave = Js.Math.sin(prevT *. 2.0 *. Js.Math._PI *. waveFrequency.contents) *. amplitude

      let xPos = centerX +. wave
      let prevX = centerX +. prevWave

      p->P5.line(prevX, prevY, xPos, yPos)
    }
  }
}

// Draw a wavy horizontal line in a tile
let drawWavyHorizontal = (p: P5.t, x: float, y: float, size: float) => {
  let steps = lineSteps.contents
  let amplitude = size *. waveAmplitude.contents
  let centerY = y +. size /. 2.0

  for i in 0 to steps {
    if i > 0 {
      let t = Float.fromInt(i) /. Float.fromInt(steps)
      let prevT = Float.fromInt(i - 1) /. Float.fromInt(steps)

      let xPos = x +. t *. size
      let prevX = x +. prevT *. size

      let wave = Js.Math.sin(t *. 2.0 *. Js.Math._PI *. waveFrequency.contents) *. amplitude
      let prevWave = Js.Math.sin(prevT *. 2.0 *. Js.Math._PI *. waveFrequency.contents) *. amplitude

      let yPos = centerY +. wave
      let prevY = centerY +. prevWave

      p->P5.line(prevX, prevY, xPos, yPos)
    }
  }
}

// Draw a diagonal line in a tile
let drawDiagonal = (p: P5.t, x: float, y: float, size: float, direction: bool) => {
  if direction {
    // Top-left to bottom-right
    p->P5.line(x, y, x +. size, y +. size)
  } else {
    // Top-right to bottom-left
    p->P5.line(x +. size, y, x, y +. size)
  }
}

// Draw a tile based on brightness (0 = black, 255 = white)
let drawTileForBrightness = (p: P5.t, x: float, y: float, size: float, brightness: float) => {
  let gridX = (x /. size)->Float.toInt
  let gridY = (y /. size)->Float.toInt

  // Very dark (0-50): dense crosshatch with diagonals
  if brightness < 50.0 {
    drawWavyVertical(p, x, y, size)
    drawWavyHorizontal(p, x, y, size)
    drawDiagonal(p, x, y, size, true)
  } else if brightness < 100.0 {
    // Dark (50-100): wavy crosshatch
    drawWavyVertical(p, x, y, size)
    drawWavyHorizontal(p, x, y, size)
  } else if brightness < 150.0 {
    // Medium-dark (100-150): alternating wavy lines
    if mod(gridX + gridY, 2) == 0 {
      drawWavyVertical(p, x, y, size)
    } else {
      drawWavyHorizontal(p, x, y, size)
    }
  } else if brightness < 200.0 {
    // Medium-light (150-200): sparse diagonals
    if mod(gridX + gridY, 3) == 0 {
      drawDiagonal(p, x, y, size, mod(gridX, 2) == 0)
    }
  }
  // Very light (200-255): blank (no lines)
}

// Draw the image using wavy tiles
let draw = (p: P5.t, paper: PlotterFrame.paperSize) => {
  p5Instance := Some(p)
  paperSize := Some(paper)

  p->P5.background(255)
  p->P5.stroke(0)
  p->P5.strokeWeight(lineThickness.contents->Float.toInt)
  p->P5.noFill

  switch loadedImage.contents {
  | None => {
      // Show loading message
      p->P5.stroke(200)
      let paperWidth = paper.width->Int.toFloat
      let paperHeight = paper.height->Int.toFloat
      p->P5.line(
        paperWidth /. 2.0 -. 50.0,
        paperHeight /. 2.0,
        paperWidth /. 2.0 +. 50.0,
        paperHeight /. 2.0,
      )
    }
  | Some(img) => {
      let paperWidth = paper.width->Int.toFloat
      let paperHeight = paper.height->Int.toFloat
      let tileSizeFloat = tileSize.contents->Int.toFloat

      let cols = (paperWidth /. tileSizeFloat)->Float.toInt
      let rows = (paperHeight /. tileSizeFloat)->Float.toInt

      let imgWidth = img->P5.imageWidth->Int.toFloat
      let imgHeight = img->P5.imageHeight->Int.toFloat

      // Draw tiles
      for row in 0 to rows - 1 {
        for col in 0 to cols - 1 {
          let x = col->Int.toFloat *. tileSizeFloat
          let y = row->Int.toFloat *. tileSizeFloat

          // Sample the image at this tile's position
          let imgX = (col->Int.toFloat /. cols->Int.toFloat *. imgWidth)->Float.toInt
          let imgY = (row->Int.toFloat /. rows->Int.toFloat *. imgHeight)->Float.toInt

          // Get pixel color and calculate brightness
          let pixel = img->P5.imageGet(imgX, imgY)
          let brightness = p->P5.brightness(pixel)

          // Draw appropriate tile
          drawTileForBrightness(p, x, y, tileSizeFloat, brightness)
        }
      }
    }
  }

  p->P5.noLoop
}

// Redraw function
let redraw = () => {
  switch p5Instance.contents {
  | Some(p) => p->P5.loop
  | None => ()
  }
}

// Load image from URL and update preview
let loadImageFromUrl = (p: P5.t, url: string) => {
  Console.log(`Loading image from: ${url}`)

  // Update preview thumbnail with the same URL
  switch PlotterFrame.getElementById("image-preview")->Js.Nullable.toOption {
  | Some(preview) => preview->PlotterFrame.setAttribute("src", url)
  | None => ()
  }

  p->P5.loadImage(url, img => {
    loadedImage := Some(img)
    Console.log("Image loaded successfully")
    redraw()
  })
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
        // Tile size control
        let tileSizeLabel = PlotterFrame.createElement("label")
        tileSizeLabel->PlotterFrame.setTextContent("Tile Size (pixels)")
        tileSizeLabel->PlotterFrame.setAttribute("for", "tile-size")
        tileSizeLabel->PlotterFrame.setClassName(
          "block text-sm font-medium text-zinc-300 mb-1 mt-3",
        )
        container->PlotterFrame.appendChild(tileSizeLabel)

        let tileSizeInput = PlotterFrame.createElement("input")
        tileSizeInput->PlotterFrame.setAttribute("type", "number")
        tileSizeInput->PlotterFrame.setAttribute("id", "tile-size")
        tileSizeInput->PlotterFrame.setValue("20")
        tileSizeInput->PlotterFrame.setAttribute("min", "5")
        tileSizeInput->PlotterFrame.setAttribute("max", "100")
        tileSizeInput->PlotterFrame.setAttribute("step", "5")
        tileSizeInput->PlotterFrame.setClassName(
          "w-full px-3 py-2 bg-zinc-700 border border-zinc-600 rounded-md text-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500",
        )

        tileSizeInput->PlotterFrame.addEventListener("input", () => {
          let value = tileSizeInput->PlotterFrame.value->Float.fromString->Option.getOr(15.0)
          tileSize := value->Float.toInt
          redraw()
        })

        container->PlotterFrame.appendChild(tileSizeInput)

        // Line thickness control
        let thicknessLabel = PlotterFrame.createElement("label")
        thicknessLabel->PlotterFrame.setTextContent("Line Thickness")
        thicknessLabel->PlotterFrame.setAttribute("for", "line-thickness")
        thicknessLabel->PlotterFrame.setClassName(
          "block text-sm font-medium text-zinc-300 mb-1 mt-3",
        )
        container->PlotterFrame.appendChild(thicknessLabel)

        let thicknessInput = PlotterFrame.createElement("input")
        thicknessInput->PlotterFrame.setAttribute("type", "number")
        thicknessInput->PlotterFrame.setAttribute("id", "line-thickness")
        thicknessInput->PlotterFrame.setValue("2")
        thicknessInput->PlotterFrame.setAttribute("min", "1")
        thicknessInput->PlotterFrame.setAttribute("max", "5")
        thicknessInput->PlotterFrame.setAttribute("step", "0.5")
        thicknessInput->PlotterFrame.setClassName(
          "w-full px-3 py-2 bg-zinc-700 border border-zinc-600 rounded-md text-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500",
        )

        thicknessInput->PlotterFrame.addEventListener("input", () => {
          let value = thicknessInput->PlotterFrame.value->Float.fromString->Option.getOr(2.0)
          lineThickness := value
          redraw()
        })

        container->PlotterFrame.appendChild(thicknessInput)

        // Wave amplitude control
        let amplitudeLabel = PlotterFrame.createElement("label")
        amplitudeLabel->PlotterFrame.setTextContent("Wave Amplitude")
        amplitudeLabel->PlotterFrame.setAttribute("for", "wave-amplitude")
        amplitudeLabel->PlotterFrame.setClassName(
          "block text-sm font-medium text-zinc-300 mb-1 mt-3",
        )
        container->PlotterFrame.appendChild(amplitudeLabel)

        let amplitudeInput = PlotterFrame.createElement("input")
        amplitudeInput->PlotterFrame.setAttribute("type", "number")
        amplitudeInput->PlotterFrame.setAttribute("id", "wave-amplitude")
        amplitudeInput->PlotterFrame.setValue("0.2")
        amplitudeInput->PlotterFrame.setAttribute("min", "0")
        amplitudeInput->PlotterFrame.setAttribute("max", "0.5")
        amplitudeInput->PlotterFrame.setAttribute("step", "0.05")
        amplitudeInput->PlotterFrame.setClassName(
          "w-full px-3 py-2 bg-zinc-700 border border-zinc-600 rounded-md text-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500",
        )

        amplitudeInput->PlotterFrame.addEventListener("input", () => {
          let value = amplitudeInput->PlotterFrame.value->Float.fromString->Option.getOr(0.2)
          waveAmplitude := value
          redraw()
        })

        container->PlotterFrame.appendChild(amplitudeInput)

        // Wave frequency control
        let frequencyLabel = PlotterFrame.createElement("label")
        frequencyLabel->PlotterFrame.setTextContent("Wave Frequency")
        frequencyLabel->PlotterFrame.setAttribute("for", "wave-frequency")
        frequencyLabel->PlotterFrame.setClassName(
          "block text-sm font-medium text-zinc-300 mb-1 mt-3",
        )
        container->PlotterFrame.appendChild(frequencyLabel)

        let frequencyInput = PlotterFrame.createElement("input")
        frequencyInput->PlotterFrame.setAttribute("type", "number")
        frequencyInput->PlotterFrame.setAttribute("id", "wave-frequency")
        frequencyInput->PlotterFrame.setValue("3")
        frequencyInput->PlotterFrame.setAttribute("min", "1")
        frequencyInput->PlotterFrame.setAttribute("max", "10")
        frequencyInput->PlotterFrame.setAttribute("step", "0.5")
        frequencyInput->PlotterFrame.setClassName(
          "w-full px-3 py-2 bg-zinc-700 border border-zinc-600 rounded-md text-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500",
        )

        frequencyInput->PlotterFrame.addEventListener("input", () => {
          let value = frequencyInput->PlotterFrame.value->Float.fromString->Option.getOr(3.0)
          waveFrequency := value
          redraw()
        })

        container->PlotterFrame.appendChild(frequencyInput)

        // Image preview
        let previewLabel = PlotterFrame.createElement("label")
        previewLabel->PlotterFrame.setTextContent("Image Preview")
        previewLabel->PlotterFrame.setClassName("block text-sm font-medium text-zinc-300 mb-1 mt-3")
        container->PlotterFrame.appendChild(previewLabel)

        let previewImg = PlotterFrame.createElement("img")
        previewImg->PlotterFrame.setAttribute("id", "image-preview")
        // Don't set src here - will be set AFTER p5 loads the image
        previewImg->PlotterFrame.setStyle("width", "100%")
        previewImg->PlotterFrame.setStyle("border", "1px solid #52525b")
        previewImg->PlotterFrame.setStyle("border-radius", "4px")
        previewImg->PlotterFrame.setStyle("margin-bottom", "12px")
        container->PlotterFrame.appendChild(previewImg)

        // Image URL control
        let urlLabel = PlotterFrame.createElement("label")
        urlLabel->PlotterFrame.setTextContent("Image URL")
        urlLabel->PlotterFrame.setAttribute("for", "image-url")
        urlLabel->PlotterFrame.setClassName("block text-sm font-medium text-zinc-300 mb-1 mt-3")
        container->PlotterFrame.appendChild(urlLabel)

        let urlInput = PlotterFrame.createElement("input")
        urlInput->PlotterFrame.setAttribute("type", "text")
        urlInput->PlotterFrame.setAttribute("id", "image-url")
        // Don't set value yet - will be set when URL is built with paper dimensions
        urlInput->PlotterFrame.setClassName(
          "w-full px-3 py-2 bg-zinc-700 border border-zinc-600 rounded-md text-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500",
        )

        container->PlotterFrame.appendChild(urlInput)

        // Load button
        let loadButton = PlotterFrame.createElement("button")
        loadButton->PlotterFrame.setTextContent("Load Image")
        loadButton->PlotterFrame.setClassName(
          "w-full mt-2 px-3 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500",
        )

        loadButton->PlotterFrame.addEventListener("click", () => {
          let url = urlInput->PlotterFrame.value

          // Try to extract base URL (everything before the size parameters)
          // For URLs like "https://placecats.com/millie/300/150", extract "https://placecats.com/millie"
          let urlParts = url->Js.String2.split("/")
          Console.log(urlParts)
          if urlParts->Array.length >= 2 {
            // Remove the last two parts (width/height) if they look like numbers
            let lastPart = urlParts->Array.get(urlParts->Array.length - 1)->Option.getOr("")
            let secondLastPart = urlParts->Array.get(urlParts->Array.length - 2)->Option.getOr("")

            // Check if both are numeric
            let lastIsNumber = lastPart->Float.fromString->Option.isSome
            let secondLastIsNumber = secondLastPart->Float.fromString->Option.isSome

            if lastIsNumber && secondLastIsNumber {
              // Remove last two parts to get base URL
              let baseUrlParts = urlParts->Array.slice(~start=0, ~end=urlParts->Array.length - 2)
              let baseUrl = baseUrlParts->Array.join("/")
              imageBaseUrl := baseUrl
              Console.log(`Updated base URL to: ${baseUrl}`)
            } else {
              // Use the full URL as base
              imageBaseUrl := url
            }
          }

          switch p5Instance.contents {
          | Some(p) => loadImageFromUrl(p, url)
          | None => ()
          }
        })

        container->PlotterFrame.appendChild(loadButton)

        Console.log("Wavy image controls created")
      }
    }
  }
}

// Build image URL with paper size dimensions (using CORS proxy)
let buildImageUrl = (baseUrl: string, paper: PlotterFrame.paperSize) => {
  let width = (0.25 *. Int.toFloat(paper.width))->Js.Math.ceil_int->Int.toString
  let height = (0.25 *. Int.toFloat(paper.height))->Js.Math.ceil_int->Int.toString
  let imageUrl = `${baseUrl}/${width}/${height}`
  // Use CORS proxy to avoid CORS errors
  `https://corsproxy.io/?${imageUrl}`
}

// Store the last paper size to detect changes
let lastPaperSize: ref<option<PlotterFrame.paperSize>> = ref(None)

// Enhanced draw with controls setup
let drawWithControls = (p: P5.t, paper: PlotterFrame.paperSize) => {
  // Setup controls first
  setupControls(p)

  // Check if paper size changed
  let paperSizeChanged = switch lastPaperSize.contents {
  | None => true // Trigger on first run to load with correct dimensions
  | Some(lastPaper) => lastPaper.width != paper.width || lastPaper.height != paper.height
  }

  if paperSizeChanged {
    // Build URL with paper dimensions
    let newUrl = buildImageUrl(imageBaseUrl.contents, paper)

    // Update the URL input field
    switch PlotterFrame.getElementById("image-url")->Js.Nullable.toOption {
    | Some(input) => input->PlotterFrame.setValue(newUrl)
    | None => ()
    }

    // Load the image ONCE - preview will be updated in the callback
    loadImageFromUrl(p, newUrl)

    // Store current paper size
    lastPaperSize := Some(paper)
  }

  draw(p, paper)
}

// Create the sketch
let createSketch = PlotterFrame.createPlotterSketch(drawWithControls)
