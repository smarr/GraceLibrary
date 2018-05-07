def warmupIterations = 50
def steadyOuterIterations = 70
def steadyInnerIterations = 1000

class List {
  
  method makeList(length) {
    (length == 0). ifTrue {
      return Done
    } ifFalse {
      var e := listElement (length)
      e.next(makeList(length - 1.asInteger))
      return e
    }
  }

  method isShorter (x) than (y) {
    var xTail := x
    var yTail := y

    { yTail.isNil }.whileFalse {
        (xTail.isNil) .ifTrue {
          return true
        }
        xTail := xTail.next
        yTail := yTail.next
    }
    
    false
  }

  method talkWithX (x) withY (y) withZ (z) {
    (isShorter (y) than (x)).ifTrue {
      return talkWithX (talkWithX (x.next) withY (y) withZ (z) )
                 withY (talkWithX (y.next) withY (z) withZ (x) )
                 withZ (talkWithX (z.next) withY (x) withZ (y) )
    } ifFalse {
      return z
    }
  }

  class listElement (n) {
    var val := n
    var next
    
    method length {
      (next.isNil).ifTrue {
        return 1
      } ifFalse {
        return 1 + next.length
      }
    } 
  }
}

method benchmark {
  var instance := List 
  var result := instance.talkWithX (instance.makeList(15)) withY (instance.makeList(10)) withZ (instance.makeList(6)).length
  def expected = 10
  if (result != expected) then {
    self.error("Expected value " + expected.asString + " differs from actual benchmark result " + result.asString)
  }
}
