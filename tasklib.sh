#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  # This script has been executed instead of sourced
  echo "Please source this file!" >&2
  exit 1
fi

tlib_debug() {
  echo "DEBUG: $*" >> "$TLIB_LOG_FILE"
}

tlib_findin() {
  local arrayname tmp array item
  arrayname=$1
  tmp="$arrayname[@]"
  array=( "${!tmp}" )
  for item in "${array[@]}"; do
    [[ "$item" == "$2" ]] && return 0
  done
  return 1
}

tlib_initialize() {
  TLIB_TEMP_DIR="$(mktemp -dq)"
  TLIB_LOG_FILE="$TLIB_TEMP_DIR/tasklib.log"
  TLIB_DOT_FILE="$TLIB_TEMP_DIR/tasks.dot"
  echo "digraph tasks {" > "$TLIB_DOT_FILE"
  TLIB_OUTPUT_PIPE="$TLIB_TEMP_DIR/pipe"
  mkfifo "$TLIB_OUTPUT_PIPE"
  exec 10<> "$TLIB_OUTPUT_PIPE"
  rm "$TLIB_OUTPUT_PIPE"

  TLIB_TASK_ARRAY_PREFIX="tlib_task_dependency__"
  tlib_registered_tasks=()

  unset -f "tlib_initialize"

  tlib_debug "===== New Execution ($(date)) ====="
  tlib_debug "using fd 10 for log $TLIB_LOG_FILE"
}

tlib_cleanup() {
  tlib_debug "cleaning up fd 10"
  exec 10>&-
  exec 10<&-
  echo "}" >> "$TLIB_DOT_FILE"
  echo "Dot file written to $TLIB_DOT_FILE"
  echo "Debug log written to $TLIB_LOG_FILE"
}

tlib_error_exit() {
  echo "ERROR: $*" | tee -a "$TLIB_LOG_FILE" >&2

  local frame
  frame=0
  while true; do
    local trace
    trace="$(caller $frame)"
    [[ -z "$trace" ]] && break
    awk '{printf "  from %s at %s:%d\n", $2, $3, $1}' <<< "$trace" | tee -a "$TLIB_LOG_FILE" >&2
    ((frame++))
  done
  exit 1
}

tlib_task_is_defined() {
  tlib_findin "tlib_registered_tasks" "$1"
}

tlib_assert_task_is_defined() {
  while [[ "$#" -gt 0 ]]; do
    tlib_task_is_defined "$1" || tlib_error_exit "task($1) is not defined"
    shift
  done
}

tlib_get_dependency_array_name() {
  echo "$TLIB_TASK_ARRAY_PREFIX$1"
}

tlib_register_dependency() {
  local taskName arrayname tmp array
  taskName="$1"
  shift
  tlib_assert_task_is_defined "$taskName"

  arrayname="$(tlib_get_dependency_array_name "$taskName")"
  tmp="$arrayname[@]"
  array=( "${!tmp}" )

  while [[ "$#" -gt 0 ]]; do
    tlib_debug "registering depdency $taskName -> $1"
    echo -e "\\t$taskName -> $1;" >> "$TLIB_DOT_FILE"
    array+=("$1")
    shift
  done

  eval "$arrayname=(\"\${array[@]}\")"
}

tlib_get_dependencies_recursive() {
  local taskName task_list arrayname tmp array subtask list dep
  taskName="$1"
  task_list=()
  arrayname="$(tlib_get_dependency_array_name "$taskName")"
  tmp="$arrayname[@]"
  array=( "${!tmp}" )

  tlib_debug "getting dependencies for task $taskName"

  for subtask in "${array[@]}"; do
    list=( $(tlib_get_dependencies_recursive "$subtask") )
    for dep in "${list[@]}"; do
      if ! tlib_findin "task_list" "$dep"; then
        task_list+=("$dep")
      fi
    done

    if ! tlib_findin "task_list" "$subtask"; then
      task_list+=("$subtask")
    fi
  done
  echo "${task_list[@]}"
}

task() {
  local taskType taskName arrayname
  taskName="$1"
  shift
  taskType="$(type -t $taskName)"

  [[ "$taskType" != "function" ]] && tlib_error_exit "task($taskName) is not a function"
  
  if ! tlib_task_is_defined "$taskName"; then
    tlib_registered_tasks+=("$taskName")
    arrayname="$(tlib_get_dependency_array_name "$taskName")"
    eval "$arrayname=()"
    tlib_debug "Registered task $taskName"
  else
    tlib_error_exit "Task($taskName) already defined"
  fi

  tlib_register_dependency "$taskName" "$@"
}

run_task() {
  tlib_assert_task_is_defined "$1"
  local task_list task output bgPid has_errored ret

  # shellcheck disable=SC2207
  task_list=( $(tlib_get_dependencies_recursive "$1") )
  task_list+=("$1")

  tlib_debug "Run list: ${task_list[*]}"
  for task in "${task_list[@]}"; do
    tlib_assert_task_is_defined "$task"
  done

  # Read from FD 10 and write to debug log
  cat <&10 | while read -r output; do
    tlib_debug "task output: $output"
  done &
  bgPid="$!"

  has_errored=false
  for task in "${task_list[@]}"; do
    tlib_debug "processing task $task"
    if $has_errored; then
      tlib_debug "skipping task $task"
      echo -e "TASK: $task\\r\\t\\t\\t\\t\\t[SKIPPED]"
    else
      echo -ne "TASK: $task\\r\\t\\t\\t\\t\\t[RUNNING]"
      $task >&10 2>&1 < /dev/null
      ret=$?
      tput el1
      if [[ "$ret" -ne 0 ]]; then
        tlib_debug "task status $task: error"
        echo -e "\\rTASK: $task\\r\\t\\t\\t\\t\\t[ERROR]"
        has_errored=true
      else
        tlib_debug "task status $task: success"
        echo -e "\\rTASK: $task\\r\\t\\t\\t\\t\\t[DONE]"
      fi
    fi
  done

  tlib_debug "killing background task $bgPid"
  kill $bgPid
}

tlib_initialize
