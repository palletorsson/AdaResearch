extends RefCounted
## A reversible geometric control, not a thermodynamic entropy model.
var draws: Array[int] = []

func seed_draws(seed_value: int, count: int) -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	draws.clear()
	for i in count: draws.append(rng.randi())

func u(index: int) -> float:
	return float(draws[index])/4294967296.0

func displaced(home: Transform3D, bounds: AABB, index: int, amount: float) -> Transform3D:
	if amount==0.0: return home
	var shift:=Vector3((u(index)*2-1)*0.23,u(index+1)*0.36,(u(index+2)*2-1)*0.20)*amount
	var angles:=Vector3(u(index+3)*2-1,u(index+4)*2-1,u(index+5)*2-1)*PI*0.8*amount
	var turn:=Basis.from_euler(angles)
	var pivot:=home*bounds.get_center()
	var moved:=Transform3D(turn*home.basis,pivot+shift+turn*(home.origin-pivot))
	# Keep every displayed mesh above its tray; no collision or heat solver.
	moved.origin.y+=maxf(0.0,-(moved*bounds).position.y)
	return moved
