extends Node3D
## Cosmetic suit under the existing inferred torso; sleeves follow tracked hands.
const Panels = preload("res://commons/artifacts/garment_cutting_table/suit_panels.gd")
const Cloth = preload("res://commons/artifacts/garment_cutting_table/cloth_record.gd")
const G = preload("res://commons/artifacts/jacquard_weaver/weave_geometry.gd")
var record: Dictionary = {}
var panels: Array[MeshInstance3D] = []
var sleeve_roots: Array[Node3D] = []

func _ready() -> void:
	for i in range(10):
		var panel := MeshInstance3D.new();panel.name=Panels.NAMES[i].replace(" ","_");panel.mesh=Panels.mesh(i)
		if i==4 or i==5:
			var holder:=Node3D.new();add_child(holder);holder.add_child(panel);sleeve_roots.append(holder)
		else: add_child(panel)
		panels.append(panel)
	var shirt := G.box(self,Vector3(0,-.23,-.18),Vector3(.115,.24,.015),G.material("eee3c9"))
	shirt.name="Shirt"
	# Supplied collar/lapels make the simplified panel construction read as a jacket.
	for side in [-1.0,1.0]:
		var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for p in [Vector3(side*.035,-.06,-.10),Vector3(side*.17,-.22,-.185),Vector3(side*.035,-.38,-.181)]:st.add_vertex(p)
		st.generate_normals()
		var lapel:=MeshInstance3D.new();lapel.mesh=st.commit();lapel.material_override=G.material("353139")
		lapel.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED;add_child(lapel)
	for y in [-.31,-.42,-.53]:
		G.box(self,Vector3(.01,y,-.173),Vector3(.014,.014,.016),G.material("bf9d65",.65))
	for side in [-1.0,1.0]:
		G.box(self,Vector3(side*.135,-1.45,-.055),Vector3(.18,.08,.29),G.material("26242b"))
	if record.is_empty():record=Cloth.sample("tartan")
	set_record(record)

func set_record(data: Dictionary) -> bool:
	if not Cloth.valid(data): return false
	record=data.duplicate(true)
	if panels.is_empty():return true
	var material := Cloth.material(record)
	for panel in panels:panel.material_override=material
	return true

func follow(left: Node3D, right: Node3D) -> void:
	for i in range(sleeve_roots.size()):
		var side := -1.0 if i==0 else 1.0
		var hand: Node3D=left if i==0 else right
		var start := Vector3(side*.28,-.16,0)
		var rest := Vector3(side*.06,-.53,0)
		var target := to_local(hand.global_position)-start if is_instance_valid(hand) else rest
		var b := Basis(Quaternion(rest.normalized(),target.normalized())) if target.length()>.01 else Basis.IDENTITY
		b=b.scaled(Vector3.ONE*clampf(target.length()/rest.length(),.4,1.5))
		sleeve_roots[i].transform=Transform3D(b,start-b*start)
