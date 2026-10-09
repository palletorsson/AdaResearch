# Noise 6 Wall

A sum of six scales, and what it takes to see one of them. Every line below is from `algorithms/randomness/shadernoisespace/WallNoiseShader.gdshader` and `noiseroom.gd`, the shader and script this hall places.

Make the bound a uniform.

```glsl
uniform int layers : hint_range(1, 6) = 6;
uniform int show_term : hint_range(0, 1) = 0;   // 0 = the room's picture, 1 = the sum alone
```

Six is the shipped room, and it was written into the loop as a literal, which is why this room's own text could propose isolating an octave that nobody could isolate.

Add the terms.

```glsl
    for (int i = 0; i < layers; i++) {
        vec2 animated_pos = pos * frequency;
        animated_pos.x += sin(t * 0.3 + pos.y * 0.5) * 0.3;
        animated_pos.y += cos(t * 0.2 + pos.x * 0.3) * 0.2;

        value += amplitude * abs(noise2d(animated_pos));
        amplitude *= 0.5;
        frequency *= 2.0;
    }
```

Half the amplitude and twice the frequency each time round. Two consequences, and the room shows both: the sum of the amplitudes is 0.5 for one term and 0.984375 for six, which is a brightness difference and nothing else; and each term is ADDED, so nothing a later term does can move what an earlier one put there.

Show the sum on its own.

```glsl
    if (show_term == 1) {
        float bare = clamp(cloud_noise(uv * cloud_scale, time * time_scale) * term_gain, 0.0, 1.0);
        ALBEDO = vec3(bare);
        EMISSION = vec3(bare) * 0.9;
        ALPHA = 1.0;
    }
```

No turbulence, no colour, no corner darkening. The patch emits its own value rather than being lit, because a comparison surface in a dark interior photographs black; `term_gain` is the same on all four, and the plate says what it is.

Build four patches that differ in one thing.

```gdscript
		mat.set_shader_parameter("layers", n)
		mat.set_shader_parameter("show_term", 1)
		mat.set_shader_parameter("time", 0.0)
		mat.set_shader_parameter("cloud_scale", 2.0)
		mat.set_shader_parameter("cloud_density", 1.0)
```

Every patch gets the same everything except `n`. The probe reads all four materials back and fails if any other parameter differs, because a fair comparison is a claim that has to be checkable.

Stop every clock, not one of them.

```gdscript
func set_frozen(frozen: bool) -> void:
	animation = "frozen" if frozen else "live"
	animation_enabled = not frozen
	color_cycling = not frozen
	cloud_density_animation = not frozen
	for m in [room_material, wall_material]:
		if m != null:
			m.set_shader_parameter("time_scale", 0.0 if frozen else 0.2)
	for p in _patches:
		var mat: ShaderMaterial = (p as Dictionary)["mat"]
		if mat != null:
			mat.set_shader_parameter("time_scale", 0.0 if frozen else 0.2)
```

Three movers and a shader clock, on the walls and on all four patches. Freezing one of them leaves a still picture of a moving thing.

Give every instance its own materials.

```gdscript
		if room_material != null and not room_material.resource_local_to_scene:
			room_material = room_material.duplicate() as ShaderMaterial
			room_material.resource_local_to_scene = true
```

The scene's materials were shared resources, so a uniform set in one hall was set in every placement of this room. Duplicating changes no pixel and stops the leak.

And speak only to your own hall.

```gdscript
	var hall: Node = _hall_ancestor()
	for r in get_tree().get_nodes_in_group("noise_rooms"):
		if hall != null and not hall.is_ancestor_of(r):
			continue
```

The same boundary the voxel bench needed a room earlier: the museum streams several halls at once, and a group is not a place.

Stage it in a map.

```
shader_noise_space:180#stand:panel
```

`stand:panel` builds the board, the four patches, the plate and LAYERS, BASIS and FREEZE; `layers` sets the count from the token. Without it the artifact is the immersive interior it always was, six layers deep, with the generator axis an earlier pass gave it.

And a board is not a room.

```gdscript
func _strip_enclosure_for_panel() -> void:
	for n in ["RoomContainer", "WallsContainer", "LightingContainer", "Camera3D"]:
		var node: Node = get_node_or_null(n)
		if node != null:
			remove_child(node)
			node.queue_free()
```

The staged body used to carry the whole 27 m enclosure behind the board. Removed rather than hidden: an extent is measured from the tree, and the museum decides where a body may stand from its extent. Put a 2 m board across a 1 m corridor and the museum will seal the route and then slide the body aside to reopen it — which is the right call, and worth knowing before you write that the board stands where you put it.
