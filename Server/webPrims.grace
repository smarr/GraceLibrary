class Http(data': String) {
  def data = data'

  method set200 {
    "HTTP/1.0 200 OK\n"
  }

  method stringify  -> String {
    return "{set200}{data}"
  }

  method asHttpString -> String {
    return stringify
  }

  method asString {
    "Http[[{stringify}]]"
  }

  method write(server) {
      server.writeStringData(asHttpString)
  }
}

class Html(data': String) {
  def data = data'

  method contentType {
    return "Content-Type: text/html\n"
  }

  method stringify -> String {
    return "{contentType}\n{data}"
  }

  method asHttpString -> String {
    return Http(stringify).asHttpString
  }

  method asString {
    "Html[[{stringify}]]"
  }

  method write(server) {
      server.writeStringData(asHttpString)
  }
}

class CSS(data': String) {
  def data = data'

  method contentType {
    return "Content-Type: text/css\n"
  }

  method stringify -> String {
    return "{contentType}\n{data}"
  }

  method asHttpString -> String {
    return Http(stringify).asHttpString
  }

  method asString {
    "CSS[[{stringify}]]"
  }

  method write(server) {
      server.writeStringData(asHttpString)
  }
}


class Image(data': String) {

  def data = data'

  method contentType {
    return "Content-Type: image/png\n"
  }

  method stringify -> String {
    return "{contentType}\n{data}"
  }

  method asString {
    "Image[[{stringify}]]"
  }

  method write(server) {
    Http("").write(server)
    server.writeStringData("{contentType}\n") 
    server.writeImageData(data) 
  }
}
