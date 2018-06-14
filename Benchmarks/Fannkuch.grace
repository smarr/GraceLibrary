// Copyright (c) 2001-2018 see AUTHORS file
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

class Fannkuch {
  def size = 7.asInteger
  var perm := 1.asInteger.to(size)
  var timesRotated := platform.kernel.Array.new(size)withAll(0.asInteger)
  var atEnd := false

  method pfannkuchen (anArray) {
    var first
    var k := 0.asInteger

    { (first := anArray.at(1.asInteger)) == 1.asInteger }.whileFalse {
      
      k := k + 1.asInteger
      var complement := first + 1.asInteger

      1.asInteger.to(first / 2.asInteger) do { i ->
        var a := anArray.at(i)
        var b := anArray.at(complement - i)
        anArray.at (i) put (b)
        anArray.at(complement - i) put (a)
      }

    }

    k
  }

  method makeNext {
    
    // Generate the next permutation.
    2.asInteger.to (perm.size) do { r ->
      
      // Rotate the first r items to the left.
      var temp := perm.at (1.asInteger)
      1.asInteger.to(r - 1.asInteger) do { i ->
        perm.at(i) put (perm.at(i + 1.asInteger))
      }
      perm.at (r) put (temp)

      timesRotated.at (r) put ((timesRotated.at(r) + 1.asInteger) % r)
      var remainder := timesRotated.at (r)
      (remainder == 0.asInteger).ifFalse {
        return self
      }

      // After r rotations, the first r items are in their original positions.
      //   Go on rotating the first r+1 items.
    }

    // We are past the final permutation.
    atEnd := true
  }

  method maxPfannkuchen {
    var max := 0.asInteger
    { atEnd }.whileFalse {
      max := max.max (pfannkuchen (next))
    }
    max
  }

  method next {
    var result := perm.copy
    makeNext
    result
  }
}

method asString {"Fannkuch.grace"}

method benchmark(innerIterations) {
  1.asInteger.to(innerIterations) do { i ->
    var result := Fannkuch.maxPfannkuchen
    (result == 16).ifFalse {
      error("{self} failed, {result} != 16")
    }
  }
}
