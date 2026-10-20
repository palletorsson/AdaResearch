extends "res://commons/artifacts/crate/crate.gd"
## The existing shipping crate at body scale. Only its north panel breaks.
## Pointer press and tracked-hand sweep converge on the same inside-only strike.
signal opened
var broken := false
var panel: Node3D
var panel_shape: CollisionShape3D
var world: Node3D
var previous_hands: Dictionary = {}
var state_key := ""
var wood_grain: ImageTexture

func _ready() -> void:
	crate_width = 3.2
	crate_depth = 2.8
	crate_height = 2.6
	plank_count = 8
	plank_thickness = 0.045
	corner_strip_width = 0.14
	corner_strip_thickness = 0.055
	show_stamp = false
	show_x_brace = false
	plank_color = Color("c9bc91")
	plank_color_alt = Color("bcaf83")
	strip_color = Color("ada17b")
	super()
	for strip in get_children():
		if strip is MeshInstance3D and "Strip" in str(strip.name):
			strip.material_override = _make_wood_mat(strip_color)
	panel = get_node("BackFace")
	var inner_brace := wood_bar(panel,Vector3(0,0,-0.065),Vector3(3.0,0.14,0.08))
	inner_brace.rotation.z = 0.48
	# Battens belong to their panel; they leave with it, not across the exit.
	for face_name in ["BackFace", "FrontFace", "LeftFace", "RightFace"]:
		var face := get_node(face_name) as Node3D
		var width := crate_width if face_name in ["BackFace","FrontFace"] else crate_depth
		for y in [-0.86,0.86]:
			wood_bar(face,Vector3(0,y,0.065),Vector3(width,0.15,0.10))
		var brace := wood_bar(face,Vector3(0,0,0.07),Vector3(width*0.93,0.13,0.10))
		brace.rotation.z = 0.50
	panel_shape = solid("BreakPanel",Vector3(0,1.3,-1.4),Vector3(3.2,2.6,0.07))
	solid("BackWall",Vector3(0,1.3,1.4),Vector3(3.2,2.6,0.07))
	solid("LeftWall",Vector3(-1.6,1.3,0),Vector3(0.07,2.6,2.8))
	solid("RightWall",Vector3(1.6,1.3,0),Vector3(0.07,2.6,2.8))
	solid("Lid",Vector3(0,2.6,0),Vector3(3.2,0.07,2.8))
	# The tower slab is the floor. No second raised collider traps the feet.
	surface_mark(get_node("FrontFace"),"care-unit-mark",Vector2(-0.25,0.65),Vector2(2.25,0.17))
	surface_mark(get_node("FrontFace"),"up-mark",Vector2(-0.8,0.35),Vector2(0.95,0.14))
	surface_mark(panel,"strike-mark",Vector2(0,0.65),Vector2(1.3,0.17),true)
	var lamp := OmniLight3D.new()
	lamp.name = "PackingLight"
	lamp.position = Vector3(0,2.2,0.8)
	lamp.light_color = Color("e8c59b")
	lamp.light_energy = 0.35
	lamp.omni_range = 3.4
	lamp.shadow_enabled = true
	add_child(lamp)
	var ancestor := get_parent()
	while ancestor != null:
		if "ready_for_play" in ancestor:
			world = ancestor
			break
		ancestor = ancestor.get_parent()
	if world != null:
		state_key = ("opened_crate_" + str(get_parent().get_parent().name) + "_" + str(get_parent().name)).replace("-","_")
		if world.get_meta(state_key,false): break_panel(false)

func wood_bar(host: Node3D, at: Vector3, size: Vector3) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _make_wood_mat(Color("b5a77c"))
	mesh.position = at
	host.add_child(mesh)
	return mesh

func surface_mark(face: Node3D, texture_name: String, centre: Vector2, size: Vector2, inward := false) -> void:
	# Flush textured ink, sliced at the plank seams. It receives the same
	# lighting as timber and travels with each board when the panel breaks.
	# Mesh decals also survive the web export and Compatibility renderer.
	var texture := load("res://commons/void/textures/"+texture_name+".png") as Texture2D
	var side := -1.0 if inward else 1.0
	for plank in face.get_children():
		if not str(plank.name).begins_with("Plank"): continue
		var width: float = plank.mesh.size.x
		var x: float = plank.position.x*side
		var left := maxf(centre.x-size.x/2,x-width/2)
		var right := minf(centre.x+size.x/2,x+width/2)
		if right<=left: continue
		var ink := MeshInstance3D.new()
		ink.name = "SurfaceInk"
		var quad := QuadMesh.new()
		quad.size = Vector2(right-left,size.y)
		ink.mesh = quad
		var material := StandardMaterial3D.new()
		material.albedo_texture = texture
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		material.alpha_scissor_threshold = 0.3
		material.roughness = 1.0
		material.uv1_scale.x = (right-left)/size.x
		material.uv1_offset.x = (left-centre.x+size.x/2)/size.x
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		ink.material_override = material
		ink.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ink.position = Vector3(side*(left+right)/2-plank.position.x,centre.y,side*(plank_thickness/2+0.001))
		if inward: ink.rotation.y = PI
		plank.add_child(ink)

