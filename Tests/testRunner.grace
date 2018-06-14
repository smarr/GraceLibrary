import "io" as io
import "mirrors" as mirrors

method getSuiteByName(name) {
  io.importModuleByName(name)
}

method findTestsInSuite(module) {
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

method runTests(moduleName) {
  var suite := getSuiteByName(moduleName)
  var names := findTestsInSuite(suite)

  print("Running tests in " + suite.asString)
  names.do { name ->
    print("  " + mirrors.invoke (name) on (suite))
  }
}

method exe(args) {
  def n = args.size
  (n == 1).ifTrue {
    runTests("GraceLibrary/Tests/language.grace")
    runTests("GraceLibrary/Tests/modules.grace")
    runTests("GraceLibrary/Tests/types.grace")
  } ifFalse {
    runTests(args.at(2.asInteger))
  }
}

exe(args)
