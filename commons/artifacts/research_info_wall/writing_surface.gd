extends Node3D
## Reuse the project's dry marker canvas, in a local writing plane.
signal edited
const Canvas=preload("res://commons/artifacts/whiteboard/whiteboard_canvas.gd")
var size:=Vector2(1.6,0.95)
var paper_color:=Color.WHITE
var resolution:=1024
var canvas: MeshInstance3D
var stroke_events:=0

func _ready() -> void:
	canvas=Canvas.new();canvas.name="Ink"
	var quad:=QuadMesh.new();quad.size=size;canvas.mesh=quad
	canvas.texture_size=Vector2i(resolution,maxi(64,roundi(resolution*size.y/size.x)))
	add_child(canvas)
	canvas._image.fill(paper_color);canvas._dirty=true

func sample_uv(world_tip: Vector3,_grid_mm: float=0.0) -> Vector2:
	var p:=to_local(world_tip)
	if absf(p.z)>0.035 or absf(p.x)>size.x/2 or absf(p.y)>size.y/2:return Vector2(-1,-1)
	return Vector2(p.x/size.x+0.5,0.5-p.y/size.y)

func paint(previous: Vector2,uv: Vector2,ink: Color,erase: bool) -> void:
	var color:=paper_color if erase else ink
	var radius:=18 if erase else 3
	if previous.x<0:canvas.draw_point(uv,color,radius)
	else:canvas.draw_line(previous,uv,color,radius)
	stroke_events+=1;edited.emit()

func encode_ink() -> String:
	return Marshalls.raw_to_base64(canvas._image.save_png_to_buffer())

func restore_ink(encoded: String) -> bool:
	if encoded.length()>8000000:return false
	var picture:=Image.new()
	if picture.load_png_from_buffer(Marshalls.base64_to_raw(encoded))!=OK:return false
	if picture.get_size()!=canvas.texture_size:return false
	picture.convert(Image.FORMAT_RGBA8);canvas._image=picture;canvas._dirty=true
	return true
