extends SceneTree
const DIR:="res://doc/book/iterations/2026-10-09-shape-grammar-a-face-continues/"
const Family=preload("res://commons/artifacts/form_grammar_family/form_grammar_family.gd")
var checks:Array=[]
var failures:Array=[]
func _initialize() -> void:run.call_deferred()
func check(title:String,ok:bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok:failures.append(title)
	print("SHAPE ","PASS " if ok else "FAIL ",title)
func settle() -> void:
	for i in 3:await physics_frame
	await process_frame
func agree(a:Dictionary,b:MeshData) -> bool:
	if a.vertices.size()!=b.vertices.size() or a.faces.size()!=b.faces.size():return false
	for i in a.vertices.size():
		if not a.vertices[i].is_equal_approx(b.vertices[i]):return false
	for i in a.faces.size():
		if a.faces[i]!=b.faces[i]:return false
		if a.tags[i]!="seed" and not b.face_tags[i].has(a.tags[i]):return false
	return true
func bounds(d:Dictionary) -> AABB:
	var box:=AABB(d.vertices[0],Vector3.ZERO)
	for p in d.vertices:box=box.expand(p)
	return box
func closed(d:Dictionary) -> bool:
	var edges:Dictionary={}
	for f in d.faces:
		for i in 3:
			var a:int=f[i];var b:int=f[(i+1)%3];var key:=Vector2i(mini(a,b),maxi(a,b))
			edges[key]=edges.get(key,0)+1
	return edges.values().all(func(n):return n==2) and d.vertices.size()-edges.size()+d.faces.size()==2
func key(study:Node,code:int) -> void:
	var e:=InputEventKey.new();e.keycode=code;e.pressed=true;study._unhandled_key_input(e)
func run() -> void:
	var host:=Node3D.new();host.position=Vector3(4,0,2);host.rotation.y=.7;root.add_child(host)
	var study=load(DIR+"printed/family.gd").new();host.add_child(study);await settle()
	check("Printed program constructs mesh readout and inherited point",study.record.accepted and study.record.faces.size()==12 and study.body.mesh!=null and study.point.has_method("pick_up"))
	check("Seed has eight vertices and selected top8and9",study.record.vertices.size()==8 and study.record.tags[8]=="growing" and study.record.tags[9]=="growing" and study.record.tags.count("growing")==2)
	var all_match:=true;var all_closed:=true;var rendered:=true;var counts:Array=[];var comparisons:=0
	for i in 6:
		study.show_recipe(i);var reference:MeshData=Family.build_data(Family.RECIPES[i])
		all_match=all_match and agree(study.record,reference);comparisons+=1
		all_closed=all_closed and closed(study.record)
		counts.append(study.record.faces.size())
		var arrays=study.body.mesh.surface_get_arrays(0)
		rendered=rendered and arrays[Mesh.ARRAY_VERTEX].size()==study.record.faces.size()*3 and arrays[Mesh.ARRAY_COLOR].size()==arrays[Mesh.ARRAY_VERTEX].size()
	check("Six complete meshes match source vertices indices and roles",all_match)
	check("Gallery counts12,24,36,84,84,444",counts==[12,24,36,84,84,444])
	check("All six have two faces per edge and Euler characteristic2",all_closed)
	check("Printed renderer emits every triangle and colour",rendered)
	for rounds in 4:
		for amount in [.08,.28,.6]:
			for selection in ["up","all"]:
				var chosen:Array=[8,9] if selection=="up" else range(12)
				var ours:Dictionary=study.model.build({"faces":chosen,"rounds":rounds,"amount":amount})
				var source:MeshData=Family.build_data({"selection":selection,"rounds":rounds,"amount":amount})
				all_match=all_match and agree(ours,source);comparisons+=1
	check("Additional24 recipes match complete source mesh",all_match and comparisons==30)
	study.show_recipe(1)
	check("Inset stays within unchanged cube bounds",bounds(study.record).is_equal_approx(AABB(Vector3.ONE*-.5,Vector3.ONE)))
	study.show_recipe(3);var narrow:Dictionary=study.record.duplicate(true)
	study.show_recipe(4)
	check("Amount changes tip area without changing total height",is_equal_approx(bounds(study.record).end.y,bounds(narrow).end.y) and not study.record.vertices[study.record.vertices.size()-1].is_equal_approx(narrow.vertices[narrow.vertices.size()-1]))
	check("Three rounds retain only two growing tips",narrow.tags.count("growing")==2 and narrow.tags.count("shoulder")==36 and narrow.tags.count("wall")==36)
	var recipe:Dictionary=study.RECIPES[3].duplicate(true);var retained:Dictionary=study.model.build(recipe);recipe.faces.clear();recipe.amount=.08
	check("Result keeps independent input recipe",retained.recipe.faces==[8,9] and retained.recipe.amount==.28)
	check("Duplicate and out-of-range seed indices refused",not study.model.build({"faces":[8,8],"rounds":1,"amount":.28}).accepted and not study.model.build({"faces":[12],"rounds":1,"amount":.28}).accepted)
	check("Unbounded rounds refused",not study.model.build({"faces":[8],"rounds":4,"amount":.28}).accepted)
	var tiny:Dictionary=study.model.build({"faces":[8,9],"rounds":1,"amount":.99})
	check("Tiny tips skip extrusion so requested round need not rise",tiny.faces.size()==24 and is_equal_approx(bounds(tiny).end.y,.5))
	check("Tiny-tip guard agrees with source",agree(tiny,Family.build_data({"selection":"up","rounds":1,"amount":.99})));comparisons+=1
	var variant=load(DIR+"variation/family.gd").new();host.add_child(variant);variant.show_recipe(3)
	check("Full edited program grows only face8 and totals48",variant.record.recipe.faces==[8] and variant.record.faces.size()==48 and variant.record.tags.count("growing")==1)
	var seed_top_stays:=false
	for f in variant.record.faces:
		if f==PackedInt32Array([3,6,7]):seed_top_stays=true
	check("Unselected top triangle remains at seed positions",seed_top_stays and variant.record.vertices[3].is_equal_approx(Vector3(-.5,.5,.5)))
	var saved:Dictionary=variant.record.duplicate(true);variant.show_recipe(0);variant.show_recipe(3)
	check("Edited recipe reconstructs same complete result",saved==variant.record)
	var wrong_order=load(DIR+"wrong_order/faces.gd").new()
	check("Test detects ascending-removal fault",not agree(wrong_order.build(study.RECIPES[2]),Family.build_data(Family.RECIPES[2])))
	var wrong_tag=load(DIR+"wrong_tag/faces.gd").new()
	check("Test detects shoulders inheriting growing tag",wrong_tag.build(study.RECIPES[2]).tags.count("growing")!=2)
	key(study,KEY_R);await settle();key(study,KEY_SPACE)
	check("Keyboard advances then resets",study.index==1);key(study,KEY_R)
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=study.point.global_position;study.point.pick_up(pickup);await settle();controller.global_position+=Vector3(.2,.2,0);await settle()
	check("Moving carried point leaves the recipe unchanged",study.index==0 and study.point.is_picked_up())
	study.point.action();await settle();check("Held trigger advances exactly one recipe",study.index==1 and study.record.faces.size()==24)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await settle()
	check("Release parks on translated rotated host",not study.point.held() and study.point.position.is_equal_approx(Vector3(0,1.15,2.2)))
	for i in 5:study.advance()
	check("Six-step cycle returns to untouched cube",study.index==0 and study.record.faces.size()==12)
	FileAccess.open(DIR+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"source_comparisons":comparisons,"scope":"Author-led exact printed code, full edited program, two faults, native mesh comparison and supplied XRTools poses. Not independent student or headset."},"  "))
	origin.queue_free();host.queue_free();await settle();quit(0 if failures.is_empty() else 1)
