// The ray tracer code in file is written by Adam Burmister. It
// is available in its original form from:
//
//   http://labs.nz.co/raytracer/
//
// It has been modified slightly by Google to work as a standalone
// benchmark, but the all the computational code remains
// untouched. This file also contains a copy of parts of the Prototype
// JavaScript framework which is used by the ray tracer.

//var RayTrace := BenchmarkSuite("RayTrace", 739989, [
//  Benchmark("RayTrace", renderScene)
//])

// Variable used to hold a number that can be used to verify that
// the scene was ray traced correctly.

        
var checkNumber: Number := 0.asInteger

type Color = interface {
    red -> Number
    green -> Number
    blue -> Number
    add(c1: Color, c2: Color)
    addScalar(c1: Color, s: Number)
    subtract(c1: Color, c2: Color)
    multiply(c1: Color, c2: Color)
    multiplyScalar(c1: Color, f: Number)
    divideFactor(c1: Color, f: Number)
    limit
    distance(color:Color)
    blend(c1: Color, c2: Color, w: Number)
    brightness
    asString
}

type Vector = interface {
    x -> Number
    y -> Number
    z -> Number
    copy(vector: Vector)
    normalize
    magnitude
    cross(w:Vector)
    dot(w:Vector)
    add(v:Vector, w:Vector)
    subtract(v:Vector, w:Vector)
    multiplyVector(v:Vector, w:Vector)
    multiplyScalar(v:Vector, w: Number)
    asString
}

type BaseMaterial = interface {
    gloss -> Number
    transparency -> Number
    reflection -> Number
    refraction -> Number
    hasTexture -> Boolean
    getColor(u: Number, v: Number) -> Color
    wrapUp(t: Number)
    asString
}

type Scene = interface {
    camera -> Camera
    background -> Background
    shapes
    lights
}

type Shape = interface {
    position -> Vector
    material -> BaseMaterial
    intersect(ray:Ray) -> IntersectionInfo
}

type Light = interface {
    position -> Vector
    color -> Color
    intensity -> Number
}

type IntersectionInfo = interface {
    isHit -> Boolean
    hitCount -> Number
    shape -> Shape
    position -> Vector
    normal -> Vector
    color -> Color
    distance ->  Number
    initialize
    asString
}
        
class Color(red': Number, green': Number, blue': Number) {
    var red: Number := red'
    var green: Number := green'
    var blue: Number := blue'

    method add(c1: Color, c2: Color) {
        var result := Color
        result.red   := c1.red  + c2.red
        result.green := c1.green + c2.green
        result.blue  := c1.blue  + c2.blue
        result
    }

    method addScalar(c1: Color, s: Number) {
        var result := Color
        result.red   := c1.red + s
        result.green := c1.green + s
        result.blue  := c1.blue + s
        result.limit
        result
    }


    method subtract(c1: Color, c2: Color) {
        var result := Color
        result.red   := c1.red - c2.red
        result.green := c1.green - c2.green
        result.blue  := c1.blue - c2.blue
        result
    }

    method multiply(c1: Color, c2: Color) {
        var result := Color
        result.red   := c1.red * c2.red
        result.green := c1.green * c2.green
        result.blue  := c1.blue * c2.blue
        result
    }

    method multiplyScalar(c1: Color, f: Number) {
        var result := Color
        result.red   := c1.red * f
        result.green := c1.green * f
        result.blue  := c1.blue * f
        result
    }


    method divideFactor(c1: Color, f: Number) {
        var result := Color
        result.red   := c1.red / f
        result.green := c1.green / f
        result.blue  := c1.blue / f
        return result
    }

    method limit {
        (  red > 0).ifTrue { (  red > 1).ifTrue {   red := 1 } } ifFalse {   red := 0 }
        (green > 0).ifTrue { (green > 1).ifTrue { green := 1 } } ifFalse { green := 0 }
        ( blue > 0).ifTrue { ( blue > 1).ifTrue {  blue := 1 } } ifFalse {  blue := 0 }
    }

    method distance(color:Color) {
        var d := (red - color.red).abs + (green - color.green).abs + (blue - color.blue).abs
        d
    }

    method blend(c1: Color, c2: Color, w: Number) {
        var result := Color(0, 0, 0)
        result := Color.add(
            Color.multiplyScalar(c1, 1 - w),
            Color.multiplyScalar(c2, w)
        )
        result
    }

    method brightness {
        var r := (  red * 255).asInteger
        var g := (green * 255).asInteger
        var b := ( blue * 255).asInteger
        (r * 77.asInteger + g * 150.asInteger + b * 29.asInteger).bitRightShift(8.asInteger)
    }

    method asString {
        // "rgb({(red * 255).asInteger},{(green * 255).asInteger},{(blue * 255).asInteger})"
        "{(red * 255).asInteger},{(green * 255).asInteger},{(blue * 255).asInteger}"
    }
}

