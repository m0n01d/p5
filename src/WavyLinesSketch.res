// Wavy Lines Sketch - horizontal sine waves pointing toward center

// Sketch state
let numLinesRef = ref(12)
let amplitudeRef = ref(20.0)
let gapSizeRef = ref(0.33) // Middle gap as fraction of height (0.33 = 1/3)
let frequencyRef = ref(4.0) // Number of complete waves across the width

let draw = (p: P5.t, paper: PlotterFrame.paperSize) => {
  let numLines = numLinesRef.contents
  let amplitude = amplitudeRef.contents
  let gapSize = gapSizeRef.contents
  let frequency = frequencyRef.contents

  // Calculate center position
  let centerX = paper.width->Int.toFloat /. 2.0
  let centerY = paper.height->Int.toFloat /. 2.0

  // Calculate gap boundaries
  let gapHeight = paper.height->Int.toFloat *. gapSize
  let gapTop = centerY -. gapHeight /. 2.0
  let gapBottom = centerY +. gapHeight /. 2.0

  // Available space for lines (above and below gap)
  let topSpace = gapTop
  let bottomSpace = paper.height->Int.toFloat -. gapBottom

  // Half lines go above, half below
  let linesPerSide = numLines / 2

  // Draw lines above the gap and mirror them below
  for i in 1 to linesPerSide {
    let spacing = topSpace /. (linesPerSide->Int.toFloat +. 1.0)
    let baseY = spacing *. i->Int.toFloat

    // Store points for the top line so we can mirror them
    let topPoints = []

    // Draw the wavy line above center
    p->P5.noFill
    p->P5.stroke(0)
    p->P5.strokeWeight(2)

    p->P5.push
    p->P5.beginShape

    // Generate points along the wave
    let steps = 200
    for step in 0 to steps {
      let t = step->Int.toFloat /. steps->Int.toFloat
      let x = t *. paper.width->Int.toFloat

      // Calculate sine wave offset
      let sineWave = Js.Math.sin(t *. frequency *. 2.0 *. Js.Math._PI)

      // Base wave offset (vertical displacement from the line)
      let waveOffset = sineWave *. amplitude

      // Calculate vector from this point to center
      let dx = centerX -. x
      let dy = centerY -. baseY

      // Calculate angle to center
      let angleToCenter = Js.Math.atan2(~y=dy, ~x=dx, ())

      // When at a peak (sineWave != 0), offset the point toward the center
      // The offset is proportional to how much of a peak/trough we're at
      let pullStrength = 0.3  // How much peaks pull toward center
      let xPull = sineWave *. amplitude *. Js.Math.cos(angleToCenter) *. pullStrength
      let yPull = sineWave *. amplitude *. Js.Math.sin(angleToCenter) *. pullStrength

      // Final position: base position + wave offset (perpendicular) + pull toward center
      let finalX = x +. xPull
      let finalY = baseY +. waveOffset +. yPull

      // Store the point for mirroring
      topPoints->Array.push((finalX, finalY))->ignore

      p->P5.vertex(finalX, finalY)
    }

    p->P5.endShape
    p->P5.pop

    // Now draw the mirrored line below center
    p->P5.push
    p->P5.beginShape

    topPoints->Array.forEach(((x, y)) => {
      // Mirror across the center Y
      let mirroredY = centerY +. (centerY -. y)
      p->P5.vertex(x, mirroredY)
    })

    p->P5.endShape
    p->P5.pop
  }
}

