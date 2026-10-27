extends "res://algorithms/randomness/galton_board/galton_board.gd"
## Trial-only adapter (randomness_04, f4_galton_board_2_10). Pegs, bins, sensors, the
## ball pool, timing and every random draw are the source's own.
##
## One seam, read from the source (static), measured by the native case `galton`:
## _spawn_ball() sets   rb.global_position = global_position + Vector3(jitter,
## _funnel_top_y + 0.02, z_jitter)   — a board-LOCAL offset added in world units. The
## token scales this board 1.5x (galton_board:180:0.9:1.5), so the funnel top stands
## at 0.57 x 1.5 = 0.86 m above the board origin while each ball appeared 0.57 m above
## it: about 0.38 board units, inside the peg field below its first three rows. The
## museum plan applies the same scale, so the seam is the source's, not the Void's.
## Here the same offset is read as board-local, so the ball enters at the funnel. The
## mapping stays right if the editor moves, turns or rescales the placement.
func _spawn_ball() -> void:
	var before: int = _active_balls.size()
	super._spawn_ball()
	if _active_balls.size() <= before: return
	var rb: RigidBody3D = _active_balls.back()
	rb.global_position = to_global(rb.global_position - global_position)
