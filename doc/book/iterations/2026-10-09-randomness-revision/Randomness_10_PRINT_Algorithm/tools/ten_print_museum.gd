extends "res://tools/probes/transformation_encounters.gd"

var _cols: int = 4

func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(0.6).timeout
    var screen := find_scene("/TenPrint.gd")
    var composition := find_scene("/composition_stochastique.gd")
    check("printer and exact-count comparison exist", screen!=null and composition!=null)
    if screen==null:return
    var origin := hall.global_position+Vector3(0,0,4)
    observations.artifacts=[]
    for record in museum.get("_edit_records"):
        var node=record.get("node")
        if not is_instance_valid(node) or record.get("seg")!=hall:continue
        var bounds: AABB=museum.call("_seat_extent",node)
        observations.artifacts.append({"token":record.get("token"),"position":xyz(node.global_position-origin),"bounds_position":xyz(bounds.position-origin),"bounds_size":xyz(bounds.size)})
    screen.set_running(false)
    screen.set_process(false)
    observations.printer_before=screen.get_state()
    await snapshot("hall-before",origin+Vector3(7.5,15,-1),origin+Vector3(7.5,1,8),75)
    await snapshot("printer-before",screen.global_position+screen.global_basis.orthonormalized()*Vector3(0.55,0.7,3),screen.global_position+Vector3(0,0,0),55)
    var floor_study: Node3D
    var walls: Node3D
    for n in hall.find_children("*","Node3D",true,false):
        if n.get_script()==null or not str(n.get_script().resource_path).ends_with("/ten_print_structure.gd"):continue
        if n.form=="floor":floor_study=n
        if n.form=="wall":walls=n
    check("linked floor and solid wall crop exist", floor_study!=null and walls!=null)
    if floor_study==null or walls==null:return
    observations.wall_cells=[]
    var wall_cells: Dictionary=walls.get_cells()
    for cell in wall_cells:observations.wall_cells.append([cell.x,cell.y,wall_cells[cell]])
    check("walls are twelve marks four per row with collision",walls.get_dims()==Vector2i(4,3) and wall_cells.size()==12 and walls.solid_body()!=null)
    check("floor follows this screen and has no solid body",floor_study.linked_interface()==screen and floor_study.solid_body()==null and floor_study.get_dims()==Vector2i(20,7))
    var agrees := true
    for cell in wall_cells:agrees=agrees and wall_cells[cell]==screen.coin_is_forward(cell.y*4+cell.x)
    check("wall crop retains first twelve seeded breathing choices",agrees)
    screen.bias=0.5
    screen.count=400
    screen._restart()
    screen._refresh_status()
    await tick()
    var original: Dictionary=screen.get_field()
    var stream=screen.stream_log.duplicate()
    var field: Dictionary=floor_study.get_cells()
    agrees=true
    for cell in field:agrees=agrees and field[cell]==original[Vector2i(cell.x,cell.y+13)]
    check("floor represents the newest seven screen rows",field.size()==140 and agrees)
    await snapshot("printer-fixed-half",screen.global_position+screen.global_basis.orthonormalized()*Vector3(0.55,0.7,3),screen.global_position,55)
    screen.press_control("semicolon")
    await tick()
    var column: Dictionary=screen.get_field()
    agrees=true
    for cell in column:agrees=agrees and cell.x==0
    check("semicolon changes layout while replaying the same400 choices",column.size()==20 and agrees and screen.stream_log==stream)
    check("linked floor becomes a single file",floor_study.get_cells().size()==7)
    await snapshot("printer-column",screen.global_position+screen.global_basis.orthonormalized()*Vector3(0.55,0.7,3),screen.global_position,55)
    screen.press_control("semicolon")
    await tick()
    check("restoring semicolon restores the field",screen.get_field()==original)
    var before_count: int=screen.draw_count
    screen.press_control("bias_plus")
    check("bias changes next odds without restarting or rewriting old marks",is_equal_approx(screen.bias,0.6) and screen.draw_count==before_count and screen.get_field()==original and screen.program_line().contains("205.4"))
    screen.press_control("step")
    await tick()
    check("step advances exactly one choice",screen.draw_count==before_count+1)
    check("separate wall crop does not follow console edits",walls.get_cells()==wall_cells)
    screen.bias=1.0
    screen._restart()
    var only_one:=true
    for flag in screen.get_field().values():only_one=only_one and flag
    check("unit bias gives one diagonal throughout this installed sample",only_one)
    screen.bias=-1.0
    screen._restart()
    await tick()
    if composition!=null:
        var counts: Array=composition.shown_counts()
        var exact_counts:=counts==[1,5,30,50]
        var nested:=true
        for k in counts:
            exact_counts=exact_counts and composition.turned_cells(k).size()==k
            for cell in composition.turned_cells(k):nested=nested and cell in composition.turned_cells(50)
        var index: int=composition.draw_index()
        composition.reseed()
        for k in counts:exact_counts=exact_counts and composition.turned_cells(k).size()==k
        check("comparison retains exact quotas on reseed",exact_counts and composition.draw_index()==index+1)
        check("comparison grids share the selected cells",nested)
        observations.composition_counts=counts
    var regions:=_regions(wall_cells,4,3)
    check("wall crop encloses a region and has a far-near crossing",regions.closed==1 and regions.far_near)
    var unbranched:=true
    for mouths in regions.mouths:unbranched=unbranched and mouths==2
    check("open regions have two mouths without branching",unbranched)
    observations.wall_regions=regions
    for layout in [[3,12],[4,16]]:
        var cells: Dictionary={}
        for i in range(layout[1]):cells[Vector2i(i%layout[0],i/layout[0])]=screen.coin_is_forward(i)
        var reg:=_regions(cells,layout[0],layout[1]/layout[0])
        check("crop %d by %d closes far-near crossing"%[layout[0],layout[1]/layout[0]],not reg.far_near)
        if layout[0]==3:check("three-wide crop has no closed room",reg.closed==0)
    var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"spec.json"))
    if spec.has("lesson"):await study_checks(spec)
    observations.scope="Isolated real hall. Supplied console operations; no headset or full-route acceptance."

