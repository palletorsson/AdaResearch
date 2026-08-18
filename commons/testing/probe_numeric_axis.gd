extends SceneTree
## A declared DNA axis may carry NUMBERS, and 47 of them do: noise_quarry.octaves
## [1,2,3,4], ca_bridge.rule [30,90,110,250], stock_stratum.live_props [true,false].
##
## `String(30)` has no constructor — "Invalid call. Nonexistent 'String' constructor" —
## and that is what em_sets.gd:478 hit in a live walk, inside `_str_list`, which exists
## precisely to turn an axis's values into strings. `str(30)` converts anything.
##
## This is the negative test for that repair: it FAILS on the String() version and
## passes on the str() one, so the fix cannot silently rot back in.
##
##   godot --path . --headless --xr-mode off --script res://commons/testing/probe_numeric_axis.gd

const EmSets = preload("res://commons/scenes/em/em_sets.gd")
const EmMultiples = preload("res://commons/scenes/em/em_multiples.gd")


func _initialize() -> void:
	var fails: int = 0

	# 1. The exact helper that crashed, fed every non-string type the registry holds.
	var got: Array = EmSets._str_list([1, 2.5, true, "x"])
	var want: Array = ["1", "2.5", "true", "x"]
	if got != want:
		print("FAIL  _str_list -> %s   (want %s)" % [got, want])
		fails += 1
	else:
		print("ok    _str_list over int/float/bool/string -> %s" % [got])

	# 2. The whole multiples plan over a numeric axis, declared as noise_quarry does.
	var plan: Array = EmMultiples.plan("noise_quarry", {}, 6, {"axes": {"octaves": [1, 2, 3, 4]}})
	if plan.is_empty():
		print("FAIL  plan() returned nothing for a numeric axis")
		fails += 1
	else:
		print("ok    plan() over octaves [1,2,3,4] -> %d entries" % plan.size())

	print("\n%d failure(s)" % fails)
	quit(1 if fails > 0 else 0)
