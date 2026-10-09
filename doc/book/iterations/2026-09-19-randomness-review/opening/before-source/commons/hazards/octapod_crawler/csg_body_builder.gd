# csg_body_builder.gd
# Shared CSG body builder used by csg_walker.gd (4-leg), csg_walker_six.gd
# (6-leg), csg_walker_eight.gd (octapod). Each walker subclass calls
# CSGBodyBuilder.build(parent_node, config_dict) in _ready() to attach
# a CSG creature body — the same body grammar that powers the
# radiolaria-csg-gallery.
#
# This decouples the body design from the gait. A 6-leg IK rig with a
# headcrab body, or an 8-leg rig with a tentacle body, or any combo,
# is a one-line change.

extends RefCounted
# Loaded via preload() — no class_name to keep editor-scan independent.


static func build(parent: Node3D, cfg: Dictionary) -> Node3D:
    """Build a CSG creature body and parent it to `parent` at local origin.

    cfg keys (all optional, sensible defaults):
      form: "headcrab" | "tentacles" | "growth"
      atom_radius, bulge_factor, atom_count, body_legs, pack,
      accent_period, drift, knee_at, initial_lift, post_knee_drop,
      seed, base_color (Color), accent_color (Color),
      show_beak (bool), body_y_offset (float)
    """
    var form := String(cfg.get("form", "headcrab"))
    var atom_r := float(cfg.get("atom_radius", 0.30))
    var bulge_factor := float(cfg.get("bulge_factor", 3.5))
    var atom_count := int(cfg.get("atom_count", 14))
    var body_legs := int(cfg.get("body_legs", 4))
    var pack := float(cfg.get("pack", 0.55))
    var accent_period := int(cfg.get("accent_period", 5))
    var drift := float(cfg.get("drift", 0.20))
    var knee_at := float(cfg.get("knee_at", 0.45))
    var initial_lift := float(cfg.get("initial_lift", 0.5))
    var post_knee_drop := float(cfg.get("post_knee_drop", 1.6))
    var seed_v := int(cfg.get("seed", 1))
    var base_color: Color = cfg.get("base_color", Color("#d8a878"))
    var accent_color: Color = cfg.get("accent_color", Color("#5a1810"))
    var show_beak := bool(cfg.get("show_beak", true))
    var body_y_offset := float(cfg.get("body_y_offset", 0.0))
    # When true, skip the decorative anatomy-legs on headcrab/tentacles
    # so the IK rig provides the visible legs. Default true for walkers.
    var bulge_only := bool(cfg.get("bulge_only", false))

    var body_root := Node3D.new()
    body_root.name = "CSGBody"
    body_root.position = Vector3(0, body_y_offset, 0)
    parent.add_child(body_root)

    var rng := RandomNumberGenerator.new()
    rng.seed = seed_v
    var base_mat := _csg_mat(base_color, 0.15, 0.6)
    var accent_mat := _csg_mat(accent_color, 0.25, 0.5)

    match form:
        "headcrab":
            _build_headcrab(body_root, base_mat, accent_mat, rng,
                atom_r, bulge_factor, atom_count, body_legs, pack,
                accent_period, knee_at, initial_lift, post_knee_drop, show_beak,
                bulge_only)
        "tentacles":
            if bulge_only:
                _build_bulge_only(body_root, base_mat, accent_mat,
                    atom_r, bulge_factor, show_beak)
            else:
                _build_tentacles(body_root, base_mat, accent_mat, rng,
                    atom_r, bulge_factor, atom_count, body_legs, pack,
                    accent_period, drift)
        _:
            if bulge_only:
                _build_bulge_only(body_root, base_mat, accent_mat,
                    atom_r, bulge_factor, show_beak)
            else:
                _build_growth(body_root, base_mat, accent_mat, rng,
                    atom_r, atom_count, pack, accent_period, drift)

    return body_root


## Just the bulge head — no decorative legs / no chain. Used when an
## external rig (FABRIK3D walker) provides the visible legs.
static func _build_bulge_only(parent: Node3D, base_mat: StandardMaterial3D,
        accent_mat: StandardMaterial3D, atom_r: float, bulge_factor: float, show_beak: bool) -> void:
    var bulge_r: float = atom_r * bulge_factor
    var body := CSGSphere3D.new()
    body.radius = bulge_r
    body.material = base_mat
    parent.add_child(body)
    var carve := CSGSphere3D.new()
    carve.radius = bulge_r * 1.05
    carve.position = Vector3(0, -bulge_r * 1.10, 0)
    carve.operation = CSGShape3D.OPERATION_SUBTRACTION
    body.add_child(carve)
    if show_beak:
        var beak := CSGSphere3D.new()
        beak.radius = atom_r * 0.45
        beak.position = Vector3(0, -bulge_r * 0.55, 0)
        beak.operation = CSGShape3D.OPERATION_UNION
        beak.material = accent_mat
        body.add_child(beak)
        var tooth := CSGSphere3D.new()
        tooth.radius = atom_r * 0.25
        tooth.position = Vector3(0, -bulge_r * 0.78, 0)
        tooth.operation = CSGShape3D.OPERATION_UNION
        tooth.material = accent_mat
        body.add_child(tooth)


