def warmupIterations = 60
def steadyOuterIterations = 60
def steadyInnerIterations = 300


class Towers {
  var piles := platform.kernel.Array.new(4.asInteger)
  var movesDone := 0
  class newTowersDisk(size) {
    var next

    method setNext(item) {
      next := item
    }

    method getSize {
      size
    }
  }

  method pushDisk (disk) onPile (pile) {
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

  method popDiskFrom(pile) {
    var top := piles.at(pile.asInteger)
    var x := top.isNil
    if (x) then {
      self.error("Attempting to remove a disk from an empty pile")
    }

    piles.at(pile.asInteger)put(top.next)
    top.setNext(platform.kernel.Nil.new)
    top
  }

  method moveTopDiskFrom (fromPile) to (toPile) {
    var disk := popDiskFrom (fromPile)
    pushDisk (disk) onPile (toPile)
    movesDone := movesDone + 1
  }

  method buildTowerAt(pile) disks(disks) {
    disks.asInteger.downTo(1) do { size ->
      var disk := newTowersDisk(size)
      pushDisk (disk) onPile (pile)
    }
  }

  method move (disks) disksFrom (fromPile) to (toPile) {
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

method benchmark {
  def towers = Towers
  towers.buildTowerAt(1) disks(13)
  towers.move(13) disksFrom(1) to(2)

  def result = towers.movesDone
  def expected = 8191
  if (result != expected) then {
    self.error("Expected value " + expected.asString + " differs from actual benchmark result " + result.asString)
  }
}
