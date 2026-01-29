# bash-import

> Dependency manager and source inliner for bash scripts.

## Installation

```bash
curl -1fsSLR https://github.com/curatorium/bash-import/releases/latest/download/bash-import -o /usr/local/bin/bash-import
chmod +x /usr/local/bin/bash-import
```

## Usage









## Subcommands
### `bash-import pack`

Inlines source .deps/... statements into a single output file.	

```bash
bash-import pack [-q|--quiet] [<file>] [-o <out>]	
bash-import pack < <file> > <out>                	
cat <file> | bash-import pack > <out>            	
```

### `bash-import fetch`

Downloads remote dependencies from .deps/https/... and .deps/github/... paths.	

```bash
bash-import fetch [-q] [<file>]	
bash-import fetch < <file>     	
cat <file> | bash-import fetch 	
```

| Argument | Description |
|----------|-------------|
| `[<file>]    ` | Input file. Default: /dev/stdin. |

### `bash-import install`

Packs a script and installs it to /usr/local/bin.	

```bash
bash-import install <file> [-o <out>]	
```

| Flag | Description |
|------|-------------|
| `[-o\|--out  <out>]` | Output file. Default: /usr/local/bin/<basename of file>. |

| Argument | Description |
|----------|-------------|
| `<file>            ` | Input file. |

### `help`




## License

MIT
