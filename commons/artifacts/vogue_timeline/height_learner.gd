extends RefCounted
## One measured feature, one continuous target. Fit, don't prescribe, the relation.
const SCHEMA := "ada-hand-height-1"
const EPOCHS := 240
const RATE := 0.10
const LIMIT := 30
var examples: Array = []
var tests: Array = []
var history: Array = []
var slope := 0.0
var intercept := 0.0
var centre := 0.0
var spread := 1.0
var epoch := 0
var trained := false

static func number(value: Variant, low: float, high: float) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and float(value) >= low and float(value) <= high

func add_example(x: float, target: float) -> bool:
	if not number(x,-2,2) or not number(target,0,1) or examples.size() >= LIMIT: return false
	examples.append({"x":x,"target":target})
	trained=false;epoch=0;tests.clear();history.clear()
	return true

func bounds() -> Vector2:
	var low := 2.0
	var high := -2.0
	for row: Dictionary in examples:
		low=minf(low,row.x);high=maxf(high,row.x)
	return Vector2(low,high)

func can_train() -> bool:
	return examples.size() >= 3 and bounds().y-bounds().x >= 0.25

func begin_training() -> bool:
	if not can_train(): return false
	centre=0.0
	for row: Dictionary in examples: centre+=float(row.x)/examples.size()
	var variance := 0.0
	for row: Dictionary in examples: variance+=pow(float(row.x)-centre,2)/examples.size()
	spread=maxf(0.05,sqrt(variance))
	slope=0.0;intercept=0.0;epoch=0;trained=false;tests.clear();history.clear()
	history.append(loss())
	return true

func raw(x: float) -> float:
	return slope*(x-centre)/spread+intercept

func loss() -> float:
	var total := 0.0
	for row: Dictionary in examples: total+=pow(raw(row.x)-float(row.target),2)
	return total/maxi(1,examples.size())

func gradient() -> Vector2:
	var result := Vector2.ZERO
	# The two derivatives are accumulated before either parameter changes.
	for row: Dictionary in examples:
		var error := raw(row.x)-float(row.target)
		result+=Vector2(2.0*error*(float(row.x)-centre)/spread,2.0*error)/examples.size()
	return result

func train_epoch() -> void:
	if not can_train() or epoch >= EPOCHS: return
	var derivatives := gradient()
	slope-=RATE*derivatives.x;intercept-=RATE*derivatives.y
	epoch+=1
	if epoch%8==0: history.append(loss())
	trained=epoch==EPOCHS

func predict(x: float) -> Dictionary:
	if not trained or not number(x,-2,2): return {}
	var limits := bounds()
	var value := raw(x)
	return {"raw":value,"value":clampf(value,0,1),"accepted":x>=limits.x-0.00001 and x<=limits.y+0.00001,"clamped":value<0 or value>1}

func test_example(x: float, expected: float) -> Dictionary:
	if not number(expected,0,1): return {}
	var result := predict(x)
	if result.is_empty(): return {}
	result=result.duplicate()
	result.merge({"x":x,"expected":expected,"error":result.raw-expected})
	tests.append(result.duplicate(true))
	if tests.size()>90: tests.pop_front()
	return result

func snapshot() -> Dictionary:
	return {"schema":SCHEMA,"examples":examples.duplicate(true),"slope":slope,"intercept":intercept,"centre":centre,"spread":spread,"epoch":epoch,"trained":trained}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.get("schema")!=SCHEMA: return false
	for key in ["slope","intercept","centre","spread","epoch"]:
		if not number(data.get(key),-100,100) and key!="epoch": return false
	if not number(data.get("epoch"),0,EPOCHS) or int(data.epoch)!=data.epoch: return false
	if not data.get("trained") is bool or data.trained!=(int(data.epoch)==EPOCHS): return false
	if float(data.spread)<0.05 or float(data.spread)>4 or absf(data.centre)>2: return false
	if not data.get("examples") is Array or data.examples.size()>LIMIT: return false
	var candidate: RefCounted = get_script().new()
	for row: Variant in data.examples:
		if not row is Dictionary or not number(row.get("x"),-2,2) or not number(row.get("target"),0,1): return false
		candidate.add_example(row.x,row.target)
	if data.epoch>0:
		if not candidate.begin_training(): return false
		if absf(candidate.centre-float(data.centre))>1e-8 or absf(candidate.spread-float(data.spread))>1e-8: return false
	examples=candidate.examples
	slope=float(data.slope);intercept=float(data.intercept);centre=float(data.centre);spread=float(data.spread)
	epoch=int(data.epoch);trained=data.trained;tests.clear();history.clear()
	return true

func save_file(path: String) -> Error:
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot(),"  ",true,true))
	return OK

func load_file(path: String) -> bool:
	if not FileAccess.file_exists(path): return false
	return restore(JSON.parse_string(FileAccess.get_file_as_string(path)))
