# filecoin-docker

docker-compose for filecoin node

To get started: `cp default.env .env`, adjust `COMPOSE_FILE` and your traefik variables if you use traefik, then `docker-compose up -d`.

Generating key: Run `docker ps` and find the name of your container, then run the command to generate the RPC auth token, e.g. `docker exec filecoin-docker_lotus_1 lotus auth create-token --perm read` 

You can force a filecoin instance to have the same token as an existing one by replacing the contents of `keystore/MF2XI2BNNJ3XILLQOJUXMYLUMU` and `token` with the contents of the existing node, and then
restarting the filecoin service. These files are in the docker volume for filecoin. Make copies first.

`lotus-haproxy.cfg` is a sample haproxy configuration file, and assumes that all filecoin nodes have the same token. `check-fcsync.sh` verifies sync status for haproxy. `haproxy-docker-sample.yml` is an example for a docker-compose file running haproxy, inside a docker swarm mode.
