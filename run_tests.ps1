$exe = ".\Godot_v4.7.2-stable_win64_console.exe"
$p = Start-Process $exe -NoNewWindow -PassThru `
  -ArgumentList "--headless","--path",".","--script","res://tests/test_runner.gd" `
  -RedirectStandardOutput out.txt -RedirectStandardError err.txt
if (-not $p.WaitForExit(30000)) { $p.Kill(); "TIMEOUT after 30s" }
Get-Content out.txt
Get-Content err.txt
exit $p.ExitCode