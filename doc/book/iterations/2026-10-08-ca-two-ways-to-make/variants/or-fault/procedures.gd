extends RefCounted
const N := 32

func next_row(old: Array[bool]) -> Array[bool]:
	var next: Array[bool] = []
	next.resize(N)
	for i in N:
		var left := old[posmod(i - 1, N)]
		var right := old[(i + 1) % N]
		next[i] = left or right
	return next

func copy_positions(at: Vector3, spacing: float, depth: int) -> Array[Vector3]:
	# Supplied recipe from the installed pyramid; it reads no cell states.
	if depth == 0:
		return [at]
	var half := spacing / 2.0
	var offset := half / 2.0
	var shifts: Array[Vector3] = [
		Vector3(0, half, 0), Vector3(0, offset, 0),
		Vector3(-offset, -offset, -offset), Vector3(offset, -offset, -offset),
		Vector3(-offset, -offset, offset), Vector3(offset, -offset, offset)
	]
	var positions: Array[Vector3] = []
	for shift in shifts:
		positions.append_array(copy_positions(at + shift, half, depth - 1))
	return positions
