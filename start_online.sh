#!/bin/bash
docker-compose --env-file env.properties rm
docker-compose --env-file env.properties pull
docker-compose --env-file env.properties up
