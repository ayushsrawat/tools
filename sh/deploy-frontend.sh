#!/usr/bin/env bash

set -euo pipefail

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
CYAN=$(tput setaf 39)
RESET=$(tput sgr0)

SERVICE_NAME="sparrow"
BUILD_FILE_BASE_NAME="${SERVICE_NAME}-frontend"
TEMP_DIR="${HOME}/${SERVICE_NAME}-temp-qI-viG-3338"
BUILD_VERSION_DUMPS_DIR="${HOME}/${SERVICE_NAME}/build/frontend"

BUILD_SOURCE_ZIP_FILE="${1:-}"
NGINX_DEST_DIR="${2:-}"

usage () {
  echo "${GREEN}"
  echo -e "Usage: \n ./deploy-frontend [BUILD_SOURCE_ZIP_FILE] [NGINX_DEST_DIR]"
  echo " ./deploy-frontend ~/${BUILD_FILE_BASE_NAME}.zip /var/www/${SERVICE_NAME}/"
  echo "${RESET}"
}

delete_temp_files () {
  if [ -d "${TEMP_DIR}" ]; then
    rm -rf "${TEMP_DIR}"
  fi
}

if [ ! -f "${BUILD_SOURCE_ZIP_FILE}" ]; then
  echo "$RED> Invalid Source : [${BUILD_SOURCE_ZIP_FILE}] Skipping..."
  usage
  exit 1
fi

if [ ! -d "${NGINX_DEST_DIR}" ]; then
  echo "$RED> Invalid Destination : [${NGINX_DEST_DIR}] Skipping..."
  usage
  exit 1
fi

if unzip -l "${BUILD_SOURCE_ZIP_FILE}" &>/dev/null; then
  echo "$GREEN> Validated source build file [${BUILD_SOURCE_ZIP_FILE}] $RESET"
else
  echo "$RED> [${BUILD_SOURCE_ZIP_FILE}] Not a Zip Archive Skipping..."
  usage
  exit 1
fi

delete_temp_files
mkdir -p "${TEMP_DIR}"
unzip "${BUILD_SOURCE_ZIP_FILE}" -d "${TEMP_DIR}"

if [ ! -d "${TEMP_DIR}"/dist ]; then
  echo "$RED> dist/ folder doesn't exist inside source zip file $RESET"
  delete_temp_files
  usage
  exit 1
fi

read -r -p "$CYAN Are you sure you want to delete the existing build at ${NGINX_DEST_DIR}/*? (y/N): " confirm

if [[ "${confirm}" =~ ^[Yy](es)?$ ]]; then
  echo "$CYAN> Deleting existing build from ${NGINX_DEST_DIR}/* $RESET"
  sudo rm -rf "${NGINX_DEST_DIR:?}"/*
else
  echo "$RED> Deployment aborted by user. $RESET"
  delete_temp_files
  exit 1
fi

echo "$CYAN> Copying extracted dist files to ${NGINX_DEST_DIR}"
sudo cp -r "${TEMP_DIR}"/dist/* "${NGINX_DEST_DIR}"

delete_temp_files

mkdir -p "${BUILD_VERSION_DUMPS_DIR}"
TIMESTAMP=$(date +"%Y-%m-%d-%H%M")
mv "${BUILD_SOURCE_ZIP_FILE}" "${BUILD_VERSION_DUMPS_DIR}/${BUILD_FILE_BASE_NAME}-${TIMESTAMP}.zip"

echo "$GREEN> Deployment Successful $RESET"