// The Computer Language Benchmarks Game
//  https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
//  contributed by Isaac Gouy 
//
/// <reference path="./Include/node/index.d.ts" />
//
//
// Translated to Grace by Richard Roberts, 28/05/2018
//

type List = interface {
   append(value)
   at(ix)
   at(ix)put(value)
}

method approximate(n: Number) -> Number {
   def u = platform.kernel.Vector.new
   def v = platform.kernel.Vector.new

   1.asInteger.to(n) do { i ->
      u.append(1)
   }

   1.asInteger.to(n) do { i ->
      v.append(0)
   }

   1.asInteger.to(10.asInteger) do { i ->
      multiplyAtAv(n,u,v)
      multiplyAtAv(n,v,u)
   }

   def vBv = 0
   def vv = 0.0
   1.asInteger.to(10.asInteger) do { i ->
      vBv := vBv + u.at(i) * v.at(i)
      vv  := vv  + v.at(i) * v.at(i)
   }

   (vBv / vv).sqrt
}

method a(i: Number, j: Number) -> Number {
   1 / ( (i + j) * ((i + j) + 1) / 2 + i + 1 ) 
}

method multiplyAv(n: Number, v: List, av: List) {
   0.asInteger.to(n - 2.asInteger) do { i ->
      av. at (i + 1.asInteger) put (0)
      0.asInteger.to(n - 2.asInteger) do { j ->
         av.at(i + 1.asInteger) put ( av.at(i + 1.asInteger) + a(i, j) * v.at(j + 1.asInteger) )
      }
   }
}

method multiplyAtv(n: Number, v: List, atv: List) {
   0.asInteger.to(n - 2.asInteger) do { i ->
      atv. at (i + 1.asInteger) put (0)
      0.asInteger.to(n - 2.asInteger) do { j ->
         atv. at (i + 1.asInteger) put ( atv.at(i + 1.asInteger) + a(j, i) * v.at(j + 1.asInteger) )
      }
   }
}

method multiplyAtAv(n: Number, v: List, atAv: List) {
   def u = platform.kernel.Vector.new
   1.asInteger.to(n) do { i -> u.append(0) }
   multiplyAv(n,v,u)
   multiplyAtv(n,u,atAv)
}


method benchmark {
   def ret = approximate(5500)
   (ret - 1.2742241527924973).abs < 0.001
}

print(benchmark)