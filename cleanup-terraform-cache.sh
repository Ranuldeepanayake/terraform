#!/usr/bin/env bash
#
# Remove Terraform provider caches and dependency lock files under this repository.
#
# Only ".terraform/providers" directories and ".terraform.lock.hcl" regular files
# are targets. Other contents of ".terraform", including state files, are preserved.
# Symbolic links are not followed; linked top-level targets are skipped.
# Requires Bash and the standard Linux find, stat, realpath, and coreutils commands.
#
# Usage:
#   bash ./cleanup-terraform-cache.sh [--dry-run] [--yes]
#
# Options:
#   -n, --dry-run  Show targets and estimated reclaimable space without deleting.
#   -y, --yes      Skip the interactive confirmation before deleting.
#   -h, --help     Show this help text.
#
# Example:
#   bash ./cleanup-terraform-cache.sh --dry-run

set -uo pipefail

ERROR_COUNT=0
SIZE_ESTIMATE_COMPLETE=1
DRY_RUN=0
ASSUME_YES=0

log() {
    local level=$1
    shift
    printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*"
}

show_help() {
    sed -n 's/^# \{0,1\}//p' "$SCRIPT_PATH" | sed -n '/^Usage:/,/^$/p; /^Options:/,/^$/p; /^Example:/,/^$/p'
}

