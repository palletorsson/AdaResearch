extends XRToolsPickable
## A roll defines its width and skin. One trigger edge fixes A; the next fixes B.
## Rays use the actual desktop camera or holding controller, never a test target.
const Strip := preload("strip.gd")
const Design := preload("tape_design.gd")
const TYPES := ["masking","pink","barrier","printed"]
const WIDTHS := [0.05,0.075,0.12,0.075]
const SURFACES := 0xFFFFFFFF & ~((1<<17)|(1<<19)) # All solid bodies, excluding avatar and collision hands.
@export_enum("masking","pink","barrier","printed") var kind := "masking"
## Printed tape only: `environment` prints what the strip measures where it lies (its length, what it
## runs from and to or marks, whether it joins them, heading, slope, its number); `note` prints `note`.
@export_enum("environment","note") var print_mode := "environment"
@export var note := ""
## A design from tapes.json (edited at the tape studio page): its width, skin and print replace the
## kind's. Empty keeps the kind as it was.
@export var tape := ""
var design: Dictionary = {}
@export var roll_length := 30.0
## How many strips a roll may have out at once (the station's three rolls keep 32; the inventory's tape sets
## 300). Each strip is one mesh; a PRINTED strip also keeps one picture of its words, `print_max_px` wide at
## most - 4096 x 96 RGBA is 1.5 MB, so 300 printed strips are at most 450 MB on a Quest and in practice far
## less, since a strip's picture is only as wide as its length needs (96 px per tape width).
@export var max_strips := 32
@export var print_max_px := 8192
@export var reach := 8.0
@export var max_span := 8.0
@export var bind_objects := true
## Deliberate opt-in: ordinary clicks must never become sampled scraps.
@export var freehand_draw := false
## A stroke's LEG (Palle, 2026-10-29: "do not add lines if we have not moved the raycast point more than
## 30 cm"): while the trigger is held the aim is read every `drag_tick` seconds (the slow ray) and a point is
## added only when it has moved `leg` from the last one and the straight leg to it is clear; the strip is the
## straight legs between those points. 0 keeps the dense sampling (every 2.5 cm, every physics frame).
@export var leg := 0.0
@export var drag_tick := 0.2
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
var _tick := 0.0
## WORN (the inventory's tape item): the roll as a bangle on the controller the bracelet is in, not held,
## so the hand stays free. Aim and fire come from that controller, through the bracelet's PLACE mode
## (fire_worn / release_worn / undo_last); the strips keep their full width whatever the bangle's size.
var worn_on: Node3D = null
var worn_active := true
var aim_line: MeshInstance3D
var _aim_from := Vector3.ZERO
var _aim_to := Vector3.ZERO
signal leg_added(count: int)
signal tape_placed(strip)
signal placement_refused(reason: String)

func _init() -> void:
	# XRTools captures its original collision state before _ready runs.
	collision_layer = 1|4;collision_mask = 1;freeze = true;gravity_scale = 0

func apply_grid_config(config: Dictionary) -> void:
	kind = str(config.get("kind",kind))
	if kind not in TYPES:kind = "masking"
	roll_length = clampf(float(config.get("roll_length",roll_length)),1,1000)
	max_strips = clampi(int(config.get("max_strips",max_strips)),1,1000)
	print_max_px = clampi(int(config.get("print_max_px",print_max_px)),256,8192)
	reach = clampf(float(config.get("reach",reach)),.5,12)
	max_span = clampf(float(config.get("max_span",max_span)),.1,12)
	bind_objects = bool(config.get("bind_objects",bind_objects))
	freehand_draw = bool(config.get("freehand_draw",freehand_draw))
	leg = clampf(float(config.get("leg",leg)),0,2)
	drag_tick = clampf(float(config.get("drag_tick",drag_tick)),0,1)
	print_mode = str(config.get("print",print_mode))
	if print_mode not in ["environment","note"]:print_mode = "environment"
	note = str(config.get("note",note))
	tape = str(config.get("tape",tape))

