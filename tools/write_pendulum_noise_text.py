"""Print actual source beside its explanation; add a bounded optional study to the hall."""
from pathlib import Path
R=Path(__file__).resolve().parents[1];A=R/'commons/artifacts/pendulum_noise';M=R/'commons/maps/Vectors_Act4b_Oscillation';O=R/'doc/book/iterations/2026-10-09-pendulum-a-recorded-push'
preamble='''# Keep the release; change the push

**Learning elements**

- A common initial state
- A saved force record
- Force projected onto a constrained direction
- Damping under matched input
- Replay and finite observation windows

The black point is familiar. In this bay it hangs from a rod. Pull either point sideways and let go: both begin from the angle you selected, with zero angular velocity. The depth of your hand movement and the speed of your throw are excluded. This makes a release that can be compared and repeated.

Start with **A: NO PUSH / B: RECORDED PUSH**. Only B receives the external force; both have the same damping. The push stops after four seconds. Watch the points continue. Their current angles and velocities retain consequences of the input even when its arrow disappears.

Press REPLAY. The input is a saved list, not another random draw. Increase FORCE and replay again: you changed the size of those same values. NEXT SEED replaces the list. These are different experiments.

Now press MODE. **SAME PUSH** sends the record to both points. A keeps its damping coefficient; B DRAG changes B. Make B equal to A before comparing a different value. Equal release, input and damping must produce equal states. That is the first useful test.

## What you bring

Keep the sphere class from Lines and Forces. Keep arrays from Trace, the update of velocity before position, and the distinction between local and world coordinates. This is an optional extension beside the hall's existing spring lesson. Waves later returns to the pendulum's sampled record; Randomness and Noise examine how the input values are generated. Here you can first treat the forty saved values as a supplied input.

We are working inside the existing Endless Museum. The code builds this small apparatus and its labels. The museum supplies its camera, room, player, installed XR Tools and shared ControlConsole. No prepared mesh children or unexplained dollar references are required. The public source paths below are part of this project; save the files there to reconstruct the same scene. Use the finished scene in a clear study bay at floor level and unit scale. It does not replace the larger spring or swing artifacts.

## The new relation

Angle and angular velocity are the moving state. A point at angle zero hangs below its pivot. The mass and rod length are fixed. Gravity contributes `-(g/L)*sin(angle)`. Tangential drag contributes `-(b/m)*angular_velocity`. A horizontal push contributes `F*cos(angle)/(m*L)`: its projection onto the direction the bob can move changes as it swings.

The model takes one fixed step of1/120s. It updates angular velocity, then angle. The rod's length follows from the position formula, so the model cannot pull it loose. This is an angular simulation with no contacts, not a Jolt hinge. The surrounding hall gives you other mechanisms to compare with it.

The saved force changes every twelve model ticks. Forty values last four seconds; the following sixteen seconds contain no external push. Sampling the state every fourth tick gives601 stored snapshots including the initial state. Recording less often changes the trace, not the update clock. Peak and settling measurements still inspect every step.

## Complete model — pendulum_pair.gd

Save as `commons/artifacts/pendulum_noise/pendulum_pair.gd`. The model owns the saved input, two states and their measurements. `reset()` restores their common start without drawing another input. `step()` reads the current force, advances the states and records what happened.

'''
paths=[A/'pendulum_pair.gd',R/'doc/book/studies/forces-point-lineage/point_body.gd',A/'angle_point.gd',A/'PendulumNoise.gd',A/'PendulumNoise.tscn']
introductions=['', '''## The inherited point — point_body.gd

This is the unchanged sphere, boundary and pickup class from the earlier lessons, at `doc/book/studies/forces-point-lineage/point_body.gd`. You already have it; its source is repeated here so the dependency is visible.

''','''## Constrain the held point — angle_point.gd

Save beside the model. XR Tools first follows the hand. This extension then projects that position onto the permitted angle and restores the fixed rod length. Its late physics priority follows the same pattern as the museum's existing constrained mower and spring handle. The unheld point follows the model. Pickup and release keep their established meanings; throwing is deliberately disabled for this comparison.

''','''## Make the comparison visible — PendulumNoise.gd

Save beside the model. The two rigs share construction and styling. Their state remains separate. The familiar ControlConsole supplies physical controls, explicitly loaded from `commons/ui/control_console.gd`; it is inherited museum infrastructure.

`_picked` gives one hand authority over the common release. `_dropped` starts both at rest. The physics callback accumulates model time in fixed steps. The process callback displays the current state and refreshes the bounded plot. Button and slider changes restart the comparison, while RUN/PAUSE preserves its state.

''','''## Scene wrapper — PendulumNoise.tscn

This root is all the scene needs; the scripts construct its contents. Open it within the Ada project or add it to your existing study bay. Camera and XR setup remain the museum's supplied environment.

''']
s=preamble
for p,intro in zip(paths,introductions):
 s+=intro+'```'+('ini' if p.suffix=='.tscn' else 'gdscript')+'\n'+p.read_text(encoding='utf-8').rstrip()+'\n```\n\n'
