extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## A compact desk for the metaball field. The generator remains the authority;
## this desk only forwards its two declared axes and keeps an earlier surface.
const EMPLACEMENTS := ["column", "ring", "pair", "shell", "scatter"]
const KERNELS := ["inverse_square", "wyvill", "gaussian", "cone"]
const PUSH_FRONT = preload("res://commons/interactables/push_button_front.tscn")
var generator
var emplacement_i := 0
var kernel_i := 0
var held_surface: MeshInstance3D
var rule_card: Label3D
var ready_for_input := false
var busy := false
var actions_taken := 0
var ids: Array = []

func _ready() -> void:
	_bind.call_deferred()

func _bind() -> void:
	var hall: Node = get_parent()
	while hall != null and not hall.has_meta("em_map"): hall = hall.get_parent()
	if hall == null: return
	var em: Node = hall
	while em != null and not "_edit_records" in em: em = em.get_parent()
	if em == null: return
	for attempt in 100:
		for rec: Dictionary in em.get("_edit_records"):
			var n = rec.get("node")
			if is_instance_valid(n) and hall.is_ancestor_of(n) and rec.get("token") == "metaball_world":
				generator = _script_node(n, "metaballgenerator.gd")
		if generator != null: break
		await get_tree().create_timer(0.1).timeout
	if generator == null: push_error("Metaball workshop needs the primary field"); return
	generator.set_process(false)
	for ui in hall.find_children("*", "CanvasLayer", true, false):
		# A monitor owns its own screen; hall HUD cleanup must not erase it.
		if ui.get_viewport() == hall.get_viewport(): ui.hide()
	ids = ["EMPLACE", "KERNEL", "HOLD", "RESET", "RULE"]
	_build_console(ids, "WHERE DOES ONE BODY BEGIN?")
	rule_card = label("The field is a sum, not a census.\nEMPLACE moves the same ten sources.\nKERNEL changes what one source contributes.\nA neck is a shared threshold, not a seam.", Vector3(0, 2.4, 0.35), 0.001)
	rule_card.visible = false
	for at in [Vector3(-3,5,-2), Vector3(3,5,-8)]:
		var light := OmniLight3D.new(); light.position = at; light.omni_range = 20; light.light_energy = 3; add_child(light)
	ready_for_input = true; refresh()

func _script_node(n: Node, ending: String):
	if n.get_script() != null and str(n.get_script().resource_path).ends_with(ending): return n
	for child in n.get_children():
		var found = _script_node(child, ending)
		if found != null: return found
	return null

func _build_console(control_ids: Array, title: String) -> void:
	var casing := material("263a44")
	box(Vector3(0,0.95,2.0), Vector3(1.12,0.12,0.44), casing, true)
	for x in [-0.42,0.42]: box(Vector3(x,0.445,2.0), Vector3(0.08,0.89,0.30), casing, true)
	for i in control_ids.size():
		var id: String = control_ids[i]; var b = PUSH_FRONT.instantiate(); var col: int = i % 3; var row: int = i / 3
		b.position = Vector3((col-1)*0.32,1.045,1.88+row*0.23); b.scale = Vector3.ONE*1.15; add_child(b); buttons[id] = b; b.pressed.connect(act.bind(id))
		var area := b.get_node_or_null("InteractableAreaButton") as Area3D
		if area != null:
			var cs := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size=Vector3(0.22,0.22,0.04); cs.shape=shape; cs.position=Vector3(0,0,0.01); area.add_child(cs)
		var caption := label(id,b.position+Vector3(0,0.01,0.09),0.00065); caption.rotation_degrees.x=-70
	box(Vector3(0,0.90,2.235), Vector3(1.12,0.15,0.025), casing); label(title,Vector3(0,0.90,2.252),0.00063)
	var panel := Node3D.new(); panel.name="TextPanel"; panel.position=Vector3(0,1.27,1.58); panel.rotation_degrees.x=-35; add_child(panel)
	var glass := MeshInstance3D.new(); var pane := QuadMesh.new(); pane.size=Vector2(1.18,0.36); glass.mesh=pane; var tint:=StandardMaterial3D.new(); tint.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; tint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; tint.cull_mode=BaseMaterial3D.CULL_DISABLED; tint.albedo_color=Color(0.12,0.25,0.30,0.14); glass.material_override=tint; glass.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; panel.add_child(glass)
	readout=label(title,Vector3.ZERO,0.0011); readout.font_size=28; readout.outline_size=7; readout.outline_modulate=Color(0.025,0.04,0.055,0.95); readout.reparent(panel,false); readout.position=Vector3(0,0,0.009)

func act(id: String) -> void:
	if not ready_for_input or busy: return
	actions_taken += 1
	if id == "RULE": rule_card.visible = not rule_card.visible; return
	busy=true
	match id:
		"EMPLACE": emplacement_i=(emplacement_i+1)%EMPLACEMENTS.size(); generator.apply_grid_config({"emplacement":EMPLACEMENTS[emplacement_i]})
		"KERNEL": kernel_i=(kernel_i+1)%KERNELS.size(); generator.apply_grid_config({"kernel":KERNELS[kernel_i]})
		"HOLD":
			if is_instance_valid(held_surface): held_surface.queue_free()
			if generator.mesh_instance != null and generator.mesh_instance.mesh is ArrayMesh:
				held_surface=MeshInstance3D.new(); held_surface.mesh=generator.mesh_instance.mesh.duplicate(true); held_surface.material_override=generator.mesh_instance.material_override; add_child(held_surface); held_surface.global_transform=generator.mesh_instance.global_transform; held_surface.global_position += global_basis*Vector3(0,0,8)
		"RESET": emplacement_i=0; kernel_i=0; generator.apply_grid_config({"emplacement":"column","kernel":"inverse_square"})
	await get_tree().process_frame; busy=false; refresh()

func refresh() -> void:
	if is_instance_valid(readout): readout.text="EMPLACEMENT %s\nKERNEL %s\nTen sources / one threshold\nHOLD keeps the earlier boundary behind the live one." % [EMPLACEMENTS[emplacement_i],KERNELS[kernel_i]]
