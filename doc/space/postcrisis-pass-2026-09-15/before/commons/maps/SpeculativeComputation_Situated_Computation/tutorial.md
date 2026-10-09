# Situated Computation

Three viewing platforms, one dataset, three different pictures. Build objectivity as the careful accounting of perspective.

Declare a standpoint.

```gdscript
class_name Standpoint
extends Resource

@export var name: String = ""
@export var origin: Vector3 = Vector3.ZERO
@export var filter_weights: Dictionary = {}
@export var color: Color = Color.WHITE
```

Each platform is a standpoint. The origin is where the observer stands. The filter is what the standpoint can see.

Build three standpoints.

```gdscript
func build_standpoints() -> Array[Standpoint]:
    var sps: Array[Standpoint] = []
    sps.append(make_standpoint("analyst", Vector3(-5, 2, 0), {"metrics": 1.0}))
    sps.append(make_standpoint("user", Vector3(0, 1.7, 5), {"friction": 1.0}))
    sps.append(make_standpoint("archivist", Vector3(5, 2, 0), {"history": 1.0}))
    return sps
```

The analyst sees metrics. The user feels friction. The archivist traces history.

No viewpoint is a superset of another.

Project the dataset through a standpoint.

```gdscript
func project(records: Array, sp: Standpoint) -> Array:
    var out: Array = []
    for r in records:
        var score := 0.0
        for key in sp.filter_weights:
            score += float(r.get(key, 0.0)) * sp.filter_weights[key]
        out.append({"record": r, "score": score})
    return out
```

The standpoint scores each record against its own weights. The same record receives three different scores. The dataset is the same; the readings diverge.

Render records as heights on a platform.

```gdscript
func render_column(parent: Node3D, record: Dictionary, score: float) -> void:
    var column := MeshInstance3D.new()
    column.mesh = BoxMesh.new()
    column.scale = Vector3(0.2, max(0.05, score), 0.2)
    column.position = record.get("position", Vector3.ZERO)
    parent.add_child(column)
```

Each record becomes a column whose height is the standpoint's score. The three platforms tell three different stories about the same city.

Label each platform with its accountability.

```gdscript
func label_platform(label: Label3D, sp: Standpoint) -> void:
    var keys: Array = sp.filter_weights.keys()
    label.text = "%s sees: %s" % [sp.name, ", ".join(keys)]
```

The sign names what this standpoint attends to. Nothing is hidden; nothing is pretended to be neutral. Accountability replaces the view from nowhere.

Mark disagreement bands between platforms.

```gdscript
func disagreement(records: Array, sps: Array) -> Array:
    var out: Array = []
    for r in records:
        var scores: Array = sps.map(func(s): return project_one(r, s))
        var spread: float = scores.max() - scores.min()
        out.append({"record": r, "spread": spread})
    return out
```

Records with high spread are precisely where the perspectives matter most. The spread is not noise to smooth away. It is the evidence.

Colour the highest-spread records across all platforms.

```gdscript
func highlight_spread(columns: Array, spreads: Array, threshold: float) -> void:
    for i in columns.size():
        if spreads[i].spread > threshold:
            (columns[i] as MeshInstance3D).modulate = Color(1.0, 0.6, 0.2)
```

Orange bands ring the contested records across all three platforms simultaneously. The controversy is structured, not scattered.

You have built a triple viewing station where perspective is declared before measurement. The next map, Collective Knowledge, turns three standpoints into four reasoning agents who must share a commons.
