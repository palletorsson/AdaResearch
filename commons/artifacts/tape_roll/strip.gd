extends MeshInstance3D
## Endpoints live in each touched body's frame, including non-uniform scale.
## Marks on one body; reversible native constraints between separate bodies.
const Binding := preload("binding.gd")
var anchors: Array[Dictionary] = []
var tape_width := 0.05
var paid_length := 0.0
var issuer: WeakRef
var cached: Array = []
var peeled := false
## Printed tape: `print_source(a, b)` returns the phrase for the strip as it lies now. It is drawn in 2D
## (a Label in a SubViewport, repeated along the strip) and that picture is the strip's own skin: the
## ribbon's UV runs in metres, so the print lies on the tape wherever the tape goes. Redrawn only when
## the words or the length change.
const PRINT_PX := 96
var print_max_px := 8192   # the picture's width at most; the roll sets it (its print_max_px)
var print_source: Callable
var print_ink := Color("1d1d1f")
var print_paper := Color("efe9dc")
## a design's pattern, one repeat at the print's scale: tiled under the words instead of the plain paper
var print_paper_texture: Texture2D
var printed := ""
## where the person who laid it stood: on a floor the print turns to read for them (a wall reads upright)
var print_reader := Vector3.ZERO
var print_reader_set := false
var _print_view: SubViewport
var _print_label: Label
var _print_skin: StandardMaterial3D
var _print_state: Array = []

static func anchor(hit: Dictionary) -> Dictionary:
	var body: Node3D = hit.collider
	return {"body":weakref(body),"point":body.to_local(hit.position),
		"normal":body.global_basis.transposed()*Vector3(hit.normal)}

static func resolve(record: Dictionary) -> Dictionary:
	var body = record.body.get_ref()
	if not is_instance_valid(body) or not body.is_inside_tree():return {}
	return {"position":body.to_global(record.point),
		"normal":(body.global_basis.inverse().transposed()*Vector3(record.normal)).normalized(),"body":body}

func _physics_process(_delta: float) -> void:
	if anchors.size()<2:return
	for record in anchors:
		if not is_instance_valid(record.body.get_ref()):
			print("TAPE_ORPHAN / removed endpoint body");queue_free();return
	if anchors.size()>2:
		var points: Array[Dictionary] = []
		for record in anchors:
			var point := resolve(record)
			if point.is_empty() or not point.body.is_visible_in_tree():hide();return
			point.break_before = record.get("break_before",false);points.append(point)
		show();draw_path(points);return
	var a := resolve(anchors[0]);var b := resolve(anchors[1])
	# XRTools may transiently reparent a live body while switching grab frames.
	if a.is_empty() or b.is_empty():visible = false;return
	if not a.body.is_visible_in_tree() or not b.body.is_visible_in_tree():visible = false;return
	visible = true
	draw_between(a.position,a.normal,b.position,b.normal)

func bind_surfaces() -> void:
	var seen: Dictionary = {}
	for i in range(1,anchors.size()):
		if anchors[i].get("break_before",false):continue
		var a := resolve(anchors[i-1]);var b := resolve(anchors[i])
		if a.is_empty() or b.is_empty() or a.body==b.body:continue
		if not a.body is PhysicsBody3D or not b.body is PhysicsBody3D:continue
		if not a.body is RigidBody3D and not b.body is RigidBody3D:continue
		var key := str(mini(a.body.get_instance_id(),b.body.get_instance_id()))+":"+str(maxi(a.body.get_instance_id(),b.body.get_instance_id()))
		if seen.has(key):continue
		seen[key] = true
		var binding := Binding.new();add_child(binding);binding.peeled.connect(func():peeled = true);binding.connect_bodies(a.body,b.body,(a.position+b.position)*.5)

func draw_path(points: Array[Dictionary]) -> void:
	visible = points.size()>1
	var state: Array = [tape_width,peeled]
	for point in points:state.append_array([point.position,point.normal,point.get("break_before",false)])
	if cached==state:return
	cached = state
	var tool := SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);var distance := 0.0;var count := 0
	for i in range(1,points.size()):
		if points[i].get("break_before",false):continue
		if peeled and i==maxi(1,points.size()/2):continue
		var a: Vector3 = points[i-1].position;var b: Vector3 = points[i].position
		var axis := b-a;var length := axis.length()
		if length<.001:continue
		axis /= length
		var na: Vector3 = points[i-1].normal;var nb: Vector3 = points[i].normal
		var wa := na.cross(axis).normalized();var wb := nb.cross(axis).normalized()
		if wa.length()<.5:wa = Vector3.UP.cross(axis).normalized()
		if wa.length()<.5:wa = Vector3.RIGHT.cross(axis).normalized()
		if wb.length()<.5:wb = wa
		if wa.dot(wb)<0:wb = -wb
		a += na*.004;b += nb*.004;wa *= tape_width*.5;wb *= tape_width*.5
		var vertices := [a-wa,a+wa,b-wb,a+wa,b+wb,b-wb]
		var uvs := [Vector2(distance,0),Vector2(distance,1),Vector2(distance+length,0),Vector2(distance,1),Vector2(distance+length,1),Vector2(distance+length,0)]
		for k in 6:
			tool.set_normal(global_basis.transposed()*(na if k in [0,1,3] else nb));tool.set_uv(uvs[k]);tool.add_vertex(to_local(vertices[k]))
		distance += length;count += 1
	if count>0:mesh = tool.commit()
	if print_source.is_valid() and count>0:lay_print(points[0].position,points[0].normal,points[-1].position,points[-1].normal,distance)

