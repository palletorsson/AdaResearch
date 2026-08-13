## probe_set_typed.gd — does Object.set() take, and does anyone find out if it does not?
##
## THE QUESTION. tier_terrarium swept ten variants into two distinct images and the
## result was written up as a fault in the sweep's per-variant PNG write. The contact
## sheet from that run does not support that: it shows five identical `body` tiles and
## five identical `grain` tiles, so the sheet and the PNGs agree completely. What they
## agree on is that `tier` never changed.
##
## tier is declared `@export_enum("1"..."5") var tier: String`, and cabinet_sweep.py's
## coerce() turns the string "1" into a Python int before it reaches the spec — the last
## run's ada_run/sweep_spec.json holds `"tier": 1`, an int, against a String property.
##
## So the question is narrow and answerable without a camera: when GDScript is handed a
## value of the wrong type for a TYPED property, does the assignment take, and is there
## any way for a caller to know that it did not?
##
## Usage:
##   godot --headless --path . --xr-mode off \
##     --script res://commons/testing/probe_set_typed.gd
extends SceneTree

const SCENE := "res://commons/artifacts/tier_terrarium/tier_terrarium.tscn"

## Each row: what we set, and what the sweep would be doing when it set it.
const CASES: Array = [
	{"key": "tier", "value": 3, "why": "int 3 — what cabinet_sweep.coerce() actually sends"},
	{"key": "tier", "value": "3", "why": "String \"3\" — what the registry declares"},
	{"key": "channel", "value": "grain", "why": "String — the axis that DID move"},
	{"key": "tier", "value": 3.0, "why": "float 3.0 — the other numeric path in coerce()"},
]


func _initialize() -> void:
	if not ResourceLoader.exists(SCENE):
		push_error("probe_set_typed: no scene at " + SCENE)
		quit(2)
		return
	var packed: PackedScene = load(SCENE)

	print("%-9s %-22s %-12s %-12s %-8s  %s" % ["key", "sent", "before", "after", "took?", "why"])
	print("-".repeat(104))
	var silent_failures := 0
	for c in CASES:
		var inst: Node = packed.instantiate()
		var key: String = String(c["key"])
		var want: Variant = c["value"]
		var before: Variant = inst.get(key)
		# Exactly what capture_config_sweep does at line 333: set on the holder,
		# BEFORE add_child, and never look at the result.
		inst.set(key, want)
		var after: Variant = inst.get(key)
		# COMPARE THE STRING FORMS, and that is not laziness — it is forced, and the
		# reason is the finding. `after == want` raises "Invalid operands 'String' and
		# 'int' in operator '=='" and takes the probe down, because after an int is
		# assigned to a String property the property is STILL a String. GDScript will
		# not even compare the two, which is a stronger statement than any table row:
		# the value did not arrive, and the types are far enough apart that the engine
		# refuses the question. str() on both sides asks the only thing that matters —
		# did the value we sent end up in the property.
		var took: bool = str(after) == str(want)
		# The declared type of the property, which is the thing the sweep never consults.
		var decl := "?"
		for p in inst.get_property_list():
			if String(p.get("name", "")) == key:
				decl = type_string(int(p.get("type", 0)))
				break
		if not took:
			silent_failures += 1
		print("%-9s %-22s %-12s %-12s %-8s  %s" % [
			key,
			"%s (%s)" % [str(want), type_string(typeof(want))],
			str(before), str(after),
			("yes" if took else "NO"),
			"property is %s · %s" % [decl, c["why"]]])
		inst.free()

	print("-".repeat(104))
	print("%d of %d assignments were REJECTED, and every one of them returned quietly."
		% [silent_failures, CASES.size()])
	var f := FileAccess.open("res://ada_run/probe_set_typed.txt", FileAccess.WRITE)
	if f:
		f.store_string("silent_failures=%d of %d\n" % [silent_failures, CASES.size()])
		f.close()
	quit(0)
