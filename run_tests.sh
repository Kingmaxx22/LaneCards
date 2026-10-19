#!/bin/bash
cd "$(dirname "$0")"
timeout 30 ./Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_runner.gd 2>&1
EXIT=$?
if grep -q "SUITE_RESULT passed=[0-9]* failed=0" <(timeout 30 ./Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/test_runner.gd 2>&1); then
  echo "TESTS PASSED"
  if [ $EXIT -ne 0 ]; then
    echo "WARNING: exit code was $EXIT but suite result was PASS"
  fi
  exit 0
else
  echo "TESTS FAILED or NO RESULT (exit code: $EXIT)"
  exit 1
fi