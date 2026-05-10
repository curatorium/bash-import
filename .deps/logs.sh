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
# @desc Two writes (syslog + stderr) instead of `logger -s` to avoid the
# @desc RFC-syslog prefix `<11>Mon DD HH:MM:SS` that `logger -s` prepends to
# @desc stderr output. Daemons whose stderr is /dev/null or systemd-journal are
# @desc unaffected (stderr write is silent / re-captured); CLIs see clean
# @desc `<tag>: <message>` lines for the user.
# @usage logs:err <message...>
# @arg <message...> -- Message to log
function logs:err() {
	logger -t "${LOGS_TAG:-${0##*/}}" -p user.err "$@";
	printf '%s: %s\n' "${LOGS_TAG:-${0##*/}}" "$*" >&2;
}

# @name logs:die
# @type function
# @desc Log at err level (syslog + stderr) then return 1.
# @desc Replaces `|| { logs:err "msg"; return 1; }`. Inherits stderr-tee from logs:err.
# @usage some-command || logs:die <message...>
# @arg <message...> -- Message to log before returning
function logs:die() { logs:err "$@"; return 1; }
