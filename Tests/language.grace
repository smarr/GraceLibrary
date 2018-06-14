method asString {"language.grace"}

method testAdd {
  def expected = 2
  def add = 1 + 1
  if (expected != add) then { return "testAdd failed: {add} != {expected}" }
  "testAdd passed"
}

method testSum {
  def expected = 45
  def sum = 1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9
  if (expected != sum) then { return "testAdd failed" }
  "testSum passed"
}

method testBlockVariableArity {
  def expected = 15

  var result := { 15 }.apply
  if (result != expected) then { return "testBlockVariableArity failed on apply" }

  var result := { i -> i }.apply(15)
  if (result != expected) then { return "testBlockVariableArity failed on apply(_)" }

  var result := { i, j -> i + j }.apply(10, 5)
  if (result != expected) then { return "testBlockVariableArity failed on apply(_, _)" }

  var result := { i, j, k -> i + j + k }.apply(2, 8, 5)
  if (result != expected) then { return "testBlockVariableArity failed on apply(_, _, _)" }

  var result := { i, j, k, l -> i + j + k + l }.apply(1, 1, 8, 5)
  if (result != expected) then { return "testBlockVariableArity failed on apply(_, _, _, _)" }

  var result := { i, j, k, l, m -> i + j + k + l + m }.apply(1, 1, 3, 5, 5)
  if (result != expected) then { return "testBlockVariableArity failed on apply(_, _, _, _, _)" }

  "testBlockVariableArity passed"
}

method testBlockReadingLocals {
  def expected = 42

  var a := 2
  def b = 15

  var result := { i, j ->
    var c := 5
    def d = 5

    a + b + c + d + i + j
  }.apply(10, 5)

  if (result != expected) then { return "testBlockVariableArity failed on apply" }

  "testBlockReadingLocals passed"
}

method testExpressionsInLoops {
  var sum
  var expected

  expected := 55
  sum := 0
  for (1.asInteger.to(10.asInteger)) do { i ->
    sum := sum + i
  }
  if (sum != expected) then { return "testExpressionsInLoops failed on for(_)do(_) {total} != {expected}" }

  expected := 450
  var x := 15
  var y := 3
  var total := 0
  for (1.asInteger.to(x.asInteger)) do { i ->
    for (1.asInteger.to(y.asInteger)) do { j ->
      total := total + i + j
    }
  }
  if (total != expected) then { return "testExpressionsInLoops failed on for(_)do(_): {total} != {expected}" }

  "testExpressionsInLoops passed"
}

class classA {
  method foo {
    123
  }
}

class classB(x) {
  method foo {
    x
  }
}

class classC(x, y) {
  method foo {
    x + y
  }
}

class classD(x, y, z) {
  method foo(w) {
    x + y + z + w
  }
}

method testClass {
  var expected

  expected := 123
  var a := classA
  if (a.foo != expected) then { return "testClass failed on A: {a.foo} != {expected}" }

  expected := 5
  var b := classB(5)
  if (b.foo != expected) then { return "testClass failed on B: {b.foo} != {expected}" }

  expected := 3
  var c := classC(1, 2)
  if (c.foo != expected) then { return "testClass failed on B: {c.foo} != {expected}" }

  expected := 4600
  var d := classD(100, 200, 300)
  var w := 4000
  if (d.foo(w) != expected) then { return "testClass failed on B: {d.foo(w)} != {expected}" }

  "testClass passed"
}


class subA {
  inherit classA
}

class subB {
  inherit classB(42)
}

method testInherits {
  var expected
 
  expected := 123
  var a := subA
  if (a.foo != expected) then { return "testInherits failed on A: {a.foo} != {expected}" }

  expected := 42
  var b := subB
  if (b.foo != expected) then { return "testInherits failed on A: {b.foo} != {expected}" }

  "testInherits passed"
}

method testObjectConstructor {

  def o1 = object { 
    def x = 42
    var y := 42
    method foo {
      42
    }
  }

  var expected := 42
  if (o1.x != expected) then { return "testObjectConstructor failed on o.x {o1.x} != {expected}" }
  if (o1.y != expected) then { return "testObjectConstructor failed on o.y {o1.y} != {expected}" }
  if (o1.foo != expected) then { return "testObjectConstructor failed on o.foo {o1.foo} != {expected}" }

  
  var o2 := object { 
    def x = 41
    var y := 41
    method foo {
      41
    }
  }

  expected := 41
  if (o2.x != expected) then { return "testObjectConstructor failed on o.x {o2.x} != {expected}" }
  if (o2.y != expected) then { return "testObjectConstructor failed on o.y {o2.y} != {expected}" }
  if (o2.foo != expected) then { return "testObjectConstructor failed on o.foo {o2.foo} != {expected}" }

  "testObjectConstructor passed"
}

method testObjectInherits {
  var expected
 
  expected := 123
  var a := object { inherit classA }
  if (a.foo != expected) then { return "testObjectInherits failed on a: {a.foo} != {expected}" }

  expected := 42
  var b := object { inherit classB(42) }
  if (b.foo != expected) then { return "testObjectInherits failed on b: {b.foo} != {expected}" }

  "testObjectInherits passed"
}