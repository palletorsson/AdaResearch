extends XRToolsPickable
## A roll defines its width and skin. One trigger edge fixes A; the next fixes B.
## Rays use the actual desktop camera or holding controller, never a test target.
const Strip := preload("strip.gd")
const TYPES := ["masking","pink","barrier"]
const WIDTHS := [0.05,0.075,0.12]
const SURFACES := 0xFFFFFFFF & ~((1<<17)|(1<<19)) # All solid bodies, excluding avatar and collision hands.
@export_enum("masking","pink","barrier") var kind := "masking"
@export var roll_length := 30.0
@export var reach := 8.0
@export var max_span := 8.0
@export var bind_objects := true
## Deliberate opt-in: ordinary clicks must never become sampled scraps.
@export var freehand_draw := false
var remaining := 30.0
var start_anchor: Dictionary = {}
var segments: Array[Node3D] = []
var preview: MeshInstance3D
var marker: MeshInstance3D
var readout: Label3D
var tape_material: StandardMaterial3D
var pressed := false
var preview_only := false
var drag_points: Array[Dictionary] = []
var drag_time := 0.0
var drag_length := 0.0
var drag_gap := false
var drag_eligible := false
signal tape_placed(strip)
signal placement_refused(reason: String)

func _init() -> void:
	# XRTools captures its original collision state before _ready runs.
	collision_layer = 1|4;collision_mask = 1;freeze = true;gravity_scale = 0

func apply_grid_config(config: Dictionary) -> void:
	kind = str(config.get("kind",kind))
	if kind not in TYPES:kind = "masking"
	roll_length = clampf(float(config.get("roll_length",roll_length)),1,100)
	reach = clampf(float(config.get("reach",reach)),.5,12)
	max_span = clampf(float(config.get("max_span",max_span)),.1,12)
	bind_objects = bool(config.get("bind_objects",bind_objects))
	freehand_draw = bool(config.get("freehand_draw",freehand_draw))

func _ready() -> void:
	super._ready()
	freeze = true;release_mode = ReleaseMode.FROZEN;gravity_scale = 0
	collision_layer = 1|4;collision_mask = 1
	remaining = roll_length
	action_pressed.connect(_fire);action_released.connect(_release_fire)
	dropped.connect(func(_who):cancel())
	tape_material = _make_tape_material()
	_build_roll()
	preview = Strip.new();preview.name = "LiveTape";add_child(preview);preview.top_level = true
	preview.tape_width = WIDTHS[TYPES.find(kind)]*absf(global_basis.get_scale().x)
	var ghost := tape_material.duplicate();ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;ghost.albedo_color.a = .48;preview.material_override = ghost;preview.hide()
	marker = MeshInstance3D.new();marker.name = "AimDot";var dot := SphereMesh.new();dot.radius = .018;dot.height = .036;marker.mesh = dot
	var dot_mat := StandardMaterial3D.new();dot_mat.albedo_color = Color("ee478f");dot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED;marker.material_override = dot_mat
	add_child(marker);marker.top_level = true;marker.hide();_status("CLICK START")

func _make_tape_material() -> StandardMaterial3D:
	# A generated texture travels through native GLB exports and Android alike.
	# UV.x is metres, so stripes repeat at a fixed pitch rather than stretching.
	var image := Image.create(256,64,false,Image.FORMAT_RGBA8)
	var base: Color = Color("d6c291") if kind=="masking" else Color("f21c7d")
	for x in 256:
		for y in 64:
			var color := base
			if kind=="barrier":color = Color("15131c") if fposmod(float(x)/256+float(y)/64*.65,1)<.5 else Color("f56ba3")
			var grain := sin(float(x)*8.47+sin(float(y)*4.1))*sin(float(y)*9.73)*.012
			var edge := .82 if y<2 or y>61 else 1.0
			image.set_pixel(x,y,Color(clampf(color.r*edge+grain,0,1),clampf(color.g*edge+grain,0,1),clampf(color.b*edge+grain,0,1)))
	var material := StandardMaterial3D.new();material.albedo_texture = ImageTexture.create_from_image(image)
	material.uv1_scale = Vector3(1/.17,1,1);material.cull_mode = BaseMaterial3D.CULL_DISABLED;material.roughness = .43 if kind=="pink" else .88
	return material

