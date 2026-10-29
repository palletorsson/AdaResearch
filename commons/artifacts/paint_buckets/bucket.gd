extends XRToolsPickable
## A bucket of paint. Hold it, aim at a timber panel, pull the trigger: one coat. `finish` cover is
## emulsion (it lays its colour over what is there); glaze is stain (it filters what is beneath).
## Aims as the tape rolls do: from the holding controller, or the desktop camera.
const SURFACES := 0xFFFFFFFF & ~((1<<17)|(1<<19))
@export var paint := Color("d63a2f")
@export var paint_name := "RED"
@export_enum("cover","glaze") var finish := "cover"
@export var reach := 4.0
var station: WeakRef
var _paint_disc: MeshInstance3D
var _label: Label3D
var _pulse := 0.0

func _init() -> void:
	collision_layer = 1|4;collision_mask = 1;freeze = true;gravity_scale = 0

func _ready() -> void:
	super._ready()
	freeze = true;release_mode = ReleaseMode.FROZEN;gravity_scale = 0
	action_pressed.connect(_pour)
	_build()

func _build() -> void:
	var glass := finish=="glaze"
	# the tin (or, for a stain, a glass jar): a cylinder, a paint surface just under the rim, a wire handle
	var body := MeshInstance3D.new();body.name = "Tin";var cyl := CylinderMesh.new();cyl.top_radius = .13;cyl.bottom_radius = .12;cyl.height = .22;body.mesh = cyl;body.position.y = .11
	var tin := StandardMaterial3D.new()
	if glass:
		tin.albedo_color = Color(paint.r,paint.g,paint.b,.55);tin.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;tin.roughness = .08;tin.metallic_specular = .8
	else:
		tin.albedo_color = Color("b9bcc0");tin.metallic = .75;tin.roughness = .35
	body.material_override = tin;add_child(body)
	_paint_disc = MeshInstance3D.new();_paint_disc.name = "Paint";var disc := CylinderMesh.new();disc.top_radius = .118;disc.bottom_radius = .118;disc.height = .01;_paint_disc.mesh = disc;_paint_disc.position.y = .205
	var wet := StandardMaterial3D.new();wet.albedo_color = paint;wet.roughness = .12 if not glass else .05;_paint_disc.material_override = wet;add_child(_paint_disc)
	if not glass:   # a band of the colour round the tin, so a shelf of them reads from the side
		var band := MeshInstance3D.new();var bm := CylinderMesh.new();bm.top_radius = .132;bm.bottom_radius = .127;bm.height = .07;band.mesh = bm;band.position.y = .12
		var bmat := StandardMaterial3D.new();bmat.albedo_color = paint;bmat.roughness = .5;band.material_override = bmat;add_child(band)
	var wire := StandardMaterial3D.new();wire.albedo_color = Color("6e7277");wire.metallic = .8;wire.roughness = .3
	var prev := Vector3(-.13,.21,0)
	for i in range(1,13):
		var a := PI*float(i)/12.0;var p := Vector3(-cos(a)*.13,.21+sin(a)*.12,0)
		var seg := MeshInstance3D.new();var sm := CylinderMesh.new();sm.top_radius = .006;sm.bottom_radius = .006;sm.height = prev.distance_to(p);seg.mesh = sm
		seg.position = (prev+p)*.5;seg.basis = Basis(Quaternion(Vector3.UP,(p-prev).normalized()));seg.material_override = wire;add_child(seg);prev = p
	var shape := CollisionShape3D.new();var cs := CylinderShape3D.new();cs.radius = .13;cs.height = .22;shape.shape = cs;shape.position.y = .11;add_child(shape)
	_label = Label3D.new();_label.text = paint_name+(" STAIN" if glass else "");_label.font_size = 28;_label.pixel_size = .0012;_label.position = Vector3(0,.12,.135)
	_label.modulate = Color("1d1d1f") if paint.get_luminance()>.45 or glass else Color("f4f0e6");_label.outline_size = 0;add_child(_label)

func _aim() -> Dictionary:
	var controller = get_picked_up_by_controller()
	var origin: Vector3;var direction: Vector3
	if controller!=null:
		origin = controller.global_position;direction = -controller.global_basis.z
	else:
		var camera := get_viewport().get_camera_3d()
		if camera==null:return {}
		origin = camera.global_position;direction = -camera.global_basis.z
	var query := PhysicsRayQueryParameters3D.create(origin,origin+direction*reach,SURFACES);query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)

func _pour(_who = null) -> void:
	if not is_picked_up():return
	var hit := _aim()
	var s = station.get_ref() if station!=null else null
	if hit.is_empty() or s==null:return
	if s.coat_body(hit.collider,paint,finish,paint_name):_pulse = .25

func _process(delta: float) -> void:
	if _pulse>0.0:   # the paint level dips as a coat leaves the tin
		_pulse = maxf(0.0,_pulse-delta);_paint_disc.position.y = .205-.02*sin(_pulse/.25*PI)
