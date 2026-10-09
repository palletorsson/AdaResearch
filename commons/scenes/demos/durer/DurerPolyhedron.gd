@tool
extends MeshInstance3D
## A closed truncated rhombohedron: six planar pentagons, two equilateral caps.
## 72-degree rhombus faces and this truncation depth are an interpretive choice.
## The engraving does not uniquely determine its three-dimensional proportions.
@export var size: float = 1.0 : set = set_size
@export var material: Material : set = set_material
@export var rotate_slowly: bool = false
@export var rotation_speed: float = 0.1
var face_polygons: Array = []
var _time := 0.0

func set_size(value: float) -> void:
 size = maxf(value,0.001)
 if is_inside_tree():mesh = _generate_durer_solid()
func set_material(value: Material) -> void:
 material = value
 material_override = value
func _ready() -> void:
 mesh = _generate_durer_solid()
 if material:material_override = material
func _process(delta: float) -> void:
 if rotate_slowly and not Engine.is_editor_hint():
  _time += delta
  rotation.y = _time * rotation_speed
func _clip(poly: Array, limit: float, sign_y: float, cap: Array) -> Array:
 var result: Array = []
 for i in range(poly.size()):
  var a: Vector3 = poly[i]
  var b: Vector3 = poly[(i+1)%poly.size()]
  var inside_a := a.y*sign_y <= limit+0.00001
  var inside_b := b.y*sign_y <= limit+0.00001
  if inside_a:result.append(a)
  if inside_a != inside_b:
   var v := a.lerp(b,(limit*sign_y-a.y)/(b.y-a.y))
   result.append(v)
   var found := false
   for old: Vector3 in cap:
    if old.distance_to(v)<0.00001:found=true
   if not found:cap.append(v)
 return result
func _generate_durer_solid() -> ArrayMesh:
 var diagonal := Vector3.ONE.normalized()
 var cosine := cos(deg_to_rad(72.0))
 var stretch := sqrt((1.0+2.0*cosine)/(1.0-cosine))
 var align := Quaternion(diagonal,Vector3.UP)
 var vertices: Array[Vector3] = []
 for x in [-1,1]:
  for y in [-1,1]:
   for z in [-1,1]:
    var v := Vector3(x,y,z)
    vertices.append(align*(v+diagonal*(stretch-1.0)*v.dot(diagonal)))
 var height := stretch*sqrt(3.0)
 var cut := height-0.38*(2.0*stretch/sqrt(3.0))
 var top: Array = []
 var bottom: Array = []
 face_polygons.clear()
 for indices in [[0,1,3,2],[4,6,7,5],[0,4,5,1],[2,3,7,6],[0,2,6,4],[1,5,7,3]]:
  var poly: Array = []
  for index in indices:poly.append(vertices[index])
  poly = _clip(poly,cut,1.0,top)
  poly = _clip(poly,cut,-1.0,bottom)
  face_polygons.append(poly)
 for cap in [top,bottom]:
  cap.sort_custom(func(a:Vector3,b:Vector3)->bool:return atan2(a.z,a.x)<atan2(b.z,b.x))
  face_polygons.append(cap)
 var st := SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for poly: Array in face_polygons:
  for i in range(poly.size()):poly[i] *= (3.0*size/(2.0*cut))
  var centre := Vector3.ZERO
  for p: Vector3 in poly:centre+=p
  centre/=poly.size()
  var normal: Vector3 = (poly[1]-poly[0]).cross(poly[2]-poly[0]).normalized()
  if normal.dot(centre)<0:
   poly.reverse()
   normal=-normal
  for i in range(1,poly.size()-1):
   for v: Vector3 in [poly[0],poly[i+1],poly[i]]:
    st.set_normal(normal)
    st.add_vertex(v)
 return st.commit()