func _build_roll() -> void:
	var faces := SurfaceTool.new();faces.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := SurfaceTool.new();sides.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outer := .14;var inner := .058;var depth: float = WIDTHS[TYPES.find(kind)]+.015
	for i in 48:
		var a := TAU*float(i)/48;var b := TAU*float(i+1)/48
		var ra := Vector3(cos(a),sin(a),0);var rb := Vector3(cos(b),sin(b),0)
		for z in [-depth*.5,depth*.5]:
			_quad(faces,ra*inner+Vector3(0,0,z),ra*outer+Vector3(0,0,z),rb*outer+Vector3(0,0,z),rb*inner+Vector3(0,0,z),Vector3(0,0,signf(z)),float(i)/48,float(i+1)/48)
		_quad(sides,ra*outer+Vector3(0,0,-depth*.5),ra*outer+Vector3(0,0,depth*.5),rb*outer+Vector3(0,0,depth*.5),rb*outer+Vector3(0,0,-depth*.5),(ra+rb).normalized(),a*outer,b*outer)
		_quad(faces,ra*inner+Vector3(0,0,depth*.5),ra*inner+Vector3(0,0,-depth*.5),rb*inner+Vector3(0,0,-depth*.5),rb*inner+Vector3(0,0,depth*.5),-(ra+rb).normalized(),float(i)/48,float(i+1)/48)
	var paper := StandardMaterial3D.new();paper.albedo_color = Color("dfd5bb") if kind=="masking" else Color("e89dbb");paper.roughness = .94;paper.cull_mode = BaseMaterial3D.CULL_DISABLED
	var winding := Image.create(4,256,false,Image.FORMAT_RGBA8)
	for y in 256:
		var tone := .91+.09*cos(float(y)/256*TAU*75)
		for x in 4:winding.set_pixel(x,y,Color(tone,tone,tone))
	paper.albedo_texture = ImageTexture.create_from_image(winding)
	var face := MeshInstance3D.new();face.name = "PaperAndCore";face.mesh = faces.commit();face.material_override = paper;add_child(face)
	var band := MeshInstance3D.new();band.name = "TapeSkin";band.mesh = sides.commit();band.material_override = tape_material;add_child(band)
	for i in 12:
		var angle := TAU*float(i)/12;var shape := CollisionShape3D.new();var box := BoxShape3D.new();box.size = Vector3(.075,.065,depth)
		shape.shape = box;shape.position = Vector3(cos(angle),sin(angle),0)*.105;shape.rotation.z = angle;add_child(shape)
	readout = Label3D.new();readout.name = "RollReadout";readout.position = Vector3(0,.205,.025);readout.font_size = 20;readout.pixel_size = .001;readout.modulate = Color("f4eee2");add_child(readout)

func _quad(tool: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3,n: Vector3,u: float,v: float) -> void:
	for row in [[a,Vector2(u,0)],[b,Vector2(u,1)],[c,Vector2(v,1)],[a,Vector2(u,0)],[c,Vector2(v,1)],[d,Vector2(v,0)]]:
		tool.set_normal(n);tool.set_uv(row[1]);tool.add_vertex(row[0])

func _aim() -> Dictionary:
	var controller = get_picked_up_by_controller()
	var origin: Vector3;var direction: Vector3
	if controller!=null:
		origin = controller.global_position;direction = -controller.global_basis.z
	else:
		var camera := get_viewport().get_camera_3d()
		if camera==null:return {}
		origin = camera.global_position;direction = -camera.global_basis.z
	var query := PhysicsRayQueryParameters3D.create(origin,origin+direction*reach,SURFACES)
	query.exclude = [get_rid()];query.hit_from_inside = false
	return get_world_3d().direct_space_state.intersect_ray(query)

func _physics_process(delta: float) -> void:
	if preview_only or preview==null:return
	if not is_picked_up():preview.hide();marker.hide();return
	var hit := _aim();marker.visible = not hit.is_empty()
	if marker.visible:marker.global_position = hit.position+hit.normal*.009
	if start_anchor.is_empty():preview.hide();return
	if pressed and drag_eligible:
		drag_time += delta
		if drag_time>=.14:_sample_drag(hit)
		if drag_points.size()>1:
			var points: Array[Dictionary] = []
			for record in drag_points:
				var point := Strip.resolve(record)
				if point.is_empty():cancel();return
				point.break_before = record.get("break_before",false);points.append(point)
			preview.draw_path(points);_status("RELEASE / STRIPE %.2f m"%drag_length);return
	var a := Strip.resolve(start_anchor)
	if a.is_empty():cancel();return
	var end: Vector3 = hit.position if not hit.is_empty() else global_position
	var normal: Vector3 = hit.normal if not hit.is_empty() else a.normal
	if a.position.distance_to(end)>max_span:end = a.position+a.position.direction_to(end)*max_span
	preview.draw_between(a.position,a.normal,end,normal)
	_status("CLICK END / %.2f m"%a.position.distance_to(end))

