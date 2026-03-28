# Copyright (c) 2025 Mihai Stancu (https://github.com/curatorium)

# @name logs:info
# @type function
# @desc Log at info level via syslog. Tag defaults to the script's namespace.
# @usage logs:info <message...>
# @arg <message...> -- Message to log
function logs:info() { logger -t "${LOGS_TAG:-${0##*/}}" -p user.info "$@"; }

# @name logs:warn
# @type function
# @desc Log at warn level via syslog. Tag defaults to the script's namespace.
# @usage logs:warn <message...>
# @arg <message...> -- Message to log
function logs:warn() { logger -t "${LOGS_TAG:-${0##*/}}" -p user.warn "$@"; }

# @name logs:err
# @type function
# @desc Log at err level via syslog. Tag defaults to the script's namespace.
# @usage logs:err <message...>
# @arg <message...> -- Message to log
function logs:err() { logger -t "${LOGS_TAG:-${0##*/}}" -p user.err "$@"; }
