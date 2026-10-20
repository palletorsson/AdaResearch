extends Node3D
## A hand-operated geometric loom. No texture represents the fabric.
## A draft cell means warp above/below weft. Committed picks retain that decision.
## Yarn paths are prescribed geometry, not a friction/tension or knot simulation.
const Shuttle = preload("res://commons/artifacts/thread_loom/shuttle.gd")
const BUTTON = preload("res://commons/interactables/push_button.tscn")
const THREADS := 12
const WIDTH := 0.90
const PITCH := 0.032
const RADIUS := 0.006
const CROSSING := 0.014
const CLOTH_Y := 0.97
const FELL_Z := 0.80
const SHED_Y := 1.06
const SHED_Z := 0.60
const EDGE := 0.56
const MAX_PICKS := 24
signal cloth_changed(picks: int)

var draft: Array = []
var picks: Array = []
var pending: Array = []
var armed := false
var last_x := 0.0
var progress_x := 0.0
var auto_time := -1.0
var feedback := "Take the shuttle from the lit side."
var shuttle: XRToolsPickable
var yarn_root: Node3D
var warp_paths: Array[PackedVector3Array] = []
var weft_path := PackedVector3Array()
var heddles: Array[Node3D] = []
var cell_lights: Array[MeshInstance3D] = []
var state_label: Label3D
var reed: Node3D
var reed_time := 0.0
var preview: MeshInstance3D
var materials: Dictionary = {}
var starting_light: MeshInstance3D

func _ready() -> void:
	materials.wood = material(Color("483b34"), 0.78)
	materials.metal = material(Color("b99c6a"), 0.32, 0.55)
	materials.warp = material(Color("f4e7cb"), 0.85)
	materials.weft = material(Color("c04d7d"), 0.8)
	materials.dark = material(Color("202d30"), 0.72)
	materials.lit = material(Color("67cdb7"), 0.5)
	set_draft("plain")
	_build()
	# A short woven beginning is explicit; every later pick comes from a pass.
	for i in range(4): picks.append(draft[i % 4].duplicate())
	refresh()
	dock_shuttle()

