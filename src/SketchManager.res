// Sketch Manager - handles switching between different sketches

type loaderFn

type sketchConfig = {
  name: string,
  loader: loaderFn,
}

type state = {
  currentP5: option<P5.t>,
  sketches: array<sketchConfig>,
  currentIndex: int,
  isLoading: bool,
}

// Global state
let state = ref({
  currentP5: None,
  sketches: [],
  currentIndex: 0,
  isLoading: false,
})

// P5 remove binding
@send external remove: P5.t => unit = "remove"

// DOM bindings
@val @scope("document")
external getElementById: string => Js.Nullable.t<Dom.element> = "getElementById"

@val @scope("document")
external createElement: string => Dom.element = "createElement"

// Timer binding
@val external setTimeout: (unit => unit, int) => float = "setTimeout"

// Date binding
type date
@new external makeDate: unit => date = "Date"
@send external toISOString: date => string = "toISOString"

// Window bindings
@val @scope("window") external currentP5Instance: P5.t = "__currentP5Instance"

// String manipulation bindings
type regExp
@new external makeRegExp: string => regExp = "RegExp"
@send external match: (string, regExp) => Js.Nullable.t<array<string>> = "match"
@send
external replace: (string, regExp, string => string) => string = "replace"

@set external setTextContent: (Dom.element, string) => unit = "textContent"
@set external setClassName: (Dom.element, string) => unit = "className"
@set external setInnerHTML: (Dom.element, string) => unit = "innerHTML"
@set external setValue: (Dom.element, string) => unit = "value"
@get external value: Dom.element => string = "value"

@send
external addEventListener: (Dom.element, string, unit => unit) => unit = "addEventListener"

@send external appendChild: (Dom.element, Dom.element) => unit = "appendChild"

// Export functionality bindings
@send external toDataURL: (Dom.element, string, float) => string = "toDataURL"
@set external setHref: (Dom.element, string) => unit = "href"
@set external setDownload: (Dom.element, string) => unit = "download"
@get external style: Dom.element => {..} = "style"
@send external click: Dom.element => unit = "click"
@send external removeChild: (Dom.element, Dom.element) => unit = "removeChild"
@val @scope("document") external body: Dom.element = "body"

// Remove current p5 instance completely
let removeCurrentSketch = () => {
  Console.log("removeCurrentSketch called")

  // Clear the container first
  let sketchDiv = getElementById("sketch")
  switch sketchDiv->Js.Nullable.toOption {
  | None => Console.log("Sketch container not found during removal")
  | Some(div) => {
      Console.log("Clearing sketch container innerHTML")
      div->setInnerHTML("")
    }
  }

  // Remove p5 instance
  switch state.contents.currentP5 {
  | None => Console.log("No current p5 instance to remove")
  | Some(p5) => {
      Console.log("Calling p5.remove()")
      p5->remove
      state := {...state.contents, currentP5: None}
    }
  }
}

// Switch to a sketch by index
let switchToSketch = (index: int) => {
  Console.log(`=== Switching to sketch index: ${index->Int.toString} ===`)

  // Always remove current sketch first
  removeCurrentSketch()

  // Set loading state
  state := {...state.contents, isLoading: true, currentIndex: index}

  // Get the sketch config
  switch state.contents.sketches[index] {
  | None => {
      Console.log(`Sketch at index ${index->Int.toString} not found`)
      state := {...state.contents, isLoading: false}
    }
  | Some(config) => {
      Console.log(`Dynamically loading sketch: ${config.name}`)

      // Call the loader function and handle the promise
      %raw(`
        (function(loader, sketchName) {
          Promise.all([
            loader(),
            import('p5')
          ])
            .then(([sketchModule, p5Module]) => {
              console.log('Sketch module loaded:', sketchName);
              const p5Constructor = p5Module.default;
              const sketchFn = sketchModule.createSketch();
              const p5Instance = new p5Constructor(sketchFn, 'sketch');

              // Update state with loaded sketch
              window.__currentP5Instance = p5Instance;
              //-- @TODO fix
              // state := {
              //         ...state.contents,
              //         currentP5: Some(p5Instance),
              //         currentIndex: index,
              //       }
              window.__sketchLoadComplete = true;
            })
            .catch(err => {
              console.error('Failed to load sketch:', err);
              window.__sketchLoadError = err;
            });
        })
      `)(config.loader, config.name)

      // Poll for completion
      %raw(`
        (function checkLoaded() {
          if (window.__sketchLoadComplete) {
            window.__sketchLoadComplete = false;
            return;
          }
          if (window.__sketchLoadError) {
            window.__sketchLoadError = null;
            return;
          }
          setTimeout(checkLoaded, 50);
        })()
      `)
    }
  }
}

