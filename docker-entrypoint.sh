#!/bin/bash
set -x
if [ ! -f /home/filecoin/.lotus/setupdone ]; then
  lotus daemon --import-snapshot https://fil-chain-snapshots-fallback.s3.amazonaws.com/mainnet/minimal_finality_stateroots_latest.car --halt-after-import
  export P2P_ANNOUNCE_IP=$(wget -qO- ifconfig.me/ip)
  dasel put string -f /home/filecoin/.lotus/config.toml API.ListenAddress "/ip4/0.0.0.0/tcp/1234/http"
  dasel put string -f /home/filecoin/.lotus/config.toml API.Timeout "30s"
  dasel put string -f /home/filecoin/.lotus/config.toml Libp2p.ListenAddresses.[0] "/ip4/0.0.0.0/tcp/6665"
  dasel put string -f /home/filecoin/.lotus/config.toml Libp2p.AnnounceAddresses.[0] "/ip4/$P2P_ANNOUNCE_IP/tcp/6665"
  dasel put bool -f /home/filecoin/.lotus/config.toml Chainstore.EnableSplitstore true
  dasel put string -f /home/filecoin/.lotus/config.toml Chainstore.Splitstore.ColdStoreType "discard"
  touch /home/filecoin/.lotus/setupdone
fi
export P2P_ANNOUNCE_IP=$(wget -qO- ifconfig.me/ip)
dasel put string -f /home/filecoin/.lotus/config.toml Libp2p.AnnounceAddresses.[0] "/ip4/$P2P_ANNOUNCE_IP/tcp/6665"
exec lotus daemon