## Attach CSG geometry to each bone of a Skeleton3D via BoneAttachment3D.
## As FABRIK3D rotates the bones, the geometry follows, so the limb bends
## with the IK chain. joint_style picks the construction:
##
##   "sphere"    — one bulge sphere per bone (vertebrae chain, default)
##   "cylinder"  — thin cylinder shaft per bone + sphere hub at each joint
##                 (mechanical / robotic arm look)
##   "pill"      — capsule (cylinder with rounded ends, sphere on each end)
##
## Bone-rest pose: each bone is 1 unit long along local +Y, attaching to
## its parent at local origin. So the joint sits at (0,0,0) and the next
## joint sits at (0,1,0).
static func attach_csg_to_skeleton(skel: Skeleton3D, base_mat: StandardMaterial3D,
        accent_mat: StandardMaterial3D,
        joint_style: String = "cylinder",
        shaft_radius: float = 0.18,
        hub_radius: float = 0.32,
        foot_radius: float = 0.42,
        taper: float = 0.50,
        accent_period: int = 3) -> int:
    if skel == null: return 0
    var n: int = skel.get_bone_count()
    for b in n:
        var attach := BoneAttachment3D.new()
        attach.bone_idx = b
        attach.use_external_skeleton = false
        skel.add_child(attach)
        var t_b: float = float(b) / float(max(n - 1, 1))
        var taper_factor: float = 1.0 - t_b * taper
        var is_accent := (b == n - 1) or ((b + 1) % accent_period == 0)
        var hub_mat: StandardMaterial3D = accent_mat if is_accent else base_mat
        var is_last := (b == n - 1)

        match joint_style:
            "sphere":
                var sph := CSGSphere3D.new()
                sph.radius = hub_radius * taper_factor
                sph.material = hub_mat
                sph.position = Vector3(0, 0.5, 0)
                attach.add_child(sph)
            "cylinder", "pill":
                # Shaft: cylinder spanning the bone (origin → tip at y=1).
                var cyl := CSGCylinder3D.new()
                cyl.height = 0.92  # slight gap so hubs read as joints
                cyl.radius = shaft_radius * taper_factor
                cyl.position = Vector3(0, 0.5, 0)
                cyl.material = base_mat
                attach.add_child(cyl)
                # Joint hub at this bone's origin (the joint with parent).
                var hub := CSGSphere3D.new()
                hub.radius = hub_radius * taper_factor
                hub.position = Vector3(0, 0, 0)
                hub.material = hub_mat
                attach.add_child(hub)
                # Pill mode: also a hub at the bone's tip (so each bone is
                # a self-contained capsule). Otherwise the next bone's
                # origin-hub fills that slot.
                if joint_style == "pill" or is_last:
                    var tip := CSGSphere3D.new()
                    var r_tip := foot_radius if is_last else (hub_radius * taper_factor)
                    tip.radius = r_tip
                    tip.position = Vector3(0, 1.0, 0)
                    tip.material = accent_mat if is_last else base_mat
                    attach.add_child(tip)
            _:
                pass
    return n


