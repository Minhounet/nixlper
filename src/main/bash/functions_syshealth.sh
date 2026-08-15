#!/usr/bin/env bash
########################################################################################################################
# FILE: functions_syshealth.sh
# DESCRIPTION: System health advisor — interprets memory/disk/CPU metrics and prints plain-English
# verdicts with suggested remediation commands. Uses only free/df/ps/uptime/nproc (falls back to
# /proc/cpuinfo for core count) — no external dependencies.
########################################################################################################################

# @cmd-palette
# @description: Show system health verdicts for memory, disk and CPU with remediation suggestions
# @category: Utilities
# @alias: health
function nixlper_health_check() {
  echo ""
  echo "──────────────────────────────────────────────────────────"
  echo "  [NIXLPER HEALTH] System health check"
  echo "──────────────────────────────────────────────────────────"
  _i_health_check_memory
  _i_health_check_disk
  _i_health_check_cpu
  echo "──────────────────────────────────────────────────────────"
  echo ""
}

#-----------------------------------------------------------------------------------------------------------------------
# Internal helpers
#-----------------------------------------------------------------------------------------------------------------------

# _i_health_level PCT: echoes OK/WARN/CRIT based on NIXLPER_HEALTH_WARN_PCT / NIXLPER_HEALTH_CRIT_PCT
function _i_health_level() {
  local -r pct="$1"
  local -r warn="${NIXLPER_HEALTH_WARN_PCT:-80}"
  local -r crit="${NIXLPER_HEALTH_CRIT_PCT:-90}"
  if (( pct >= crit )); then
    echo "CRIT"
  elif (( pct >= warn )); then
    echo "WARN"
  else
    echo "OK"
  fi
}

# _i_health_print LEVEL MESSAGE: prints a formatted verdict line
function _i_health_print() {
  local -r level="$1" message="$2"
  case "$level" in
    CRIT) printf "[CRIT] %s\n" "$message" ;;
    WARN) printf "[WARN] %s\n" "$message" ;;
    *)    printf "[OK]   %s\n" "$message" ;;
  esac
}

# _i_health_join SEP ITEM...: joins items with SEP ("${arr[*]}" with IFS only keeps SEP's first char)
function _i_health_join() {
  local -r sep="$1"; shift
  local out="" item first=true
  for item in "$@"; do
    if $first; then out="$item"; first=false; else out="${out}${sep}${item}"; fi
  done
  echo "$out"
}

# _i_health_top_mem: top N memory consumers, formatted "comm (X.Y MB, pid P)"
function _i_health_top_mem() {
  local -r top_n="${NIXLPER_HEALTH_TOP_N:-3}"
  local -a items=()
  local pid comm rss
  while read -r pid comm rss; do
    [[ -z "$pid" ]] && continue
    items+=("$(printf '%s (%.1f MB, pid %s)' "$comm" "$(awk -v r="$rss" 'BEGIN{printf "%.1f", r/1024}')" "$pid")")
  done < <(ps -eo pid,comm,rss --no-headers --sort=-rss 2>/dev/null | head -n "${top_n}")
  _i_health_join ", " "${items[@]}"
}

# _i_health_top_cpu: top N CPU consumers, formatted "comm (X%, pid P)"
function _i_health_top_cpu() {
  local -r top_n="${NIXLPER_HEALTH_TOP_N:-3}"
  local -a items=()
  local pid comm cpu
  while read -r pid comm cpu; do
    [[ -z "$pid" ]] && continue
    items+=("$(printf '%s (%s%%, pid %s)' "$comm" "$cpu" "$pid")")
  done < <(ps -eo pid,comm,%cpu --no-headers --sort=-%cpu 2>/dev/null | head -n "${top_n}")
  _i_health_join ", " "${items[@]}"
}