func _make_wood_mat(c: Color) -> StandardMaterial3D:
	if wood_grain == null:
		var image := Image.create(128,256,false,Image.FORMAT_RGB8)
		var noise := FastNoiseLite.new()
		noise.seed = 731
		noise.frequency = 0.06
		for y in range(256):
			for x in range(128):
				var bend := noise.get_noise_2d(x*0.3,y*0.18)*5.0
				var grain := sin((float(x)+bend)*1.5)*0.025
				var value := clampf(0.94+grain+noise.get_noise_2d(x*2.0,y*0.2)*0.10,0.7,1.0)
				image.set_pixel(x,y,Color(value,value,value))
		wood_grain = ImageTexture.create_from_image(image)
	var material := super(c)
	material.albedo_texture = wood_grain
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return material

func solid(title: String, at: Vector3, size: Vector3) -> CollisionShape3D:
	var body := StaticBody3D.new()
	body.name = title
	body.collision_layer = 1 | (1 << 20)
	body.position = at
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	return shape

func inside(at: Vector3) -> bool:
	var p := to_local(at)
	return absf(p.x)<1.56 and absf(p.z)<1.38 and p.y>0.05 and p.y<2.55

func strike(from: Vector3, at: Vector3) -> bool:
	if broken or not inside(from): return false
	if world != null and (not world.ready_for_play or world.recovering): return false
	var p := to_local(at)
	if absf(p.x)>1.5 or p.y<0.15 or p.y>2.45 or absf(p.z+1.4)>0.22: return false
	if from.distance_to(at)>2.2: return false
	break_panel()
	return true

func pointer_event(event: XRToolsPointerEvent) -> void:
	if event.event_type == XRToolsPointerEvent.Type.PRESSED:
		strike(event.pointer.global_position,event.position)

func _physics_process(delta: float) -> void:
	if broken or world == null or not world.vr: return
	if not world.ready_for_play or world.recovering:
		previous_hands.clear()
		return
	for controller in world.get_node("XROrigin3D").get_children():
		if not (controller is XRController3D): continue
		if not controller.get_is_active():
			previous_hands.erase(controller)
			continue
		var now: Vector3 = controller.global_position
		if previous_hands.has(controller):
			sweep_hand(previous_hands[controller],now,delta)
		previous_hands[controller] = now

func sweep_hand(before: Vector3, now: Vector3, delta: float) -> bool:
	var a := to_local(before)
	var b := to_local(now)
	# A swept test catches fast punches without waiting for overlap. Ignore
	# tracking teleports and stationary hands; do not require the catalyst.
	if before.distance_to(now)>0.8 or delta<=0: return false
	if (a.z-b.z)/delta<0.55 or a.z<=-1.27 or b.z> -1.27: return false
	var t := (-1.27-a.z)/(b.z-a.z)
	var contact := a.lerp(b,t)
	contact.z = -1.4
	return strike(before,to_global(contact))

func break_panel(animate := true) -> void:
	if broken: return
	broken = true
	panel_shape.set_deferred("disabled",true)
	if world != null: world.set_meta(state_key,true)
	get_node("PackingLight").light_energy = 0.12
	if animate:
		play_crack()
		# Finite visual fragments, no rigid debris under the player's feet.
		var i := 0
		for piece in panel.get_children():
			if not (piece is Node3D): continue
			var tween := create_tween().set_parallel(true)
			tween.tween_property(piece,"position",piece.position+Vector3((i%3-1)*0.16,-1.4,1.4+(i%4)*0.12),0.65)
			tween.tween_property(piece,"rotation:x",0.9+(i%3)*0.22,0.65)
			i += 1
		var finish := create_tween()
		finish.tween_interval(0.75)
		finish.tween_callback(panel.hide)
	else: panel.hide()
	opened.emit()

func play_crack() -> void:
	var sound := AudioStreamPlayer3D.new()
	sound.name = "WoodSplinter"
	sound.position = Vector3(0,1.3,-1.4)
	sound.max_distance = 12.0
	sound.volume_db = -14.0
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var bytes := PackedByteArray()
	bytes.resize(6615*2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 731
	var low := 0.0
	for i in range(6615):
		var t := float(i)/22050.0
		low = lerpf(low,rng.randf_range(-1,1),0.38)
		var amplitude := exp(-t*22.0)
		var value := (low*0.65+sin(TAU*135*t)*0.28)*amplitude
		bytes.encode_s16(i*2,int(value*32767))
	stream.data = bytes
	sound.stream = stream
	add_child(sound)
	sound.finished.connect(sound.queue_free)
	sound.play()
