#!/usr/bin/env bash

## This file has a very simple public interface
## ntlib_cleanup should be run. It is expected that this will be set up like `trap ntlib_cleanup EXIT`
## `task` is used to register a task function and its dependences
## `run_task` is used to run a single task and all associated dependencies
##
## Feel free to use `ntlib_debug` and `ntlib_error_exit`. Both simply take a message
## `ntlib_error_exit` will call exit 1 on the current process, and should not be used if the calling script was
## sourced instead of executed
##
## For `ntlib_cleanup` to run properly, this file should be sourced at the top, before the task definitions
## If you want to call ntlib_cleanup in your own custom cleanup function, define your custom cleanup function
## and any helper functions used within *before* sourcing this file. It is up to you to cleanup these custom/helper functions

NTLIB_INITIALIZED=false

# ntlib_check_initialized is defined before capturing the existing functions
# It must be explicitly cleaned up
ntlib_check_initialized() {
  if ! $NTLIB_INITIALIZED; then
    echo "ERROR: Run ntlib_initialize first!" >&2
    exit 1
  fi
}

# ntlib_debug is defined before capturing the existing functions
# It must be explicitly cleaned up
ntlib_debug() {
  ntlib_check_initialized
  echo "DEBUG: $*" >> "$NTLIB_LOG_FILE"
}

# ntlib_findin is defined before capturing the existing functions
# It must be explicitly cleaned up
ntlib_findin() {
  local arrayname tmp array task
  arrayname=$1
  # shellcheck disable=SC1087
  tmp="$arrayname[@]"
  array=( "${!tmp}" )
  for task in "${array[@]}"; do
    [[ "$task" == "$2" ]] && return 0
  done
  return 1
}

ntlib_initialize() {
  # TODO: Use mktemp
  NTLIB_TEMP_DIR="."
  NTLIB_LOG_FILE="$NTLIB_TEMP_DIR/dotfile-setup-debug.log"

  # Named pipe used to send output from tasks to the debug log
  # The FD is closed in ntlib_cleanup
  NTLIB_OUTPUT_PIPE="$NTLIB_TEMP_DIR/pipe"
  mkfifo "$NTLIB_OUTPUT_PIPE"
  exec 10<> "$NTLIB_OUTPUT_PIPE"
  rm "$NTLIB_OUTPUT_PIPE"

  # Track existing bash functions in the environment so we can clean up any that we create
  local func
  NTLIB_EXISTING_FUNCTIONS=()
  for func in $(compgen -A function); do
    NTLIB_EXISTING_FUNCTIONS+=("$func")
  done

  NTLIB_TASK_ARRAY_PREFIX="ntlib_task_dependency__"
  ntlib_registered_tasks=()

  NTLIB_INITIALIZED=true

  ntlib_debug "===== New Execution ($(date)) ====="
  ntlib_debug "using fd 10 for log $NTLIB_LOG_FILE"
}

## ----- Initialization happens here ----- ##
ntlib_initialize

ntlib_cleanup() {
  ntlib_check_initialized
  ntlib_debug "starting cleanup... the rest of this log can probably be ignored"
  local prop

  for prop in $(compgen -A function); do
    if ! ntlib_findin NTLIB_EXISTING_FUNCTIONS "$prop"; then
      ntlib_debug "cleaning up function $prop"
      unset -f "$prop"
    fi
  done

  for prop in ntlib_findin ntlib_initialize; do
    ntlib_debug "cleaning up function $prop"
    unset -f "$prop"
  done

  for prop in "${ntlib_registered_tasks[@]}"; do
    ntlib_debug "cleaning up array $NTLIB_TASK_ARRAY_PREFIX$prop"
    unset "$NTLIB_TASK_ARRAY_PREFIX$prop"
  done
  unset ntlib_registered_tasks

  ntlib_debug "cleaning up fd 10"
  exec 10>&-
  exec 10<&-

  for prop in NTLIB_EXISTING_FUNCTIONS NTLIB_TEMP_DIR NTLIB_OUTPUT_PIPE NTLIB_TASK_ARRAY_PREFIX ntlib_registered_tasks; do
    ntlib_debug "cleaning up variable $prop"
    unset "$prop"
  done

  # These two get removed together because ntlib_debug requires ntlib_check_initialized
  ntlib_debug "cleaning up function ntlib_check_initialized"
  ntlib_debug "cleaning up function ntlib_debug"
  unset -f "ntlib_debug" "ntlib_check_initialized"

  echo "Debug log written to $NTLIB_LOG_FILE"
  unset NTLIB_LOG_FILE NTLIB_INITIALIZED
}

