method methodNamesForObject(obj) {
  def methodMirrors = platform.mirrors.ClassMirror.reflecting(obj).methods
  def methodNames = platform.kernel.Array.new(methodMirrors.size)

  var i := 1
  methodMirrors.do { methodMirror ->
    methodNames.at (i.asInteger) put (methodMirror.name)
    i := i + 1
  }

  methodNames
}

method invoke (methodName) on (obj) {
  def objMirror = platform.mirrors.ObjectMirror.reflecting(obj)
  objMirror.perform(methodName.asSymbol)
}

method invoke (methodName) on (obj) withArguments (args) {
  def objMirror = platform.mirrors.ObjectMirror.reflecting(obj)
  objMirror.perform(methodName.asSymbol)withArguments(args)
}
