// Main p5.js sketch

// Helper to set setup function
@set external setSetup: (P5.t, unit => unit) => unit = "setup"

// Helper to set draw function
@set external setDraw: (P5.t, unit => unit) => unit = "draw"

// Sketch function that defines setup and draw
let sketch = (p: P5.t) => {
  // Setup - called once at the start
  p->setSetup(() => {
    p->P5.createCanvas(800, 600)
    p->P5.background(220)
  })

  // Draw - runs every frame
  p->setDraw(() => {
    // Create a dynamic background
    p->P5.background2(240, 240, 245)

    // Draw a circle that follows the mouse
    p->P5.fill3(100, 150, 255)
    p->P5.noStroke
    p->P5.circle(p->P5.mouseX, p->P5.mouseY, 50.0)

    // Draw a static circle in the center
    p->P5.fill3(255, 100, 100)
    p->P5.circle(400.0, 300.0, 100.0)

    // Draw animated circles
    let time = p->P5.frameCount->float_of_int
    let x = 400.0 +. Js.Math.cos(time *. 0.05) *. 200.0
    let y = 300.0 +. Js.Math.sin(time *. 0.05) *. 200.0

    p->P5.fill3(100, 255, 150)
    p->P5.circle(x, y, 60.0)
  })
}

// Access global p5 constructor
@val external p5: 'a = "p5"

// Create the sketch instance using global p5
let _ = %raw("new p5(sketch)")
