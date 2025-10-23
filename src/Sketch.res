// Main p5.js sketch

// Helper to set setup function
@set external setSetup: (P5.t, unit => unit) => unit = "setup"

// Helper to set draw function
@set external setDraw: (P5.t, unit => unit) => unit = "draw"

// Paper size definitions in pixels (at 96 DPI for screen display)
type paperSize = {
  width: int,
  height: int,
}

let getPaperSize = (size: string): paperSize => {
  switch size {
  | "A4" => {width: 794, height: 1123} // 210mm × 297mm
  | "A3" => {width: 1123, height: 1587} // 297mm × 420mm
  | "A5" => {width: 559, height: 794} // 148mm × 210mm
  | "Letter" => {width: 816, height: 1056} // 8.5in × 11in
  | "Legal" => {width: 816, height: 1344} // 8.5in × 14in
  | "Tabloid" => {width: 1056, height: 1632} // 11in × 17in
  | "Square" => {width: 1134, height: 1134} // 300mm × 300mm
  | _ => {width: 794, height: 1123} // Default to A4
  }
}

// DOM bindings for the paper size selector
@val @scope("document")
external getElementById: string => Js.Nullable.t<Dom.element> = "getElementById"

@get external value: Dom.element => string = "value"

@send
external addEventListener: (Dom.element, string, unit => unit) => unit = "addEventListener"

// Sketch function that defines setup and draw
let sketch = (p: P5.t) => {
  // Current paper size state
  let currentSize = ref(getPaperSize("A4"))

  // Function to update canvas size
  let updateCanvasSize = () => {
    let selector = getElementById("paper-size")
    switch selector->Js.Nullable.toOption {
    | Some(element) => {
        let size = element->value
        currentSize := getPaperSize(size)
        p->P5.resizeCanvas(currentSize.contents.width, currentSize.contents.height)
        p->P5.background(255) // White background for paper
      }
    | None => ()
    }
  }

  // Setup - called once at the start
  p->setSetup(() => {
    p->P5.createCanvas(currentSize.contents.width, currentSize.contents.height)
    p->P5.background(255) // White background for paper

    // Add event listener to paper size selector
    let selector = getElementById("paper-size")
    switch selector->Js.Nullable.toOption {
    | Some(element) => element->addEventListener("change", updateCanvasSize)
    | None => ()
    }
  })

  // Draw - runs every frame
  p->setDraw(() => {
    // White background for paper
    p->P5.background(255)

    // Draw a border to show paper edge
    p->P5.noFill
    p->P5.stroke(0)
    p->P5.strokeWeight(2)
    p->P5.rect(
      10.0,
      10.0,
      (currentSize.contents.width - 20)->Belt.Int.toFloat,
      (currentSize.contents.height - 20)->Belt.Int.toFloat,
    )

    // Draw some example plotter art
    p->P5.stroke3(0, 0, 0)
    p->P5.strokeWeight(1)
    p->P5.noFill

    // Draw concentric circles in the center
    let centerX = currentSize.contents.width->Belt.Int.toFloat /. 2.0
    let centerY = currentSize.contents.height->Belt.Int.toFloat /. 2.0
    let maxRadius = Js.Math.min_float(centerX, centerY) -. 50.0

    let numCircles = 20
    for i in 1 to numCircles {
      let radius = maxRadius *. Belt.Int.toFloat(i) /. Belt.Int.toFloat(numCircles)
      p->P5.circle(centerX, centerY, radius *. 2.0)
    }

    // Draw animated line art based on mouse position
    if p->P5.mouseX > 0.0 && p->P5.mouseY > 0.0 {
      p->P5.stroke3(100, 150, 255)
      p->P5.strokeWeight(1)
      p->P5.line(centerX, centerY, p->P5.mouseX, p->P5.mouseY)
      p->P5.circle(p->P5.mouseX, p->P5.mouseY, 20.0)
    }
  })
}

// Access global p5 constructor
@val external p5: 'a = "p5"

// Create the sketch instance using global p5
let _ = %raw("new p5(sketch)")
