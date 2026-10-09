extends Node3D
## One production petal operation, retained at two physical scales.
## These are open triangle strips, not a closed shell or a growth simulation.
const Data = preload("res://commons/mesh_grammar/mesh_data.gd")
const Selector = preload("res://commons/mesh_grammar/mesh_selector.gd")
const Petals = preload("res://commons/mesh_grammar/operations/petal_splay_op.gd")
const LARGE_SCALE := 4.0
const PARAMS := {"count":6,"length":1.25,"width":0.52,"curl":0.38,"tilt":0.45,"segments":16,"twist":0.0}
var specimens: Dictionary = {}
var records: Array[Dictionary] = []

static func seed_face() -> MeshData:
 var cube: MeshData = Data.create_cube(0.5)
 var face: PackedInt32Array = cube.faces[8]
 var centre: Vector3 = cube.get_face_centroid(8)
 var verts: Array = []
 for index in face: verts.append(cube.vertices[index]-centre)
 return Data.from_arrays(verts,[[0,1,2]])

static func petal_data() -> MeshData:
 var result: MeshData = seed_face()
 var rule := Petals.new(Selector.all_faces(),PARAMS.duplicate(true))
 rule.apply(result)
 return result

func _ready() -> void:
 var seed: MeshData = seed_face()
 var flower: MeshData = petal_data()
 _specimen("seed_face",seed,Vector3(-4.3,0,3.6),1.0)
 _specimen("petals",flower,Vector3(4.3,0,3.6),1.0)
 # Reuse the same generated data, not another random draw or recipe.
 _specimen("canopy",flower,Vector3(0,0,-4),LARGE_SCALE)
 _plaque(Vector3(-4.3,0.20,5.0),3.8)
 _plaque(Vector3(4.3,0.20,5.0),3.8)
 _plaque(Vector3(0,0.20,0.95),5.4)
 _label("07 / ONE OF THE TWO",Vector3(-4.3,0.24,5.05),38)
 _label("The cube's top triangle, kept",Vector3(-4.3,0.09,5.05),25)
 _label("08 / ANOTHER OPERATION",Vector3(4.3,0.24,5.05),38)
 _label("Six curved strips added to that face",Vector3(4.3,0.09,5.05),25)
 _label("09 / THE SAME SURFACE, FOUR TIMES",Vector3(0,0.22,1.0),38)
 _label("Walk beneath. Find the open edges.",Vector3(0,0.06,1.0),26)

func _specimen(key: String, data: MeshData, at: Vector3, factor: float) -> void:
 var root := Node3D.new()
 root.name = key
 root.position = at
 root.scale = Vector3.ONE * factor
 add_child(root)
 # The seed triangle and the entire flower each keep this identical support.
 _cylinder(root,0.08,0.90,Vector3(0,0.45,0),Color("334653"))
 _cylinder(root,0.31,0.06,Vector3(0,0.03,0),Color("334653"))
 var body := MeshInstance3D.new()
 body.name = "Surface"
 body.position.y = 0.90
 for i in range(data.face_count()):
  var colour := Color("ef86ad")
  if i>0:
   var petal_index := int((i-1)/(2*int(PARAMS.segments)))
   var row := int((i-1)%(2*int(PARAMS.segments)))/2
   var amount := float(row)/float(PARAMS.segments)
   colour = [Color("a55e91"),Color("58b8b2"),Color("dbb578")][petal_index%3].lerp(Color("f3d2ca"),amount*0.65)
  data.face_metadata[i]["color"] = colour
 body.mesh = data.to_array_mesh({"face_colors":true})
 var material := StandardMaterial3D.new()
 material.vertex_color_use_as_albedo = true
 material.cull_mode = BaseMaterial3D.CULL_DISABLED
 material.roughness = 0.48
 material.metallic = 0.14
 body.material_override = material
 root.add_child(body)
 body.create_trimesh_collision()
 # An open, two-sided surface must collide from below as well as above.
 for child in body.get_children():
  if child is StaticBody3D:
   for collider in child.get_children():
    if collider is CollisionShape3D and collider.shape is ConcavePolygonShape3D:
     collider.shape.backface_collision = true
 _open_edges(body,data)
 specimens[key] = body
 var rendered_vertices: PackedVector3Array = body.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
 records.append({"id":key,"scale":factor,"position":[at.x,at.y,at.z],"seed_faces":1,"generated_faces":data.face_count(),"rendered_triangles":rendered_vertices.size()/3,"surface_origin_height":0.9*factor,"parameters":PARAMS.duplicate(true) if key!="seed_face" else {}})

func _open_edges(body: MeshInstance3D, data: MeshData) -> void:
 # Edge positions are welded for this outline; it never alters the surface.
 var edges: Dictionary = {}
 for face in data.faces:
  for j in range(3):
   var a: Vector3 = data.vertices[face[j]]
   var b: Vector3 = data.vertices[face[(j+1)%3]]
   if a.distance_squared_to(b)<0.0000001: continue
   var ka := str(a.snapped(Vector3.ONE*0.00001))
   var kb := str(b.snapped(Vector3.ONE*0.00001))
   var key := ka+"/"+kb if ka<kb else kb+"/"+ka
   if edges.has(key): edges[key].count += 1
   else: edges[key] = {"a":a,"b":b,"count":1}
 var mesh := ImmediateMesh.new()
 mesh.surface_begin(Mesh.PRIMITIVE_LINES)
 for edge in edges.values():
  if edge.count==1:
   mesh.surface_add_vertex(edge.a)
   mesh.surface_add_vertex(edge.b)
 mesh.surface_end()
 var wire := MeshInstance3D.new()
 wire.mesh = mesh
 var material := StandardMaterial3D.new()
 material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 material.albedo_color = Color("f8dbc0")
 wire.material_override = material
 wire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 body.add_child(wire)

func _cylinder(parent: Node3D, radius: float, height: float, at: Vector3, colour: Color) -> void:
 var node := MeshInstance3D.new()
 var mesh := CylinderMesh.new()
 mesh.top_radius = radius
 mesh.bottom_radius = radius
 mesh.height = height
 mesh.radial_segments = 24
 node.mesh = mesh
 node.position = at
 var material := StandardMaterial3D.new()
 material.albedo_color = colour
 material.roughness = 0.6
 node.material_override = material
 parent.add_child(node)
 node.create_trimesh_collision()

func _label(text: String, at: Vector3, font: int) -> void:
 var label := Label3D.new()
 label.text = text
 label.position = at
 label.font_size = font
 label.pixel_size = 0.003
 label.modulate = Color("efe4d8")
 label.outline_size = 0
 label.outline_modulate = Color("293746")
 add_child(label)

func _plaque(at: Vector3, width: float) -> void:
 var node := MeshInstance3D.new()
 var mesh := BoxMesh.new()
 mesh.size = Vector3(width,0.4,0.06)
 node.mesh = mesh
 node.position = at
 var material := StandardMaterial3D.new()
 material.albedo_color = Color("243343")
 material.roughness = 0.85
 node.material_override = material
 add_child(node)
