# import Test Results

## import:pack

### Smoke Tests
Scenario      | Input                | Expected         | Status | Result
--------------|----------------------|------------------|--------|-------
basic-inline  | source .deps/lib     | packed in log    |      0 | ✅
passthrough   | no source lines      | no packed in log |      0 | ✅

### Acceptance Tests
Scenario          | Input                    | Expected          | Status | Result
------------------|--------------------------|-------------------|--------|-------
quoted-path       | source ".deps/lib"       | packed in log     |      0 | ✅
dotslash-path     | source ./.deps/lib       | packed in log     |      0 | ✅
multiple-sources  | 2 source lines           | 2x packed         |      0 | ✅
semicolon-suffix  | source .deps/lib;        | packed in log     |      0 | ✅
integrity         | source + other lines     | inlined, stripped |      0 | ✅

---

## import:fetch

### Smoke Tests
Scenario     | Input                              | Expected         | Status | Result
-------------|------------------------------------|------------------|--------|-------
github-basic | github/curatorium/...@main/LICENSE  | file downloaded  |      0 | ✅
https-basic  | https/raw.githubusercontent.com/...| file downloaded  |      0 | ✅

### Acceptance Tests
Scenario       | Input              | Expected           | Status | Result
---------------|--------------------|--------------------|--------|-------
creates-dirs   | github nested path | directories made   |      0 | ✅
skips-existing | fetch twice        | second uses -z     |      0 | ✅

### Regression Tests
Scenario      | Input            | Expected      | Status | Result
--------------|------------------|---------------|--------|-------
multiple-deps | github + https   | both fetched  |      0 | ✅

---

## URL Fallback

Scenario        | Input                          | Expected              | Status | Result
----------------|--------------------------------|-----------------------|--------|-------
latest-release  | bash-args@latest/bash-args.sh          | releases/latest/...   |      0 | ✅
named-release   | bash-args@v1.0.0-alpha/bash-args.sh    | releases/download/... |      0 | ✅
branch-fallback | bash-args@main/bash-args.sh            | refs/heads/main/...   |      0 | ✅

---

## LICENSE Injection

### Smoke Tests
Scenario        | Input                | Expected              | Status | Result
----------------|----------------------|-----------------------|--------|-------
injects-license | line 2 is # Copyright| LICENSE content added |      0 | ✅

### Acceptance Tests
Scenario           | Input                    | Expected          | Status | Result
-------------------|--------------------------|-------------------|--------|-------
skips-no-copyright | line 2 is not copyright  | line unchanged    |      0 | ✅
comments-license   | LICENSE file             | lines prefixed #  |      0 | ✅

---

## Flags

Scenario | Input                  | Expected             | Status | Result
---------|------------------------|----------------------|--------|-------
quiet    | -q pack bash-import    | no stderr output     |      0 | ✅
trace    | -x app pack bash-import| trace lines present  |      0 | ✅

---

## Integration Tests

Scenario        | Description                          | Status | Result
----------------|--------------------------------------| -------|-------
self-pack       | bash-import pack bash-import works   |      0 | ✅
fetch-then-pack | fetch + pack real dep                |      0 | ✅


## Summary

| ✅ Pass | ❌ Fail | ⚠️ Error |
|---------|---------|----------|
| 22 | 0 | 0 |

