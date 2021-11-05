#!/bin/sh
MIN_PEERS=50
STATUS=$(curl -s -m2 -N -X POST -H "Content-Type: application/json" -H "Authorization: Bearer YOURTOKEN" --data '{ "jsonrpc": "2.0", "method": "Filecoin.NodeStatus", "params": [true], "id": 1 }' "https://${HAPROXY_SERVER_NAME}/rpc/v0")
echo "${STATUS}" | grep -q "result"
if [ $? -ne 0 ]; then
  return 1
fi
BEHIND=$(echo "${STATUS}" | jq .result.SyncStatus.Behind)
PEERS=$(echo "${STATUS}" | jq .result.PeerStatus.PeersToPublishBlocks)
if [ "${BEHIND}" -eq 0 -a "${PEERS}" -ge "$MIN_PEERS" ]; then
  return 0
else
  return 1
fi