func _ready() -> void:
	super._ready()
	freeze = true;release_mode = ReleaseMode.FROZEN;gravity_scale = 0
	collision_layer = 1|4;collision_mask = 1
	remaining = roll_length
	action_pressed.connect(_fire);action_released.connect(_release_fire)
	dropped.connect(func(_who):cancel())
	design = Design.load_design(tape)
	tape_material = Design.material(design) if not design.is_empty() else _make_tape_material()
	_build_roll()
	preview = Strip.new();preview.name = "LiveTape";add_child(preview);preview.top_level = true
	preview.tape_width = _width()*_tape_scale()
	var ghost := tape_material.duplicate();ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;ghost.albedo_color.a = .48;preview.material_override = ghost;preview.hide()
	marker = MeshInstance3D.new();marker.name = "AimDot";var dot := SphereMesh.new();dot.radius = .018;dot.height = .036;marker.mesh = dot
	var dot_mat := StandardMaterial3D.new();dot_mat.albedo_color = Color("ee478f");dot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED;marker.material_override = dot_mat
	add_child(marker);marker.top_level = true;marker.hide();_status("CLICK START")

func _make_tape_material() -> StandardMaterial3D:
	# A generated texture travels through native GLB exports and Android alike.
	# UV.x is metres, so stripes repeat at a fixed pitch rather than stretching.
	var image := Image.create(256,64,false,Image.FORMAT_RGBA8)
	var base: Color = Color("d6c291") if kind=="masking" else Color("efe9dc") if kind=="printed" else Color("f21c7d")
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
	var outer := .14;var inner := .058;var depth: float = _width()+.015
	for i in 48:
		var a := TAU*float(i)/48;var b := TAU*float(i+1)/48
		var ra := Vector3(cos(a),sin(a),0);var rb := Vector3(cos(b),sin(b),0)
		for z in [-depth*.5,depth*.5]:
			_quad(faces,ra*inner+Vector3(0,0,z),ra*outer+Vector3(0,0,z),rb*outer+Vector3(0,0,z),rb*inner+Vector3(0,0,z),Vector3(0,0,signf(z)),float(i)/48,float(i+1)/48)
		_quad(sides,ra*outer+Vector3(0,0,-depth*.5),ra*outer+Vector3(0,0,depth*.5),rb*outer+Vector3(0,0,depth*.5),rb*outer+Vector3(0,0,-depth*.5),(ra+rb).normalized(),a*outer,b*outer)
		_quad(faces,ra*inner+Vector3(0,0,depth*.5),ra*inner+Vector3(0,0,-depth*.5),rb*inner+Vector3(0,0,-depth*.5),rb*inner+Vector3(0,0,depth*.5),-(ra+rb).normalized(),float(i)/48,float(i+1)/48)
	var paper := StandardMaterial3D.new();paper.albedo_color = Color("dfd5bb") if kind in ["masking","printed"] else Color("e89dbb");paper.roughness = .94;paper.cull_mode = BaseMaterial3D.CULL_DISABLED
	if not design.is_empty():paper.albedo_color = Color(str(design.get("a","dfd5bb")))   # the wound tape shows its own colour at the sides
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
	var controller = worn_on if worn_on!=null else get_picked_up_by_controller()
	var origin: Vector3;var direction: Vector3
	if controller!=null:
		origin = controller.global_position;direction = -controller.global_basis.z
	else:
		var camera := get_viewport().get_camera_3d()
		if camera==null:return {}
		origin = camera.global_position;direction = -camera.global_basis.z
	var query := PhysicsRayQueryParameters3D.create(origin,origin+direction*reach,SURFACES)
	query.exclude = [get_rid()];query.hit_from_inside = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	_aim_from = origin;_aim_to = hit.position if not hit.is_empty() else origin+direction*reach
	return hit

