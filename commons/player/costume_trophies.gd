# @identity
# essence: trophy(sequence) = one small object built from that sequence's OWN vocabulary
# desire: to be recognisable at arm's length as the thing you learned, not as a generic badge
# critical_parameter: the sequence id — every branch here is a different argument about form
# triggers: a finished sequence; the wardrobe asks for one and hangs it
# emerges: a silhouette you can READ — the walk becomes legible on the body
# needs: nothing (pure procedural geometry, no scene files, no registry lookup)
# relationships: hung by costume_wardrobe onto queer_costume's slots
# truth: a medal says you were there; these say WHAT was there.

extends RefCounted
class_name CostumeTrophies

## TWENTY-TWO SMALL THINGS (2026-08-27, Palle: "attach beautiful thing to it as
## we go along the sequences").
##
## Each is built out of the sequence it comes from: primitives gives a point,
## forces gives an arrow, formfinding gives a hanging chain, fractals gives a
## self-similar edge, boolean_surfaces gives an actual CSG subtraction. That
## constraint is the whole design. Twenty-two identical stars in different
## colours would hang just as well and mean nothing, and the moment a trophy
## stops arguing its own sequence it becomes a scoreboard token — which is the
## shape the sieve's first question exists to catch.
##
## All of them are 4–9 cm and emissive, because they are read at arm's length in
## a headset, in rooms that are often dark.

## Which slot each sequence hangs on. Read down the list and it walks the body:
## the foundations at the throat and ears, the middle at the shoulders, the late
## synthesis low on the spine and hips — so the silhouette grows DOWNWARD and
## OUTWARD as the walk goes on.
const SLOT_FOR := {
	"primitives": "throat", "transformation": "ear_right", "color": "shoulder_left",
	"change": "ear_left", "forces": "shoulder_right", "formfinding": "hip_left",
	"wavefunctions": "ear_left", "randomness": "hip_right", "noise": "hip_right",
	"cellularautomata": "shoulder_left", "fractals": "shoulder_right",
	"lsystems": "shoulder_left", "proceduralgeneration": "spine",
	"softbodies": "hip_left", "isosurfaces": "hip_right", "boolean_surfaces": "spine",
	"swarmintelligence": "shoulder_right", "machinelearning": "spine",
	"graphtheory": "spine", "foundationscrisis": "throat",
	"qfeplaboratory": "throat", "postfoundationscrisis": "hip_left",
}


static func slot_for(seq: String) -> String:
	return String(SLOT_FOR.get(seq, "spine"))


static func known() -> Array:
	return SLOT_FOR.keys()


# ── the small vocabulary every trophy is made from ──────────────────────────

static func _mat(c: Color, glow: float = 1.1, metal: float = 0.35) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.32
	m.metallic = metal
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = glow
	return m


static func _ball(p: Vector3, r: float, c: Color, glow: float = 1.1) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 12
	sm.rings = 7
	mi.mesh = sm
	mi.material_override = _mat(c, glow)
	mi.position = p
	return mi


## A ROD IS A LINE THAT KNOWS ITS OWN LENGTH — the height IS the distance between
## its two ends, which is the rule the whole corpus's `line` already obeys.
static func _rod(a: Vector3, b: Vector3, r: float, c: Color, glow: float = 0.9) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var v: Vector3 = b - a
	var h: float = maxf(v.length(), 0.0005)
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 8
	mi.mesh = cm
	mi.material_override = _mat(c, glow)
	mi.position = (a + b) * 0.5
	var axis: Vector3 = v / h
	var dot: float = Vector3.UP.dot(axis)
	if dot > 0.9999:
		mi.basis = Basis()
	elif dot < -0.9999:
		mi.basis = Basis(Vector3.RIGHT, PI)
	else:
		mi.basis = Basis(Vector3.UP.cross(axis).normalized(), acos(clampf(dot, -1.0, 1.0)))
	return mi


static func _box(p: Vector3, s: Vector3, c: Color, glow: float = 0.8) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = s
	mi.mesh = bm
	mi.material_override = _mat(c, glow)
	mi.position = p
	return mi


