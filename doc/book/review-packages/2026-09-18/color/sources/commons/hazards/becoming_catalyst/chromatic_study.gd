extends Node3D
## Opt-in mounted encounter: the native chromatic projectile, without a wrist lease.
const Chromatic = preload("res://commons/hazards/becoming_catalyst/modes/mode_chromatic.gd")
var fire_button: Node3D
var readout: Label
var target: Node3D
var shots := 0
var impacts := 0
var cooldown := 0.0
var last_projectile: CatalystProjectile

func _ready() -> void:
	# This installation is a mounted instrument, not a wrist pickup.
	get_parent().enabled = false
	var panel: Node3D = load("res://commons/ui/control_panel.gd").new()
	panel.title = "ONE SHOT / WHAT CHANGES?"
	panel.position = Vector3(0,0,-0.55)
	panel.rotation_degrees.y = 180
	add_child(panel)
	fire_button = panel.add_button("FIRE COLOUR")
	readout = panel.add_readout("AIM FIXED / HUE VARIES")
	fire_button.pressed.connect(fire)
	var support := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.0,0.9,1.1)
	support.mesh = box
	support.position = Vector3(0,-0.65,-0.25)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("cdc5ba")
	support.material_override = mat
	add_child(support)
	support.create_convex_collision()
	get_parent().set_meta("em_visibility_bounds", AABB(Vector3(-0.7,-1.1,-1.0),Vector3(1.4,2,1.8)))

func _process(delta: float) -> void:
	cooldown = maxf(0.0,cooldown-delta)

func fire() -> void:
	if cooldown > 0.0: return
	# Scope to this recovered grid; a neighbouring hall can have its own target.
	if not is_instance_valid(target):
		var grid: Node = get_parent()
		while grid != null and not grid.is_in_group("grid_system"): grid = grid.get_parent()
		if grid != null:
			for n in grid.find_children("*","Node3D",true,false):
				if n.is_in_group("catalyst_target"): target=n; break
	if not is_instance_valid(target):
		readout.text = "TARGET NOT READY"
		return
	if target.get("_destroyed") == true:
		readout.text = "WAIT FOR THE RETURN"
		return
	var launch := to_global(Vector3(0,0.15,0.45))
	last_projectile = Chromatic.create_projectile(launch,(target.global_position-launch).normalized())
	get_tree().current_scene.add_child(last_projectile)
	last_projectile.global_position = launch
	last_projectile.projectile_hit.connect(func(_body: Node3D,_pos: Vector3):
		impacts += 1
		print("CHROMATIC_IMPACT ", _pos, " target ",target.global_position)
		readout.text = "SHOTS %d / IMPACTS %d" % [shots,impacts])
	shots += 1
	cooldown = Chromatic.FIRE_RATE
	readout.text = "SHOT %d / HUE %.2f" % [shots,last_projectile.color_primary.h]