func _physics_process(delta: float) -> void:
	if preview_only or preview==null:return
	if not _active():preview.hide();marker.hide();_hide_aim();return
	var hit := _aim();marker.visible = not hit.is_empty()
	if marker.visible:marker.global_position = hit.position+hit.normal*.009
	if worn_on!=null:_draw_aim()
	if start_anchor.is_empty():preview.hide();return
	if pressed and drag_eligible:
		drag_time += delta;_tick += delta
		if drag_time>=.14 and (leg<=0 or _tick>=drag_tick):_tick = 0;_sample_drag(hit)
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
	if preview_only or pressed or not _active():return
	pressed = true
	drag_eligible = false
	var hit := _aim()
	if hit.is_empty():_refuse("AIM AT A SURFACE");return
	if start_anchor.is_empty():
		start_anchor = Strip.anchor(hit);drag_points = [start_anchor];drag_time = 0;_tick = 0;drag_length = 0;drag_gap = false;drag_eligible = freehand_draw
		_status("HOLD + DRAG / TAP END" if freehand_draw else "MOVE / CLICK END");return
	var a := Strip.resolve(start_anchor)
	if a.is_empty():cancel();return
	var length: float = Vector3(a.position).distance_to(hit.position)
	segments = segments.filter(func(segment):return is_instance_valid(segment) and not segment.is_queued_for_deletion())
	if length<.06:_refuse("MOVE FURTHER");return
	if length>max_span:_refuse("SPAN TOO LONG");return
	if length>remaining or segments.size()>=max_strips:_refuse("ROLL EMPTY / TIDY TO RESET");return
	var query := PhysicsRayQueryParameters3D.create(a.position+a.normal*.012,hit.position+hit.normal*.012,SURFACES)
	query.exclude = [get_rid(),a.body.get_rid(),hit.collider.get_rid()]
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():_refuse("SOMETHING CROSSES THE TAPE");return
	var strip := Strip.new();strip.name = "TapeStrip";get_tree().current_scene.add_child(strip)
	strip.tape_width = _width()*_tape_scale();strip.material_override = tape_material;strip.print_max_px = print_max_px
	strip.anchors = [start_anchor,Strip.anchor(hit)];strip.paid_length = length;strip.issuer = weakref(self)
	print("TAPE_LINK ",a.body.get_path()," -> ",hit.collider.get_path())
	strip.draw_between(a.position,a.normal,hit.position,hit.normal)
	if bind_objects:strip.bind_surfaces()
	if _prints():
		strip.print_source = printer(strip,a.body,hit.collider,segments.size()+1)
		_set_reader(strip)
		strip.lay_print(a.position,a.normal,hit.position,hit.normal)
	segments.append(strip);remaining -= length;start_anchor = {};preview.hide();_status("CLICK START");tape_placed.emit(strip)

## `final`: the point where the trigger was let go, taken from 6 cm so the strip ends where the hand stopped.
func _sample_drag(hit: Dictionary,final := false) -> void:
	if hit.is_empty():drag_gap = true;return
	if drag_points.size()>=256:return
	var previous := Strip.resolve(drag_points[-1])
	if previous.is_empty():cancel();return
	var step: float = previous.position.distance_to(hit.position)
	if step<(.06 if final and leg>0 else maxf(.025,leg)):return
	var record := Strip.anchor(hit)
	# A missing ray or a sudden large jump (dense sampling) - or a leg something crosses (leg sampling) -
	# starts a fresh patch. Dragging over empty air must not paint an invisible bridge through another exhibit.
	if drag_gap or (step>.45 if leg<=0 else _leg_blocked(previous,hit)):
		record.break_before = true;drag_gap = false
	else:
		if drag_length+step>minf(remaining,max_span):_status("STRIPE LIMIT / RELEASE");return
		drag_length += step
	drag_points.append(record)
	if worn_on!=null and worn_on.has_method("trigger_haptic_pulse"):worn_on.trigger_haptic_pulse("haptic",0.0,.03,.2,0.0)
	leg_added.emit(drag_points.size())

func _leg_blocked(a: Dictionary,hit: Dictionary) -> bool:
	var query := PhysicsRayQueryParameters3D.create(a.position+a.normal*.012,hit.position+hit.normal*.012,SURFACES)
	query.exclude = [get_rid(),a.body.get_rid(),hit.collider.get_rid()]
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _release_fire(_who = null) -> void:
	if not pressed:return
	pressed = false
	if not drag_eligible:return
	_sample_drag(_aim(),true)
	if drag_points.size()>1 and drag_length>=.06:
		segments = segments.filter(func(segment):return is_instance_valid(segment) and not segment.is_queued_for_deletion())
		if segments.size()>=max_strips:_refuse("ROLL EMPTY / TIDY TO RESET");cancel();return
		var strip := Strip.new();strip.name = "TapeStripe";get_tree().current_scene.add_child(strip)
		strip.tape_width = _width()*_tape_scale();strip.material_override = tape_material;strip.print_max_px = print_max_px
		strip.anchors = drag_points.duplicate();strip.paid_length = drag_length;strip.issuer = weakref(self)
		if bind_objects:strip.bind_surfaces()
		if _prints():   # a stroke prints too; it is drawn (and printed) on its next physics frame
			var first := Strip.resolve(drag_points[0]);var last := Strip.resolve(drag_points[-1])
			if not first.is_empty() and not last.is_empty():strip.print_source = printer(strip,first.body,last.body,segments.size()+1);_set_reader(strip)
		segments.append(strip);remaining -= drag_length;tape_placed.emit(strip);start_anchor = {};preview.hide();_status("CLICK START")
	elif leg>0 and not start_anchor.is_empty():_status("TAP END / HOLD + MOVE")   # a tap that did not move a leg: the start stays, the next tap is the end
	drag_eligible = false;drag_points.clear()

