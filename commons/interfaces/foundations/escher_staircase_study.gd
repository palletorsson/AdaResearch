extends Node3D
## Reachable controls for the existing staircase model. Advances a marker, never
## the visitor or camera. Readouts measure the displayed tread centres in metres.
const FORMS := ["none", "hairline", "gap", "scaffold", "field"]
const NAMES := ["RETURN SIDE", "CLOSING DROP", "OPEN RUN", "SCAFFOLD", "TILTED TREADS"]
var model: Node3D
var screen: Label3D
var last_delta := 0.0
var ascent := 0.0
var descent := 0.0
var _start_y := 0.0
var _last_index := 0

func setup(host: Node3D) -> void:
	model = host
	name = "StudyControls"
	var console = preload("res://commons/ui/interface_presets.gd").build("workbench", "FOLLOW THE STEP", 0.95)
	console.position = Vector3(0, 0.95, 0.65)
	add_child(console)
	# Side readout leaves the low treads visible from the controls.
	var card := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.82, 0.23, 0.025)
	card.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.035,0.045,0.06)
	card.material_override = mat
	card.position = Vector3(-0.97,1.25,0.40)
	add_child(card)
	screen = Label3D.new()
	screen.name = "MeasuredSteps"
	screen.font_size = 24
	screen.pixel_size = 0.0008
	screen.position = card.position + Vector3(0,0,0.02)
	screen.outline_size = 2
	add_child(screen)
	var actions: Array[Callable] = [advance.bind(-1),advance.bind(1),next_form,restart]
	for i in 4:
		var button := preload("res://commons/interactables/push_button.tscn").instantiate()
		button.name = ["BACK","STEP","FORM","RESET"][i]
		button.position = Vector3((i-1.5)*0.24,1.00,0.9)
		add_child(button)
		button.pressed.connect(actions[i])
		var label := Label3D.new()
		label.text = button.name
		label.font_size = 20
		label.pixel_size = 0.001
		label.position = button.position + Vector3(0,0.09,0)
		add_child(label)
	model.step_taken.connect(_on_step)
	model.paradox_completed.connect(_refresh)
	reset_measurements()

func reset_measurements() -> void:
	last_delta=0.0
	ascent=0.0
	descent=0.0
	_last_index = int(model._current_step)
	_start_y = _height(_last_index)
	_refresh()

func _height(index: int) -> float:
	return model._steps[index].global_position.y

func _on_step(index: int, _direction: String) -> void:
	last_delta = _height(index)-_height(_last_index)
	ascent += maxf(last_delta,0.0)
	descent += maxf(-last_delta,0.0)
	_last_index = index
	_refresh()

func advance(direction: int) -> void:
	if direction > 0: model.climb_step()
	else: model.descend_step()
	_refresh()

func next_form() -> void:
	var index := (FORMS.find(model.seam)+1)%FORMS.size()
	model.apply_grid_config({"seam":FORMS[index]})

func restart() -> void:
	model.reset()
	reset_measurements()

func _refresh() -> void:
	if screen==null or model._steps.is_empty(): return
	var end := ""
	if model._ring_is_open() and model._open_run_declared and model._current_step in [0,model._steps.size()-1]: end=" | CUT END"
	elif model._steps_climbed>0 and model._current_step==0: end=" | AT START"
	var idx: int=maxi(0,FORMS.find(model.seam))
	screen.text = "%s | %d/%d%s\nCentre change %+.2f m | from start %+.2f m\nUp %.2f m | down %.2f m" % [NAMES[idx],model._current_step+1,model._steps.size(),end,last_delta,_height(model._current_step)-_start_y,ascent,descent]
