#!/usr/bin/env bash

# shellcheck disable=SC2154,SC2086
chik ${chik_args} start ${service}

trap "echo Shutting down ...; chik stop all -d; exit 0" SIGINT SIGTERM

# shellcheck disable=SC2154
if [[ ${log_to_file} == 'true' ]]; then
  # Ensures the log file actually exists, so we can tail successfully
  touch "$CHIK_ROOT/log/debug.log"
  tail -F "$CHIK_ROOT/log/debug.log" &
fi

tail -F /dev/null
