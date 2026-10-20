# A field kept

## Learning elements

- Previous state and next state
- Reading neighbouring cells in a texture
- Reaction, diffusion, feed and loss
- A starting difference and a repeated update
- Data, display and receiver as separate things

<!-- @shader_state_chamber -->

Touch the large wall, then let go. The mark stays. STEP changes it once. RUN lets the field continue; HOLD stops after the current batch. INK changes how you see the record. It does not replace the record.

In Pink, the point chose three amounts for a material. Here the same point plants a difference into a field. Keep its class, the cube, plinth and box helper. Replace the composition shader with a display of saved data, and add the update shader and its runner. Your small study stands beside the installed wall; it has its own field and controls.

## What must survive a frame?

Every address stores two numbers, U and V, between zero and one. Start with U = 1, V = 0, except three small discs containing U = 0.5, V = 1. The update reads the **old** U and V, and their neighbours, then writes a **new** pair. Every cell in that step reads the same completed old field. Writing into the field while reading it would make update order part of the rule.

The Gray–Scott rule combines neighbour exchange with three local terms. `U * V * V` consumes U and produces V. Feed replenishes U toward one; feed plus loss removes V. This is a discretized model, not a measurement of chemicals in the museum.[^model]

Keep the distinction from Water: TIME can make a surface move without retaining its previous surface. Here a completed output becomes the next input. The data texture is separate from the colours you see.

## Two passes through the same study

First run the complete program and compare CLEAR, a planted mark, STEP, RUN/HOLD and INK. Explain which actions change the stored values. Trace `previous_state` through the update and the completed texture back into the next input. That is the central new capability.

Then open the numerical rule: predict one cell, change FEED and compare equal step counts. The chemistry coefficients are a supplied model to investigate. The render-target scheduling and byte packing below keep it executable; understanding every transport detail is not an additional entry requirement. Both passes use the same program and field.

## Read the update rule

In `field_step.gdshader`, `read_state` retrieves one pair. `lap` compares it with eight neighbours: centre −1, side neighbours 0.2 each, diagonals 0.05 each. The weights sum to zero, so a uniform field has no exchange. Opposite edges wrap; this is a periodic square field even when displayed on a sphere.

The coefficients are Du = 1, Dv = 0.5, F = 0.055, K = 0.062, with one numerical step of dt = 1. One step is not one second. Clamping bounds concentrations; it does not make arbitrary rates or timesteps accurate.

`integrate` distinguishes advancing the model from planting a mark. The brush overwrites a small disc after the update, or on its own while held. Planting is an intervention, not a chemical reaction.

The short packing functions are supplied transport code: two 12-bit numbers share an RGB8 pixel. They introduce quantization of 1/4095. There is no `source_color` hint on this data sampler. Colour conversion would corrupt the numbers. Focus on the reads, update and final write; the full support is visible here.

<!-- student-code:field_step.gdshader -->
```glsl
shader_type canvas_item;
render_mode unshaded, blend_disabled;
// Data, not colour: two 12-bit concentrations packed in RGB8. No source_color hint.
// The spare low nibbles share blue; alpha stays opaque on every renderer.
uniform sampler2D previous_state : filter_nearest, repeat_enable;
uniform float feed = 0.055;
uniform float kill = 0.062;
uniform bool integrate = true;
uniform vec2 brush = vec2(-10.0);
uniform float brush_radius = 0.04;
vec2 read_state(vec2 uv) {
    vec3 bytes = floor(texture(previous_state, uv).rgb * 255.0 + 0.5);
    return (bytes.rg * 16.0 + vec2(floor(bytes.b / 16.0), mod(bytes.b, 16.0))) / 4095.0;
}
vec4 pack_state(vec2 value) {
    vec2 bits = floor(clamp(value, vec2(0.0), vec2(1.0)) * 4095.0 + 0.5);
    return vec4(floor(bits / 16.0), mod(bits.x, 16.0) * 16.0 + mod(bits.y, 16.0), 255.0) / 255.0;
}
void fragment() {
    vec2 c = read_state(UV);
    if (integrate) {
        vec2 p = 1.0 / vec2(textureSize(previous_state, 0));
        vec2 lap = -c;
        lap += 0.2 * (read_state(UV + vec2(p.x, 0.0)) + read_state(UV - vec2(p.x, 0.0))
            + read_state(UV + vec2(0.0, p.y)) + read_state(UV - vec2(0.0, p.y)));
        lap += 0.05 * (read_state(UV + p) + read_state(UV - p)
            + read_state(UV + vec2(p.x, -p.y)) + read_state(UV + vec2(-p.x, p.y)));
        float reaction = c.x * c.y * c.y;
        // Gray–Scott: dt=1, Du=1, Dv=.5 with this weighted nine-cell stencil.
        c += vec2(lap.x - reaction + feed * (1.0 - c.x),
            0.5 * lap.y + reaction - (feed + kill) * c.y);
    }
    if (distance(UV, brush) < brush_radius) c = vec2(0.5, 1.0);
    COLOR = pack_state(c);
}
```

