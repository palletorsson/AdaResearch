extends SceneTree

## Verifies the catalyst <-> counterpart sequence binding.
##
## 1. The binding table resolves sequence -> (mode, foe_kind, friend_power)
##    and round-trips mode -> sequence.
## 2. The table's mode column stays in sync with BecomingCatalyst.MODE_DEFS
##    and its friend_power column with CatalystCapabilityManager.FRIEND_POWERS.
## 3. A CatalystVent configured with sequence:<name> seeds its brood kind
##    from the table; unbound sequences leave the brood on default; the
##    foe_mode:auto shorthand routes through the binding.
##
## All cases run synchronously so we exit before autoload polling can
## keep the SceneTree alive.

const BINDING := preload("res://commons/hazards/catalyst_sequence_binding.gd")
const VENT_SCENE := preload("res://commons/hazards/catalyst_foe/catalyst_vent.tscn")

var _fails: int = 0

func _check(label: String, ok: bool) -> void:
	print("  %s [%s]" % [label, "PASS" if ok else "FAIL"])
	if not ok:
		_fails += 1

func _initialize() -> void:
	print("=== catalyst sequence binding ===")

	# 1 — table resolution + round-trip
	_check("primitives -> mode primitives",
		BINDING.mode_for_sequence("primitives") == "primitives")
	_check("wavefunctions -> foe_kind wave",
		BINDING.foe_kind_for_sequence("wavefunctions") == "wave")
	_check("cellularautomata -> friend_power replicator",
		BINDING.friend_power_for_sequence("cellularautomata") == "replicator")
	_check("mode chromatic round-trips to color",
		BINDING.sequence_for_mode("chromatic") == "color")
	_check("unbound sequence resolves empty",
		BINDING.mode_for_sequence("catalyst_lab") == "" \
		and BINDING.foe_kind_for_sequence("catalyst_lab") == "")

	# 2 — sync with MODE_DEFS and FRIEND_POWERS
	var catalyst_script: GDScript = load("res://commons/hazards/becoming_catalyst/becoming_catalyst.gd")
	var mode_defs: Array = catalyst_script.get_script_constant_map().get("MODE_DEFS", [])
	var defs_by_seq: Dictionary = {}
	for def in mode_defs:
		var seq: String = String(def.get("sequence", ""))
		if not seq.is_empty():
			defs_by_seq[seq] = String(def.get("id", ""))
	var sync_ok: bool = true
	for seq in BINDING.BINDINGS:
		if String(defs_by_seq.get(seq, "")) != BINDING.mode_for_sequence(seq):
			print("    OUT OF SYNC with MODE_DEFS: %s" % seq)
			sync_ok = false
	_check("binding modes match MODE_DEFS (%d sequences)" % BINDING.BINDINGS.size(), sync_ok)
	_check("binding covers every MODE_DEFS sequence",
		defs_by_seq.size() == BINDING.BINDINGS.size())

	var mgr_script: GDScript = load("res://commons/managers/CatalystCapabilityManager.gd")
	var friend_powers: Dictionary = mgr_script.get_script_constant_map().get("FRIEND_POWERS", {})
	var powers_ok: bool = true
	for seq in BINDING.BINDINGS:
		var mode_id: String = BINDING.mode_for_sequence(seq)
		var expect: String = String(friend_powers.get(mode_id, {}).get("power", ""))
		if expect != BINDING.friend_power_for_sequence(seq):
			print("    OUT OF SYNC with FRIEND_POWERS: %s" % seq)
			powers_ok = false
	_check("binding powers match FRIEND_POWERS", powers_ok)

	# 3 — vent side (the counterpart resolves the same table)
	var holder := Node3D.new()
	get_root().add_child(holder)

	var vent_a: Node = VENT_SCENE.instantiate()
	holder.add_child(vent_a)
	vent_a.call("apply_grid_config", {"sequence": "fractals"})
	vent_a.call("_resolve_brood_kind")
	_check("vent sequence:fractals -> brood kind fractal",
		String(vent_a.get("default_foe_mode")) == "fractal")

	var vent_b: Node = VENT_SCENE.instantiate()
	holder.add_child(vent_b)
	vent_b.call("apply_grid_config", {"sequence": "catalyst_lab"})
	vent_b.call("_resolve_brood_kind")
	_check("vent unbound sequence -> brood stays default",
		String(vent_b.get("default_foe_mode")) == "" \
		and String(vent_b.get("bind_sequence")) == "")

	var vent_c: Node = VENT_SCENE.instantiate()
	holder.add_child(vent_c)
	vent_c.call("apply_grid_config", {"foe_mode": "auto"})
	_check("vent foe_mode:auto routes to bind_sequence auto",
		String(vent_c.get("bind_sequence")) == "auto" \
		and String(vent_c.get("default_foe_mode")) == "")

	var vent_d: Node = VENT_SCENE.instantiate()
	holder.add_child(vent_d)
	vent_d.call("apply_grid_config",
		{"sequence": "wavefunctions", "foe_mode": "transport"})
	vent_d.call("_resolve_brood_kind")
	_check("explicit foe_mode wins over sequence binding",
		String(vent_d.get("default_foe_mode")) == "transport")

	if _fails == 0:
		print("PASS: catalyst sequence binding")
		quit(0)
	else:
		print("FAIL: %d checks failed" % _fails)
		quit(1)
