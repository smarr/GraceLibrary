import "intrinsic" as intrinsic
import "io" as io
import "webPrims" as webPrims

type Packet = interface {
    data -> String
}

type SecurePacket = Packet & interface { 
    safetyBrand -> Unknown
}

class AbstractRequest {
  def brand: String = "Abstract"
  
  method asString {
    "Request[{_brand}]"
  }

  method getResponse(server) {
    ProgrammingError("Subclasses of AbstractRequest must override #getResponse")
  }
}

class GetRequest(path' : String) {
  inherit AbstractRequest
  def brand: String = "Get"
  def path = path'

  method asString {
    super.asString ++ " for `{path}`"
  }

  method buildIndex(server) {
    var indexStart := io.read("pages/indexStart.html")relativeTo(self)
    var indexEnd := io.read("pages/indexEnd.html")relativeTo(self)
    var indexContents := ""

    def data = server.readDatabase
    for (0 .. (data.size - 1)) do { i ->
      indexContents := "{indexContents}<div class=\"post\">{data.at(i)}</div>\n"
    }
    return webPrims.Html("{indexStart}{indexContents}{indexEnd}")
  }

  method getResponse(server) {
    match (path)
      case { "/" ->  return buildIndex(server) }
      case { "/index.css" -> return webPrims.CSS(io.read("pages/index.css")relativeTo(self)) }
      case { "/images/logo.png" -> return webPrims.Image(io.readRaw("images/logo.png")relativeTo(self)) }
      case { "/favicon.ico" -> return webPrims.Image(io.readRaw("images/logo.png")relativeTo(self)) }
      case { _ -> 
        print("Warning: {brand} cannot process {path}")
        return webPrims.Http("Not found")
      }
  }
}

class PostRequest(data' : String) {
    inherit AbstractRequest
    def brand: String = "Post"
    def data = data'

    method getResponse(server) {
        server.addToDB(data)
        return GetRequest("").buildIndex(server)
    }
}

method BuildRequestFromInput(input: String) {
    var parts := input.split("\n")
    var partsOfItemZero := parts.at(0).split(" ")

    var reqType := partsOfItemZero.at(0)
    var path := partsOfItemZero.at(1)

    var req := match(reqType)
        case { "GET" ->
          print("Building {reqType} request for {path}")
          return GetRequest(path)
        
        } case { "POST" ->
          var contentRowIx := 0
          var contentLengthRow := 0
          var contentLengthSig := ""
          while { contentLengthSig ≠ "Content-Length:" } do {
            if (contentRowIx >= parts.size ) then {
              EnvironmentError.raise("The POST request did not contain a Content-Length header:\n{input}")
            }
            contentLengthRow := parts.at(contentRowIx).split(" ")
            contentLengthSig := contentLengthRow.at(0)
            contentRowIx := contentRowIx + 1
          }

          if (contentLengthSig ≠ "Content-Length:") then {
            EnvironmentError.raise("The POST request does not contain a Content-Length header:\n{input}")
          }

          
          def length = contentLengthRow.at(1).asNumber
          def content = input.substringFrom(input.size - length)
          print("Building {reqType} request of {content}")
          return PostRequest(content)

        } case { _ ->
          ProgrammingError.raise("{reqType} not understood")
    }
}

class serverOnPort(port, db') {
  inherit platform.kernel.Socket

  def db = db'
  setPort(intrinsic.number_G2S(port))

  print("Running server on {port}, using {db}.")
  init

  method respondToRequest(input: String) -> Http {
    def req: AbstractRequest = BuildRequestFromInput(input)
    return req.getResponse(self)
  }

  method waitForRequestLoop {
    def req: String = intrinsic.graceString(listen)
    def res: Http = respondToRequest(req)
    res.write(self)
    close
    waitForRequestLoop
  }

  method writeStringData(data: String) {
    writeString(intrinsic.string_G2S(data))
  }

  method writeImageData(data: String) {
    writeRaw(intrinsic.string_G2S(data))
  }

  method readDatabase {
      def somArr = readDB(intrinsic.string_G2S(db))
      somArr.at(1.somDouble.asInteger).println
      def graceArr = intrinsic.primitiveArray.new(intrinsic.number_S2G(somArr.size))
      var i := 0
      somArr.doForGrace { item ->
        graceArr.at(i)put(intrinsic.string_S2G(item))
        i := i + 1
      }
      return graceArr
  }

  method addToDB(data: String) {
    ProgrammingError.raise("Subclasses of server must implement the #addToDB(_)")
  }

  method writePacketToDB(packet: Packet) {
    def data: String = packet.data
    add(intrinsic.string_G2S(data))toDB(intrinsic.string_G2S(db))
  }

}

class createServerUnsafe(db) {
    inherit serverOnPort(1111, db)  
    
    method convertToPacket(data') -> Packet {
      return object {
        def data = data'
      }
    }

    method addToDB(data: String) {
        def packet = convertToPacket(data)
        writePacketToDB(packet)
    }
}

class createServerSafe(db) {
    inherit serverOnPort(1112, db)  

    method safetyCheck(packet: SecurePacket) -> SecurePacket {}
    
    method convertToPacket(data') -> Packet {
      def packet = object {
        def data = data'
      }

      try {
        safetyCheck(packet)
      } catch { e: TypeError ->
        EnvironmentError.raise("This server will not accept user-supplied strings")
      }
    }

    method addToDB(data: String) {
      try {
        def packet = convertToPacket(data)
        writePacketToDB(packet)
      } catch { e: EnvironmentError ->
        print("Warning: avoided writing user-supplied string to database") 
      }
    }
}

class createServerSanitizing(db) {
    inherit serverOnPort(1113, db)  
    
    method safetyCheck(packet: SecurePacket) -> SecurePacket {}

    method sanitize(data') -> SecurePacket {
      print("Warning: sanitizing user-supplied string")

      def m = "data=attack"
      if (data'.matches(m)) then {
        EnvironmentError.raise("An attack has been attempted, discarding")
      }

      return object { 
        def data = data'
        def safetyBrand = ""
      }
    }
    
    method convertToPacket(data') -> Packet {
      def packet = object {
        def data = data'
      }

      try {
        safetyCheck(packet)
      } catch { e: TypeError ->
        return sanitize(data')
      }

      return object { 
        def data = data'
        def safetyBrand = ""
      }
    }

    method addToDB(data: String) {
      try {
        def packet = convertToPacket(data)
        writePacketToDB(packet)
      } catch { e: EnvironmentError ->
        print("Warning: skipped attack") 
      }
    }
}
