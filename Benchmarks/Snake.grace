import "random" as random

def boardWidth = 100.asInteger
def boardHeight = 100.asInteger
def seed = 24453.asInteger
def minFruitAtStart = 5
def maxFruitAtStart = 10
def appleSpawnWhenRandimGreaterThan = 950

def render = false

type Coordinate = interface {
  x
  y
}

class Coordinate(x: Number, y: Number) {
  method asString {
    "{x}, {y}"
  }
}

method randomCoordinateOnBoard {
  def x = random.randomBetween(1.asInteger)and(boardWidth - 1.asInteger)
  def y = random.randomBetween(1.asInteger)and(boardHeight - 1.asInteger)
  Coordinate(x, y)
}

type Segment = interface {
  coordinate
}

class Segment(coordinate: Coordinate) {
  method asString {
    "Segment[{coordinate.asString}]"
  }
}

type Snake = interface {
  segment(ix)
  nSegments
}

class Snake {
  def segments = platform.kernel.Vector.new
  segments.append(Segment(randomCoordinateOnBoard))

  method reversedIndex(ix:Number) {
    segments.size - ix + 1.asInteger
  }

  method segment(ix: Number) {
    segments.at(reversedIndex(ix))
  }

  method replaceSegmentAt(ix: Number) with (segment: Segment) {
    segments.at(reversedIndex(ix)) put(segment)
  }

  method nSegments {
    segments.size
  }

  method tail {
    segments.at(1.asInteger)
  }

  method isTouching(coordinate: Coordinate) {
    1.asInteger.to(segments.size) do { ix ->
      var item := segments.at(ix)
      ((item.coordinate.x == coordinate.x) && (item.coordinate.y == coordinate.y)).ifTrue {
        return true
      }
    }

    false
  }

  method shiftSegments {
    1.asInteger.to(segments.size - 1.asInteger) do { ix ->
      var seg := segment(ix)
      replaceSegmentAt(ix + 1.asInteger) with(seg)
    }
  }

  method grow(ox, oy) {
    var c := segment(1.asInteger).coordinate
    var x := c.x + ox
    var y := c.y + oy
    segments.append(Segment(Coordinate(x, y)))
  }

  method growLeft  { grow ((0 - 1).asInteger,       0.asInteger) }
  method growRight { grow (      1.asInteger,       0.asInteger) }
  method growUp    { grow (      0.asInteger, (0 - 1).asInteger) }
  method growDown  { grow (      0.asInteger,       1.asInteger) }

  method moveLeft {
    growLeft
    segments.remove(tail)
  }

  method moveRight {
    growRight
    segments.remove(tail)
  }

  method moveUp {
    growUp
    segments.remove(tail)
  }

  method moveDown {
    growDown
    segments.remove(tail)
  }

  method asString {
    var ret := ""
    1.asInteger.to(segments.size) do { ix ->
      var seg := segment(ix)
      ret := ret + "{ix}: {seg}\n"
    }
    ret
  }

}

type Apple = interface {
  coordinate
}

class Apple(coordinate: Coordinate) {}

class Game {

  // Setup
  def snake = Snake
  def food = platform.kernel.Vector.new
  1.asInteger.to(random.randomBetween(minFruitAtStart)and(maxFruitAtStart)) do { i ->
    food.append(Apple(randomCoordinateOnBoard))
  }  

  method isThereFoodAt(coordinate: Coordinate) {
    1.asInteger.to(food.size) do { i ->
      var item := food.at(i)
      ((item.coordinate.x == coordinate.x) && (item.coordinate.y == coordinate.y)).ifTrue {
        return true
      }
    }

    false
  }

  // Collided with foo when the head is at any of the existing foods.
  method hasCollidedWithFood(snake : Snake) {
    var head := snake.segment(1.asInteger)
    1.asInteger.to(food.size) do { i ->
      var item := food.at(i)
      ((head.coordinate.x == item.coordinate.x) && (head.coordinate.y == item.coordinate.y)).ifTrue {
        food.remove(item)
        return true
      }
    }

    false
  }

  // Collided with wall when the head is at or somehow outside the rectangular
  // region defined between (0, 0) and (boardWidth, boardHeight).
  method hasCollidedWithWall(snake : Snake) {
    var head := snake.segment(1.asInteger)
    return (head.coordinate.x <= 0) || (head.coordinate.y <= 0) || (head.coordinate.x >= boardWidth) || (head.coordinate.y >= boardHeight)
  }

  // Collided with self when the head occurs at the same position
  // as any of its body segments
  method hasCollidedWithSelf(snake: Snake) {
    var head := snake.segment(1.asInteger)
    var bodySegment
    2.asInteger.to(snake.nSegments) do { i ->
      bodySegment := snake.segment(i)

      ((head.coordinate.x == bodySegment.coordinate.x) && (head.coordinate.y == bodySegment.coordinate.y)).ifTrue {
        return true
      }
    }

    return false
  }

  // Game is over when the snake eats collides with either a wall or itself
  method isGameOver(snake: Snake) {
    return hasCollidedWithSelf(snake) || hasCollidedWithWall(snake)
  }

  // Given a direction for the snake to move, update the game one step.
  method update(move: String) {
    // (random.randomBetween(1)and(1000) > appleSpawnWhenRandimGreaterThan).ifTrue {
    //   food.append(Apple(randomCoordinateOnBoard))
    // }

    def collided = hasCollidedWithFood(snake)
    collided.ifTrue {
      (move == "left").ifTrue  { snake.growLeft }
      (move == "right").ifTrue { snake.growRight }
      (move == "up").ifTrue    { snake.growUp }
      (move == "down").ifTrue  { snake.growDown }
    } ifFalse {
      (move == "left").ifTrue  { snake.moveLeft }
      (move == "right").ifTrue { snake.moveRight }
      (move == "up").ifTrue    { snake.moveUp }
      (move == "down").ifTrue  { snake.moveDown }
    }
    
  }

  method draw {
    var board_str := ""
    0.asInteger.to(boardWidth) do { x ->
      var row_str := ""
      0.asInteger.to(boardHeight) do { y ->
        var c := Coordinate(x, y)
        var isWall := (x == 0) || (x == boardWidth) || (y == 0) || (y == boardHeight)
        var isFood := isThereFoodAt(c)
        var isSnake := snake.isTouching(c)

        var ascii := " "
        
        isSnake.ifTrue {
          ascii := "S"
        } ifFalse {
          isFood.ifTrue {
            ascii := "O"
          } ifFalse {
            isWall.ifTrue {
              ascii := "X"
            }
          } 
        }
        
        row_str := row_str + ascii
      }
      board_str := board_str + row_str + "\n"
    }
    print(board_str)
  }

  method run(moves) {
    1.asInteger.to(moves.size) do { ix ->
      var move := moves.at(ix)
      update(move)
      
      render.ifTrue {
        draw()
      }
      
      (render && isGameOver(snake)).ifTrue {
        print("Game Over after {ix} moves.")
        return 0
      }
    }
  }

}

method benchmark {
  var moves := platform.kernel.Vector.new
  1.asInteger.to(100.asInteger) do { i ->
    var r := random.randomBetween(0.asInteger)and(4.asInteger)
    (r == 1.asInteger).ifTrue { moves.append("left") }
    (r == 2.asInteger).ifTrue { moves.append("right") }
    (r == 3.asInteger).ifTrue { moves.append("up") }
    (r == 4.asInteger).ifTrue { moves.append("down") }
    
  }
  Game.run(moves)
}
