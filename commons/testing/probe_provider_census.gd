extends SceneTree
## THE PROVIDER CENSUS: the Quest crashed in XRToolsPlayerBody.sort_by_order —
## some node stands in the movement_providers group without an `order`
## property, and the repeating error flooded the log past the line that named
## it. This census instantiates each rig-carrying scene locally, lets its
## _ready storm pass, then reads the group and writes every member down:
## name, class, script, and whether `order` exists. The nameless culprit
## gets a name.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_provider_census.gd

const OUT := "res://ada_run/provider_census.txt"
const SCENES := [
	"res://commons/scenes/base.tscn",
	"res://commons/scenes/main_menu/main_menu_level.tscn",
	"res://algorithms/alternativegeometries/mobiusstrip/scenes/mobius_world_demo.tscn",
	"res://algorithms/wavefunctions/wave_function_ride/WaveRideScene.tscn",
]

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var lines: Array = []
	var bad := 0
	for path in SCENES:
		lines.append("== " + path)
		var ps: PackedScene = load(path)
		if ps == null:
			lines.append("  LOAD FAILED")
			bad += 1
			continue
		var inst: Node = ps.instantiate()
		get_root().add_child(inst)
		await process_frame
		await process_frame
		await create_timer(1.0).timeout
		for n in get_nodes_in_group("movement_providers"):
			var sc: Script = n.get_script()
			var has_order: bool = "order" in n
			lines.append("  %s%s  class=%s  script=%s  order=%s" % [
				"" if has_order else "!! NO ORDER  ",
				String(n.get_path()).replace("/root/", ""),
				n.get_class(),
				sc.resource_path if sc != null else "NONE",
				str(n.get("order")) if has_order else "-"])
			if not has_order:
				bad += 1
		inst.free()
		await process_frame
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n\n%s" % ("CLEAN" if bad == 0 else "%d BAD" % bad))
	f.close()
	print("PROVIDER CENSUS: " + ("CLEAN" if bad == 0 else "%d BAD" % bad))
	quit(0 if bad == 0 else 1)