func _fire(_who = null) -> void:
	if preview_only or pressed or not is_picked_up():return
	pressed = true
	drag_eligible = false
	var hit := _aim()
	if hit.is_empty():_refuse("AIM AT A SURFACE");return
	if start_anchor.is_empty():
		start_anchor = Strip.anchor(hit);drag_points = [start_anchor];drag_time = 0;drag_length = 0;drag_gap = false;drag_eligible = freehand_draw
		_status("HOLD + DRAG / TAP END" if freehand_draw else "MOVE / CLICK END");return
	var a := Strip.resolve(start_anchor)
	if a.is_empty():cancel();return
	var length: float = Vector3(a.position).distance_to(hit.position)
	segments = segments.filter(func(segment):return is_instance_valid(segment) and not segment.is_queued_for_deletion())
	if length<.06:_refuse("MOVE FURTHER");return
	if length>max_span:_refuse("SPAN TOO LONG");return
	if length>remaining or segments.size()>=32:_refuse("ROLL EMPTY / TIDY TO RESET");return
	var query := PhysicsRayQueryParameters3D.create(a.position+a.normal*.012,hit.position+hit.normal*.012,SURFACES)
	query.exclude = [get_rid(),a.body.get_rid(),hit.collider.get_rid()]
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():_refuse("SOMETHING CROSSES THE TAPE");return
	var strip := Strip.new();strip.name = "TapeStrip";get_tree().current_scene.add_child(strip)
	strip.tape_width = WIDTHS[TYPES.find(kind)]*absf(global_basis.get_scale().x);strip.material_override = tape_material
	strip.anchors = [start_anchor,Strip.anchor(hit)];strip.paid_length = length;strip.issuer = weakref(self)
	print("TAPE_LINK ",a.body.get_path()," -> ",hit.collider.get_path())
	strip.draw_between(a.position,a.normal,hit.position,hit.normal)
	if bind_objects:strip.bind_surfaces()
	segments.append(strip);remaining -= length;start_anchor = {};preview.hide();_status("CLICK START");tape_placed.emit(strip)

func _sample_drag(hit: Dictionary) -> void:
	if hit.is_empty():drag_gap = true;return
	if drag_points.size()>=256:return
	var previous := Strip.resolve(drag_points[-1])
	if previous.is_empty():cancel();return
	var step: float = previous.position.distance_to(hit.position)
	if step<.025:return
	var record := Strip.anchor(hit)
	# A missing ray or a sudden large jump starts a fresh patch. Dragging over
	# empty air must not paint an invisible bridge through another exhibit.
	if drag_gap or step>.45:
		record.break_before = true;drag_gap = false
	else:
		if drag_length+step>minf(remaining,max_span):_status("STRIPE LIMIT / RELEASE");return
		drag_length += step
	drag_points.append(record)

func _release_fire(_who = null) -> void:
	if not pressed:return
	pressed = false
	if not drag_eligible:return
	_sample_drag(_aim())
	if drag_points.size()>1 and drag_length>=.06:
		segments = segments.filter(func(segment):return is_instance_valid(segment) and not segment.is_queued_for_deletion())
		if segments.size()>=32:_refuse("ROLL EMPTY / TIDY TO RESET");cancel();return
		var strip := Strip.new();strip.name = "TapeStripe";get_tree().current_scene.add_child(strip)
		strip.tape_width = WIDTHS[TYPES.find(kind)]*absf(global_basis.get_scale().x);strip.material_override = tape_material
		strip.anchors = drag_points.duplicate();strip.paid_length = drag_length;strip.issuer = weakref(self)
		if bind_objects:strip.bind_surfaces()
		segments.append(strip);remaining -= drag_length;tape_placed.emit(strip);start_anchor = {};preview.hide();_status("CLICK START")
	drag_eligible = false;drag_points.clear()

func _refuse(reason: String) -> void:
	_status(reason);placement_refused.emit(reason)

func _status(message: String) -> void:
	if readout!=null:readout.text = kind.to_upper()+" / %.1f m\n"%remaining+message

func cancel() -> void:
	start_anchor = {};pressed = false
	drag_points.clear();drag_eligible = false;drag_time = 0;drag_length = 0;drag_gap = false
	if preview!=null:preview.hide()
	if marker!=null:marker.hide()
	_status("CLICK START")

func clear_tape() -> void:
	cancel()
	for strip in segments:
		if is_instance_valid(strip):strip.queue_free()
	segments.clear();remaining = roll_length;_status("CLICK START")

func prepare_editor_preview() -> void:
	preview_only = true;cancel();freeze = true
