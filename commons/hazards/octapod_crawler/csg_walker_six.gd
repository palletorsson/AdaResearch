# csg_walker_six.gd — 6-leg variant
extends "res://commons/hazards/octapod_crawler/six_leg_critter.gd"

const _BodyBuilder := preload("res://commons/hazards/octapod_crawler/csg_body_builder.gd")

@export_group("CSG body")
@export_enum("headcrab", "tentacles", "growth") var creature_form: String = "headcrab"
@export var creature_atom_radius: float = 0.30
@export var creature_bulge_factor: float = 3.5
@export var creature_atom_count: int = 12
@export var creature_body_legs: int = 6
@export var creature_pack: float = 0.55
@export var creature_accent_period: int = 4
@export var creature_seed: int = 13
@export var creature_knee_at: float = 0.45
@export var creature_post_knee_drop: float = 1.6
@export var creature_initial_lift: float = 0.5
@export var creature_drift: float = 0.25
@export var creature_base_color: Color = Color("#88a878")
@export var creature_accent_color: Color = Color("#3a1810")
@export var creature_show_beak: bool = true

@export_group("CSG legs (bone-skinned)")
@export var skin_legs_to_bones: bool = true
@export_enum("cylinder", "pill", "sphere") var leg_joint_style: String = "cylinder"
@export var leg_shaft_radius: float = 0.18
@export var leg_hub_radius: float = 0.32
@export var leg_foot_radius: float = 0.42
@export var leg_taper: float = 0.50
@export var leg_accent_period: int = 3
@export var hide_default_leg_meshes: bool = true


func _ready() -> void:
    super._ready()
    mesh = null
    _BodyBuilder.build(self, {
        "form": creature_form,
        "atom_radius": creature_atom_radius,
        "bulge_factor": creature_bulge_factor,
        "atom_count": creature_atom_count,
        "body_legs": creature_body_legs,
        "pack": creature_pack,
        "accent_period": creature_accent_period,
        "seed": creature_seed,
        "knee_at": creature_knee_at,
        "post_knee_drop": creature_post_knee_drop,
        "initial_lift": creature_initial_lift,
        "drift": creature_drift,
        "base_color": creature_base_color,
        "accent_color": creature_accent_color,
        "show_beak": creature_show_beak,
        "bulge_only": skin_legs_to_bones,
    })
    if skin_legs_to_bones:
        _attach_csg_legs()


func _attach_csg_legs() -> void:
    var base_mat := StandardMaterial3D.new()
    base_mat.albedo_color = creature_base_color
    base_mat.metallic = 0.15
    base_mat.roughness = 0.6
    var accent_mat := StandardMaterial3D.new()
    accent_mat.albedo_color = creature_accent_color
    accent_mat.metallic = 0.25
    accent_mat.roughness = 0.5
    for i in LEG_COUNT:
        var skel: Skeleton3D = get_node_or_null("IK_leg_%d/Armature/Skeleton3D" % i) as Skeleton3D
        if skel == null:
            continue
        if hide_default_leg_meshes:
            var existing := skel.get_node_or_null("LegMesh_%d" % i)
            if existing and existing is MeshInstance3D:
                (existing as MeshInstance3D).visible = false
        _BodyBuilder.attach_csg_to_skeleton(
            skel, base_mat, accent_mat,
            leg_joint_style,
            leg_shaft_radius, leg_hub_radius, leg_foot_radius,
            leg_taper, leg_accent_period,
        )