s+='''## Read the result, then make another case

The gold plot shows the saved input; blue and rose show the two angle histories. The input plot spans four seconds, while the angle plot spans twenty. Their vertical display limits are±12N and±πrad. These are drawing limits only. They do not clip the actual forcing, state or measurements. The force arrow uses0.12m per newton and shows the external push, not gravity or the total force.

The settling readout waits until the experiment ends. It asks whether, after the last violation following the cutoff, the state remained within2° and0.05rad/s for at least the final second. It describes the observed twenty seconds. A brief crossing through zero would not pass: a fast-moving point can be at the centre without being settled.

Try three cases before adding more machinery:

1. Set force strength to zero. Predict the two traces in OFF/ON, then compare them. The code must preserve equality.
2. In SAME INPUT set B drag to0.35kg/s, matching A. The two states should remain equal even with a strong push. Then change only B drag and replay.
3. Change the initial angle to zero in the model and set force strength to zero. Both states should remain at rest. This is a new case, not a reproduction of the opening swing.

The native checks execute these invariants and also compare the small-angle period against its numerical reference. Tests do not prove exact mechanics: the undamped integration shows a small energy discrepancy. A long engine callback advances at most0.1model seconds and reports omitted wall time. Nothing changes headset tracking or assumes that wall time and model time remain identical during a stall.

Gaussian values come from a local seeded generator. The sample is neither a bounded force distribution nor continuous ideal white noise. Generator details can change between engine versions; preserve the values as well as the seed for a durable experiment. [Godot4.6 RandomNumberGenerator](https://docs.godotengine.org/en/4.6/classes/class_randomnumbergenerator.html)

Run `python -X utf8 tools/test_pendulum_noise.py` for the model and control checks. The installed-room probe also uses the actual pointer and supplied XR pickup poses. The author-led tests do not certify a physical headset, Quest performance or an independent student's understanding.

What travels onward is a comparison you can reconstruct: common release, saved input, stated update, separate response. The later Noise study scales a saved displacement field instead. A navigator can eventually return to the same method with an imperfect observation; that changes where the disturbance enters the computation.
'''
(A/'tutorial.md').write_text(s,encoding='utf-8')
addition='''\n\n<!-- @pendulum_noise -->
## Optional comparison — a recorded push

**Learning elements:** common initial state; saved force input; tangential projection; matched damping comparison; replay; finite settling criterion.

Between the spring row and the swings, pull either black point and release. Both begin from the same angle. First compare external force off/on with matching damping. Then use MODE to send the same saved four-second push to both and change only B's damping. The motion continues for twenty seconds; the trace distinguishes the end of a push from the end of its consequence. These are angular models, not engine hinges. The primary spring lesson above remains the hall's first reconstruction.

The [complete companion tutorial](../../artifacts/pendulum_noise/tutorial.md) prints the model, unchanged point class, constrained hand extension, full apparatus and scene. It declares the existing museum controls and includes independent zero-input and equal-parameter cases. Randomness/Noise later returns to how the saved input is produced.
'''
p=M/'tutorial.md';old=p.read_text(encoding='utf-8');old=old.split('\n\n<!-- @pendulum_noise -->')[0];p.write_text(old+addition,encoding='utf-8')
reflection='''The push has stopped. The black sphere keeps moving. For four seconds a recorded force entered its calculation; now that input is zero. Angle and velocity remain. The point carries what happened without needing a story about it.

Release the pair again. Give both the same record and change the resistance of one. Their paths separate. We can repeat the disturbance, but a disturbance alone does not describe what a body will do. Its attachment, its resistance and the state from which it begins all participate in the response.

The display waits before calling either point settled. We gave that word an angle, a speed and an observation window. A point passing quickly through the centre does not qualify. The one still moving at the end has not necessarily failed; it has exceeded the patience of this particular test. You may prefer its longer return. The criterion makes a comparison possible while leaving that preference open.
'''
(O/'reflection.md').write_text('# After the push\n\n'+reflection,encoding='utf-8')
p=M/'final.md';old=p.read_text(encoding='utf-8');marker='<!-- @pendulum_noise -->'
if marker not in old:
 anchor='We will return to oscillation in Wavefunctions.';assert anchor in old
 old=old.replace(anchor,marker+'\n\n'+reflection+'\n'+anchor,1);p.write_text(old,encoding='utf-8')
print('Full companion source printed; optional hall tutorial and reflection added.')
