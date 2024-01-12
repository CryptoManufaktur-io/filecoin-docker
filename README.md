# filecoin-docker

docker compose for filecoin node

`./ethd install` can install docker-ce for you

To get started: `cp default.env .env`, adjust `COMPOSE_FILE` and your traefik variables if you use traefik, then `./ethd up`.

Observe logs until the initial snapshot sync is complete and lotus has restarted. Then generate a key: Run `docker ps` and find the name of your container, then run the command to generate the RPC auth token, e.g. `docker exec filecoin-docker-lotus-1 lotus auth create-token --perm read`

Provided you created a key as above, you can then force a filecoin instance to have the same token as an existing one by replacing the contents of `keystore/MF2XI2BNNJ3XILLQOJUXMYLUMU` and `token` with the contents of the existing node, and then
restarting the filecoin service. These files are in the docker volume for filecoin. Make copies first.

To update lotus, run `./ethd update`, followed by `./ethd up`.

`lotus-haproxy.cfg` is a sample haproxy configuration file, and assumes that all filecoin nodes have the same token. `check-fcsync.sh` verifies sync status for haproxy. `haproxy-docker-sample.yml` is an example for a docker-compose file running haproxy, inside a docker swarm mode.

## Pruning

To prune the chain, run `docker exec <lotus-container> lotus chain prune hot-moving`. This requires about 300 GiB free space.

This is filecoin-docker v1.1.1
