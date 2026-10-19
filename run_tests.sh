#!/bin/bash
cd "$(dirname "$0")"
timeout 30 ./Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_runner.gd 2>&1
exit $?