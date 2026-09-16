extends Node3D
## Opt-in museum furnishing: the exhibit keeps its own scale and callbacks.
## A glass boundary marks the simulation; a separate console fits the visitor.
var config: Dictionary = {}
var host: Node3D

static func install(artifact: Node3D, cfg: Dictionary) -> void:
	if not cfg.has("glass_width") and str(cfg.get("controls", "")) != "compact": return
	if artifact.has_node("ExhibitStage"): return
	var stage: Node3D = load("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd").new()
	stage.name = "ExhibitStage"
	stage.set_meta("em_exhibit_stage", true)
	stage.config = cfg.duplicate()
	artifact.add_child(stage)

func _ready() -> void:
	host = get_parent()
	# Artifact builders can defer their last panel until after _ready.
	await get_tree().process_frame
	await get_tree().process_frame
	if config.has("glass_width"):
		glass_box(self, float(config.glass_width), float(config.get("glass_depth", config.glass_width)), float(config.get("glass_height", 4.0)), str(config.get("glass_title", "SIMULATION")), str(config.get("glass_grid", "true")) != "false", float(config.get("glass_entry", 2.2)))
	if str(config.get("controls", "")) == "compact": _compact_controls()
	if str(config.get("glass_moat", "false")) == "true": _moat_rails()

func _moat_rails() -> void:
	# Source map cuts the moat. These rails never fill it with a hidden collider.
	# As in Transformation: flush apron, gap, gallery; two open end bridges.
	var w: float = float(config.glass_width)+3.0
	var d: float = float(config.get("glass_depth",config.glass_width))+3.0
	var color := Color(0.36,0.7,0.76,0.15)
	for x in [-w/2.0,w/2.0]:
		box(self,Vector3(x,0.6,0),Vector3(0.05,1.2,d),color,true)
	for z in [-d/2.0,d/2.0]:
		for side in [-1.0,1.0]:
			box(self,Vector3(side*(w/4.0+0.5),0.6,z),Vector3(w/2.0-1.0,1.2,0.05),color,true)

static func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.55
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid: bool = false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new(); shape.size = size
	mesh.mesh = shape; mesh.material_override = material(color); mesh.position = pos
	parent.add_child(mesh)
	if solid:
		var body := StaticBody3D.new(); mesh.add_child(body)
		var col := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = size
		col.shape = bs; body.add_child(col)
	return mesh

static func label(parent: Node3D, text: String, pos: Vector3, yaw: float = 0.0) -> Label3D:
	var l := Label3D.new(); l.text = text; l.font_size = 36; l.pixel_size = 0.003
	l.position = pos; l.rotation.y = yaw; l.outline_size = 4
	parent.add_child(l); return l

static func glass_box(parent: Node3D, width: float, depth: float, height: float, title: String, draw_grid: bool = true, entry_width: float = 2.2) -> void:
	var frame := Node3D.new(); frame.name = "GlassSimulation"; parent.add_child(frame)
	frame.set_meta("entry_width", entry_width)
	var glass := Color(0.38, 0.76, 0.83, 0.085)
	var steel := Color(0.12, 0.19, 0.24)
	var trim := Color(0.97, 0.59, 0.27)
	# Side panes and split end panes leave two real, 2.2 m doorways.
	for x in [-width/2.0, width/2.0]:
		box(frame, Vector3(x,height/2.0,0),Vector3(0.045,height,depth),glass,true)
		for y in [0.04,height]: box(frame,Vector3(x,y,0),Vector3(0.09,0.09,depth),steel)
	for z in [-depth/2.0, depth/2.0]:
		var pane: float = (width-entry_width)/2.0
		for side in [-1.0,1.0]:
			box(frame,Vector3(side*(entry_width/2.0+pane/2.0),height/2.0,z),Vector3(pane,height,0.045),glass,true)
			for x in [side*width/2.0,side*entry_width/2.0]: box(frame,Vector3(x,height/2.0,z),Vector3(0.09,height,0.09),steel)
		box(frame,Vector3(0,height,z),Vector3(width,0.09,0.09),steel)
		box(frame,Vector3(0,0.018,z),Vector3(entry_width,0.025,0.35),trim)
		label(frame,title,Vector3(0,height-0.35,z),PI if z < 0 else 0.0)
	# The one-metre grid is ink, not an invisible floor over a pit.
	for x in range(-int(width/2.0)+1,int(width/2.0)):
		if draw_grid: box(frame,Vector3(x,0.012,0),Vector3(0.012,0.006,depth-0.1),Color(0.5,0.7,0.72))
	for z in range(-int(depth/2.0)+1,int(depth/2.0)):
		if draw_grid: box(frame,Vector3(0,0.012,z),Vector3(width-0.1,0.006,0.012),Color(0.5,0.7,0.72))
	# Glass ceiling makes the volume legible; no collision overhead or in the doors.
	box(frame,Vector3(0,height,0),Vector3(width,0.025,depth),Color(0.6,0.84,0.9,0.025))

func _compact_controls() -> void:
	var panels: Array[Node3D] = []
	for node in host.find_children("*", "Node3D", true, false):
		if node.has_meta("panel_w") and node.has_meta("panel_h"):
			panels.append(node)
	if panels.is_empty(): return
	var console := Node3D.new(); console.name = "ReachConsole"; add_child(console)
	var front: float = float(config.get("control_front", 1.0))
	var hand_height: float = float(config.get("control_height", 1.10))
	console.position = Vector3(0,hand_height,front)
	console.rotation.y = PI if str(config.get("control_facing", "+z")) == "-z" else 0.0
	# Fit actual panel widths into 80 cm. Keep original buttons and signal wiring.
	var total: float = 0.0
	for p in panels: total += float(p.get_meta("panel_w"))
	var factor: float = minf(2.2, (0.80-0.025*(panels.size()-1))/maxf(total,0.01))
	var cursor: float = -(total*factor+0.025*(panels.size()-1))/2.0
	var max_h: float = 0.0
	for p in panels:
		var w: float = float(p.get_meta("panel_w"))*factor
		var h: float = float(p.get_meta("panel_h"))*factor
		max_h = maxf(max_h,h)
		p.reparent(console, false)
		p.scale = Vector3.ONE*factor
		p.position = Vector3(cursor+w/2.0,0,0.015)
		p.rotation_degrees = Vector3(-25,0,0)
		cursor += w+0.025
	var casing := box(console,Vector3(0,0,-0.025),Vector3(0.86,max_h+0.055,0.07),Color(0.13,0.2,0.23))
	casing.rotation_degrees.x = -25
	box(console,Vector3(0,-0.60,-0.08),Vector3(0.09,0.97,0.09),Color(0.16,0.2,0.22))
	var mark := Marker3D.new(); mark.name = "StandingPosition"
	var standing_floor: float = float(config.get("control_floor",0.0))
	mark.position = Vector3(0,standing_floor-hand_height,0.57); console.add_child(mark)
	box(console,Vector3(0,standing_floor-hand_height+0.015,0.57),Vector3(0.6,0.018,0.12),Color(0.96,0.67,0.3))
	console.set_meta("panel_count",panels.size())
	console.set_meta("control_width",total*factor+0.025*(panels.size()-1))
	# A cycling cube moves its root. Its operating place must stay on the bank.
	if str(config.get("control_fixed", "false")) == "true":
		var anchored: Transform3D = console.global_transform
		console.top_level = true
		console.global_transform = anchored
