# Copyright (c) 2025 Mihai Stancu (https://github.com/curatorium)

# @name assert
# @type function
# @desc Assert equality between two values.
#
# @usage assert "$actual" "expected" ["message"]
#
# @arg <actual> -- The actual value to test.
# @arg <expected> -- The expected value.
# @arg [message] -- Optional message prefix on failure.
#
# @return 0 when values are equal
# @return 1 when values differ
function assert() {
	local actual="$1" expected="$2" msg="${3:-}";
	if [[ "$actual" != "$expected" ]]; then
		echo "${msg:+$msg: }expected '$expected', got '$actual'";
		return 1;
	fi
}

# @name assert:array-eq
# @type function
# @desc Assert array equality (compares stringified arrays).
#
# @usage assert:array-eq arrayname "expected elements" ["message"]
#
# @arg <arrayname> -- Name of array variable (not $array).
# @arg <expected> -- Space-separated expected elements.
# @arg [message] -- Optional message prefix on failure.
#
# @return 0 when arrays match
# @return 1 when arrays differ
function assert:array-eq() {
	local -n arr="$1";
	local expected="$2" msg="${3:-}";
	local actual="${arr[*]}";
	if [[ "$actual" != "$expected" ]]; then
		echo "${msg:+$msg: }expected '($expected)', got '(${actual})'";
		return 1;
	fi
}

# @name assert:status
# @type function
# @desc Assert return code matches expected value.
#
# @usage assert:status $? 0 ["message"]
#
# @arg <actual> -- The actual return code.
# @arg <expected> -- The expected return code.
# @arg [message] -- Optional message prefix on failure. Default: "return code".
#
# @return 0 when codes match
# @return 1 when codes differ
function assert:status() {
	local actual="$1" expected="$2" msg="${3:-return code}";
	if [[ "$actual" -ne "$expected" ]]; then
		echo "${msg}: expected $expected, got $actual";
		return 1;
	fi
}

# @name assert:contains
# @type function
# @desc Assert string contains substring.
#
# @usage assert:contains "$haystack" "needle" ["message"]
#
# @arg <haystack> -- The string to search in.
# @arg <needle> -- The substring to find.
# @arg [message] -- Optional message prefix on failure.
#
# @return 0 when substring is found
# @return 1 when substring is not found
function assert:contains() {
	local haystack="$1" needle="$2" msg="${3:-}";
	if [[ "$haystack" != *"$needle"* ]]; then
		echo "${msg:+$msg: }'$haystack' does not contain '$needle'";
		return 1;
	fi
}

# @name assert:match
# @type function
# @desc Assert string matches regex pattern.
#
# @usage assert:match "$string" "^pattern$" ["message"]
#
# @arg <string> -- The string to test.
# @arg <pattern> -- The regex pattern to match.
# @arg [message] -- Optional message prefix on failure.
#
# @return 0 when pattern matches
# @return 1 when pattern does not match
function assert:match() {
	local string="$1" pattern="$2" msg="${3:-}";
	if [[ ! "$string" =~ $pattern ]]; then
		echo "${msg:+$msg: }'$string' does not match '$pattern'";
		return 1;
	fi
}
