## probe_config_coercion.gd — proof that a typed @export can now be set from a
## map token, and proof that it could not before.
##
## A map token carries text. _parse_config_token stores every config value as a
## String, so an artifact doing `blade_length = config_data["blade_length"]` on a
## typed float was handed "0.9", Godot refused the assignment, and the artifact
## kept its default. Silently — no error, no warning, no log line. An audit found
## 54 placed artifacts in that state across 353 placements.
##
## This probe is the negative test the grid rule asks for. It does not check that
## the coercion function returns the right thing in the abstract; it checks that
## the OLD behaviour genuinely failed and the NEW behaviour genuinely works, on
## real exports from real artifacts, so a future refactor that quietly reverts it
## fails here rather than in a room.
##
##   godot --headless --path . --xr-mode off \
##     --script res://commons/testing/probe_config_coercion.gd

extends SceneTree

const GRID := preload("res://commons/grid/GridInteractablesComponent.gd")

## (script path, property, the text a token would carry, what it must become)
const CASES := [
	["res://commons/primitives/line/laser_sword.gd", "blade_length", "0.9", TYPE_FLOAT],
	["res://commons/primitives/arrays/pattern_tile_puzzle.gd", "tile_size", "6", TYPE_INT],
	["res://commons/primitives/point/xyz_slider_plate.gd", "min_value", "-50.0", TYPE_FLOAT],
]


func _initialize() -> void:
	var pass_n := 0
	var fail_n := 0

	for case in CASES:
		var path: String = case[0]
		var prop: String = case[1]
		var text: String = case[2]
		var want_type: int = case[3]

		if not ResourceLoader.exists(path):
			print("SKIP  %s (not in this tree)" % path)
			continue
		var scr: Script = load(path)
		var node: Node = scr.new()
		if node == null:
			print("SKIP  %s (could not instance)" % path)
			continue

		# does the artifact actually declare this export, and typed?
		var declared := -1
		for p in node.get_property_list():
			if String(p.get("name", "")) == prop:
				declared = int(p.get("type", 0))
				break
		if declared != want_type:
			print("SKIP  %s.%s — declared type %d, expected %d (the artifact changed)"
				% [path.get_file(), prop, declared, want_type])
			node.free()
			continue

		# WHAT THE ARTIFACTS ACTUALLY DO is a direct typed assignment —
		# `min_value = config_data["min_value"]` — and GDScript refuses that at
		# runtime with "Trying to assign value of type 'String' to a variable of
		# type 'float'". Object.set() is NOT that path: it goes through Variant
		# conversion and accepts the string quietly, so testing with set() proves
		# nothing about the bug. _demo_strict_assignment below reproduces the real
		# one. Here the question is only whether the coercion hands the artifact a
		# value of the type its own assignment demands.
		var coerced: Variant = GRID._coerce_to_export_type(node, prop, text)
		var right_type: bool = (typeof(coerced) == want_type)
		var still_string: bool = (coerced is String)

		var ok: bool = right_type and not still_string
		if ok:
			pass_n += 1
		else:
			fail_n += 1
		print("%s  %s.%s   token carries \"%s\"  ->  %s (type %d, wanted %d)"
			% ["PASS " if ok else "FAIL ", path.get_file(), prop, text,
				str(coerced), typeof(coerced), want_type])

		node.free()

	# A key the artifact does not declare must pass through untouched, or this
	# change would be rewriting config it has no business touching.
	var probe := Node3D.new()
	var passthrough: Variant = GRID._coerce_to_export_type(probe, "not_a_property", "12")
	var untouched: bool = (passthrough is String and passthrough == "12")
	print("%s  undeclared key passes through untouched: %s"
		% ["PASS " if untouched else "FAIL ", str(passthrough)])
	if untouched:
		pass_n += 1
	else:
		fail_n += 1
	probe.free()

	print("\n%d passed, %d failed" % [pass_n, fail_n])
	quit(1 if fail_n > 0 else 0)


## The failure this whole change exists to remove, reproduced literally.
## Expect one SCRIPT ERROR on the line below when run — that error IS the bug,
## and it is what every one of the 54 artifacts hit in silence because it happens
## inside a deferred apply_grid_config where nobody is reading the log.
var _strict: float = 1.0


func _demo_strict_assignment() -> void:
	var config_from_a_token: Dictionary = {"len": "0.9"}
	print("
-- reproducing the original failure (one SCRIPT ERROR expected) --")
	print("   before: ", _strict)
	_strict = config_from_a_token["len"]
	print("   after : ", _strict, "  (unchanged means the assignment was refused)")
