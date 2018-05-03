import "io" as io
import "mirrors" as mirrors

method getTestByName(name) {
  io.importModuleByName(name)
}

method findTestsInModule(module) {
  def names = mirrors.methodNamesForObject(module)

  var n := 0
  names.do { name ->
    if (name.beginsWith("test")) then {
      n := n + 1
    }
  }

  def testNames = platform.kernel.Array.new(n.asInteger)
  var i := 1
  names.do { name ->
    if (name.beginsWith("test")) then {
      testNames.at (i.asInteger) put(name)
      i := i + 1
    }
  }

  testNames
}

method runTestsInModule(moduleName) {
  var testModule := getTestByName(moduleName)
  var names := findTestsInModule(testModule)

  print("Running tests on " + testModule.asString)
  names.do { name ->
    print("  " + mirrors.invoke (name) on (testModule))
  }
}

runTestsInModule(args.at(2.asInteger))