// Create sketch selector dropdown
let createSketchSelector = () => {
  let controlsDiv = getElementById("sketch-controls")

  switch controlsDiv->Js.Nullable.toOption {
  | None => Console.log("Controls container not found")
  | Some(controls) => {
      // Clear existing controls
      controls->setInnerHTML("")

      // Create label
      let label = createElement("label")
      label->setTextContent("Select Sketch: ")
      label->setClassName("sketch-label")
      controls->appendChild(label)

      // Create select dropdown
      let select = createElement("select")
      select->setClassName("sketch-selector")

      // Add options for each sketch
      state.contents.sketches->Array.forEachWithIndex((sketch, index) => {
        let option = createElement("option")
        option->setValue(index->Int.toString)
        option->setTextContent(sketch.name)
        select->appendChild(option)
      })

      // Set initial value
      select->setValue(state.contents.currentIndex->Int.toString)

      // Add change listener
      select->addEventListener("change", () => {
        let selectedIndex = select->value->Int.fromString->Option.getOr(0)
        Console.log(`Dropdown changed to index: ${selectedIndex->Int.toString}`)
        switchToSketch(selectedIndex)
      })

      controls->appendChild(select)

      Console.log("Sketch selector created")
    }
  }
}

// Export current sketch
let exportCurrentSketch = () => {
  let p5 = currentP5Instance
  let formatSelect = getElementById("export-format")
  switch formatSelect->Js.Nullable.toOption {
  | None => Console.log("Export format selector not found")
  | Some(element) => {
      let format = element->value
      Console.log(`Exporting current sketch as ${format}`)

      let canvas = p5->P5.canvas
      let timestamp = makeDate()->toISOString
      let filename = `${timestamp}.${format}`

      if format == "png" {
        // PNG export
        let dataUrl = canvas->toDataURL("image/png", 1.0)
        let link = createElement("a")
        link->setHref(dataUrl)
        link->setDownload(filename)
        let linkStyle = link->style
        linkStyle["display"] = "none"
        body->appendChild(link)
        link->click
        body->removeChild(link)
      } else if format == "svg" {
        // SVG export - extract SVG from DOM and add plotter-friendly metadata
        let svgElements = P5.getElementsByTagName("svg")
        switch svgElements[0] {
        | None => {
            Console.log("No SVG element found - canvas is not using SVG renderer")
            Console.log("SVG export requires creating canvas with SVG renderer")
          }
        | Some(svgElement) => {
            // Get the current paper size for physical dimensions
            let paperSize = PlotterFrame.getCurrentPaperSize()

            // Get the SVG content and modify it for plotter use
            let svgContent = svgElement->P5.outerHTML

            // Add physical dimensions in mm for plotter software
            // Replace width and height attributes with mm units while preserving viewBox
            let enhancedSvg = {
              let svgTagRegex = makeRegExp("<svg([^>]*)>")
              svgContent->replace(svgTagRegex, attrs => {
                // Extract viewBox if it exists
                let viewBoxRegex = makeRegExp("viewBox=\"([^\"]+)\"")
                let viewBoxMatch = attrs->match(viewBoxRegex)

                let viewBoxAttr = switch viewBoxMatch->Js.Nullable.toOption {
                | Some(matches) =>
                    switch matches[1] {
                    | Some(vb) => ` viewBox="${vb}"`
                    | None => ""
                    }
                | None => ""
                }

                // Build new SVG tag with mm units
                let widthMmStr = paperSize.widthMm->Float.toString
                let heightMmStr = paperSize.heightMm->Float.toString

                `<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="${widthMmStr}mm" height="${heightMmStr}mm"${viewBoxAttr}>`
              })
            }

            let blobOpts: P5.blobOptions = {\"type": "image/svg+xml"}
            let blob = P5.createBlob([enhancedSvg], blobOpts)
            let url = P5.createObjectURL(blob)

            let link = createElement("a")
            link->setHref(url)
            link->setDownload(filename)
            let linkStyle = link->style
            linkStyle["display"] = "none"
            body->appendChild(link)
            link->click
            body->removeChild(link)

            // Clean up the object URL after a short delay
            let _ = setTimeout(() => P5.revokeObjectURL(url), 100)

            Console.log(`Saved SVG: ${filename} (${paperSize.widthMm->Float.toString}mm × ${paperSize.heightMm->Float.toString}mm)`)
          }
        }
      }
    }
  }
}

// Register a sketch with its loader function
let registerSketch = (name: string, loader: loaderFn) => {
  state := {
      ...state.contents,
      sketches: Array.concat(state.contents.sketches, [{name, loader}]),
    }
  Console.log(`Registered sketch: ${name}`)
}

// Initialize the sketch manager
let init = () => {
  Console.log("Initializing Sketch Manager...")

  // Create selector UI
  createSketchSelector()

  // Set up export button (only once)
  let exportBtn = getElementById("export-btn")
  switch exportBtn->Js.Nullable.toOption {
  | None => Console.log("Export button not found")
  | Some(btn) => {
      btn->addEventListener("click", () => exportCurrentSketch())
      Console.log("Export button initialized")
    }
  }

  // Load first sketch if available
  if Array.length(state.contents.sketches) > 0 {
    switchToSketch(0)
  }

  Console.log("Sketch Manager initialized")
}
