import jazzle/net

let listserver = "list.jazzjackrabbit.com"

echo "Super Simple Games in Progress"
echo ""

echo "=== Listserver: " & listserver & " ==="
echo ""

var pings: seq[Future[PingResponse]] = @[]
for server in listserverServers(listserver):
  let p = ping(server.address, server.port)
  pings.add(p)


for p in waitFor pings.all():
  if not p.success:
    continue

  echo p


# ping a server directly
# echo waitFor ping("localhost", Port(10052))
