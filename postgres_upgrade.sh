#!/bin/sh

set -e

# variables from the image
OLDVER="${OLDVER:-}"
NEWVER="${NEWVER:-}"

# make sure old directory exists
if [ ! -d "/data/pg${OLDVER}" ]
then
  echo "ERROR: no directory found for PostgreSQL ${OLDVER}!"
  exit 1
else
  # make sure we find PG_VERSION (lazy way to see if there are postgres files)
  if [ ! -f "/data/pg${OLDVER}/PG_VERSION" ]
  then
    echo "ERROR: PG_VERSION not found for PostgreSQL ${OLDVER}!"
    exit 1
  fi
fi

# make sure new directory exists
if [ ! -d "/data/pg${NEWVER}" ]
then
  echo "ERROR: no directory found for PostgreSQL ${NEWVER}!"
  exit 1
else
  # make sure we do not find PG_VERSION (lazy way to see if there are postgres files)
  if [ -f "/data/pg${NEWVER}/PG_VERSION" ]
  then
    echo "ERROR: PG_VERSION found for PostgreSQL ${NEWVER}! We are expecting the directory to be empty!"
    exit 1
  fi
fi

# Create the necessary user
adduser -D -u $PUID pgupgrade

# Ensure old database is in a clean state
"/usr/libexec/postgresql${OLDVER}/pg_ctl" start -w -D "/data/pg${OLDVER}"
"/usr/libexec/postgresql${OLDVER}/pg_ctl" stop -w -D "/data/pg${OLDVER}"

# set ownership
chown pgupgrade "/data/pg${NEWVER}"

# cd to new directory
cd "/data/pg${NEWVER}"

# init new db
gosu pgupgrade initdb -D "/data/pg${NEWVER}" --locale=en_US.UTF-8 --encoding=UTF8

# run the upgrade
gosu pgupgrade pg_upgrade -b "/usr/libexec/postgresql${OLDVER}/" -B "/usr/libexec/postgresql${NEWVER}/" -d "/data/pg${OLDVER}/" -D "/data/pg${NEWVER}/"