At the centre of a seeded disc, all neighbours initially agree. The first update gives U ≈ **0.0275**, V = **1** after clamping. Away from the discs, U = 1, V = 0 stays unchanged. Predict both before pressing STEP.

## Keep the output before using it again

`field.gd` is the supplied GPU runner, printed in full. `_schedule` binds `state_texture` as the first input, then chains up to eight separate render targets. `_completed` publishes only the finished last texture, and switches groups. Two groups prevent the next batch from overwriting the texture it still reads. Old dependencies are disconnected before a group is reused.

Each SubViewport renders once, then holds its pixels.[^viewport] RUN requests up to eight steps per rendered frame toward 240 model steps per second; slower rendering slows the model. HOLD finishes the current batch. RESET cancels queued work and restores the three discs after any in-flight batch. CLEAR restores the uniform background. Neither changes F or K. A mark queue holds at most 32 requests. There is no CPU chemistry or GPU readback in this live path.

<!-- student-code:field.gd -->
```gdscript
extends Node
## Each pass reads an immutable previous texture. The next group is scheduled
## only after frame_post_draw. No readback or CPU chemistry in the live path.
signal changed
const SIZE := 96
const PASSES := 8
const STEP = preload("./field_step.gdshader")
var views: Array[SubViewport] = []
var materials: Array[ShaderMaterial] = []
var state_texture: Texture2D
var initial_texture: ImageTexture
var running := false
var busy := false
var iterations := 0
var feed := .055
var kill := .062
var pending_steps := 0
var pending_reset := -1
var brush_queue: Array[Vector2] = []
var _group := 0
var _last := 0
var _count := 0
var _integrating := false
var _budget := 0.0

func _ready()->void:
    for i in range(PASSES*2):
        var view:=SubViewport.new();view.name="State_%02d"%i
        view.size=Vector2i(SIZE,SIZE);view.disable_3d=true;view.use_hdr_2d=false
        view.render_target_update_mode=SubViewport.UPDATE_DISABLED;add_child(view)
        var rect:=ColorRect.new();rect.size=Vector2(SIZE,SIZE)
        var mat:=ShaderMaterial.new();mat.shader=STEP;rect.material=mat;view.add_child(rect)
        views.append(view);materials.append(mat)
    RenderingServer.frame_post_draw.connect(_completed)
    _reset_now(true)

static func encode(a:float,b:float)->Color:
    var u:=roundi(clampf(a,0,1)*4095);var v:=roundi(clampf(b,0,1)*4095)
    return Color(float(u/16)/255.0,float(v/16)/255.0,float((u%16)*16+v%16)/255.0,1)

static func decode(c:Color)->Vector2:
    var packed:=roundi(c.b*255)
    return Vector2(roundi(c.r*255)*16+packed/16,roundi(c.g*255)*16+packed%16)/4095.0

func reset(seeded:bool=true)->void:
    running=false;pending_steps=0;brush_queue.clear();_budget=0
    if busy:pending_reset=int(seeded)
    else:_reset_now(seeded)

func _reset_now(seeded:bool)->void:
    var image:=Image.create(SIZE,SIZE,false,Image.FORMAT_RGB8);image.fill(encode(1,0))
    if seeded:
        for at in [Vector2(.32,.35),Vector2(.52,.49),Vector2(.67,.66)]:
            for y in range(SIZE):
                for x in range(SIZE):
                    if Vector2((x+.5)/SIZE,(y+.5)/SIZE).distance_to(at)<.055:image.set_pixel(x,y,encode(.5,1))
    initial_texture=ImageTexture.create_from_image(image);state_texture=initial_texture
    for mat in materials:mat.set_shader_parameter("previous_state",initial_texture)
    iterations=0;pending_reset=-1;changed.emit()

func mark(uv:Vector2)->void:
    if uv.x<0 or uv.y<0 or uv.x>1 or uv.y>1:return
    if brush_queue.size()<32:brush_queue.append(uv)

func step(count:int=1)->void:
    running=false;pending_steps+=clampi(count,1,20000)

func _process(delta:float)->void:
    if busy:return
    if pending_reset>=0:_reset_now(pending_reset==1)
    var count:=0
    if pending_steps>0:count=mini(PASSES,pending_steps);pending_steps-=count
    elif running:
        _budget=minf(_budget+delta*240.0,PASSES)
        count=int(_budget);_budget-=count
    if count==0 and brush_queue.is_empty():return
    _schedule(maxi(1,count),count>0)

func _schedule(count:int,integrating:bool)->void:
    busy=true;_count=count;_integrating=integrating
    # Break old dependencies: disabled targets keep their completed pixels.
    for mat in materials:mat.set_shader_parameter("previous_state",initial_texture)
    var source:Texture2D=state_texture
    for i in range(count):
        var slot:=_group*PASSES+i;var mat:=materials[slot]
        mat.set_shader_parameter("previous_state",source)
        mat.set_shader_parameter("feed",feed);mat.set_shader_parameter("kill",kill)
        mat.set_shader_parameter("integrate",integrating)
        mat.set_shader_parameter("brush",brush_queue.pop_front() if not brush_queue.is_empty() else Vector2(-10,-10))
        views[slot].render_target_update_mode=SubViewport.UPDATE_ONCE
        source=views[slot].get_texture();_last=slot

func _completed()->void:
    if not busy:return
    state_texture=views[_last].get_texture()
    if _integrating:iterations+=_count
    _group=1-_group;busy=false;changed.emit()

func _exit_tree()->void:
    if RenderingServer.frame_post_draw.is_connected(_completed):RenderingServer.frame_post_draw.disconnect(_completed)
```

