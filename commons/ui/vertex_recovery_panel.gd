extends Node3D
## A small reset station beside a directly manipulated object. Local +Z faces the visitor.
## The owner supplies reset_shape() and any_handle_held(); the grips remain the main interface.
const Baked = preload("res://commons/utils/baked_text_albedo.gd")
const Case = preload("res://commons/ui/instrument_panel_case.gd")
var subject: Node3D
var button: Node3D
var status: Node3D
var support: MeshInstance3D
var _mount: Transform3D
var _last_wording := ""
var _elapsed := 0.0

func _ready() -> void:
	subject = get_parent()
	_mount = transform
	set_as_top_level(true) # Do not let a console determine the specimen's plinth seating.
	var casing := Case.new()
	add_child(casing)
	casing.fit_rect(Vector2(0,-.075),Vector2(.39,.42),Color(.9,.62,.26))
	button = load("res://commons/interactables/push_button.tscn").instantiate()
	button.name = "ResetButton"
	button.position = Vector3(0,-.17,.003)
	button.released_color = Color(.86,.72,.39)
	button.released_emission_energy = .04
	button.pressed.connect(_reset)
	add_child(button)
	var caption := Baked.make_label_mesh("RESET SHAPE",Color.WHITE,Vector2(.30,.032),2400,true)
	caption.name = "ResetCaption"
	caption.position = Vector3(0,-.247,.005)
	add_child(caption)
	support = MeshInstance3D.new()
	support.name = "UprightSupport"
	support.set_as_top_level(true)
	support.mesh = BoxMesh.new()
	support.material_override = StandardMaterial3D.new()
	support.material_override.albedo_color = Color(.14,.16,.18)
	add_child(support)
	refresh()

func _reset() -> void:
	subject.reset_shape() # Owner also guards against a reset while a handle is held.
	refresh()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= .1:
		_elapsed = 0
		refresh()

func refresh() -> void:
	var basis := subject.global_basis.orthonormalized()
	global_transform = Transform3D(basis*_mount.basis,subject.global_position+basis*_mount.origin)
	var hall: Node = subject
	while hall != null and not hall.has_meta("em_map"): hall = hall.get_parent()
	var floor_y: float = hall.global_position.y if hall is Node3D else subject.global_position.y-.705
	var height := maxf(.10,global_position.y-floor_y-.22)
	var front := global_basis.z
	front.y = 0
	front = front.normalized()
	support.global_transform = Transform3D(Basis.IDENTITY,Vector3(global_position.x,floor_y+height*.5,global_position.z)-front*.07)
	support.mesh.size = Vector3(.06,height,.06)
	var held: bool = subject.any_handle_held()
	var wording := "MOVE A CORNER\nThen try another." if not held else "LET GO FIRST\nThen reset the shape."
	if wording == _last_wording: return
	_last_wording = wording
	if status:
		remove_child(status)
		status.queue_free()
	status = Node3D.new()
	status.name = "Status"
	status.set_meta("text",wording)
	add_child(status)
	var lines := wording.split("\n")
	for i in lines.size():
		var line := Baked.make_label_mesh(lines[i],Color(.95,.94,.88),Vector2(.33,.04),2400,true)
		line.position = Vector3(0,.082-float(i)*.052,.005)
		status.add_child(line)
	button.play_press_sound = not held
	button.released_color = Color(.19,.20,.21) if held else Color(.86,.72,.39)
	button.pressed_color = button.released_color if held else Color(1,.85,.4)
	button.update_colors()
