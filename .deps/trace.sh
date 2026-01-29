# Copyright (c) 2025 Mihai Stancu (https://github.com/curatorium)

# @name trace:stop
# @type function
#
# @desc Enable code path tracing for current files (skips files fron .deps/).
# @desc Prints "file:00 function -- command"
function trace:app() {
  set -T;
  trap 'echo "${BASH_SOURCE[0]}:$LINENO ${FUNCNAME[0]:-main} -- $BASH_COMMAND" | sed "/.deps/d" 1>&2' DEBUG;
}

# @name trace:stop
# @type function
#
# @desc Enable code path tracing for all files (including files from .deps/).
# @desc Prints "file:00 function -- command"
function trace:all() {
  set -T;
  trap 'echo "${BASH_SOURCE[0]}:$LINENO ${FUNCNAME[0]:-main} -- $BASH_COMMAND" 1>&2' DEBUG;
}

# @name trace:stop
# @type function
#
# @desc Disable code path tracing.
function trace:stop() {
  trap - DEBUG;
  set +T;
}
