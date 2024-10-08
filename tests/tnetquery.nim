import jazzle/net

let listserver = "list.jazzjackrabbit.com"

echo "Super Simple Games in Progress"
echo ""

echo "=== Listserver: " & listserver & " ==="
echo ""

var queries: seq[Future[QueryResponse]] = @[]
for server in listserverServers(listserver):
  let q = query(server.address, server.port)
  queries.add(q)


for q in waitFor queries.all():
  if not q.success:
    continue

  q.prettyPrint()

echo "=== Servers on Local Area Network ==="
echo ""

# query servers on LAN
let servers = broadcastQuery()
for q in servers:
  if not q.success:
    continue

  q.prettyPrint()


# query a server directly
# (waitFor query("localhost", Port(10052))).prettyPrint()
