extends "res://commons/artifacts/barber_pole/barber_pole.gd"
## A rotating sleeve around a fixed square structural pillar. Unlike the museum
## pole's UV scrolling, the textured geometry actually turns; nothing climbs.
var part_defaults: Dictionary = {}
var rotor: Node3D
var mount: Node3D
var phase := 0.0

func _ready() -> void:
	pole_height = 4.8;pole_radius = .74;stripe_turns = 3.0
	stripe_color_a = Color("d52b54");stripe_color_b = Color("ed8fba")
	spin_speed = .075
	rotor = Node3D.new();rotor.name = "StripedSleeve";add_child(rotor)
	var shell := MeshInstance3D.new();shell.name = "RotatingPinkRedWhiteBands"
	var cylinder := CylinderMesh.new();cylinder.top_radius = pole_radius;cylinder.bottom_radius = pole_radius
	cylinder.height = pole_height;cylinder.cap_top = false;cylinder.cap_bottom = false;cylinder.radial_segments = 96
	shell.mesh = cylinder;shell.material_override = _make_stripe_material();shell.position.y = 2.95;rotor.add_child(shell)
	mount = Node3D.new();mount.name = "PillarMount";add_child(mount)
	var finish = load("res://commons/artifacts/machine_finish.gd")
	for y in [.53,5.37]:
		var cuff := MeshInstance3D.new();var ring := TorusMesh.new()
		ring.inner_radius = .72;ring.outer_radius = .8;ring.rings = 80;ring.ring_segments = 12
		cuff.mesh = ring;cuff.material_override = finish.steel();cuff.position.y = y;mount.add_child(cuff)
	# Stationary witness and rotating pink notch distinguish real rotation from
	# the apparent vertical travel of the continuous diagonal colour bands.
	var witness := MeshInstance3D.new();witness.mesh = BoxMesh.new();witness.mesh.size = Vector3(.035,.6,.035)
	witness.position = Vector3(0,2.95,.79);witness.material_override = finish.ivory();mount.add_child(witness)
	var notch := MeshInstance3D.new();notch.mesh = BoxMesh.new();notch.mesh.size = Vector3(.12,.08,.06)
	notch.position = Vector3(0,5.26,.76);notch.material_override = finish.pink();rotor.add_child(notch)
	part_defaults = {"StripedSleeve":{"position":[0,0,0],"rotation":[0,0,0],"bounds":[-.8,.55,-.8,1.6,4.8,1.6]},"PillarMount":{"position":[0,0,0],"rotation":[0,0,0],"bounds":[-.8,.49,-.8,1.6,4.92,1.6]}}
	set_meta("void_preview_kind","Actual rotating striped sleeve; exported source geometry and generated pink/red/white stripe texture, frozen at phase zero.")

func _process(delta: float) -> void:
	if spin and is_instance_valid(rotor):
		phase = fposmod(phase+spin_speed*TAU*delta,TAU);rotor.rotation.y = phase

func _make_stripe_material() -> StandardMaterial3D:
	# Same museum helix formula, resolved for a five-metre architectural sleeve.
	var img := Image.create(512,1024,false,Image.FORMAT_RGBA8)
	var palette := [stripe_color_a,Color("f5f1e9"),stripe_color_b]
	for y in 1024:
		for x in 512:
			var band := (float(x)/512.0-float(y)/1024.0*stripe_turns)*3.0
			var index := posmod(floori(band),3)
			var colour: Color = palette[index]
			var edge := fposmod(band,1.0)
			if edge<.012:colour = palette[posmod(index-1,3)].lerp(colour,edge/.012)
			img.set_pixel(x,y,colour)
	_stripe_mat = StandardMaterial3D.new();_stripe_mat.albedo_texture = ImageTexture.create_from_image(img)
	_stripe_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_stripe_mat.roughness = .35;_stripe_mat.metallic = .12
	return _stripe_mat

func apply_grid_config(config: Dictionary) -> void:
	if config.has("spin"):spin = bool(config.spin)
	if config.has("spin_speed"):spin_speed = float(config.spin_speed)
	for child: Node3D in [rotor,mount]:
		var id := str(child.name)
		if config.has("only_parts") and id not in config.only_parts:
			part_defaults.erase(id);child.free();continue
		var pose: Dictionary = config.get("parts",{}).get(id,part_defaults[id])
		var p: Array = pose.get("position",[0,0,0]);var r: Array = pose.get("rotation",[0,0,0])
		child.position = Vector3(p[0],p[1],p[2]);child.rotation_degrees = Vector3(r[0],r[1],r[2])

func prepare_editor_preview() -> void:
	set_process(false)
	if is_instance_valid(rotor):rotor.rotation.y = 0
	await get_tree().process_frame
