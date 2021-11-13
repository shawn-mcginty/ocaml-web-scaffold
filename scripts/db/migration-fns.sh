function install_migrate() {
	echo "install migration tool if needed..."

	MIGRATION_VER="v4.14.1"
	if [[ $OSTYPE == "darwin" ]]; then
		PLATFORM="darwin"
	else
		PLATFORM="linux"
	fi

	INST_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

	if [[ -n "${IS_DOCKER_COMPOSE}" ]]; then
		echo "script running in dc, force re-install migrate tool"
		rm -f $INST_SCRIPTS_DIR/migrate

		echo "and install curl"
		apt-get update && apt-get install -y curl
	fi

	if [[ -f "$INST_SCRIPTS_DIR/migrate" ]]; then
		echo "migration tool already exists."
	else
		OG_DIR="$(pwd)"
		cd $INST_SCRIPTS_DIR
		curl -L https://github.com/golang-migrate/migrate/releases/download/$MIGRATION_VER/migrate.$PLATFORM-amd64.tar.gz | tar xvz
		mv migrate.$PLATFORM-amd64 migrate
		chmod +x migrate
		cd $OG_DIR
	fi
}

function migrate_up() {
	if [[ -n "${DB_HOST}" ]]; then
		DB_HOST="${DB_HOST}"
	else
		DB_HOST="localhost"
	fi

	if [[ -n "${DB_PORT}" ]]; then
		DB_PORT="${DB_PORT}"
	else
		DB_PORT="5432"
	fi

	if [[ -n "${DB_USER}" ]]; then
		DB_USER="${DB_USER}"
	else
		DB_USER="scaffold"
	fi

	if [[ -n "${DB_PASSWORD}" ]]; then
		DB_PW="${DB_PASSWORD}"
	else
		DB_PW="scaffold1"
	fi

	UP_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
	echo "$UP_SCRIPTS_DIR/migrate -source=\"file://$UP_SCRIPTS_DIR/migrations\" -database=\"postgres://${DB_USER}:${DB_PW}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=disable\" -verbose up"

	$UP_SCRIPTS_DIR/migrate -source="file://$UP_SCRIPTS_DIR/migrations" -database="postgres://${DB_USER}:${DB_PW}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=disable" -verbose up
}

function migrate_down() {
	DOWN_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
	$DOWN_SCRIPTS_DIR/migrate -source="file://$DOWN_SCRIPTS_DIR/migrations" -database="postgres://werkt:werkt1@localhost/werkt_dev?sslmode=disable" -verbose down
}

function migrate_drop() {
	DROP_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
	$DROP_SCRIPTS_DIR/migrate -source="file://$DROP_SCRIPTS_DIR/migrations" -database="postgres://werkt:werkt1@localhost/werkt_dev?sslmode=disable" -verbose drop -f
}