#!/usr/bin/env bash

#
# fixhomeperms.sh
#
# Fix permissions for files and directories under one or more target paths.
#
# Default rules:
#   * directories:        0755
#   * regular files:      0644
#   * executable-by-type: 0755
#       - Shell scripts (.sh)
#       - Perl files  (.pl)
#       - Python files(.py)
#       - Ruby files  (.rb)
#       - RUN files   (.run)
#
# Examples:
#   ./fixhomeperms.sh -A
#   ./fixhomeperms.sh -A -v "$HOME"
#   ./fixhomeperms.sh -A .
#   ./fixhomeperms.sh -A -vv my-directory
#   ./fixhomeperms.sh -A -q dir1 dir2 dir3
#   ./fixhomeperms.sh -d -n .
#   ./fixhomeperms.sh -a ~/bin ~/src
#

set -o nounset
set -o pipefail

SCRIPT_NAME="$(basename "$0")"
VERSION="0.2100"

TARGETS=()
DO_DIRS=0
DO_NONEXEC=0
DO_EXEC=0

VERBOSE=0

PARALLEL_JOBS=4
XARGS_BATCH=1024

usage() {
    cat <<EOF
$SCRIPT_NAME v$VERSION by Martin Mielke <martinm@rsysadmin.com>

Usage:
  $SCRIPT_NAME [-h] [-v|-vv|-q] [-d] [-n] [-s] [-p] [-P] [-r] [-R] [-a] [-A] [directory ...]

Verbosity:
  -v   Verbose
  -vv  Very verbose (print every chmod)
  -q   Quiet

Options:
  -h  Help
  -d  Directories (0755)
  -n  Non-exec files (0644)
  -s  *.sh (0755)
  -p  *.pl (0755)
  -P  *.py (0755)
  -r  *.rb (0755)
  -R  *.run (0755)
  -a  All executable-by-type
  -A  Everything

EOF
    exit 1
}

timestamp() { date +%H:%M:%S; }

log() {
    [[ $VERBOSE -ge 0 ]] && printf ' [%s] == %s' "$(timestamp)" "$1"
}

log_verbose() {
    [[ $VERBOSE -ge 1 ]] && echo "    $*"
}

ok() { printf '\t[ OK ]\n'; }
error() { printf '\t[ ERROR ]\n' >&2; }

finish_message() {
    [[ $VERBOSE -ge 0 ]] && printf ' [%s] -- All set.\n\n' "$(timestamp)"
    exit 0
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

validate_targets() {
    for t in "${TARGETS[@]}"; do
        [[ -d "$t" ]] || die "Invalid directory: $t"
    done
}

run_chmod_find() {
    local description="$1"
    local mode="$2"
    shift 2

    log "$description ... "

    if [[ $VERBOSE -ge 2 ]]; then
        # VERY VERBOSE → per-file
        find "${TARGETS[@]}" "$@" -print0 |
        while IFS= read -r -d '' f; do
            echo "chmod $mode \"$f\""
            chmod "$mode" "$f"
        done
    else
        # NORMAL / VERBOSE → batched
        if find "${TARGETS[@]}" "$@" -print0 | \
            xargs -0 -r -n"$XARGS_BATCH" -P"$PARALLEL_JOBS" chmod "$mode"
        then
            :
        else
            error
            return 1
        fi
    fi

    ok
}

fix_directories() {
    run_chmod_find "Fixing directory permissions (0755)" "0755" -type d
}

fix_nonexec_files() {
    run_chmod_find "Fixing non-exec files (0644)" "0644" \
        -type f \
        ! -name '*.sh' \
        ! -name '*.pl' \
        ! -name '*.py' \
        ! -name '*.rb' \
        ! -name '*.run' \
        ! -path '*/.*'
}

fix_exec_by_pattern() {
    local pattern="$1"
    local label="$2"

    log_verbose "Pattern: $pattern"

    run_chmod_find "Fixing $label files (0755)" "0755" \
        -type f -name "$pattern"
}

fix_shell_files()  { fix_exec_by_pattern '*.sh' "Shell"; }
fix_perl_files()   { fix_exec_by_pattern '*.pl' "Perl"; }
fix_python_files() { fix_exec_by_pattern '*.py' "Python"; }
fix_ruby_files()   { fix_exec_by_pattern '*.rb' "Ruby"; }
fix_run_files()    { fix_exec_by_pattern '*.run' "RUN"; }

parse_args() {
    if [[ $# -eq 0 ]]; then
        usage
    fi

    while getopts ":hvqdnsppPrRaA" opt; do
        case "$opt" in
            h) usage ;;
            v) ((VERBOSE++)) ;;
            q) VERBOSE=-1 ;;
            d) DO_DIRS=1 ;;
            n) DO_NONEXEC=1 ;;
            s) DO_EXEC=1; EXEC_SHELL=1 ;;
            p) DO_EXEC=1; EXEC_PERL=1 ;;
            P) DO_EXEC=1; EXEC_PYTHON=1 ;;
            r) DO_EXEC=1; EXEC_RUBY=1 ;;
            R) DO_EXEC=1; EXEC_RUN=1 ;;
            a)
                DO_EXEC=1
                EXEC_SHELL=1
                EXEC_PERL=1
                EXEC_PYTHON=1
                EXEC_RUBY=1
                EXEC_RUN=1
                ;;
            A)
                DO_DIRS=1
                DO_NONEXEC=1
                DO_EXEC=1
                EXEC_SHELL=1
                EXEC_PERL=1
                EXEC_PYTHON=1
                EXEC_RUBY=1
                EXEC_RUN=1
                ;;
            *) usage ;;
        esac
    done

    shift $((OPTIND - 1))

    if [[ $# -gt 0 ]]; then
        TARGETS=("$@")
    else
        TARGETS=("$HOME")
    fi

    if [[ $DO_DIRS -eq 0 && $DO_NONEXEC -eq 0 && $DO_EXEC -eq 0 ]]; then
        usage
    fi
}

main() {
    EXEC_SHELL=0
    EXEC_PERL=0
    EXEC_PYTHON=0
    EXEC_RUBY=0
    EXEC_RUN=0

    parse_args "$@"
    validate_targets

    [[ $DO_DIRS -eq 1 ]] && fix_directories
    [[ $DO_NONEXEC -eq 1 ]] && fix_nonexec_files

    if [[ $DO_EXEC -eq 1 ]]; then
        [[ $EXEC_SHELL -eq 1 ]] && fix_shell_files
        [[ $EXEC_PERL -eq 1 ]] && fix_perl_files
        [[ $EXEC_PYTHON -eq 1 ]] && fix_python_files
        [[ $EXEC_RUBY -eq 1 ]] && fix_ruby_files
        [[ $EXEC_RUN -eq 1 ]] && fix_run_files
    fi

    finish_message
}

main "$@"