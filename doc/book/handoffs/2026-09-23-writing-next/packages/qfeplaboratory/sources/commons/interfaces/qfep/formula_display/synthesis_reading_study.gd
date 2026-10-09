extends Node3D
## Local reading apparatus. It changes a display, not a global simulation.
var lambda_control: Node3D
var phi_control: Node3D
var _label: Label3D
var _scope: Node
var _attempts: int = 0
var _lambda: float = 0.4
var _phi: float = 0.3
var _selected: String = "F"
var _phi_stand: Node3D
const EXPLANATIONS := {
	"F":"What is being predicted?\nWhich discrepancies count?",
	"lambda":"How much weight does variation receive?\nThe coloured scale is an authored proposal.",
	"phi":"How is change being weighted?\nFor whom is this change possible?"}

func _ready() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07,0.08,0.12)
	_box(self, Vector3(0,-1.25,0), Vector3(1.8,0.9,0.35), mat)
	_box(self, Vector3(0,-0.34,-0.04), Vector3(2.3,0.55,0.04), mat)
	_label = _tag("",Vector3(0,-0.34,-0.012),21)
	_tag("QFEP / PROJECT READING",Vector3(0,0.4,0),25)
	for i in 3:
		var button := preload("res://commons/interactables/push_button.tscn").instantiate()
		var term: String = ["F","lambda","phi"][i]
		button.name = "Read_"+term
		button.position = Vector3((i-1)*0.5,-0.70,0.10)
		add_child(button)
		button.pressed.connect(select_term.bind(term))
		_tag(["F","lambda * E","phi * change"][i],button.position+Vector3(0,0.12,0),17)
	_scope = get_parent().get_parent()
	var ancestor := _scope
	while ancestor != null:
		if ancestor.has_meta("em_map"):
			_scope = ancestor
			break
		ancestor = ancestor.get_parent()
	call_deferred("_bind_local_controls")

func _bind_local_controls() -> void:
	if not is_inside_tree() or not is_instance_valid(_scope): return
	_attempts += 1
	for node in _scope.find_children("*","Node3D",true,false):
		var script: Script = node.get_script()
		if script == null: continue
		if script.resource_path.ends_with("/lambda_slider.gd") and lambda_control == null:
			lambda_control = node
			lambda_control.lambda_changed.connect(_on_lambda)
			_on_lambda(float(lambda_control.get("lambda")))
		elif script.resource_path.ends_with("/phi_slider.gd") and phi_control == null:
			phi_control = node
			phi_control.phi_changed.connect(_on_phi)
			_on_phi(float(phi_control.get("phi")))
	if lambda_control != null and phi_control != null:
		if _phi_stand == null:
			_phi_stand = Node3D.new()
			_phi_stand.name = "SynthesisStand"
			phi_control.add_child(_phi_stand)
			var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.10,0.12,0.16)
			_box(_phi_stand,Vector3(0.25,-0.5,0),Vector3(0.7,1.0,0.30),mat)
		select_term(_selected)
	elif _attempts < 20:
		await get_tree().create_timer(0.25).timeout
		_bind_local_controls()

func _exit_tree() -> void:
	if is_instance_valid(lambda_control) and lambda_control.lambda_changed.is_connected(_on_lambda): lambda_control.lambda_changed.disconnect(_on_lambda)
	if is_instance_valid(phi_control) and phi_control.phi_changed.is_connected(_on_phi): phi_control.phi_changed.disconnect(_on_phi)
	if is_instance_valid(_phi_stand): _phi_stand.queue_free()

func _on_lambda(value: float) -> void:
	_lambda = value
	get_parent().on_lambda_changed(value)
	refresh()

func _on_phi(value: float) -> void:
	_phi = value
	get_parent().on_phi_changed(value)
	refresh()

func select_term(term: String) -> void:
	if not EXPLANATIONS.has(term): return
	_selected = term
	get_parent().highlight_term(term)
	refresh()

func refresh() -> void:
	if _label == null: return
	get_parent().highlight_term(_selected)
	get_parent().on_lambda_changed(_lambda)
	get_parent().on_phi_changed(_phi)
	_label.text = "lambda %.2f     phi %+.2f\n%s\nDisplay weights; no entropy is measured here." % [_lambda,_phi,EXPLANATIONS[_selected]]

func _tag(text: String, pos: Vector3, size: int) -> Label3D:
	var label := Label3D.new(); label.text = text; label.position = pos
	label.font_size = size; label.pixel_size = 0.0017; label.no_depth_test = false
	add_child(label); return label

func _box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> void:
	var mesh := MeshInstance3D.new(); var box := BoxMesh.new(); box.size = size
	mesh.mesh = box; mesh.material_override = mat; mesh.position = pos; parent.add_child(mesh)
