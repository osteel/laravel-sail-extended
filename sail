#!/usr/bin/env bash

if ! [ -x "$(command -v docker-compose)" ]; then
    shopt -s expand_aliases
    alias docker-compose='docker compose'
fi

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
    echo "Unsupported operating system [$(uname -s)]. Laravel Sail supports macOS, Linux, and Windows (WSL2)." >&2

    exit 1
fi

# Source the ".env" file so Laravel's environment variables are available...
if [ -f ./.env ]; then
    source ./.env
fi

# Define environment variables...
export APP_PORT=${APP_PORT:-80}
export APP_SERVICE=${APP_SERVICE:-"laravel.test"}
export DB_PORT=${DB_PORT:-3306}
export WWWUSER=${WWWUSER:-$UID}
export WWWGROUP=${WWWGROUP:-$(id -g)}

export SAIL_SHARE_DASHBOARD=${SAIL_SHARE_DASHBOARD:-4040}
export SAIL_SHARE_SERVER_HOST=${SAIL_SHARE_SERVER_HOST:-"laravel-sail.site"}
export SAIL_SHARE_SERVER_PORT=${SAIL_SHARE_SERVER_PORT:-8080}
export SAIL_SHARE_SUBDOMAIN=${SAIL_SHARE_SUBDOMAIN:-""}

# Function that outputs Sail is not running...
function sail_is_not_running {
    echo -e "${WHITE}Sail is not running.${NC}" >&2
    echo "" >&2
    echo -e "${WHITE}You may Sail using the following commands:${NC} './vendor/bin/sail up' or './vendor/bin/sail up -d'" >&2

    exit 1
}

if [ -z "$SAIL_SKIP_CHECKS" ]; then
    # Ensure that Docker is running...
    if ! docker info > /dev/null 2>&1; then
        echo -e "${WHITE}Docker is not running.${NC}" >&2

        exit 1
    fi

    # Determine if Sail is currently up...
    PSRESULT="$(docker-compose ps -q)"
    if docker-compose ps | grep $APP_SERVICE | grep 'Exit'; then
        echo -e "${WHITE}Shutting down old Sail processes...${NC}" >&2

        docker-compose down > /dev/null 2>&1

        EXEC="no"
    elif [ -n "$PSRESULT" ]; then
        EXEC="yes"
    else
        EXEC="no"
    fi
else
    EXEC="yes"
fi

if [ $# -gt 0 ]; then
    # Initiate a Mongo shell terminal session within the "mongo" container...
    if [ "$1" == "mongo" ]; then

        if [ "$EXEC" == "yes" ]; then
            docker-compose exec mongo mongo
        else
            sail_is_not_running
        fi

    # Pass unknown commands to the original "sail" script...
    else
        ./vendor/bin/sail "$@"
    fi
else
    docker-compose ps
fi
