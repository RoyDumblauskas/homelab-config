#!/bin/sh
monitor=$(hyprctl monitors -j | jq -r 'first(.[] | select(.focused == false) | .name)')
hyprctl dispatch movecurrentworkspacetomonitor $monitor
