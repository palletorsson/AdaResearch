extends "res://tools/probes/transformation_encounters.gd"
const Pointer = preload("res://addons/godot-xr-tools/events/pointer_event.gd")
var pointer: Node3D

func press(controls: Node, index: int) -> void:
    var area=controls.panel.get_node("Btn_%d/InteractableAreaButton" % index)
    Pointer.pressed(pointer,area,area.global_position)
    Pointer.released(pointer,area,area.global_position)

func fingerprint(art: Node) -> int:
    var record: Array=[]
    for child in art.get_children():
        if child is Camera3D or child.name=="ArtSeedControls":continue
        describe(child,record)
    return hash(var_to_bytes(record))

func describe(node: Node, record: Array) -> void:
    record.append(node.get_class())
    if node is Node3D:
        # The sculpture slowly spins; compare its generated pose at time zero.
        record.append(Transform3D.IDENTITY if node.name=="LiquidComposition" else node.transform)
    if node is MeshInstance3D and node.mesh:
        record.append(node.mesh.get_class())
        for i in range(node.mesh.get_surface_count()):
            record.append(hash(var_to_bytes(node.mesh.surface_get_arrays(i))))
            material(node.get_active_material(i),record)
    if node is MultiMeshInstance3D and node.multimesh:
        record.append(node.multimesh.buffer)
        material(node.material_override,record)
    if node is CSGPrimitive3D:
        for key in ["radius","height","width","depth","sides","radial_segments","rings","ring_sides","smoothing","operation"]:
            for prop in node.get_property_list():
                if prop.name==key:record.append([key,node.get(key)])
        material(node.material,record)
    if node is Light3D:record.append([node.light_color,node.light_energy,node.rotation])
    for child in node.get_children():describe(child,record)

func material(mat: Material, record: Array) -> void:
    if mat is StandardMaterial3D:
        record.append([mat.albedo_color,mat.metallic,mat.roughness,mat.transparency])
        if mat.normal_texture is NoiseTexture2D:
            var n=mat.normal_texture.noise
            record.append([n.seed,n.frequency,n.noise_type,n.fractal_octaves])

func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(0.8).timeout
    pointer=Node3D.new();root.add_child(pointer)
    var env=find_scene("/envOne.gd")
    var sculpt=find_scene("/SculptOne.gd")
    check("both generated artworks installed",env!=null and sculpt!=null)
    if env==null or sculpt==null:return
    sculpt.set_process(false)
    observations.artworks=[]
    for art in [env,sculpt]:
        var controls=art.get_node_or_null("ArtSeedControls")
        var title="kitbash" if art==env else "sculpture"
        check(title+" seed console installed",controls!=null and controls.panel!=null)
        if controls==null or controls.panel==null:continue
        var original_camera=art.get_node("Camera3D")
        art.set_generation_seed(42)
        await tick()
        var original:=fingerprint(art)
        var count: int=art.get_child_count()
        check(title+" seed42 displayed on readout and slider",controls.readout.text=="SEED 042" and controls.slider._label.text=="42")
        press(controls,2)
        check(title+" pointer NEXT selects43 and changes artwork",art.get_generation_seed()==43 and fingerprint(art)!=original)
        press(controls,0)
        check(title+" pointer PREVIOUS restores complete seed42 artwork",art.get_generation_seed()==42 and fingerprint(art)==original)
        press(controls,1)
        check(title+" pointer REPLAY reproduces meshes materials and placements",fingerprint(art)==original)
        press(controls,3)
        check(title+" NEW SEED selects a different seed",art.get_generation_seed()!=42 and controls.chosen_seed==art.get_generation_seed())
        art.set_generation_seed(42)
        check(title+" return after NEW SEED is exact",fingerprint(art)==original)
        var values_ok:=true
        for value in [1,42,43,100]:
            var handle=controls.slider._slider
            var physical: float=lerpf(handle.slider_limit_min,handle.slider_limit_max,float(value-1)/99.0)
            handle.move_slider(physical)
            await create_timer(0.35).timeout
            values_ok=values_ok and art.get_generation_seed()==value and controls.slider._label.text==str(value)
        check(title+" physical slider events select1 42 43 100",values_ok)
        press(controls,2)
        check(title+" NEXT bounded at100",art.get_generation_seed()==100)
        art.set_generation_seed(1);press(controls,0)
        check(title+" PREVIOUS bounded at1",art.get_generation_seed()==1)
        # Generation must not reseed other works or consume their global stream.
        seed(724);var expected: int=randi();seed(724)
        art.set_generation_seed(42)
        check(title+" rebuild leaves global RNG unchanged",randi()==expected)
        await tick()
        check(title+" repeated rebuilds preserve child count camera and controls",art.get_child_count()==count and is_instance_valid(original_camera) and controls==art.get_node("ArtSeedControls"))
        var approach: Vector3=controls.to_global(Vector3(0,0,0.75))
        check(title+" console and visitor approach have floor",not floor_at(controls.global_position).is_empty() and not floor_at(approach).is_empty())
        var body:=CapsuleShape3D.new();body.radius=0.26;body.height=1.6
        var query:=PhysicsShapeQueryParameters3D.new();query.shape=body;query.collision_mask=1|4
        query.transform=Transform3D(Basis.IDENTITY,approach+Vector3.UP*0.91)
        var blockers: Array=[]
        for hit in hall.get_world_3d().direct_space_state.intersect_shape(query):
            if hit.collider!=museum.get("_player"):blockers.append(str(hit.collider.get_path()))
        check(title+" visitor has body sized clear approach",blockers.is_empty())
        observations[title+"_approach_blockers"]=blockers
        check(title+" controls stay hand sized",is_equal_approx(controls.global_basis.get_scale().x,1.0))
        observations.artworks.append({"name":title,"at":xyz(hall.to_local(art.global_position)),"controls":xyz(hall.to_local(controls.global_position)),"seed":42,"fingerprint":original})
        await snapshot(title+"-controls",controls.to_global(Vector3(0,1.38,1.2)),controls.to_global(Vector3(0,1.28,0)),52)
        if art==sculpt:
            await snapshot("sculpture-seed42",hall.to_global(Vector3(9,2.9,21.4)),art.global_position+Vector3.UP*1.2,57)
            press(controls,2)
            await snapshot("sculpture-seed43",hall.to_global(Vector3(9,2.9,21.4)),art.global_position+Vector3.UP*1.2,57)
            press(controls,0)
        else:
            await snapshot("kitbash-seed42",hall.to_global(Vector3(10,8,14)),art.global_position+Vector3.UP*1.6,72)
            press(controls,2)
            await snapshot("kitbash-seed43",hall.to_global(Vector3(10,8,14)),art.global_position+Vector3.UP*1.6,72)
            press(controls,0)
    var other:=fingerprint(sculpt)
    env.set_generation_seed(43)
    check("one artwork's control leaves the other intact",fingerprint(sculpt)==other and sculpt.get_generation_seed()==42)
    env.set_generation_seed(42)
    await snapshot("hall-with-art-controls",hall.to_global(Vector3(6,25,1)),hall.to_global(Vector3(6,0,19)),65)
    observations.scope="Native museum. Supplied XRTools pointer events and slider-handle moves. No physical headset acceptance; exact replay within this project/engine version, not across future generator edits."