method Color {
    Color(0, 0, 0)
}

class Light(position: Vector, color: Color, intensity: Number) {
    method asString {
        "Light [{position.x},{position.y},{position.z}]"
    }
}

method Light(position: Vector, color: Color) {
    Light(position, color, 10)
}

class Vector(x': Number, y': Number, z': Number) {
    var x: Number := x'
    var y: Number := y'
    var z: Number := z'

    method copy(vector: Vector) {
        x := vector.x
        y := vector.y
        z := vector.z
    }

    method normalize {
        var m := magnitude
        Vector(x / m, y / m, z / m)
    }

    method magnitude {
        ((x * x) + (y * y) + (z * z)).sqrt
    }

    method cross(w:Vector) {
        Vector( -z * w.y + y * w.z
              ,  z * w.x - x * w.z
              , -y * w.x + x * w.y )
    }

    method dot(w:Vector) {
        x * w.x + y * w.y + z * w.z
    }

    method add(v:Vector, w:Vector) {
        Vector(w.x + v.x, w.y + v.y, w.z + v.z)
    }

    method subtract(v:Vector, w:Vector) {
        (w.isNil || v.isNil).ifTrue {
            error("Vectors must be defined [{v},{w}]")
        }
        Vector(v.x - w.x, v.y - w.y, v.z - w.z)
    }

    method multiplyVector(v:Vector, w:Vector) {
        Vector(v.x * w.x, v.y * w.y, v.z * w.z)
    }

    method multiplyScalar(v:Vector, w: Number) {
        Vector(v.x * w, v.y * w, v.z * w)
    }

    method asString {
        "Vector [{x},{y},{z}]"
    }
}

method Vector {
    Vector(0, 0, 0)
}
 
type Ray = interface {
    position -> Vector
    direction -> Vector
}

class Ray(position: Vector, direction: Vector) {

    method asString {
        "Ray [{position},{direction}]"
    }
}


class Scene {
    var camera : Camera := Camera( Vector(0, 0, -5)
                                 , Vector(0, 0,  1)
                                 , Vector(0, 1,  0) )
    var background : Background := Background(Color(0, 0, 0.5), 0.2)
    var shapes := platform.kernel.Vector.new
    var lights := platform.kernel.Vector.new
}

class BaseMaterial {
    var gloss: Number := 2.0
    var transparency: Number := 0
    var reflection: Number := 0
    var refraction: Number := 0.50
    var hasTexture: Boolean := false

    method getColor(u: Number, v: Number) -> Color {
        error("Abstract method")
    }

