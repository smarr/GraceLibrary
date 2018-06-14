var one
var calls

class datum(v) {
    method succ {
        datum(v + 1)
    }
    method pred {
        datum(v - 1)
    }
    method iszero {
        v == 0
    }
    method asString {
        "Datum {v}"
    }
}

type Datum = interface {
    succ -> Datum
    pred -> Datum
    iszero -> Boolean
    asString -> String
}

method ack(m : Datum, n : Datum) -> Datum {
    calls := calls + 1
    (m.iszero).ifTrue {
        return n.succ
    }

    (n.iszero).ifTrue {
        return ack(m.pred, one)
    }

    return ack(m.pred, ack(m, n.pred))
}

class datumR(inner) {
    method succ {
        datumR(self)
    }
    method pred {
        inner
    }
    method iszero {
        false
    }
    method asString {
        "DatumR {length}"
    }
    method length {
        1 + inner.length
    }
}

def oneR = datumR(object {
    method succ {
        datumR(self)
    }
    method pred {
        self
    }
    method iszero {
        true
    }
    def length is public = 0
})

method benchmark {
    one := datum(1)
    calls := 0
    ack(datum 3, datum 4)

    one := oneR
    calls := 0
    ack(oneR.succ.succ, oneR.succ.succ.succ)
}

