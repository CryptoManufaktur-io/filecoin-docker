# filecoin-docker

docker-compose for filecoin node

To get started: `cp default.env .env`, adjust `COMPOSE_FILE` and your traefik variables if you use traefik, then `docker-compose up -d`.

Generating key: Run `docker ps` and find the name of your container, then run the command to generate the RPC auth token, e.g. `docker exec filecoin-docker_lotus_1 lotus auth create-token --perm read` 
