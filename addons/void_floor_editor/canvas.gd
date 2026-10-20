@tool
extends Control
signal picked(index: int)
signal moved(index: int, at: Vector2)
signal placed(at: Vector2)
var document: RefCounted
var dragging := -1
var drag_to := Vector2.ZERO
var pointer_down := Vector2.ZERO
var move_tool := true
var cell := 0.5
var hint_start = null
const INK := Color("b8c6d7")
func _ready() -> void:
	custom_minimum_size=Vector2(650,350)
	mouse_filter=Control.MOUSE_FILTER_STOP
	focus_mode=Control.FOCUS_ALL

func unit() -> float:
	return minf(size.x/46.0,size.y/23.0)
func screen(at: Vector2) -> Vector2:
	return size/2+at*unit()
func world(at: Vector2) -> Vector2:
	return (at-size/2)/unit()
func snap(at: Vector2) -> Vector2:
	return at.snapped(Vector2.ONE*cell)
func rectangle(at: Vector2, extent: Vector2, colour: Color) -> void:
	draw_rect(Rect2(screen(at-extent/2),extent*unit()),colour)
func text_at(at: Vector2, words: String, colour: Color=INK, font_size: int=12) -> void:
	draw_string(ThemeDB.fallback_font,screen(at),words,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,colour)
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("111923"))
	if document==null or document.data.is_empty(): return
	rectangle(Vector2.ZERO,Vector2(42,18),Color("26333c"))
	for x in range(-21,22): draw_line(screen(Vector2(x,-9)),screen(Vector2(x,9)),Color("35424c"),1)
	for z in range(-9,10): draw_line(screen(Vector2(-21,z)),screen(Vector2(21,z)),Color("35424c"),1)
	for shaft in document.frame.shafts:
		rectangle(Vector2(shaft.x,0),Vector2(5,6),Color("080c13"))
		text_at(Vector2(shaft.x-1.2,.2),"OPEN SHAFT",Color("d99387"))
	for x in document.frame.column_x:
		for z in document.frame.column_z: rectangle(Vector2(x,z),Vector2.ONE*.9,Color("b5aea2"))
	var floor_data: Dictionary = document.floor_data()
	for b in floor_data.get("basin",{}).get("rects",[]): rectangle(Vector2(b[0]+b[2]/2,b[1]+b[3]/2),Vector2(b[2],b[3]),Color("374e63"))
	rectangle(Vector2(-6,4.5),Vector2(1.2,1.2),Color("325a53"))
	text_at(Vector2(-7,5.5),"CHECKPOINT")
	var side := 1.0 if document.floor_index%2==1 else -1.0
	if document.floor_index>0:
		rectangle(Vector2(0,side*10.2),Vector2(6,2.4),Color("557863"))
		text_at(Vector2(-2,side*10.2),"LANDING")
	var route: Array = floor_data.get("route",[])
	for i in range(route.size()):
		var pos: Vector2 = document.vec(route[i].position)
		if i>0: draw_line(screen(document.vec(route[i-1].position)),screen(pos),Color("71ab9b"),2,true)
		draw_circle(screen(pos),4,Color("9ad6c5"))
		text_at(pos+Vector2(.2,-.2),str(i+1),Color("a8ddc9"),11)
	var entries: Array = document.entries()
	for i in range(entries.size()):
		var entry: Dictionary = entries[i]
		var pos: Vector2 = entry.position
		var colour := Color("d8b3c5")
		if entry.kind=="walls":
			var wall: Dictionary = floor_data.walls[entry.index]
			draw_line(screen(document.vec(wall.from)),screen(document.vec(wall.to)),Color("b6a38b"),5,true)
		elif entry.kind=="props":
			var prop: Dictionary = floor_data.props[entry.index]
			var dims: Array = document.catalog.props[prop.kind].size
			var extent := Vector2(dims[0],dims[2])*float(prop.scale)
			if int(prop.facing)%180==90: extent=Vector2(extent.y,extent.x)
			rectangle(pos,extent,Color("7f8d82"))
		elif entry.kind in ["artifacts","copies"]:
			draw_arc(screen(pos),10,0,TAU,24,colour,1.5,true)
		elif entry.kind=="part":
			if str(entry.key).begins_with("Caption") and i!=document.selected: continue
			var item: Dictionary = floor_data[entry.get("collection","artifacts")][entry.index]
			var defaults: Dictionary = document.parts[entry.area][entry.key]
			var placement: Dictionary = item.get("config",{}).get("parts",{}).get(entry.key,defaults)
			var bounds: Array = defaults.get("bounds",[0,0,0,0,0,0])
			var rot: Array = placement.get("rotation",defaults.rotation)
			var rotation := Basis.from_euler(Vector3(deg_to_rad(rot[0]),deg_to_rad(rot[1]),deg_to_rad(rot[2])))
			rotation=Basis(Vector3.UP,deg_to_rad(item.facing))*rotation
			var points := PackedVector2Array()
			for x in [0,1]:
				for y in [0,1]:
					for z in [0,1]:
						var point: Vector3 = rotation*Vector3(bounds[0]+x*bounds[3],bounds[1]+y*bounds[4],bounds[2]+z*bounds[5])*float(item.scale)
						points.append(screen(pos+Vector2(point.x,point.z)))
			var hull := Geometry2D.convex_hull(points)
			if hull.size()>3:
				draw_colored_polygon(hull,Color(.72,.56,.62,.12))
				draw_polyline(hull,Color(.72,.56,.62,.5),1,true)
			draw_circle(screen(pos),3.5,colour)
		if i==document.selected:
			draw_arc(screen(pos),13,0,TAU,32,Color("ffe3a7"),2,true)
			text_at(pos+Vector2(.5,-.5),str(entry.label).strip_edges(),Color("ffe3a7"),14)
	if dragging>=0:
		draw_arc(screen(drag_to),13,0,TAU,24,Color("ffe3a7"),2,true)
	if hint_start!=null: draw_circle(screen(hint_start),7,Color("ffe3a7"))
	text_at(Vector2(-21,-9.6),"NORTH  /  1 metre grid  /  fixed pillars and shafts",INK,13)

func _gui_input(event: InputEvent) -> void:
	if document==null or document.data.is_empty(): return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			grab_focus();pointer_down=event.position
			var at := snap(world(event.position))
			if not move_tool: placed.emit(at);return
			var nearest := -1
			var distance := 16.0
			var entries: Array = document.entries()
			for i in range(entries.size()):
				var entry: Dictionary = entries[i]
				if entry.kind=="part" and str(entry.key).begins_with("Caption"): continue
				var d: float = screen(entry.position).distance_to(event.position)
				if d<distance: distance=d;nearest=i
			dragging=nearest;drag_to=at;picked.emit(nearest);queue_redraw()
		else:
			if dragging>=0 and pointer_down.distance_to(event.position)>4:
				moved.emit(dragging,snap(world(event.position)))
			dragging=-1;queue_redraw()
	elif event is InputEventMouseMotion and dragging>=0:
		drag_to=snap(world(event.position));queue_redraw()
