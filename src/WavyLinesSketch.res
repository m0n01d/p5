// Wavy Lines Sketch - horizontal sine waves pointing toward center

// Sketch state
let numLinesRef = ref(12)
let amplitudeRef = ref(20.0)

let draw = (p: P5.t, paper: PlotterFrame.paperSize) => {
  let numLines = numLinesRef.contents
  let amplitude = amplitudeRef.contents

  // Calculate center Y position
  let centerY = paper.height->Int.toFloat /. 2.0

  // Spacing between lines
  let spacing = paper.height->Int.toFloat /. (numLines->Int.toFloat +. 1.0)

  // Draw each wavy line
  for i in 1 to numLines {
    let y = spacing *. i->Int.toFloat

    // Determine if this line is above or below center
    // Above center: troughs point down (toward center)
    // Below center: peaks point up (toward center)
    let phaseShift = if y < centerY {
      Js.Math._PI  // Invert the wave
    } else {
      0.0
    }

    // Draw the wavy line
    p->P5.noFill
    p->P5.stroke(0)
    p->P5.strokeWeight(2)

    p->P5.push

    // Use beginShape
    p->P5.beginShape

    // Generate points along the wave
    let steps = 200
    for step in 0 to steps {
      let t = step->Int.toFloat /. steps->Int.toFloat
      let x = t *. paper.width->Int.toFloat

      // Calculate sine wave offset
      let frequency = 4.0  // Number of complete waves across the width
      let waveOffset = Js.Math.sin(t *. frequency *. 2.0 *. Js.Math._PI +. phaseShift) *. amplitude

      p->P5.vertex(x, y +. waveOffset)
    }

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

      Console.log("Wavy lines controls created")
    }
  }
}

// Create the sketch
let createSketch = () => {
  createControls()
  PlotterFrame.createPlotterSketch(draw)()
}
