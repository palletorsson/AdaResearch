extends SceneTree
func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    if args.is_empty(): push_error("Supply an assertion script path"); quit(1); return
    var script = load(args[0])
    if script==null: quit(1); return
    var suite = script.new()
    suite.run()
    var passed: bool = not suite.checks.is_empty()
    for result in suite.checks: passed = passed and result.passed
    print("PASS" if passed else "FAIL", " / ",args[0]," / ",suite.checks.size()," assertions")
    quit(0 if passed else 1)
