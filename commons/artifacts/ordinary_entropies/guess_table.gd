extends Node3D
## One guess, then one uniform ID draw. Moving a chair does not change its category.
const Model = preload("guess_model.gd")
const Objects = preload("objects.gd")
const Controls = preload("study_controls.gd")
const Carrier = preload("res://commons/artifacts/entropy_sorting_table/sorting_cube.gd")
const PhysicalChair = preload("physical_chair.gd")
var baseline: Array = [8,8,0]
var movable := false
var floor_mode := false
var cohort := "A"
var title := "A / TWO TYPES"
var model = Model.new()
var chairs: Array[Node3D] = []
var markers: Array[Node3D] = []
var buttons: Dictionary = {}
var reading: Label3D
var result: Label3D
var message := "Which type comes next? Choose a guess, then DRAW."

func _ready() -> void:
	model.configure(baseline)
	if not floor_mode:Objects.table(self,2.8,2.2)
	# A low, horizontal rail puts the caps within reach while keeping the
	# miniature chair backs above it. No shin-height vertical controls.
	var face := Node3D.new()
	var rail_z:=2.0 if floor_mode else 1.42
	face.name="TableControlStrip";face.position=Vector3(0,0.86,rail_z)
	face.rotation_degrees.x=-90;add_child(face)
	for x in [-1.2,1.2]:
		Objects.box(self,Vector3(x,0.43,rail_z),Vector3(0.035,0.86,0.035),Objects.DARK)
	var control_back := Objects.box(face,Vector3.ZERO,Vector3(2.8,0.60,0.045),Color("e9e5d9"),true)
	control_back.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	Objects.ink(face,title,Vector3(0,0.25,0.03),27,0.0015)
	reading=Objects.ink(face,"",Vector3(0,0.155,0.03),25,0.0015)
	result=Objects.ink(face,"",Vector3(0,0.045,0.03),24,0.0014)
	Objects.ink(face,"TOUCH A CAP  /  OR POINT + TRIGGER",Vector3(0,-0.275,0.03),18,0.0013)
	var names: Array[String]=["PINK","BLACK"]
	var actions: Array[Callable]=[choose.bind(0),choose.bind(1)]
	if baseline[2]>0:names.append("BLACK+ARMS");actions.append(choose.bind(2))
	names.append("DRAW");actions.append(draw)
	if baseline[0]<16:names.append("CHANGE ONE");actions.append(change_one)
	names.append("RESET");actions.append(reset_table)
	for i in names.size():
		var x: float=(i-(names.size()-1)*0.5)*0.43
		buttons[names[i]]=Controls.button(face,Vector3(x,-0.10,0.04),names[i],actions[i],names[i]=="DRAW")
	buttons["PINK"].released_color=Objects.PINK
	buttons["BLACK"].released_color=Color("414851")
	if buttons.has("BLACK+ARMS"):buttons["BLACK+ARMS"].released_color=Color("414851")
	build_chairs()
	refresh()

func site(i: int) -> Vector3:
	if floor_mode:
		# A stepped pyramid of 9 + 4 + 2 + 1 chairs. Upper feet land on
		# lower seats; their backrests stay clear. Physics decides what holds.
		# Armchairs start at the four lower corners, clear of upper legs.
		if baseline[2]>0:i=[1,3,4,5,7,9,10,11,12,13,14,15,0,2,6,8][i]
		if i<9:return Vector3((i%3-1)*0.5,0.01,(i/3-1)*0.5)
		if i<13:return Vector3(((i-9)%2-0.5)*0.5,0.51,((i-9)/2-0.5)*0.5)
		if i<15:return Vector3((i-13-0.5)*0.46,1.01,0)
		return Vector3(0,1.51,0.05)
	return Vector3((i%4-1.5)*0.57,0.75,(i/4-1.5)*0.48)

func build_chairs() -> void:
	for old in chairs:remove_child(old);old.free()
	chairs.clear();markers.clear()
	for i in 16:
		var holder: Node3D=PhysicalChair.new() if floor_mode else (Carrier.new() if movable else Node3D.new())
		holder.name="Chair"+str(i+1)
		var category: int=int(model.categories[i])
		if floor_mode:
			holder.colour=Objects.PINK if category==0 else Objects.DARK
			holder.variant=1 if category==2 else 0
			holder.chair_id=i;holder.cohort=cohort
		else:
			var furniture:=Objects.chair(holder,Vector3.ZERO,Objects.PINK if category==0 else Objects.DARK,1 if category==2 else 0)
			furniture.scale=Vector3.ONE*0.5
			for child in furniture.get_children():
				if child is StaticBody3D:furniture.remove_child(child);child.free()
		var ring:=MeshInstance3D.new();var torus:=TorusMesh.new()
		torus.inner_radius=0.18;torus.outer_radius=0.20;torus.rings=24;torus.ring_segments=8
		if floor_mode:torus.inner_radius=0.34;torus.outer_radius=0.37
		ring.mesh=torus;ring.material_override=Objects.material(Color("c39736"));ring.position.y=0.013
		holder.add_child(ring);markers.append(ring)
		if movable and not floor_mode:
			holder.cube_id=i;holder.freeze=true;holder.release_mode=1;holder.gravity_scale=0
			holder.collision_layer=6;holder.collision_mask=0;holder.ranged_grab_method=2
			var collision:=CollisionShape3D.new();collision.name="CollisionShape3D"
			var shape:=BoxShape3D.new();shape.size=Vector3(0.30,0.48,0.28)
			collision.shape=shape;collision.position.y=0.235;holder.add_child(collision)
			holder.placement_requested.connect(func(body):settle.call_deferred(body))
		holder.position=site(i);add_child(holder);chairs.append(holder)

