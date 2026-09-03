extends SceneTree
## The change chapter's three green rooms make claims a probe can answer.
## Functions copied from Change_Intro, Accumulation_Riemann and
## Change_Reconciliation tutorial.md and asked questions with known answers.
##
##   1  the forward difference settles on the analytic slope 0.8x - 1.2 as h shrinks,
##      and the centred one is better for the same cost (its error is second order)
##   2  the valley bottom: slope_at reads zero at x = 1.5, the one moment of stillness
##   3  the left-rule Riemann sum approaches the exact area as n grows, and midpoint
##      beats left and right at the same n  <- the "ask the rectangles why"
##   4  the tutorial's own numbers: pi_estimate(10) = 3.30 and pi_estimate(1000) = 3.143
##   5  the workbench's integral: 0.5 + 0.4 sin 2x + 0.15 cos 5x on [0,5] is 2.864
##   6  FTC direction one: accumulate the rate and get f(b) - f(a)
##   7  FTC direction two: differentiate the running area and get f back
##   8  the fine print: a step at x = 2 leaves direction one intact and makes direction
##      two stutter, exactly where the theorem's continuity clause says it must

# --- Change_Intro -----------------------------------------------------------
func f1(x: float) -> float:
	return 0.4 * x * x - 1.2 * x + 2.0

func slope_at(x: float, h: float = 0.001) -> float:
	return (f1(x + h) - f1(x)) / h

func slope_centered(x: float, h: float = 0.001) -> float:
	return (f1(x + h) - f1(x - h)) / (2.0 * h)

func analytic1(x: float) -> float:
	return 0.8 * x - 1.2

# --- Accumulation_Riemann ---------------------------------------------------
func quarter_circle(x: float) -> float:
	return sqrt(maxf(0.0, 1.0 - x * x))

func riemann_left(fn: Callable, a: float, b: float, n: int) -> float:
	var dx := (b - a) / n
	var total := 0.0
	for i in n:
		total += fn.call(a + i * dx) * dx
	return total

func riemann_right(fn: Callable, a: float, b: float, n: int) -> float:
	var dx := (b - a) / n
	var total := 0.0
	for i in n:
		total += fn.call(a + (i + 1) * dx) * dx
	return total

func riemann_mid(fn: Callable, a: float, b: float, n: int) -> float:
	var dx := (b - a) / n
	var total := 0.0
	for i in n:
		total += fn.call(a + (i + 0.5) * dx) * dx
	return total

func pi_estimate(n: int) -> float:
	return 4.0 * riemann_left(quarter_circle, 0.0, 1.0, n)

func bench(x: float) -> float:      # riemann_sum_workbench's curve
	return 0.5 + 0.4 * sin(2.0 * x) + 0.15 * cos(5.0 * x)

# --- Change_Reconciliation --------------------------------------------------
func f3(x: float) -> float:
	return 1.0 + 0.5 * sin(x)

func integral_of_derivative(fn: Callable, a: float, b: float, n: int = 1000) -> float:
	var dx := (b - a) / n
	var total := 0.0
	for i in n:
		var x := a + (i + 0.5) * dx
		var fprime: float = (fn.call(x + 0.001) - fn.call(x - 0.001)) / 0.002
		total += fprime * dx
	return total

func running_area(fn: Callable, x: float, n: int = 500) -> float:
	var dx := x / n
	var total := 0.0
	for i in n:
		total += fn.call((i + 0.5) * dx) * dx
	return total

func derivative_of_integral(fn: Callable, x: float) -> float:
	return (running_area(fn, x + 0.001) - running_area(fn, x - 0.001)) / 0.002

func step(x: float) -> float:       # the tutorial's "break it": a jump at x = 2
	return 1.0 if x < 2.0 else 2.0

