extends Node3D
## A finite, seeded dismantling of architecture. Stones change place; none disappear.
## It is a staged erosion rule, not a thermodynamic or structural-engineering solver.
const Stage = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const SEED: int = 79
const INTERVAL: float = 0.65
var rng := RandomNumberGenerator.new()
var pieces: Array[Dictionary] = []
var stacks: Array = []
var history: Array[int] = []
var running: bool = true
var clock: float = -5.0
var readout: Label3D
var stone_materials: Array[StandardMaterial3D] = []
var brick_materials: Array[StandardMaterial3D] = []

func _ready() -> void:
	for i in range(7):
		var stone := Stage.material(Color(0.64,0.59,0.48).lerp(Color(0.9,0.85,0.71),float(i)/6.0))
		stone.roughness = 1.0; stone_materials.append(stone)
		var brick := Stage.material(Color(0.36,0.24,0.17).lerp(Color(0.67,0.48,0.31),float(i)/6.0))
		brick.roughness = 1.0; brick_materials.append(brick)
	# Shallow archaeological bed contains the fallen stones. The museum floor stays intact.
	Stage.box(self,Vector3(0,0.04,0),Vector3(6.2,0.08,2.8),Color(0.39,0.35,0.27),true)
	for x in [-3.05,3.05]:
		Stage.box(self,Vector3(x,0.11,0),Vector3(0.1,0.22,2.8),Color(0.62,0.58,0.48),true)
	# Twelve masonry stacks behind the colonnade. Removing top courses exposes a jagged wall.
	for col in range(12):
		var stack: Array[int] = []
		for row in range(6):
			var size := Vector3(0.45,0.255,0.34)
			var pos := Vector3(-2.65+col*0.48,0.08+0.14+row*0.275,0.7)
			stack.append(_piece(_block(size),pos,brick_materials[(col*3+row)%7],size))
		stacks.append(stack)
	# Four classical columns: separate fluted drums, echinus and square abacus.
	for c in range(4):
		var x: float = -2.4+c*1.6
		Stage.box(self,Vector3(x,0.18,-0.1),Vector3(0.8,0.2,0.8),Color(0.66,0.62,0.52),true)
		var stack: Array[int] = []
		for row in range(8):
			var radius: float = 0.285-row*0.007
			stack.append(_piece(_drum(radius,0.31,c*11+row),Vector3(x,0.445+row*0.325,-0.1),stone_materials[(row+c)%7],Vector3(radius*2,0.31,radius*2)))
		var echinus := CylinderMesh.new()
		echinus.top_radius = 0.37; echinus.bottom_radius = 0.24; echinus.height=0.16; echinus.radial_segments=24
		stack.append(_piece(echinus,Vector3(x,2.97,-0.1),stone_materials[5],Vector3(0.74,0.16,0.74)))
		stack.append(_piece(_block(Vector3(0.8,0.16,0.8)),Vector3(x,3.14,-0.1),stone_materials[4],Vector3(0.8,0.16,0.8)))
		# A lintel section belongs to its supporting column and falls first.
		stack.append(_piece(_block(Vector3(1.55,0.3,0.65)),Vector3(x,3.38,-0.1),stone_materials[3],Vector3(1.55,0.3,0.65)))
		stacks.append(stack)
	var panel := Rack.create_panel("WHAT STILL HOLDS?",[[{"type":"button","label":"RUN / PAUSE"},{"type":"button","label":"ONE STONE"},{"type":"button","label":"RESTORE"}]])
	panel.position=Vector3(0,1.1,-2.0); panel.rotation.y=PI; add_child(panel)
	panel.find_child("Btn_0",true,false).pressed.connect(func(): running=not running; _readout())
	panel.find_child("Btn_1",true,false).pressed.connect(func(): running=false; weather_one())
	panel.find_child("Btn_2",true,false).pressed.connect(restore)
	readout=Stage.label(self,"",Vector3(0,1.6,-1.9),PI)
	readout.font_size=24; readout.pixel_size=0.0015
	Stage.box(self,Vector3(0,1.6,-1.87),Vector3(1.5,0.24,0.035),Color(0.07,0.1,0.12))
	rng.seed=SEED
	_readout()

