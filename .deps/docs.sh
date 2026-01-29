# Copyright (c) 2025 Mihai Stancu (https://github.com/curatorium)

# @name docs:list
# @type function
#
# @desc List all @name values from entries where @type=<type>
# @arg <type> -- The @type to filter by (command, keyword, function)
function docs:list() {
	local type="${1?usage: docs:list <type>}"
	grep -B1 "^# @type $type" "$DOCFILE" | grep -oP '(?<=^# @name ).+'
}

# @name docs:tag
# @type function
#
# @desc Get all values of @<tag> from entry with @name=<name>
# @opt [-i|--indent <n>] -- Indent output by <n> tabs
# @opt [-f|--format <fmt>] -- Output format: txt (default) or md (markdown table rows)
# @arg <name> -- The @name of the documented item
# @arg <tag> -- The tag to extract (desc, usage, arg, flag, etc.)
function docs:tag() {
	local indent=0 format="txt"
	[[ "$1" == "-i" || "$1" == "--indent" ]] && shift && indent="$1" && shift;
	[[ "$1" == "-f" || "$1" == "--format" ]] && shift && format="$1" && shift;
	# shellcheck disable=SC2031
	local entry="${1?usage: docs:tag [-i <n>] [-f txt|md] <name> <tag[,tag...]>}"
	# shellcheck disable=SC2031
	local tag="${2?usage: docs:tag [-i <n>] [-f txt|md] <name> <tag[,tag...]>}"

	local tag_pat="(${tag//,/|})"
	local result
	result="$(sed -n "/^# @name $entry\$/,/^# @name /p" "$DOCFILE" | grep -E "^# @$tag_pat " | sed -E "s/^# @$tag_pat  *//")"

	# Auto-align name/desc columns in txt mode
	if [[ "$format" == "txt" && -n "$result" ]]; then
		local max_w=0 col_name
		while IFS= read -r line; do
			col_name="${line%% -- *}"
			(( ${#col_name} > max_w )) && max_w=${#col_name}
		done <<< "$result"

		result="$(while IFS= read -r line; do
			col_name="${line%% -- *}"; col_desc=""
			[[ "$line" == *" -- "* ]] && col_desc="${line#* -- }"
			printf "%-${max_w}s\t%s\n" "$col_name" "$col_desc"
		done <<< "$result")"
	fi

	if [[ "$format" == "md" && -n "$result" ]]; then
		local -a md_names=() md_descs=()
		local md_nw=9 md_dw=11 fn fd

		while IFS= read -r line; do
			col_name="${line%% -- *}"; col_desc=""
			[[ "$line" == *" -- "* ]] && col_desc="${line#* -- }"
			col_name="${col_name%"${col_name##*[![:space:]]}"}"
			col_desc="${col_desc%"${col_desc##*[![:space:]]}"}"
			fn="\`${col_name//|/\\|}\`"
			fd="${col_desc//|/\\|}"
			md_names+=("$fn"); md_descs+=("$fd")
			(( ${#fn} > md_nw )) && md_nw=${#fn}
			(( ${#fd} > md_dw )) && md_dw=${#fd}
		done <<< "$result"

		local md_sep_n md_sep_d
		printf -v md_sep_n '%*s' "$((md_nw + 2))" ''; md_sep_n="${md_sep_n// /-}"
		printf -v md_sep_d '%*s' "$((md_dw + 2))" ''; md_sep_d="${md_sep_d// /-}"

		printf -v result "| %-${md_nw}s | %-${md_dw}s |" "Parameter" "Description"
		result+=$'\n'"$(printf "|%s|%s|" "$md_sep_n" "$md_sep_d")"
		local i
		for i in "${!md_names[@]}"; do
			result+=$'\n'"$(printf "| %-${md_nw}s | %-${md_dw}s |" "${md_names[$i]}" "${md_descs[$i]}")"
		done
	fi

	if [[ "$indent" -gt 0 ]]; then
		local tabs; tabs="$(printf '\t%.0s' $(seq 1 "$indent"))"
		result="${result//$'\n'/$'\n'"$tabs"}"
		result="${tabs}${result}"
	fi

	echo "$result"
}
