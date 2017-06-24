#!/usr/bin/env bash

set -x
cd "${APP_HOME}" || exit 1

mix deps.get

mix run --no-halt
