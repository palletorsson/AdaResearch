extends RefCounted
const Body = preload("body.gd")
const PATH = "user://ada_postcrisis_pose_v1.json"

func whole(value, low: int, high: int) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and value==int(value) and value>=low and value<=high

func decode(data) -> Dictionary:
    if not data is Dictionary or not data.has_all(["schema","model","positions","edges","edits"]): return {"ok":false}
    if data.schema!=1 or data.model!="postcrisis-body-v1" or not whole(data.edits,0,1000000): return {"ok":false}
    if not data.positions is Array or data.positions.size()!=13 or not data.edges is Array or data.edges.size()!=12: return {"ok":false}
    var body := Body.new()
    for i in 13:
        var p = data.positions[i]
        if not p is Array or p.size()!=3: return {"ok":false}
        for n in p:
            if not (n is int or n is float) or not is_finite(float(n)): return {"ok":false}
        var v := Vector3(p[0],p[1],p[2])
        if absf(v.x)>1.9 or absf(v.z)>1.9 or v.y<.12 or v.y>2.35: return {"ok":false}
        body.graph.points[i] = v
    var seen: Dictionary = {}
    for i in 12:
        var e = data.edges[i]
        if not e is Array or e.size()!=2 or not whole(e[0],0,12) or not whole(e[1],0,12) or e[0]==e[1]: return {"ok":false}
        var edge := Vector2i(int(e[0]),int(e[1]))
        var key := Vector2i(mini(edge.x,edge.y),maxi(edge.x,edge.y))
        if seen.has(key) or (i!=5 and edge!=Body.EDGES[i]): return {"ok":false}
        seen[key] = true
        body.graph.edges[i] = edge
    body.edits = int(data.edits)
    return {"ok":true,"body":body}

func read(path: String = PATH) -> Dictionary:
    if not FileAccess.file_exists(path): return {"ok":true,"empty":true,"message":"No pose kept. Visit Assembly."}
    var file := FileAccess.open(path,FileAccess.READ)
    if file==null or file.get_length()>65536: return {"ok":false,"message":"Cannot read this record."}
    var parser := JSON.new()
    if parser.parse(file.get_as_text())!=OK: return {"ok":false,"message":"Invalid JSON; file kept unchanged."}
    var result := decode(parser.data)
    result["empty"] = false
    result["message"] = "Saved pose read." if result.ok else "Invalid record; file kept unchanged."
    return result

func save(body, path: String = PATH) -> bool:
    if not decode(body.pack()).ok or not read(path).ok: return false
    var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
    if file==null: return false
    file.store_string(JSON.stringify(body.pack(),"  "))
    file.flush()
    var error := file.get_error()
    file.close()
    if error!=OK: return false
    return DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))==OK