func _init() -> void:
	var fails := 0

	# 1. the difference quotient settles, and centred is second order
	var x := 2.0
	var e_fwd_big := absf(slope_at(x, 0.1) - analytic1(x))
	var e_fwd_small := absf(slope_at(x, 0.001) - analytic1(x))
	var e_cen_big := absf(slope_centered(x, 0.1) - analytic1(x))
	print("1  at x=2 the slope is %.3f; forward h=0.1 errs by %.4f, h=0.001 by %.6f; centred at h=0.1 errs by %.9f (a parabola's centred difference is exact)" % [analytic1(x), e_fwd_big, e_fwd_small, e_cen_big])
	if e_fwd_small > e_fwd_big or e_fwd_small > 1e-3 or e_cen_big > 1e-9:
		print("   FAIL the limit did not settle, or centred was not better"); fails += 1

	# 2. the valley bottom
	var best_x := 0.0; var best := INF
	for i in 3001:
		var xx := i * 0.001
		var s := absf(slope_centered(xx))
		if s < best: best = s; best_x = xx
	print("2  slope reads zero at x = %.3f (must be 1.5, the curve's one moment of stillness)" % best_x)
	if absf(best_x - 1.5) > 0.002:
		print("   FAIL the valley is not where the arithmetic puts it"); fails += 1

	# 3. rectangles: left approaches, midpoint wins
	var exact_q := PI / 4.0
	var l4 := riemann_left(quarter_circle, 0.0, 1.0, 4); var l400 := riemann_left(quarter_circle, 0.0, 1.0, 400)
	var l := absf(riemann_left(quarter_circle, 0.0, 1.0, 64) - exact_q)
	var r := absf(riemann_right(quarter_circle, 0.0, 1.0, 64) - exact_q)
	var m := absf(riemann_mid(quarter_circle, 0.0, 1.0, 64) - exact_q)
	print("3  quarter circle, exact %.5f: left n=4 %.4f, n=400 %.5f; at n=64 the errors are left %.5f, right %.5f, midpoint %.5f (midpoint must be smallest)" % [exact_q, l4, l400, l, r, m])
	if absf(l400 - exact_q) > absf(l4 - exact_q) or m >= l or m >= r:
		print("   FAIL the staircase did not melt, or midpoint did not win"); fails += 1

	# 4. the tutorial's own numbers
	var p10 := pi_estimate(10); var p1000 := pi_estimate(1000)
	print("4  pi_estimate(10) = %.3f (tutorial says 3.30), pi_estimate(1000) = %.4f (tutorial says 3.143)" % [p10, p1000])
	if absf(p10 - 3.30) > 0.006 or absf(p1000 - 3.143) > 0.0015:
		print("   FAIL the tutorial's printed numbers are not what its own code gives"); fails += 1

	# 5. the workbench's integral
	var exact_bench := 2.5 + 0.2 * (1.0 - cos(10.0)) + 0.03 * sin(25.0)
	var mid128 := riemann_mid(bench, 0.0, 5.0, 128); var mid4 := riemann_mid(bench, 0.0, 5.0, 4)
	print("5  workbench curve on [0,5]: exact %.4f (plaque says 2.864); midpoint N=4 %.3f, N=128 %.4f" % [exact_bench, mid4, mid128])
	if absf(exact_bench - 2.864) > 0.001 or absf(mid128 - exact_bench) > 0.002:
		print("   FAIL the workbench's stated integral is wrong, or N=128 does not reach it"); fails += 1

	# 6. FTC direction one
	var a := 0.5; var b := 4.0
	var d1 := integral_of_derivative(f3, a, b)
	var want1 := f3(b) - f3(a)
	print("6  accumulate f' from %.1f to %.1f: %.6f; f(b) - f(a) = %.6f (must agree to the step size)" % [a, b, d1, want1])
	if absf(d1 - want1) > 1e-4:
		print("   FAIL direction one did not telescope"); fails += 1

	# 7. FTC direction two
	var worst := 0.0
	for i in 8:
		var xx := 0.5 + i * 0.5
		worst = maxf(worst, absf(derivative_of_integral(f3, xx) - f3(xx)))
	print("7  differentiate the running area at eight points across the span: worst disagreement with f is %.6f (must be in the far decimals)" % worst)
	if worst > 2e-3:
		print("   FAIL direction two did not return f"); fails += 1

	# 8. the fine print
	var d1_step := integral_of_derivative(step, 0.0, 4.0, 4000)
	var want_step := step(4.0) - step(0.0)
	var smooth_side := absf(derivative_of_integral(step, 1.0) - step(1.0))
	var at_jump := absf(derivative_of_integral(step, 2.0) - step(2.0))
	print("8  a jump at x=2: direction one gives %.4f against f(b)-f(a) = %.1f (survives); direction two errs by %.6f at x=1 and by %.4f at the jump (stutters)" % [d1_step, want_step, smooth_side, at_jump])
	if absf(d1_step - want_step) > 0.02 or smooth_side > 1e-3 or at_jump < 0.1:
		print("   FAIL the continuity clause did not show where the tutorial says"); fails += 1

	print("")
	print("PROBE %s" % ("OK" if fails == 0 else "FAILED %d" % fails))
	quit(fails)
