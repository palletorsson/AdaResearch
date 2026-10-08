extends "res://commons/artifacts/spine_films/film_stage.gd"
## Native presentation of drawPoint() from the immutable browser study.
## The optional +1 is an erroneous value sent to a local receiver, not a
## demonstration that local and world coordinates are interchangeable.
const G = preload("res://commons/artifacts/spine_films/early/geometry.gd")
const SOURCE := "res://commons/artifacts/spine_films/foundation_source.js"
const MIN_HEIGHT := 0.0
const MAX_HEIGHT := 3.0
const STEP := 0.1
const INITIAL_HEIGHT := 1.2
const RADIUS := 16.0 / 49.0
const PINK := Color("ca628f")
var height_value := INITIAL_HEIGHT
var wrong_frame := false
var manual_mode := false
var body: MeshInstance3D
var expected: Node3D
var connection: MeshInstance3D
var ruler_link: MeshInstance3D
var requested_label: Label3D
var displayed_label: Label3D
var error_label: Label3D

func _build() -> void:
	title_text = "A value places a body"
	duration = 24.0
	phases = ["A LOCAL HEIGHT", "CHANGE THE VALUE", "AN EXTRA METRE", "RETURN TO THE RIGHT FRAME"]
	notes = ["The sphere gives a position a visible body. Only its local Y value will change.", "Height changes in 0.1 m steps. Radius, X and Z stay fixed.", "The study incorrectly adds 1 m before passing the value to the local receiver.", "Remove the extra offset. The displayed centre agrees with the requested local height."]
	source_paths = [SOURCE]
	G.box(display, Vector3(0,-.43,0), Vector3(4.4,.20,2.6), Color("294052"))
	G.line(display, Vector3(-1.8,0,0), Vector3(1.8,0,0), G.WHITE, .012)
	G.line(display, Vector3(.65,0,0), Vector3(.65,4.25,0), PINK, .022)
	G.line(display, Vector3(-.82,0,-.7), Vector3(-.82,0,.7), Color("788b99"), .009)
	for i in range(5):
		G.line(display, Vector3(.53,i,0), Vector3(.77,i,0), G.WHITE, .012)
		G.label(display, "%d m" % i, Vector3(1.05,i,0), G.WHITE, .16)
	G.label(display, "LOCAL Y", Vector3(.65,4.5,0), PINK, .16)
	body = G.sphere(display, Vector3(-.82,height_value,0), RADIUS, Color("ffffff"))
	body.name = "DisplayedBody"
	# Three dashed great circles give the expected position a visible 3D extent.
	expected = Node3D.new()
	expected.name = "ExpectedBody"
	display.add_child(expected)
	for axis in range(3):
		for i in range(24):
			if i % 3 == 2: continue
			var a := Vector3.ZERO
			var b := Vector3.ZERO
			a[(axis+1)%3] = cos(TAU*i/24.0)*RADIUS
			a[(axis+2)%3] = sin(TAU*i/24.0)*RADIUS
			b[(axis+1)%3] = cos(TAU*(i+1)/24.0)*RADIUS
			b[(axis+2)%3] = sin(TAU*(i+1)/24.0)*RADIUS
			G.line(expected,a,b,PINK,.008)
	connection = G.line(display, Vector3.ZERO, Vector3.UP, PINK, .012)
	ruler_link = G.line(display, Vector3.ZERO, Vector3.RIGHT, PINK, .012)
	requested_label = G.label(display,"",Vector3(0,-.05,1.08),G.WHITE,.20)
	displayed_label = G.label(display,"",Vector3(-1.52,1.2,.12),G.WHITE,.16)
	error_label = G.label(display,"+ 1 m",Vector3(-1.5,1.7,.12),PINK,.19)
	evidence = {"source_function":"drawPoint", "height_min":MIN_HEIGHT, "height_max":MAX_HEIGHT, "height_step":STEP, "initial_height":INITIAL_HEIGHT, "error_offset":1.0, "presentation":"Source display scale 49 px/m gives the fixed sphere radius 16/49 m. Axis and body are native 3D. No museum object is controlled."}
	frame_scene(Vector3(0,1.92,0),11.8,.22,.16)

func _draw(time: float) -> void:
	if not manual_mode:
		match phase_index(time):
			0: height_value = INITIAL_HEIGHT; wrong_frame = false
			1: height_value = snappedf(INITIAL_HEIGHT+floorf(phase_progress(time)*19.0)*STEP,STEP); wrong_frame = false
			2: height_value = INITIAL_HEIGHT; wrong_frame = true
			3: height_value = INITIAL_HEIGHT; wrong_frame = false
	var actual := displayed_height()
	body.position = Vector3(-.82,actual,0)
	expected.position = Vector3(-.82,height_value,0)
	expected.visible = wrong_frame
	G.line_pose(connection,Vector3(-.82,height_value,0),Vector3(-.82,actual,0))
	G.line_pose(ruler_link,Vector3(-.82+RADIUS,actual,0),Vector3(.52,actual,0))
	requested_label.text = "REQUEST  centre.y = %.1f m" % height_value
	displayed_label.text = "%.1f m" % actual
	displayed_label.position.y = actual
	error_label.position.y = height_value+.5
	error_label.visible = wrong_frame

func displayed_height() -> float:
	return height_value + (1.0 if wrong_frame else 0.0)

func experiment_controls() -> Array:
	return [{"key":"lower","label":"LOWER"},{"key":"raise","label":"RAISE"},{"key":"frame","label":"FRAME +1"},{"key":"reset","label":"RESET"}]

func experiment_action(key: String) -> void:
	if key not in ["lower","raise","frame","reset"]: return
	manual_mode = true
	running = false
	match key:
		"lower": height_value = snappedf(clampf(height_value-STEP,MIN_HEIGHT,MAX_HEIGHT),STEP)
		"raise": height_value = snappedf(clampf(height_value+STEP,MIN_HEIGHT,MAX_HEIGHT),STEP)
		"frame": wrong_frame = not wrong_frame
		"reset": height_value = INITIAL_HEIGHT; wrong_frame = false
	refresh()

func refresh() -> void:
	super.refresh()
	if manual_mode and _note != null:
		_note.text = "Requested local Y %.1f; displayed local Y %.1f. %s" % [height_value,displayed_height(),"The extra 1 m is a frame mistake; the dashed body is expected." if wrong_frame else "Radius and the other coordinates stay fixed."]
		_footer.text = "MANUAL / LOWER or RAISE by 0.1 m / FRAME toggles the mistake / REPLAY restores the film"

func replay() -> void:
	manual_mode = false
	height_value = INITIAL_HEIGHT
	wrong_frame = false
	super.replay()

func state_snapshot() -> Dictionary:
	return {"height":height_value,"displayed":displayed_height(),"wrong_frame":wrong_frame,"manual":manual_mode}

func experiment_snapshot() -> Dictionary:
	return {"height":height_value,"mistake":wrong_frame,"actual":displayed_height(),"manual":manual_mode}

func validation() -> Dictionary:
	var body_ok := body != null and body.position.is_equal_approx(Vector3(-.82,displayed_height(),0)) and is_equal_approx((body.mesh as SphereMesh).radius,RADIUS)
	return {"passed":height_value>=MIN_HEIGHT-.0001 and height_value<=MAX_HEIGHT+.0001 and body_ok and expected.visible==wrong_frame, "state":state_snapshot(), "evidence":evidence}