format_bytes() {
    local bytes=$1
    local value=$bytes
    local -a units=(B KB MB GB TB)
    local unit_index=0

    while (( value >= 1024 && unit_index < ${#units[@]} - 1 )); do
        value=$((value / 1024))
        unit_index=$((unit_index + 1))
    done

    # Keep one decimal digit without floating-point dependencies.
    if (( unit_index == 0 )); then
        printf '%s %s' "$bytes" "${units[$unit_index]}"
    else
        local divisor=1
        local i
        for ((i = 0; i < unit_index; i++)); do
            divisor=$((divisor * 1024))
        done
        local tenths=$((bytes * 10 / divisor))
        printf '%d.%d %s' "$((tenths / 10))" "$((tenths % 10))" "${units[$unit_index]}"
    fi
}

# Verify a canonical path is beneath (not equal to) the canonical repository root.
is_within_repository() {
    local candidate=$1
    case "$candidate" in
        "$REPOSITORY_ROOT"/*) return 0 ;;
        *) return 1 ;;
    esac
}

# Measure regular-file lengths only; find does not follow symbolic links by default.
measure_target() {
    local target_type=$1
    local target_path=$2
    local total_bytes=0
    local size

    if [[ $target_type == "dependency lock file" ]]; then
        if ! size=$(stat -c '%s' -- "$target_path"); then
            log ERROR "Could not measure '$target_path'."
            return 1
        fi
        printf '%s' "$size"
        return 0
    fi

    local file_list
    file_list=$(mktemp "$TEMP_DIRECTORY/files.XXXXXX") || {
        log ERROR 'Could not create a temporary file list for size measurement.'
        return 1
    }

    if ! find "$target_path" -type f -print0 >"$file_list"; then
        log ERROR "Could not fully scan provider cache '$target_path' for its size."
        rm -f -- "$file_list"
        return 1
    fi

    local file
    while IFS= read -r -d '' file; do
        if ! size=$(stat -c '%s' -- "$file"); then
            log ERROR "Could not measure file '$file'."
            rm -f -- "$file_list"
            return 1
        fi
        total_bytes=$((total_bytes + size))
    done <"$file_list"

    rm -f -- "$file_list"
    printf '%s' "$total_bytes"
}

while (($# > 0)); do
    case "$1" in
        -n|--dry-run)
            DRY_RUN=1
            ;;
        -y|--yes)
            ASSUME_YES=1
            ;;
        -h|--help)
            SCRIPT_PATH=${BASH_SOURCE[0]}
            show_help
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            printf 'Use --help for usage.\n' >&2
            exit 2
            ;;
    esac
    shift
done

SCRIPT_PATH=${BASH_SOURCE[0]}
SCRIPT_DIRECTORY=$(cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd -P) || {
    printf 'ERROR: Could not resolve the script directory.\n' >&2
    exit 1
}
REPOSITORY_ROOT=$SCRIPT_DIRECTORY

if [[ ! -e $REPOSITORY_ROOT/.git ]]; then
    log ERROR "The script directory is not a Git repository root: $REPOSITORY_ROOT"
    exit 1
fi

TEMP_DIRECTORY=$(mktemp -d) || {
    log ERROR 'Could not create a temporary directory.'
    exit 1
}
trap 'rm -rf -- "$TEMP_DIRECTORY"' EXIT

log INFO "Repository root: $REPOSITORY_ROOT"
if (( DRY_RUN )); then
    log INFO 'Dry run enabled; no files or directories will be removed.'
fi
log INFO 'Terraform state and all files outside the two explicit target types are protected.'

SCAN_RESULTS=$TEMP_DIRECTORY/scan-results
if ! find "$REPOSITORY_ROOT" -mindepth 1 \
    \( -type d -name .git -prune \) -o \
    \( -type d -name .terraform -print0 -prune \) -o \
    \( -type f -name .terraform.lock.hcl -print0 \) >"$SCAN_RESULTS"; then
    log ERROR 'Repository scan failed; refusing to remove any targets.'
    exit 1
fi

declare -a TARGET_PATHS=()
declare -a TARGET_TYPES=()

add_target() {
    local target_type=$1
    local target_path=$2
    local canonical_path

    if ! canonical_path=$(realpath -e -- "$target_path"); then
        log ERROR "Could not resolve cleanup target '$target_path'."
        ERROR_COUNT=$((ERROR_COUNT + 1))
        SIZE_ESTIMATE_COMPLETE=0
        return
    fi

    if ! is_within_repository "$canonical_path"; then
        log ERROR "Refusing target outside the repository: $canonical_path"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        SIZE_ESTIMATE_COMPLETE=0
        return
    fi

    TARGET_PATHS+=("$canonical_path")
    TARGET_TYPES+=("$target_type")
}

# The scan prunes each .terraform directory, so inspect only its providers child.
while IFS= read -r -d '' scan_path; do
    if [[ ${scan_path##*/} == .terraform ]]; then
        providers_path=$scan_path/providers
        if [[ -L $providers_path ]]; then
            log WARN "Skipping linked providers directory: $providers_path"
        elif [[ -d $providers_path ]]; then
            add_target 'provider cache' "$providers_path"
        fi
    else
        add_target 'dependency lock file' "$scan_path"
    fi
done <"$SCAN_RESULTS"

if (( ERROR_COUNT > 0 )); then
    log ERROR 'Target discovery was incomplete; refusing to remove any targets.'
    exit 1
fi

log INFO "Found ${#TARGET_PATHS[@]} cleanup target(s)."
RECLAIMABLE_BYTES=0
for index in "${!TARGET_PATHS[@]}"; do
    if target_bytes=$(measure_target "${TARGET_TYPES[$index]}" "${TARGET_PATHS[$index]}"); then
        RECLAIMABLE_BYTES=$((RECLAIMABLE_BYTES + target_bytes))
    else
        ERROR_COUNT=$((ERROR_COUNT + 1))
        SIZE_ESTIMATE_COMPLETE=0
    fi
done

if (( SIZE_ESTIMATE_COMPLETE )); then
    log INFO "Estimated reclaimable file size: $(format_bytes "$RECLAIMABLE_BYTES") ($RECLAIMABLE_BYTES bytes)."
else
    log ERROR 'Could not calculate a complete reclaimable-size estimate; refusing to remove any targets.'
    exit 1
fi

if (( DRY_RUN )); then
    for index in "${!TARGET_PATHS[@]}"; do
        log INFO "Would remove ${TARGET_TYPES[$index]}: ${TARGET_PATHS[$index]}"
    done
    log INFO 'Dry run completed; no changes were made.'
    exit 0
fi

if ((${#TARGET_PATHS[@]} > 0)) && (( ! ASSUME_YES )); then
    if [[ ! -t 0 ]]; then
        log ERROR 'Confirmation is required in non-interactive mode; rerun with --yes after reviewing the targets.'
        exit 2
    fi

    read -r -p 'Remove all listed targets? [y/N] ' confirmation
    case "$confirmation" in
        [yY]|[yY][eE][sS]) ;;
        *)
            log INFO 'Cleanup cancelled; no changes were made.'
            exit 0
            ;;
    esac
fi

for index in "${!TARGET_PATHS[@]}"; do
    target_path=${TARGET_PATHS[$index]}
    target_type=${TARGET_TYPES[$index]}

    if [[ $target_type == 'provider cache' ]]; then
        if rm -rf -- "$target_path"; then
            log INFO "Removed $target_type: $target_path"
        else
            log ERROR "Failed to remove '$target_path'."
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    else
        if rm -f -- "$target_path"; then
            log INFO "Removed $target_type: $target_path"
        else
            log ERROR "Failed to remove '$target_path'."
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    fi
done

if (( ERROR_COUNT > 0 )); then
    log ERROR "Cleanup completed with $ERROR_COUNT error(s)."
    exit 1
fi

log INFO 'Cleanup completed successfully.'