ntlib_error_exit() {
  ntlib_check_initialized
  echo "ERROR: $*" | tee -a "$NTLIB_LOG_FILE" >&2

  local frame
  frame=0
  while true; do
    local trace
    trace="$(caller $frame)"
    [[ -z "$trace" ]] && break
    awk '{printf "  from %s at %s:%d\n", $2, $3, $1}' <<< "$trace" | tee -a "$NTLIB_LOG_FILE" >&2
    ((frame++))
  done
  exit 1
}

ntlib_task_is_defined() {
  ntlib_check_initialized
  ntlib_findin ntlib_registered_tasks "$1" || ntlib_error_exit "task($1) is not defined"
}

ntlib_register_dependency() {
  ntlib_check_initialized
  local taskName arrayname tmp array
  taskName="$1"
  shift
  ntlib_task_is_defined "$taskName"

  arrayname="$NTLIB_TASK_ARRAY_PREFIX$taskName"
  # shellcheck disable=SC1087
  tmp="$arrayname[@]"
  array=( "${!tmp}" )

  while [[ "$#" -gt 0 ]]; do
    ntlib_debug "registering dependency $taskName -> $1"
    array+=("$1")
    shift
  done

  eval "$arrayname=(\"\${array[@]}\")"
}

ntlib_get_dependencies_recursive() {
  ntlib_check_initialized
  local task_list taskName arrayname tmp array subtask list dep
  taskName="$1"
  task_list=()
  arrayname="$NTLIB_TASK_ARRAY_PREFIX$taskName"
  # shellcheck disable=SC1087
  tmp="$arrayname[@]"
  array=( "${!tmp}" )

  ntlib_debug "getting dependencies for task $1"

  for subtask in "${array[@]}"; do
    # shellcheck disable=SC2207
    list=( $(ntlib_get_dependencies_recursive "$subtask") )
    for dep in "${list[@]}"; do
      if ! ntlib_findin "task_list" "$dep"; then
        task_list+=("$dep")
      fi
    done

    if ! ntlib_findin "task_list" "$subtask"; then
      task_list+=("$subtask")
    fi
  done
  echo "${task_list[@]}"
}

# Invocation: task taskName [dependencies...]
# Register a task function and all dependencies for the task
# All stdout and stderr from this function will be redirected to a debug log
# Stdin will be redirected from /dev/null
# A non-zero exit code will cause all further tasks to be skipped
# Task invocations should be idempotent
# For each registered task, an array "$NTLIB_TASK_ARRAY_PREFIX$taskName" will be created
task() {
  ntlib_check_initialized
  local taskType taskName
  taskType=$(type -t "$1")
  taskName="$1"
  shift
  if [[ "$taskType" != "function" ]]; then
    error_exit "task($taskName) is not a function"
  fi
  if ! ntlib_findin ntlib_registered_tasks "$taskName"; then
    ntlib_registered_tasks+=("$taskName")
    eval "$NTLIB_TASK_ARRAY_PREFIX$taskName=()"
    ntlib_debug "Registered task $taskName"
  else
    ntlib_error_exit "Task($taskName) already defined"
  fi

  ntlib_register_dependency "$taskName" "$@"
}

# Invocation: run_task taskName
# Runs a single task and all associated dependencies
run_task() {
  ntlib_check_initialized
  ntlib_task_is_defined "$1"
  local task_list task output bgPid has_errored ret

  # shellcheck disable=SC2207
  task_list=( $(ntlib_get_dependencies_recursive "$1") )
  task_list+=("$1")

  ntlib_debug "Run list: ${task_list[*]}"
  for task in "${task_list[@]}"; do
    ntlib_task_is_defined "$task"
  done

  # Read from FD 10 and write to debug log
  cat <&10 | while read -r output; do
    ntlib_debug "task output: $output"
  done &
  bgPid="$!"

  has_errored=false
  for task in "${task_list[@]}"; do
    ntlib_debug "processing task $task"
    if $has_errored; then
      ntlib_debug "skipping task $task"
      echo -e "TASK: $task\\t\\t\\t[SKIPPED]"
    else
      echo -ne "TASK: $task\\t\\t\\t[RUNNING]"
      $task >&10 2>&1 < /dev/null
      ret=$?
      tput el1
      if [[ "$ret" -ne 0 ]]; then
        ntlib_debug "task status $task: error"
        echo -e "\\rTASK: $task\\t\\t\\t[ERROR]"
        has_errored=true
      else
        ntlib_debug "task status $task: success"
        echo -e "\\rTASK: $task\\t\\t\\t[DONE]"
      fi
    fi
  done

  ntlib_debug "killing background task $bgPid"
  kill $bgPid
}
