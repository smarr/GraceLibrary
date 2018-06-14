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

import "random" as random

var MinNodes := 20.asInteger
var MaxNodes := 1.asInteger.bitLeftShift(31.asInteger)
var MinEdges := 2.asInteger
var MaxInitEdges := 4.asInteger
var MinWeight := 1.asInteger
var MaxWeight := 1.asInteger

def ExpectedNoOfNodes = 3000000.asInteger
def ExpectedTotalCost = 26321966.asInteger

class EdgeNewWith (dest) and (weight) {}
class NodeNewWith (starting) and (noOfEdges) {}

class GraphSearch {

  var graphNodes
  var graphMask
  var updatingGraphMask
  var graphVisited
  var cost
  var graphEdges
  var k
  var firstCost

  method initializeGraph (noOfNodes) with (random) {
    var source
    var graph
    var totalEdges

    graphNodes         := platform.kernel.Array.new (noOfNodes)
    graphMask          := platform.kernel.Array.new (noOfNodes) withAll(false)
    updatingGraphMask  := platform.kernel.Array.new (noOfNodes) withAll(false)
    graphVisited       := platform.kernel.Array.new (noOfNodes) withAll(false)
    cost               := platform.kernel.Array.new (noOfNodes) withAll(-1)

    source := 1.asInteger
    graph := platform.kernel.Array.new (noOfNodes) withAll { platform.kernel.Vector.new }

    graph.doIndexes { i ->
      var noOfEdges := random.next.rem(MaxInitEdges - MinEdges + 1.asInteger).abs + MinEdges

      1.asInteger.to (noOfEdges) do { j-> 
        var nodeId := (random.next.rem(noOfNodes)).abs + 1.asInteger
        var weight := (random.next.rem(MaxWeight - MinWeight + 1.asInteger)).abs + MinWeight
        graph.at(i).append(EdgeNewWith (nodeId) and (weight))
        graph.at(nodeId).append(EdgeNewWith (i) and (weight))
      }
    }

    totalEdges := 0.asInteger
    graph.doIndexes { i ->
      var noOfEdges := graph.at(i).size
      graphNodes.at (i) put (NodeNewWith (totalEdges + 1.asInteger) and (noOfEdges))
      totalEdges := totalEdges + noOfEdges
    }

    graphMask.at (source) put (true)
    graphVisited.at (source) put (true)

    graphEdges := platform.kernel.Array.new (totalEdges) withAll (0.asInteger)

    var k := 1.asInteger
    graph.do { i ->
      i.do { j ->
        graphEdges.at (k) put (j.dest)
        k := k + 1.asInteger
      }
    }
    cost.at (source) put (0.asInteger)
  }

  method breadthFirstSearch (noOfNodes) {
    var stop := true
    
    { stop }.whileTrue {
      stop := false

      1.asInteger.to (noOfNodes) do { tid ->
        graphMask.at(tid).ifTrue {
          graphMask.at(tid)put (false)
          graphNodes.at (tid).starting.to (graphNodes.at(tid).noOfEdges + graphNodes.at(tid).starting - 1.asInteger)
              do { i ->
            var id := graphEdges.at (i)
            graphVisited.at (id). ifFalse {
              cost. at (id) put (cost.at(tid) + 1.asInteger)
              updatingGraphMask.at (id) put (true)
            }
          }
        }
      }

      1.asInteger.to(noOfNodes) do { tid ->
        updatingGraphMask.at(tid). ifTrue {
          graphMask.at (tid) put (true)
          graphVisited.at (tid) put (true)
          stop := true
          updatingGraphMask.at (tid) put (false)
        }
      }
    }
  }

  method run (innerIterations) {
    var r := random.Jenkins(49734321.asInteger)
    var noOfNodes := (ExpectedNoOfNodes / 1000.asInteger).asInteger * innerIterations
    
    initializeGraph (noOfNodes) with (r)
    breadthFirstSearch (noOfNodes)

    (cost.size == ((ExpectedNoOfNodes / 1000.asInteger).asInteger * innerIterations)).ifFalse {
      return false
    }

    var totalCost := 0
    cost.do { c ->
      totalCost := totalCost + c
    }

    (cost.size == ExpectedNoOfNodes).ifTrue {
        (totalCost == ExpectedTotalCost).ifFalse {
          error("{self} failed, {totalCost} != {ExpectedTotalCost}")
        }
    } ifFalse {
      (firstCost.isNil).ifTrue {
        firstCost := totalCost
        return true
      } ifFalse {
        return firstCost == totalCost
      }
    }

    true
  }
}

method asString {"GraphSearch.grace"}
  
method benchmark(innerIterations) {
  GraphSearch.run(innerIterations)
}