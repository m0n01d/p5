// Shared Plotter Frame - provides paper size controls and plotter settings for all sketches

// Paper size definitions in pixels (at 96 DPI for screen display)
type paperSize = {
  width: int,
  height: int,
  widthMm: float,
  heightMm: float,
}

// Convert mm to pixels at 96 DPI (3.7795275591 pixels per mm)
let mmToPixels = (mm: float): int => {
  (mm *. 3.7795275591)->Float.toInt
}

let getPaperSize = (size: string): paperSize => {
  switch size {
  | "A4" => {width: 794, height: 1123, widthMm: 210.0, heightMm: 297.0}
  | "A3" => {width: 1123, height: 1587, widthMm: 297.0, heightMm: 420.0}
  | "A5" => {width: 559, height: 794, widthMm: 148.0, heightMm: 210.0}
  | "Letter" => {width: 816, height: 1056, widthMm: 215.9, heightMm: 279.4}
  | "Legal" => {width: 816, height: 1344, widthMm: 215.9, heightMm: 355.6}
  | "Tabloid" => {width: 1056, height: 1632, widthMm: 279.4, heightMm: 431.8}
  | "Square" => {width: 1134, height: 1134, widthMm: 300.0, heightMm: 300.0}
  | _ => {width: 794, height: 1123, widthMm: 210.0, heightMm: 297.0} // Default to A4
  }
}

let customPaperSize = (widthMm: float, heightMm: float): paperSize => {
  {
    width: mmToPixels(widthMm),
    height: mmToPixels(heightMm),
    widthMm,
    heightMm,
  }
}

// DOM bindings for the paper size selector
@val @scope("document")
external getElementById: string => Js.Nullable.t<Dom.element> = "getElementById"

@get external value: Dom.element => string = "value"

@send
external addEventListener: (Dom.element, string, unit => unit) => unit = "addEventListener"

// Canvas export bindings
@send external toDataURL: (Dom.element, string, float) => string = "toDataURL"

@val @scope("document")
external createElement: string => Dom.element = "createElement"

@set external setHref: (Dom.element, string) => unit = "href"
@set external setDownload: (Dom.element, string) => unit = "download"
@get external style: Dom.element => {..} = "style"
@send external click: Dom.element => unit = "click"
@send external appendChild: (Dom.element, Dom.element) => unit = "appendChild"
@send external removeChild: (Dom.element, Dom.element) => unit = "removeChild"
@val @scope("document") external body: Dom.element = "body"

// Type for sketch drawing function
type drawFn = (P5.t, paperSize) => unit

// Global current paper size (for export)
let currentPaperSize = ref(getPaperSize("A4"))

// Get current paper size (for export)
let getCurrentPaperSize = () => currentPaperSize.contents

// Create a plotter-framed sketch
let createPlotterSketch = (drawFn: drawFn) => {
  () => {
    (p: P5.t) => {
      // Use shared paper size state
      let currentSize = currentPaperSize

      // Function to update canvas size
      let updateCanvasSize = () => {
        let selector = getElementById("paper-size")
        switch selector->Js.Nullable.toOption {
        | Some(element) => {
            let size = element->value

            // Show/hide custom size inputs
            let customDiv = getElementById("custom-size")
            switch customDiv->Js.Nullable.toOption {
            | Some(div) => {
                let divStyle = div->style
                if size == "Custom" {
                  divStyle["display"] = "flex"
                } else {
                  divStyle["display"] = "none"
                  currentSize := getPaperSize(size)
                  p->P5.resizeCanvas(currentSize.contents.width, currentSize.contents.height)
                  p->P5.background(255)
                }
              }
            | None => ()
            }
          }
        | None => ()
        }
      }

      // Function to apply custom size
      let applyCustomSize = () => {
        let widthInput = getElementById("custom-width")
        let heightInput = getElementById("custom-height")

        switch (widthInput->Js.Nullable.toOption, heightInput->Js.Nullable.toOption) {
        | (Some(wInput), Some(hInput)) => {
            let widthMm = wInput->value->Float.fromString->Option.getOr(210.0)
            let heightMm = hInput->value->Float.fromString->Option.getOr(297.0)
            currentSize := customPaperSize(widthMm, heightMm)
            p->P5.resizeCanvas(currentSize.contents.width, currentSize.contents.height)
            p->P5.background(255)
          }
        | _ => ()
        }
      }


      // Setup - called once at the start
      p->P5.setSetup(() => {
        let canvas = p->P5.createCanvas(currentSize.contents.width, currentSize.contents.height)
        canvas->ignore
        p->P5.background(255) // White background for paper

        // Add event listener to paper size selector
        let selector = getElementById("paper-size")
        switch selector->Js.Nullable.toOption {
        | Some(element) => element->addEventListener("change", updateCanvasSize)
        | None => ()
        }

        // Add event listener to custom size apply button
        let applyBtn = getElementById("apply-custom")
        switch applyBtn->Js.Nullable.toOption {
        | Some(element) => element->addEventListener("click", applyCustomSize)
        | None => ()
        }
      })

      // Draw - runs every frame
      p->P5.setDraw(() => {
        // White background for paper
        p->P5.background(255)

        // Draw a border to show paper edge
        p->P5.noFill
        p->P5.stroke(0)
        p->P5.strokeWeight(2)
        p->P5.rect(
          10.0,
          10.0,
          (currentSize.contents.width - 20)->Int.toFloat,
          (currentSize.contents.height - 20)->Int.toFloat,
        )

        // Call the custom draw function with current paper size
        drawFn(p, currentSize.contents)
      })
    }
  }
}
