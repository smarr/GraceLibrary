method print(x) {
  x.println
}

method if (cond) then (block) {
  cond.ifTrue(block)
}

method for (indices) do (block) {
  indices.do(block)
}

method while (cond) do (block) {
  cond.whileTrue(block)
}
