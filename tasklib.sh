#!/usr/bin/env bash

# Usage:
# Sourcing this file implicitly initializes the library
#
# Tasks:
# This library is used to order execution of 'tasks', where each task
# is a simple bash function. **Tasks must be idempotent**
# Tasks can depend on the completion of other tasks.
# Given a bash function 'bar' that needs to run after function 'foo', they
# can be registered as:
# task foo
# task bar foo
# task <function_name> <dep_0> <dep_1> ... <dep_n>
#
# Task environment:
# Tasks share the same environment as the setup script that invokes them
# Furthermore, any output to stdout or stderr is redirected to the debug log, and
# stdin is redirected from /dev/null.
#
# Running Tasks:
# A defined task can be run by using the 'run_task' function. The 'run_task'
# function will only accept a single task at a time, but can be invoked multiple
# times. Any task that returns a non-zero exit status will be marked as failed
# and all subsequent tasks will be skipped.
#
# Bash Traps:
# This library takes over the EXIT signal trap to run 'tlib_cleanup'
# You are free to override this, but in that case, it is your responsibility to
# ensure 'tlib_cleanup' is run in any possible exit condition. Zombie
# processes will be left beind if this does not happen
#
# If you would like to run a custom cleanup function, your function can be inserted
# into the array TLIB_CLEANUP_HOOKS. These functions are run in reverse order from
# within the 'tlib_cleanup' function
#
# Debug Logging:
# After this library is sourced/initialized, the 'tlib_debug' method is available
# until 'tlib_cleanup' is run. It accepts a string and writes it directly into
# the debug log
#
# Aborting:
# The tasks are run in the same process as the one that invokes 'run_task'. Any
# task can abort and cancel the remaining tasks by returning a non-zero exit code.
# In an emergency, the 'tlib_error_exit' method is available as well. This method
# will print the provided message to both the user and the debug log along with a
# stack trace, and kill the process by calling exit 1
#
# Circular Dependencies:
# Circular dependencies are not detected by this library, and will not cause an error,
# and the execution order of the tasks are not guaranteed to be correct.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  # This script has been executed instead of sourced
  echo "Please source this file!" >&2
  exit 1
fi

# Enable job control (required for background process handling in log writer)
set -m

TLIB_CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >>/dev/null && pwd)"

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

tlib_cleanup() {
  local idx taskName taskType ret
  for (( idx=${#TLIB_CLEANUP_HOOKS[@]}-1 ; idx >= 0 ; idx-- )) ; do
    taskName="${TLIB_CLEANUP_HOOKS[idx]}"
    taskType="$(type -t $taskName)"
    tlib_debug "Running cleanup task: $taskName"
    if [[ "$taskType" != "function" ]]; then
      tlib_debug "$taskName is not a function... skipping"
    else
      $taskName >&10 2>&1 < /dev/null
      ret=$?
      tlib_debug "$taskName completed with return code $ret"
    fi
  done

  # Close up the log fd at the end
  # Otherwise we cannot use tlib_debug above
  tlib_debug "cleaning up fd 10"
  exec 10<&-

  # Explicit user-facing messages here
  echo "Dot file written to $TLIB_DOT_FILE"
  echo "Debug log written to $TLIB_LOG_FILE"
}

tlib_initialize() {
  TLIB_TEMP_DIR="$(mktemp -dq)"
  TLIB_LOG_FILE="$TLIB_TEMP_DIR/tasklib.log"
  TLIB_CLEANUP_HOOKS=()

  # Set up the log pipe
  TLIB_OUTPUT_PIPE="$TLIB_TEMP_DIR/pipe"
  mkfifo "$TLIB_OUTPUT_PIPE"
  exec 10<> "$TLIB_OUTPUT_PIPE"
  rm "$TLIB_OUTPUT_PIPE"

  # Set up the cleanup hooks to run on exit
  trap tlib_cleanup EXIT

  # Initialize components and their cleanup hooks
  tlib_initialize_log_writer
  tlib_initialize_dot_file

  TLIB_TASK_ARRAY_PREFIX="tlib_task_dependency__"
  tlib_registered_tasks=()

  unset -f "tlib_initialize"

  tlib_debug "===== New Execution ($(date)) ====="
  tlib_debug "using fd 10 for log $TLIB_LOG_FILE"
}

tlib_initialize_log_writer() {
  # Read from FD 10 and write to debug log
  (cat <&10 | while read -r output; do
    tlib_debug "task output: $output"
  done) &
  TLIB_BG_PGID="$!"
  tlib_debug "Log writer initialized with pgid $TLIB_BG_PGID"

  tlib_cleanup_log_writer() {
    tlib_debug "Killing log writer pgid $TLIB_BG_PGID"
    kill -- -$TLIB_BG_PGID
  }

  TLIB_CLEANUP_HOOKS+=(tlib_cleanup_log_writer)
}

tlib_initialize_dot_file() {
  TLIB_DOT_FILE="$TLIB_TEMP_DIR/tasks.dot"
  echo "digraph tasks {" > "$TLIB_DOT_FILE"

  tlib_finalize_dot_file() {
    echo "}" >> "$TLIB_DOT_FILE"
  }

  TLIB_CLEANUP_HOOKS+=(tlib_finalize_dot_file)
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

phony() {
  local taskName taskType
  taskName="$1"
  shift
  taskType="$(type -t $taskName)"
  [[ -n "$taskType" ]] && tlib_error_exit "task($taskName) is already defined as $taskType... cannot override"
  . /dev/stdin <<EOF
$taskName() {
  :
}
EOF
  task $taskName "$@"
}

run_task() {
  tlib_assert_task_is_defined "$1"
  local task_list task output bgPid has_errored ret dirstackdepth

  # shellcheck disable=SC2207
  task_list=( $(tlib_get_dependencies_recursive "$1") )
  task_list+=("$1")

  tlib_debug "Run list: ${task_list[*]}"
  for task in "${task_list[@]}"; do
    tlib_assert_task_is_defined "$task"
  done

  has_errored=false
  for task in "${task_list[@]}"; do
    tlib_debug "processing task $task"
    if $has_errored; then
      tlib_debug "skipping task $task"
      echo -e "TASK: $task\\r\\t\\t\\t\\t\\t[SKIPPED]"
    else
      tlib_debug "Changing workdir to $TLIB_CURRENT_DIR"
      pushd "$TLIB_CURRENT_DIR" > /dev/null
      dirstackdepth="${#DIRSTACK[@]}"
      echo -ne "TASK: $task\\r\\t\\t\\t\\t\\t[RUNNING]"
      $task >&10 2>&1 < /dev/null
      ret=$?
      if [[ "${#DIRSTACK[@]}" -gt "$dirstackdepth" ]]; then
        tlib_debug "Directory stack depth mismatch: Expected $dirstackdepth, Actual ${#DIRSTACK[@]}"
      fi
      while [[ "${#DIRSTACK[@]}" -ge "$dirstackdepth" ]]; do
        popd > /dev/null
      done
      tput el1
      if [[ "$ret" -ne 0 ]]; then
        tlib_debug "task status $task: error($ret)"
        echo -e "\\rTASK: $task\\r\\t\\t\\t\\t\\t[ERROR]"
        has_errored=true
      else
        tlib_debug "task status $task: success"
        echo -e "\\rTASK: $task\\r\\t\\t\\t\\t\\t[DONE]"
      fi
    fi
  done
}

tlib_initialize
