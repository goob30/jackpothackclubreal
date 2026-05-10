#!/bin/sh
printf '\033c\033]0;%s\a' Deal with the Devil
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Deal with the Devil.x86_64" "$@"
