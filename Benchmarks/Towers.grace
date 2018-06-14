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
// Mmm... Hanoi...
//
//
// Adapted for Grace by Richard Roberts
//   2018, June
//

type Disk = interface {
  setNext(item)
}

class Towers {

  var piles := platform.kernel.Array.new(4.asInteger)
  var movesDone := 0

  class newTowersDisk(size: Number) {
    var next

    method setNext(item) {
      next := item
    }

    method getSize {
      size
    }
  }

  method pushDisk (disk: Disk) onPile (pile: Number) {
    var top := piles.at(pile.asInteger)
    
    var x := top.isNil
    if (!x) then {
      if (disk.getSize >= top.getSize) then {
        self.error("Cannot put a bigger disk on a smaller one")
      }
    }

    disk.setNext(top)
    piles.at(pile.asInteger)put(disk)
  }

  method popDiskFrom(pile: Number) {
    var top := piles.at(pile.asInteger)
    var x := top.isNil
    if (x) then {
      self.error("Attempting to remove a disk from an empty pile")
    }

    piles.at(pile.asInteger)put(top.next)
    top.setNext(platform.kernel.Nil.new)
    top
  }

  method moveTopDiskFrom (fromPile: Number) to (toPile: Number) {
    var disk := popDiskFrom (fromPile)
    pushDisk (disk) onPile (toPile)
    movesDone := movesDone + 1
  }

  method buildTowerAt(pile: Number) disks(disks: Number) {
    disks.asInteger.downTo(1) do { size ->
      var disk := newTowersDisk(size)
      pushDisk (disk) onPile (pile)
    }
  }

  method move (disks: Number) disksFrom (fromPile: Number) to (toPile: Number) {
    (disks == 1).ifTrue {
      moveTopDiskFrom (fromPile) to (toPile)
    } ifFalse {
      var otherPile := 6 - fromPile - toPile
      move (disks - 1) disksFrom (fromPile) to (otherPile)
      moveTopDiskFrom (fromPile) to (toPile)
      move (disks - 1) disksFrom (otherPile) to (toPile)
    }
  }
}

method asString {"Towers.grace"}

method benchmark(innerIterations) {
  1.asInteger.to(innerIterations) do { i ->
    def towers = Towers
    towers.buildTowerAt(1) disks(13)
    towers.move(13) disksFrom(1) to(2)

    def result = towers.movesDone
    if (result != 8191) then {
      error("{self} failed, {result} != 8191")
    }
  }
}
