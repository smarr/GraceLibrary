// Copyright (c) 2001-2018 see AUTHORS file
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the 'Software'), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//
// Adapted for Grace by Richard Roberts
//   2018, June
//

class ListElement(n) {
  var val := n
  var next
  
  method length {
    (next.isNil).ifTrue {
      return 1.asInteger
    } ifFalse {
      return 1.asInteger + next.length
    }
  } 
}

class List {
  
  method makeList(length) {
    (length == 0).ifTrue {
      return Done
    } ifFalse {
      var e := ListElement(length)
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

  
}

method asString {
  "ListUntyped.grace"
}

method benchmark(innerIterations) {
  var instance := List

  1.asInteger.to(innerIterations) do { i ->
    var result := instance.talkWithX (instance.makeList(15)) withY (instance.makeList(10)) withZ (instance.makeList(6)).length
    if (result != 10) then {
      error("{self} failed, {result} != 10")
    }
  }

  Done
}
