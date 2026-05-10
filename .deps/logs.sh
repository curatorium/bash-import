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
# @desc Log at err level via syslog AND echo to stderr.
# @desc Tag defaults to the script's namespace. The `-s` flag tees the message to
# @desc stderr so CLIs surface errors to the user (and parent processes that
# @desc capture stderr) without adding a separate code path. Daemons whose stderr
# @desc goes to /dev/null or the systemd journal are unaffected.
# @usage logs:err <message...>
# @arg <message...> -- Message to log
function logs:err() { logger -s -t "${LOGS_TAG:-${0##*/}}" -p user.err "$@"; }

# @name logs:die
# @type function
# @desc Log at err level (syslog + stderr) then return 1.
# @desc Replaces `|| { logs:err "msg"; return 1; }`. Inherits stderr-tee from logs:err.
# @usage some-command || logs:die <message...>
# @arg <message...> -- Message to log before returning
function logs:die() { logs:err "$@"; return 1; }
