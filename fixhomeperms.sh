#!/usr/bin/env bash

#
# fixhomeperms.sh v0.1000
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
#   ./fixhomeperms.sh -A "$HOME"
#   ./fixhomeperms.sh -A .
#   ./fixhomeperms.sh -A my-directory
#   ./fixhomeperms.sh -A dir1 dir2 dir3
#   ./fixhomeperms.sh -d -n .
#   ./fixhomeperms.sh -a ~/bin ~/src
#

set -o nounset
set -o pipefail

SCRIPT_NAME="$(basename "$0")"
VERSION="0.1000"

TARGETS=()
DO_DIRS=0
DO_NONEXEC=0
DO_EXEC=0

# xargs parallelism; tune if desired
PARALLEL_JOBS=4
XARGS_BATCH=1024

usage() {
    cat <<EOF
$SCRIPT_NAME v$VERSION by Martin Mielke <martinm@rsysadmin.com>

Usage:
  $SCRIPT_NAME [-h] [-d] [-n] [-s] [-p] [-P] [-r] [-R] [-a] [-A] [directory ...]

Options:
  -h  Print this help.
  -d  Fix permissions on directories (0755).
  -n  Fix permissions on non-exec files (0644).
  -s  Fix permissions on shell script files (*.sh -> 0755).
  -p  Fix permissions on Perl files (*.pl -> 0755).
  -P  Fix permissions on Python files (*.py -> 0755).
  -r  Fix permissions on Ruby files (*.rb -> 0755).
  -R  Fix permissions on RUN files (*.run -> 0755).
  -a  Fix permissions on all executable-by-type files.
  -A  Fix everything in one step:
      directories + non-exec files + all executable-by-type files.

Notes:
  * If no directory is provided, \$HOME is used.
  * Multiple directories may be specified.
  * Hidden files are excluded from the non-exec pass, like in your original script.

Examples:
  $SCRIPT_NAME -A
  $SCRIPT_NAME -A \$HOME
  $SCRIPT_NAME -A .
  $SCRIPT_NAME -A my-directory
  $SCRIPT_NAME -A dir1 dir2 dir3
EOF
    exit 1
}

timestamp() {
    date +%H:%M:%S
}

log() {
    printf ' [%s] == %s' "$(timestamp)" "$1"
}

ok() {
    printf '\t[ OK ]\n'
}

error() {
    printf '\t[ ERROR ]\n' >&2
}

finish_message() {
    printf ' [%s] -- All set.\n\n' "$(timestamp)"
    exit 0
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

validate_targets() {
    local t
    for t in "${TARGETS[@]}"; do
        [[ -e "$t" ]] || die "Target does not exist: $t"
        [[ -d "$t" ]] || die "Target is not a directory: $t"
    done
}

run_chmod_find() {
    local description="$1"
    local mode="$2"
    shift 2

    log "$description ... "

    if find "${TARGETS[@]}" "$@" -print0 | xargs -0 -r -n"$XARGS_BATCH" -P"$PARALLEL_JOBS" chmod "$mode"
    then
        ok
    else
        error
        return 1
    fi
}

fix_directories() {
    run_chmod_find \
        "Fixing directory permissions (chmod 0755)" \
        "0755" \
        -type d
}

fix_nonexec_files() {
    run_chmod_find \
        "Fixing non-exec file permissions (chmod 0644)" \
        "0644" \
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

    run_chmod_find \
        "Fixing permissions for $label files (chmod 0755)" \
        "0755" \
        -type f \
        -name "$pattern"
}

fix_shell_files() {
    fix_exec_by_pattern '*.sh' 'Shell'
}

fix_perl_files() {
    fix_exec_by_pattern '*.pl' 'Perl'
}

fix_python_files() {
    fix_exec_by_pattern '*.py' 'Python'
}

fix_ruby_files() {
    fix_exec_by_pattern '*.rb' 'Ruby'
}

fix_run_files() {
    fix_exec_by_pattern '*.run' 'RUN'
}

fix_all_executable_files() {
    fix_shell_files
    fix_perl_files
    fix_python_files
    fix_ruby_files
    fix_run_files
}

fix_all() {
    fix_directories
    fix_nonexec_files
    fix_all_executable_files
}

parse_args() {
    local opt

    if [[ $# -eq 0 ]]; then
        usage
    fi

    while getopts ":hdnspPrRaA" opt; do
        case "$opt" in
            h) usage ;;
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
            \?)
                usage
                ;;
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
    # initialize per-extension flags
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

# The End.