// Create controls
let createControls = () => {
  open PlotterFrame

  let container = getElementById("sketch-specific-controls")
  switch container->Js.Nullable.toOption {
  | None => Console.log("Sketch controls container not found")
  | Some(element) => {
      element->setInnerHTML("")
      element->setClassName("space-y-4")

      // Number of lines control
      let linesLabel = createElement("label")
      linesLabel->setTextContent("Number of Lines")
      linesLabel->setAttribute("for", "num-lines")
      linesLabel->setClassName("block text-sm font-medium text-zinc-300 mb-1")
      element->appendChild(linesLabel)

      let linesInput = createElement("input")
      linesInput->setAttribute("type", "range")
      linesInput->setAttribute("id", "num-lines")
      linesInput->setAttribute("min", "3")
      linesInput->setAttribute("max", "30")
      linesInput->setAttribute("value", "12")
      linesInput->setClassName("w-full")
      element->appendChild(linesInput)

      let linesValue = createElement("div")
      linesValue->setAttribute("id", "num-lines-value")
      linesValue->setTextContent("12")
      linesValue->setClassName("text-sm text-zinc-400")
      element->appendChild(linesValue)

      linesInput->addEventListener("input", () => {
        let value = linesInput->value->Int.fromString->Option.getOr(12)
        numLinesRef := value
        linesValue->setTextContent(value->Int.toString)
      })

      // Amplitude control
      let ampLabel = createElement("label")
      ampLabel->setTextContent("Wave Amplitude")
      ampLabel->setAttribute("for", "amplitude")
      ampLabel->setClassName("block text-sm font-medium text-zinc-300 mb-1 mt-4")
      element->appendChild(ampLabel)

      let ampInput = createElement("input")
      ampInput->setAttribute("type", "range")
      ampInput->setAttribute("id", "amplitude")
      ampInput->setAttribute("min", "5")
      ampInput->setAttribute("max", "100")
      ampInput->setAttribute("value", "20")
      ampInput->setClassName("w-full")
      element->appendChild(ampInput)

      let ampValue = createElement("div")
      ampValue->setAttribute("id", "amplitude-value")
      ampValue->setTextContent("20")
      ampValue->setClassName("text-sm text-zinc-400")
      element->appendChild(ampValue)

      ampInput->addEventListener("input", () => {
        let value = ampInput->value->Float.fromString->Option.getOr(20.0)
        amplitudeRef := value
        ampValue->setTextContent(value->Float.toString)
      })

      // Gap size control
      let gapLabel = createElement("label")
      gapLabel->setTextContent("Center Gap Size (%)")
      gapLabel->setAttribute("for", "gap-size")
      gapLabel->setClassName("block text-sm font-medium text-zinc-300 mb-1 mt-4")
      element->appendChild(gapLabel)

      let gapInput = createElement("input")
      gapInput->setAttribute("type", "range")
      gapInput->setAttribute("id", "gap-size")
      gapInput->setAttribute("min", "0")
      gapInput->setAttribute("max", "50")
      gapInput->setAttribute("value", "33")
      gapInput->setClassName("w-full")
      element->appendChild(gapInput)

      let gapValue = createElement("div")
      gapValue->setAttribute("id", "gap-size-value")
      gapValue->setTextContent("33%")
      gapValue->setClassName("text-sm text-zinc-400")
      element->appendChild(gapValue)

      gapInput->addEventListener("input", () => {
        let value = gapInput->value->Float.fromString->Option.getOr(33.0)
        gapSizeRef := value /. 100.0  // Convert percentage to fraction
        gapValue->setTextContent(value->Float.toString ++ "%")
      })

      // Frequency control
      let freqLabel = createElement("label")
      freqLabel->setTextContent("Wave Frequency")
      freqLabel->setAttribute("for", "frequency")
      freqLabel->setClassName("block text-sm font-medium text-zinc-300 mb-1 mt-4")
      element->appendChild(freqLabel)

      let freqInput = createElement("input")
      freqInput->setAttribute("type", "range")
      freqInput->setAttribute("id", "frequency")
      freqInput->setAttribute("min", "1")
      freqInput->setAttribute("max", "20")
      freqInput->setAttribute("value", "4")
      freqInput->setClassName("w-full")
      element->appendChild(freqInput)

      let freqValue = createElement("div")
      freqValue->setAttribute("id", "frequency-value")
      freqValue->setTextContent("4")
      freqValue->setClassName("text-sm text-zinc-400")
      element->appendChild(freqValue)

      freqInput->addEventListener("input", () => {
        let value = freqInput->value->Float.fromString->Option.getOr(4.0)
        frequencyRef := value
        freqValue->setTextContent(value->Float.toString)
      })

      Console.log("Wavy lines controls created")
    }
  }
}

// Create the sketch
let createSketch = () => {
  createControls()
  PlotterFrame.createPlotterSketch(draw)()
}
