extends SceneTree
## THE WHITE PLAYGROUND AND ITS WINDMILLS ON A BENCH (2026-11-09). No tower, no floor index: the playground scenes are
## instantiated directly, with the config metas a Void placement would set (floor_content sets config_* before _ready).
##   A default (no key): the legacy bulky kit - box rods, socket joints, no edge overlay
##   B palette "white": slim fitted rods (r 7.5 cm) and whole-sphere joints (r 10 cm), the white finish, edge overlays
##     (also in the static batches); motion.tscn and connection.tscn too
##   C windmills: the replaced free rotors gone, the three windmills present, each grown from its dock corner joint,
##     hub at +2 m (x, z) / +1 m (y), turning about its own axis, paddle counts 3 / 2 / 2
##   D over a full turn no windmill shape touches any other playground body; the open side of each walkway stays clear
##     while the paddles sweep the other side
##   E NEGATIVE: the same X windmill on a 0.8 m stand must be caught sweeping through the deck
##   F the bench and glass box (display.tscn) draw the same white fitted parts with "palette": "white"; default unchanged
##   G a place spec with palette "white" compiles white; an unknown palette is refused
## Run: godot --headless --path . --xr-mode off --script res://tools/probes/playground_white_windmills.gd
##      (without --headless it also writes PNGs to ada_run/playground_white/)
const Fitted=preload("res://commons/artifacts/scaffold_workstation/fitted_geometry.gd")
const EdgeOutline=preload("res://commons/void/edge_outline.gd")
const Motion=preload("res://commons/modular/grid_motion.gd")
const Windmill=preload("res://commons/modular/windmill.gd")
const SIDE:="res://commons/modular/playgrounds/revolving-windmills.json"
var checks:Array=[]
var shots:=DisplayServer.get_name()!="headless"

func _initialize()->void:run.call_deferred()

func check(label:String,passed:bool,details:Variant="")->void:
	checks.append({"label":label,"passed":passed,"details":str(details)});print("PASS " if passed else "FAIL ",label," | ",details)

func make(scene:String,metas:Dictionary,at:=Vector3.ZERO)->Node3D:
	var n:Node3D=load(scene).instantiate()
	for k in metas:n.set_meta("config_"+k,metas[k])
	n.position=at;root.add_child(n);return n

func first_mesh(body:Node)->MeshInstance3D:
	for c in body.get_children():
		if c is MeshInstance3D and not c.name.begins_with(EdgeOutline.NAME):return c
	return null

func overlays(body:Node)->int:
	return body.get_children().filter(func(c):return c is MeshInstance3D and c.name.begins_with(EdgeOutline.NAME)).size()

func id_of(pg:Node3D,kind:String)->String:
	for p in pg.recipe.parts:
		if "parent" in p or p.motion.enabled or str(p.source)!="workshop_"+kind:continue
		return p.id
	return ""

