extends Node3D
## @identity
## essence: one stored elementary-CA history, read at two scales
## desire: make a tabletop decision alter the architecture around its operator
## needs: a ca_rule_explorer on this floor; no independent automaton or clock
## truth: the monumental pattern is the consequence of the small local rule.
const Mount = preload("res://commons/void/ceiling_display_mount.gd")
var source: Node3D
var cells: MultiMesh
var caption: Label3D
var rendered: Array = []
var signature := ""
var elapsed := 0.0
var primed := false
func _ready() -> void:
	var steel := Mount.material("20252b",.38,.7)
	var cream := Mount.material("e7e3db",.72)
	var pink := Mount.material("ef69af",.42,.15)
	Mount.box(self,"Back",Vector3(0,2.72,-.07),Vector3(15.7,4.0,.14),steel)
	var solid := StaticBody3D.new();solid.name = "SolidFrame";add_child(solid)
	shape(solid,Vector3(0,2.72,-.07),Vector3(15.7,4.0,.14))
	for x in [-8.05,8.05]:
		Mount.box(self,"Upright",Vector3(x,2.8,0),Vector3(.14,5.6,.18),steel)
		Mount.box(self,"Foot",Vector3(x,.08,0),Vector3(.65,.16,1.05),steel)
		shape(solid,Vector3(x,2.8,0),Vector3(.14,5.6,.18))
		shape(solid,Vector3(x,.08,0),Vector3(.65,.16,1.05))
		Mount.box(self,"CeilingShoe",Vector3(x,5.55,0),Vector3(.65,.1,.45),cream)
		for z in [-.3,.3]:Mount.box(self,"AnchorBolt",Vector3(x,.18,z),Vector3(.045,.04,.045),cream)
	for y in [.65,4.78]:Mount.box(self,"Crossbar",Vector3(0,y,0),Vector3(16.3,.12,.18),steel)
	Mount.box(self,"SignalBar",Vector3(0,.46,.08),Vector3(15.7,.035,.035),pink)
	cells = MultiMesh.new();cells.transform_format = MultiMesh.TRANSFORM_3D;cells.use_colors = true;cells.instance_count = 32*24
	var tile := BoxMesh.new();tile.size = Vector3(.46,.145,.045);cells.mesh = tile
	var view := MultiMeshInstance3D.new();view.name = "SharedHistory";view.multimesh = cells
	var finish := StandardMaterial3D.new();finish.vertex_color_use_as_albedo = true;finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	view.material_override = finish;view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(view)
	caption = Label3D.new();caption.name = "SourceReadout";caption.position = Vector3(0,5.04,.12)
	caption.font_size = 52;caption.pixel_size = .003;caption.outline_size = 0;caption.modulate = Color("ffe7f1");add_child(caption)
	set_meta("void_preview_kind","Live receiver of the same 32 by 24 stored CA rows as the original desk; no second solver. Initial 23 generations are computed by that original solver.")
	refresh()
func shape(body: StaticBody3D, at: Vector3, size: Vector3) -> void:
	var collider := CollisionShape3D.new();var box := BoxShape3D.new();box.size = size
	collider.shape = box;collider.position = at;body.add_child(collider)
func _process(delta: float) -> void:
	elapsed += delta
	if elapsed>=.1:elapsed = 0;refresh()
func find_source() -> Node3D:
	var floor_root: Node = get_parent()
	while floor_root!=null and not floor_root.has_meta("void_content_floor"):floor_root = floor_root.get_parent()
	if floor_root==null:return null
	var id: String = str(get_meta("config_source_id",""))
	for host in floor_root.get_children():
		var work: Node = host.get_node_or_null("Artifact")
		if work!=null and work.get_meta("artifact_lookup_name","")=="ca_rule_explorer" and (id.is_empty() or str(host.name)==id):return work
	return null
func refresh() -> void:
	if not is_instance_valid(source):source = find_source()
	if source==null:
		caption.text = "CONNECT A CA RULE EXPLORER ON THIS FLOOR";return
	if not primed:
		primed = true
		if source.generation==0:
			for i in 23:source.step()
	var next := "%d:%d:%s:%d"%[source.generation,source.rule,source.seed_pair,source.sample_cell]
	if next==signature:return
	signature = next;rendered = source._grid.duplicate(true);rendered.reverse()
	for row in 24:
		for col in 32:
			var present: bool = row<rendered.size()
			var alive: bool = present and bool(rendered[row][col])
			var color := Color("ef69af") if alive else Color("252b35")
			if present and col==source.sample_cell:color = Color("fff3d5") if alive else Color("654b70")
			cells.set_instance_transform(row*32+col,Transform3D(Basis(),Vector3((col-15.5)*.48,4.56-row*.16,.035)))
			cells.set_instance_color(row*32+col,color if present else Color("11161d"))
	caption.text = "RULE %d  /  SAME 32 ADDRESSES  /  GENERATIONS %d–%d\nSTEP AT THE DESK · THE ROOM KEEPS THE RECORD"%[source.rule,source.generation-rendered.size()+1,source.generation]
