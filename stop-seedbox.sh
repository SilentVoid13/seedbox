#!/usr/bin/env bash

echo-debug() {
  if [[ ${DEBUG} == "1" ]]; then echo "$@"; fi
}

[[ -z $DOCKER_COMPOSE_BINARY ]] && export DOCKER_COMPOSE_BINARY="docker-compose"
ALL_SERVICES="-f docker-compose.yaml"

for json in $(yq eval -o json config.yaml | jq -c ".services[]"); do
  name=$(echo $json | jq -r .name)
  enabled=$(echo $json | jq -r .enabled)
  vpn=$(echo $json | jq -r .vpn)

  # Skip disabled services
  if [[ ${enabled} == "false" ]]; then
    echo-debug "[$0] Service $name is disabled. Skipping it."
    continue
  fi

  echo-debug "[$0] ➡️  Parsing service: \"$name\"..."

  # Default docker-compose filename is the service name + .yaml.
  # Take into account explicit filename if specified in config
  customFile=$(echo $json | jq -r .customFile)
  file="$name.yaml"
  if [[ ${customFile} != "null" ]]; then 
    file=${customFile}
  fi
  echo-debug "[$0]    File: \"$file\"..."

  # Append $file to global list of files which will be passed to docker commands
  ALL_SERVICES="${ALL_SERVICES} -f services/${file}"
done

${DOCKER_COMPOSE_BINARY} ${ALL_SERVICES} down
