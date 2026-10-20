extends RefCounted
## A learned, time-aligned two-hand prototype. Complete takes are observations.
## Timing is retained: no unordered pose bag and no time warping.
const SCHEMA := "ada-two-hand-phrase-1"
const SECONDS := 4.0
const STEPS := 41
const MAX_TAKES := 12
const MIN_LIMIT := 0.14
const MAX_LIMIT := 0.32
var examples: Array = []
var prototype: Array = []
var limits: Array = []
var tests: Array = []
var trained := false
var fit_error := 0.0
var message := "Record three complete takes of one phrase."

static func number(v: Variant, low: float, high: float) -> bool:
	return (v is float or v is int) and is_finite(float(v)) and float(v)>=low and float(v)<=high

static func valid_x(x: Variant) -> bool:
	if not x is Array or x.size()!=6: return false
	for v in x:
		if not number(v,-4,4): return false
	return true

static func valid_take(take: Variant) -> bool:
	if not take is Array or take.size()<40 or take.size()>100: return false
	var previous := -1.0
	for row in take:
		if not row is Dictionary or not number(row.get("t"),0,SECONDS) or not valid_x(row.get("x")): return false
		if float(row.t)<=previous or (previous>=0 and float(row.t)-previous>0.151): return false
		previous=float(row.t)
	return float(take[0].t)<=0.10 and float(take[-1].t)>=SECONDS-0.05

static func sample(take: Array, t: float) -> Array:
	if take.is_empty(): return []
	if t<=float(take[0].t): return take[0].x.duplicate()
	for i in range(1,take.size()):
		if t<=float(take[i].t):
			var a:Dictionary=take[i-1];var b:Dictionary=take[i]
			var amount:=inverse_lerp(float(a.t),float(b.t),t)
			var x:Array=[]
			for j in 6: x.append(lerpf(float(a.x[j]),float(b.x[j]),amount))
			return x
	return take[-1].x.duplicate()

static func resample(take: Array) -> Array:
	if not valid_take(take): return []
	var rows:Array=[]
	for i in STEPS: rows.append(sample(take,SECONDS*i/(STEPS-1)))
	return rows

static func hand_motion(rows: Array, hand: int) -> float:
	var mean:=Vector3.ZERO
	for x:Array in rows: mean+=Vector3(x[hand*3],x[hand*3+1],x[hand*3+2])/rows.size()
	var variance:=0.0
	for x:Array in rows: variance+=Vector3(x[hand*3],x[hand*3+1],x[hand*3+2]).distance_squared_to(mean)/rows.size()
	return sqrt(variance)

static func distances(a: Array, b: Array) -> Dictionary:
	var rms:=[0.0,0.0];var peak:=[0.0,0.0]
	for i in STEPS:
		for hand in 2:
			var squared:=0.0
			for j in 3: squared+=pow(float(a[i][hand*3+j])-float(b[i][hand*3+j]),2)
			rms[hand]+=squared/STEPS;peak[hand]=maxf(peak[hand],sqrt(squared))
	for hand in 2: rms[hand]=sqrt(rms[hand])
	return {"rms":rms,"peak":peak}

func invalidate() -> void:
	trained=false;prototype.clear();limits.clear();tests.clear();fit_error=0.0

func add_example(take: Array) -> bool:
	var rows:=resample(take)
	if rows.is_empty(): message="Incomplete or invalid take.";return false
	if hand_motion(rows,0)<0.07 or hand_motion(rows,1)<0.07: message="Move BOTH hands through the phrase.";return false
	if examples.size()>=MAX_TAKES: message="Maximum 12 takes. UNDO or RESET first.";return false
	examples.append(take.duplicate(true));invalidate()
	message="One complete phrase kept. Perform it again from the same start."
	return true

func undo() -> bool:
	if examples.is_empty(): return false
	examples.pop_back();invalidate();message="Last teaching take removed. Train again."
	return true

