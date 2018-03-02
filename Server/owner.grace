method somDirectory {
  return platform.files.FilePath.currentDirectory.pattern
}

method readUnicodeStringFromSomDirectory(path: String) {
  def filepath: String = String(somDirectory) ++ path
  platform.files.FilePath.for(filepath.value).read.readToUnicodeString
}

method readBase64StringFromSomDirectory(path: String) {
  def filepath: String = String(somDirectory) ++ path
  platform.files.FilePath.for(filepath.value).read.readToBase64String
}

method exitWithError(message: String) {
  platform.system.error(message.value)
}

def Done = object {
  method asString { return "Done" }
}

method getMethodNames(obj) {
  var x := platform.mirrors.ClassMirror.reflecting(obj).methodNames
  var n := x.size

  var y := platform.kernel.Array.new(n)
  for (1 .. n) do { i ->
    y.at(i)put(String(x.at(i)))
  }

  return y
}

method check(other) conformsTo (typeObj) {
  def otherMethods = getMethodNames(other)
  def typeMethods = getMethodNames(typeObj)
  
  typeMethods.doForGrace { typeMethodName ->

    var found := false
    var isMatch := typeMethodName == "match:"
    var isAsString := typeMethodName == "asString"

    if (isMatch || isAsString) then {
      // Set true for all implicit methods
      found := true

    } else {
      // Search for matching method signature
      otherMethods.doForGrace { otherMethodName ->
        if (typeMethodName == otherMethodName) then {
          found := true
        }
      }  
    }

    if (!found) then {
      return false
    }
  }

  return true
}

class TypeSuper {
  
  method match (other) {
    if (check(other) conformsTo (self)) then {
      return true // should be SuccessfulMatch?
    } else {
      return false // should be FailedMatch?
    }
  }
}

type String = type {
    ++(o : String) -> String
}

type Number = type {
    +(o : Number) -> Number
    *(o : Number) -> Number
    -(o : Number) -> Number
    /(o : Number) -> Number
    %(o : Number) -> Number
    <(o : Number) -> Number
    >(o : Number) -> Number

    ^(o : Number) -> Number
}

type Boolean = type {
    ifTrue(b) -> Done
    ifFalse(b) -> Done
    ifTrue(b1) ifFalse(b2)
    &&(o : Boolean) -> Boolean
    ||(o : Boolean) -> Boolean
}

class _SuccessfulMatch(obj') {
  def obj = obj'

  def succeeded is public = true
  def asString is public = "{obj}"
  method result {
      obj
  }
  method ifTrue(blk) {
    blk.apply
  }
  method ifFalse(blk) { }
  method ifTrue(blk) ifFalse(_) {
      blk.apply
  }
}

class _FailedMatch(obj') {
  def obj = obj'

  def succeeded is public = false
  def asString is public = "Failure[{obj}]"
  method result {
      obj
  }
  method ifFalse(blk) {
      blk.apply
  }
  method ifTrue(blk) { }
  method ifTrue(_) ifFalse(blk) {
      blk.apply
  }
}


class BooleanBase {
  inherit GraceObject

  method ifTrue (blk) { error }
  method ifFalse (blk) { error}

  method ifTrue(trueBlk) ifFalse (falseBlk) {
    ifTrue { return trueBlk.apply } 
    ifFalse { return falseBlk.apply }
  }

  method ifFalse(falseBlk) ifTrue (trueBlk) {
    ifTrue { return trueBlk.apply } 
    ifFalse { return falseBlk.apply }
  }

  method not {
    ifTrue { return false }
    ifFalse { return true }
  }

  method || (other) {
    ifTrue { return true }
    other.ifTrue { return true }
    return false
  }

  method && (other) {
    ifFalse { return false }
    ifTrue { other.ifTrue { return true } ifFalse { return false } }
  }

  method asString {
    ifTrue { return "true" }
    ifFalse { return "false" }
  }
}

def true = object {
  inherit BooleanBase
  method ifTrue (blk) { return blk.apply }
  method ifFalse (blk) { return Done }
  method andAlso (blk) { return blk.apply }
  method orElse (blk) { return true }
}

def false = object {
  inherit BooleanBase
  method ifTrue (blk) { return Done }
  method ifFalse (blk) { return blk.apply }
  method andAlso (blk) { return false }
  method orElse (blk) { return blk.apply }
}

method Boolean(value) {
  value.ifFalseWithGraceBlock { return false }
  value.ifTrueWithGraceBlock { return true }
}

class GraceObject {
  method doesNotUnderstand(selector) arguments(arguments) {
    Error.raise("Message {selector} not understand by {self}")
  }

  method == (o: Number) -> Boolean { Boolean(self.equals(o)) }
  method != (o: Number) -> Boolean { !(self == o) }

  // Pattern matching
  method match (other) {
    if (self == other) then {
      return _SuccessfulMatch(other)
    } else {
      return _FailedMatch(other)
    }
  }

  method |(o) {
      OrPattern(self, o)
  }
  method &(o) {
      AndPattern(self, o)
  }

