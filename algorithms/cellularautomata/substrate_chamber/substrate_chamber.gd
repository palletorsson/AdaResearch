# SubstrateChamber.gd
# Architectural-scale variant of SubstrateBox: a 12×8×12 cube box at half-metre
# cube size, with floor-plan AUTO_STITCH enabled by default so the bottom 2
# layers always carve a walkable path. Player can step inside the chamber
# while the substrate cycles its visibility and colour expressions overhead.
#
# Inherits SubstrateBox so all parameter logic + mutator wiring stays shared.
# Only overrides defaults and post-mounts floor_plan_mode on the visibility
# mutator after _ready completes.
#
# @identity
# essence: SubstrateBox at architectural scale + AUTO_STITCH floor plan
# desire: to be the second spine artifact — a chamber the player walks
#   THROUGH, not just up to. Pattern is the maze, pathfinding ensures the
#   maze is solvable.
# critical_parameter: cube_size (0.5 → ~6m total span, 4m head-room) and
#   floor_plan_mode (AUTO_STITCH connects all empty pockets in the bottom
#   2 cube layers)
# triggers: _ready calls super(), then enables floor-plan AUTO_STITCH
# emerges: a 6m×4m×6m chamber whose walls are CA + fractal patterns whose
#   floor is a maze the player walks. Spawn lands them on the largest
#   connected empty component; auto-stitch ensures they can reach all of it
# needs: SubstrateBox parent [✓]; GridVisibilityMutator's floor_plan_mode [✓]
# relationships: extends SubstrateBox; sister artifact alongside the
#   tabletop substrate_box; for spine maps with footprint big enough to
#   host an architectural piece
# truth: scale changes what the substrate is for — tabletop = look-at,
#   architectural = walk-through

extends "res://algorithms/cellularautomata/substrate_box/substrate_box.gd"
class_name SubstrateChamber

func _init() -> void:
	# Override SubstrateBox defaults before _ready runs.
	grid_dims = Vector3i(12, 8, 12)
	cube_size = 0.5  # ~6m × 4m × 6m total
	visibility_cycle_seconds = 7.0
	color_cycle_seconds = 11.0


func _ready() -> void:
	super._ready()
	_enable_walkable_floor_plan()


# Configure the visibility mutator's floor-plan analysis so the bottom 2
# layers always have a walkable empty component, regardless of which
# expression is active. AUTO_STITCH carves minimum doors between disconnected
# empty pockets in the floor strata.
func _enable_walkable_floor_plan() -> void:
	if not _vis_mutator:
		return
	# FloorPlanMode.AUTO_STITCH = 2 (see GridVisibilityMutator)
	_vis_mutator.floor_plan_mode = 2
	_vis_mutator.floor_plan_layers = 2


# Public: where the player should spawn. Reads the visibility mutator's
# computed walkable component. Returns the chamber's local origin if
# unavailable. Map-level wiring can call this to position the player.
func get_recommended_spawn_local() -> Vector3:
	if not _vis_mutator or not _vis_mutator.has_method("get_recommended_spawn"):
		return Vector3.ZERO
	var cell: Vector3i = _vis_mutator.get_recommended_spawn()
	# Convert cell coord back to local-space origin (matches _build_multimesh).
	var ox_off: float = -(grid_dims.x - 1) * 0.5 * cube_size
	var oz_off: float = -(grid_dims.z - 1) * 0.5 * cube_size
	return Vector3(
		ox_off + cell.x * cube_size,
		cell.y * cube_size + cube_size * 0.5,
		oz_off + cell.z * cube_size,
	)
