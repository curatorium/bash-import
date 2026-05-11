# Copyright (c) 2026 Mihai Stancu (https://github.com/curatorium)

# Tunables: env override the size caps without editing the lib.
: "${FETCH_MAX_DOWNLOAD_BYTES:=$((50 * 1024 * 1024))}";
: "${FETCH_MAX_EXTRACTED_BYTES:=$((200 * 1024 * 1024))}";

# Lookup table for github URL shapes. Keyed by `<mode>/<source>`.
# `archive/release` is intentionally absent -- it normalizes to `archive/tag`
# inside fetch::gh-to-url ("specific case is the generic case").
# `file/release-latest` is a synthetic key for the latest-release URL switch.
declare -gA FETCH_GH_URL_TEMPLATES=(
	[archive/tag]="https://github.com/%s/%s/archive/refs/tags/%s.tar.gz"
	[archive/branch]="https://github.com/%s/%s/archive/refs/heads/%s.tar.gz"
	[file/tag]="https://github.com/%s/%s/raw/%s/%s"
	[file/branch]="https://github.com/%s/%s/raw/%s/%s"
	[file/release]="https://github.com/%s/%s/releases/download/%s/%s"
	[file/release-latest]="https://github.com/%s/%s/releases/latest/download/%s"
);

# @name fetch:url
# @type function
# @desc Fetch a https URL or GitHub short-ref into <dest>.
# @desc Accepted ref forms:
# @desc   - https://...                            (used as-is, --gh-source ignored)
# @desc   - vendor/pkg@ver[/sub]                   (canonical github short-ref)
# @desc   - gh:vendor/pkg@ver[/sub]                (gh: scheme prefix)
# @desc   - github:vendor/pkg@ver[/sub]            (github: scheme prefix)
# @desc   - @github/vendor/pkg@ver[/sub]           (bash-import convention)
# @desc With -u|--unpack: treat the download as a tarball and extract it. For
# @desc github-archive URLs the optional `#/<sub>` fragment selects a subtree.
# @desc Security guards: https-only, SSRF (private IPs blocked), download cap
# @desc (FETCH_MAX_DOWNLOAD_BYTES, default 50 MiB), extracted cap
# @desc (FETCH_MAX_EXTRACTED_BYTES, default 200 MiB), tar safety (no absolute
# @desc paths, no `..` traversal).
# @usage fetch:url <ref-or-url> -o <dest> [-u|--unpack] [--gh-source tag|branch|release]
# @arg <ref-or-url> -- https:// URL or github short-ref
# @opt -o|--output <dest> -- Destination path (file when no --unpack, directory when --unpack)
# @flag -u|--unpack -- Extract the download as a tarball into <dest>
# @opt --gh-source <tag|branch|release> -- For github short-refs only; default: tag
# @return 0 ok | 2 bad input/ref | 3 network or extract failure | 4 security guard
function fetch:url() {
	# shellcheck disable=SC2034 # used by args:* via dynamic-scoped ARGS
	local ARGS=("$@");

	local ref="";
	args:arg ref \
		|| { logs:err "fetch:url: <ref-or-url> required"; return 2; };

	local output="";
	args:opt -r output o \
		|| { logs:err "fetch:url: -o|--output required"; return 2; };

	local unpack="";
	args:flag unpack u;

	local gh_source="tag";
	args:opt gh-source "" "^(tag|branch|release)$" \
		|| { logs:err "fetch:url: --gh-source must be tag|branch|release"; return 2; };

	# Resolve ref → URL. Order: reject non-https schemes, pass-through https,
	# else translate github short-ref.
	local url="";
	[[ "$ref" =~ ^[a-z]+:// && ! "$ref" =~ ^https:// ]] \
		&& { logs:err "fetch:url: only https:// allowed (got: $ref)"; return 4; };
	[[ "$ref" =~ ^https:// ]] && url="$ref";
	[[ -z "$url" ]] && { fetch::gh-to-url url "$ref" "$gh_source" "$unpack" || return $?; };

	fetch::https "$url" "$output" "$unpack";
}

# @name fetch::gh-to-url
# @type internal
# @desc Convert a github short-ref (vendor/pkg@ver[/sub], optional gh:/github:/@github/
# @desc prefix) to a GitHub URL. Writes result to caller's nameref variable.
# @desc Normalizes archive+release to archive+tag (release source ≡ tag source).
# @desc Rejects archive+@latest (no stable archive URL for latest).
# @desc For file fetches, the subpath portion is required (it IS the filename).
# @usage fetch::gh-to-url <out-var> <ref> <source> <unpack>
# @arg <out-var> -- name of caller-declared variable to receive the URL
# @arg <ref> -- github short-ref, with optional scheme prefix
# @arg <source> -- tag | branch | release
# @arg <unpack> -- "true" to build an archive URL; anything else for a file URL
# @return 0 url assigned | 2 ref unparseable / invalid combination
function fetch::gh-to-url() {
	local -n __url_="${1?ERROR: fetch::gh-to-url: missing <out-var>}";
	local ref="${2?ERROR: fetch::gh-to-url: missing <ref>}";
	local source="${3:-tag}";
	local unpack="${4:-}";

	# Strip optional scheme prefixes; all three normalize to canonical form.
	ref="${ref#gh:}";
	ref="${ref#github:}";
	ref="${ref#@github/}";

	# Parse: vendor/package@version[/everything-else]
	[[ "$ref" =~ ^([^/]+)/([^/@]+)@([^/]+)(/(.*))?$ ]] \
		|| { logs:err "fetch::gh-to-url: cannot parse ref: $ref"; return 2; };
	local vendor="${BASH_REMATCH[1]}";
	local pkg="${BASH_REMATCH[2]}";
	local ver="${BASH_REMATCH[3]}";
	local sub="${BASH_REMATCH[5]:-}"; sub="${sub%/}";

	local mode="file";
	[[ "$unpack" == "true" ]] && mode="archive";

	# Normalize: release-archive URL = tag-archive URL.
	[[ "$mode/$source" == "archive/release" ]] && source="tag";

	# Reject: archive + @latest -- no stable URL exists for the latest tag's archive.
	[[ "$mode" == "archive" && "$ver" == "latest" ]] \
		&& { logs:err "fetch::gh-to-url: no stable archive URL for @latest; pin a tag or branch"; return 2; };

	# File mode requires a subpath (the file's path inside repo or release).
	[[ "$mode" == "file" && -z "$sub" ]] \
		&& { logs:err "fetch::gh-to-url: file mode (no --unpack) requires a subpath: ${ref}/<path>"; return 2; };

	# Pick template; latest+file+release uses a different URL shape (no ver slot).
	local key="$mode/$source";
	[[ "$key" == "file/release" && "$ver" == "latest" ]] && key="file/release-latest";

	local template="${FETCH_GH_URL_TEMPLATES[$key]:-}";
	[[ -n "$template" ]] \
		|| { logs:err "fetch::gh-to-url: invalid combination: --unpack=${unpack:-false} --gh-source=$source"; return 2; };

	# Write directly to the nameref. Avoiding an intermediate `local url=""`
	# is deliberate: if the caller's variable is also named `url`, a local of
	# the same name would shadow it (bash resolves namerefs at access time,
	# so a fresh local would catch the writes instead of the caller's slot).
	# Each template arity differs -- archive templates have 3 %s, file/release-latest
	# has 3 %s (no version), other file templates have 4 %s.
	# shellcheck disable=SC2059 # $template is a controlled lookup value, not user input
	case "$key" in
		archive/*)           printf -v __url_ "$template" "$vendor" "$pkg" "$ver" ;;
		file/release-latest) printf -v __url_ "$template" "$vendor" "$pkg" "$sub" ;;
		file/*)              printf -v __url_ "$template" "$vendor" "$pkg" "$ver" "$sub" ;;
	esac

	# Archive URLs carry the subpath as a `#/<sub>` fragment so fetch::https
	# can selectively extract after download.
	[[ "$mode" == "archive" && -n "$sub" ]] && __url_="${__url_}#/$sub";

	# Last conditional may evaluate to false (file mode, or no subpath). Under
	# `set -e` the function would inherit that non-zero exit -- force success.
	return 0;
}

# @name fetch::https
# @type internal
# @desc Fetch an https URL into <dest>, optionally extracting it as a tarball.
# @desc Enforces: https-only, SSRF (block private IPs), compressed size cap,
# @desc tar safety (no absolute / .. entries), decompressed size cap.
# @desc For unpack mode, an optional `#/<sub>` fragment in the URL selects a
# @desc subtree to extract; without a fragment the full archive is extracted
# @desc with the top-level wrapper dir stripped (the GitHub convention).
# @usage fetch::https <url> <dest> [<unpack>]
# @arg <url> -- https URL, optionally with `#/<sub>` fragment
# @arg <dest> -- destination file (no unpack) or directory (unpack)
# @arg [unpack] -- "true" to treat as tarball and extract
# @return 0 ok | 3 download / extract failure | 4 security guard
function fetch::https() {
	local url="${1?ERROR: fetch::https: missing <url>}";
	local dest="${2?ERROR: fetch::https: missing <dest>}";
	local unpack="${3:-}";

	# Split URL ↔ fragment.
	local url_clean="${url%%#*}";
	local fragment="";
	[[ "$url" == *#* ]] && fragment="${url#*#}";
	fragment="${fragment#/}"; fragment="${fragment%/}";

	[[ "$url_clean" =~ ^https:// ]] \
		|| { logs:err "fetch::https: only https:// allowed (got: $url_clean)"; return 4; };

	# SSRF guard: resolve host, refuse private/loopback/link-local IPs.
	local host;
	host=$(awk -F/ '{print $3}' <<< "$url_clean" | awk -F: '{print $1}' | tr -d '[]');
	[[ -n "$host" ]] || { logs:err "fetch::https: cannot parse host: $url_clean"; return 4; };
	local ip;
	ip=$(getent ahosts "$host" 2>/dev/null | awk '{print $1; exit}');
	[[ -n "$ip" ]] || { logs:err "fetch::https: dns lookup failed: $host"; return 4; };
	fetch::is-blocked-ip "$ip" \
		&& { logs:err "fetch::https: blocked private host: $host ($ip)"; return 4; };

	# Download to temp; RETURN trap reclaims on any path out of this function.
	local tmp;
	tmp=$(mktemp);
	# shellcheck disable=SC2064 # expand $tmp now; the local is gone by trap-fire
	trap "rm -f '$tmp'" RETURN;

	curl -fsSL --max-filesize "$FETCH_MAX_DOWNLOAD_BYTES" -o "$tmp" "$url_clean" \
		|| { logs:err "fetch::https: download failed: $url_clean"; return 3; };

	# File mode: place the file and exit.
	if [[ "$unpack" != "true" ]]; then
		mkdir -p "$(dirname "$dest")" \
			|| { logs:err "fetch::https: cannot create $(dirname "$dest")"; return 3; };
		mv "$tmp" "$dest" \
			|| { logs:err "fetch::https: move failed: $tmp -> $dest"; return 3; };
		return 0;
	fi

	# Unpack mode: list once, vet for safety, then extract.
	local entries;
	entries=$(tar -tzf "$tmp" 2>/dev/null) \
		|| { logs:err "fetch::https: tar list failed (not a gzipped tarball?)"; return 3; };

	if grep -qE '^/|(^|/)\.\.($|/)' <<< "$entries"; then
		logs:err "fetch::https: unsafe tar entries (absolute path or .. traversal)";
		return 4;
	fi

	mkdir -p "$dest" \
		|| { logs:err "fetch::https: cannot create $dest"; return 3; };

	# Detect the github-archive wrapper dir (first entry's first segment).
	local prefix="${entries%%$'\n'*}";
	prefix="${prefix%/}";
	prefix="${prefix%%/*}";

	if [[ -n "$fragment" ]]; then
		# Selective extract: <prefix>/<fragment>/... → <dest>/...
		# Verify the subpath exists in the archive before we extract.
		grep -qE "^${prefix}/${fragment}(/|\$)" <<< "$entries" \
			|| { logs:err "fetch::https: subpath not found in archive: $fragment"; return 3; };

		local parts;
		IFS=/ read -ra parts <<< "$fragment";
		local strip=$((1 + ${#parts[@]}));

		tar -xzf "$tmp" -C "$dest" --strip-components="$strip" "$prefix/$fragment" 2>/dev/null \
			|| { logs:err "fetch::https: extract failed for subpath: $fragment"; return 3; };
	else
		# Full archive: strip the top-level wrapper dir (github convention).
		tar -xzf "$tmp" -C "$dest" --strip-components=1 2>/dev/null \
			|| { logs:err "fetch::https: extract failed"; return 3; };
	fi

	# Decompressed size cap (after extract, so we know the true cost).
	local size;
	size=$(du -sb "$dest" 2>/dev/null | awk '{print $1}');
	[[ "$size" -le "$FETCH_MAX_EXTRACTED_BYTES" ]] \
		|| { logs:err "fetch::https: extracted size $size exceeds $FETCH_MAX_EXTRACTED_BYTES"; return 4; };
}

# @name fetch::is-blocked-ip
# @type internal
# @desc Return 0 if IP is in a blocked range (loopback / RFC1918 / link-local /
# @desc IPv6 ::1). IPv4-mapped IPv6 (::ffff:1.2.3.4) is unwrapped to its IPv4
# @desc form before the case matches, so the same patterns cover both families.
# @usage fetch::is-blocked-ip <ip>
# @arg <ip> -- IPv4 or IPv6 address string
# @return 0 blocked | 1 allowed
function fetch::is-blocked-ip() {
	local ip="${1?ERROR: fetch::is-blocked-ip: missing <ip>}";
	[[ "$ip" =~ ^::ffff:([0-9.]+)$ ]] && ip="${BASH_REMATCH[1]}";
	case "$ip" in
		127.*|10.*|169.254.*|192.168.*) return 0 ;;
		172.1[6-9].*|172.2[0-9].*|172.3[0-1].*) return 0 ;;
		::1) return 0 ;;
		*) return 1 ;;
	esac
}
