#!/bin/sh
toMonitor=$(hyprctl monitors -j | jq -r 'first(.[] | select(.focused == false) | .name)')
hyprctl dispatch "hl.dsp.workspace.move({ monitor = '$toMonitor' })"
