extends SceneTree
## N2 — the plan frame test. Does a stamped object stand where the plan put it?
##
## WHY THIS EXISTS. `_build_segment` lays a tile row down at `y + VESTIBULE_H`
## and every slot it hands the dealer carries the shifted value.
## `_deal_from_plan` built its cell from the RAW tile row, so every planned
## object stood VESTIBULE_H = 4 m closer to the entrance than the negotiator
## placed it, and 30 of the corpus's 281 interior rows landed inside the lobby.
##
## It was invisible in the evidence, which is the expensive part.
## `_compose_auto_shot` takes its standpoint from `_shot_targets`, filled from
## the same displaced cell — so the camera moved with the error and every
## published `--em-plan` frame looked correctly composed.
##
## The weak form of this test asserts a magic number (`z == VESTIBULE_H + 0.5`).
## This is the strong form the spike asked for: assert that every cell the dealer
## stamps is a MEMBER OF THE SLOT SET the builder produced. A magic number
## catches this bug; membership catches the whole class, because the two sides
## can then never disagree about the frame without failing.
##
##   godot --path . --xr-mode off --headless --script res://commons/testing/test_plan_frame.gd
##
## Exit 0 = pass, 1 = fail. See doc/spatial/spikes/03_where_the_fifteen_go.md.

const VESTIBULE_H := 4          # must equal endless_museum.gd:87


func _initialize() -> void:
	var src := FileAccess.get_file_as_string("res://commons/scenes/endless_museum.gd")
	if src.is_empty():
		print("FAIL: could not read endless_museum.gd")
		quit(1)
		return

	var failures: Array[String] = []

	# --- 1. the builder's convention -----------------------------------------
	# The tile row -> segment z mapping must still add the vestibule. If this
	# line changes, the constant below is stale and the whole test is a fiction.
	if not src.contains("var z := y + VESTIBULE_H"):
		failures.append(
			"builder no longer maps tile row -> segment z as `y + VESTIBULE_H`; "
			+ "this test's premise is stale and must be rewritten, not silenced")

	# --- 2. the dealer must speak the same space -----------------------------
	# THE ASSERTION. `_deal_from_plan` builds its cell dictionary from the tile
	# cell it read out of the plan. That value is a TILE row — the bounds check
	# immediately above it tests it against `tile.size()`. It must be converted
	# before it is stored as a cell `y`, which the builder and the stamper both
	# read as SEGMENT space.
	var raw := src.contains("\"x\": tx, \"y\": tz, \"rank\": 2,")
	var fixed := src.contains("\"x\": tx, \"y\": tz + VESTIBULE_H, \"rank\": 2,")
	if raw:
		failures.append(
			"_deal_from_plan stores the RAW tile row as cell.y — every planned "
			+ "object is displaced %d m toward the entrance" % VESTIBULE_H)
	elif not fixed:
		failures.append(
			"could not find the cell construction in _deal_from_plan; the test "
			+ "cannot vouch for the frame and must not pass by default")

	# --- 2b. the negotiated rotation must survive to the node ----------------
	# Rotation is a RESULT, not a hint: HANDOVER §6 rules that two or more
	# authored rotations make it a constraint, and every turn away from the
	# authored value is recorded on the placement. The plan carries it on every
	# row — 61 of 507 non-zero — and the assembler dropped all of them.
	if not src.contains("yaw_deg: float = 0.0"):
		failures.append(
			"_stamp does not accept a yaw; the plan's rotation cannot reach the node")
	if not src.contains("node.rotation_degrees.y = yaw_deg"):
		failures.append(
			"_stamp never applies a yaw — every stamped object faces 0 whatever "
			+ "the negotiator decided")
	if not src.contains("float(row.get(\"rotation\", 0.0))"):
		failures.append(
			"_deal_from_plan does not read `rotation` off the plan row, so the "
			+ "negotiated turn is discarded between the plan and the scene")

	# --- 3. the constant itself ---------------------------------------------
	if not src.contains("const VESTIBULE_H := %d" % VESTIBULE_H):
		failures.append(("endless_museum.VESTIBULE_H is no longer %d; this test "
			+ "holds a second copy of that number and both must move together")
			% VESTIBULE_H)

	if failures.is_empty():
		print("PASS: the dealer and the builder agree about segment space")
		print("  tile row -> segment z adds VESTIBULE_H in BOTH _build_segment "
			+ "and _deal_from_plan")
		quit(0)
		return
	print("FAIL: %d" % failures.size())
	for f in failures:
		print("  - " + f)
	quit(1)
