# fixhomeperms.sh

A fast and flexible Bash utility to fix file and directory permissions across one or more target paths.

Originally a "quick and dirty" script, it has evolved into a more robust and configurable tool that normalizes permissions using `find` and `xargs` for performance.

## Features

- Supports one or multiple target directories
- Defaults to `$HOME` if no path is provided
- Fast execution using `find` + `xargs`
- Optional verbosity levels
- Optional dry-run mode
- Selective fixes (directories, files, or specific script types)

## Use case

Especially useful when copying files between systems or restoring backups where permissions get mangled:

```
  drwxrwxrwx directory
  -rwxrwxrwx file
```

## Assumptions

The script enforces the following conventions:

1. Directories -> `rwxr-xr-x` (0755)
2. Non-executable files (e.g. .txt, .pdf) -> `rw-r--r--` (0644)
3. Executable files by extension:
   - .sh, .pl, .py, .rb, .run -> `rwxr-xr-x` (0755)
4. Hidden files and directories are ignored in the non-exec pass

Note: Executable files are detected by extension, not by shebang or existing execute bit.

## Usage

`./fixhomeperms.sh [options] [directory ...]`

If no directory is provided, `$HOME` is used.

### Options
```
  -h  Help

  -d  Fix directories (0755)
  -n  Fix non-exec files (0644)

  -s  *.sh files (0755)
  -p  *.pl files (0755)
  -P  *.py files (0755)
  -r  *.rb files (0755)
  -R  *.run files (0755)

  -a  All executable-by-type files
  -A  Everything:
      directories + non-exec + executable files
```

### Verbosity
```
  -v   Verbose output
  -vv  Very verbose (prints every chmod)
  -q   Quiet mode (cron-friendly)
```

### Dry-run (simulation mode)
```
  -N            Dry-run
  --dry-run     Dry-run
```
Shows what would be executed without modifying anything.

## Examples

Fix everything in current directory:
`./fixhomeperms.sh -A .`

Fix everything in multiple directories:
`./fixhomeperms.sh -A dir1 dir2 dir3`

Dry-run before applying changes:
`./fixhomeperms.sh -A --dry-run .`

Verbose dry-run:
`./fixhomeperms.sh -A -vv --dry-run .`

Quiet mode:
`./fixhomeperms.sh -A -q /some/path`

## Considerations

- Uses parallel execution (`xargs -P`), which can be tuned in the script
- Hidden files are skipped in non-exec processing
- Does not detect executables via shebang (by design)
- Use caution when running on large directory trees or system paths

## Customization

You can easily adapt:

- File extensions considered executable
- Permission modes
- Exclusion rules (e.g. .git, .cache, node_modules)
- Parallelism (PARALLEL_JOBS)

## Disclaimer

This script is provided "AS IS", without warranty of any kind.

The author shall not be held responsible for any damage caused by the use or misuse of this tool.