func study_checks(spec: Dictionary) -> void:
    var study=load(spec.lesson).new()
    study.position=Vector3(3.5,0,10)
    study.rotation.y=PI/2
    hall.add_child(study)
    await tick()
    observations.student_bay=xyz(study.position)
    observations.student_yaw_degrees=90
    check("study stands over museum floor",not floor_at(study.global_position).is_empty())
    var approach: Vector3=study.to_global(Vector3(0,0,2))
    check("student approach has floor",not floor_at(approach).is_empty())
    var capsule:=CapsuleShape3D.new()
    capsule.radius=0.26
    capsule.height=1.6
    var query:=PhysicsShapeQueryParameters3D.new()
    query.shape=capsule
    query.transform=Transform3D(Basis.IDENTITY,approach+Vector3.UP*0.91)
    query.collision_mask=1|4
    var obstacles: Array=[]
    for hit in hall.get_world_3d().direct_space_state.intersect_shape(query):
        if hit.collider!=museum.get("_player") and not study.is_ancestor_of(hit.collider):obstacles.append(str(hit.collider.get_path()))
    observations.approach_obstacles=obstacles
    check("approach clear of other bodies",obstacles.is_empty())
    check("printed program initializes inside museum",study.rods.size()==64 and study.marks.size()==64 and not study.status.text.is_empty())
    var original: Array=study.marks.duplicate()
    var samples: Array=study.samples.duplicate()
    observations.student_half_count=original.count(true)
    await snapshot("student-half",study.to_global(Vector3(0,2.3,3.8)),study.to_global(Vector3(0,1.7,0)),54)
    study.point.position.x=0
    study.point.action()
    check("inherited action changes bias in the hall",study.probability==0.75 and study.samples==samples)
    observations.student_three_quarters_count=study.marks.count(true)
    await snapshot("student-biased",study.to_global(Vector3(0,2.3,3.8)),study.to_global(Vector3(0,1.7,0)),54)
    study.point.position.x=-0.75
    var biased: Array=study.marks.duplicate()
    study.point.action()
    check("point replay retains biased field",study.marks==biased)
    study.probability=0.5
    study.build_pattern()
    check("restored threshold restores original field",study.marks==original)
    study.free()
    var edited=load(spec.bias).new()
    edited.position=Vector3(3.5,0,10)
    edited.rotation.y=PI/2
    hall.add_child(edited)
    check("actual edited source uses30 percent threshold",is_equal_approx(edited.probability,0.3) and edited.samples==samples)
    observations.student_030_count=edited.marks.count(true)
    await snapshot("student-030",edited.to_global(Vector3(0,2.3,3.8)),edited.to_global(Vector3(0,1.7,0)),54)
    edited.free()


