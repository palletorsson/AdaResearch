"""Write the final shader lesson from an explicit Pink continuation."""
from pathlib import Path
import hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-10-state-a-field-kept'
MAP=ROOT/'commons/maps/Shader_10_ReactionDiffusion'
PRE=ROOT/'doc/book/iterations/2026-10-10-pink-three-amounts/learner/printed'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    (OUT/'before').mkdir(parents=True,exist_ok=True)
    for name in ['tutorial.md','final.md','map_data.json']:
        p=OUT/'before'/name
        if not p.exists():
            if (MAP/name).exists():shutil.copy2(MAP/name,p)
            else:p.write_text('',encoding='utf8')
    old=(PRE/'shaping.gd').read_text(encoding='utf8').rstrip()
    host=old[:old.index('func _process')]
    host=host.replace('const REPEATS := Vector2(3, 3)','const Field = preload("field.gd")\nconst PushButton = preload("res://commons/interactables/push_button.tscn")\nconst FEED := 0.055')
    host=host.replace('var amounts := Vector3(1.0, 0.6, 0.3)\nvar mode := 1','var field: Node\nvar alternate_ink := false\nvar buttons: Dictionary = {}')
    host=host.replace('    material.set_shader_parameter("repeats", REPEATS)\n','')
    host=host.replace('control.action_pressed.connect(next_mode)','control.action_pressed.connect(plant)')
    host=host.replace('readout.position = Vector3(0, 1.9, -0.5)','readout.position = Vector3(0, 2.72, -0.5)')
    host=host.replace('    update_rule()','''    var board := MeshInstance3D.new()
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
    show_state()''')
    host+='''func plant(_point) -> void:
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
    readout.text = "%s / %d steps / F %.3f\\nHold point; trigger plants at its X/Y address" % [
        "RUNNING" if field.running else "HELD", field.iterations, field.feed
    ]
'''
    host=host.rstrip()
    field=(ROOT/'commons/artifacts/shader_state_chamber/field.gd').read_text(encoding='utf8').expandtabs(4).rstrip()
    step=(ROOT/'commons/artifacts/shader_state_chamber/field_step.gdshader').read_text(encoding='utf8').expandtabs(4).rstrip()
    recipe=(ROOT/'commons/artifacts/shader_state_chamber/field_view.gdshader').read_text(encoding='utf8').expandtabs(4).rstrip()
    point=(PRE/'point_body.gd').read_text(encoding='utf8').rstrip()
    files={'shaping.gd':host,'point_body.gd':point,'field.gd':field,'field_step.gdshader':step,'recipe.gdshader':recipe}
    incoming={n:{'path':(PRE/n).relative_to(ROOT).as_posix(),'sha256':sha(PRE/n)} for n in ['shaping.gd','point_body.gd','recipe.gdshader']}
    chain={'incoming':incoming,'edits':{'shaping.gd':[[old,host]],'point_body.gd':[],'recipe.gdshader':[[(PRE/'recipe.gdshader').read_text(encoding='utf8').rstrip(),recipe]]},'new_files':['field.gd','field_step.gdshader'],'invariants':['PointBody unchanged','make_box unchanged','cube and plinth unchanged','same local point start and lamp'],'supplied':['Prepared museum XR player and camera','push_button.tscn with InteractableAreaButton receiver','GPU scheduler field.gd and encode/decode support printed in full']}
    (OUT/'continuation.json').write_text(json.dumps(chain,indent=2)+'\n',encoding='utf8')
    brief='''MAKE: mark a field; release; advance from its saved state.
BRING: Pink point/cube; UV lookup; uniforms; arrays; old/next reasoning.
GIVEN: museum/XR; named push-button prefab; printed GPU scheduler/packing.
BUILD: previous texture → neighbour/reaction rule → next texture; separate display.
CHECK: hold/step/reset; palette leaves state; F=.065 variation; broken feedback fails.
LATER: CA rules; curved-surface diffusion; physical chemistry; persistent saves.
'''
    (OUT/'BRIEF.md').write_text(brief,encoding='utf8')
    def code(n):return '\n<!-- student-code:'+n+' -->\n```'+('gdscript' if n.endswith('.gd') else 'glsl')+'\n'+files[n]+'\n```\n'
    t='''# A field kept

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

## Read the rule first

In `field_step.gdshader`, `read_state` retrieves one pair. `lap` compares it with eight neighbours: centre −1, side neighbours 0.2 each, diagonals 0.05 each. The weights sum to zero, so a uniform field has no exchange. Opposite edges wrap; this is a periodic square field even when displayed on a sphere.

The coefficients are Du = 1, Dv = 0.5, F = 0.055, K = 0.062, with one numerical step of dt = 1. One step is not one second. Clamping bounds concentrations; it does not make arbitrary rates or timesteps accurate.

`integrate` distinguishes advancing the model from planting a mark. The brush overwrites a small disc after the update, or on its own while held. Planting is an intervention, not a chemical reaction.

The short packing functions are supplied transport code: two 12-bit numbers share an RGB8 pixel. They introduce quantization of 1/4095. There is no `source_color` hint on this data sampler. Colour conversion would corrupt the numbers. Focus on the reads, update and final write; the full support is visible here.
'''+code('field_step.gdshader')+'''
At the centre of a seeded disc, all neighbours initially agree. The first update gives U ≈ **0.0275**, V = **1** after clamping. Away from the discs, U = 1, V = 0 stays unchanged. Predict both before pressing STEP.

## Keep the output before using it again

`field.gd` is the supplied GPU runner, printed in full. `_schedule` binds `state_texture` as the first input, then chains up to eight separate render targets. `_completed` publishes only the finished last texture, and switches groups. Two groups prevent the next batch from overwriting the texture it still reads. Old dependencies are disconnected before a group is reused.

Each SubViewport renders once, then holds its pixels.[^viewport] RUN requests up to eight steps per rendered frame toward 240 model steps per second; slower rendering slows the model. HOLD finishes the current batch. RESET cancels queued work and restores the three discs after any in-flight batch. CLEAR restores the uniform background. Neither changes F or K. A mark queue holds at most 32 requests. There is no CPU chemistry or GPU readback in this live path.
'''+code('field.gd')+'''
## Colour is a reading of the field

`recipe.gdshader` reads V and maps it into ink. The transition from paper to ink spans V = 0.05 to 0.30, so fully dark ink does not mean V = 1. This displayed colour never feeds the update. The same texture coats the point, cube and square: three views of one flat record, not three simulations or diffusion across their physical surfaces.
'''+code('recipe.gdshader')+'''
## Continue the point and cube in the museum

Keep the five files together. The prepared AdaResearch project supplies XRTools, player, camera, lighting and the push-button prefab at `res://commons/interactables/push_button.tscn`. That prefab creates the named `InteractableAreaButton` receiver used below. It supplies a physical press and pointer event; our code decides what the press does. No museum artifact constructs the learner's field or geometry.

Open `res://doc/book/studies/shaders-lineage/State.tscn` and Run Current Scene. The supplied launcher places this small study beside the existing State chamber; set its LESSON preload to your saved `shaping.gd`. Alternatively attach the script to a Node3D at floor level, unit scale, with a clear 3 × 3 metre area in the prepared museum.

Hold the point. Its local X from −1 to 1 selects left to right; Y from 0.5 to 2.5 selects bottom to top. Trigger plants a disc. Z does not select an address: this is an XY selector, not a contact detector. Outside that rectangle it plants nothing. Moving without triggering plants nothing. Release keeps the point and, while HELD, the field still. The installed large wall additionally accepts direct touch; that input adapter is outside this reconstruction.

The five nearby buttons operate your field: RUN/HOLD, STEP, RESET, CLEAR and INK. The large wall's own desk controls its separate field. The board here is a visual display; the inherited cube and plinth retain their colliders.
'''+code('shaping.gd')+'''
## Carried point_body.gd — unchanged
'''+code('point_body.gd')+'''
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
'''
    (MAP/'tutorial.md').write_text(t,encoding='utf8')
    f='''# Where is the last frame?

<!-- @shader_state_chamber -->

Touch the wall. Take your hand away. Something remains where you were, although it has kept neither your hand nor the reason you put it there. A small disc of two quantities is enough for this field to continue from your intervention.

Press STEP. Press it again. RUN lets the change gather; HOLD gives you time to look. The point and cube wear the same record. They do not exchange anything through the space between them. One flat field has been fitted to three bodies, and the fit makes different parts of it visible.

Pink asked how much to add and what the surrounding room made of that addition. Here an addition acquires consequences. The next state depends on the previous one. Your mark may become difficult to recognise while the process still depends on its presence. This is a limited kind of memory: a present state shaped by earlier operations, without a story about who made them.

Change INK. The field looks different and its stored quantities have not changed. Clear it. Now something has been removed from the record. These actions can resemble each other on a screen, but they do different work. What would you need to inspect to tell concealment from erasure?

<!-- @shader_10_reactiondiffusion -->

The older two-square display remains nearby. The left square is green, edge to edge. Its label says Reaction-Diffusion. It runs a rule that asks for two quantities from a previous texture, lets them diffuse and react, and draws a new colour. The missing part is the return. Its script never binds that previous texture to its own completed output.[^unbound]

In the captured version, the unassigned input reads white. Both quantities begin at one, the first update produces green, and the next frame repeats that first update. The panel has a place for a past and no past handed to it. The new wall makes that absent connection visible: completed data must be kept somewhere and supplied again.

A return alone does not promise an intricate pattern. A uniform field can remain uniform. The wall begins with three differences; CLEAR removes them. STEP after CLEAR changes nothing. You have not broken the mechanism. You have given its rule a condition that it preserves.

![Earlier numerical comparison of the old rule with feedback and two diffusion settings](/book-images/figures/shaders/what-the-rule-would-do.png)

*An earlier reconstruction used a ten-cell seed in a 256 × 256 field. At diffusion coefficients 0.16 and 0.08 the disturbance remained small; at 1.0 and 0.5, with the same feed and loss, it spread. This is an earlier comparison, not a capture of today's 96 × 96 wall. The starting difference, boundary and coefficients belong to the result.*

The right square looks grown: cyan frost branching from its centre. GROWTH lengthens its reach; DENSITY thickens it. Its label says DLA, a name used elsewhere in the museum for particles wandering until they stick to an aggregate. Here the shader constructs the appearance with noise and a radial mask.[^dla] Turn the control down and up: a branch can return without having regrown. The nearby Memory Skin moves too, but does not store the contacts its name may lead you to imagine.

These are useful likenesses. A convincing image of a process can invite us to ask how that process works. It can also let the question disappear. The difference becomes available when the controls expose what changes and what survives.

<!-- @dark_sphere -->

The dark sphere pulses from a number kept on the CPU. Memory was already present in the room's machinery, in earlier recorded traces and in settings left where a hand released them. The new distinction is narrower: this shader's evolving field receives its own previous state and the neighbouring values within it.

Nothing here remembers everything. The wall keeps concentrations, not identities or intentions. It wraps one edge onto another. It stops when its clock stops, and its record disappears when the study unloads. Calling it a living skin may begin an association; it does not establish a living being.

What becomes possible when a surface can continue after we leave it alone? And what do we mistake for care when a system merely retains a trace? The next hall will change the rule while keeping the obligation to say which past each update receives.

<!-- @ -->

[^unbound]: The retained `shader_10_reactiondiffusion.gd` rack loads `commons/resourses/shaders/reaction_diffusion.gdshader` without assigning `prev_texture`. The flat green capture and white-input explanation refer to that implementation and renderer, not a promise about every unassigned sampler.
[^dla]: `dla_visual.gdshader` describes its output as a visual approximation using noise. The particle-by-particle aggregate elsewhere in the project is a different implementation. Similar appearance does not establish the same process.
'''
    (MAP/'final.md').write_text(f,encoding='utf8')
    print('Wrote State tutorial/reflection; production hall unchanged.')
if __name__=='__main__':main()

