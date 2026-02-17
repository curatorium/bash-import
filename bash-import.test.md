# import Test Results

## Smoke Tests

Scenario     | Description                      | Status | Result
-------------|----------------------------------|--------|-------
self-pack    | bash-import packs itself          |      0 | ✅
pack-inline  | source .deps/lib → packed log     |      0 | ✅
fetch-github | download from github              |      0 | ✅
fetch-https  | download from https               |      0 | ✅
install      | pack + install to bin              |      0 | ✅
quiet        | -q suppresses output              |      0 | ✅
trace        | -x app enables tracing            |      0 | ✅

---

## Feature Tests

### Source line formats
Scenario      | Input                    | Expected      | Status | Result
--------------|--------------------------|---------------|--------|-------
passthrough   | no source lines          | no packed log |      0 | ✅
quoted        | source ".deps/lib"       | packed        |      0 | ✅
single-quoted | source '.deps/lib'       | packed        |      0 | ✅
dotslash      | source ./.deps/lib       | packed        |      0 | ✅
indented      | \tsource .deps/lib       | packed        |      0 | ✅
semicolon     | source .deps/lib;        | packed        |      0 | ✅

### Source line rejection
Scenario    | Input                   | Expected   | Status | Result
------------|-------------------------|------------|--------|-------
commented   | # source .deps/lib      | not packed |      0 | ✅
in-string   | echo "source .deps/lib" | not packed |      0 | ✅
dot-builtin | . .deps/lib             | not packed |      0 | ✅

### Dep content handling
Scenario         | Input                | Expected                  | Status | Result
-----------------|----------------------|---------------------------|--------|-------
integrity        | source .deps/lib-full| headers stripped, inlined  |      0 | ✅
install-strips   | install lib-full dep | headers stripped in output |      0 | ✅
shebang-only     | dep: shebang no ©    | shebang stripped, content  |      0 | ✅
no-headers       | dep: no shebang/©    | all content preserved      |      0 | ✅
empty-dep        | dep: empty file      | main code preserved        |      0 | ✅
single-line      | input: just shebang  | shebang preserved          |      0 | ✅
help-heredoc     | source .deps/@help   | heredoc wrapping           |      0 | ✅
empty-input      | input: empty file    | no crash, empty output     |      0 | ✅

### LICENSE injection
Scenario           | Input                 | Expected              | Status | Result
-------------------|-----------------------|-----------------------|--------|-------
injects            | line 2 is # Copyright | LICENSE content added  |      0 | ✅
skips-no-copyright | line 2 not copyright  | line unchanged         |      0 | ✅
comments           | LICENSE file          | lines prefixed #       |      0 | ✅

### Fetch behavior
Scenario       | Input              | Expected         | Status | Result
---------------|--------------------|------------------|--------|-------
creates-dirs   | github nested path | directories made |      0 | ✅
skips-existing | fetch twice        | second uses -z   |      0 | ✅
no-remote-deps | source .deps/lib   | no-op            |      0 | ✅
stale-refetch  | old mtime file     | mtime updated    |      0 | ✅
fresh-found    | fetch twice        | log says "found" |      0 | ✅
dedup          | same dep twice     | one log line     |      0 | ✅

### URL fallback strategies
Scenario       | Input                         | Expected            | Status | Result
---------------|-------------------------------|---------------------|--------|-------
latest-release | bash-args@latest/bash-args.sh  | releases/latest/... |      0 | ✅
named-release  | bash-args@v1.0.0-alpha/...     | releases/download/  |      0 | ✅

### Flag forms
Scenario   | Input                        | Expected         | Status | Result
-----------|------------------------------|------------------|--------|-------
quiet-long | --quiet pack bash-import     | no stderr output |      0 | ✅
trace-long | --trace app pack bash-import | trace present    |      0 | ✅

### Install
Scenario    | Input          | Expected | Status | Result
------------|----------------|----------|--------|-------
permissions | install -m 755 | file 755 |      0 | ✅
overwrite  | install twice  | new wins |      0 | ✅

---

## Acceptance Tests

Scenario           | Description                | Status | Result
-------------------|----------------------------|--------|-------
multiple-sources   | 2 deps in one file         |      0 | ✅
fetch-multiple-deps| github + https in one file |      0 | ✅
fetch-then-pack    | fetch + pack pipeline      |      0 | ✅
fetch-via-main     | ./bash-import fetch e2e    |      0 | ✅
install-via-main   | ./bash-import install e2e  |      0 | ✅
stdin-pipe         | cat | ./bash-import pack   |      0 | ✅

---

## Regression Tests

Scenario         | Description                  | Status | Result
-----------------|------------------------------|--------|-------
quiet-trace          | -q -x app: quiet wins        |      0 | ✅
no-license-file      | pack without LICENSE in dir   |      0 | ✅
missing-dep          | source .deps/nonexistent     |      0 | ✅
nonexistent-repo     | fetch from fake github repo  |      0 | ✅
missing-file         | pack nonexistent input file  |      0 | ✅
temp-cleanup         | install cleans temp file     |      0 | ✅
install-invalid-input| install with bad input file  |      0 | ✅


## Summary

| ✅ Pass | ❌ Fail | ⚠️ Error |
|---------|---------|----------|
| 52 | 0 | 0 |