func _tri(cells: Dictionary, c: int, r: int, edge: String) -> int:
    var fwd: bool = cells.get(Vector2i(c, r), false)
    var t: int
    if fwd:
        t = 0 if edge in ["far", "right"] else 1
    else:
        t = 0 if edge in ["far", "left"] else 1
    return (r * _cols + c) * 2 + t


func _regions(cells: Dictionary, cols: int, rows: int) -> Dictionary:
    _cols = cols
    var parent: Array = []
    for i in cols * rows * 2:
        parent.append(i)
    var find := func(x: int) -> int:
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x
    var join := func(a: int, b: int) -> void:
        parent[find.call(a)] = find.call(b)
    for r in rows:
        for c in cols:
            if c + 1 < cols:
                join.call(_tri(cells, c, r, "right"), _tri(cells, c + 1, r, "left"))
            if r + 1 < rows:
                join.call(_tri(cells, c, r, "near"), _tri(cells, c, r + 1, "far"))
    var sides: Dictionary = {}   # root -> {far, near, left, right}
    var mouths: Dictionary = {}  # root -> how many boundary cell-edges open into it
    for r in rows:
        for c in cols:
            var pairs: Array = []
            if r == 0: pairs.append(["far", _tri(cells, c, r, "far")])
            if r == rows - 1: pairs.append(["near", _tri(cells, c, r, "near")])
            if c == 0: pairs.append(["left", _tri(cells, c, r, "left")])
            if c == cols - 1: pairs.append(["right", _tri(cells, c, r, "right")])
            for p in pairs:
                var root: int = find.call(p[1])
                if not sides.has(root):
                    sides[root] = {}
                sides[root][p[0]] = true
                mouths[root] = int(mouths.get(root, 0)) + 1
    var roots: Dictionary = {}
    for i in cols * rows * 2:
        roots[find.call(i)] = true
    var closed := 0
    var through := false
    var far_near := false
    for root in roots.keys():
        if not sides.has(root):
            closed += 1
        else:
            var s: Dictionary = sides[root]
            if (s.has("far") and s.has("near")) or (s.has("left") and s.has("right")):
                through = true
            if s.has("far") and s.has("near"):
                far_near = true
    var mouth_counts: Array = []
    for root in mouths.keys():
        mouth_counts.append(int(mouths[root]))
    mouth_counts.sort()
    # how many triangles each OPEN region holds: how deep a body can go into it
    var tri_count: Dictionary = {}
    for i in cols * rows * 2:
        var rt: int = find.call(i)
        tri_count[rt] = int(tri_count.get(rt, 0)) + 1
    var open_sizes: Array = []
    for root in sides.keys():
        open_sizes.append(int(tri_count.get(root, 0)))
    open_sizes.sort()
    return {"regions": roots.size(), "open": sides.size(), "closed": closed, "through": through,
        "far_near": far_near, "mouths": mouth_counts, "open_sizes": open_sizes}