func fit() -> bool:
	invalidate()
	if examples.size()<3: message="Need at least three complete teaching takes.";return false
	var samples:Array=[]
	for take:Array in examples: samples.append(resample(take))
	for i in STEPS:
		var row:=[0.0,0.0,0.0,0.0,0.0,0.0]
		for take:Array in samples:
			for j in 6: row[j]+=float(take[i][j])/samples.size()
		prototype.append(row)
	limits=[MIN_LIMIT,MIN_LIMIT]
	var coherent:=true
	for take:Array in samples:
		var d:=distances(take,prototype)
		for hand in 2:
			# Residual to the average of the OTHER complete takes.
			var leave_one_out:float=d.rms[hand]*samples.size()/(samples.size()-1.0)
			coherent=coherent and leave_one_out<=MAX_LIMIT
			limits[hand]=clampf(maxf(limits[hand],leave_one_out*1.5+0.025),MIN_LIMIT,MAX_LIMIT)
			fit_error+=pow(float(d.rms[hand]),2)/(samples.size()*2)
	if not coherent:
		invalidate();message="Takes differ too much. UNDO an accidental take or RESET; teach one phrase.";return false
	trained=true;message="Timed paths fitted. Test a NEW performance."
	return true

func predict(take: Array) -> Dictionary:
	if not trained: return {}
	var rows:=resample(take)
	if rows.is_empty(): return {}
	var result:=distances(rows,prototype)
	var accepted:=true
	for hand in 2:
		accepted=accepted and result.rms[hand]<=limits[hand] and result.peak[hand]<=float(limits[hand])*2.5 and hand_motion(rows,hand)>=0.07
	result.accepted=accepted
	return result

func test_example(take: Array) -> Dictionary:
	var result:=predict(take)
	if result.is_empty(): return {}
	tests.append(result.duplicate(true))
	if tests.size()>60: tests.pop_front()
	return result

func target(t: float) -> Array:
	if not trained: return []
	var phase:=clampf(t/SECONDS,0,1)*(STEPS-1)
	var a:=mini(int(phase),STEPS-2)
	var result:Array=[]
	for j in 6: result.append(lerpf(prototype[a][j],prototype[a+1][j],phase-a))
	return result

func snapshot() -> Dictionary:
	return {"schema":SCHEMA,"seconds":SECONDS,"examples":examples.duplicate(true),"prototype":prototype.duplicate(true),"limits":limits.duplicate(),"trained":trained}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.get("schema")!=SCHEMA or data.get("seconds")!=SECONDS or not data.get("trained") is bool: return false
	if not data.get("examples") is Array or data.examples.size()>MAX_TAKES or not data.get("prototype") is Array or not data.get("limits") is Array: return false
	var candidate:RefCounted=get_script().new()
	for take:Variant in data.examples:
		if not take is Array or not candidate.add_example(take): return false
	if data.trained:
		if not candidate.fit() or data.prototype.size()!=STEPS or data.limits.size()!=2: return false
		for i in STEPS:
			if not valid_x(data.prototype[i]): return false
			for j in 6:
				if absf(float(data.prototype[i][j])-candidate.prototype[i][j])>1e-8: return false
		for hand in 2:
			if not number(data.limits[hand],MIN_LIMIT,MAX_LIMIT) or absf(data.limits[hand]-candidate.limits[hand])>1e-8: return false
	elif not data.prototype.is_empty() or not data.limits.is_empty(): return false
	examples=candidate.examples;prototype=candidate.prototype;limits=candidate.limits
	trained=candidate.trained;fit_error=candidate.fit_error;tests.clear()
	message="Loaded locally. Fresh tests begin here."
	return true

func save_file(path: String) -> Error:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot(),"  ",true,true))
	return file.get_error()

func load_file(path: String) -> bool:
	return restore(JSON.parse_string(FileAccess.get_file_as_string(path))) if FileAccess.file_exists(path) else false