func run()->void:
	var env:=WorldEnvironment.new();var e:=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("30343c")
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color("d8d2c8");e.ambient_light_energy=.75;env.environment=e;root.add_child(env)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-50,35,0);root.add_child(sun)
	var legacy:=make("res://commons/modular/playgrounds/revolving.tscn",{},Vector3(0,0,-40))
	var white:=make("res://commons/modular/playgrounds/revolving.tscn",{"palette":"white","windmills":true})
	var motion:=make("res://commons/modular/playgrounds/motion.tscn",{"palette":"white"},Vector3(40,0,0))
	var connection:=make("res://commons/modular/playgrounds/connection.tscn",{"palette":"white"},Vector3(80,0,0))
	var bad_spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SIDE))
	for w in bad_spec.windmills:
		if w.axis=="x":w.height=.8
	bad_spec.windmills=bad_spec.windmills.filter(func(w):return w.axis=="x")
	var negative:=make("res://commons/modular/playgrounds/revolving.tscn",{"palette":"white","windmills":bad_spec},Vector3(-40,0,0))
	for pg in [legacy,white,motion,connection,negative]:pg.running=false
	for i in 4:await physics_frame

	# A - default
	var rod_id:=id_of(legacy,"rod");var point_id:=id_of(legacy,"point")
	var lrod:=first_mesh(legacy.bodies[rod_id]);var lpoint:=first_mesh(legacy.bodies[point_id])
	var edges_default:=0
	for b in legacy.bodies.values():edges_default+=overlays(b)
	check("A default revolving keeps the legacy kit: box rod, socketed 18 cm joint, no edges, no windmills",
		lrod.mesh is BoxMesh and is_equal_approx(lrod.mesh.size.x,.15) and lpoint.mesh is SphereMesh and is_equal_approx(lpoint.mesh.radius,.18) and legacy.bodies[point_id].get_children().filter(func(c):return c is MeshInstance3D).size()>1 and edges_default==0 and lrod.material_override!=Fitted.white_finish() and legacy.bodies.has("bay-3-sweep") and not legacy.bodies.has("windmill-y-rotor"),
		"rod %s %.3f, joint r %.3f + %d sockets, overlays %d" % [lrod.mesh.get_class(),lrod.mesh.size.x if lrod.mesh is BoxMesh else 0.0,lpoint.mesh.radius,legacy.bodies[point_id].get_child_count()-2,edges_default])

	# B - white, slim
	for pair in [["revolving",white],["motion",motion],["connection",connection]]:
		var pg:Node3D=pair[1]
		var wrod:=first_mesh(pg.bodies[id_of(pg,"rod")]);var wpoint:=first_mesh(pg.bodies[id_of(pg,"point")]);var wquad:=first_mesh(pg.bodies[id_of(pg,"quad")])
		var meshes:=0;var whites:=0;var lines:=0
		for b in pg.bodies.values():
			for c in b.get_children():
				if c is MeshInstance3D and not c.name.begins_with(EdgeOutline.NAME):
					meshes+=1;whites+=int(c.material_override==Fitted.white_finish())
			lines+=overlays(b)
		var batched_lines:int=pg.batches.filter(func(m):return m.material_override==EdgeOutline.line_material()).size()
		check("B %s white: fitted rod r 0.075, whole sphere r 0.10, white on every mesh, edges on rods/quads, batched" % pair[0],
			wrod.mesh is CylinderMesh and is_equal_approx(wrod.mesh.top_radius,.075) and wpoint.mesh is SphereMesh and is_equal_approx(wpoint.mesh.radius,.1) and wpoint.get_child_count()==0 and whites==meshes and lines>=pg.recipe.parts.filter(func(p):return str(p.source) in ["workshop_rod","workshop_quad"]).size() and batched_lines>0 and wquad.material_override==Fitted.white_finish(),
			"rod %s r %.4f, joint r %.3f, white %d/%d meshes, %d edge overlays, %d line batches" % [wrod.mesh.get_class(),wrod.mesh.top_radius if wrod.mesh is CylinderMesh else 0.0,wpoint.mesh.radius,whites,meshes,lines,batched_lines])

	# C - windmills
	var gone:=["bay-0-rotor","bay-2-rotor","bay-3-sweep","bay-3-sweep-002-rod"].filter(func(id):return white.bodies.has(id))
	check("C the free rotors the windmills replace are gone (bay-1/bay-4 Y quads kept)",gone.is_empty() and white.bodies.has("bay-1-rotor") and white.bodies.has("bay-4-rotor"),"left: %s" % [gone])
	var side:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SIDE))
	for w in side.windmills:
		var hub:Node3D=white.bodies.get(w.id+"-rotor")
		var corner:Node3D=white.bodies.get(w.corner_part)
		if hub==null or corner==null:check("C %s exists" % w.id,false,"hub %s corner %s" % [hub,corner]);continue
		var rise:float=hub.position.y-corner.position.y
		var expect:float=1.0 if w.axis=="y" else 2.0
		var base:Node3D=white.bodies[w.id+"-stand-"+("mast" if w.axis=="y" else "post-0")]
		var foot:Vector3=base.position-Vector3.UP*(.5 if w.axis=="y" else 1.0)
		var paddles:int=white.bodies.keys().filter(func(k):return str(k).begins_with(w.id+"-rotor-paddle")).size()
		var b0:Basis=hub.transform.basis
		white.apply_time(float(w.period)/4.0)
		var q:Quaternion=(hub.transform.basis*b0.inverse()).get_rotation_quaternion()
		var turned:Vector3=q.get_axis()*signf(q.get_angle())
		var axis:Vector3=Windmill.axis_vector(w.axis)
		white.apply_time(0)
		var horizontal:=Vector2(hub.position.x-corner.position.x,hub.position.z-corner.position.z).length()
		check("C %s: on corner %s, hub +%.2f m (want %.0f), turns about %s (%.0f deg in a quarter period), %d paddles" % [w.id,w.corner_part,rise,expect,w.axis,rad_to_deg(q.get_angle()),paddles],
			foot.distance_to(corner.position)<.001 and absf(rise-expect)<.001 and absf(absf(turned.dot(axis))-1)<.001 and absf(rad_to_deg(q.get_angle())-90)<.5 and paddles==int(w.paddles) and absf(horizontal-(0.0 if w.axis=="y" else 1.0))<.001,
			"foot-to-corner %.4f m, hub offset %.2f m across, axis %s" % [foot.distance_to(corner.position),horizontal,turned])

	# D - the sweep never meets the structure; the open side of each walkway stays clear
	var hits:=await sweep_hits(white,side.windmills)
	check("D over a full turn (72 poses) no windmill shape touches any other part of the playground",hits.is_empty(),"hits: %s" % [hits.slice(0,6)])
	var open_side:={"windmill-x":[7.4,2.2],"windmill-z":[14.75,9.5],"windmill-y":[14.0,11.1]}
	var swept_side:={"windmill-x":[7.4,0.9],"windmill-z":[16.0,9.5],"windmill-y":[14.1,12.2]}
	for w in side.windmills:
		var clear:=await capsule_hits(white,w,open_side[w.id]);var swept:=await capsule_hits(white,w,swept_side[w.id])
		check("D %s: a body on the open side of the walkway is never touched; on the swept side it is (%d of 72 poses)" % [w.id,swept],clear==0 and swept>0,"open %d / swept %d" % [clear,swept])

	# E - negative
	var bad:=await sweep_hits(negative,bad_spec.windmills)
	check("E NEGATIVE: the X windmill on a 0.8 m stand is caught sweeping through the structure",not bad.is_empty(),"%d hits, e.g. %s" % [bad.size(),bad.slice(0,3)])

	# F - the editors
	var bench_white:=make("res://commons/artifacts/scaffold_workstation/display.tscn",{"palette":"white","persist":false,"space":true,"space_floor":20},Vector3(0,0,40))
	var bench_plain:=make("res://commons/artifacts/scaffold_workstation/display.tscn",{"persist":false,"space":true,"space_floor":20},Vector3(30,0,40))
	await physics_frame
	var rod:={"kind":"rod","at":[0,0,0],"end":[1,0,0]}
	var vw:MeshInstance3D=bench_white.visual(rod,2.0);var vp:MeshInstance3D=bench_plain.visual(rod,2.0)
	var sw:Shape3D=bench_white.shape_for(rod,2.0);var sp:Shape3D=bench_plain.shape_for(rod,2.0)
	check("F glass box + bench with palette white draw the fitted white rod with edges; without it the legacy box rod",
		vw.mesh is CylinderMesh and vw.material_override==Fitted.white_finish() and vw.get_node_or_null(EdgeOutline.NAME)!=null and sw is CylinderShape3D and vp.mesh is BoxMesh and vp.get_node_or_null(EdgeOutline.NAME)==null and sp is BoxShape3D,
		"white: %s/%s, default: %s/%s" % [vw.mesh.get_class(),sw.get_class(),vp.mesh.get_class(),sp.get_class()])
	vw.free();vp.free()

	# G - place spec palette
	var Builder=load("res://commons/modular/places/place_builder.gd")
	var place:={"id":"place","at":[0,0],"y":2,"size":[6,6],"depth":0,"type":"plate","rim":1,"access":{"outer":"ramp","inner":"level"}}
	var spec:={"version":1,"units":"metres","palette":"white","places":[place]}
	var built:Dictionary=Builder.new().compile(spec)
	var whites:=0;var total:=0
	if built.has("recipe"):
		for p in built.recipe.parts:total+=1;whites+=int(p.get("workshop_palette","")=="white" and p.get("workshop_profile","")=="fitted")
	var refused:Dictionary=Builder.new().compile({"version":1,"units":"metres","palette":"pink","places":[place]})
	check("G place_spec palette white: every part white + fitted, recipe appearance white; palette pink refused",
		total>0 and whites==total and built.recipe.appearance.get("palette","")=="white" and "Unknown structural palette" in refused.get("errors",[]),
		"%d/%d parts, errors on pink: %s, on white: %s" % [whites,total,refused.get("errors",[]).slice(0,2),built.get("errors",[]).slice(0,2)])

	if shots:await photograph(white,legacy,bench_white)
	var passed:=checks.filter(func(c):return c.passed).size()
	print("playground_white_windmills %d/%d" % [passed,checks.size()])
	var out:=ProjectSettings.globalize_path("res://ada_run/playground_white");DirAccess.make_dir_recursive_absolute(out)
	var f:=FileAccess.open(out.path_join("report.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks},"  "));f.close()
	quit(0 if passed==checks.size() else 1)

func windmill_of(node:Node)->String:
	var id:=str(node.get_meta("grid_part",""))
	var m:=id.find("-stand");if m<0:m=id.find("-rotor")
	return id.substr(0,m) if id.begins_with("windmill") and m>0 else ""

## Every (windmill shape, other playground body) contact over one full turn of each windmill.
func sweep_hits(pg:Node3D,mills:Array)->Array:
	var hits:Array=[]
	var space:=pg.get_world_3d().direct_space_state
	for step in 72:
		for w in mills:
			pg.apply_time(float(w.period)*step/72.0)
			await physics_frame
			for id in pg.bodies:
				if not str(id).begins_with(w.id+"-rotor"):continue
				var body:Node3D=pg.bodies[id]
				for shape in body.get_children():
					if not shape is CollisionShape3D:continue
					var q:=PhysicsShapeQueryParameters3D.new();q.shape=shape.shape;q.transform=body.global_transform*shape.transform;q.collision_mask=0xFFFFFFFF
					for hit in space.intersect_shape(q,16):
						var other:Node=hit.collider
						if other.get_meta("grid_owner",0)!=pg.get_instance_id() or windmill_of(other)==str(w.id):continue
						var tag:="%s x %s" % [id,other.get_meta("grid_part","?")]
						if not tag in hits:hits.append(tag)
	pg.apply_time(0)
	return hits

## How many of 72 poses put one of this windmill's shapes into a standing body (capsule r .26, 1.82 m) on the deck.
func capsule_hits(pg:Node3D,w:Dictionary,at:Array)->int:
	var capsule:=CapsuleShape3D.new();capsule.radius=.26;capsule.height=1.82
	var foot:Vector3=pg.to_global(Motion.point([at[0],4.22,at[1]],pg.recipe.grid))
	var q:=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.transform=Transform3D(Basis.IDENTITY,foot+Vector3.UP*.91);q.collision_mask=0xFFFFFFFF
	var count:=0
	for step in 72:
		pg.apply_time(float(w.period)*step/72.0)
		await physics_frame
		for hit in pg.get_world_3d().direct_space_state.intersect_shape(q,32):
			if windmill_of(hit.collider)==str(w.id) and str(hit.collider.get_meta("grid_part","")).contains("-rotor"):count+=1;break
	pg.apply_time(0)
	return count

func photograph(white:Node3D,legacy:Node3D,bench:Node3D)->void:
	var out:=ProjectSettings.globalize_path("res://ada_run/playground_white");DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1600,1000)
	var cam:=Camera3D.new();cam.fov=55;root.add_child(cam);cam.make_current()
	white.apply_time(2.0);legacy.apply_time(2.0)
	var views:=[
		["revolving_white_overview",white,Vector3(-2,15,18),Vector3(0,3,0)],
		["revolving_legacy_overview",legacy,Vector3(-2,15,18),Vector3(0,3,0)],
		["windmill_x",white,Vector3(-5.5,7.5,-11.5),Vector3(-1.6,5.4,-6.0)],
		["windmill_z",white,Vector3(12.5,7.5,0.5),Vector3(7.4,5.4,3.0)],
		["windmill_y",white,Vector3(2.5,6.9,10.0),Vector3(5.4,4.8,6.0)]]
	for v in views:
		var host:Node3D=v[1]
		cam.global_position=host.to_global(v[2]);cam.look_at(host.to_global(v[3]))
		for i in 6:await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join(v[0]+".png"))
		print("PNG ",out.path_join(v[0]+".png"))