# ── the twenty-two ──────────────────────────────────────────────────────────

## Build the trophy for one sequence. Returns null for a name it does not know,
## which is deliberate: a silent generic badge would hide the gap.
static func make(seq: String) -> Node3D:
	var n := Node3D.new()
	n.name = "Trophy_" + seq
	var built: bool = true
	match seq:
		"primitives":
			# THE POINT. Everything else on this body is an elaboration of it.
			n.add_child(_ball(Vector3.ZERO, 0.014, Color(1.0, 0.96, 0.86), 2.2))
		"transformation":
			# a cube on a gimbal ring, caught mid-turn
			var ring := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = 0.026
			tm.outer_radius = 0.030
			tm.rings = 20
			ring.mesh = tm
			ring.material_override = _mat(Color(0.86, 0.72, 0.34), 0.7, 0.8)
			ring.rotation_degrees = Vector3(74, 0, 22)
			n.add_child(ring)
			var cube: MeshInstance3D = _box(Vector3.ZERO, Vector3(0.022, 0.022, 0.022),
				Color(0.62, 0.86, 1.0), 1.1)
			cube.rotation_degrees = Vector3(35, 45, 12)
			n.add_child(cube)
		"color":
			# three discs that overlap and stay distinct — additive, not blended away
			var hues: Array = [Color(1.0, 0.22, 0.3), Color(0.3, 1.0, 0.42), Color(0.35, 0.5, 1.0)]
			for i in range(3):
				var a: float = float(i) * TAU / 3.0
				var d := MeshInstance3D.new()
				var cy := CylinderMesh.new()
				cy.top_radius = 0.019
				cy.bottom_radius = 0.019
				cy.height = 0.004
				cy.radial_segments = 20
				d.mesh = cy
				d.material_override = _mat(hues[i], 1.5, 0.0)
				d.position = Vector3(cos(a) * 0.010, sin(a) * 0.010, float(i) * 0.003)
				d.rotation_degrees = Vector3(90, 0, 0)
				n.add_child(d)
		"change":
			# a curve, and the straight line that touches it at exactly one place
			var col: Color = Color(0.55, 0.92, 0.82)
			var prev: Vector3 = Vector3(-0.030, 22.0 * 0.030 * 0.030 - 0.010, 0.0)
			for i in range(1, 9):
				var x: float = -0.030 + 0.0075 * float(i)
				var p: Vector3 = Vector3(x, x * x * 22.0 - 0.010, 0.0)
				n.add_child(_rod(prev, p, 0.0016, col, 0.8))
				prev = p
			# the tangent at x = 0.008, whose slope is 2ax and nothing else
			var x0: float = 0.008
			var y0: float = x0 * x0 * 22.0 - 0.010
			var m0: float = 2.0 * 22.0 * x0
			n.add_child(_rod(Vector3(-0.020, y0 + m0 * (-0.020 - x0), 0.0),
				Vector3(0.030, y0 + m0 * (0.030 - x0), 0.0), 0.0011,
				Color(1.0, 0.78, 0.32), 1.6))
		"forces":
			# an arrow: a vector with a head, which is the whole sequence
			var col2: Color = Color(0.98, 0.55, 0.28)
			n.add_child(_rod(Vector3(0, -0.028, 0), Vector3(0, 0.014, 0), 0.0028, col2, 1.0))
			var head := MeshInstance3D.new()
			var cn := CylinderMesh.new()
			cn.top_radius = 0.0
			cn.bottom_radius = 0.0095
			cn.height = 0.020
			cn.radial_segments = 12
			head.mesh = cn
			head.material_override = _mat(col2, 1.4)
			head.position = Vector3(0, 0.024, 0)
			n.add_child(head)
		"formfinding":
			# a catenary: beads let hang, finding their own shape rather than a drawn one
			var col3: Color = Color(0.72, 0.80, 0.95)
			var prev3: Vector3 = Vector3.ZERO
			for i in range(9):
				var u: float = -1.0 + 2.0 * float(i) / 8.0
				var p3: Vector3 = Vector3(u * 0.030, (cosh(u * 1.5) - cosh(1.5)) * 0.018, 0.0)
				if i > 0:
					n.add_child(_rod(prev3, p3, 0.0013, col3, 0.6))
				n.add_child(_ball(p3, 0.0033, col3, 1.0))
				prev3 = p3
		"wavefunctions":
			var col4: Color = Color(0.55, 0.86, 1.0)
			var prev4: Vector3 = Vector3(-0.030, 0.0, 0.0)
			for i in range(1, 13):
				var u2: float = float(i) / 12.0
				var p4: Vector3 = Vector3(-0.030 + u2 * 0.060, sin(u2 * TAU) * 0.014, 0.0)
				n.add_child(_rod(prev4, p4, 0.0015, col4, 1.0))
				prev4 = p4
		"randomness":
			# a throw. SEEDED, so it is the same throw every time you look — which
			# is the sequence's own joke about what random means to a machine.
			var rng := RandomNumberGenerator.new()
			rng.seed = 7734
			for i in range(11):
				n.add_child(_ball(Vector3(rng.randfn(0.0, 0.014), rng.randfn(0.0, 0.014),
					rng.randfn(0.0, 0.010)), 0.0042, Color(0.94, 0.90, 0.62), 1.0))
		"noise":
			# structured randomness: a lump, not a scatter — neighbours agree here
			var noise := FastNoiseLite.new()
			noise.seed = 11
			noise.frequency = 2.2
			for i in range(14):
				var a2: float = float(i) * 2.399963
				var rr: float = 0.006 + 0.017 * sqrt(float(i) / 14.0)
				var p5: Vector3 = Vector3(cos(a2) * rr, sin(a2) * rr * 0.8, 0.0)
				p5.z = noise.get_noise_2d(p5.x * 60.0, p5.y * 60.0) * 0.012
				n.add_child(_ball(p5, 0.0055, Color(0.66, 0.74, 0.58).lerp(
					Color(0.92, 0.86, 0.70), (p5.z + 0.012) / 0.024), 0.7))
		"cellularautomata":
			# one row of rule 110, stepped five times — a local rule, a global pattern
			var cells: Array = []
			for i in range(13):
				cells.append(1 if i == 9 else 0)
			for row in range(5):
				for i in range(13):
					if int(cells[i]) == 1:
						n.add_child(_box(Vector3(-0.030 + float(i) * 0.005,
							0.012 - float(row) * 0.005, 0.0),
							Vector3(0.0042, 0.0042, 0.0042), Color(0.86, 0.94, 1.0), 1.0))
				var nxt: Array = []
				for i in range(13):
					var l: int = int(cells[maxi(0, i - 1)])
					var c2: int = int(cells[i])
					var r2: int = int(cells[mini(12, i + 1)])
					nxt.append(1 if (110 >> (l * 4 + c2 * 2 + r2)) & 1 else 0)
				cells = nxt
		"fractals":
			# a Koch edge, three rewrites, so the same move is visible at three scales
			var pts: Array = [Vector3(-0.030, -0.010, 0.0), Vector3(0.030, -0.010, 0.0)]
			for _lvl in range(3):
				var out: Array = [pts[0]]
				for i in range(pts.size() - 1):
					var a3: Vector3 = pts[i]
					var b3: Vector3 = pts[i + 1]
					var d3: Vector3 = (b3 - a3) / 3.0
					var p1: Vector3 = a3 + d3
					var apex: Vector3 = p1 + d3.rotated(Vector3.BACK, -PI / 3.0)
					out.append_array([p1, apex, a3 + d3 * 2.0, b3])
				pts = out
			for i in range(pts.size() - 1):
				n.add_child(_rod(pts[i], pts[i + 1], 0.0011, Color(0.80, 0.62, 1.0), 1.2))
		"lsystems":
			# a grammar grown twice and then walked, exactly as the turtle does it
			var s: String = "F"
			for _i in range(2):
				s = s.replace("F", "G[+G]G[-G]").replace("G", "F")
			var pos: Vector3 = Vector3(0, -0.032, 0)
			var ang: float = PI * 0.5
			var stack: Array = []
			for ch in s:
				match ch:
					"F":
						var nxt2: Vector3 = pos + Vector3(cos(ang), sin(ang), 0.0) * 0.0075
						n.add_child(_rod(pos, nxt2, 0.0013, Color(0.60, 0.90, 0.55), 0.9))
						pos = nxt2
					"+":
						ang += 0.44
					"-":
						ang -= 0.44
					"[":
						stack.append([pos, ang])
					"]":
						var top: Array = stack.pop_back()
						pos = top[0]
						ang = top[1]
		"proceduralgeneration":
			# tiles that agree at their edges and disagree everywhere else
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = 4103
			for i in range(9):
				n.add_child(_box(Vector3(-0.016 + float(i % 3) * 0.016,
					0.016 - float(i / 3) * 0.016, rng2.randf() * 0.006),
					Vector3(0.014, 0.014, 0.004),
					Color(0.55, 0.62, 0.78).lerp(Color(0.95, 0.84, 0.60), rng2.randf()), 0.6))
		"softbodies":
			# a ring that has given up holding its own shape
			var col5: Color = Color(1.0, 0.62, 0.72)
			var prev5: Vector3 = Vector3(0.026, -0.006, 0.0)
			for i in range(1, 15):
				var a4: float = float(i) / 14.0 * TAU
				var sag: float = 1.0 - 0.42 * (0.5 - 0.5 * cos(a4))
				var p6: Vector3 = Vector3(cos(a4) * 0.026, sin(a4) * 0.026 * sag - 0.006, 0.0)
				n.add_child(_rod(prev5, p6, 0.0022, col5, 0.9))
				prev5 = p6
		"isosurfaces":
			# two fields that have merged into one surface — the neck is the point
			n.add_child(_ball(Vector3(-0.012, 0.0, 0.0), 0.016, Color(0.62, 0.90, 0.86), 0.9))
			n.add_child(_ball(Vector3(0.012, 0.004, 0.0), 0.013, Color(0.62, 0.90, 0.86), 0.9))
			n.add_child(_ball(Vector3(0.0, 0.002, 0.0), 0.010, Color(0.72, 0.96, 0.92), 1.3))
		"boolean_surfaces":
			# AN ACTUAL SUBTRACTION, done by CSG at runtime rather than drawn to look
			# like one. The sequence is about the operation, so the trophy has to BE
			# the operation — anything else would be an illustration of a claim.
			var comb := CSGCombiner3D.new()
			var bx := CSGBox3D.new()
			bx.size = Vector3(0.030, 0.030, 0.030)
			bx.material = _mat(Color(0.90, 0.86, 0.72), 0.5, 0.7)
			comb.add_child(bx)
			var sp := CSGSphere3D.new()
			sp.radius = 0.020
			sp.radial_segments = 16
			sp.rings = 10
			sp.operation = CSGShape3D.OPERATION_SUBTRACTION
			sp.position = Vector3(0.013, 0.013, 0.013)
			comb.add_child(sp)
			n.add_child(comb)
		"swarmintelligence":
			# many small things agreeing, and two that have not agreed yet
			var rng3 := RandomNumberGenerator.new()
			rng3.seed = 2211
			for i in range(14):
				var cone := MeshInstance3D.new()
				var cm2 := CylinderMesh.new()
				cm2.top_radius = 0.0
				cm2.bottom_radius = 0.0038
				cm2.height = 0.011
				cm2.radial_segments = 6
				cone.mesh = cm2
				cone.material_override = _mat(Color(0.95, 0.92, 0.55), 0.9)
				cone.position = Vector3(rng3.randfn(0, 0.014), rng3.randfn(0, 0.011),
					rng3.randfn(0, 0.008))
				var stray: float = 1.6 if i > 11 else 0.16
				cone.rotation = Vector3(rng3.randfn(0, stray) - 1.2, rng3.randfn(0, stray), 0.0)
				n.add_child(cone)
		"machinelearning":
			# three layers, and the weights are visible as thickness
			var rng4 := RandomNumberGenerator.new()
			rng4.seed = 909
			var layers: Array = [3, 4, 2]
			var cols: Array = []
			for li in range(layers.size()):
				var col6: Array = []
				var cnt: int = int(layers[li])
				for j in range(cnt):
					var p7: Vector3 = Vector3(-0.024 + float(li) * 0.024,
						0.010 - float(j) * 0.020 / maxf(1.0, float(cnt - 1)), 0.0)
					col6.append(p7)
					n.add_child(_ball(p7, 0.0040, Color(0.72, 0.86, 1.0), 1.1))
				cols.append(col6)
			for li in range(layers.size() - 1):
				for a5 in (cols[li] as Array):
					for b5 in (cols[li + 1] as Array):
						n.add_child(_rod(a5, b5, 0.0004 + rng4.randf() * 0.0013,
							Color(0.42, 0.55, 0.78), 0.4))
		"graphtheory":
			# nodes and edges on no grid at all — the substrate that was always under it
			var rng5 := RandomNumberGenerator.new()
			rng5.seed = 6161
			var nodes: Array = []
			for i in range(7):
				var a6: float = float(i) / 7.0 * TAU + rng5.randf() * 0.4
				var rr2: float = 0.014 + rng5.randf() * 0.012
				nodes.append(Vector3(cos(a6) * rr2, sin(a6) * rr2, rng5.randfn(0, 0.004)))
			for i in range(7):
				for j in range(i + 1, 7):
					if rng5.randf() < 0.42:
						n.add_child(_rod(nodes[i], nodes[j], 0.0009, Color(0.58, 0.70, 0.80), 0.5))
			for p8 in nodes:
				n.add_child(_ball(p8, 0.0044, Color(0.95, 0.95, 0.90), 1.2))
		"foundationscrisis":
			# a ring that cannot close. The GAP is the trophy.
			var col7: Color = Color(0.92, 0.36, 0.36)
			var prev7: Vector3 = Vector3(cos(0.4) * 0.024, sin(0.4) * 0.024, 0.0)
			for i in range(1, 15):
				var a7: float = float(i) / 14.0 * (TAU * 0.86) + 0.4
				var p9: Vector3 = Vector3(cos(a7) * 0.024, sin(a7) * 0.024, 0.0)
				n.add_child(_rod(prev7, p9, 0.0021, col7, 1.0))
				prev7 = p9
			n.add_child(_ball(prev7, 0.0038, col7, 2.0))
		"qfeplaboratory":
			# four marks — Q, F, E and P — in the sizes the formula gives them
			var qc: Array = [Color(0.85, 0.55, 1.0), Color(0.55, 0.85, 1.0),
				Color(1.0, 0.72, 0.45), Color(0.60, 1.0, 0.72)]
			for i in range(4):
				var a8: float = float(i) * TAU / 4.0 + 0.4
				n.add_child(_ball(Vector3(cos(a8) * 0.019, sin(a8) * 0.019, 0.0),
					0.0060 - float(i) * 0.0008, qc[i], 1.5))
			n.add_child(_ball(Vector3.ZERO, 0.0042, Color(1.0, 1.0, 0.96), 2.4))
		"postfoundationscrisis":
			# a rhizome: no root, no top, and every part joins more than one other
			var rng6 := RandomNumberGenerator.new()
			rng6.seed = 3232
			var pts2: Array = []
			for i in range(10):
				pts2.append(Vector3(rng6.randfn(0, 0.018), rng6.randfn(0, 0.011),
					rng6.randfn(0, 0.009)))
			for i in range(10):
				for j in range(i + 1, 10):
					if (pts2[i] as Vector3).distance_to(pts2[j]) < 0.024:
						n.add_child(_rod(pts2[i], pts2[j], 0.0014,
							Color(0.72, 0.86, 0.62), 0.7))
			for p10 in pts2:
				n.add_child(_ball(p10, 0.0030, Color(0.88, 0.96, 0.80), 0.9))
		_:
			built = false
	if not built:
		n.queue_free()
		push_warning("costume: no trophy is designed for sequence '%s'" % seq)
		return null
	return n
