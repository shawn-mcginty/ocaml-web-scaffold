#!/bin/bash
set -e
SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
echo $SCRIPTS_DIR
if [[ -z "${IS_DOCKER_COMPOSE}" ]]; then
	echo "loading .env file"
	source $SCRIPTS_DIR/../../.env
fi

source $SCRIPTS_DIR/migration-fns.sh

if [[ -n "${IS_DOCKER_COMPOSE}" ]]; then
	install_migrate
fi

migrate_up