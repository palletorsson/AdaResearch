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

func _draw():
	for stroke in strokes:
		draw_circle(stroke.pos, stroke.radius, stroke.color)
	
	# Clear strokes after drawing them once
	# They will be captured by the BackBufferCopy for the next frame
	strokes.clear()

func add_splat(pos: Vector2, radius: float, color: Color):
	strokes.append(BrushStroke.new(pos, radius, color))
	queue_redraw()
