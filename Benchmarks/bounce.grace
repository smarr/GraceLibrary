def warmupIterations = 20
def steadyOuterIterations = 500 // 60
def steadyInnerIterations = 1000

class Random(seed') {
  var seed := seed'
  method next {
    seed := ((seed * 1309.asInteger) + 13849.asInteger) & 65535.asInteger
    seed
  }
}

class Ball(random) {
  var x := random.next % 500.asInteger
  var y := random.next % 500.asInteger
  var xVel := (random.next % 300.asInteger) - 150.asInteger
  var yVel := (random.next % 300.asInteger) - 150.asInteger
    
  method bounce {
    var xLimit := 500.asInteger
    var yLimit := 500.asInteger
    var bounced := false

    x := x + xVel
    y := y + yVel
    
    (x > xLimit).ifTrue {
      x := xLimit
      xVel := 0 - xVel.abs
      bounced := true
    }
    
    (x < 0).ifTrue {
      x := 0
      xVel := xVel.abs
      bounced := true
    }
    
    (y > yLimit).ifTrue {
      y := yLimit
      yVel := 0 - yVel.abs
      bounced := true
    }
    
    (y < 0).ifTrue {
      y := 0
      yVel := yVel.abs
      bounced := true
    }
    
    bounced
  }
}

method Bounce {

  var random := Random(74755.asInteger)
  var ballCount := 100.asInteger
  var bounces := 0.asInteger
  var balls := platform.kernel.Array.new (ballCount) withAll {
    Ball(random)
  }

  1.asInteger.to(50.asInteger) do { i ->
    balls.do { ball ->
      ball.bounce.ifTrue {
        bounces := bounces + 1.asInteger
      }
    }
  }

  bounces
}

method benchmark {
  def result = Bounce
  def expected = 1331.asInteger
  if (result != expected) then {
    self.error("Expected value " + expected.asString + " differs from actual benchmark result " + result.asString)
  }
}
  
  