extends RefCounted
class_name Checker

var passed: int = 0
var failed: int = 0

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("  [PASS] " + message)
	else:
		failed += 1
		print("  [FAIL] " + message)

func section(title: String) -> void:
	print("\n--- " + title + " ---")