## Colour is a reading of the field

`recipe.gdshader` reads V and maps it into ink. The transition from paper to ink spans V = 0.05 to 0.30, so fully dark ink does not mean V = 1. This displayed colour never feeds the update. The same texture coats the point, cube and square: three views of one flat record, not three simulations or diffusion across their physical surfaces.

<!-- student-code:recipe.gdshader -->
```glsl
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D state_texture : filter_nearest, repeat_enable;
uniform vec4 paper : source_color = vec4(0.88,0.85,0.76,1.0);
uniform vec4 ink : source_color = vec4(0.025,0.08,0.085,1.0);
void fragment() {
    vec3 bytes = floor(texture(state_texture, UV).rgb * 255.0 + 0.5);
    float b = (bytes.g * 16.0 + mod(bytes.b,16.0)) / 4095.0;
    // Display mapping only; never fed into the solver.
    vec3 colour = mix(paper.rgb, ink.rgb, smoothstep(0.05,0.30,b));
    ALBEDO = colour;
    ROUGHNESS = 0.55;
    EMISSION = colour * 0.14;
}
```

## Continue the point and cube in the museum

Keep the five files together. The prepared AdaResearch project supplies XRTools, player, camera, lighting and the push-button prefab at `res://commons/interactables/push_button.tscn`. That prefab creates the named `InteractableAreaButton` receiver used below. It supplies a physical press and pointer event; our code decides what the press does. No museum artifact constructs the learner's field or geometry.

Open `res://doc/book/studies/shaders-lineage/State.tscn` and Run Current Scene. The supplied launcher places this small study beside the existing State chamber; set its LESSON preload to your saved `shaping.gd`. Alternatively attach the script to a Node3D at floor level, unit scale, with a clear 3 × 3 metre area in the prepared museum.

Hold the point. Its local X from −1 to 1 selects left to right; Y from 0.5 to 2.5 selects bottom to top. Trigger plants a disc. Z does not select an address: this is an XY selector, not a contact detector. Outside that rectangle it plants nothing. Moving without triggering plants nothing. Release keeps the point and, while HELD, the field still. The installed large wall additionally accepts direct touch; that input adapter is outside this reconstruction.

The five nearby buttons operate your field: RUN/HOLD, STEP, RESET, CLEAR and INK. The large wall's own desk controls its separate field. The board here is a visual display; the inherited cube and plinth retain their colliders.

<!-- student-code:shaping.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const Recipe = preload("recipe.gdshader")
const Field = preload("field.gd")
const PushButton = preload("res://commons/interactables/push_button.tscn")
const FEED := 0.055
var material := ShaderMaterial.new()
var control: PointBody
var readout := Label3D.new()
var field: Node
var alternate_ink := false
var buttons: Dictionary = {}
var cube: StaticBody3D

