extends Node3D
## Graduations belong to the measured segment, not to a fixed board.
var ticks: MultiMeshInstance3D
var labels: Array[Label3D] = []
var tick_count := 0
var tick_step := 0.1
var _last := ""

func _ready() -> void:
	ticks = MultiMeshInstance3D.new()
	ticks.name = "Graduations"
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = BoxMesh.new()
	(multi.mesh as BoxMesh).size = Vector3.ONE
	multi.instance_count = 128
	multi.visible_instance_count = 0
	ticks.multimesh = multi
	var ink := StandardMaterial3D.new()
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.albedo_color = Color("a4f7ee")
	ticks.material_override = ink
	add_child(ticks)
	for i in range(7):
		var label := Label3D.new()
		label.name = "Measure%d" % i
		label.font_size = 24
		label.pixel_size = .0014
		label.modulate = Color("dcfff6")
		label.outline_size = 4
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)
		labels.append(label)

func update_measure(a: Vector3, b: Vector3, represented_metres: float) -> void:
	var key := str(a) + str(b) + str(snappedf(represented_metres,.0001))
	if key == _last: return
	_last = key
	for label in labels: label.hide()
	var span := a.distance_to(b)
	if span < .001 or represented_metres < .001:
		ticks.multimesh.visible_instance_count = 0
		tick_count = 0
		return
	var axis := (b-a)/span
	var side := axis.cross(Vector3.UP)
	if side.length_squared() < .01: side = axis.cross(Vector3.RIGHT)
	side = side.normalized()
	var basis := Basis(axis, side, axis.cross(side))
	# Legible 1/2/5 decimal intervals, bounded even when an end is far away.
	var decade := pow(10.0, floor(log(represented_metres/40.0)/log(10.0)))
	tick_step = decade
	for multiplier in [1.0,2.0,5.0,10.0]:
		tick_step = decade*multiplier
		if represented_metres/tick_step <= 60.0: break
	var count := int(floor(represented_metres/tick_step))
	tick_count = 0
	for i in range(count+1):
		var centre := a.lerp(b,float(i)*tick_step/represented_metres)
		var length := .10 if i%5==0 else .045
		ticks.multimesh.set_instance_transform(tick_count,Transform3D(basis.scaled_local(Vector3(.004,length,.004)),centre+side*length*.5))
		tick_count += 1
	for offset in [-.026,.026]:
		ticks.multimesh.set_instance_transform(tick_count,Transform3D(basis.scaled_local(Vector3(span,.004,.004)),(a+b)*.5+side*offset))
		tick_count += 1
	ticks.multimesh.visible_instance_count = tick_count
	var major := maxi(1,int(ceil(float(count)/5.0)))
	var label_index := 0
	for i in range(0,count+1,major):
		if label_index >= labels.size()-1: break
		var label := labels[label_index]
		label.text = "%.2f" % (float(i)*tick_step)
		label.position = a.lerp(b,float(i)*tick_step/represented_metres)+side*.16
		label.show()
		label_index += 1
	var end_label := labels[6]
	end_label.text = "%.2f m" % represented_metres
	end_label.position = b-side*.15
	end_label.show()
