extends Node3D
## A separate large-place draft; small hand-model records and built state stay intact.
const Builder=preload("res://commons/modular/places/place_builder.gd")
const Receiver=preload("res://commons/modular/places/parameterized_place.gd")
const Spec=preload("res://commons/modular/places/place_spec.gd")
const SAVE="user://playground_place.json"
var work:Node3D
var place:Dictionary={"id":"place","at":[0,0],"y":4,"size":[8,8],"depth":1,"type":"plastic_pool","rim":1,"access":{"outer":"ramp","inner":"ramp"}}
var labels:Dictionary={}
var miniature:Node3D
var compiled:Dictionary={}
var active:=false
var preview_dirty:=false

func configure(owner:Node3D)->void:
	work=owner
	# A left-side console leaves the operating plate and visor dock unobstructed.
	position=Vector3(-1.57,1.24,.45)
	work.Kit.box(self,"Board",Vector3.ZERO,Vector3(.94,1.08,.035),Color("273d48"),false)
	work.Kit.box(self,"Stand",Vector3(0,-.88,-.04),Vector3(.055,.70,.06),Color("8fcacc"),false)
	work.Kit.box(self,"Foot",Vector3(0,-1.21,-.04),Vector3(.45,.035,.30),Color("8fcacc"),false)
	var fields=["height","width","length","depth","type","access","mode"]
	for i in fields.size():
		var key:String=fields[i];var y:=.43-i*.14
		labels[key]=work.Kit.label(self,"",Vector3(0,y,.025),14)
		labels[key].modulate=Color("eef6f1")
		for direction in [-1,1]:
			var button:Node3D=work.Furniture.rectangular_button(work.ButtonScene)
			button.position=Vector3(direction*.38,y,.04);button.rotation.x=PI/2
			button.released_color=Color("8fcacc");button.pressed.connect(func():adjust(key,direction));add_child(button)
			work.Kit.label(self,"−" if direction<0 else "+",Vector3(direction*.38,y,.10),18)
	if work.persist and FileAccess.file_exists(SAVE):
		var saved=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
		if saved is Dictionary and Spec.validate({"version":1,"units":"metres","places":[saved]}).is_empty():place=saved
	refresh_labels()
	set_process(false)

func document()->Dictionary:return {"version":1,"units":"metres","places":[place.duplicate(true)]}

func set_place(value:Dictionary)->void:
	if work.visit.active or is_instance_valid(work.held):return
	place=value.duplicate(true);refresh_labels();schedule_preview()

func adjust(key:String,step:int)->void:
	if not work._interactive:return
	if work.visit.active or is_instance_valid(work.held):work.feedback.text="Return from the model and release the tool before changing the place.";return
	if key=="mode":set_mode(not active);return
	if key in ["width","length"]:
		var axis:=0 if key=="width" else 1
		place.size[axis]=clampi(int(place.size[axis])+step*2,4,20)
	elif key=="height":
		place.y=clampi(int(place.y)+step,0,12)
		place.access.outer="level" if place.y==0 else ("ramp" if place.access.outer=="level" else place.access.outer)
	elif key=="depth":place.depth=0 if place.type=="plate" else clampi(int(place.depth)+step,1,3)
	elif key=="type":
		var choices=["plate","plastic_pool","steel_pool"]
		place.type=choices[posmod(choices.find(place.type)+step,choices.size())]
		place.depth=0 if place.type=="plate" else maxi(1,int(place.depth))
		place.access.inner="level" if place.type=="plate" else "ramp"
	elif key=="access":
		if place.y==0:place.access.outer="level"
		else:place.access.outer="tc" if place.access.outer=="ramp" else "ramp"
	if not active:set_mode(true)
	refresh_labels();schedule_preview()

func refresh_labels()->void:
	labels.height.text="HEIGHT  %dm"%place.y
	labels.width.text="WIDTH  %dm"%place.size[0]
	labels.length.text="LENGTH  %dm"%place.size[1]
	labels.depth.text="POOL DEPTH  %dm"%place.depth
	labels.type.text=str(place.type).replace("_"," ").to_upper()
	labels.access.text="ACCESS  "+str(place.access.outer).to_upper()
	labels.mode.text="PLACE PARAMETERS" if active else "ELEMENT TOOLS"

func set_mode(value:bool)->void:
	if work.visit.active or is_instance_valid(work.held):return
	active=value;work.set_meta("place_mode",active)
	work.drawing.visible=not active;work.sockets.visible=not active
	for tool in work.tools.values():tool.visible=not active
	work.lock_other_pieces(null)
	if is_instance_valid(miniature):miniature.visible=active
	refresh_labels()
	if active:schedule_preview()
	else:work.feedback.text="ELEMENT TOOLS / grab stock, paint near sockets, or use REMOVE."

func schedule_preview()->void:
	preview_dirty=true;set_process(true)

