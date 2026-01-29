# Copyright (c) 2025 Mihai Stancu (https://github.com/curatorium)

# @name namespace:use
# @type function
# @desc Create aliases for functions matching patterns or explicit names.
#
# @usage namespace:use <pattern|name...> [as <ns>]
#
# @arg <pattern|name...> -- Glob pattern (e.g., "some-ns:*") or list of function names
# @arg [as <ns>] -- Optional alias prefix (default: none)
function namespace:use() {
	local ns="";
	(($# >= 2)) && [[ "${*: -2:1}" == "as" ]] && ns="${*: -1}" && set -- "${@:1:$#-2}";

	shopt -s expand_aliases;

	local pattern fn name;
	for pattern in "$@"; do
		# Find all matching functions (convert glob * to regex .*)
		while IFS= read -r fn; do
			# Short name = everything after last :
			name="${fn##*:}";

			# shellcheck disable=SC2139
			alias "$ns$name"="$fn";
		done <<<"$(declare -F | grep -P "^declare -f ${pattern//\*/.*}\$" | sed 's/declare -f //')"
	done
}