func _block(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new(); mesh.size=size; return mesh

func _drum(radius: float, height: float, salt: int) -> ArrayMesh:
	# Alternating radii cut shallow flutes into the real silhouette, with small chips.
	var mesh := SurfaceTool.new(); mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(48):
		var j: int=(i+1)%48
		var ra: float=radius*(0.91 if i%2 else 1.0)
		var rb: float=radius*(0.91 if j%2 else 1.0)
		if (i+salt)%17==0: ra*=0.94
		if (j+salt)%17==0: rb*=0.94
		var a:=Vector3(cos(i*TAU/48)*ra,-height/2,sin(i*TAU/48)*ra)
		var b:=Vector3(cos(j*TAU/48)*rb,-height/2,sin(j*TAU/48)*rb)
		var at:=a+Vector3.UP*height; var bt:=b+Vector3.UP*height
		for v in [a,at,b,b,at,bt,Vector3(0,height/2,0),bt,at,Vector3(0,-height/2,0),a,b]: mesh.add_vertex(v)
	mesh.generate_normals(); return mesh.commit()

func _piece(mesh: Mesh, pos: Vector3, mat: Material, size: Vector3) -> int:
	var item:=MeshInstance3D.new(); item.mesh=mesh; item.material_override=mat; item.position=pos; add_child(item)
	var body:=StaticBody3D.new(); item.add_child(body)
	var collision:=CollisionShape3D.new(); var shape:=BoxShape3D.new(); shape.size=size; collision.shape=shape; body.add_child(collision)
	pieces.append({"node":item,"home":item.transform,"body":body,"size":size,"fallen":false,"age":-1.0,"target":Vector3.ZERO,"turn":Vector3.ZERO})
	return pieces.size()-1

func _process(delta: float) -> void:
	# A paused exhibit freezes both selection and descent.
	if not running: return
	_animate(delta)
	clock+=minf(delta,0.1)
	if clock>=INTERVAL:
		clock=0.0; weather_one()

func _animate(delta: float) -> void:
	for piece in pieces:
		if piece.age<0: continue
		piece.age+=minf(delta,0.1)
		var t: float=clampf(piece.age/0.85,0.0,1.0)
		var from: Transform3D=piece.home
		# Accelerating descent with a lateral tumble; curated landing slots bound the rubble.
		var pos: Vector3=from.origin.lerp(piece.target,t)
		pos.y=lerpf(from.origin.y,piece.target.y,t*t)
		piece.node.position=pos
		piece.node.rotation=piece.turn*t
		if t>=1.0:
			piece.age=-1.0
			piece.body.collision_layer=1

func weather_one() -> void:
	# Only exposed top pieces may go. The bottom two courses/drums remain as stumps.
	var eligible: Array[int]=[]
	for i in range(stacks.size()):
		if stacks[i].size()>2: eligible.append(i)
	if eligible.is_empty():
		# Let the last selected stone finish its descent before stopping automatically.
		var settling: bool=false
		for stone in pieces:
			if stone.age>=0: settling=true
		running=running and settling
		_readout(); return
	var chosen: int=eligible[rng.randi_range(0,eligible.size()-1)]
	var id: int=stacks[chosen].pop_back()
	var piece: Dictionary=pieces[id]
	piece.fallen=true; piece.age=0.0; piece.body.collision_layer=0
	# Slots and layer number make bounded piles; each actual stone is retained.
	var n: int=history.size()
	piece.turn=Vector3(rng.randf_range(-0.8,0.8),rng.randf_range(-PI,PI),rng.randf_range(-0.8,0.8))
	var basis:=Basis.from_euler(piece.turn)
	var size: Vector3=piece.size
	var extent: Vector3=(abs(basis.x)*size.x+abs(basis.y)*size.y+abs(basis.z)*size.z)*0.5
	piece.target=Vector3(clampf(-2.5+(n%9)*0.625,-3.0+extent.x,3.0-extent.x),0.08+extent.y+float(n/27)*0.14,clampf(-0.8+float((n/9)%3)*0.75,-1.35+extent.z,1.35-extent.z))
	history.append(id)
	# A single-step press lands one stone immediately while the rest stay paused.
	if not running:
		piece.node.position=piece.target; piece.node.rotation=piece.turn
		piece.age=-1.0; piece.body.collision_layer=1
	_readout()

func restore() -> void:
	for piece in pieces:
		piece.node.transform=piece.home; piece.fallen=false; piece.age=-1.0; piece.body.collision_layer=1
	# Restore the original stack ownership from creation order.
	stacks.clear()
	for col in range(12):
		var stack: Array[int]=[]
		for row in range(6): stack.append(col*6+row)
		stacks.append(stack)
	for col in range(4):
		var stack: Array[int]=[]
		for row in range(11): stack.append(72+col*11+row)
		stacks.append(stack)
	history.clear(); rng.seed=SEED; clock=0.0; running=false
	_readout()

func _readout() -> void:
	if readout==null: return
	readout.text="%d STONES / %d DISPLACED\n%s / seed %d" % [pieces.size(),history.size(),"RUNNING" if running else "PAUSED",SEED]
