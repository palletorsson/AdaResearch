extends SceneTree
## Exercise the real deferred diptych/panel rebuild without a full tower load.
const Diptych := preload("res://commons/primitives/hand_telemetry_diptych/hand_telemetry_diptych.tscn")
const Hardware := preload("res://commons/void/trace_interface_hardware.gd")
class Building extends Node3D:
	var spec := {"levels":[0,-6],"slab_thickness":.3}
class Host extends Node3D:
	var building: Node3D
var checks: Array = []
func _initialize() -> void: run.call_deferred()
func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	print("TRACE_CHECK ",label," ",passed)
func frames(n: int) -> void:
	for i in n: await physics_frame
func inspect(source: Node3D,label: String) -> bool:
	var complete := true
	for side in ["left","right"]:
		var panel := source.get_node_or_null("Panel_"+side)
		var ok: bool = panel != null and panel.has_node("Bezel") and panel.has_node("Screen")
		check(label+" / stable "+side+" panel and screen",ok)
		if not ok:
			print("CHILDREN ",source.get_children().map(func(c):return str(c.name)))
			complete=false
		else:
			check(label+" / correct hand "+side,panel.hand==side)
			check(label+" / original viewport retained "+side,is_instance_valid(panel._viewport) and panel._screen_mesh.material_override.albedo_texture==panel._viewport.get_texture())
	return complete
func run() -> void:
	var building := Building.new();root.add_child(building)
	var host := Host.new();host.building=building;building.add_child(host)
	var floor := Node3D.new();floor.set_meta("void_content_floor",1);floor.position.y=-6;host.add_child(floor)
	var source: Node3D = Diptych.instantiate();floor.add_child(source)
	source.apply_grid_config({"panel_width":1.2,"panel_height":1.6})
	await frames(5)
	var ready := inspect(source,"initial deferred config")
	if ready:
		Hardware.attach_later(source,"hand_telemetry_diptych")
		await frames(5)
		check("hardware has complete support and supply",source.has_node("ArchitecturalHardware/StructuralSupport") and source.has_node("ArchitecturalHardware/HardwareSupply"))
		Hardware.attach(source,"hand_telemetry_diptych")
		check("reattach does not duplicate hardware",source.get_children().filter(func(c):return c.name=="ArchitecturalHardware").size()==1)
		for i in 3:source.apply_grid_config({"panel_width":1.3+i*.1,"panel_height":1.7})
		await frames(5)
		if inspect(source,"repeated same-frame config"):
			Hardware.attach_later(source,"hand_telemetry_diptych");await frames(5)
			check("hardware returns after edited rebuild",source.has_node("ArchitecturalHardware/HardwareSupply"))
		var partial := Node3D.new();floor.add_child(partial)
		Hardware.attach(partial,"hand_telemetry_diptych")
		check("unready source does not leave a partial mount",not partial.has_node("ArchitecturalHardware"))
		partial.free()
		var retired: Node3D = Diptych.instantiate();floor.add_child(retired)
		Hardware.attach_later(retired,"hand_telemetry_diptych")
		retired.queue_free();await frames(5)
		check("source unloaded during delayed attach",not is_instance_valid(retired))
	var passed := checks.all(func(c):return c.passed)
	var out := "res://ada_run/trace-hardware-rebuild.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	FileAccess.open(out,FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks},"  "))
	print("TRACE_HARDWARE_RESULT ",JSON.stringify({"passed":passed,"checks":checks}))
	quit(0 if passed else 1)
