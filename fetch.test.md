# fetch.sh tests

Tests for `fetch:url`, `fetch::gh-to-url`, `fetch::https`, and `fetch::is-blocked-ip`.

---

## Smoke -- the 2x3 URL matrix (plus latest)

| Cell                       | Input                                  | Expected URL family                 | Result                          |
|----------------------------|----------------------------------------|-------------------------------------|---------------------------------|
| archive + tag (default)    | curatorium/curated@v1/redis            | /archive/refs/tags/v1.tar.gz#/redis | ✅               |
| archive + branch           | curatorium/curated@main/redis          | /archive/refs/heads/main.tar.gz     | ✅            |
| archive + release (norm.)  | curatorium/curated@v1/redis            | normalizes to archive+tag           | ✅ |
| file + tag                 | curatorium/bash-import@v1.0/bash-import| /raw/v1.0/bash-import               | ✅                  |
| file + branch              | curatorium/bash-import@main/bash-import| /raw/main/bash-import               | ✅               |
| file + release             | curatorium/bash-import@v1.0/...        | /releases/download/v1.0/...         | ✅              |
| file + release + @latest   | curatorium/bash-import@latest/...      | /releases/latest/download/...       | ✅       |

---

## Feature -- prefix stripping, defaults, fragments

| Scenario               | Input prefix or shape       | Expected                          | Result                              |
|------------------------|-----------------------------|-----------------------------------|-------------------------------------|
| gh: prefix             | gh:vendor/pkg@v/sub         | same URL as canonical             | ✅                  |
| github: prefix         | github:vendor/pkg@v/sub     | same URL as canonical             | ✅              |
| @github/ prefix        | @github/vendor/pkg@v/sub    | same URL as canonical             | ✅           |
| archive, no subpath    | vendor/pkg@v (no /sub)      | no #fragment in URL               | ✅         |
| nested subpath         | vendor/pkg@v/a/b/c          | fragment encodes full subpath     | ✅             |

## Feature -- fetch::is-blocked-ip coverage

| IP                      | Class                       | Expected | Result                                |
|-------------------------|-----------------------------|----------|---------------------------------------|
| 127.0.0.1               | IPv4 loopback               | blocked  | ✅             |
| 10.1.2.3                | RFC1918 10.x                | blocked  | ✅           |
| 192.168.1.1             | RFC1918 192.168.x           | blocked  | ✅          |
| 169.254.169.254         | link-local (AWS metadata)   | blocked  | ✅           |
| 172.16.0.1              | RFC1918 172.16.x (boundary) | blocked  | ✅      |
| 172.31.255.255          | RFC1918 172.31.x (boundary) | blocked  | ✅     |
| ::1                     | IPv6 loopback               | blocked  | ✅        |
| ::ffff:127.0.0.1        | IPv4-mapped IPv6            | blocked  | ✅     |
| 8.8.8.8                 | public                      | allowed  | ✅               |
| 172.32.0.1              | just outside RFC1918        | allowed  | ✅  |

## Feature -- fetch::https tar safety, selective extract (mocked curl)

| Scenario              | Input                            | Expected                       | Result                              |
|-----------------------|----------------------------------|--------------------------------|-------------------------------------|
| absolute path entry   | tar contains /etc/passwd         | rc=4 (rejected)                | ✅   |
| .. traversal entry    | tar contains ../etc/passwd       | rc=4 (rejected)                | ✅       |
| selective extract     | archive#/redis, archive has redis/, mysql/ | only redis/ in dest    | ✅  |
| full extract          | archive, no fragment             | top-level wrapper stripped     | ✅ |
| fragment not in tar   | archive#/nonexistent             | rc=3 (subpath missing)         | ✅    |
| file mode             | URL, no --unpack                 | saved as-is, contents preserved| ✅      |

---

## Negative -- inputs we must reject

| Scenario              | Input                              | Expected rc | Result                          |
|-----------------------|------------------------------------|-------------|---------------------------------|
| archive + @latest     | vendor/pkg@latest/sub --unpack tag | 2           | ✅        |
| file mode no subpath  | vendor/pkg@v --no-unpack tag       | 2           | ✅       |
| malformed ref         | not-a-valid-ref                    | 2           | ✅         |
| missing @version      | vendor/pkg/sub                     | 2           | ✅       |
| http:// rejected      | fetch:url http://...               | 4           | ✅         |
| ftp:// rejected       | fetch:url ftp://...                | 4           | ✅          |
| file:// rejected      | fetch:url file://...               | 4           | ✅         |

## Summary

| ✅ Pass | ❌ Fail | ⚠️ Error |
|---------|---------|----------|
| 35 | 0 | 0 |

