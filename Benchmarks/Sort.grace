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

import "random" as random

var smallest
var largest
 
class Sort {
  method dataSize { error("dataSize must be implemented by subclass") }
  method sort(array) { error("sort(_) must be implemented by subclass") }

  method randomArray (size) {
    var array := platform.kernel.Array.new (size) withAll { random.next }
    
    smallest := array.at(1.asInteger)
    largest := array.at(1.asInteger)
    array.do { elm ->
        (elm > largest).  ifTrue { largest :=  elm }
        (elm < smallest). ifTrue { smallest := elm }
    }
    array
  }

  method verify(result) {
    def array = result
    ((array.at(1.asInteger) != smallest) || (array.at(array.size) != largest)).ifTrue {
        error("{self} failed, array not sorted")
    }
    3.asInteger.to(array.size) do { i ->
      (array.at(i - 1.asInteger) > array.at(i)).ifTrue {
        error("{self} failed, array not sorted")   
      }
    }
  }
}

class BubbleSort {
  inherit Sort
  
  method sort (array) {
    array.size.downTo (1.asInteger) do { i ->
      1.asInteger.to(i - 1.asInteger) do { j ->
        var current := array.at (j)
        var next :=    array.at (j + 1.asInteger)
        (current > next).ifTrue {
          array.at (j) put (next)
          array.at (j + 1.asInteger) put (current)
        }
      }
    }
    
    array
  }

  method dataSize { 130.asInteger }
}

class QuickSort {
  inherit Sort

  method sort (array) {
    sort (array) low (1.asInteger) high (dataSize)
    array
  }

  method sort (array) low (low) high (high) {
    var pivot := array.at (((low + high) / 2.asInteger).asInteger)
    var i := low
    var j := high
    { i <= j }.whileTrue {
      { array.at(i) < pivot }.whileTrue { i := i + 1 }
      { pivot < array.at(j) }.whileTrue { j := j - 1 }
      ( i <= j ).ifTrue {
        var tmp := array.at (i)
        array.at (i) put (array.at(j))
        array.at (j) put (tmp)
        i := i + 1
        j := j - 1
      }
    }

    (low < j   ).ifTrue { sort (array) low (low) high (j)    }
    (i   < high).ifTrue { sort (array) low (i)   high (high) }
  }

  method dataSize { 800.asInteger }
}

class TreeNode (val) {
  var left
  var right
  var value := val

  method check {
    (left. isNil || { (left .value <  value) && left .check }) && (right.isNil || { (right.value >= value) && right.check })
  }

  method insert (n) {
    (n < value).ifTrue {
      left.isNil.ifTrue { left := TreeNode(n) } ifFalse { left.insert (n) }
    } ifFalse {
      right.isNil.ifTrue { right := TreeNode(n) } ifFalse { right.insert(n) }
    }
  }
}

class TreeSort {
  inherit Sort
  
  method sort (array) {
      var tree
      array.doIndexes { i -> 
        (i == 1).ifTrue { 
          tree := TreeNode (array.at(i))
        } ifFalse {
          tree.insert (array.at(i))
        }
      }
      tree
  }

  method verify(result) {
    def tree = result
    return tree.check
  }

  method dataSize { 1000.asInteger }
}


method asString { "Sort.grace" }


method benchmark(innerIterations) {
  1.asInteger.to(innerIterations) do { i ->
    var array := randomArray (dataSize)
    def result = sort (array)
    verify(result)
  }
}
