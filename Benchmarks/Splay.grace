// Copyright 2009 the V8 project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// This benchmark is based on a JavaScript log processing module used
// by the V8 profiler to generate execution time profiles for runs of
// JavaScript applications, and it effectively measures how fast the
// JavaScript engine is at allocating nodes and reclaiming the memory
// used for old nodes. Because of the way splay trees work, the engine
// also has to deal with a lot of changes to the large tree object
// graph.




// Splay Benchmark
//
//   Translated for Moth from TypeScript
//   24/05/2018
//   Richard Roberts

import "random" as random

type Node = interface {
    left
    right
    traverse(f)
}

class Node(key: Number, value) {
    var left : Node
    var right : Node

    method traverse(f) {
        var current: Node := self
        { current.isNil.not }.whileTrue {
            var left := current.left
            (left.isNil.not).ifTrue {
                left.traverse(f)
            } 
            f.apply(current)
            current := current.right
        }
    }
}

class SplayTree {

    var root

    method insert(key: Number, value) {
        root.isNil.ifTrue {
            root := Node(key, value)
            return
        }

        // Splay on the key to move the last node on the search path for
        // the key to the root of the tree.
        splay(key)
        (root.key == key).ifTrue {
            return
        }

        var node := Node(key, value)
        (key > root.key).ifTrue {
            node.left := root
            node.right := root.right
            root.right := Done
        } ifFalse {
            node.right := root
            node.left := root.left
            root.left := Done
        }
        root := node
    }

    method remove(key) {
        (root.isNil).ifTrue { self.error("Key not found: {key}") }
        splay(key)
        (root.key != key).ifTrue { self.error("Key not found: {key}") }

        var removed := root
        (root.left.isNil).ifTrue {
            root := root.right
        } ifFalse {
            var right := root.right
            root := root.left
            splay(key)
            root.right := right
        }
        
        removed
    }

    method find(key) {
        root.isNil.ifTrue { return Done }
        splay(key)

        (root.key == key).ifTrue {
            return root
        }

        Done
    }

    method findMax(opt_startNode: Node) -> Node {
        (root.isNil).ifTrue { return Done }
        
        var current : Node
        (opt_startNode.isNil).ifTrue {
            current := root
        } ifFalse {
            current := opt_startNode
        }

        { current.right.isNil.not }.whileTrue {
            current := current.right
        }
        
        current
    }

    method findGreatestLessThan(key) -> Node {
        root.isNil.ifTrue { return Done }
        splay(key)
        (root.key < key).ifTrue {
            return root
        } ifFalse {
            root.left.isNil.not.ifTrue {
                return findMax(root.left)
            } ifFalse {
                return Done
            }
        }
    }

    method exportKeys {
        var result := platform.kernel.Vector.new
        (!root.isNil).ifTrue {
            root.traverse({ node -> result.append(node.key) })
        }
        result
    }

    method splay(key) {
        root.isNil.ifTrue {
            return
        }
        
        var dummy: Node := Node(-1.asInteger, Done)
        var left := dummy
        var right := dummy
        var current := root

        object {
            method exe {
                { true }.whileTrue {
                    (key < current.key).ifTrue {
                        (current.left.isNil).ifTrue {
                            return
                        }
                        (key < current.left.key).ifTrue {
                            // Rotate right.
                            var tmp := current.left
                            current.left := tmp.right
                            tmp.right := current
                            current := tmp
                            (current.left.isNil).ifTrue {
                                return
                            }
                        }
                        // Link right.
                        right.left := current
                        right := current
                        current := current.left
                    } ifFalse {
                        (key > current.key).ifTrue {
                            (current.right.isNil).ifTrue {
                                return
                            }
                            (key > current.right.key).ifTrue {
                                var tmp := current.right
                                current.right := tmp.left
                                tmp.left := current
                                current := tmp
                                (current.right.isNil).ifTrue {
                                    return
                                }
                            }

                            left.right := current
                            left := current
                            current := current.right
                        } ifFalse {
                            return
                        }
                    }
                }
            }
        }.exe
        
        left.right := current.left
        right.left := current.right
        current.left := dummy.right
        current.right := dummy.left
        root := current
    }
}


method GeneratePayloadTree(depth: Number, tag: Number) {
    (depth == 0.asInteger).ifTrue {
        return object {
            var array := platform.kernel.Vector.new
            [0.asInteger, 1.asInteger, 2.asInteger, 3.asInteger, 4.asInteger, 5.asInteger, 6.asInteger, 7.asInteger, 8.asInteger, 9.asInteger].do { item ->
                array.append(item)
            }
            var string := "String for key {tag} in leaf node"
        }
    } ifFalse {
        return object {
            var left := GeneratePayloadTree(depth - 1.asInteger, tag)
            var right := GeneratePayloadTree(depth - 1.asInteger, tag)
        }
    }
}



var treeSize := 100.asInteger
var kSplayTreeModifications := 80.asInteger
var kSplayTreePayloadDepth := 5.asInteger
var splayTree := Done


method insertNewNode {
    var key: Number := random.random
    { splayTree.find(key) != Done }.whileTrue {
        key := random.random
    }
    
    var payload := GeneratePayloadTree(kSplayTreePayloadDepth, key)
    splayTree.insert(key, payload)
    key
}



method setup {
    splayTree := SplayTree
    1.asInteger.to (treeSize) do { i -> insertNewNode }
}


method verify {

    var keys := splayTree.exportKeys
    splayTree := Done

    var length := keys.size
    (length != treeSize).ifTrue { return false }

    1.asInteger.to(length - 1) do { i ->
        (keys.at(i) >= keys.at(i + 1.asInteger)).ifTrue { return false }
    }

    true
}

method run {
    1.asInteger.to(kSplayTreeModifications) do { i -> 
        var key := insertNewNode
        var greatest := splayTree.findGreatestLessThan(key)
        (greatest.isNil).ifTrue {
            splayTree.remove(key)
        } ifFalse {
            splayTree.remove(greatest.key)    
        }
    }
}

method benchmark { 
    setup
    run
    verify
}