## What a printed strip says. The two bodies and the number are fixed when it is laid; the length,
## heading, slope and whether it still holds are read again each time the strip is redrawn, so a
## plank carried away with tape on it changes what the tape says.
func printer(strip: Node3D,from_body: Node,to_body: Node,number: int) -> Callable:
	_dress_print(strip)
	var mode: String = str(design.get("print",{}).get("mode",print_mode)) if not design.is_empty() else print_mode
	if mode=="note":
		var words: String = (str(design.get("print",{}).get("note","")) if not design.is_empty() else note).strip_edges()
		return func(_a,_b,_length):return ("NOTE · "+words+" · ") if words!="" else "NOTE · "
	var from_name := thing_name(from_body);var to_name := thing_name(to_body);var same := from_body==to_body
	return func(a: Vector3,b: Vector3,length: float) -> String:
		var d := b-a;var flat := Vector2(d.x,d.z).length()
		var parts: Array[String] = ["%.2f M"%length]
		if length>d.length()+.05:parts.append("A STROKE %.2f M END TO END"%d.length())
		var bound := false
		for child in strip.get_children():
			if child.get_script()==Strip.Binding:bound = true
		if same:parts.append("ON "+from_name)
		elif strip.get("peeled"):parts.append("PEELED FROM "+from_name+" AND "+to_name)
		else:parts.append(("JOINS " if bound else "FROM ")+from_name+(" TO " if not bound else " AND ")+to_name)
		if flat<.05:parts.append("VERTICAL")
		else:
			var heading := fposmod(rad_to_deg(atan2(d.x,-d.z)),360.0)
			parts.append("HEADING "+["N","NE","E","SE","S","SW","W","NW"][int(round(heading/45.0))%8])
			var slope := rad_to_deg(atan2(d.y,flat))
			parts.append("LEVEL" if absf(slope)<3 else ("RISING %d°" if slope>0 else "FALLING %d°")%int(round(absf(slope))))
		parts.append("TAPE %d"%number)
		return " · ".join(PackedStringArray(parts))+" · "

func _width() -> float:
	return float(design.get("width",.075)) if not design.is_empty() else WIDTHS[TYPES.find(kind)]

## A strip's width follows a held roll's scale (a half-size roll lays half-width tape); a worn bangle is a
## picture of the roll, and lays the full width.
func _tape_scale() -> float:
	return 1.0 if worn_on!=null else absf(global_basis.get_scale().x)

## Held in a hand, or worn on one by the bracelet and in its PLACE mode.
func _active() -> bool:
	return is_picked_up() or (worn_on!=null and worn_active)

## WEAR: a bangle over the back of the hand, its axis along the forearm, `bangle` the size of the real roll;
## not grabbable, no collision, under the controller so it rides with it. Called again with the same controller
## it only shows itself; with another it moves over.
func wear(ctrl: Node3D,bangle := .4) -> void:
	cancel()
	if get_parent()!=ctrl:
		if get_parent()!=null:get_parent().remove_child(self)
		ctrl.add_child(self)   # _ready runs here on a fresh roll and sets its layers: ours come after
	enabled = false;collision_layer = 0;collision_mask = 0;freeze = true
	worn_on = ctrl;worn_active = true;visible = true
	transform = Transform3D(Basis().scaled(Vector3.ONE*bangle),Vector3(0,.045,.09))
	for child in get_children():
		if child is CollisionShape3D:child.disabled = true
	if preview!=null:preview.tape_width = _width()*_tape_scale()
	if readout!=null:readout.font_size = 32
	_status("HOLD + MOVE / TAP, TAP" if leg>0 else "CLICK START")

## Put away (another item chosen, or the bracelet out of PLACE): hidden and inert, strips kept.
func put_away() -> void:
	cancel();worn_active = false;visible = false;_hide_aim()

## The bracelet's trigger, pressed and let go, while the roll is worn.
func fire_worn() -> void:
	if worn_on!=null and worn_active:_fire()

func release_worn() -> void:
	if worn_on!=null:_release_fire()

## The last strip back onto the roll (the bracelet's grip when worn; the station's UNDO does the same). Returns it.
func undo_last() -> Node3D:
	segments = segments.filter(func(segment):return is_instance_valid(segment) and not segment.is_queued_for_deletion())
	if segments.is_empty():cancel();return null
	var strip: Node3D = segments.pop_back();remaining = minf(roll_length,remaining+strip.paid_length);cancel();strip.queue_free();return strip

