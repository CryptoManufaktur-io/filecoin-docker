#!/bin/bash
set -x
if [ ! -f /home/filecoin/.lotus/setupdone ]; then
  lotus daemon --import-snapshot https://snapshots.mainnet.filops.net/minimal/latest.zst --halt-after-import
  export P2P_ANNOUNCE_IP=$(wget -qO- ifconfig.me/ip)
  # dasel v2 syntax
  dasel put -t string -v "/ip4/0.0.0.0/tcp/1234/http" -f /home/filecoin/.lotus/config.toml API.ListenAddress
  dasel put -t string -v "30s" -f /home/filecoin/.lotus/config.toml API.Timeout
  dasel put -t string -v "/ip4/0.0.0.0/tcp/6665" -f /home/filecoin/.lotus/config.toml Libp2p.ListenAddresses.[]
  dasel put -t string -v "/ip4/$P2P_ANNOUNCE_IP/tcp/6665" -f /home/filecoin/.lotus/config.toml Libp2p.AnnounceAddresses.[]
  dasel put -t bool -v true -f /home/filecoin/.lotus/config.toml Chainstore.EnableSplitstore
  dasel put -t string -v "discard" -f /home/filecoin/.lotus/config.toml Chainstore.Splitstore.ColdStoreType
  touch /home/filecoin/.lotus/setupdone
fi
export P2P_ANNOUNCE_IP=$(wget -qO- ifconfig.me/ip)
dasel put -t string -v "/ip4/$P2P_ANNOUNCE_IP/tcp/6665" -f /home/filecoin/.lotus/config.toml Libp2p.AnnounceAddresses.[0]
exec lotus daemon
