extends RefCounted
const START = [0.69,-0.73,0.91,-0.52,-0.53,0.25,0.59,-0.35,-0.55,-0.07,0.14,-0.1,-0.05]
const RATE := 0.5
const LIMIT := 1000
var weights := PackedFloat64Array(START)
var data := PackedVector2Array([Vector2(-0.8,-0.8),Vector2(-0.8,0.8),Vector2(0.8,-0.8),Vector2(0.8,0.8)])
var labels := PackedInt32Array([0,1,1,0])
var fresh := PackedVector2Array([Vector2(-0.6,-0.7),Vector2(-0.6,0.7),Vector2(0.6,-0.7),Vector2(0.6,0.7)])
var flipped := false
var epoch := 0
var last_change := 0.0

func reset() -> void:
    weights = PackedFloat64Array(START)
    epoch = 0
    last_change = 0.0

func flip_labels() -> void:
    flipped = not flipped
    for i in labels.size(): labels[i] = 1-labels[i]
    reset()

func forward(x: Vector2) -> Dictionary:
    var hidden := PackedFloat64Array()
    for j in 3:
        hidden.append(tanh(weights[2*j]*x.x+weights[2*j+1]*x.y+weights[6+j]))
    var z := weights[12]
    for j in 3: z += weights[9+j]*hidden[j]
    var probability: float
    if z >= 0: probability = 1.0/(1.0+exp(-z))
    else: probability = exp(z)/(1.0+exp(z))
    return {"hidden":hidden,"z":z,"p":probability}

func example_loss(x: Vector2, target: int) -> float:
    var z: float = forward(x).z
    return maxf(z,0.0)-target*z+log(1.0+exp(-absf(z)))

func loss() -> float:
    var total := 0.0
    for i in data.size(): total += example_loss(data[i],labels[i])
    return total/data.size()

func gradient(x: Vector2, target: int) -> PackedFloat64Array:
    var g := PackedFloat64Array(); g.resize(13); g.fill(0.0)
    var f := forward(x)
    var d: float = f.p-target
    g[12] = d
    for j in 3:
        g[9+j] = d*f.hidden[j]
        var dh: float = d*weights[9+j]*(1.0-f.hidden[j]*f.hidden[j])
        g[6+j] = dh
        g[2*j] = dh*x.x
        g[2*j+1] = dh*x.y
    return g

func train_epoch() -> bool:
    if epoch >= LIMIT: return false
    var mean := PackedFloat64Array(); mean.resize(13); mean.fill(0.0)
    for i in data.size():
        var g := gradient(data[i],labels[i])
        for p in 13: mean[p] += g[p]/data.size()
    last_change = -RATE*mean[0]
    for p in 13: weights[p] -= RATE*mean[p]
    epoch += 1
    return true

func check_fresh() -> Dictionary:
    var total := 0.0
    var correct := 0
    var scores: Array = []
    for i in fresh.size():
        var f := forward(fresh[i]); scores.append(f.p)
        total += example_loss(fresh[i],labels[i])
        if int(f.p >= 0.5) == labels[i]: correct += 1
    return {"loss":total/fresh.size(),"correct":correct,"scores":scores}
