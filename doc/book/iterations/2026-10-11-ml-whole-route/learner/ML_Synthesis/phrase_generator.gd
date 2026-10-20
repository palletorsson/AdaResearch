extends RefCounted
## Fit a Gaussian distribution over complete, aligned, paired hand paths.
const Movement = preload("movement_learner.gd")
var mean: Array = []
var residuals: Array = []
var trained := false
var message := "Fit at least three whole takes."

func clear() -> void:
    mean.clear(); residuals.clear(); trained=false

func fit(takes: Array) -> bool:
    clear()
    if takes.size()<3 or takes.size()>Movement.MAX_TAKES:
        message="Need 3 to 12 complete takes."; return false
    var aligned: Array=[]
    for take in takes:
        if not Movement.valid_take(take):
            message="Incomplete or invalid take."; return false
        var rows: Array=Movement.resample(take)
        if Movement.hand_motion(rows,0)<0.07 or Movement.hand_motion(rows,1)<0.07:
            message="Each teaching take must move both hands."; return false
        aligned.append(rows)
    for i in Movement.STEPS:
        var row: Array=[0.0,0.0,0.0,0.0,0.0,0.0]
        for take: Array in aligned:
            for j in 6: row[j]+=float(take[i][j])/aligned.size()
        mean.append(row)
    for take: Array in aligned:
        var difference: Array=[]
        for i in Movement.STEPS:
            var row: Array=[]
            for j in 6: row.append(float(take[i][j])-float(mean[i][j]))
            difference.append(row)
        residuals.append(difference)
    trained=true; message="Mean and joint variation fitted."
    return true

func draw(sample_seed: int, amount: float) -> Dictionary:
    if not trained or not is_finite(amount) or amount<0 or amount>1: return {}
    var rng:=RandomNumberGenerator.new()
    rng.seed=sample_seed
    var weights: Array=[]
    for _take in residuals: weights.append(rng.randfn(0,1))
    return compose(weights,amount)

func compose(weights: Array, amount: float) -> Dictionary:
    if not trained or weights.size()!=residuals.size(): return {}
    if not is_finite(amount) or amount<0 or amount>1: return {}
    for value in weights:
        if not (value is int or value is float) or not is_finite(float(value)): return {}
    var rows: Array=mean.duplicate(true)
    var factor:=amount/sqrt(float(residuals.size()-1))
    # ONE coefficient per WHOLE residual, shared by both hands and all times.
    for k in residuals.size():
        for i in Movement.STEPS:
            for j in 6: rows[i][j]+=factor*float(weights[k])*float(residuals[k][i][j])
    var inside:=true
    for row: Array in rows: inside=inside and Movement.valid_x(row)
    var moving:=Movement.hand_motion(rows,0)>=0.07 and Movement.hand_motion(rows,1)>=0.07
    # Keep raw output inspectable; do not clip, retry or call it a dance score.
    return {"rows":rows,"weights":weights.duplicate(),"amount":amount,
        "previewable":inside and moving,
        "reason":"Ready to preview." if inside and moving else "Outside coordinate or two-hand-motion policy; preview withheld."}
