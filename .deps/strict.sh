# Copyright (c) 2025 Mihai Stancu (https://github.com/curatorium)

# @name strict:on
# @type function
#
# @desc Enables strict error handling
# @desc set -E: -- ERR traps propagate into functions/subshells
# @desc set -e: -- exit on error
# @desc set -u: -- error on undefined variables
# @desc set -o pipefail -- pipe returns the rightmost non-zero exit code instead of only the last command's
# @desc shopt -s inherit_errexit -- enforces set -e on command substitutions like $(failing_cmd) (which would otherwise silently succeed)
function strict:on() {
	set -Eeuo pipefail;
	shopt -s inherit_errexit;
	shopt -s nullglob;
}

# @name strict:on
# @type function
#
# @desc Disables strict error handling
function strict:off() {
	set +Eeuo pipefail;
	shopt -u inherit_errexit;
	shopt -u nullglob;
}
