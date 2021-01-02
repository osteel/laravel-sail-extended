#!/usr/bin/env bash

UNAMEOUT="$(uname -s)"

WHITE='\033[1;37m'
NC='\033[0m'

# Verify operating system is supported...
case "${UNAMEOUT}" in
    Linux*)             MACHINE=linux;;
    Darwin*)            MACHINE=mac;;
    *)                  MACHINE="UNKNOWN"
esac

if [ "$MACHINE" == "UNKNOWN" ]; then
    echo "Unsupported operating system [$(uname -s)]. Laravel Sail supports macOS, Linux, and Windows (WSL2)."
fi

# Define environment variables...
export APP_PORT=${APP_PORT:-80}
export APP_SERVICE=${APP_SERVICE:-"laravel.test"}
export MYSQL_PORT=${MYSQL_PORT:-3306}
export WWWUSER=${WWWUSER:-$UID}
export WWWGROUP=${WWWGROUP:-$(id -g)}

if [ "$MACHINE" == "linux" ]; then
    export SEDCMD="sed -i"
elif [ "$MACHINE" == "mac" ]; then
    export SEDCMD="sed -i .bak"
fi

# Ensure that Docker is running...
if ! docker info > /dev/null 2>&1; then
    echo -e "${WHITE}Docker is not running.${NC}"

    exit 1
fi

# Determine if Sail is currently up...
PSRESULT="$(docker-compose ps -q)"

if docker-compose ps | grep 'Exit' &> /dev/null; then
    docker-compose down > /dev/null 2>&1

    EXEC="no"
elif [ -n "$PSRESULT" ]; then
    EXEC="yes"
else
    EXEC="no"
fi

# Function that outputs Sail is not running...
function sail_is_not_running {
    echo -e "${WHITE}Sail is not running.${NC}"
    echo ""
    echo -e "${WHITE}You may Sail using the following commands:${NC} './sail up' or './sail up -d'"

    exit 1
}

if [ $# -gt 0 ]; then
    # Source the ".env" file so Laravel's environment variables are available...
    if [ -f ./.env ]; then
        source ./.env
    fi

    # Initiate a Mongo shell terminal session within the "mongo" container...
    if [ "$1" == "mongo" ]; then

        if [ "$EXEC" == "yes" ]; then
            docker-compose exec mongo mongo
        else
            sail_is_not_running
        fi

    # Pass unknown commands to the original "sail" script..
    else
        ./vendor/bin/sail "$@"
    fi
fi
