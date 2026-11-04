extends Node3D
## THE BELT, SEEN (Palle, 2026-11-04: "see and turn"): a row of miniatures of everything the hand has collected, the
## empty hand first (a thin ring), the one in the hand larger, lifted, on a ring, its name over it. It shows for a
## moment whenever the hand changes - the left stick click, a pick-up, a choice on the prism - and then fades. In VR
## it floats over the back of the left hand; on a desktop it is a strip at the foot of the view. At most WINDOW
## entries, centred on the one in the hand.

const SHOW_FOR := 2.5             # seconds the row stays after a change
const WINDOW := 7                 # entries shown at once
var hand: Node = null
var spacing := 0.065              # metres between miniatures along the holder's x
var size := 0.045                 # a miniature's longest side
var _row: Node3D = null
var _key := ""                    # the belt and the current item the row was built for
var _left := 0.0
var _name: Label3D = null

## `holder` is the node the row hangs from (the left controller, or the camera); `at` its place there.
func setup(p_hand: Node, holder: Node3D, at: Vector3, p_spacing := 0.065, p_size := 0.045) -> void:
	hand = p_hand;spacing = p_spacing;size = p_size
	if get_parent() != null:get_parent().remove_child(self)
	holder.add_child(self);position = at
	hand.item_changed.connect(func(_id):show_for())
	hand.collected.connect(func(_id):show_for())
	visible = false

## Show the row now, for SHOW_FOR seconds.
func show_for(seconds := SHOW_FOR) -> void:
	_rebuild();_left = seconds;visible = true

func showing() -> bool:
	return visible and _left > 0.0

func _process(delta: float) -> void:
	if _left <= 0.0:return
	_left -= delta
	if _left <= 0.0:visible = false

## The ids in the row, in order, and the index of the one in the hand.
func window() -> Dictionary:
	var belt: Array = hand.belt()
	var at: int = maxi(belt.find(hand.current), 0)
	var lo: int = clampi(at - WINDOW / 2, 0, maxi(belt.size() - WINDOW, 0))
	return {"ids": belt.slice(lo, lo + WINDOW), "current": at - lo}

func _rebuild() -> void:
	var w := window()
	var key := JSON.stringify(w)
	if key == _key and _row != null:return
	_key = key
	if _row != null:remove_child(_row);_row.queue_free()
	_row = Node3D.new();_row.name = "Row";add_child(_row)
	var ids: Array = w.ids
	var x0: float = -spacing * (ids.size() - 1) * .5
	for i in ids.size():
		var id: String = str(ids[i]);var on: bool = i == int(w.current)
		var slot := Node3D.new();slot.name = "Slot_%d" % i;_row.add_child(slot)
		slot.position = Vector3(x0 + i * spacing, .02 if on else 0.0, 0)
		var m: Node3D = _empty_hand() if id == "" else hand.make_mini(id, size)
		if m != null:
			slot.add_child(m)
			if on:m.scale *= 1.4
		if on:slot.add_child(_ring(size * .75))
	_on_top.call_deferred(_row)   # after the miniatures' own _ready has dressed them
	_name = Label3D.new();_name.name = "Name";_row.add_child(_name)
	_name.text = str(hand.name_of(hand.current)).to_upper()
	_name.billboard = BaseMaterial3D.BILLBOARD_ENABLED;_name.no_depth_test = true;_name.fixed_size = false
	_name.pixel_size = size * .012;_name.font_size = 32;_name.outline_size = 6;_name.modulate = Color("f1eadc")
	_name.render_priority = 11   # over the miniatures, which draw over everything else
	_name.position = Vector3(x0 + int(w.current) * spacing, size * 2.3, 0)   # clear of the lit miniature (1.4 x)

## Drawn over everything (a desktop avatar's shoulders fill the foot of the view; in VR a hand can pass in front): each
## surface's own material, copied without the depth test. Shader materials are left as they are.
func _on_top(root: Node) -> void:
	if not is_instance_valid(root):return
	var stack: Array = [root]
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		for c in x.get_children():stack.append(c)
		if not x is MeshInstance3D or (x as MeshInstance3D).mesh == null:continue
		var mi := x as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var src: Material = mi.get_active_material(i)
			if src is BaseMaterial3D:
				var m: BaseMaterial3D = (src as BaseMaterial3D).duplicate();m.no_depth_test = true;m.render_priority = 10
				mi.set_surface_override_material(i, m)
		if mi.material_override is BaseMaterial3D:
			var mo: BaseMaterial3D = (mi.material_override as BaseMaterial3D).duplicate();mo.no_depth_test = true;mo.render_priority = 10
			mi.material_override = mo

## The empty hand: an open ring, the same size as a miniature.
func _empty_hand() -> Node3D:
	var r := _ring(size * .4);r.name = "EmptyHand"
	return r

func _ring(radius: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new();var t := TorusMesh.new()
	t.inner_radius = radius * .82;t.outer_radius = radius;t.rings = 24;t.ring_segments = 6;mi.mesh = t
	var m := StandardMaterial3D.new();m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED;m.albedo_color = Color("f59e0b");mi.material_override = m
	mi.position.y = -size * .55
	return mi
