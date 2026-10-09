extends Node2D

class BrushStroke:
	var pos: Vector2
	var radius: float
	var color: Color
	
	func _init(p, r, c):
		pos = p
		radius = r
		color = c

var strokes: Array = []
const SPRAY_SHADER = preload("res://algorithms/color/drawing/spray_stamp.gdshader")
const MAX_SPRAY_STAMPS := 64
var sprays: Array = []
var spray_pool: Array[Polygon2D] = []
var _clear_splats_next_frame := false

func _process(_delta: float) -> void:
	# Clear last frame's draw commands even when no new input arrives.
	if _clear_splats_next_frame:
		queue_redraw()
		_clear_splats_next_frame = false
	for stamp in spray_pool: stamp.visible = false
	for i in range(sprays.size()):
		if i >= spray_pool.size():
			var stamp := Polygon2D.new()
			stamp.polygon = PackedVector2Array([Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)])
			stamp.uv = PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)])
			var mat := ShaderMaterial.new(); mat.shader = SPRAY_SHADER; stamp.material = mat
			# Polygon2D UV coordinates are pixel coordinates of its texture.
			var pixel := Image.create(1,1,false,Image.FORMAT_RGBA8); pixel.fill(Color.WHITE)
			stamp.texture = ImageTexture.create_from_image(pixel)
			add_child(stamp); spray_pool.append(stamp)
		var data: Dictionary = sprays[i]; var stamp := spray_pool[i]
		stamp.transform = Transform2D(data.x, data.y, data.pos)
		stamp.material.set_shader_parameter("ink", data.color)
		stamp.material.set_shader_parameter("coverage", data.opacity)
		stamp.material.set_shader_parameter("seed", data.seed)
		stamp.material.set_shader_parameter("stamp_pixels", Vector2(data.x.length(),data.y.length()) * 2.0)
		stamp.visible = true
	sprays.clear()

func add_spray(pos: Vector2, x: Vector2, y: Vector2, color: Color, opacity: float, seed: float) -> void:
	if sprays.size() < MAX_SPRAY_STAMPS:
		sprays.append({"pos":pos,"x":x,"y":y,"color":color,"opacity":opacity,"seed":seed})

func _draw():
	_clear_splats_next_frame = not strokes.is_empty()
	for stroke in strokes:
		draw_circle(stroke.pos, stroke.radius, stroke.color)
	
	# Clear strokes after drawing them once
	# They will be captured by the BackBufferCopy for the next frame
	strokes.clear()

func add_splat(pos: Vector2, radius: float, color: Color):
	strokes.append(BrushStroke.new(pos, radius, color))
	queue_redraw()
