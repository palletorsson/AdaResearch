# Where is the last frame?

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
