extends Node3D
## @identity
## essence: one depth slice through the original 26-neighbour address, at body scale
## desire: make occluded neighbours countable without inventing a second automaton
## needs: the original StructureStudy on this floor; all nine addresses stay visible
## truth: a cell counts its neighbours, not the apparent density of the sculpture.
const Mount = preload("res://commons/void/ceiling_display_mount.gd")
const Source = preload("res://commons/void/ca_receiver_source.gd")
const ADDRESS := Vector3i(26,22,24)
var source: Node3D
var depth := 0
var cells: MultiMesh
var caption: Label3D
var rendered := PackedInt32Array()
var signature := ""
var elapsed := 0.0
func _ready() -> void:
	depth = clampi(int(get_meta("config_depth",0)),-1,1)
	var steel := Mount.material("20252b",.38,.7)
	var cream := Mount.material("e7e3db",.72)
	var pink := Mount.material("ef69af",.42,.15)
	var gold := Mount.material("ffd77d",.5,.15)
	var solid := StaticBody3D.new();solid.name = "SolidFrame";add_child(solid)
	part(solid,"Back",Vector3(0,2.72,-.2),Vector3(5.7,4.6,.16),steel)
	for x in [-2.95,2.95]:
		part(solid,"Upright",Vector3(x,2.75,0),Vector3(.12,5.5,.16),steel)
		part(solid,"Foot",Vector3(x,.08,0),Vector3(.55,.16,1.0),steel)
		Mount.box(self,"SlabShoe",Vector3(x,5.56,0),Vector3(.55,.1,.38),cream)
		for z in [-.3,.3]:Mount.box(self,"AnchorBolt",Vector3(x,.18,z),Vector3(.045,.04,.045),cream)
	for y in [.4,5.04]:Mount.box(self,"Crossbar",Vector3(0,y,0),Vector3(6.02,.1,.18),steel)
	cells = MultiMesh.new();cells.transform_format = MultiMesh.TRANSFORM_3D;cells.use_colors = true;cells.instance_count = 9
	var cube := BoxMesh.new();cube.size = Vector3(1.16,1.16,.25);cells.mesh = cube
	var view := MultiMeshInstance3D.new();view.name = "NineRealAddresses";view.multimesh = cells
	var finish := StandardMaterial3D.new();finish.vertex_color_use_as_albedo = true;finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	view.material_override = finish;view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(view)
	for y in range(-1,2):
		for x in range(-1,2):
			var at := Vector3(x*1.55,2.72+y*1.38,.02)
			var witness := depth==0 and x==0 and y==0
			for side in [-1,1]:
				Mount.box(self,"AddressEdge",at+Vector3(0,side*.62,0),Vector3(1.28,.035,.06),gold if witness else cream)
				Mount.box(self,"AddressEdge",at+Vector3(side*.62,0,0),Vector3(.035,1.28,.06),gold if witness else cream)
	Mount.box(self,"SignalStrip",Vector3(0,.24,.05),Vector3(5.7,.035,.035),pink)
	caption = Label3D.new();caption.name = "SourceReadout";caption.position = Vector3(0,5.28,.12)
	caption.font_size = 48;caption.pixel_size = .0027;caption.outline_size = 0;caption.modulate = Color("ffe7f1");add_child(caption)
	set_meta("void_preview_kind","Nine real neighbourhood addresses from the original 50-cubed three-state solver. A static preview of a live receiver; outlines persist when empty.")
	refresh()
func part(body: StaticBody3D, title: String, at: Vector3, size: Vector3, finish: Material) -> void:
	Mount.box(self,title,at,size,finish)
	var collider := CollisionShape3D.new();var box := BoxShape3D.new();box.size = size
	collider.shape = box;collider.position = at;body.add_child(collider)
func _process(delta: float) -> void:
	elapsed += delta
	if elapsed>=.1:elapsed = 0;refresh()
func refresh() -> void:
	if not is_instance_valid(source):source = Source.find(self,"structure_growth")
	if source==null or not source.has_node("StructureStudy"):
		caption.text = "CONNECT THE THREE-STATE STUDY ON THIS FLOOR";return
	var study: Node3D = source.get_node("StructureStudy")
	var next := "%d:%s"%[source.generation,study.state_colours]
	if next==signature:return
	signature = next;rendered.clear()
	for y in range(-1,2):
		for x in range(-1,2):
			var i := (y+1)*3+x+1
			var address := ADDRESS+Vector3i(x,y,depth)
			var state: int = source.current_state[address.x+address.y*source.stride_y+address.z*source.stride_z]
			rendered.append(state)
			var color: Color = study.neighbour_room.colour_for(state,address)
			var basis := Basis.IDENTITY if state>0 else Basis.IDENTITY.scaled(Vector3.ZERO)
			cells.set_instance_transform(i,Transform3D(basis,Vector3(x*1.55,2.72+y*1.38,.04)))
			cells.set_instance_color(i,color)
	caption.text = "Z %d  /  GEN %d\n%s"%[ADDRESS.z+depth,source.generation,"GOLD: THE WITNESS ADDRESS" if depth==0 else "NINE OF THE SAME 27 ADDRESSES"]
func readback() -> Dictionary:
	return {"depth":depth,"states":Array(rendered),"source_id":str(get_meta("config_source_id","")),"generation":source.generation if is_instance_valid(source) else -1}