  method OrPattern(l, r) {
    object {
      method match(o) {
          def mr = l.match(o)
          def mr2 = r.match(o)

          if (mr) then {
              return mr
          }
          
          if (mr2) then {
              return mr2
          }
          false
      }
      method |(o) {
          OrPattern(self, o)
      }
      method &(o) {
          AndPattern(self, o)
      }
      method asString {
        return "{l} | {r}"
      }
    }
  }

  method AndPattern(l, r) {
      object {
        method match(o) {
          def mr = l.match(o)
          if (mr) then {
              def mr2 = r.match(o)
              return mr2
          }
          return mr
        }
        method |(o) {
            OrPattern(self, o)
        }
        method &(o) {
            AndPattern(self, o)
        }
        method asString {
          return "{l} & {r}"
        }
    }
  }
}

class Number(value') {
  inherit GraceObject

  def value is confidental = value'

  // Equality
  method == (o: Number) -> Boolean { Boolean(self.value.equals(o.value)) }
  method != (o: Number) -> Boolean { !(self == o) }
  method .. (o: Number) -> List { return value.asInteger.to(o.value.asInteger) }

  // Arithmetic
  method +(o : Number) -> Number { return Number(value + o.value) }
  method *(o : Number) -> Number { return Number(value * o.value) }
  method -(o : Number) -> Number { return Number(value - o.value) }
  method /(o : Number) -> Number { return Number(value / o.value) }
  method %(o : Number) -> Number { return Number(value % o.value) }
  method ^(o : Number) -> Number { return Number(value.power(o.value)) }

  // Comparison
  method <(o : Number) -> Boolean { return Boolean(value < o.value) }
  method <=(o : Number) -> Boolean { return Boolean(value <= o.value) }
  method >(o : Number) -> Boolean { return Boolean(value > o.value) }
  method >=(o : Number) -> Boolean { return Boolean(value >= o.value) }

  // Other operations
  method truncated -> Number {
    return value.round.asDouble
  }

  method negated -> Number {
    return Number(value * (0 - 1).value)
  }

  // Printing
  method asString {
    if (self == truncated) then {
      return String(value.asInteger.asString)
    } else {
      return String(value.asString)  
    }
  }
}


class String(value') {
  inherit GraceObject

  def value is confidental = value'

  method == (o: String) -> Boolean { return Boolean(o.value.equals(value)) }
  method != (o: Number) -> Boolean { !(self == o) }
  method ++ (other) { return String(asString.value + other.asString.value) }
  method println {
    value.println
    return Done
  }

  method size { return Number(value.length) }
  method asString { return self } 
}

class Block(blk') {
  def blk is confidental = blk'

  method value { blk.value }
  method apply { blk.value }
  method apply(x) { blk.value(x) }
  method apply(x, y) { blk.value(x)with(y) }

  method whileTrue(otherBlk) {
    apply.ifFalse { return Done }
    otherBlk.blk.value
    return whileTrue(otherBlk)
  }

  method asString {
    return "GraceBlock[" ++ String(blk.asString) ++ "]"
  }
}

method printMethods(obj) {
  getMethodNames(obj).do { name ->
    print(name)
  }
}

method print (x) {
  x.asString.println
}

method if (cond) then (passBlk) {
  cond.ifTrue(passBlk)
}

method if (cond) then (passBlk) else (failBlk) {
  cond.ifTrue (passBlk) ifFalse (failBlk)
}

method if (cond1) then (passBlk1) elseif (cond2) then (passBlk2) {
  cond1.ifTrue (passBlk1) ifFalse ({
    if (cond2.apply) then(passBlk2)
  })
}

method if (cond1) then (passBlk1) elseif (cond2) then (passBlk2) else (failBlk) {
  cond1.ifTrue (passBlk1) ifFalse ({
    if (cond2.apply) then (passBlk2) else (failBlk)
  })
}

method if (cond1) then (passBlk1) elseif (cond2) then (passBlk2) elseif (cond3) then (passBlk3) {
  cond1.ifTrue (passBlk1) ifFalse ({
    if (cond2.apply) then (passBlk2) elseif (cond3) then (passBlk3)
  })
}

method if (cond1) then (passBlk1) elseif (cond2) then (passBlk2) elseif (cond3) then (passBlk3) else (failBlk) {
  cond1.ifTrue (passBlk1) ifFalse ({
    if (cond2.apply) then (passBlk2) elseif (cond3) then (passBlk3) else (failBlk)
  })
}

method repeat (n) times (blk) {
  var i := 0
  while { i < n } do {
    blk.apply
    i := i + 1
  }
}

method for (iterable) do (blk) {
  iterable.doForGrace(blk)
}

method while (cond) do (blk) {
  cond.whileTrue(blk)
}

method do (blk) while (cond) {
  blk.apply
  while (cond) do (blk)
}

class AnyMatchingObject(blk') {
  def blk = blk'

  method match (other) {
    return _SuccessfulMatch(blk.apply(other))
  }  

  method apply(other) {
    return blk.apply(other)
  }

  method asString {
    return "AnyMatchingObject[]"
  }
}

