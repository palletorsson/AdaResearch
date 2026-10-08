extends "res://commons/artifacts/concept_monitor/triangle_reveal_stage.gd"
## Reuse the monitor's lit 3D stage; unfold rigid copies of the source faces.
const Polyhedron = preload("res://commons/artifacts/concept_monitor/polyhedra_reveal_record.gd")
const TIMES := [0.0, 2.5, 5.0, 8.5, 12.5, 16.0, 20.0]
const PERIOD := 23.0
var face_marks: Array[Node3D] = []
var hinges: Array[MeshInstance3D] = []

func set_record(value: Dictionary) -> bool:
	var signature: int = value.get("signature", hash(value))
	if signature == _signature: return false
	_signature = signature
	record = value.duplicate(true)
	# Presentation-only keys used by the shared face renderer.
	var labels: Array[int] = []
	for i in range(record.get("points", []).size()): labels.append(i)
	record["indices"] = labels
	record["closed"] = true
	playhead = 0.0
	rebuild()
	refresh()
	return true

func rebuild() -> void:
	face_marks.clear()
	hinges.clear()
	super()
	if faces.is_empty(): return
	geometry.basis = Polyhedron.display_basis(record)
	geometry.position.y = 2.45
	# A tetrahedron has six unique edges, not the four-edge loop of a drawing.
	for edge in boundaries:
		edge.get_parent().remove_child(edge)
		edge.queue_free()
	boundaries.clear()
	var edges := {}
	var points: PackedVector3Array = record.points
	var face_rows: Array = record.faces
	for row: Array in face_rows:
		for i in range(3):
			var a := mini(row[i], row[(i + 1) % 3])
			var b := maxi(row[i], row[(i + 1) % 3])
			edges[Vector2i(a, b)] = [a, b]
	for pair: Array in edges.values():
		boundaries.append(rod(geometry, display_position(points[pair[0]]), display_position(points[pair[1]]), 0.016, Color("a6cbd0")))
	for i in range(corner_labels.size()): corner_labels[i].text = str(i)
	for i in range(faces.size()):
		var marks := Node3D.new()
		faces[i].add_child(marks)
		face_marks.append(marks)
		for index: int in face_rows[i]:
			var dot := MeshInstance3D.new()
			var ball := SphereMesh.new()
			ball.radius = 0.047
			ball.height = 0.094
			ball.radial_segments = 12
			ball.rings = 6
			dot.mesh = ball
			dot.material_override = finish(Color("f4ecdf"))
			dot.position = display_position(points[index])
			marks.add_child(dot)
			# Shared hinge corners need one label, on the fixed base. The free
			# corner is repeated on the three flaps and meets itself on closing.
			if i != 3 and face_rows[3].has(index): continue
			var caption := Label3D.new()
			caption.text = str(index)
			caption.position = dot.position + Vector3(0, 0.12, 0)
			caption.pixel_size = 0.007
			caption.font_size = 32
			caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			caption.modulate = Color("f7e7eb")
			caption.outline_size = 5
			marks.add_child(caption)
	# Gold lines identify the fixed base edges around which the other faces turn.
	var base: Array = face_rows[3]
	for i in range(3):
		hinges.append(rod(geometry, display_position(points[base[i]]), display_position(points[base[(i + 1) % 3]]), 0.023, Color("dbb377")))

func advance(delta: float) -> void:
	if running:
		playhead = fmod(playhead + delta, PERIOD)
		refresh()

func step_sample() -> void:
	running = false
	for time in TIMES:
		if time > playhead + 0.01:
			playhead = time + 0.01
			refresh()
			return
	replay()

func refresh() -> void:
	if camera == null: return
	var phase := 0
	for i in range(TIMES.size()):
		if playhead >= TIMES[i]: phase = i
	var unfolding := 0.0
	if phase == 3: unfolding = smoothstep(8.5, 12.0, playhead)
	if phase == 4: unfolding = 1.0
	if phase == 5: unfolding = 1.0 - smoothstep(16.0, 19.5, playhead)
	var angle := camera_angle + PI / 3.0 + 0.12 * sin(playhead / PERIOD * TAU)
	camera.fov = 42
	camera.position = Vector3(sin(angle) * 11.2, 5.5 + 5.0 * unfolding, cos(angle) * 11.2)
	camera.look_at(Vector3(0, 2.40 - 0.6 * unfolding, 0))
	title.text = ["01 / FOUR POSITIONS", "02 / SIX CONNECTIONS", "03 / FOUR TRIANGULAR FACES", "04 / UNFOLD THE SURFACE", "05 / ONE NET", "06 / FOLD THE SAME FACES", "07 / AN ENCLOSURE"][phase]
	detail.text = ["Four positions, with one outside the plane of the other three.", "Each position connects to the other three.", "A face names three of the stored positions.", "Three faces turn around the edges of a fixed fourth face.", "The repeated corner numbers will meet when the surface closes.", "Each triangle keeps its shape as the angles between faces change.", "The visible mesh closes. Physics uses a separate collision shape."][phase]
	var points: PackedVector3Array = record.get("points", PackedVector3Array())
	if points.is_empty():
		title.text = "FACES / A BODY"
		detail.text = record.get("error", "Waiting for the tetrahedron in this hall.")
		if detail.text.is_empty(): detail.text = "Waiting for the tetrahedron in this hall."
	var moving := phase >= 3 and phase <= 5
	for i in range(corners.size()):
		corners[i].visible = not moving and (phase > 0 or i < maxi(1, ceili(playhead / 1.8 * corners.size())))
		corner_labels[i].visible = corners[i].visible
	for i in range(boundaries.size()):
		boundaries[i].visible = not moving and phase >= 1 and (phase > 1 or i < ceili((playhead - 2.5) / 1.8 * boundaries.size()))
	var shown := 0
	for i in range(faces.size()):
		faces[i].visible = phase > 2 or (phase == 2 and i < maxi(1, ceili((playhead - 5.0) / 2.5 * faces.size())))
		var turn: Transform3D = Polyhedron.unfold_transform(record, i, unfolding)
		# Conjugate the raw hinge transform by the display's centering and scale.
		faces[i].transform = Transform3D(turn.basis, (turn.origin + turn.basis * _centre - _centre) * _scale)
		face_marks[i].visible = moving
		if faces[i].visible: shown += 1
	for hinge in hinges: hinge.visible = moving
	counter.text = "%d positions  /  %d edges  /  %d of %d faces" % [points.size(), boundaries.size(), shown, faces.size()]
	provenance.text = "ACTUAL TETRAHEDRON MESH  /  " + str(record.get("source_name", "waiting"))
	if moving: provenance.text = "FOLDING IS A DISPLAY OPERATION  /  the museum artifact stays intact"
