extends SceneTree
const Forms=preload("res://commons/artifacts/camera_glitch_study/receivers.gd")
var checks:Array=[]
var failures:Array=[]
func check(label:String,ok:bool)->void:
	checks.append({"name":label,"passed":ok})
	if not ok:failures.append(label)
	print("CAMERA ","PASS " if ok else "FAIL ",label)
func _initialize()->void:run.call_deferred()
func run()->void:
	var f=Forms.new()
	check("ten named, explained operations",Forms.TITLES.size()==10 and Forms.NOTES.size()==10)
	for mode in 10:
		var valid:=true;var neutral:=true
		for a in [0.0,.5,1.0]:
			var arrays:Array=f.build(mode,a).surface_get_arrays(0)
			var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var uv:PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
			valid=valid and vertices.size()<=13824 and vertices.size()%3==0 and uv.size()==vertices.size()
			for i in vertices.size():
				valid=valid and vertices[i].is_finite() and uv[i].is_finite() and vertices[i].length()<3 and uv[i].x>=-.00001 and uv[i].x<=1.00001 and uv[i].y>=-.00001 and uv[i].y<=1.00001
				if a==0:neutral=neutral and vertices[i].distance_to(Vector3((uv[i].x-.5)*3.2,(.5-uv[i].y)*1.8,0))<.00001
		check("mode %d: finite, bounded geometry and UV addresses"%mode,valid)
		check("mode %d: zero returns geometry and UV to rectangle"%mode,neutral)
	var addresses:Dictionary={}
	for tile in 24:
		var sample:=Vector2((tile%6+.5)/6.0,(floori(tile/6.0)+.5)/4.0)
		var mapped:Vector2=f.source_uv(5,sample,1,tile)
		addresses[Vector2i(floori(mapped.x*6),floori(mapped.y*4))]=true
	check("tile shuffle visits every source tile exactly once",addresses.size()==24)
	check("first shuffled tile reads source tile five",f.source_uv(5,Vector2(1.0/12,1.0/8),1,0).distance_to(Vector2(11.0/12,1.0/8))<.00001)
	var seam:=true
	for i in 21:
		var t:=float(i)/20
		seam=seam and f.location(9,Vector2(0,t),1).distance_to(f.location(9,Vector2(1,t),1))<.00001
		seam=seam and f.location(9,Vector2(t,0),1).distance_to(f.location(9,Vector2(t,1),1))<.00001
	check("torus closes both geometric seams",seam)
	check("torus has a real hole of radius .63m",f.location(9,Vector2(0,.5),1).distance_to(Vector3(0,0,.63))<.00001)
	check("strips separate at a shared row boundary",f.location(0,Vector2(.5,.5),1,7).distance_to(f.location(0,Vector2(.5,.5),1,8))>.1)
	check("curl preserves the vertical coordinate",is_equal_approx(f.location(4,Vector2(.8,.2),1).y,.54))
	check("production scene loads",load("res://commons/artifacts/camera_glitch_study/CameraGlitchStudy.tscn")!=null)
	var dest:=OS.get_cmdline_user_args()[0]
	var file:=FileAccess.open(dest,FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"passed":failures.is_empty()},"  "));file.close()
	quit(0 if failures.is_empty() else 1)
