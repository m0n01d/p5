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
  // iPhone wallpaper sizes (at actual pixel dimensions)
  | "iPhone 15 Pro Max" => {width: 1290, height: 2796, widthMm: 341.4, heightMm: 739.7}
  | "iPhone 15 Pro" => {width: 1179, height: 2556, widthMm: 311.9, heightMm: 676.3}
  | "iPhone 15 Plus" => {width: 1290, height: 2796, widthMm: 341.4, heightMm: 739.7}
  | "iPhone 15" => {width: 1179, height: 2556, widthMm: 311.9, heightMm: 676.3}
  | "iPhone 14 Pro Max" => {width: 1290, height: 2796, widthMm: 341.4, heightMm: 739.7}
  | "iPhone 14 Pro" => {width: 1179, height: 2556, widthMm: 311.9, heightMm: 676.3}
  | "iPhone 14 Plus" => {width: 1284, height: 2778, widthMm: 339.7, heightMm: 735.0}
  | "iPhone 14" => {width: 1170, height: 2532, widthMm: 309.5, heightMm: 670.0}
  | "iPhone SE" => {width: 750, height: 1334, widthMm: 198.4, heightMm: 353.0}
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

@val @scope("document")
external createElement: string => Dom.element = "createElement"

@get external value: Dom.element => string = "value"
@set external setValue: (Dom.element, string) => unit = "value"
@set external setTextContent: (Dom.element, string) => unit = "textContent"
@set external setClassName: (Dom.element, string) => unit = "className"
@set external setInnerHTML: (Dom.element, string) => unit = "innerHTML"
@send external setAttribute: (Dom.element, string, string) => unit = "setAttribute"
@send external appendChild: (Dom.element, Dom.element) => unit = "appendChild"
@send external querySelector: (Dom.element, string) => Js.Nullable.t<Dom.element> = "querySelector"

@send
external addEventListener: (Dom.element, string, unit => unit) => unit = "addEventListener"

// Style manipulation
let setStyle: (Dom.element, string, string) => unit = %raw(`
  function(element, property, value) {
    element.style[property] = value;
  }
`)

// Timer binding
@val external setTimeout: (unit => unit, int) => float = "setTimeout"

// Canvas export bindings
@send external toDataURL: (Dom.element, string, float) => string = "toDataURL"

@val @scope("document")
external createElement: string => Dom.element = "createElement"

@set external setHref: (Dom.element, string) => unit = "href"
@set external setDownload: (Dom.element, string) => unit = "download"
type cssStyleDeclaration
@get external style: Dom.element => cssStyleDeclaration = "style"
@send external removeProperty: (cssStyleDeclaration, string) => unit = "removeProperty"
@set_index external setStyleProperty: (cssStyleDeclaration, string, string) => unit = ""
@send external click: Dom.element => unit = "click"
@send external appendChild: (Dom.element, Dom.element) => unit = "appendChild"
@send external removeChild: (Dom.element, Dom.element) => unit = "removeChild"
@val @scope("document") external body: Dom.element = "body"

// Type for sketch drawing function
type drawFn = (P5.t, paperSize) => unit

// Global current paper size (for export)
let currentPaperSize = ref(getPaperSize("A4"))
let currentMarginMm = ref(10.0) // Default 10mm margin (bleed/cut area)
let currentPaddingMm = ref(5.0) // Default 5mm padding (additional safe space)

// Get current paper size (for export)
let getCurrentPaperSize = () => currentPaperSize.contents

