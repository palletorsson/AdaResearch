extends "res://tools/probes/transformation_encounters.gd"

func slider(control: Node,value: float) -> void:
    control.set_normalized_value(value)
    control.slider_moved.emit(Vector3.ZERO)

func pixels(mixer: Node) -> PackedByteArray:
    return mixer._material.albedo_texture.get_image().get_data()

func point_action(study: Node3D, words: String) -> void:
    for caption in study.find_children("*","Label3D",true,false):
        if caption.text==words:
            study.point.global_position=study.to_global(Vector3(caption.position.x,1.05,0.3))
            study.point.action()
            return

func landing_checks() -> void:
    museum.call("flush_stamps")
    await create_timer(0.5).timeout
    var mixer=find_scene("/noise_mixer.gd")
    check("installed mixer and controls exist",mixer!=null and mixer._octaves_slider!=null and mixer._persistence_slider!=null)
    if mixer==null:return
    observations.mixer=xyz(hall.to_local(mixer.global_position))
    var saved_offsets: Array=mixer._octave_offsets.duplicate();var saved_rng: int=mixer._rng.state
    slider(mixer._octaves_slider,0)
    var one:=pixels(mixer)
    check("OCT control selects one layer",mixer.octaves==1)
    slider(mixer._lacunarity_slider,1);slider(mixer._persistence_slider,0)
    check("single source layer ignores both ratio controls",pixels(mixer)==one and mixer._octave_offsets==saved_offsets and mixer._rng.state==saved_rng)
    slider(mixer._lacunarity_slider,1.0/3.0);slider(mixer._persistence_slider,0.5)
    await snapshot("installed-one",mixer.global_position+Vector3(0,1.3,1.5),mixer.global_position,60)
    slider(mixer._octaves_slider,0.5)
    var four:=pixels(mixer)
    check("four-layer source picture differs",mixer.octaves==4 and four!=one)
    slider(mixer._persistence_slider,0)
    check("PER changes multi-layer picture without new offsets",pixels(mixer)!=four and mixer._octave_offsets==saved_offsets and mixer._rng.state==saved_rng)
    slider(mixer._persistence_slider,0.5)
    check("returning source parameters restores exact image",pixels(mixer)==four)
    await snapshot("installed-four",mixer.global_position+Vector3(0,1.3,1.5),mixer.global_position,60)
    var old_seed: int=mixer.seed_value
    var seed_button=mixer._control_panel.find_child("Btn_0",true,false).get_node("InteractableAreaButton")
    seed_button.button_pressed.emit(seed_button)
    var oracle:=RandomNumberGenerator.new();oracle.seed=mixer.seed_value
    var expected: Array=[]
    for i in range(8):expected.append(Vector2(oracle.randf_range(-100,100),oracle.randf_range(-100,100)))
    check("SEED button generates offsets reproducible from chosen seed",mixer._octave_offsets==expected and mixer._rng.state==oracle.state)
    observations.chosen_seed=mixer.seed_value
    mixer.apply_grid_config({"seed":old_seed})
    check("restoring source seed recovers saved image",pixels(mixer)==four and mixer._octave_offsets==saved_offsets)
    var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"spec.json"))
    var study=load(spec.lesson).new()
    var location:=Vector3(9.5,0,12)
    var at: Vector3=hall.to_global(location)
    var floor_query:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*3,at-Vector3.UP*2,1)
    var ground:=hall.get_world_3d().direct_space_state.intersect_ray(floor_query)
    check("learner bay has an existing support surface",not ground.is_empty())
    if ground.is_empty():study.free();return
    location.y=hall.to_local(ground.position).y+0.02
    study.position=location;study.rotation.y=-PI/2
    hall.add_child(study);await tick()
    observations.learner_origin=xyz(location)
    observations.support_collider=str(ground.collider.get_path())
    var approach: Vector3=study.to_global(Vector3(0,0,1.25))
    check("learner approach has nearby floor",not floor_at(approach).is_empty())
    var shape:=CapsuleShape3D.new();shape.radius=0.26;shape.height=1.6
    var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1|4
    query.transform=Transform3D(Basis.IDENTITY,approach+Vector3.UP*0.92)
    var obstacles:=[]
    for hit in hall.get_world_3d().direct_space_state.intersect_shape(query):
        if hit.collider!=museum.get("_player") and not study.is_ancestor_of(hit.collider):obstacles.append(str(hit.collider.get_path()))
    observations.approach_obstacles=obstacles
    check("learner standing approach is clear",obstacles.is_empty())
    var eye: Vector3=study.to_global(Vector3(0,2.1,3.65));var target: Vector3=study.to_global(Vector3(0,1.63,-0.3))
    await snapshot("student-one",eye,target,65)
    point_action(study,"OCT");point_action(study,"OCT");point_action(study,"OCT")
    study.point.position=Vector3(0,1.05,0.3)
    check("carried point adds three layers",study.layer_count==4)
    var baseline: Array=study.raw.duplicate();var parts: Array=study.parts.duplicate(true)
    var sum_ok:=true
    for y in range(study.SIDE):
        for x in range(study.SIDE):
            sum_ok=sum_ok and absf(study.raw[y*study.SIDE+x]-mixer._fbm(float(x)/study.SIDE,float(y)/study.SIDE))<0.000001
    check("learner raw sums agree with installed mixer at all shared addresses",sum_ok)
    observations.raw_four=[study.raw.min(),study.raw.max()]
    await snapshot("student-four",eye,target,65)
    point_action(study,"WEIGHT")
    check("point WEIGHT changes later contributions only",is_equal_approx(study.persistence,0.3) and study.parts[0]==parts[0] and study.raw!=baseline)
    study.point.position=Vector3(0,1.05,0.3)
    await snapshot("student-low-weight",eye,target,65)
    study.persistence=0.5;study.sample_fields()
    point_action(study,"SEED")
    check("point SEED changes offsets and field",study.sample_seed==43 and study.raw!=baseline)
    study.sample_seed=42
    point_action(study,"REPLAY")
    check("point REPLAY restores baseline at current settings",study.layer_count==4 and study.raw==baseline)
    study.point.position=Vector3(0,1.05,0.3)
    var fixed: Image=study.screens[1].material_override.albedo_texture.get_image()
    var stretched: Image=study.screens[2].material_override.albedo_texture.get_image()
    study.free()
    var changed=load(spec.quarter).new();changed.position=location;changed.rotation.y=-PI/2
    hall.add_child(changed);changed.layer_count=4;changed.sample_fields()
    var quarter_ok:=true
    for i in range(baseline.size()):quarter_ok=quarter_ok and is_equal_approx(changed.raw[i],baseline[i]*0.25)
    check("complete quarter-sum edit scales raw and preserves parts",quarter_ok and changed.parts==parts)
    check("quarter-sum changes fixed display",fixed.get_data()!=changed.screens[1].material_override.albedo_texture.get_image().get_data())
    var actual: Image=changed.screens[2].material_override.albedo_texture.get_image()
    var max_error:=0.0
    for y in range(stretched.get_height()):
        for x in range(stretched.get_width()):max_error=maxf(max_error,absf(actual.get_pixel(x,y).r-stretched.get_pixel(x,y).r))
    check("quarter-sum preserves stretched display within one pixel level",max_error<=0.004)
    observations.quarter_raw=[changed.raw.min(),changed.raw.max()];observations.stretched_pixel_max_error=max_error
    await snapshot("student-quarter-sum",eye,target,65)
    changed.free()
    study=load(spec.lesson).new();study.position=location;study.rotation.y=-PI/2
    hall.add_child(study);study.layer_count=4;study.sample_fields()
    await snapshot("hall-with-study",hall.to_global(Vector3(6.5,16,0)),hall.to_global(Vector3(6.5,0,11)),63)
    observations.scope="Native hall and supplied control/PointBody action events; exact learner and edited program. No physical headset, independent learner or full-route acceptance."
    study.free()
