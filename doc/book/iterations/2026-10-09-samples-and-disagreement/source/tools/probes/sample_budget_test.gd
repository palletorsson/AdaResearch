extends SceneTree
const Run = preload("res://algorithms/randomness/monte_carlo_dartboard/sample_run.gd")
var checks:Array=[]
var observations:Dictionary={}
func check(label:String, ok:bool)->void:
	checks.append({"name":label,"passed":ok});print("SAMPLE ",label," ",ok)
func _initialize()->void:
	var run=Run.new(1847)
	check("no estimate before evidence",is_nan(run.estimate()))
	for point in [Vector2(.5,.5),Vector2(0,.5),Vector2(1,.5),Vector2(.5,0),Vector2(.5,1)]:
		check("inside including boundary "+str(point),Run.in_circle(point))
	for point in [Vector2.ZERO,Vector2.ONE,Vector2(0,1),Vector2(1,0)]:
		check("square corner outside "+str(point),not Run.in_circle(point))
	var worsens:=0
	var previous_error:=INF
	var prefix:Array[Vector2]=[]
	var prefix_inside:=0
	var full_range:=true
	for i in 8000:
		var point:Vector2=run.next_sample()
		full_range=full_range and point.x>=0 and point.x<=1 and point.y>=0 and point.y<=1
		var error:=absf(run.estimate()-PI)
		if error>previous_error:worsens+=1
		previous_error=error
		if i==99:prefix=run.points.duplicate();prefix_inside=run.inside
	check("all uniform coordinates remain in unit square",full_range)
	check("retains 8000 counted samples",run.points.size()==8000)
	check("ratio uses all counts",is_equal_approx(run.estimate(),4.0*run.inside/8000))
	check("fixed run includes increases of absolute error",worsens>0)
	observations.error_increases=worsens
	var saved:Dictionary=run.snapshot()
	run.reset(1847)
	check("reset empties count and records",run.points.is_empty() and run.inside==0)
	for i in 100:run.next_sample()
	check("reset rewinds the exact prefix",run.points==prefix and run.inside==prefix_inside)
	check("saved record survives reset",saved.points.size()==8000)
	var other=Run.new(1848)
	other.next_sample()
	check("another seed changes first sample",other.points[0]!=prefix[0])
	var state:int=run.rng.state
	var before:Dictionary=run.snapshot()
	var comparison:Array=run.compare_seeds(1847,500)
	check("comparison has eight independent seeds",comparison.size()==8 and comparison[7].seed==1854)
	check("comparison preserves active stream and records",run.rng.state==state and run.points==before.points and run.inside==before.inside)
	check("comparison replay repeats results",comparison==run.compare_seeds(1847,500))
	var verified:=true
	for row in comparison:
		var independent_rng:=RandomNumberGenerator.new();independent_rng.seed=row.seed
		var count:=0
		for i in 500:
			var x:=independent_rng.randf()-.5;var y:=independent_rng.randf()-.5
			if x*x+y*y<=.25:count+=1
		verified=verified and row.inside==count and row.total==500 and is_equal_approx(row.estimate,4.0*count/500)
	check("seed table agrees with independent scalar oracle",verified)
	seed(77);var expected:=randf();seed(77);run.next_sample()
	check("local generator leaves global stream alone",randf()==expected)
	var means:Array=[]
	for budget in [100,500,2000,8000]:
		var rows:Array=run.compare_seeds(1847,budget)
		var total:=0.0
		for row in rows:total+=absf(row.error)
		means.append({"budget":budget,"mean_absolute_error":total/8,"rows":rows})
	observations.fixed_seed_fixture=means
	check("this fixture has lower aggregate error at 8000 than 100",means[3].mean_absolute_error<means[0].mean_absolute_error)
	var passed:=true
	for c in checks:passed=passed and c.passed
	var output:=OS.get_cmdline_user_args()[0]
	var file:=FileAccess.open(output,FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"passed":passed,"observations":observations},"\t"));file.close()
	quit(0 if passed else 1)
