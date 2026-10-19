extends SceneTree

func _initialize() -> void:
	print("stage6 only started")
	var checker = Checker.new()
	var s6 = TestStage6.new()
	s6.run(checker)
	print("========================================")
	print("  TOTAL: %d passed, %d failed" % [checker.passed, checker.failed])
	print("========================================")
	if checker.failed == 0:
		quit(0)
	else:
		quit(1)