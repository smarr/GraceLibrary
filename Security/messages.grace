import "mirrors" as mirrors

type MessagePacket = interface {
    receiver -> graceObject
    selector -> String
    asString -> String
}

type SecureMessagePacket = MessagePacket & interface { 
    brand -> Unknown
}

type Protocol = interface { 
    sendMessage (message : MessagePacket) -> Unknown
    sendSafely (message : SecureMessagePacket) -> Unknown
    sanitize (message : MessagePacket) -> SecureMessagePacket
}

class BaseProtocol {

    class createMessagePacket(receiver' : Unknown, selector': String) -> MessagePacket {
        def receiver = receiver'
        def selector = selector'

        method asString {
          return "Packet[[{receiver}, {selector}]]"
        }
    }

    class createSafeMessagePacket(receiver' : Unknown, selector': String) -> SecureMessagePacket {
        def receiver = receiver'
        def selector = selector'

        method asString {
          return "Packet[[{receiver}, {selector}]]"
        }
    }

    method sendMessage (message : MessagePacket) -> Unknown {
        ProgrammingError.raise("The sendMessage method must be implemented by subclasses of Protocol")
    }

}

class NoopProtocol {
    inherit BaseProtocol

    method sendMessage (message : MessagePacket) -> Unknown {
        mirrors.invoke(message.selector)on(message.receiver)
    }

    method asString {
      "NoopProtocol"
    }
}


class SafeProtocol {
    inherit BaseProtocol

    method failTypeCheckWhenNotSafe(message : SecureMessagePacket) {}

    method sendMessage (message : MessagePacket) -> Unknown {
        failTypeCheckWhenNotSafe(message)
        mirrors.invoke(message.selector)on(message.receiver)
    }

    method asString {
      "SafeProtocol"
    }

}


class SanitizeProtocol {
    inherit BaseProtocol

    method failTypeCheckWhenNotSafe(message : SecureMessagePacket) {}

    method sendMessage (message : MessagePacket) -> Unknown {
        try {
            failTypeCheckWhenNotSafe(message)
            mirrors.invoke(message.selector)on(message.receiver)
        } catch { e: TypeError ->
            var safeMessage := sanitize(message)
            mirrors.invoke(safeMessage.selector)on(safeMessage.receiver)
        }
    }

    method sanitize (message : MessagePacket) -> SecureMessagePacket {
        print("Message #{message.selector} is being sanitized")
        return createSafeMessagePacket(message.receiver, message.selector)
    }

    method asString {
      "SanitizeProtocol"
    }

}