func _ready() -> void:
    material.shader = Recipe
    cube = make_box(Vector3(-0.6, 0.9, 0), Vector3.ONE * 0.60, material)
    make_box(Vector3(-0.6, 0.30, 0), Vector3(0.8, 0.60, 0.8))
    control = PointBody.new()
    control.position = Vector3(0.65, 1.2, 1.2)
    add_child(control)
    control.coat(material)
    control.action_pressed.connect(plant)
    var lamp := OmniLight3D.new()
    lamp.position = Vector3(-1.3, 2.4, 1.8)
    lamp.omni_range = 4.0
    lamp.light_energy = 5.0
    lamp.shadow_enabled = true
    add_child(lamp)
    readout.position = Vector3(0, 2.72, -0.5)
    readout.font_size = 28
    readout.pixel_size = 0.002
    add_child(readout)
    var board := MeshInstance3D.new()
    var quad := QuadMesh.new()
    quad.size = Vector2(2, 2)
    board.mesh = quad
    board.position = Vector3(0, 1.5, -0.5)
    board.material_override = material
    add_child(board)
    make_box(Vector3(0, 0.93, 1.8), Vector3(2.4, 0.10, 0.5))
    for i in range(5):
        var key: String = ["RUN/HOLD", "STEP", "RESET", "CLEAR", "INK"][i]
        var button = PushButton.instantiate()
        button.position = Vector3(-0.96 + i * 0.48, 0.99, 1.8)
        add_child(button)
        buttons[key] = button
        # This declared prefab creates its named press receiver.
        button.get_node("InteractableAreaButton").button_pressed.connect(func(_b): act(key))
        var label := Label3D.new()
        label.text = key
        label.font_size = 24
        label.pixel_size = 0.0015
        label.position = button.position + Vector3(0, 0.015, 0.19)
        label.rotation_degrees.x = -60
        add_child(label)
    field = Field.new()
    field.feed = FEED
    add_child(field)
    field.changed.connect(show_state)
    show_state()



func make_box(at: Vector3, size: Vector3, paint: Material = null) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.position = at
    var surface := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    surface.mesh = box
    var grey := StandardMaterial3D.new()
    grey.albedo_color = Color(0.12, 0.12, 0.12)
    surface.material_override = grey if paint == null else paint
    body.add_child(surface)
    var boundary := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    boundary.shape = shape
    body.add_child(boundary)
    add_child(body)
    return body

func plant(_point) -> void:
    if not control.is_picked_up():
        return
    var p := to_local(control.global_position)
    field.mark(Vector2(p.x / 2.0 + 0.5, 1.0 - (p.y - 0.5) / 2.0))

func act(key: String) -> void:
    match key:
        "RUN/HOLD": field.running = not field.running
        "STEP": field.step()
        "RESET": field.reset(true)
        "CLEAR": field.reset(false)
        "INK":
            alternate_ink = not alternate_ink
            material.set_shader_parameter("ink", Color("822547") if alternate_ink else Color("143436"))
    show_state()

func show_state() -> void:
    material.set_shader_parameter("state_texture", field.state_texture)
    readout.text = "%s / %d steps / F %.3f\nHold point; trigger plants at its X/Y address" % [
        "RUNNING" if field.running else "HELD", field.iterations, field.feed
    ]
```

## Carried point_body.gd — unchanged

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable

const RADIUS := 0.14
var surface := MeshInstance3D.new()

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)

func coat(material: Material) -> void:
    surface.material_override = material
```

## Build, predict, change

1. CLEAR, then STEP. Explain why a uniform U = 1, V = 0 field stays uniform.
2. Hold the point at local (−0.3, 1.8, 1.2); trigger, then release. The mark should appear left of centre and above it. Compare HELD, STEP and RUN. HOLD, then change INK: the shape and step count should stay fixed.
3. RESET and STEP. Read the first-step prediction above. Change only `const FEED := 0.055` to `const FEED := 0.065` in `shaping.gd`, rerun, reset and step. The same interior address now has U ≈ **0.0325**; V still clamps to one. Both local terms contain feed, even though this saturated V masks one difference on the first step. Compare later fields only at equal update counts.
4. Make two marks with a relation you can describe. Let them evolve, then hold a result. Explain which decisions came from your input, the rule and the display. The test can check those operations; it cannot decide whether your composition matters to you.

The record survives between steps while this study is loaded. It is not saved to disk or carried across halls. Carry the programming distinction onward: **read old, write next, then exchange their roles**. Cellular Automata will make another rule from it.

<!-- @ -->

## Other encounters

The older green square asks for previous input without receiving its own output. The frost panel and Memory Skin construct appearances without retaining your touch. Keep them as comparisons. The dark sphere also carries CPU state; it is not a second version of this field. None needs another implementation in this lesson.

[^model]: [MIT's Gray–Scott model notes](https://groups.csail.mit.edu/mac/projects/amorphous/GrayScott/) describe the reaction, supply, removal and neighbour exchange. This lesson uses the room's specific discretization and coefficients.
[^viewport]: [Godot's SubViewport documentation](https://docs.godotengine.org/en/stable/classes/class_subviewport.html) specifies UPDATE_ONCE and UPDATE_DISABLED. The runner explicitly uses these modes and waits for completed rendering.