func settle(body: Node3D) -> void:
	# Keep the experiment on its own tabletop; a released chair stays upright and can turn.
	var yaw: float=body.rotation.y
	body.position=Vector3(clampf(body.position.x,-1.22,1.22),0.75,clampf(body.position.z,-0.91,0.91))
	body.rotation=Vector3(0,yaw,0);body.freeze=true
	body.linear_velocity=Vector3.ZERO;body.angular_velocity=Vector3.ZERO
	message="Places and turns changed. The colour answer stays pink."
	refresh()

func any_held() -> bool:
	if not movable:return false
	for chair in chairs:
		if chair.held():return true
	return false

func refresh() -> void:
	var values: Dictionary=model.readings()
	var c: Array=values.counts
	reading.text="%d pink / %d black%s  |  best %.1f%%\nH-min %.3f bits   /   Shannon %.3f bits" % [c[0],c[1],(" / %d black+arms" % c[2]) if baseline[2]>0 else "",values.best*100,values.min,values.shannon]
	for i in markers.size():markers[i].visible=i==model.selected
	result.text=message
	for key in ["PINK","BLACK","BLACK+ARMS"]:
		if buttons.has(key):buttons[key].set_selected(model.guess==["PINK","BLACK","BLACK+ARMS"].find(key))

func choose(category: int) -> void:
	model.choose(category)
	message="Guess: %s. DRAW selects one chair ID; then returns it." % Model.CATEGORY_NAMES[category]
	refresh()

func draw() -> void:
	if not model.draw():message="Choose PINK or BLACK%s before DRAW." % ("+ARMS" if baseline[2]>0 else "")
	else:
		var category: int=int(model.categories[model.selected])
		message="Draw %d: chair %d, %s. %s. Returned." % [model.draws,model.selected+1,Model.CATEGORY_NAMES[category],"MATCH" if category==model.guess else "different"]
	refresh()

func change_one() -> void:
	if any_held():message="Release the chair before CHANGE ONE.";refresh();return
	var kept:=capture()
	if model.change_one():
		build_chairs()
		if floor_mode:apply_poses(kept.poses)
		message="One black chair becomes pink. Places stay; predict again."
	else:message="All sixteen are pink. RESET restores this group's beginning."
	refresh()

func reset_table() -> void:
	if any_held():message="Release the chair before RESET.";refresh();return
	model.reset();build_chairs();message="Beginning restored. Which type comes next? Choose, then DRAW."
	refresh()

func capture() -> Dictionary:
	if any_held():return {}
	var poses: Array=[]
	for chair in chairs:
		if floor_mode:
			poses.append([chair.position.x,chair.position.y,chair.position.z,chair.rotation.x,chair.rotation.y,chair.rotation.z,chair.linear_velocity.x,chair.linear_velocity.y,chair.linear_velocity.z,chair.angular_velocity.x,chair.angular_velocity.y,chair.angular_velocity.z,chair.sleeping])
		else:poses.append([chair.position.x,chair.position.y,chair.position.z,chair.rotation.y])
	if floor_mode:return {"schema":"one-guess-floor/2","model":model.capture(),"poses":poses,"cohort":cohort,"units":"metres-radians-world-velocity"}
	return {"schema":"one-guess-table/1","model":model.capture(),"poses":poses,"movable":movable}

func restore(record: Variant) -> bool:
	if floor_mode:return restore_floor(record)
	if any_held() or not record is Dictionary or record.get("schema")!="one-guess-table/1" or record.get("movable")!=movable:return false
	var restored=Model.new()
	if not restored.restore(record.get("model")) or restored.baseline!=baseline:return false
	var poses: Variant=record.get("poses")
	if not poses is Array or poses.size()!=16:return false
	for p in poses:
		if not p is Array or p.size()!=4:return false
		for value in p:
			if not (value is float or value is int) or not is_finite(value):return false
		if absf(p[0])>1.22 or not is_equal_approx(p[1],0.75) or absf(p[2])>0.91:return false
	model=restored;build_chairs()
	for i in 16:chairs[i].position=Vector3(poses[i][0],poses[i][1],poses[i][2]);chairs[i].rotation.y=poses[i][3]
	message="Restored category record, places and next seeded draw.";refresh()
	return true

func apply_poses(poses: Array) -> void:
	for i in 16:
		var p: Array=poses[i]
		chairs[i].position=Vector3(p[0],p[1],p[2]);chairs[i].rotation=Vector3(p[3],p[4],p[5])
		chairs[i].linear_velocity=Vector3(p[6],p[7],p[8]);chairs[i].angular_velocity=Vector3(p[9],p[10],p[11]);chairs[i].sleeping=p[12]

func restore_floor(record: Variant) -> bool:
	if any_held() or not record is Dictionary or record.get("schema")!="one-guess-floor/2" or record.get("cohort")!=cohort or record.get("units")!="metres-radians-world-velocity":return false
	var restored=Model.new()
	if not restored.restore(record.get("model")) or restored.baseline!=baseline:return false
	var poses: Variant=record.get("poses")
	if not poses is Array or poses.size()!=16:return false
	for p in poses:
		if not p is Array or p.size()!=13 or not p[12] is bool:return false
		for j in 12:
			if not (p[j] is float or p[j] is int) or not is_finite(p[j]):return false
		if absf(p[0])>128 or absf(p[2])>128 or p[1]<-20 or p[1]>64:return false
		for j in range(3,12):
			if absf(p[j])>64:return false
	model=restored;build_chairs();apply_poses(poses)
	message="Restored this group's poses, motion and next seeded draw.";refresh()
	return true
