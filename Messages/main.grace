import "../Security/messages" as m

def anA = object {

  method foo {
    "Doing foo"
  }

  method asString {
    "an A"
  }

}


var protocol
var packet

print("Running with NoopProtocol")
protocol := m.NoopProtocol
packet := protocol.createMessagePacket(anA, "foo")
protocol.sendMessage(packet)

print("Running with SanitizeProtocol")
protocol := m.SanitizeProtocol
packet := protocol.createMessagePacket(anA, "foo")
protocol.sendMessage(packet)

print("Running with SafeProtocol")
protocol := m.SafeProtocol
packet := protocol.createMessagePacket(anA, "foo")
protocol.sendMessage(packet)
