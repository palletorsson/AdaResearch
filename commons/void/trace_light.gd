extends Node3D
## A view of the existing recorder: luminous tube mesh and two bounded lights.
## It never writes, snaps, resamples or archives the student's positions.
const CAPACITY := 2048
const RADIUS := 0.012
var source: Node3D
var shadow := false
var tubes: MultiMeshInstance3D
var lamps: Array[OmniLight3D] = []
var starts: Array[Vector3] = []
var ends: Array[Vector3] = []
var last_count := -1
var last_first := Vector3.INF
var last_end := Vector3.INF
var elapsed := 0.0

func _ready() -> void:
	source = get_parent()
	shadow = source.has_node("KeptTrace")
	add_to_group("void_trace_light")
	# DrawDot records world positions; the shadow point's ink is station-local.
	if not shadow:
		set_as_top_level(true)
		global_transform = Transform3D.IDENTITY
	var color: Color = Color("f5a8d5") if shadow else source.trail_color
	var finish := StandardMaterial3D.new()
	finish.albedo_color = color.lightened(0.2)
	finish.emission_enabled = true
	finish.emission = color
	finish.emission_energy_multiplier = 2.0
	finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var segment := CylinderMesh.new()
	segment.top_radius = RADIUS
	segment.bottom_radius = RADIUS
	segment.height = 1.0
	segment.radial_segments = 6
	segment.rings = 0
	segment.material = finish
	tubes = MultiMeshInstance3D.new()
	tubes.name = "LuminousTraceMesh"
	tubes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tubes.multimesh = MultiMesh.new()
	tubes.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	tubes.multimesh.mesh = segment
	tubes.multimesh.instance_count = CAPACITY
	tubes.multimesh.visible_instance_count = 0
	add_child(tubes)
	for i in range(2):
		var lamp := OmniLight3D.new()
		lamp.name = "TraceLight%d" % i
		lamp.light_color = color.lightened(0.25)
		lamp.omni_range = 3.4
		lamp.omni_attenuation = 1.25
		lamp.shadow_enabled = false
		lamp.visible = false
		add_child(lamp)
		lamps.append(lamp)
	refresh()

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed < 0.05: return
	elapsed = 0.0
	refresh()

func refresh() -> void:
	var count: int
	var first := Vector3.ZERO
	var end := Vector3.ZERO
	if shadow:
		source.ink.hide()
		count = source.ink.get_child_count()
	else:
		source._trail_instance.hide()
		count = source._trail_points.size()
		if count > 0:
			first = source._trail_points[0]
			end = source._trail_points[-1]
	if count == last_count and first == last_first and end == last_end: return
	last_count = count
	last_first = first
	last_end = end
	starts.clear()
	ends.clear()
	if shadow:
		# Every existing cylinder is a segment. Separate strokes stay separate.
		for line: MeshInstance3D in source.ink.get_children():
			var half: Vector3 = line.basis.y * (line.mesh as CylinderMesh).height * 0.5
			starts.append(line.position - half)
			ends.append(line.position + half)
	else:
		for i in range(1, count):
			starts.append(source._trail_points[i - 1])
			ends.append(source._trail_points[i])
	_render()

func _render() -> void:
	var lengths: Array[float] = []
	var total := 0.0
	var drawn := 0
	var bounds := AABB()
	for i in range(mini(starts.size(), CAPACITY)):
		var direction := ends[i] - starts[i]
		var length := direction.length()
		lengths.append(length)
		total += length
		if length < 0.00001: continue
		direction /= length
		var axis := Vector3.RIGHT if absf(direction.dot(Vector3.UP)) > 0.99 else Vector3.UP
		var side := axis.cross(direction).normalized()
		var basis := Basis(side, direction * length, side.cross(direction))
		tubes.multimesh.set_instance_transform(drawn, Transform3D(basis, (starts[i] + ends[i]) * 0.5))
		bounds = AABB(starts[i], Vector3.ZERO) if drawn == 0 else bounds.expand(starts[i])
		bounds = bounds.expand(ends[i])
		drawn += 1
	tubes.multimesh.visible_instance_count = drawn
	tubes.multimesh.custom_aabb = bounds.grow(RADIUS) if drawn > 0 else AABB()
	var active := 2 if total > 1.5 else (1 if total > 0.02 else 0)
	for i in range(lamps.size()):
		lamps[i].visible = i < active
		if i >= active: continue
		# Walk actual segment length, never the empty gap between two drawings.
		var remaining := total * (float(i) + 0.5) / float(active)
		for j in range(lengths.size()):
			if remaining <= lengths[j] and lengths[j] > 0.00001:
				lamps[i].position = starts[j].lerp(ends[j], remaining / lengths[j])
				break
			remaining -= lengths[j]
		# Fixed total energy: adding thousands of samples does not add lamps.
		lamps[i].light_energy = 2.6 / float(active)
