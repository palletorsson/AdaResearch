# schrodinger_box.gd
# Schrödinger's cat thought experiment visualization
# The box holds superposition until observed

extends Node3D

class_name SchrodingerBox

# @identity
# essence: |ψ⟩ = α|alive⟩ + β|dead⟩ → observation collapses to |alive⟩ or |dead⟩ with P = |α|²
# desire: open the box and watch the superposition collapse — the lid swings, the state resolves, then resets
# critical_parameter: auto_reset_time — how long the collapsed state persists before returning to superposition
# triggers: click/observe collapses the wavefunction randomly; timer resets to superposition; lid animates open/close
# emerges: the discomfort of genuine indeterminacy — the cat is not secretly alive or dead, it is both
# needs: VR click interaction [has via mouse], XR interaction [missing]
# relationships: contrasts florensky_sphere (quantum vs paraconsistent superposition); paired with superposition_display (abstract vs physical metaphor)
# truth: observation does not reveal a pre-existing state — it creates one

signal box_opened
signal state_collapsed(is_alive: bool)
signal superposition_entered

enum State { SUPERPOSITION, ALIVE, DEAD }

@export var box_size: Vector3 = Vector3(0.4, 0.3, 0.3)
@export var current_state: State = State.SUPERPOSITION
@export var auto_reset_time: float = 5.0

var _xr_active: bool = false
var _box_mesh: MeshInstance3D
var _lid_mesh: MeshInstance3D
var _cat_alive: MeshInstance3D
var _cat_dead: MeshInstance3D
var _superposition_glow: MeshInstance3D
var _label: Label3D
var _state_label: Label3D
var _lid_open: bool = false
var _reset_timer: float = 0.0

func _ready():
	_xr_active = XRServer.primary_interface != null
	_create_box()
	_create_lid()
	_create_cat_states()
	_create_superposition_effect()
	_create_labels()
	_update_display()

func _create_box():
	_box_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = box_size
	_box_mesh.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.25, 0.2)
	mat.metallic = 0.1
	mat.roughness = 0.8
	_box_mesh.material_override = mat
	add_child(_box_mesh)

func _create_lid():
	_lid_mesh = MeshInstance3D.new()
	var lid = BoxMesh.new()
	lid.size = Vector3(box_size.x * 1.05, 0.02, box_size.z * 1.05)
	_lid_mesh.mesh = lid
	_lid_mesh.position.y = box_size.y / 2 + 0.01
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.3, 0.25)
	mat.metallic = 0.2
	mat.roughness = 0.7
	_lid_mesh.material_override = mat
	add_child(_lid_mesh)

func _create_cat_states():
	# Alive cat (happy sphere)
	_cat_alive = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.08
	sphere.height = 0.16
	_cat_alive.mesh = sphere
	_cat_alive.position = Vector3(0, 0, 0)
	_cat_alive.visible = false
	
	var alive_mat = StandardMaterial3D.new()
	alive_mat.albedo_color = Color(0.3, 0.8, 0.3)
	alive_mat.emission_enabled = true
	alive_mat.emission = Color(0.2, 0.6, 0.2)
	alive_mat.emission_energy_multiplier = 0.5
	_cat_alive.material_override = alive_mat
	add_child(_cat_alive)
	
	# Dead cat (flat shape)
	_cat_dead = MeshInstance3D.new()
	var dead_box = BoxMesh.new()
	dead_box.size = Vector3(0.15, 0.03, 0.1)
	_cat_dead.mesh = dead_box
	_cat_dead.position = Vector3(0, -box_size.y / 2 + 0.025, 0)
	_cat_dead.visible = false
	
	var dead_mat = StandardMaterial3D.new()
	dead_mat.albedo_color = Color(0.4, 0.4, 0.4)
	_cat_dead.material_override = dead_mat
	add_child(_cat_dead)

func _create_superposition_effect():
	_superposition_glow = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	_superposition_glow.mesh = sphere
	_superposition_glow.position = Vector3(0, 0, 0)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.3, 0.8, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.2, 0.7)
	mat.emission_energy_multiplier = 0.8
	_superposition_glow.material_override = mat
	add_child(_superposition_glow)

func _create_labels():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 14
	_label.text = "SCHRÖDINGER'S BOX\nClick to observe"
	_label.position = Vector3(0, -box_size.y / 2 - 0.1, 0)
	add_child(_label)
	
	_state_label = Label3D.new()
	_state_label.pixel_size = 0.001
	_state_label.font_size = 16
	_state_label.position = Vector3(0, box_size.y / 2 + 0.1, 0)
	add_child(_state_label)

func _update_display():
	match current_state:
		State.SUPERPOSITION:
			_cat_alive.visible = false
			_cat_dead.visible = false
			_superposition_glow.visible = true
			_state_label.text = "|ψ⟩ = α|alive⟩ + β|dead⟩"
			_state_label.modulate = Color(0.7, 0.5, 1.0)
		State.ALIVE:
			_cat_alive.visible = true
			_cat_dead.visible = false
			_superposition_glow.visible = false
			_state_label.text = "COLLAPSED: |alive⟩"
			_state_label.modulate = Color(0.3, 1.0, 0.3)
		State.DEAD:
			_cat_alive.visible = false
			_cat_dead.visible = true
			_superposition_glow.visible = false
			_state_label.text = "COLLAPSED: |dead⟩"
			_state_label.modulate = Color(0.8, 0.3, 0.3)

func _process(delta):
	# Animate superposition
	if current_state == State.SUPERPOSITION:
		var t = Time.get_ticks_msec() / 1000.0
		var mat = _superposition_glow.material_override as StandardMaterial3D
		mat.albedo_color.a = 0.3 + 0.3 * sin(t * 3.0)
		mat.emission_energy_multiplier = 0.5 + 0.3 * sin(t * 2.0)
	
	# Auto reset after collapse
	if current_state != State.SUPERPOSITION and auto_reset_time > 0:
		_reset_timer += delta
		if _reset_timer >= auto_reset_time:
			reset_to_superposition()

func observe():
	if current_state == State.SUPERPOSITION:
		# Collapse the wavefunction
		var is_alive = randf() > 0.5
		current_state = State.ALIVE if is_alive else State.DEAD
		_reset_timer = 0.0
		
		# Open lid
		var tween = create_tween()
		tween.tween_property(_lid_mesh, "rotation_degrees:x", -110, 0.5)
		_lid_open = true
		
		_update_display()
		box_opened.emit()
		state_collapsed.emit(is_alive)

func reset_to_superposition():
	current_state = State.SUPERPOSITION
	_reset_timer = 0.0
	
	# Close lid
	if _lid_open:
		var tween = create_tween()
		tween.tween_property(_lid_mesh, "rotation_degrees:x", 0, 0.5)
		_lid_open = false
	
	_update_display()
	superposition_entered.emit()

func _input(event):
	if _xr_active:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if current_state == State.SUPERPOSITION:
				observe()
			else:
				reset_to_superposition()

func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
