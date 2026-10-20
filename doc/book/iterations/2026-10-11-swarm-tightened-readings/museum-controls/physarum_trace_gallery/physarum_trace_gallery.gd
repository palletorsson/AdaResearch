extends Node3D
## A hand writes into the existing Physarum grid. The original agent, diffusion,
## decay and anchor-carousel rules remain in the original private simulation.
const MuseumColony = preload("res://commons/artifacts/physarum_museum/physarum_museum.tscn")
const PointBody = preload("res://commons/artifacts/particle_swarm_walk/point_body.gd")
const PushButton = preload("res://commons/interactables/push_button.tscn")
const PAD := Vector3(2.5, 1.02, 1.5)
const HOME := Vector3(3.55, 1.16, 2.15)
const PAD_SIZE := 1.2
const WALL_SIZE := 6.0
const CAMERA_SPAN := 54.0 # Existing overhead camera; colony itself spans 50m.
const WRITE_INTERVAL := .05
const BRUSH_RADIUS := 3
const INK := 2.0
var source: Node3D
var point: XRToolsPickable
var wall: MeshInstance3D
var pad: MeshInstance3D
var wall_cursor: MeshInstance3D
var pad_cursor: MeshInstance3D
var status: Label3D
var buttons: Array[Node3D] = []
var drawing := false
var playing := true
var previous_cell := Vector2i(-1,-1)
var writing_accum := 0.0
var released := 0.0
var written_cells := 0
var input_mark_count := 0
var return_count := 0

func material(colour: Color, unlit := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = colour; m.roughness = .45
	if unlit: m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func box(size: Vector3, at: Vector3, colour: Color, solid := true) -> void:
	var n := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = size
	n.mesh = mesh; n.position = at; n.material_override = material(colour); add_child(n)
	if solid:
		var body := StaticBody3D.new(); body.position = at; body.collision_layer = 1; body.collision_mask = 0
		var boundary := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = size
		boundary.shape = shape; body.add_child(boundary); add_child(body)

func words(text: String, at: Vector3, size := 28) -> Label3D:
	var label := Label3D.new(); label.text = text; label.position = at; label.font_size = size
	label.pixel_size = .004; label.outline_size = 6; label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label); return label

func _ready() -> void:
	# Move the existing museum table into this court; run one colony, not copies.
	source = MuseumColony.instantiate(); add_child(source); source.position = Vector3(-2.2,0,1.5)
	source.colony._caption.hide() # Omit the internal 50m caption from the live camera view.
	process_physics_priority = 2
	var shared: Material = source.screen.material_override
	wall = MeshInstance3D.new(); var panel := QuadMesh.new(); panel.size = Vector2.ONE*WALL_SIZE
	wall.mesh = panel; wall.material_override = shared; wall.position = Vector3(0,3.65,-3.7); add_child(wall)
	box(Vector3(6.18,6.18,.12),Vector3(0,3.65,-3.79),Color("252b32"))
	pad = MeshInstance3D.new(); var plane := PlaneMesh.new(); plane.size = Vector2.ONE*PAD_SIZE
	pad.mesh = plane; pad.material_override = shared; pad.position = PAD; add_child(pad)
	box(Vector3(1.34,.08,1.34),PAD-Vector3.UP*.05,Color("252b32"))
	box(Vector3(.45,.93,.45),Vector3(PAD.x,.465,PAD.z),Color("ece8db"))
	box(Vector3(.48,.09,1.8),Vector3(3.55,.94,1.5),Color("252b32"))
	box(Vector3(.28,.90,.28),Vector3(3.55,.45,1.5),Color("ece8db"))
	point = PointBody.new(); point.name = "LeaveATrace"; add_child(point); point.position = HOME
	point.action_pressed.connect(func(_p): drawing = point.held())
	point.action_released.connect(func(_p): stop_stroke())
	pad_cursor = cursor(false); wall_cursor = cursor(true)
	add_button("PAUSE / PLAY", Vector3(3.55,1.02,1.45), toggle_play)
	add_button("RESTART", Vector3(3.55,1.02,.9), restart)
	words("A MARK LEFT BEHIND",Vector3(0,7.1,-3.7),64)
	words("One simulated colony, three views",Vector3(0,6.8,-3.7),28)
	var instructions := words("TAKE THE POINT\nHold trigger above the surface to draw\nRelease and watch",Vector3(2.5,1.75,.65),22)
	instructions.pixel_size = .0022
	words("ONE COLONY / THREE VIEWS",Vector3(-2.2,2.0,1.5),24)
	words("Original anchor layout changes every 20 simulation seconds",Vector3(0,.36,-3.65),21)
	status = words("",Vector3(3.55,1.50,.2),18)
	status.pixel_size = .0018
	update_display()

func cursor(vertical: bool) -> MeshInstance3D:
	var n := MeshInstance3D.new(); var ring := TorusMesh.new(); ring.inner_radius = .035; ring.outer_radius = .045
	n.mesh = ring; n.material_override = material(Color("78e7ec"),true)
	if vertical: n.rotation.x = PI/2; n.scale = Vector3.ONE*(WALL_SIZE/PAD_SIZE)
	n.visible = false; add_child(n); return n

