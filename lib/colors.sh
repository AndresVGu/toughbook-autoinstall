#!/usr/bin/env bash
# Color variables and message helpers

readonly GREEN='\033[1;32m'
readonly END='\033[0m'
readonly RED='\033[1;31m'
readonly BLUE='\033[1;34m'
readonly YELLOW='\033[1;33m'
readonly PURPLE='\033[1;35m'
readonly TURQUOISE='\033[1;36m'
readonly GRAY='\033[1;37m'
readonly DIM='\033[2m'
readonly BOLD='\033[1m'
readonly WHITE='\033[1;97m'

# Standardized message prefixes
msg_ok()   { echo -e "  ${GREEN}[+]${END} $1"; }
msg_err()  { echo -e "  ${RED}[!]${END} $1"; }
msg_warn() { echo -e "  ${YELLOW}[*]${END} $1"; }
msg_info() { echo -e "  ${TURQUOISE}[>]${END} $1"; }
msg_dim()  { echo -e "  ${DIM}$1${END}"; }
msg_time() { echo -e "  ${DIM}$1${END}"; }

# Section separator
separator() {
    echo -e "${DIM}  ──────────────────────────────────────────────────${END}"
}
