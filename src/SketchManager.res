// Sketch Manager - handles switching between different sketches

type sketchConfig = {
  name: string,
  createFn: unit => P5.t => unit,
}

type state = {
  currentP5: option<P5.t>,
  sketches: array<sketchConfig>,
  currentIndex: int,
}

// Global state
let state = ref({
  currentP5: None,
  sketches: [],
  currentIndex: 0,
})

// P5 remove binding
@send external remove: P5.t => unit = "remove"

// DOM bindings
@val @scope("document")
external getElementById: string => Js.Nullable.t<Dom.element> = "getElementById"

@val @scope("document")
external createElement: string => Dom.element = "createElement"

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

  // Small delay to ensure removal completes
  %raw(`setTimeout(() => {}, 10)`)

  // Get the sketch config
  switch state.contents.sketches[index] {
  | None => Console.log(`Sketch at index ${index->Int.toString} not found`)
  | Some(config) => {
      Console.log(`Creating new sketch: ${config.name}`)

      // Create new p5 instance with parent container
      // This prevents p5 from creating canvas in body first
      let sketchFn = config.createFn()
      let p5Instance = P5.makeWithParent(sketchFn, "sketch")

      Console.log("New sketch attached to container")

      // Update state
      state := {
        ...state.contents,
        currentP5: Some(p5Instance),
        currentIndex: index,
      }

      Console.log(`=== Sketch switch complete ===`)
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
  switch state.contents.currentP5 {
  | None => Console.log("No sketch to export")
  | Some(p5) => {
      let formatSelect = getElementById("export-format")
      switch formatSelect->Js.Nullable.toOption {
      | None => Console.log("Export format selector not found")
      | Some(element) => {
          let format = element->value
          Console.log(`Exporting current sketch as ${format}`)

          let canvas = p5->P5.canvas
          let timestamp = %raw(`new Date().toISOString()`)
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
            // SVG export with embedded canvas image
            let dataUrl = canvas->toDataURL("image/png", 1.0)
            let widthPx = p5->P5.width
            let heightPx = p5->P5.height

            // Get paper size in mm for accurate plotting
            let paperSize = PlotterFrame.getCurrentPaperSize()
            let widthMm = paperSize.widthMm->Float.toString
            let heightMm = paperSize.heightMm->Float.toString

            let svgContent = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
     width="${widthMm}mm" height="${heightMm}mm"
     viewBox="0 0 ${widthPx->Int.toString} ${heightPx->Int.toString}">
  <image width="${widthPx->Int.toString}" height="${heightPx->Int.toString}" xlink:href="${dataUrl}"/>
</svg>`
            let blob = %raw(`(content) => new Blob([content], {type: 'image/svg+xml'})`)(
              svgContent,
            )
            let url = %raw(`(b) => URL.createObjectURL(b)`)(blob)
            let link = createElement("a")
            link->setHref(url)
            link->setDownload(filename)
            let linkStyle = link->style
            linkStyle["display"] = "none"
            body->appendChild(link)
            link->click
            body->removeChild(link)
            %raw(`(u) => URL.revokeObjectURL(u)`)(url)
          }
        }
      }
    }
  }
}

// Register a sketch
let registerSketch = (name: string, createFn: unit => P5.t => unit) => {
  state := {
    ...state.contents,
    sketches: Array.concat(state.contents.sketches, [{name, createFn}]),
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