func _process(_delta:float)->void:
	set_process(false)
	if not preview_dirty:return
	preview_dirty=false
	var result:Dictionary=Builder.new().compile(document())
	if not result.errors.is_empty():
		compiled={};work.feedback.text=str(result.errors[0])
		if is_instance_valid(miniature):miniature.hide()
		return
	compiled=result.recipe
	if work.persist:FileAccess.open(SAVE,FileAccess.WRITE).store_string(JSON.stringify(place,"  "))
	if is_instance_valid(miniature):miniature.free()
	var b:Array=compiled.places[0].bounds
	var scale_factor:float=.62/maxf(float(b[3]),float(b[5]))
	miniature=Node3D.new();miniature.set_script(Receiver);miniature.recipe=compiled.duplicate(true)
	miniature.embedded_study=true;miniature.running=false;miniature.scale=Vector3.ONE*scale_factor
	miniature.position=Vector3(.1-(b[0]+b[3]*.5)*scale_factor,-.20,.1-(b[2]+b[5]*.5)*scale_factor)
	work.bench.add_child(miniature)
	work.disable_collisions(miniature)
	for lift in miniature.lifts:lift.prepare_editor_preview()
	miniature.visible=active
	work.feedback.text="PLACE READY / BUILD MODEL, then wear the visor. Floor at %dm."%(place.y-place.depth)

func build_copy()->bool:
	if work.visit.active or is_instance_valid(work.held) or not work._interactive:return false
	if preview_dirty:_process(0)
	if compiled.is_empty():work.feedback.text="Correct the place parameters before building.";return false
	var b:Array=compiled.places[0].bounds
	var factor:float=work.model_scale
	var bounds:=AABB(Vector3(b[0],b[1],b[2])*factor,Vector3(b[3],b[4],b[5])*factor)
	if bounds.size.x>work.CLEAR-.2 or bounds.size.z>work.CLEAR-.4 or bounds.end.y>work.chamber_height-.35:
		work.feedback.text="This place exceeds the glass room. Reduce its dimensions or use the web full-size trial.";return false
	var offset:=Vector3(-(b[0]+b[3]*.5)*factor,0,-(b[2]+b[5]*.5)*factor)
	bounds.position+=offset
	if work.START_CLEARANCE.intersects(bounds):work.feedback.text="The place would occupy START. Reduce its length.";return false
	var next:=Node3D.new();next.set_script(Receiver);next.recipe=compiled.duplicate(true);next.embedded_study=true;next.running=false
	next.scale=Vector3.ONE*factor;next.position=offset;work.output.add_child(next)
	var exclusions:Array[RID]=[]
	for body in next.find_children("*","CollisionObject3D",true,false):exclusions.append(body.get_rid())
	for body in work.output.get_node("Structure").find_children("*","CollisionObject3D",true,false):exclusions.append(body.get_rid())
	var blocked:=false
	for collision in next.find_children("*","CollisionShape3D",true,false):
		if collision.disabled or not collision.get_parent() is PhysicsBody3D:continue
		var box:AABB=collision.global_transform*collision.shape.get_debug_mesh().get_aabb()
		var query:=PhysicsShapeQueryParameters3D.new();var shape:=BoxShape3D.new();shape.size=box.size
		query.shape=shape;query.transform=Transform3D(Basis.IDENTITY,box.get_center());query.exclude=exclusions;query.collision_mask=7
		for hit in work.get_world_3d().direct_space_state.intersect_shape(query,8):
			if hit.collider.get_parent().name=="GlassBase" and box.position.y>=work.output.global_position.y-.30:continue
			if work.foundation_contact(hit.collider,box):continue
			if seated_ground(hit.collider,box):continue
			print("PLACE_BUILD_BLOCKED ",hit.collider.get_path()," / ",box)
			blocked=true;break
		if blocked:break
	if blocked:next.free();work.feedback.text="Build space is occupied. Clear it before rebuilding.";return false
	if is_instance_valid(work.test_ball):work.test_ball.free()
	work.test_active=false;work.clear_children(work.output.get_node("Structure"))
	next.reparent(work.output.get_node("Structure"),true)
	for lift in next.lifts:lift.platform.move_speed*=factor;lift.rebase()
	work.built=[{"place":place.duplicate(true)}]
	work.feedback.text="PLACE BUILT / wear the visor to enter. Parameters change only the draft until BUILD."
	return true

func seated_ground(body:Node,bounds:AABB)->bool:
	# Flush shaft landing boards are also host ground. Keep the same shallow,
	# datum-checked allowance; raised obstacles and ordinary props still block.
	if not body.get_meta("void_structural_slab",false) and not body.get_meta("void_landing_pad",false):return false
	var y:float=work.output.global_position.y
	if bounds.position.y<y-.30 or bounds.end.y>y+.08:return false
	for child in body.get_children():
		if child is CollisionShape3D:
			var slab:AABB=child.global_transform*child.shape.get_debug_mesh().get_aabb()
			if absf(slab.end.y-y)<=.10:return true
	return false