static func _csg_mat(c: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.metallic = metallic
    m.roughness = roughness
    return m


static func _add_atom(parent: CSGSphere3D, pos: Vector3, radius: float, mat: StandardMaterial3D) -> void:
    var atom := CSGSphere3D.new()
    atom.radius = radius
    atom.position = pos
    atom.operation = CSGShape3D.OPERATION_UNION
    atom.material = mat
    parent.add_child(atom)


static func _build_headcrab(parent: Node3D, base_mat: StandardMaterial3D, accent_mat: StandardMaterial3D, rng: RandomNumberGenerator,
        atom_r: float, bulge_factor: float, atom_count: int, body_legs: int, pack: float,
        accent_period: int, knee_at: float, initial_lift: float, post_knee_drop: float, show_beak: bool,
        bulge_only: bool = false) -> void:
    var bulge_r: float = atom_r * bulge_factor
    var body := CSGSphere3D.new()
    body.radius = bulge_r
    body.material = base_mat
    parent.add_child(body)

    var carve := CSGSphere3D.new()
    carve.radius = bulge_r * 1.05
    carve.position = Vector3(0, -bulge_r * 1.10, 0)
    carve.operation = CSGShape3D.OPERATION_SUBTRACTION
    body.add_child(carve)

    if show_beak:
        var beak := CSGSphere3D.new()
        beak.radius = atom_r * 0.45
        beak.position = Vector3(0, -bulge_r * 0.55, 0)
        beak.operation = CSGShape3D.OPERATION_UNION
        beak.material = accent_mat
        body.add_child(beak)
        var tooth := CSGSphere3D.new()
        tooth.radius = atom_r * 0.25
        tooth.position = Vector3(0, -bulge_r * 0.78, 0)
        tooth.operation = CSGShape3D.OPERATION_UNION
        tooth.material = accent_mat
        body.add_child(tooth)

    if bulge_only:
        return  # Skip decorative anatomy legs — IK rig provides legs.

    for leg_idx in body_legs:
        var phi: float = leg_idx * TAU / float(body_legs)
        var dir_l := Vector3(cos(phi), initial_lift, sin(phi)).normalized()
        var pos_l: Vector3 = dir_l * (bulge_r * 0.9 + atom_r * pack)
        var cur_dir: Vector3 = dir_l

        for j in atom_count:
            var t_leg: float = float(j) / float(max(atom_count - 1, 1))
            var taper: float = 1.0 - t_leg * 0.55
            var r_l: float = atom_r * taper

            if t_leg < knee_at:
                cur_dir.y = lerp(cur_dir.y, 0.10, 0.20)
            elif abs(t_leg - knee_at) < 1.0 / float(atom_count):
                cur_dir = Vector3(cur_dir.x, -post_knee_drop, cur_dir.z).normalized()
            else:
                cur_dir.y -= 0.18
            cur_dir = cur_dir.normalized()

            var is_tip: bool = (j == atom_count - 1)
            var is_band: bool = ((j + 1) % accent_period == 0)
            var atom_mat: StandardMaterial3D = accent_mat if (is_tip or is_band) else base_mat
            _add_atom(body, pos_l, r_l, atom_mat)
            pos_l += cur_dir * (2.0 * atom_r * pack * taper)


static func _build_tentacles(parent: Node3D, base_mat: StandardMaterial3D, accent_mat: StandardMaterial3D, rng: RandomNumberGenerator,
        atom_r: float, bulge_factor: float, atom_count: int, body_legs: int, pack: float,
        accent_period: int, drift: float) -> void:
    var bulge_r: float = atom_r * bulge_factor
    var body := CSGSphere3D.new()
    body.radius = bulge_r
    body.material = base_mat
    parent.add_child(body)

    var golden: float = (1.0 + sqrt(5.0)) / 2.0
    for t_idx in body_legs:
        var theta: float = acos(1.0 - 2.0 * (float(t_idx) + 0.5) / float(body_legs))
        var phi: float = TAU * float(t_idx) / golden
        var dir_t := Vector3(
            sin(theta) * cos(phi),
            sin(theta) * sin(phi),
            cos(theta),
        ).normalized()
        var pos_t: Vector3 = dir_t * (bulge_r + atom_r * pack)
        var cur_dir_t: Vector3 = dir_t
        for j in atom_count:
            var taper_t: float = 1.0 - float(j) / float(atom_count) * 0.45
            var r_j: float = atom_r * taper_t
            var is_tip_t: bool = (j == atom_count - 1)
            var is_accent_t: bool = is_tip_t or ((j + 1) % accent_period == 0)
            _add_atom(body, pos_t, r_j, accent_mat if is_accent_t else base_mat)
            var axis_t := Vector3(rng.randf() * 2 - 1, rng.randf() * 2 - 1, rng.randf() * 2 - 1).normalized()
            cur_dir_t = cur_dir_t.rotated(axis_t, rng.randf_range(-drift, drift)).normalized()
            pos_t += cur_dir_t * (2.0 * atom_r * pack * taper_t)


static func _build_growth(parent: Node3D, base_mat: StandardMaterial3D, accent_mat: StandardMaterial3D, rng: RandomNumberGenerator,
        atom_r: float, atom_count: int, pack: float, accent_period: int, drift: float) -> void:
    var seed_atom := CSGSphere3D.new()
    seed_atom.radius = atom_r
    seed_atom.material = base_mat
    parent.add_child(seed_atom)
    var prev_pos := Vector3.ZERO
    var cur_dir := Vector3(1, 0.3, 0.2).normalized()
    for i in range(1, atom_count):
        var axis := Vector3(rng.randf() * 2 - 1, rng.randf() * 2 - 1, rng.randf() * 2 - 1).normalized()
        cur_dir = cur_dir.rotated(axis, rng.randf_range(-drift, drift)).normalized()
        var new_pos: Vector3 = prev_pos + cur_dir * (2.0 * atom_r * pack)
        var is_accent: bool = (i % accent_period == 0) or (i >= atom_count - 2)
        _add_atom(seed_atom, new_pos, atom_r * (0.92 + rng.randf() * 0.18),
            accent_mat if is_accent else base_mat)
        prev_pos = new_pos
