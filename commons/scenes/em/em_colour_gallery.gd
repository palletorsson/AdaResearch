extends Node3D
## Optional finish for the eight authored Colour halls in the Endless Museum.
## Existing artifacts retain their scripts, receivers and interaction state.
const FINISH=preload("res://commons/scenes/em/colour_gallery.gdshader")
const IDENTITY=preload("res://commons/scenes/em/em_identity.gd")
const MATERIALS=preload("res://commons/scenes/em/em_materials.gd")
var grid: Node3D
var map_id: String
var stone: Material
var pale: Material
var pier_count:=0

static func install(source_grid: Node3D) -> void:
 if source_grid.has_node("ColourGallery"):return
 var path: String="res://commons/maps/%s/map_data.json" % source_grid.get("map_name")
 var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
 if doc.get("map_info",{}).get("museum",{}).get("gallery_finish","")!="colour_2026_10":return
 var gallery:=new()
 gallery.name="ColourGallery";gallery.grid=source_grid;gallery.map_id=source_grid.get("map_name")
 source_grid.add_child(gallery)
 gallery.build(doc)

func box(parent: Node3D, label: String, at: Vector3, size: Vector3, material: Material, solid:=false) -> MeshInstance3D:
 var n:=MeshInstance3D.new();n.name=label;n.position=at
 var mesh:=BoxMesh.new();mesh.size=size;n.mesh=mesh;n.material_override=material;parent.add_child(n,true)
 if solid:
  var body:=StaticBody3D.new();body.name="GalleryBoundary";n.add_child(body)
  var shape:=CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=size;body.add_child(shape)
 return n

func build(doc: Dictionary) -> void:
 stone=MATERIALS.gallery_white().duplicate()
 stone.albedo_color=Color("eeeae1");stone.roughness=0.65
 pale=MATERIALS.gallery_white()
 var mm: MultiMeshInstance3D=grid.get_node("GridMultiMesh")
 var mat:=ShaderMaterial.new();mat.shader=FINISH
 mat.set_shader_parameter("world_to_grid",grid.global_transform.affine_inverse())
 mat.set_shader_parameter("addressed_floor",map_id=="Color_Grid_Pallet")
 mm.material_override=mat
 var structure: Array=doc.layers.structure
 var w: int=doc.map_info.dimensions.width
 var depth: int=doc.map_info.dimensions.depth
 # Engaged columns stand at existing exterior walls, never across a doorway.
 for x in [0,w-1]:
  for z in range(4,depth-2,6):
   if int(str(structure[z][x]))<3:continue
   pier(Vector3(float(x)+(.30 if x==0 else -.30),.5,float(z)))
 # Existing identity typography, positioned against real grid walls.
 var faces: Array=[]
 for z in range(2,depth-2):
  if int(str(structure[z][0]))>=4:
   faces.append({"x":.515,"z":float(z),"along_x":false,"nx":1.0,"nz":0.0})
  if int(str(structure[z][w-1]))>=4:
   faces.append({"x":float(w)-1.515,"z":float(z),"along_x":false,"nx":-1.0,"nz":0.0})
 IDENTITY.install(grid,faces,[])
 # Local, restrained neutral fill; light-study rooms retain their own lights.
 if map_id not in ["Color_Flashlight","Color_Pillar"]:
  var centres: Array=[Vector3(w*.35,4.8,8),Vector3(w*.68,4.8,minf(depth-4,19))]
  if map_id=="Color_Context_Placed":centres=[Vector3(8,5.5,8),Vector3(15,5.5,25),Vector3(8,6.5,45),Vector3(15,6.5,65)]
  for centre: Vector3 in centres:
   var light:=OmniLight3D.new();light.name="GalleryFill";light.position=centre
   light.light_color=Color(1,.98,.95);light.light_energy=.8;light.omni_range=12;light.omni_attenuation=1.7
   light.shadow_enabled=false;add_child(light)
 polish_displays()

func pier(at: Vector3) -> void:
 pier_count+=1
 box(self,"PierFoot",at+Vector3(0,.10,0),Vector3(.86,.20,.86),stone,true)
 var shaft:=MeshInstance3D.new();shaft.name="EngagedColumn"
 var mesh:=CylinderMesh.new();mesh.bottom_radius=.29;mesh.top_radius=.25;mesh.height=5.25;mesh.radial_segments=16
 shaft.mesh=mesh;shaft.material_override=pale;shaft.position=at+Vector3(0,2.825,0);add_child(shaft)
 # A conservative collision envelope covers the visible shaft.
 var body:=StaticBody3D.new();shaft.add_child(body)
 var shape:=CollisionShape3D.new();shape.shape=CylinderShape3D.new();shape.shape.radius=.29;shape.shape.height=5.25;body.add_child(shape)
 box(self,"Capital",at+Vector3(0,5.5,0),Vector3(.76,.25,.76),stone)
 box(self,"Entablature",at+Vector3(0,5.80,0),Vector3(.65,.28,5.6),stone)

func recolour(n: MeshInstance3D, material: Material) -> void:
 if n!=null:n.material_override=material

func polish_displays() -> void:
 for n: Node3D in grid.find_children("*","Node3D",true,false):
  var script: Script=n.get_script()
  if script==null:continue
  var path: String=script.resource_path
  if path.ends_with("/chroma_stack.gd") or path.ends_with("/color_dna_stack.gd"):
   # The whole static body rises as one; the five-part rule is unchanged.
   var home: Vector3=n.position
   n.position.y+=.24
   box(grid,"StackPlinth",home+Vector3(0,.12,0),Vector3(1.55,.24,1.55),stone,true)
   for screen in n.find_children("Plate","Node3D",true,false):
    screen.bg_color=Color("eeeae1");screen.frame_color=Color("d9d5cc")
    screen.title_color=Color("25242a");screen.body_color=Color("36343a")
    screen.call("_rebuild")
  elif path.ends_with("/nail_salon.gd"):
   recolour(n.get_node("ManicureTop"),stone)
   box(n,"ManicurePlinth",Vector3(0,.38,3),Vector3(3.25,.76,1.0),stone,true)
   for label in ["ControlPlinthLeft","ControlPlinthRight"]:recolour(n.get_node(label),stone)
   for label in n.find_children("*","Label3D",true,false):
    if label.text in ["NAILS","SKIN"]:label.modulate=Color("29272b");label.outline_size=0
  elif path.ends_with("/pillarcolorcollection.gd") and n.get("spatial_gradient"):
   for pillar in n.find_children("Pillar_*","Node3D",false,false):
    recolour(pillar.get_node_or_null("Footer"),stone)
    var label: Label3D=pillar.get_node("SampleAddress")
    label.pixel_size=.002;label.position.y=.24;label.position.z=-.54
    label.modulate=Color("29272b");label.outline_size=0
  elif path.ends_with("/address_lesson.gd"):
   recolour(n.get_node_or_null("AddressPlinth"),stone)
  elif path.ends_with("/ball_painting_automation.gd"):
   for piece in n.get_node("Frame").get_children():
    if piece is MeshInstance3D and str(piece.name).begins_with("Frame"):recolour(piece,stone)
   box(n,"PaintPlinth",Vector3(0,.08,1.275),Vector3(2.88,1.06,.55),stone,true)
   recolour(n.get_node_or_null("PigmentTray"),stone)
   var hint: Label3D=n.get_node_or_null("SprayHint")
   if hint!=null:hint.position.z=1.59
