

// var NavierStokes = new BenchmarkSuite('NavierStokes', .at(1484000),
//                                       .at(new Benchmark('NavierStokes',
//                                                      true,
//                                                      false,
//                                                      180,
//                                                      runNavierStokes,
//                                                      setupNavierStokes,
//                                                      tearDownNavierStokes,
//                                                      null,
//                                                      16)))

// method checkResult(dens) {

//     this.result = 0
//     for (var i=7000i<7100i++) {
//         this.result+=~~((dens.at(i)*10))
//     }

//     if (this.result!=77) {
//         throw(new Error("checksum failed"))
//     }
// }


var solver := Done
var nsFrameCounter := 0.asInteger


method runNavierStokes {
    solver.update
    nsFrameCounter := nsFrameCounter + 1.asInteger

    (nsFrameCounter == 15.asInteger).ifTrue {
        checkResult(solver.getDens)
    }
}

method setupNavierStokes {
    solver = FluidField(Done)
    solver.setResolution(128.asInteger, 128.asInteger)
    solver.setIterations(20.asInteger)
    solver.reset
}

method tearDownNavierStokes {
    solver := Done
}

method addPoints(field) {
    var n := 64.asInteger
    1.asInteger.to(n) do { i ->
        field.setVelocity(i, i, n, n)
        field.setDensity(i, i, 5.asInteger)
        field.setVelocity(i, n - i, -n, -n)
        field.setDensity(i, n - i, 20.asInteger)
        field.setVelocity(128.asInteger - i, n + i, -n, -n)
        field.setDensity(128.asInteger - i, n + i, 30.asInteger)
    }
}

var framesTillAddingPoints := 0.asInteger
var framesBetweenAddingPoints := 5.asInteger

method prepareFrame(field) {
    (framesTillAddingPoints == 0.asInteger).ifTrue {
        addPoints(field)
        framesTillAddingPoints := framesBetweenAddingPoints
        framesBetweenAddingPoints := framesBetweenAddingPoints + 1
    } ifFalse {
        framesTillAddingPoints := framesTillAddingPoints - 1
    }
}

