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

  // Load first sketch if available
  if Array.length(state.contents.sketches) > 0 {
    switchToSketch(0)
  }

  Console.log("Sketch Manager initialized")
}
