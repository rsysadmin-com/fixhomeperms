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
#   ./fixhomeperms.sh -a -N ~/bin ~/src
#

set -o nounset
set -o pipefail

SCRIPT_NAME="$(basename "$0")"
VERSION="0.1200"

TARGETS=()
DO_DIRS=0
DO_NONEXEC=0
DO_EXEC=0

VERBOSE=0          # -1=quiet, 0=normal, 1=verbose, 2=very verbose
DRY_RUN=0

PARALLEL_JOBS=4
XARGS_BATCH=1024

usage() {
    cat <<EOF
$SCRIPT_NAME v$VERSION by Martin Mielke <martinm@rsysadmin.com>

Usage:
  $SCRIPT_NAME [options] [directory ...]

Verbosity:
  -v            Verbose
  -vv           Very verbose
  -q            Quiet

Simulation:
  -N            Dry run
  --dry-run     Dry run

Options:
  -h  Help
  -d  Fix directories (0755)
  -n  Fix non-exec files (0644)
  -s  Fix shell files (*.sh -> 0755)
  -p  Fix Perl files (*.pl -> 0755)
  -P  Fix Python files (*.py -> 0755)
  -r  Fix Ruby files (*.rb -> 0755)
  -R  Fix RUN files (*.run -> 0755)
  -a  Fix all executable-by-type files
  -A  Fix everything:
      directories + non-exec files + executable-by-type files

Notes:
  * If no directory is provided, \$HOME is used.
  * Multiple directories may be specified.
  * Hidden paths are excluded from the non-exec pass.

Examples:
  $SCRIPT_NAME -A
  $SCRIPT_NAME -A .
  $SCRIPT_NAME -A \$HOME
  $SCRIPT_NAME -A dir1 dir2
  $SCRIPT_NAME -A -N .
  $SCRIPT_NAME -A --dry-run -vv .
EOF
    exit 1
}

timestamp() {
    date +%H:%M:%S
}

log() {
    [[ $VERBOSE -ge 0 ]] && printf ' [%s] == %s' "$(timestamp)" "$1"
}

log_verbose() {
    [[ $VERBOSE -ge 1 ]] && printf '    %s\n' "$*"
}

log_vverbose() {
    [[ $VERBOSE -ge 2 ]] && printf '    %s\n' "$*"
}

ok() {
    [[ $VERBOSE -ge 0 ]] && printf '\t[ OK ]\n'
}

error() {
    [[ $VERBOSE -ge 0 ]] && printf '\t[ ERROR ]\n' >&2
}

finish_message() {
    [[ $VERBOSE -ge 0 ]] && printf ' [%s] -- All set.\n\n' "$(timestamp)"
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

preparse_long_options() {
    REMAINING_ARGS=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --help)
                usage
                ;;
            --)
                shift
                while [[ $# -gt 0 ]]; do
                    REMAINING_ARGS+=("$1")
                    shift
                done
                break
                ;;
            *)
                REMAINING_ARGS+=("$1")
                shift
                ;;
        esac
    done
}

apply_mode_to_file() {
    local mode="$1"
    local file="$2"

    if [[ $DRY_RUN -eq 1 ]]; then
        printf 'chmod %s %q\n' "$mode" "$file"
    else
        chmod "$mode" "$file"
    fi
}

run_chmod_find() {
    local description="$1"
    local mode="$2"
    shift 2

    log "$description ... "

    if [[ $VERBOSE -ge 1 ]]; then
        if [[ $DRY_RUN -eq 1 ]]; then
            log_verbose "Mode: $mode"
            log_verbose "Targets: ${TARGETS[*]}"
            log_verbose "Dry-run: yes"
        else
            log_verbose "Mode: $mode"
            log_verbose "Targets: ${TARGETS[*]}"
            log_verbose "Dry-run: no"
        fi
    fi

    if [[ $DRY_RUN -eq 1 || $VERBOSE -ge 2 ]]; then
        local f
        local rc=0

        while IFS= read -r -d '' f; do
            apply_mode_to_file "$mode" "$f" || rc=1
        done < <(find "${TARGETS[@]}" "$@" -print0)

        if [[ $rc -eq 0 ]]; then
            ok
        else
            error
            return 1
        fi
    else
        if find "${TARGETS[@]}" "$@" -print0 | \
           xargs -0 -r -n"$XARGS_BATCH" -P"$PARALLEL_JOBS" chmod "$mode"
        then
            ok
        else
            error
            return 1
        fi
    fi
}

fix_directories() {
    run_chmod_find \
        "Fixing directory permissions (0755)" \
        "0755" \
        -type d
}

fix_nonexec_files() {
    run_chmod_find \
        "Fixing non-exec file permissions (0644)" \
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

    log_verbose "Pattern: $pattern"

    run_chmod_find \
        "Fixing permissions for $label files (0755)" \
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

parse_args() {
    local opt

    preparse_long_options "$@"
    set -- "${REMAINING_ARGS[@]}"

    if [[ $# -eq 0 ]]; then
        usage
    fi

    while getopts ":hvqNdnspPrRaA" opt; do
        case "$opt" in
            h) usage ;;
            v) ((VERBOSE++)) ;;
            q) VERBOSE=-1 ;;
            N) DRY_RUN=1 ;;
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
    EXEC_SHELL=0
    EXEC_PERL=0
    EXEC_PYTHON=0
    EXEC_RUBY=0
    EXEC_RUN=0
    REMAINING_ARGS=()

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