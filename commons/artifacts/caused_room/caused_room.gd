extends Node3D
class_name CausedRoom

## A single LOGICAL room — the smallest proof that "needs cause the building".
##
## The reactor's needs are INFERRED (NeedsModel), and the needs then CAUSE the room:
##   load >= 2  -> structure responds with a supported slab under it
##   power      -> a lit edge routed on the floor from a wall source
##   vent       -> a pipe routed up to a ceiling intake
## The console (a screen) needs power + data, so it gets a power edge and a data edge, and its
## readout shows it satisfied. Gravity is the constant: floor flat + walkable, heavy thing low on
## a support, pipes overhead, sources on the boundary. See doc/GENERATIVE_MAPS.md §5.

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const NeedsModel := preload("res://commons/artifacts/_hangar/needs_model.gd")


func _ready() -> void:
	_build()


func _build() -> void:
	# ── the protected volume: thick surfaces holding space open against gravity ──
	add_child(HangarKit.box(Vector3(0, -0.05, 0), Vector3(6.0, 0.1, 5.0), HangarKit.rams_body(HangarKit.BODY_LIGHT, 0.14)))   # floor slab
	add_child(HangarKit.box(Vector3(0, 1.5, -2.5), Vector3(6.0, 3.0, 0.16), HangarKit.rams_body(HangarKit.PANEL_TRIM, 0.1)))  # back wall
	for sx in [-2.9, 2.9]:                                                                                                    # corner columns (load down)
		add_child(HangarKit.box(Vector3(sx, 1.5, -2.4), Vector3(0.2, 3.0, 0.2), HangarKit.rams_body(HangarKit.PANEL_TRIM, 0.12)))
	add_child(HangarKit.box(Vector3(-1.5, 2.95, -1.3), Vector3(1.7, 0.18, 1.5), HangarKit.rams_body(HangarKit.PANEL_TRIM, 0.12)))  # ceiling beam over the machine

	# ── PROGRAM 1: a heavy reactor. Infer needs, then let the needs build the response. ──
	var reactor_pos := Vector3(-1.5, 0.0, -1.3)
	var reactor_need := NeedsModel.infer([], "machine", "reactor", {"footprint_cells": 4})
	print("CAUSED: REACTOR needs = ", reactor_need)
	var base_y := 0.0
	if int(reactor_need["load"]) >= 2:                                   # load -> structure: a supported slab
		add_child(HangarKit.box(reactor_pos + Vector3(0, 0.07, 0), Vector3(1.3, 0.14, 1.1), HangarKit.rams_body(HangarKit.PANEL_TRIM, 0.1)))
		base_y = 0.14
	var mh := 1.7
	add_child(HangarKit.box(reactor_pos + Vector3(0, base_y + mh * 0.5, 0), Vector3(1.0, mh, 0.8), HangarKit.terminal_body(HangarKit.TERMINAL_BODY, 0.3)))
	var rst := HangarKit.stencil("REACTOR", Vector2(0.62, 0.16), HangarKit.TEXT_DISPLAY)
	if rst:
		rst.position = reactor_pos + Vector3(0, base_y + mh * 0.62, 0.41)
		add_child(rst)
	var reactor_top := reactor_pos + Vector3(0, base_y + mh, 0)
	var reactor_base_front := reactor_pos + Vector3(0, base_y + 0.06, 0.42)
	var reactor_face := reactor_pos + Vector3(0, base_y + mh * 0.45, 0.42)

	# ── PROGRAM 2: a work console (the screen). Infer needs; it's a power+data sink. ──
	var table_pos := Vector3(1.6, 0.0, -0.6)
	_table(table_pos, 1.2, 0.7, 0.9)
	var console_need := NeedsModel.infer([], "console", "work screen readout", {"footprint_cells": 1})
	print("CAUSED: WORK SCREEN needs = ", console_need)
	var ro := HangarKit.readout("STATUS", ["POWER   ON", "DATA    LINK"], Vector2(0.5, 0.32))
	ro.position = table_pos + Vector3(0, 1.18, -0.05)
	add_child(ro)
	var screen_sink := table_pos + Vector3(0, 0.95, 0.18)

	# ── SOURCES on the boundary (where life-support enters the room) ──
	var pwr_src := Vector3(-2.65, 0.9, -2.41)
	_add_source("power", pwr_src)
	var vent_src := Vector3(-1.5, 2.84, -1.3)        # ceiling intake above the reactor
	_add_source("vent", vent_src, true)

	# ── SYSTEMS: each NEED routed from a source to its sink (the visible flow) ──
	add_child(HangarKit.system_edge(Vector3(pwr_src.x, 0.0, pwr_src.z + 0.12), reactor_base_front, "power"))   # reactor power
	add_child(HangarKit.system_edge(reactor_top, vent_src, "vent"))                                           # reactor vent
	add_child(HangarKit.system_edge(Vector3(pwr_src.x + 0.35, 0.0, pwr_src.z + 0.12), screen_sink, "power"))  # console power
	add_child(HangarKit.system_edge(reactor_face, screen_sink, "data"))                                       # console data (reads the reactor)


func _table(pos: Vector3, w: float, d: float, h: float) -> void:
	var mat := HangarKit.rams_body(HangarKit.PANEL_TRIM, 0.12)
	add_child(HangarKit.box(pos + Vector3(0, h, 0), Vector3(w, 0.07, d), mat))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			add_child(HangarKit.box(pos + Vector3(sx * (w * 0.5 - 0.06), h * 0.5, sz * (d * 0.5 - 0.06)), Vector3(0.06, h, 0.06), mat))


func _add_source(kind: String, pos: Vector3, ceiling: bool = false) -> void:
	var s := HangarKit.system_source(kind)
	s.position = pos
	if ceiling:
		s.rotation_degrees = Vector3(90, 0, 0)
	add_child(s)
