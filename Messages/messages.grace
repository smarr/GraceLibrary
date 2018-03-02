type Secure = type { 
    iAmBrandedSecure  
}

type Message = type {
    asString    
}

class message {
    method asString { "I am a message" }   
}

class secureMessage {
    method asString { "I am a SECURE message" }   
    method iAmBrandedSecure { Exception.raise "crash" }
}

class listener {
    method accept (m : Message) { }
    method secure (m : Message & Secure) { }
    method asString {
      "Listener"
    }
}

method unsecureAccept(l: Unknown, m: Message) {
  try {
    l.accept(m)
    print("{l} accepted \"{m}\" insecurely")
  } catch { e: TypeError ->
    print("{l} rejected \"{m}\" insecurely")
  }
}

method secureAccept(l: Unknown, m: Message) {
  try {
    l.secure(m)
    print("{l} accepted \"{m}\" securely")
  } catch { e: TypeError ->
    print("{l} rejected \"{m}\" securely")
  }
}

def l = listener
def m = message
def s = secureMessage

unsecureAccept(l, s)
unsecureAccept(l, m)
secureAccept(l, s)
secureAccept(l, m)


