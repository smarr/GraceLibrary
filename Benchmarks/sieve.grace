def warmupIterations = 100
def steadyOuterIterations = 60
def steadyInnerIterations = 400

method Sieve {
  var flags := platform.kernel.Array.new(5000.asInteger)
  var size := 5000
  
  var primeCount := 0
  flags.putAll(true)

  2.asInteger.to(size.asInteger)do { i ->
    if (flags.at(i - 1.asInteger)) then {
      primeCount := primeCount + 1
      var k := i + i
      { k <= size.asInteger }.whileTrue {
        flags.at (k - 1.asInteger) put (false)
        k := k + i
      }
    }
  }
  
  primeCount
}

method benchmark {
  def expected = 669
  def result = Sieve
  if (result != expected) then {
    self.error("Expected value " + expected.asString + " differs from actual benchmark result " + result.asString)
  }
}