    method wrapUp(t: Number) {
        var t' := t % 2
        (t' < -1).ifTrue { t' := t' + 2 }
        (t' >= 1).ifTrue { t' := t' - 2 }
        t'
    }

    method asString {
        "Material [gloss={gloss}, transparency={transparency}, hasTexture={hasTexture}]"
    }
}

class Solid(color: Color, reflection': Number, refraction': Number, transparency': Number, gloss': Number) {
    inherit BaseMaterial
    gloss := gloss'
    transparency := transparency'
    reflection := reflection'
    refraction := refraction'

    method getColor(u: Number, v: Number) -> Color {
        color
    }

    method asString {
        "SolidMaterial [gloss={gloss}, transparency={transparency}, hasTexture={hasTexture}]"
    }
}

class Chessboard(colorEven: Color, colorOdd: Color, reflection': Number, transparency': Number, gloss': Number, density: Number) {
    inherit BaseMaterial
    reflection := reflection'
    transparency := transparency'
    gloss := gloss'
    hasTexture := true

    method getColor(u: Number, v: Number) -> Color {
        var t := wrapUp(u * density) * wrapUp(v * density)

        (t < 0.0).ifTrue {
            return colorEven
        } ifFalse {
            return colorOdd
        }   
    }

    method asString {
        return "ChessMaterial [gloss={gloss}, transparency={transparency}, hasTexture={hasTexture}]"
    }
}

method Chessboard(colorEven: Color, colorOdd: Color, reflection': Number, transparency': Number, gloss': Number) {
    Chessboard(colorEven, colorOdd, reflection', transparency', gloss', 0.5)
}

class Shape {
    var position: Vector
    var material: BaseMaterial

    method intersect(ray:Ray) -> IntersectionInfo {
        error("Abstract method")
    }
}

class Sphere(position': Vector, radius: Number, material':BaseMaterial) {
    inherit Shape
    position := position'
    material := material'

    method intersect(ray:Ray) -> IntersectionInfo {
        var info := IntersectionInfo
        info.shape := self

        var dst := Vector.subtract(ray.position, position)
        var B := dst.dot(ray.direction)
        var C := dst.dot(dst) - (radius * radius)
        var D := (B * B) - C

        (D > 0).ifTrue {
            info.isHit := true
            info.distance := (-B) - D.sqrt
            info.position := Vector.add(
                ray.position,
                Vector.multiplyScalar(
                    ray.direction,
                    info.distance
                )
            )
            info.normal := Vector.subtract(
                info.position,
                position
            ).normalize

            info.color := material.getColor(0, 0)
        } ifFalse {
            info.isHit := false
        }
        info
    }

    method asString {
        return "Sphere [position={position}, radius={radius}]"
    }
}

class Plane (position': Vector, d: Number, material': BaseMaterial) {
    inherit Shape
    position := position'
    material := material'

    method intersect(ray:Ray) -> IntersectionInfo {
        var info := IntersectionInfo

        var Vd := position.dot(ray.direction)
        (Vd == 0).ifTrue { return info } // no intersection

        var t := -(position.dot(ray.position) + d) / Vd
        (t <= 0).ifTrue { return info }

        info.shape := self
        info.isHit := true
        info.position := Vector.add(
            ray.position,
            Vector.multiplyScalar(
                ray.direction,
                t
            )
        )
        info.normal := position
        info.distance := t

        (material.hasTexture).ifTrue {
            var vU := Vector(position.y, position.z, -position.x)
            var vV := vU.cross(position)
            var u := info.position.dot(vU)
            var v := info.position.dot(vV)
            info.color := material.getColor(u, v)
        } ifFalse {
            info.color := material.getColor(0, 0)
        }

        info
    }

    method asString {
        "Plane [{position}, d={d}]"
    }
}

class IntersectionInfo {

    var isHit: Boolean := false
    var hitCount: Number := 0.asInteger
    var shape: Shape
    var position: Vector
    var normal: Vector
    var color: Color
    var distance:  Number

    method initialize {
        color := Color(0, 0, 0)
    }

    method asString {
        "Intersection [{position}]"
    }
}

class Camera(position: Vector, lookAt: Vector, up: Vector) {
    var equator := lookAt.normalize.cross(up)
    var screen := Vector.add(position, lookAt)

    method getRay(vx: Number, vy: Number) {
        var pos := Vector.subtract(
            screen,
            Vector.subtract(
                Vector.multiplyScalar(equator, vx),
                Vector.multiplyScalar(up, vy)
            )
        )
        pos.y := pos.y * -1
        var dir := Vector.subtract(
            pos,
            position
        )

        Ray(pos, dir.normalize)
    }
    
    method asString {
        "Ray []"
    }
}

class Background(color: Color, ambience: Number) {}

method Background(color: Color) {
    Background(color, 0)
}

type Options = interface {
    canvasWidth -> Number
    canvasHeight -> Number
    pixelWidth -> Number
    pixelHeight -> Number
    renderDiffuse -> Boolean
    renderHighlights -> Boolean
    renderShadows -> Boolean
    renderReflections -> Boolean
    rayDepth -> Number
}

method extend(dest: Options, src: Options) -> Options {
    src.canvasHeight.isNil.ifFalse { dest.canvasHeight := src.canvasHeight }
    src.canvasWidth.isNil.ifFalse { dest.canvasWidth := src.canvasWidth }
    src.pixelWidth.isNil.ifFalse { dest.pixelWidth := src.pixelWidth }
    src.pixelHeight.isNil.ifFalse { dest.pixelHeight := src.pixelHeight }
    src.renderDiffuse.isNil.ifFalse { dest.renderDiffuse := src.renderDiffuse }
    src.renderShadows.isNil.ifFalse { dest.renderShadows := src.renderShadows }
    src.renderHighlights.isNil.ifFalse { dest.renderHighlights := src.renderHighlights }
    src.renderReflections.isNil.ifFalse { dest.renderReflections := src.renderReflections }
    src.rayDepth.isNil.ifFalse { dest.rayDepth := src.rayDepth }
    
    dest
}

def defaultOptions = object {
    var canvasHeight := 100.asInteger
    var canvasWidth := 100.asInteger
    var pixelWidth := 2.asInteger
    var pixelHeight := 2.asInteger
    var renderDiffuse := false
    var renderShadows := false
    var renderHighlights := false
    var renderReflections := false
    var rayDepth := 2.asInteger
}

class Engine(options': Options) {
    var canvas
    var options: Options

    (options'.isNil).ifTrue {
        options := defaultOptions
    } ifFalse {
        options := extend(defaultOptions, options')
    }

    options.canvasHeight := options.canvasHeight / options.pixelHeight
    options.canvasWidth := options.canvasWidth  / options.pixelWidth

    method setPixel(x, y, color:Color) {
        var pxW := options.pixelWidth
        var pxH := options.pixelHeight

        canvas.isNil.not.ifTrue {
            canvas.fillStyle := color.toString
            canvas.fillRect(x * pxW, y * pxH, pxW, pxH)
        } ifFalse {
            (x == y).ifTrue {
                checkNumber := checkNumber + color.brightness
            }
        }
    }

    method renderScene(scene:Scene, canvas') {
        checkNumber := 0.asInteger
        (canvas'.isNil).ifTrue {
            canvas := Done
        } ifFalse {
            canvas := canvas'.getContext("2d")
        }

        var canvasHeight := options.canvasHeight
        var canvasWidth := options.canvasWidth

        0.asInteger.to(canvasHeight - 1.asInteger) do { y ->
            0.asInteger.to(canvasWidth - 1.asInteger) do { x ->
                var yp := y * 1.0 / canvasHeight * 2 - 1
                var xp := x * 1.0 / canvasWidth * 2 - 1
                var ray := scene.camera.getRay(xp, yp)
                var color := getPixelColor(ray, scene)
                setPixel(x, y, color)
                // print("{x},{y},{color}")
            }
        }
    }

    method getPixelColor(ray:Ray, scene:Scene) {
        var info := testIntersection(ray, scene, Done)
        (info.isHit).ifTrue {
            var color := rayTrace(info, ray, scene, 0)
            return color
        }
        scene.background.color
    }

    method testIntersection(ray: Ray, scene: Scene, excluded: Shape) -> IntersectionInfo {
        var hits := 0.asInteger
        var best := IntersectionInfo
        best.distance := 2000

        1.asInteger.to(scene.shapes.size) do { i ->
            var shape := scene.shapes.at(i)

            var process := true
            excluded.isNil.ifFalse {
                (shape == excluded).ifTrue {
                    process := false
                }
            }
            
            process.ifTrue {
                var info := shape.intersect(ray)
                (info.isHit).ifTrue {
                    (info.distance >= 0).ifTrue {

                        (best.distance.isNil).ifTrue {
                            best := info
                        } ifFalse {
                            (info.distance < best.distance).ifTrue {
                                best := info
                            }
                        }
                        
                        hits := hits + 1
                    }
                }
            }
        }
        
        best.hitCount := hits
        best
    }

    method getReflectionRay(P: Vector, N: Vector, V: Vector) {
        var c1 := -N.dot(V)
        var R1 := Vector.add(Vector.multiplyScalar(N, 2 * c1), V)
        Ray(P, R1)
    }

    method rayTrace(info: IntersectionInfo, ray: Ray, scene: Scene, depth: Number) {
        var color := Color.multiplyScalar(info.color, scene.background.ambience)
        var oldColor := color
        var shininess := 10.pow(info.shape.material.gloss + 1)

        1.asInteger.to(scene.lights.size) do { i-> 
            var light := scene.lights.at(i)
            var v := Vector.subtract(light.position, info.position).normalize

            (options.renderDiffuse.isNil).ifFalse {
                var L := v.dot(info.normal)
                (L > 0).ifTrue {
                    color := Color.add(color, Color.multiply(info.color, Color.multiplyScalar(light.color, L)))
                }
            }

            (depth <= options.rayDepth).ifTrue {
                (options.renderReflections && (info.shape.material.reflection > 0)).ifTrue {
                    var reflectionRay := getReflectionRay(info.position, info.normal, ray.direction)
                    var refl := testIntersection(reflectionRay, scene, info.shape)

                    (refl.isHit && (refl.distance > 0)).ifTrue {
                        refl.color := rayTrace(refl, reflectionRay, scene, depth + 1.asInteger)
                    } ifFalse {
                        refl.color := scene.background.color
                    }

                    color := Color.blend(color, refl.color, info.shape.material.reflection)
                }
            }

            var shadowInfo := IntersectionInfo
            (options.renderShadows).ifTrue {
                var shadowRay := Ray(info.position, v)
                shadowInfo := testIntersection(shadowRay, scene, info.shape)
                (shadowInfo.isHit && (shadowInfo.shape != info.shape)).ifTrue {
                    var vA := Color.multiplyScalar(color, 0.5)
                    var dB := 0.5 * shadowInfo.shape.material.transparency.pow(0.5)
                    color := Color.addScalar(vA, dB)
                }
            }
            (options.renderHighlights && !shadowInfo.isHit && (info.shape.material.gloss > 0)).ifTrue {
                var Lv := Vector.subtract(info.shape.position, light.position).normalize
                var E := Vector.subtract(scene.camera.position, info.shape.position).normalize
                var H := Vector.subtract(E, Lv).normalize
                var glossWeight := info.normal.dot(H).max(0).pow(shininess)
                color := Color.add(Color.multiplyScalar(light.color, glossWeight), color)
            }
        }
        color.limit
        color
    }
}

method renderScene {
    var scene := Scene

    scene.camera := Camera(
        Vector(   0,   0, -15),
        Vector(-0.2,   0,   5),
        Vector(   0,   1,   0)
    )

    scene.background := Background(
        Color(0.5, 0.5, 0.5),
        0.4
    )

    var sphere := Sphere(
        Vector(-1.5, 1.5, 2),
        1.5,
        Solid(
            Color(0, 0.5, 0.5),
            0.3,
            0.0,
            0.0,
            2.0
        )
    )

    var sphere1 := Sphere(
        Vector(1, 0.25, 1),
        0.5,
        Solid(
            Color(0.9, 0.9, 0.9),
            0.1,
            0.0,
            0.0,
            1.5
        )
    )

    var plane := Plane(
        Vector(0.1, 0.9, -0.5).normalize,
        1.2,
        Chessboard(
            Color(1, 1, 1),
            Color(0, 0, 0),
            0.2,
            0.0,
            1.0,
            0.7
        )
    )

    scene.shapes.append(plane)
    scene.shapes.append(sphere)
    scene.shapes.append(sphere1)

    var light := Light(
        Vector(5, 10, -1),
        Color(0.8, 0.8, 0.8)
    )

    var light1 := Light(
        Vector(-3, 5, -15),
        Color(0.8, 0.8, 0.8),
        100
    )

    scene.lights.append(light)
    scene.lights.append(light1)

    var imageWidth := 100.asInteger
    var imageHeight := 100.asInteger
    var pixelSize := [5, 5]
    var renderDiffuse := true
    var renderShadows := true
    var renderHighlights := true 
    var renderReflections := true
    var rayDepth := 2.asInteger

    var raytracer := Engine(
        object {
            var canvasWidth := imageWidth
            var canvasHeight := imageHeight
            var pixelWidth := pixelSize.at(1.asInteger)
            var pixelHeight := pixelSize.at(2.asInteger)
            var renderDiffuse := renderDiffuse
            var renderHighlights := renderHighlights
            var renderShadows := renderShadows
            var renderReflections := renderReflections
            var rayDepth := rayDepth
        }
    )
    
    raytracer.renderScene(scene, Done)
}

method verify {
    var expected := 1778.asInteger
    checkNumber == expected
}

method benchmark {
    renderScene
    verify
}
