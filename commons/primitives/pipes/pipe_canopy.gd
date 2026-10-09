extends Node3D
## Bounded architectural application of PipeLayout and the shared hollow sweep.
## Coordinates are floor-relative. Rules are deterministic; no per-frame rebuild.
const Layout = preload("res://commons/primitives/pipes/pipe_layout.gd")
const RULES := ["RIBS", "WEAVE", "RETURNS"]
const FINISHES := ["PINK LACQUER", "PALE ENAMEL", "CHROME"]
const COUNTS := [3, 5, 7]
const RADII := [0.18, 0.30, 0.42]
const HEIGHT := 6.8
const LIFT := 0.55
const SPAN := 6.5
var rule := 1
var count_index := 1
var radius_index := 1
var finish := 0
var layout: Node3D
var generation := 0
var definition: Dictionary = {}

func _ready() -> void:
	layout = Layout.new(); layout.auto_build = false; add_child(layout)
	rebuild()

func rebuild() -> void:
	definition = make_layout(rule, COUNTS[count_index], RADII[radius_index])
	layout.load_layout_from_dict(definition)
	apply_finish()
	generation += 1

func apply_finish() -> void:
	var surface := StandardMaterial3D.new()
	surface.albedo_color = [Color("df408b"), Color("eae6db"), Color("b9c4d0")][finish]
	surface.roughness = [0.14, 0.17, 0.10][finish]
	surface.metallic = [0.28, 0.05, 0.92][finish]
	surface.clearcoat_enabled = true; surface.clearcoat = 0.8
	surface.clearcoat_roughness = 0.12
	for run in layout.pipe_systems.values():
		run.skin.material_override = surface
		# The local probe sees the room and its luminaires, not recursive pipes.
		run.skin.layers = 2

static func make_layout(mode: int, count: int, radius: float) -> Dictionary:
	count = clampi(count, 3, 7); radius = clampf(radius, 0.18, 0.42)
	var data := {"settings":{"pipe_type":"pipe","show_anchors":false}, "anchors":{}, "paths":[]}
	if mode == 0:
		# Split the trunk at the branch stations so the shared endpoints are explicit.
		var last := Vector3(0, HEIGHT, -SPAN)
		for j in count:
			var z := lerpf(-5.4, 5.4, float(j)/float(count-1))
			var joint := Vector3(0, HEIGHT, z)
			add_run(data, "trunk_%d" % j, [last, joint], radius)
			for direction in [-1.0, 1.0]:
				var points: Array = []
				for k in 33:
					var t := float(k)/32.0
					points.append(Vector3(direction*SPAN*t, HEIGHT+0.36*sin(PI*t), z+0.4*t*t))
				add_run(data, "rib_%d_%s" % [j,str(direction)], points, radius)
			last = joint
		add_run(data, "trunk_end", [last, Vector3(0,HEIGHT,SPAN)], radius)
	elif mode == 1:
		var spacing := 10.8/float(count-1)
		for j in count:
			var lane := -5.4+j*spacing
			for axis in 2:
				var points: Array = []
				for k in 97:
					var t := lerpf(-SPAN,SPAN,float(k)/96.0)
					var wave := LIFT*cos(PI*(t+5.4)/spacing+PI*j)
					points.append(Vector3(t,HEIGHT+wave,lane) if axis == 0 else Vector3(lane,HEIGHT-wave,t))
				add_run(data,"weave_%d_%d" % [axis,j],points,radius)
	else:
		var spacing := 14.0/float(count)
		var turn := spacing*0.28
		for j in count:
			var x := -7.0+spacing*(j+0.5)
			var points: Array = [Vector3(x-turn,HEIGHT,SPAN),Vector3(x-turn,HEIGHT,-4.9)]
			for k in range(1,33):
				var angle := PI+PI*float(k)/32.0
				points.append(Vector3(x+turn*cos(angle),HEIGHT,-4.9+turn*sin(angle)))
			points.append(Vector3(x+turn,HEIGHT,SPAN))
			add_run(data,"return_%d" % j,points,radius)
	return data

static func add_run(data: Dictionary, id: String, points: Array, radius: float) -> void:
	var endpoints: Array[String] = []
	for p in [points[0],points[-1]]:
		var key := "p_%.4f_%.4f_%.4f" % [p.x,p.y,p.z]
		data.anchors[key] = [p.x,p.y,p.z]; endpoints.append(key)
	var coords: Array = []
	for p in points: coords.append([p.x,p.y,p.z])
	data.paths.append({"id":id,"from":endpoints[0],"to":endpoints[1],"kind":"pipe","pipe_radius":radius,"sides":24,"points":coords})