func draw_between(a: Vector3,na: Vector3,b: Vector3,nb: Vector3) -> void:
	var next: Array = [a,na,b,nb,tape_width,peeled]
	if cached==next:return
	cached = next
	var axis := b-a;var length := axis.length()
	if length<0.001:visible = false;return
	visible = true;axis /= length
	var wa := na.cross(axis).normalized();var wb := nb.cross(axis).normalized()
	if wa.length()<.5:wa = Vector3.UP.cross(axis).normalized()
	if wa.length()<.5:wa = Vector3.RIGHT.cross(axis).normalized()
	if wb.length()<.5:wb = wa
	if wa.dot(wb)<0:wb = -wb
	var vertices := PackedVector3Array();var normals := PackedVector3Array();var uv := PackedVector2Array();var indices := PackedInt32Array()
	for i in range(9):
		var t := float(i)/8.0;var normal := na.lerp(nb,t).normalized()
		if normal.length()<.5:normal = na
		var width_axis := wa.lerp(wb,t).normalized()*tape_width*.5
		var center := a.lerp(b,t)+normal*.004
		for side in [-1.0,1.0]:
			vertices.append(to_local(center+width_axis*side));normals.append(global_basis.transposed()*normal);uv.append(Vector2(t*length,(side+1)*.5))
		if i>0 and not (peeled and i==5):
			var k := i*2;indices.append_array(PackedInt32Array([k-2,k-1,k,k-1,k+1,k]))
	var arrays := [];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices;arrays[Mesh.ARRAY_NORMAL] = normals;arrays[Mesh.ARRAY_TEX_UV] = uv;arrays[Mesh.ARRAY_INDEX] = indices
	var ribbon := ArrayMesh.new();ribbon.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);mesh = ribbon
	if print_source.is_valid():lay_print(a,na,b,nb)

## The print, drawn in 2D: the phrase repeated as many whole times as the strip holds (a short strip keeps
## whole items, cut at a separator), ink on the tape's paper, in a SubViewport whose picture is the strip's
## skin over its whole length. On a wall the picture is turned to read upright.
func lay_print(a: Vector3,na: Vector3,b: Vector3,nb: Vector3,along := -1.0) -> void:
	var length := along if along>0 else a.distance_to(b)   # a stroke: its own length, the picture spans it all
	var phrase: String = str(print_source.call(a,b,length)).to_upper()
	var axis := (b-a).normalized();var mid := na.lerp(nb,.5);var face := (mid-axis*mid.dot(axis)).normalized()
	var up := face.cross(axis)   # where the tops of the letters point, unturned
	var flip := up.y<0 if absf(face.y)<.7 else (print_reader_set and up.dot(a.lerp(b,.5)-print_reader)<0)
	var state := [phrase,snappedf(length,.005),flip,tape_width]
	if state==_print_state:return
	_print_state = state
	var wide := clampi(int(round(length/tape_width*PRINT_PX)),PRINT_PX,print_max_px)
	var font: Font = ThemeDB.fallback_font;var size := int(PRINT_PX*.56);var room := wide-PRINT_PX*.6
	var width_of := func(t: String) -> float:return font.get_string_size(t,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	var count := int(floor(room/maxf(width_of.call(phrase),1.0)))
	var text := phrase.repeat(count).strip_edges() if count>=1 else ""
	if count<1:   # too short for the whole phrase: the most whole items that fit
		var items := phrase.split(" · ",false)
		for k in range(items.size(),0,-1):
			var candidate := " · ".join(items.slice(0,k)).strip_edges()
			if width_of.call(candidate)<=room:text = candidate;break
	printed = text
	if _print_view==null:
		_print_view = SubViewport.new();_print_view.name = "PrintView";_print_view.disable_3d = true;_print_view.transparent_bg = false
		var paper: Control
		if print_paper_texture!=null:
			var tiled := TextureRect.new();tiled.texture = print_paper_texture;tiled.stretch_mode = TextureRect.STRETCH_TILE;tiled.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;paper = tiled
		else:
			var plain := ColorRect.new();plain.color = print_paper;paper = plain
		paper.name = "Paper";_print_view.add_child(paper)
		_print_label = Label.new();_print_label.name = "Print";_print_view.add_child(_print_label)
		_print_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;_print_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(_print_view)
		_print_skin = (material_override as StandardMaterial3D).duplicate() if material_override is StandardMaterial3D else StandardMaterial3D.new()
		_print_skin.albedo_color = Color.WHITE;_print_skin.cull_mode = BaseMaterial3D.CULL_DISABLED
		_print_skin.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		material_override = _print_skin
	_print_view.size = Vector2i(wide,PRINT_PX)
	var paper_rect: Control = _print_view.get_node("Paper");paper_rect.position = Vector2.ZERO;paper_rect.size = Vector2(wide,PRINT_PX)   # explicit: a preset anchor keeps a zero rect here
	_print_label.text = text;_print_label.add_theme_font_size_override("font_size",size);_print_label.add_theme_color_override("font_color",print_ink)
	_print_label.position = Vector2.ZERO;_print_label.size = Vector2(wide,PRINT_PX);_print_label.pivot_offset = Vector2(wide,PRINT_PX)*.5
	_print_label.rotation = PI if flip else 0.0
	_print_view.render_target_update_mode = SubViewport.UPDATE_ONCE
	# the ribbon's u runs in metres from A, its v from the side the width axis subtracts: one picture
	# over the whole length, turned over in v so the print is not mirrored
	_print_skin.albedo_texture = _print_view.get_texture()
	_print_skin.uv1_scale = Vector3(1.0/maxf(length,.001),-1,1);_print_skin.uv1_offset = Vector3(0,1,0)