func material(color: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color; m.roughness = rough; m.metallic = metal
	return m

func box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, solid: bool = false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new(); shape.size = size
	mesh.mesh = shape; mesh.material_override = mat; mesh.position = pos
	parent.add_child(mesh)
	if solid:
		var body := StaticBody3D.new(); body.collision_layer = 1
		var col := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = size
		col.shape = bs; body.add_child(col); mesh.add_child(body)
	return mesh

func label(text: String, pos: Vector3, size: int = 27) -> Label3D:
	var n := Label3D.new(); n.text = text; n.position = pos
	n.font_size = size; n.pixel_size = 0.0012; n.outline_size = 3
	n.modulate = Color("f4e7cb"); add_child(n)
	return n

func button(text: String, pos: Vector3, callback: Callable) -> void:
	var n := BUTTON.instantiate() as Node3D
	n.name = text.replace(" ", "_") if not text.is_empty() else "DraftCell"
	n.position = pos
	n.scale = Vector3.ONE * 0.75; add_child(n)
	n.get_node("InteractableAreaButton").button_pressed.connect(func(_b): callback.call())
	label(text, pos + Vector3(0, -0.053, 0.015), 17)

func _build() -> void:
	box(self, Vector3(0, .045, .22), Vector3(2.6,.09,2.05), materials.dark, true)
	for x in [-.71, .71]:
		for z in [-.69, .90]:
			box(self, Vector3(x,.50,z), Vector3(.09,1,.09), materials.wood,true)
		box(self, Vector3(x,1.0,.10),Vector3(.09,.08,1.7),materials.wood,true)
		box(self, Vector3(x,1.37,-.64),Vector3(.085,.80,.09),materials.wood,true)
	box(self,Vector3(0,1.78,-.64),Vector3(1.54,.10,.12),materials.wood,true)
	for z in [-.64,.91]: box(self,Vector3(0,.97,z),Vector3(1.45,.075,.085),materials.metal,true)
	label("FOLLOW THE THREAD",Vector3(0,1.91,-.63),39)
	label("Lift the warp. Pass the shuttle. Beat the weft.",Vector3(0,1.67,-.55),22)
	label("4 woven passes to begin  /  12 warp threads",Vector3(0,.73,1.04),20)
	yarn_root = Node3D.new(); yarn_root.name = "InterlacedYarn"; add_child(yarn_root)
	for x in range(THREADS):
		var eye := box(self,Vector3(warp_x(x),1.2,.30),Vector3(.016,.22,.018),materials.metal)
		heddles.append(eye)
	reed = Node3D.new(); reed.position = Vector3(0,1.0,.38); add_child(reed)
	box(reed,Vector3.ZERO,Vector3(1.19,.045,.035),materials.wood)
	for x in range(THREADS+1):
		box(reed,Vector3(-.49+float(x)*.082,-.055,0),Vector3(.006,.12,.006),materials.metal)
	preview = MeshInstance3D.new(); preview.material_override = materials.weft; add_child(preview)
	box(self,Vector3(-1.05,1.18,.32),Vector3(.56,.79,.06),materials.dark)
	label("LIFT DRAFT",Vector3(-1.05,1.63,.36),26)
	label("lit = warp over",Vector3(-1.05,1.55,.37),17)
	for row in range(4):
		for col in range(4):
			var p := Vector3(-1.23+col*.12,1.45-row*.12,.38)
			button("",p, toggle_cell.bind(row,col))
			cell_lights.append(box(self,p+Vector3(0,0,.052),Vector3(.045,.045,.012),materials.dark))
	button("PLAIN",Vector3(-1.18,.85,.42),set_draft.bind("plain"))
	button("TWILL",Vector3(-.93,.85,.42),set_draft.bind("twill"))
	box(self,Vector3(.97,.91,.42),Vector3(.51,.50,.04),materials.dark)
	button("BEAT",Vector3(.85,1.0,.46),beat)
	button("UNDO",Vector3(1.09,1.0,.46),undo_pick)
	button("PASS",Vector3(.85,.82,.49),start_pass)
	button("RESET",Vector3(1.09,.82,.49),reset_cloth)
	label("PASS: guided shuttle",Vector3(.98,.65,.55),15)
	label("Trigger on shuttle: beat",Vector3(.97,1.12,.44),15)
	state_label = label("",Vector3(0,1.50,-.54),21)
	starting_light = box(self,Vector3(-EDGE,.975,SHED_Z),Vector3(.10,.025,.11),materials.lit)
	shuttle = Shuttle.new(); shuttle.name = "Shuttle"; shuttle.loom = self; add_child(shuttle)
	var work_light := OmniLight3D.new(); work_light.position = Vector3(0,1.65,.65)
	work_light.light_color = Color("ffe8c7"); work_light.light_energy = .8
	work_light.omni_range = 2.5; work_light.shadow_enabled = false; add_child(work_light)

func warp_x(col: int) -> float:
	return -WIDTH*.5 + float(col)*WIDTH/float(THREADS-1)

func start_side() -> float:
	return -1.0 if picks.size()%2 == 0 else 1.0

func current_row() -> Array:
	return draft[picks.size()%4].duplicate()

func set_draft(kind: String) -> void:
	if armed or not pending.is_empty() or auto_time >= 0.0: return
	draft.clear()
	for row in range(4):
		var values: Array = []
		for col in range(4): values.append(int((col+row)%2==0) if kind=="plain" else int(posmod(col-row,4)<2))
		draft.append(values)
	if is_instance_valid(yarn_root): refresh()

func toggle_cell(row: int, col: int) -> void:
	if armed or not pending.is_empty() or auto_time >= 0.0: return
	draft[row][col] = 1-int(draft[row][col]); refresh()

func release_shuttle() -> void:
	if armed:
		armed = false; feedback = "Pass paused: return to the lit side."
	if is_instance_valid(preview) and pending.is_empty(): preview.mesh = null
	update_label()

func sample_shuttle(p: Vector3) -> void:
	if not pending.is_empty() or picks.size()>=MAX_PICKS: return
	# Only a complete path through the shed counts. A jump or a path above it cannot weave.
	if absf(p.y-SHED_Y)>.025 or absf(p.z-SHED_Z)>.035:
		if armed: release_shuttle()
		return
	if not armed:
		if absf(p.x-start_side()*EDGE)<.08:
			armed = true; last_x = p.x; progress_x = p.x
		return
	if absf(p.x-last_x)>.24:
		release_shuttle(); feedback = "Stay in the opening and move the shuttle through."; update_label(); return
	last_x = p.x; progress_x = clampf(p.x,-EDGE,EDGE)
	preview.mesh = tube(PackedVector3Array([Vector3(start_side()*EDGE,SHED_Y,SHED_Z),Vector3(progress_x,SHED_Y,SHED_Z)]))
	if p.x*(-start_side())>=EDGE-.025:
		pending = current_row(); armed = false
		feedback = "Weft through. Pull it into place with BEAT / trigger."
		update_label()

func beat() -> bool:
	if pending.is_empty():
		feedback = "Pass the shuttle through the opening first."; update_label(); return false
	picks.append(pending.duplicate()); pending.clear(); preview.mesh = null
	reed_time = .35; feedback = "Pass kept. The next row is ready."
	refresh(); cloth_changed.emit(picks.size())
	if not shuttle.held(): dock_shuttle()
	return true

func undo_pick() -> void:
	if armed or auto_time>=0.0: return
	if not pending.is_empty(): pending.clear(); preview.mesh = null
	elif not picks.is_empty(): picks.pop_back()
	feedback = "Last pass removed; earlier crossings stay."; refresh()
	if not shuttle.held(): dock_shuttle()

func reset_cloth() -> void:
	if shuttle.held(): return
	picks.clear(); pending.clear(); armed = false; auto_time = -1.0
	preview.mesh = null; feedback = "Empty warp. Weave the first pass."; refresh(); dock_shuttle()

func dock_shuttle() -> void:
	if shuttle.held(): return
	shuttle.position = Vector3(start_side()*EDGE,SHED_Y,SHED_Z)
	shuttle.linear_velocity = Vector3.ZERO; shuttle.angular_velocity = Vector3.ZERO
	shuttle.force_update_transform()

func start_pass() -> void:
	if shuttle.held() or armed or not pending.is_empty() or picks.size()>=MAX_PICKS: return
	auto_time = 0.0; dock_shuttle()
	sample_shuttle(shuttle.position)

func _process(delta: float) -> void:
	if auto_time>=0.0:
		if shuttle.held(): auto_time = -1.0; release_shuttle()
		else:
			auto_time = minf(1.2,auto_time+delta)
			shuttle.position = Vector3(lerpf(start_side()*EDGE,-start_side()*EDGE,auto_time/1.2),SHED_Y,SHED_Z)
			sample_shuttle(shuttle.position)
			if auto_time>=1.2: auto_time = -1.0
	if reed_time>0:
		reed_time = maxf(0,reed_time-delta)
		reed.position.z = .38+sin((.35-reed_time)/.35*PI)*.37
	else: reed.position.z = .38

func cloth_position(x: float, lift: float, distance: float) -> Vector3:
	# Prescribed take-up around the front beam; no implicit cloth dynamics.
	if distance <= .11: return Vector3(x,CLOTH_Y+lift,FELL_Z+distance)
	return Vector3(x,CLOTH_Y-(distance-.11),.91+lift)

func refresh() -> void:
	for child in yarn_root.get_children(): child.free()
	warp_paths.clear(); weft_path.clear()
	var next: Array = current_row()
	for col in range(THREADS):
		var x := warp_x(col)
		var shed := 1.48 if int(next[col%4])==1 else .84
		heddles[col].position.y = shed
		var path := PackedVector3Array([Vector3(x,CLOTH_Y,-.64),Vector3(x,shed,.30),Vector3(x,CLOTH_Y,FELL_Z-.025)])
		for row in range(picks.size()-1,-1,-1):
			var distance := float(picks.size()-1-row)*PITCH
			path.append(cloth_position(x,CROSSING*(1 if int(picks[row][col%4])==1 else -1),distance))
		path.append(Vector3(x,.16,.91))
		warp_paths.append(path); add_yarn(path,materials.warp)
	# One continuous weft snakes back at the selvedges. Each committed row holds its draft.
	for row in range(picks.size()):
		var distance := float(picks.size()-1-row)*PITCH
		var direction := 1.0 if row%2==0 else -1.0
		weft_path.append(cloth_position(-direction*.50,0,distance))
		for step in range(THREADS):
			var col := step if row%2==0 else THREADS-1-step
			var lift := -CROSSING*(1 if int(picks[row][col%4])==1 else -1)
			weft_path.append(cloth_position(warp_x(col),lift,distance))
		weft_path.append(cloth_position(direction*.50,0,distance))
	if weft_path.size()>1: add_yarn(weft_path,materials.weft)
	for row in range(4):
		for col in range(4): cell_lights[row*4+col].material_override = materials.lit if int(draft[row][col])==1 else materials.dark
	starting_light.position.x = start_side()*EDGE
	update_label()

func update_label() -> void:
	if not is_instance_valid(state_label): return
	state_label.text = "%d / %d passes  ·  draft row %d\n%s" % [picks.size(),MAX_PICKS,picks.size()%4+1,feedback if picks.size()<MAX_PICKS else "Sample complete. UNDO a pass or RESET to weave again."]

func add_yarn(path: PackedVector3Array, mat: Material) -> void:
	var n := MeshInstance3D.new(); n.mesh = tube(path); n.material_override = mat; yarn_root.add_child(n)

func tube(path: PackedVector3Array) -> ArrayMesh:
	# Explicit tube vertices keep the yarn inspectable from below as well as above.
	var vertices := PackedVector3Array(); var normals := PackedVector3Array(); var indices := PackedInt32Array()
	if path.size()<2 or path[0].is_equal_approx(path[path.size()-1]): return ArrayMesh.new()
	for i in range(path.size()):
		var tangent := path[mini(i+1,path.size()-1)]-path[maxi(0,i-1)]
		if tangent.length_squared()<0.0000001: tangent = Vector3.RIGHT
		tangent = tangent.normalized()
		var axis := Vector3.UP if absf(tangent.dot(Vector3.UP))<.95 else Vector3.RIGHT
		var u := tangent.cross(axis).normalized(); var v := tangent.cross(u).normalized()
		for side in range(8):
			var angle := TAU*float(side)/8.0
			var normal := u*cos(angle)+v*sin(angle)
			vertices.append(path[i]+normal*RADIUS); normals.append(normal)
	for i in range(path.size()-1):
		var base := i*8
		for side in range(8):
			var a := base+side; var b := base+(side+1)%8
			indices.append_array([a,a+8,b,b,a+8,b+8])
	var mesh := ArrayMesh.new()
	if not vertices.is_empty():
		var arrays: Array = []; arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices; arrays[Mesh.ARRAY_NORMAL] = normals; arrays[Mesh.ARRAY_INDEX] = indices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh
