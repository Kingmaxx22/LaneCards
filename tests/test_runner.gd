extends SceneTree

func _initialize() -> void:
	print("test runner started")
	var checker = Checker.new()
	var s1 = TestStage1.new()
	s1.run(checker)
	var s2 = TestStage2.new()
	s2.run(checker)
	var s3 = TestStage3.new()
	s3.run(checker)
	var s4 = TestStage4.new()
	s4.run(checker)
	var s5 = TestStage5.new()
	s5.run(checker)
	var s6 = TestStage6.new()
	s6.run(checker)
	print("========================================")
	print("  TOTAL: %d passed, %d failed" % [checker.passed, checker.failed])
	print("========================================")
	print("SUITE_RESULT passed=%d failed=%d" % [checker.passed, checker.failed])
	if checker.failed == 0:
		quit(0)
	else:
		quit(1)