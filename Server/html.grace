class Html(data': String) {
  def data = data'

  method contentType {
    return "Content-Type: text/html\n"
  }

  method write(server) {
    Http("{contentType}\n{data}").write(server)
  }
}

