import "server" as server
import "io" as io

def db = io.pathOfModule(self) ++ "data/db.json"
var aServer := server.createServerSanitizing(db)
aServer.waitForRequestLoop