## A knob turned while the roll is in use (the inventory's live config): the config again, and the skin and
## roll rebuilt when the kind or the design changed. The tape already laid keeps its skin.
func apply_config(config: Dictionary) -> void:
	var was := [kind,tape]
	apply_grid_config(config);remaining = minf(remaining,roll_length)
	if [kind,tape]!=was:
		design = Design.load_design(tape)
		tape_material = Design.material(design) if not design.is_empty() else _make_tape_material()
		for child in get_children():
			if child is CollisionShape3D or (child is MeshInstance3D and child.name in ["PaperAndCore","TapeSkin"]) or child==readout:remove_child(child);child.queue_free()
		_build_roll()
		if worn_on!=null:
			for child in get_children():
				if child is CollisionShape3D:child.disabled = true
			readout.font_size = 32
		preview.tape_width = _width()*_tape_scale()
		var ghost := tape_material.duplicate();ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;ghost.albedo_color.a = .48;preview.material_override = ghost
	cancel()

## Worn, the aim is a thin line from the hand to the dot: at 8 m a dot alone is lost.
func _draw_aim() -> void:
	if aim_line==null:
		aim_line = MeshInstance3D.new();aim_line.name = "AimLine";aim_line.mesh = ImmediateMesh.new();add_child(aim_line);aim_line.top_level = true
		var line_mat := StandardMaterial3D.new();line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED;line_mat.albedo_color = Color("ee478f",.55)
		line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;aim_line.material_override = line_mat
	aim_line.global_transform = Transform3D.IDENTITY
	var im: ImmediateMesh = aim_line.mesh;im.clear_surfaces();im.surface_begin(Mesh.PRIMITIVE_LINES);im.surface_add_vertex(_aim_from);im.surface_add_vertex(_aim_to);im.surface_end();aim_line.show()

func _hide_aim() -> void:
	if aim_line!=null:aim_line.hide()

## A strip prints when the roll is the printed kind, or wears a design that prints.
func _prints() -> bool:
	return kind=="printed" or (not design.is_empty() and str(design.get("print",{}).get("mode","none"))!="none")

## A design's print: its ink, on its own pattern as the paper.
func _dress_print(strip: Node3D) -> void:
	if design.is_empty():return
	strip.set("print_ink",Color(str(design.get("print",{}).get("ink","1d1d1f"))))
	strip.set("print_paper_texture",Design.print_paper(design,Strip.PRINT_PX))

## The print reads for whoever laid it: the head (the viewport's camera, in VR the headset) when it was committed.
func _set_reader(strip: Node3D) -> void:
	var head := get_viewport().get_camera_3d()
	if head!=null:strip.set("print_reader",head.global_position);strip.set("print_reader_set",true)

## A touched body's name as a person would say it: the artifact it belongs to (its registry token
## or scene), not the collider's node name.
static func thing_name(body: Node) -> String:
	var node := body
	for i in 8:
		if node==null:break
		for key in ["lookup_name","config_token","token","artifact"]:
			if node.has_meta(key) and str(node.get_meta(key))!="":return _humane(str(node.get_meta(key)))
		if node.scene_file_path!="":return _humane(node.scene_file_path.get_file().get_basename())
		node = node.get_parent()
	return _humane(str(body.name)) if body!=null else "?"

static func _humane(raw: String) -> String:
	var spaced := ""
	for i in raw.length():
		var c := raw[i]
		if i>0 and c==c.to_upper() and c!=c.to_lower() and raw[i-1]==raw[i-1].to_lower() and raw[i-1]!="_":spaced += " "
		spaced += c
	return spaced.replace("_"," ").strip_edges().to_upper()

func _refuse(reason: String) -> void:
	_status(reason);placement_refused.emit(reason)

func _status(message: String) -> void:
	if readout!=null:readout.text = (tape if not design.is_empty() else kind).to_upper()+" / %.1f m\n"%remaining+message

func cancel() -> void:
	start_anchor = {};pressed = false
	drag_points.clear();drag_eligible = false;drag_time = 0;drag_length = 0;drag_gap = false
	if preview!=null:preview.hide()
	if marker!=null:marker.hide()
	_status("HOLD + MOVE / TAP, TAP" if worn_on!=null and leg>0 else "CLICK START")

func clear_tape() -> void:
	cancel()
	for strip in segments:
		if is_instance_valid(strip):strip.queue_free()
	segments.clear();remaining = roll_length;_status("CLICK START")

func prepare_editor_preview() -> void:
	preview_only = true;cancel();freeze = true