// Code from Oliver Hunt (http://nerget.com/fluidSim/pressure.js) starts here.
method FluidField(canvas) {

    method addFields(x, s, dt) {
        0.asInteger.to(size - 1.asInteger) do { i ->
            x.at (i) put (x.at(i) + dt * s.at(i))
        }
    }

    method set_bnd(b, x) {
        (b===1.asInteger).ifTrue {
            
            1.asInteger.to(width) do { i ->
                x.at(i) put (x.at(i + rowSize))
                x.at(i + (height + 1.asInteger) * rowSize) put (x.at(i + height * rowSize))
            }

            
            1.asInteger.to(height) do { j ->
                x.at(j * rowSize) put(0.asInteger - x.at(1.asInteger + j * rowSize))
                x.at((width + 1.asInteger) + j * rowSize) put(-x.at(width + j * rowSize))
            }
        } ifFalse {

            (b === 2).ifTrue {
                
                1.asInteger.to(width) do { i ->
                    x.at(i) put(-x.at(i + rowSize))
                    x.at(i + (height + 1.asInteger) * rowSize) put(0.asInteger - x.at(i + height * rowSize))
                }

                
                1.asInteger.to(height) do { j ->
                    x.at(j * rowSize) put( x.at(1.asInteger + j * rowSize))
                    x.at((width + 1.asInteger) + j * rowSize) put( x.at(width + j * rowSize))
                }
            } ifFalse {
                
                1.asInteger.to(width) do { i ->
                    x.at(i) put( x.at(i + rowSize))
                    x.at(i + (height + 1.asInteger) * rowSize) put(x.at(i + height * rowSize))
                }

                
                1.asInteger.to(height) do { j ->
                    x.at(j * rowSize) put( x.at(1.asInteger + j * rowSize))
                    x.at((width + 1.asInteger) + j * rowSize) put(x.at(width + j * rowSize))
                }
            }
        }

        var maxEdge := (height + 1.asInteger) * rowSize
        x.at(0.asInteger)                   put (0.5 * (x.at(1.asInteger)           + x.at(rowSize)))
        x.at(maxEdge)                       put (0.5 * (x.at(1.asInteger + maxEdge) + x.at(height * rowSize)))
        x.at(width + 1.asInteger)           put (0.5 * (x.at(width)                 + x.at(width + 1 + rowSize)))
        x.at(width + 1.asInteger + maxEdge) put (0.5 * (x.at(width + maxEdge)       + x.at(width + 1 + height * rowSize)))
    }

    method lin_solve(b, x, x0, a, c) {
        if (a === 0.asInteger && c === 1.asInteger) {
            1.asInteger.to(height) do { j -> 
                var currentRow := j * rowSize
                currentRow := currentRow + 1.asInteger

                0.asInteger.to(width - 1.asInteger) do { i->
                    x.at(currentRow) put (x0.at(currentRow))
                    currentRow := currentRow + 1.asInteger
                }
            }
            set_bnd(b, x)

        } else {
            var invC := 1 / c
            0.asInteger.to(iterations - 1.asInteger) do { k ->
                1.asInteger.to(height) do { j ->

                    var lastRow    := (j - 1.asInteger) * rowSize
                    var currentRow := j * rowSize
                    var nextRow    := (j + 1.asInteger) * rowSize
                    var lastX      := x.at(currentRow)
                    
                    currentRow := currentRow + 1.asInteger
                    1.asInteger.to(width) do { i ->
                        currentRow := currentRow + 1.asInteger
                        lastRow := lastRow + 1.asInteger
                        nextRow := nextRow + 1.asInteger

                        var tmp := x0.at(currentRow) + a * (lastX + x.at(currentRow)) + x.at(lastRow) + x.at(nextRow))) * invC
                        lastX := tmp
                        x.at(currentRow) put(tmp)

                    }                        
                }
                set_bnd(b, x)
            }
        }
    }

    method diffuse(b, x, x0, dt) {
        var a := 0.asInteger
        lin_solve(b, x, x0, a, 1.asInteger + 4.asInteger * a)
    }

    method lin_solve2(x, x0, y, y0, a, c) {
        if (a === 0.asInteger && c === 1.asInteger) {
            1.asInteger.to(height) do { j ->
                var currentRow := j * rowSize
                currentRow := currentRow + 1.asInteger
                0.asInteger.to(width - 1.asInteger) do { i -> 
                    x.at(currentRow) = x0.at(currentRow)
                    y.at(currentRow) = y0.at(currentRow)
                    currentRow := currentRow + 1.asInteger
                }
            }
            set_bnd(1.asInteger, x)
            set_bnd(2.asInteger, y)

        } else {
            var invC := 1.asInteger / c
            0.asInteger.to(iterations - 1.asInteger) do { k ->
                1.asInteger.to(height) do { j ->
                    var lastRow    := (j - 1.asInteger) * rowSize
                    var currentRow := j * rowSize
                    var nextRow    := (j + 1.asInteger) * rowSize
                    var lastX      := x.at(currentRow)
                    var lastY      := y.at(currentRow)
                    currentRow := currentRow + 1.asInteger

                    1.asInteger.to(width) do { i ->
                        tmp := (x0.at(currentRow) + a * (lastX + x.at(currentRow) + x.at(lastRow) + x.at(nextRow))) * invC
                        lastX = tmp
                        x.at(currentRow) = tmp

                        tmp := (y0.at(currentRow) + a * (lastY + y.at(++currentRow) + y.at(++lastRow) + y.at(++nextRow))) * invC
                        lastY = tmp
                        y.at(currentRow) = tmp
                    }
                }
                set_bnd(1.asInteger, x)
                set_bnd(2.asInteger, y)
            }
        }
    }

    method diffuse2(x, x0, y, y0, dt) {
        var a := 0.asInteger
        lin_solve2(x, x0, y, y0, a, 1.asInteger + 4.asInteger * a)
    }

    method advect(b, d, d0, u, v, dt) {
        var Wdt0 := dt * width
        var Hdt0 := dt * height
        var Wp5 := width + 0.5
        var Hp5 := height + 0.5

        1.asInteger.to(height) do { j->
            var pos := j * rowSize
            1.asInteger.to(width) do { i ->
                pos := pos + 1
                var x := i - Wdt0 * u.at(pos)
                var y := j - Hdt0 * v.at(pos)
                (x < 0.5).ifTrue {
                    x := 0.5
                } ifFalse {
                    (x > Wp5).ifTrue {
                        x := Wp5    
                    }
                }
                var i0 := x.bitOr(0.asInteger)
                var i1 := i0 + 1.asInteger
                (y < 0.5).ifTrue {
                    y = 0.5
                } ifFalse {
                    (y > Hp5).ifTrue {
                        y := Hp5
                    }
                }
                var j0 := y.bitOr(0.asInteger)
                var j1 := j0 + 1.asInteger
                var s1 := x - i0
                var s0 := 1.asInteger - s1
                var t1 := y - j0
                var t0 := 1.asInteger - t1
                var row1 := j0 * rowSize
                var row2 := j1 * rowSize
                d.at(pos) = s0 * (t0 * d0.at(i0 + row1) + t1 * d0.at(i0 + row2)) + s1 * (t0 * d0.at(i1 + row1) + t1 * d0.at(i1 + row2))
            }
        }

        set_bnd(b, d)
    }

    method project(u, v, p, div) {
        var h := -0.5 / (width * height).sqrt
        1.asInteger.to(height) do { j ->
            var row         := j * rowSize
            var previousRow := (j - 1.asInteger) * rowSize
            var prevValue   := row - 1.asInteger
            var currentRow  := row
            var nextValue   := row + 1.asInteger
            var nextRow     := (j + 1.asInteger) * rowSize

            1.asInteger.to(width) do { i ->
                currentRow  := currentRow + 1.asInteger
                nextValue   := nextValue + 1.asInteger
                prevValue   := prevValue + 1.asInteger
                nextRow     := nextRow + 1.asInteger
                previousRow := previousRow + 1.asInteger
                div.at(currentRow) put (h * (u.at(nextValue) - u.at(prevValue) + v.at(nextRow) - v.at(previousRow)))
                p.at(currentRow) put (0.asInteger)
            }
        }
        set_bnd(0.asInteger, div)
        set_bnd(0.asInteger, p)

        lin_solve(0.asInteger, p, div, 1.asInteger, 4.asInteger)
        var wScale := 0.5 * width
        var hScale := 0.5 * height

        1.asInteger.to(height) do { j ->
            var prevPos    := j * rowSize - 1.asInteger
            var currentPos := j * rowSize
            var nextPos    := j * rowSize + 1.asInteger
            var prevRow    := (j - 1.asInteger) * rowSize
            var currentRow := j * rowSize
            var nextRow    := (j + 1.asInteger) * rowSize

            1.asInteger.to(width) do { i ->
                currentPos := currentPos + 1.asInteger
                
                nextPos := nextPos + 1.asInteger
                prevPos := prevPos + 1.asInteger
                u.at(currentPos) put( v.at(currentPos) - wScale * (p.at(nextPos) - p.at(prevPos)))

                nextRow := nextRow + 1.asInteger
                prevRow := prevRow + 1.asInteger
                v.at(currentPos)   put( v.at(currentPos) - hScale * (p.at(nextRow) - p.at(prevRow)))
            }
        }
        set_bnd(1.asInteger, u)
        set_bnd(2.asInteger, v)
    }

    method dens_step(x, x0, u, v, dt) {
        addFields(x, x0, dt)
        diffuse(0.asInteger, x0, x, dt )
        advect(0.asInteger, x, x0, u, v, dt )
    }

    method vel_step(u, v, u0, v0, dt) {
        addFields(u, u0, dt)
        addFields(v, v0, dt)
        var temp := u0
        u0 := u
        u := temp

        var temp := v0
        v0 := v
        v := temp
        diffuse2(u,u0,v,v0, dt)
        project(u, v, u0, v0)

        var temp := u0
        u0 := u
        u := temp

        var temp := v0
        v0 := v
        v := temp

        advect(1.asInteger, u, u0, u0, v0, dt)
        advect(2.asInteger, v, v0, u0, v0, dt)
        project(u, v, u0, v0 )
    }

    method Field(dens, u, v) {
        // Just exposing the fields here rather than using accessors is a measurable win during display (maybe 5%)
        // but makes the code ugly.
        this.setDensity = method(x, y, d) {
             dens.at((x + 1) + (y + 1) * rowSize) = d
        }
        this.getDensity = method(x, y) {
             return dens.at((x + 1) + (y + 1) * rowSize)
        }
        this.setVelocity = method(x, y, xv, yv) {
             u.at((x + 1) + (y + 1) * rowSize) = xv
             v.at((x + 1) + (y + 1) * rowSize) = yv
        }
        this.getXVelocity = method(x, y) {
             return u.at((x + 1) + (y + 1) * rowSize)
        }
        this.getYVelocity = method(x, y) {
             return v.at((x + 1) + (y + 1) * rowSize)
        }
        this.width = method { return width }
        this.height = method { return height }
    }
    method queryUI(d, u, v) {
        for (var i = 0 i < size i++)
            u.at(i) = v.at(i) = d.at(i) = 0.0
        prepareFrame(new Field(d, u, v))
    }

    this.update = method  {
        queryUI(dens_prev, u_prev, v_prev)
        vel_step(u, v, u_prev, v_prev, dt)
        dens_step(dens, dens_prev, u, v, dt)
        displayFunc(new Field(dens, u, v))
    }

    this.iterations = method { return iterations }
    this.setIterations = method(iters) {
        if (iters > 0 && iters <= 100)
           iterations = iters
    }
    
    var iterations = 10
    var visc = 0.5
    var dt = 0.1
    var dens
    var dens_prev
    var u
    var u_prev
    var v
    var v_prev
    var width
    var height
    var rowSize
    var size
    var displayFunc
    method reset {
        rowSize = width + 2
        size = (width+2)*(height+2)
        dens = new Array(size)
        dens_prev = new Array(size)
        u = new Array(size)
        u_prev = new Array(size)
        v = new Array(size)
        v_prev = new Array(size)
        for (var i = 0 i < size i++)
            dens_prev.at(i) = u_prev.at(i) = v_prev.at(i) = dens.at(i) = u.at(i) = v.at(i) = 0
    }
    this.reset = reset
    this.getDens = method {
        return dens
    }
    this.setResolution = method (hRes, wRes) {
        var res = wRes * hRes
        if (res > 0 && res < 1000000 && (wRes != width || hRes != height)) {
            width = wRes
            height = hRes
            reset
            return true
        }
        return false
    }
    this.setResolution(64, 64)
}