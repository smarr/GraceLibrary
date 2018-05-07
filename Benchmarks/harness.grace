import "io" as io
import "mirrors" as mirrors

// Configuration
//
// Set `pretty` to true for human-readable output and set `csv` to true
// for csv output.
var pretty := false
var csv := false

method prettyPrint(x) {
  if (pretty) then {
    print(x)
  }
}

method printCsv(x) {
  if (csv) then {
    print(x)
  }
}

method getSuiteByName(name) {
  io.importModuleByName(name)
}

method findBenchmarksInSuite(module) {
  def names = mirrors.methodNamesForObject(module)

  var n := 0
  names.do { name ->
    if (name.beginsWith("benchmark")) then {
      n := n + 1
    }
  }

  def benchmarkNames = platform.kernel.Array.new(n.asInteger)
  var i := 1
  names.do { name ->
    if (name.beginsWith("benchmark")) then {
      benchmarkNames.at (i.asInteger) put(name)
      i := i + 1
    }
  }

  benchmarkNames
}

method doIterations(suite, name, n) {
  1.asInteger.to(n) do {
    i -> mirrors.invoke (name) on (suite)
  }
}


method runBenchmark(suite, name) {

  // warmup
  doIterations(suite, name, suite.warmupIterations.asInteger) 

  // run
  printCsv(name)
  def times = platform.kernel.Array.new(suite.steadyOuterIterations.asInteger)
  var start
  var end
  1.asInteger.to(suite.steadyOuterIterations.asInteger) do { i -> 
    start := platform.system.ticks 
    doIterations(suite, name, suite.steadyInnerIterations.asInteger) 
    end := platform.system.ticks 
    times.at (i) put (end - start)
    printCsv(end - start)
  }
  times

  // Print out human-readable information 
  var micros := 0
  times.do { time -> micros := micros + time }
  def microsAvg = micros / suite.steadyOuterIterations.asInteger
  def millis = micros / 1000
  def millisAvg = microsAvg / 1000
  def seconds = millis / 1000
  prettyPrint("  " + name + " completed in " +
    seconds.asString + "s (n=" + suite.steadyOuterIterations.asInteger + 
    ", avg=" + millisAvg.asInteger + "ms)")
}

method runBenchmarks(moduleName) {
  var suite := getSuiteByName(moduleName)
  var names := findBenchmarksInSuite(suite)

  prettyPrint("Running benchmarks in " + suite.asString)
  names.do { name ->
    runBenchmark(suite, name)
  }
}

// Set the output mode
def mode = args.at(3.asInteger)
if (mode == "pretty") then {
  pretty := true
}
if (mode == "csv") then {
  csv := true
}

// Run the given benchmark
runBenchmarks(args.at(2.asInteger))