func add_button(title: String, at: Vector3, action: Callable) -> void:
	var b := PushButton.instantiate(); add_child(b); b.position = at; b.rotation = Vector3.ZERO; b.scale = Vector3.ONE*1.4
	b.pressed.connect(action); buttons.append(b); words(title,at+Vector3.UP*.15,13)

func stop_stroke() -> void:
	drawing = false; previous_cell = Vector2i(-1,-1); writing_accum = 0.0

func point_uv(local_point: Vector3) -> Vector2:
	var delta := local_point - PAD
	# Height gate prevents writing while walking past or carrying the point away.
	if delta.y < .08 or delta.y > .70: return Vector2(-1,-1)
	var uv := Vector2(delta.x,delta.z)/PAD_SIZE + Vector2.ONE*.5
	var margin := (CAMERA_SPAN - 50.0)/(2.0*CAMERA_SPAN)
	if uv.x < margin or uv.y < margin or uv.x > 1-margin or uv.y > 1-margin: return Vector2(-1,-1)
	return uv

func uv_to_cell(uv: Vector2) -> Vector2i:
	var p := (uv-Vector2.ONE*.5)*CAMERA_SPAN
	return source.colony._world_to_grid(Vector3(p.x,0,p.y))

func write_brush(cell: Vector2i) -> void:
	var grid = source.colony.grid
	for y in range(-BRUSH_RADIUS,BRUSH_RADIUS+1):
		for x in range(-BRUSH_RADIUS,BRUSH_RADIUS+1):
			var p := cell+Vector2i(x,y)
			if x*x+y*y <= BRUSH_RADIUS*BRUSH_RADIUS and p.x>=0 and p.y>=0 and p.x<grid.width and p.y<grid.height:
				grid.add_slime(p.x,p.y,INK); written_cells += 1
	input_mark_count += 1

func write_to(cell: Vector2i) -> void:
	var start := cell if previous_cell.x < 0 else previous_cell
	var count := maxi(absi(cell.x-start.x),absi(cell.y-start.y))
	# At most 256 dabs; leaving the surface terminates the stroke instead of clamping.
	for i in range(1,maxi(count,1)+1):
		write_brush(Vector2i(Vector2(start).lerp(Vector2(cell),float(i)/maxi(count,1)).round()))
	previous_cell = cell
	# Required even while the colony is paused: the hand is an explicit new writer.
	source.colony.p_image = source.colony.grid.get_image()
	source.colony.p_texture.update(source.colony.p_image)

func _physics_process(dt: float) -> void:
	if point.held(): released = 0
	else:
		stop_stroke(); released += dt
		if released > 3 and (point.position.distance_to(HOME)>.001 or not point.rotation.is_zero_approx()):
			point.position = HOME; point.rotation = Vector3.ZERO; return_count += 1
	var uv := point_uv(to_local(point.global_position)) if point.held() else Vector2(-1,-1)
	var valid := uv.x >= 0
	pad_cursor.visible = valid; wall_cursor.visible = valid
	if valid:
		pad_cursor.position = PAD+Vector3((uv.x-.5)*PAD_SIZE,.012,(uv.y-.5)*PAD_SIZE)
		wall_cursor.position = Vector3((uv.x-.5)*WALL_SIZE,3.65+(.5-uv.y)*WALL_SIZE,-3.68)
	if drawing and valid:
		writing_accum += dt
		if writing_accum >= WRITE_INTERVAL:
			writing_accum = fmod(writing_accum,WRITE_INTERVAL)
			write_to(uv_to_cell(uv))
	else:
		previous_cell = Vector2i(-1,-1); writing_accum = 0
	update_display()

func toggle_play() -> void:
	playing = not playing
	source.colony.process_mode = Node.PROCESS_MODE_INHERIT if playing else Node.PROCESS_MODE_DISABLED
	update_display()

func restart() -> void:
	# Defer rebuilding from a button's physics callback.
	rebuild.call_deferred()

func rebuild() -> void:
	stop_stroke(); source.colony._rebuild_now(); written_cells=0; input_mark_count=0
	source.colony._caption.hide()
	update_display()

func update_display() -> void:
	if status == null: return
	status.text = ("RUNNING" if playing else "PAUSED / drawing still works")+"\n%d brush marks / %s anchors" % [input_mark_count,source.colony.CAROUSEL[source.colony.dist_mode]]
	buttons[0].set_selected(not playing)

func get_museum_occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	# Reserve physical furniture only; leave the approach and viewing aisle open.
	for rect in [Rect2(-3.7,.0,3.0,3.0),Rect2(1.8,.8,1.4,1.4),Rect2(3.25,.5,.65,1.95),Rect2(-3.2,-3.9,6.4,.3)]:
		for x in range(ceili(rect.size.x*4)+1):
			for z in range(ceili(rect.size.y*4)+1):
				var at := to_global(Vector3(rect.position.x+x*.25,0,rect.position.y+z*.25))
				var cell := Vector2i(floori(at.x),floori(at.z))
				if not cells.has(cell): cells.append(cell)
	return cells
