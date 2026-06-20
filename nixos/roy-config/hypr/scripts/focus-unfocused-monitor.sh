#!/bin/sh
toMonitor=$(hyprctl monitors -j | jq -r 'first(.[] | select(.focused == false) | .name)')
hyprctl dispatch "hl.dsp.focus({ monitor = '$toMonitor' })"
