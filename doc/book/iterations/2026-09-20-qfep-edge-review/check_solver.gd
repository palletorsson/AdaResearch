extends SceneTree
var checks: Array = []
var metrics: Array = []
const S = preload("res://commons/artifacts/edge_of_chaos_unlocked/edge_of_chaos_unlocked.gd")
func _initialize(): call_deferred("run")
func check(ok: bool, message: String): checks.append({"ok":ok,"message":message})
func specimen(l: float, dt: float, gs: int = 32, pair: bool = false):
	var n = S.new()
	n.grid_size=gs
	n.lambda=l
	n.time_step=dt
	n.comparison_study=pair
	n._init_grid()
	n._seed_pattern()
	n._reset_comparison()
	return n
func rms(a: PackedFloat32Array,b: PackedFloat32Array) -> float:
	var out:=0.0
	for i in range(a.size()): out+=pow(a[i]-b[i],2)
	return sqrt(out/a.size())
func run():
	var began=Time.get_ticks_msec()
	for l in [0.0,0.2,0.4,0.7,1.0]:
		var n=specimen(l,.3,32,true)
		for i in range(640):n._advance_tick()
		check(not n.solver_fault and Array(n._grid_a).min()>=0 and Array(n._grid_b).min()>=0,"Finite nonnegative concentrations at lambda "+str(l))
		check(absf(n.model_time-192.0)<.0001,"Matched model duration at lambda "+str(l))
		metrics.append({"lambda":l,"duration":n.model_time,"rms_B":n.comparison_error(),"B_min":Array(n._grid_b).min(),"B_max":Array(n._grid_b).max()})
		n.free()
	var coarse=specimen(.4,.3,64)
	var fine=specimen(.4,.15,64)
	var finer=specimen(.4,.075,64)
	for i in range(200):coarse._advance_tick()
	for i in range(400):fine._advance_tick()
	for i in range(800):finer._advance_tick()
	var e1=rms(coarse._grid_b,fine._grid_b)
	var e2=rms(fine._grid_b,finer._grid_b)
	metrics.append({"lambda":.4,"grid":64,"duration":60,"dt_03_vs_015":e1,"dt_015_vs_0075":e2})
	check(e2<e1,"Halving timestep reduces field difference in the selected 64x64, t=60 comparison")
	coarse.free();fine.free();finer.free()
	var slow=specimen(.4,.3)
	var fast=specimen(.4,.3)
	for i in range(90):slow._process(1.0/30.0)
	for i in range(360):fast._process(1.0/120.0)
	check(is_equal_approx(slow.model_time,fast.model_time) and slow._grid_b==fast._grid_b,"30 and 120 rendered frames per second give the same model state after three seconds")
	var initial=specimen(.4,.3)
	var seed=initial._grid_b.duplicate()
	slow.restart()
	check(slow._grid_b==seed and slow.model_time==0,"Restart returns to identical field and zero model time")
	slow.new_seed()
	check(slow._grid_b!=seed,"New seed actually changes the initial field")
	slow._paused=true
	var before=slow._grid_b.duplicate()
	slow._process(1)
	check(slow._grid_b==before and slow.model_time==0,"Hold stops both calculation and its clock")
	for n in [initial,slow,fast]:n.free()
	var uniform=specimen(.4,.3)
	uniform._grid_a.fill(1.0);uniform._grid_b.fill(0.0)
	for i in range(200):uniform._advance_tick()
	check(Array(uniform._grid_a).min()==1 and Array(uniform._grid_b).max()==0,"Homogeneous supply state remains an exact fixed point")
	uniform.free()
	var failed=checks.filter(func(c):return not c.ok)
	var report={"checks":checks,"metrics":metrics,"passed":failed.is_empty(),"elapsed_ms":Time.get_ticks_msec()-began}
	var f=FileAccess.open("res://doc/book/iterations/2026-09-20-qfep-edge-review/solver-checks.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
	print("SOLVER CHECKS ",checks.size()," ",failed," ",metrics)
	quit(0 if failed.is_empty() else 1)