// Scale canvas to fit within container
let scaleCanvasToFit = (canvas: Dom.element) => {
  %raw(`
    (function(canvas) {
      const container = canvas.parentElement;
      if (!container) return;

      const containerRect = container.getBoundingClientRect();
      const canvasWidth = canvas.width;
      const canvasHeight = canvas.height;

      // Calculate scale to fit both width and height (with some padding)
      const padding = 0; // No padding, use full container
      const availableWidth = containerRect.width - padding;
      const availableHeight = containerRect.height - padding;

      const scaleX = availableWidth / canvasWidth;
      const scaleY = availableHeight / canvasHeight;
      const scale = Math.min(scaleX, scaleY);

      // Set explicit dimensions to scaled size
      canvas.style.width = Math.floor(canvasWidth * scale) + 'px';
      canvas.style.height = Math.floor(canvasHeight * scale) + 'px';
      canvas.style.display = 'block';
    })
  `)(canvas)
}

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
                  divStyle->setStyleProperty("display", "flex")
                } else {
                  divStyle->setStyleProperty("display", "none")
                  currentSize := getPaperSize(size)
                  p->P5.resizeCanvas(currentSize.contents.width, currentSize.contents.height)
                  p->P5.background(255)

                  // Remove inline styles after resize
                  let canvasElement = p->P5.canvas
                  let _ = setTimeout(
                    () => {
                      let canvasStyle = canvasElement->style
                      canvasStyle->removeProperty("width")
                      canvasStyle->removeProperty("height")
                    },
                    100,
                  )
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

            // Remove inline styles after resize
            let canvasElement = p->P5.canvas
            let _ = setTimeout(
              () => {
                let canvasStyle = canvasElement->style
                canvasStyle->removeProperty("width")
                canvasStyle->removeProperty("height")
              },
              100,
            )
          }
        | _ => ()
        }
      }

      // Create margin and padding controls
      let createSpacingControls = () => {
        let controlsDiv = getElementById("paper-settings-controls")
        switch controlsDiv->Js.Nullable.toOption {
        | None => Console.log("Paper settings controls container not found")
        | Some(container) => {
            container->setInnerHTML("")
            container->setClassName("mb-6 space-y-4")

            // Margin label
            let marginLabel = createElement("label")
            marginLabel->setTextContent("Margin (mm) - Bleed/Cut Area")
            marginLabel->setAttribute("for", "margin-size")
            marginLabel->setClassName("block text-sm font-medium text-zinc-300 mb-1")
            container->appendChild(marginLabel)

            // Margin input
            let marginInput = createElement("input")
            marginInput->setAttribute("type", "number")
            marginInput->setAttribute("id", "margin-size")
            marginInput->setValue("10")
            marginInput->setAttribute("min", "0")
            marginInput->setAttribute("max", "50")
            marginInput->setAttribute("step", "1")
            marginInput->setClassName(
              "w-full px-3 py-2 bg-zinc-700 border border-zinc-600 rounded-md text-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500",
            )

            marginInput->addEventListener("input", () => {
              let value = marginInput->value->Float.fromString->Option.getOr(10.0)
              currentMarginMm := value
            })

            container->appendChild(marginInput)

            // Padding label
            let paddingLabel = createElement("label")
            paddingLabel->setTextContent("Padding (mm) - Extra Safe Space")
            paddingLabel->setAttribute("for", "padding-size")
            paddingLabel->setClassName("block text-sm font-medium text-zinc-300 mb-1 mt-3")
            container->appendChild(paddingLabel)

            // Padding input
            let paddingInput = createElement("input")
            paddingInput->setAttribute("type", "number")
            paddingInput->setAttribute("id", "padding-size")
            paddingInput->setValue("5")
            paddingInput->setAttribute("min", "0")
            paddingInput->setAttribute("max", "50")
            paddingInput->setAttribute("step", "1")
            paddingInput->setClassName(
              "w-full px-3 py-2 bg-zinc-700 border border-zinc-600 rounded-md text-white text-sm focus:outline-none focus:ring-2 focus:ring-blue-500",
            )

            paddingInput->addEventListener("input", () => {
              let value = paddingInput->value->Float.fromString->Option.getOr(5.0)
              currentPaddingMm := value
            })

            container->appendChild(paddingInput)

            Console.log("Spacing controls created")
          }
        }
      }

      // Setup - called once at the start
      p->P5.setSetup(() => {
        // Create SVG canvas for vector export support
        let svgRenderer = p->P5._SVG
        let canvas = p->P5.createCanvasSVG(
          currentSize.contents.width,
          currentSize.contents.height,
          svgRenderer,
        )
        p->P5.background(255) // White background for paper

        // Remove inline width/height styles set by p5 to let CSS handle scaling
        let canvasElement = p->P5.canvas
        let canvasStyle = canvasElement->style
        canvasStyle->removeProperty("width")
        canvasStyle->removeProperty("height")

        // Create spacing controls
        createSpacingControls()

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

        // Convert margin and padding from mm to pixels
        let marginPx = currentMarginMm.contents *. 3.7795275591
        let paddingPx = currentPaddingMm.contents *. 3.7795275591
        let totalSpacePx = marginPx +. paddingPx

        // Draw margin border (light gray) - bleed/cut area
        p->P5.noFill
        p->P5.stroke(200)
        p->P5.strokeWeight(1)
        p->P5.rect(
          marginPx,
          marginPx,
          currentSize.contents.width->Int.toFloat -. marginPx *. 2.0,
          currentSize.contents.height->Int.toFloat -. marginPx *. 2.0,
        )

        // Draw padding border (darker gray) - safe drawing area
        if paddingPx > 0.0 {
          p->P5.stroke(150)
          p->P5.strokeWeight(1)
          p->P5.rect(
            totalSpacePx,
            totalSpacePx,
            currentSize.contents.width->Int.toFloat -. totalSpacePx *. 2.0,
            currentSize.contents.height->Int.toFloat -. totalSpacePx *. 2.0,
          )
        }

        // Create a reduced paper size that accounts for margin + padding
        let totalSpaceMm = currentMarginMm.contents +. currentPaddingMm.contents
        let drawableSize = {
          width: currentSize.contents.width - (totalSpacePx *. 2.0)->Float.toInt,
          height: currentSize.contents.height - (totalSpacePx *. 2.0)->Float.toInt,
          widthMm: currentSize.contents.widthMm -. totalSpaceMm *. 2.0,
          heightMm: currentSize.contents.heightMm -. totalSpaceMm *. 2.0,
        }

        // Push transform to offset drawing into the safe area
        p->P5.push
        p->P5.translate(totalSpacePx, totalSpacePx)

        // Call the custom draw function with drawable paper size
        drawFn(p, drawableSize)

        p->P5.pop
      })
    }
  }
}
