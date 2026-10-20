extends XRToolsPickable
## Two physical wrappers. The lesson builders still own the visible geometry.
const BoxBody := preload("res://commons/museum_runner/forms/box_body.gd")
const LineSkin := preload("res://commons/museum_runner/forms/line_skin.gd")
var form := "cube"
var desktop_held := false

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 196615

func _ready() -> void:
	var boundary := CollisionShape3D.new()
	if form == "cube":
		var mesh := BoxBody.new(Vector3.ONE * 0.44)
		var finish := StandardMaterial3D.new()
		finish.albedo_color = Color("526d72")
		finish.roughness = 0.4
		mesh.material_override = finish
		add_child(mesh)
		var shape := BoxShape3D.new()
		shape.size = Vector3.ONE * 0.44
		boundary.shape = shape
	else:
		var line := LineSkin.new()
		line.show_segment(Vector3(0, -0.36, 0), Vector3(0, 0.72, 0), 0.72)
		line.mesh.top_radius = 0.035
		line.mesh.bottom_radius = 0.035
		add_child(line)
		var shape := CylinderShape3D.new()
		shape.radius = 0.045
		shape.height = 0.72
		boundary.shape = shape
	add_child(boundary)
	super()

func is_held() -> bool: return desktop_held or is_picked_up()

func on_desktop_grab(_pointer: Node) -> void:
	desktop_held = true
	picked_up.emit(self)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_held = false
	dropped.emit(self)
