extends Node3D
## @identity
## essence: the bridge's graded health becomes an aperture above the visitor
## desire: reveal a local loss of support at both foot and room scale
## needs: the original proximity bridge; no clock, solver or visitor sampling here
## truth: colour, aperture and support are distinct readings of one scalar.
const Mount = preload("res://commons/void/ceiling_display_mount.gd")
const Source = preload("res://commons/void/ca_receiver_source.gd")
var source: Node3D
var angles: Dictionary = {}
var leaves: MultiMesh
var rims: MultiMesh
var axles: MultiMesh
var rendered: Dictionary = {}
var caption: Label3D
var elapsed := 0.0
func _ready() -> void:
	var steel := Mount.material("20252b",.38,.7)
	var cream := Mount.material("e7e3db",.6,.1)
	var pink := Mount.material("ef69af",.42,.2)
	var gold := Mount.material("ffd77d",.5,.15)
	leaves = batch("HealthLeaves",80,Vector3(.54,.055,.52),cream,true)
	rims = batch("LeafRims",160,Vector3(.55,.035,.025),pink,true)
	axles = batch("LeafAxles",80,Vector3(.035,.035,.61),steel)
	# Real drop rods end at the underside of the next slab (5.64 m).
	for x in [-1.7,1.7]:
		Mount.box(self,"CarrierRail",Vector3(x,4.92,4.5),Vector3(.09,.14,10.0),steel)
		for z in [-.35,4.5,9.35]:
			Mount.box(self,"DropRod",Vector3(x,5.26,z),Vector3(.05,.68,.05),cream)
			Mount.box(self,"SlabPlate",Vector3(x,5.59,z),Vector3(.4,.08,.4),steel)
			for dx in [-.13,.13]:Mount.box(self,"AnchorBolt",Vector3(x+dx,5.53,z),Vector3(.025,.04,.025),pink)
	for z in range(16):
		Mount.box(self,"HingeRail",Vector3(0,4.66,z*.6),Vector3(3.5,.055,.055),steel)
		for x in range(5):
			var coord := Vector2i(x,z)
			angles[coord] = 0.0
			var i := z*5+x
			axles.set_instance_transform(i,Transform3D(Basis(),Vector3((x-2)*.6,4.6,z*.6)))
			for side in 2:rims.set_instance_color(i*2+side,Color("ffd77d") if coord==Vector2i(2,6) else Color("ef69af"))
	caption = Label3D.new();caption.name = "SourceReadout";caption.position = Vector3(0,3.85,-.42);caption.rotation.y = PI
	caption.font_size = 42;caption.pixel_size = .0019;caption.outline_size = 0;caption.modulate = Color("ffe7f1");add_child(caption)
	set_meta("void_preview_kind","80 louvers read the original proximity bridge's health. Angle = 80 degrees times (1-health). Suspended above head height; no extra simulation or collision rule.")
	refresh()
func batch(title: String, count: int, size: Vector3, finish: StandardMaterial3D, colours := false) -> MultiMesh:
	var m := MultiMesh.new();m.transform_format = MultiMesh.TRANSFORM_3D;m.use_colors = colours;m.instance_count = count
	var box := BoxMesh.new();box.size = size;m.mesh = box
	var view := MultiMeshInstance3D.new();view.name = title;view.multimesh = m
	var local_finish := finish.duplicate() as StandardMaterial3D
	if colours:local_finish.albedo_color = Color.WHITE;local_finish.vertex_color_use_as_albedo = true
	view.material_override = local_finish;add_child(view);return m
func _process(delta: float) -> void:
	elapsed += delta
	if elapsed>=.05:elapsed = 0;refresh()
func refresh() -> void:
	if not is_instance_valid(source):source = Source.find(self,"decaying_bridge")
	if source==null or source.grid.is_empty():
		caption.text = "CONNECT THE PROXIMITY BRIDGE ON THIS FLOOR";return
	for coord: Vector2i in angles:
		var health: float = source.grid.get(coord,1.0)
		if rendered.has(coord) and is_equal_approx(rendered[coord],health):continue
		rendered[coord] = health
		angles[coord] = deg_to_rad(80.0*(1.0-health))
		var pose := Transform3D(Basis(Vector3.FORWARD,-angles[coord]),Vector3((coord.x-2)*.6,4.6,coord.y*.6))
		var i := coord.y*5+coord.x
		leaves.set_instance_transform(i,pose);leaves.set_instance_color(i,Color("ef69af").lerp(Color("e7e3db"),health))
		for side in 2:rims.set_instance_transform(i*2+side,pose*Transform3D(Basis(),Vector3(0,-.035,(side*2-1)*.255)))
	var study: Node3D = source.get_node("ProximityStudy")
	caption.text = "THE SAME HEALTH ABOVE / %04.1f s\nFULL: CLOSED · DRAINED: OPEN · GOLD: W (2,6)"%(study.ticks*.1)
func readback() -> Dictionary:
	return {"health":rendered.duplicate(),"source_id":str(get_meta("config_source_id","")),"minimum_swept_height":4.32,"mapping":"angle=80*(1-health) degrees; no added support rule"}
