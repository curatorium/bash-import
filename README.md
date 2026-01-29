# bash-import

> Dependency manager and source inliner for bash scripts.

## Installation

```bash
curl -1fsSLR https://github.com/curatorium/bash-import/releases/latest/download/bash-import -o /usr/local/bin/bash-import
chmod +x /usr/local/bin/bash-import
```

## Usage

```bash
  bash-import [-q] [-x <lvl: app|all>] <cmd: pack|fetch|install> [...args]	
  bash-import -h                                                          	
```

| Parameter                       | Description                                                                          |
|---------------------------------|--------------------------------------------------------------------------------------|
| `<cmd>`                         | Subcommand: fetch, pack, or install                                                  |
| `[-q\|--quiet]`                 | Suppress output.                                                                     |
| `[-x\|--trace <lvl: app\|all>]` | Level of debug tracing, "app" traces only this file, "all" also traces dependencies. |
| `[-h\|--help]`                  | Print the help instructions                                                          |

## Subcommands
### `bash-import fetch`

Downloads remote dependencies from .deps/@https/* and .deps/@github/* paths.	

```bash
bash-import fetch <file>      	
bash-import fetch < <file>    	
cat <file> | bash-import fetch	
```

| Parameter | Description |
|-----------|-------------|
| `<file>`  | Input file. |

### `bash-import pack`

Inlines source .deps/... statements into a single output file.	

```bash
bash-import pack <file> [-o <out>]   	
bash-import pack < <file> > <out>    	
cat <file> | bash-import pack > <out>	
```

| Parameter            | Description                        |
|----------------------|------------------------------------|
| `<file>`             | Input file.                        |
| `[-o\|--out  <out>]` | Output file. Default: /dev/stdout. |

### `bash-import install`

Packs a script and installs it to /usr/local/bin.	

```bash
bash-import install <file> [-o <out>]	
```

| Parameter            | Description                                              |
|----------------------|----------------------------------------------------------|
| `<file>`             | Input file.                                              |
| `[-o\|--out  <out>]` | Output file. Default: /usr/local/bin/<basename of file>. |


## License

MIT
