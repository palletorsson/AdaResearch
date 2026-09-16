extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var packed:=load("res://algorithms/randomness/trng_vs_prng/trng_vs_prng.tscn") as PackedScene
	var standalone:=packed.instantiate()
	root.add_child(standalone)
	var sun:=standalone.get_node("DirectionalLight3D") as DirectionalLight3D
	var demo_ok:=sun.visible and sun.shadow_enabled and sun.light_cull_mask!=0
	standalone.queue_free()
	await process_frame
	var hall:=Node3D.new();hall.set_meta("em_map","Random_Definition");root.add_child(hall)
	var installed:=packed.instantiate();hall.add_child(installed)
	sun=installed.get_node("DirectionalLight3D") as DirectionalLight3D
	var museum_ok:=not sun.visible and not sun.shadow_enabled
	print("[demo-sun] standalone=",demo_ok," museum=",museum_ok)
	quit(0 if demo_ok and museum_ok else 1)