function _i_health_check_memory() {
  if ! command -v free &>/dev/null; then
    _i_health_print WARN "free not found — cannot assess memory usage."
    return
  fi
  local total used
  read -r total used <<< "$(free -m | awk '/^Mem:/ {print $2, $3}')"
  if [[ -z "$total" || "$total" -eq 0 ]]; then
    _i_health_print WARN "Unable to read memory usage from 'free'."
    return
  fi
  local -r pct=$(( used * 100 / total ))
  local level
  level=$(_i_health_level "$pct")
  if [[ "$level" == "OK" ]]; then
    _i_health_print "$level" "Memory at ${pct}% (${used}MB / ${total}MB)."
    return
  fi
  local top
  top=$(_i_health_top_mem)
  if [[ -n "$top" ]]; then
    _i_health_print "$level" "Memory at ${pct}% (${used}MB / ${total}MB) — top consumers: ${top} → consider: ik or kill -9 <pid>"
  else
    _i_health_print "$level" "Memory at ${pct}% (${used}MB / ${total}MB) → consider: ik or kill -9 <pid>"
  fi
}

function _i_health_check_disk() {
  if ! command -v df &>/dev/null; then
    _i_health_print WARN "df not found — cannot assess disk usage."
    return
  fi
  local parsed
  parsed=$(df -P -T 2>/dev/null | tail -n +2 | awk '{t=$7; for(i=8;i<=NF;i++) t=t" "$i; print $2, $6, t}')
  if [[ -z "$parsed" ]]; then
    # df -T unsupported (e.g. busybox df) — fall back to type-less output, skip pseudo-fs filtering
    parsed=$(df -P 2>/dev/null | tail -n +2 | awk '{t=$6; for(i=7;i<=NF;i++) t=t" "$i; print "-", $5, t}')
  fi
  if [[ -z "$parsed" ]]; then
    _i_health_print WARN "Unable to read disk usage from 'df'."
    return
  fi
  local fstype pct_raw target
  while read -r fstype pct_raw target; do
    [[ "$fstype" == "tmpfs" || "$fstype" == "devtmpfs" || "$fstype" == "squashfs" ]] && continue
    local pct="${pct_raw%\%}"
    [[ "$pct" =~ ^[0-9]+$ ]] || continue
    local level
    level=$(_i_health_level "$pct")
    if [[ "$level" == "OK" ]]; then
      _i_health_print "$level" "Disk ${target} at ${pct}%."
    else
      _i_health_print "$level" "Disk ${target} at ${pct}% → consider: du -sh ${target%/}/* 2>/dev/null | sort -rh | head"
    fi
  done <<< "$parsed"
}

function _i_health_check_cpu() {
  if ! command -v uptime &>/dev/null; then
    _i_health_print WARN "uptime not found — cannot assess CPU load."
    return
  fi
  local loadavg
  loadavg=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')
  if [[ -z "$loadavg" ]]; then
    _i_health_print WARN "Unable to read load average from 'uptime'."
    return
  fi
  local ncpu
  ncpu=$(nproc 2>/dev/null)
  if [[ -z "$ncpu" ]]; then
    ncpu=$(grep -c ^processor /proc/cpuinfo 2>/dev/null)
  fi
  [[ -z "$ncpu" || "$ncpu" -lt 1 ]] && ncpu=1
  local pct
  pct=$(awk -v l="$loadavg" -v n="$ncpu" 'BEGIN { printf "%d", (l/n)*100 }')
  local level
  level=$(_i_health_level "$pct")
  if [[ "$level" == "OK" ]]; then
    _i_health_print "$level" "CPU load ${loadavg} on ${ncpu} core(s) (${pct}%)."
    return
  fi
  local top
  top=$(_i_health_top_cpu)
  if [[ -n "$top" ]]; then
    _i_health_print "$level" "CPU load ${loadavg} on ${ncpu} core(s) (${pct}%) — top consumers: ${top} → consider: ik or renice heavy processes"
  else
    _i_health_print "$level" "CPU load ${loadavg} on ${ncpu} core(s) (${pct}%) → consider: ik or renice heavy processes"
  fi
}
