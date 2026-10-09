extends "res://commons/artifacts/randomness_space/entropy_ruin.gd"
## A replacement for real museum wall cells, including their collision.
## Uses the ruin's seeded top-course rule and bounded, authored descent.
var length_m: int = 6
var height_m: float = 4.5
var wall_seed: int = 79
var original_stacks: Array = []

func _ready() -> void:
	name = "WeatheringWall"
	# Architecture can be streamed long before a visitor reaches this corner.
	# Let the visitor begin the wall's change at the console.
	running = false
	clock = 0.0
	# The footing remains visible and solid; the floor is never weathered.
	Stage.box(self, Vector3(0,0.25,0), Vector3(length_m,0.5,1), Color(0.65,0.62,0.55), true)
	Stage.box(self, Vector3(0,-0.1,0.7), Vector3(length_m,0.2,2.6), Color(0.24,0.24,0.25), true)
	for x in [-length_m/2.0, length_m/2.0]:
		Stage.box(self, Vector3(x,0.075,1.25), Vector3(0.06,0.15,1.5), Color(0.55,0.52,0.46), true)
	var rows: int = 12
	var rise: float = (height_m-0.5)/rows
	for col in range(length_m*2):
		var stack: Array[int] = []
		for row in range(rows):
			var size := Vector3(0.49,rise-0.008,0.99)
			var mat := Stage.material(Color(0.76,0.74,0.69).lerp(Color(0.94,0.92,0.87),float((col*3+row)%7)/6.0))
			mat.roughness = 0.94
			stack.append(_piece(_block(size),Vector3(-length_m/2.0+0.25+col*0.5,0.5+rise*(row+0.5),0),mat,size))
		stacks.append(stack)
	original_stacks = stacks.duplicate(true)
	var panel := Rack.create_panel("THE MUSEUM WALL", [[{"type":"button","label":"RUN / PAUSE"},{"type":"button","label":"ONE STONE"},{"type":"button","label":"RESTORE"}]])
	panel.position = Vector3(0,1.1,2.55)
	add_child(panel)
	panel.find_child("Btn_0",true,false).pressed.connect(func(): running=not running; _readout())
	panel.find_child("Btn_1",true,false).pressed.connect(func(): running=false; weather_one())
	panel.find_child("Btn_2",true,false).pressed.connect(restore)
	readout = Stage.label(self,"",Vector3(0,1.55,2.54))
	readout.font_size=24; readout.pixel_size=0.0015
	Stage.box(self,Vector3(0,1.55,2.51),Vector3(1.65,0.24,0.035),Color(0.07,0.1,0.12))
	Stage.install(self,{"controls":"compact","control_front":2.55})
	rng.seed = wall_seed
	_readout()

func weather_one() -> void:
	var previous: int = history.size()
	super.weather_one()
	if history.size() == previous: return
	var piece: Dictionary = pieces[history.back()]
	var basis := Basis.from_euler(piece.turn)
	var size: Vector3 = piece.size
	var extent: Vector3 = (abs(basis.x)*size.x+abs(basis.y)*size.y+abs(basis.z)*size.z)*0.5
	var n: int = previous
	# Fall towards the hall, into the shallow apron. Keep the console approach clear.
	piece.target = Vector3(clampf(-length_m/2.0+0.35+(n%9)*(length_m-0.7)/8.0,-length_m/2.0+extent.x,length_m/2.0-extent.x),extent.y+float(n/18)*0.10,clampf(0.95+float((n/9)%2)*0.40,0.51+extent.z,2.0-extent.z))
	if not running: piece.node.position=piece.target

func restore() -> void:
	for piece in pieces:
		piece.node.transform=piece.home; piece.fallen=false; piece.age=-1.0; piece.body.collision_layer=1
	stacks=original_stacks.duplicate(true)
	history.clear(); rng.seed=wall_seed; clock=0.0; running=false
	_readout()

func _readout() -> void:
	if readout == null: return
	readout.text="WALL: %d STONES / %d DISPLACED\n%s / seed %d" % [pieces.size(),history.size(),"RUNNING" if running else "PAUSED",wall_seed]