class LiteralMatchingObject (lit', blk') {
  def blk = blk'
  def lit = lit'

  method match (other) {
    if (lit.match(other)) then {
      return _SuccessfulMatch(blk.apply(other))
    } else {
      return _FailedMatch(other)
    }
  }  

  method apply(other) {
    return blk.apply(other)
  }

  method asString {
    return "LiteralMatchingObject[{lit}]"
  }
}

class TypeMatchingObject (typeObj', blk') {
  def typeObj = typeObj'
  def blk = blk'

  method match (other) {
    if (check(other) conformsTo (typeObj)) then {
      return _SuccessfulMatch(blk.apply(other))
    } else {
      return _FailedMatch(other)
    }
  }

  method compareBrand(other) {
    return typeObj.brand == other.brand
  }

  method apply(other) {
    return blk.apply(other)
  }

  method asString {
    return "TypeMatchingObject[{typeObj}]"
  }
}

method match(target) against(cases) {
  cases.doForGrace { case ->
    var mr := case.match(target)
    if (mr) then {
      return mr
    }
  }

  fail ("Match case fell through")
}

method match(target)
  case(case) {
    var mr := case.match(target)
    if (mr) then {
      return mr
    } else {
      fail ("Match case fell through")
    }
}

method match(target)
  case(case1)
  case(case2) {
    var mr := case1.match(target)
    if (mr) then {
      return mr
    } else {
      match(target)
        case(case2)
    }
}

method match(target)
  case(case1)
  case(case2)
  case(case3) {
    
    var mr := case1.match(target)
    if (mr) then {
      return mr
    } else {
      match(target)
        case(case2)
        case(case3)
    }
}

method match(target)
  case(case1)
  case(case2)
  case(case3)
  case(case4) {
    var mr := case1.match(target)
    if (mr) then {
      return mr
    } else {
      match(target)
        case(case2)
        case(case3)
        case(case4)
    }
}

method match(target)
  case(case1)
  case(case2)
  case(case3)
  case(case4)
  case(case5) {
    var mr := case1.match(target)
    if (mr) then {
      return mr
    } else {
      match(target)
        case(case2)
        case(case3)
        case(case4)
        case(case5)
    }
}

method match(target)
  case(case1)
  case(case2)
  case(case3)
  case(case4)
  case(case5)
  case(case6) {
    var mr := case1.match(target)
    if (mr) then {
      return mr
    } else {
      match(target)
        case(case2)
        case(case3)
        case(case4)
        case(case5)
        case(case6)
    }
}

method match(target)
  case(case1)
  case(case2)
  case(case3)
  case(case4)
  case(case5)
  case(case6)
  case(case7) {
    var mr := case1.match(target)
    if (mr) then {
      return mr
    } else {
      match(target)
        case(case2)
        case(case3)
        case(case4)
        case(case5)
        case(case6)
        case(case7)
    }
}


method match(target)
  case(case1)
  case(case2)
  case(case3)
  case(case4)
  case(case5)
  case(case6)
  case(case7)
  case(case8) {
    var mr := case1.match(target)
    if (mr) then {
      return mr
    } else {
      match(target)
        case(case2)
        case(case3)
        case(case4)
        case(case5)
        case(case6)
        case(case7)
        case(case8)
    }
}

method match(target)
  case(case1)
  case(case2)
  case(case3)
  case(case4)
  case(case5)
  case(case6)
  case(case7)
  case(case8)
  case(case9) {
    var mr := case1.match(target)
    if (mr) then {
      return mr
    } else {
      match(target)
        case(case2)
        case(case3)
        case(case4)
        case(case5)
        case(case6)
        case(case7)
        case(case8)
        case(case9)
    }
}

method fail(msg) {
  Error.raise(msg)
}

class Exception {
    inherit platform.kernel.SOMException
    var brand := "Exception"
    var message := ""

    method refine(brand') {
        brand := brand'
        return self
    }

    method raise(msg) {
        message := msg
        signal
    }

    method asString {
        // TODO: make grace Exception handler in VM so that `.value` is not needed below.
        return "{brand}: {message}".value
    }
}

def Error = Exception.refine("Error")
def RuntimeError = Exception.refine("RuntimeError")
def ProgrammingError = Exception.refine("ProgrammingError")

method try(b) finally(f) {
    b.apply
    f.apply
}


method try(b) catch(e1) {
    b.blk.catch({ e ->
      if (e1.compareBrand(e)) then {
        e1.apply(e)
      } 
    }.blk)
}

method try(b) catch(e1) finally(f) {
    b.blk.catch({ e ->
      if (e1.compareBrand(e)) then {
        e1.apply(e)
      }
    }.blk)
    f.apply
}

method try(b) catch(e1) catch(e2) {
    b.blk.catch({ e ->
      if (e1.compareBrand(e)) then {
        e1.apply(e)
      } elseif { e2.compareBrand(e) } then {
        e2.apply(e)
      } 
    }.blk)
}
