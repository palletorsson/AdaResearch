from pathlib import Path
import re, shutil
R=Path(__file__).resolve().parents[1]
S=R/'doc/book/studies/procedural-generation-through-the-hands/PG_Percolation_Network'
M=R/'commons/maps/PG_Percolation_Network'
shutil.copyfile(S.parent/'PG_Branching_Growth/point_body.gd', S/'point_body.gd')
def block(name): return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf-8').rstrip()+'\n```\n'
text='''# Percolation — a rule of contact

## Learning elements

- Represent occupied cells separately from reached cells
- Define six face neighbours with integer offsets
- Read one generation while writing the next
- Test reachability by changing a contact rule

The point returns as our stepping control. The cubes return as cells with integer addresses. Branching Growth kept a parent relation for each new position. Here the positions are already present. We ask which of them a signal can reach.

## Two cubes first

At the existing museum desk, press RESET. A pink source touches a white cube along a face. Predict the result of STEP. Then press CONTACT: the second cube moves to a corner contact. They still touch, but STEP no longer transmits between them.

The program consults six offsets: one cell in either direction along each axis. A diagonal contact is absent from that list. This is the new decision to inspect. The old/next update returns from Cellular Automata; it makes that decision once per generation.

## Keep the lattice; change what has reached it

Save these three complete files together in your prepared Endless Museum working copy. Attach `lattice.gd` to an empty Node3D at unit scale in an open working bay. Our test placement is hall-local (8.5, 0, 18), yaw 180 degrees. The museum supplies the player, camera, floor and XRTools.

The small model has six cells along each axis. The installed comparison has eighteen. Each dictionary key is a Vector3i address; its value is simply true. Membership answers a question: is this cell occupied, a source, or reached? We do not store a false entry. `occupied` stays fixed during propagation. `sources` stays fixed too. `reached` is the changing state.

For the contact test we place a source at (2, 1, 2). The second cell is either (3, 1, 2), one face away, or (3, 2, 3), one corner away. A cell outside the occupied set cannot acquire flow: the update never visits it. The grid does not wrap at its boundaries.

`step()` starts with a copy of the old reached set. It visits occupied cells and asks whether any of their permitted neighbours was already reached. It reads `reached`, writes `next`, and swaps them only after the pass. A newly reached cell cannot transmit again during that same pass. `break` stops the neighbour search after one successful contact; one is enough. The returned number counts additions on this step.

'''+block('reach.gd')+'''
R restarts propagation by copying the sources, leaving the occupied arrangement intact. The Boolean values and integer keys need only an ordinary dictionary copy. There are no nested records here. Changing the copy to an alias would change the meaning of a generation.

L builds the six-cubed comparison. The local random generator restarts at seed 1337 and visits addresses in x, y, z order. D changes the occupation cutoff between 0.2, 0.4 and 0.6 using those same draws. The whole z = 5 face is then explicitly occupied and supplied as a source, regardless of its draws. This matches the museum desk's boundary policy; the standalone production artifact normally seeds only occupied boundary cells. A boundary condition is part of the experiment.

One step crosses at most one permitted contact. A row of four face-connected cells needs three steps to reach its last cell from the first. Repeating a step cannot carry the signal across an empty gap. The 64-step limit is a working budget, not proof that every possible six-cubed path has been explored.

## Make that decision visible

These are the cubes and materials we already know. Their edge length and address spacing are both 0.3 metres, so neighbouring faces actually meet. White means occupied but unreached, pink means reached, and dark pink identifies a source. The geometry is drawn from the records; moving its host does not change adjacency.

The inherited point advances STEP when its held trigger is pressed. SPACE does the same; T makes ten requests. C alternates the two contacts, L opens the small lattice, D changes density, and R restarts only the current flow. R therefore differs from the museum desk's RESET, which returns to its face-contact opening. The caption counts all reached non-source cells so far, not just the most recent step.

'''+block('lattice.gd')+'''
The miniature supplies no cube collision. The installed white cubes do: their collision is removed when they become flowing. That separate physical rule is visible in the hall, but it is not required to calculate reachability. Neither a pink cell nor a connected chain of centres guarantees a supported route for your body.

### Carry the point

This file is unchanged from Branching Growth. The host gives its existing action another job. Moving it alone does not advance the field; releasing it parks it beside the model.

'''+block('point_body.gd')+'''
## Permit one more kind of contact

Run the corner test first and predict that it stays white. Add `Vector3i(1,1,1)` and `Vector3i(-1,-1,-1)` to `OFFSETS`. These opposite offsets permit one diagonal orientation in both directions. They do not admit every possible edge or corner contact.

Run the same corner test again. The cube should now be reached in one step, without changing either position. A different corner, such as an offset of (1, 1, −1), should still fail. Explain why both results follow from the list. Then return to the seeded lattice and compare the two rules at the same density and generation. The occupied arrangement must remain identical; only the permitted relations have changed.

Do not expect every edited rule to produce a visibly different result in every field. Test a contact that distinguishes them before using a larger arrangement. An empty far-face count after a few steps may mean the wave has not arrived yet. A stopped wave on this finite field is not a universal critical threshold.

## Return to the large field

Use LATTICE and DENSITY at the museum desk. Its 18-cubed field has a supplied z = 17 source plane, and the opposite plane is z = 0. These are opposing sides, not top and bottom in Godot's y-up world. The seed and cutoff match our construction procedure, but the different grid size changes which random draw belongs to each address. The two fields are not scaled copies.

Our model keeps the reachability decision only. The installed artifact also stores numerical flow, decay, randomized transfer amounts and separate flowing/connected states. The tutorial does not reconstruct those amplitudes or claim to simulate a conserved fluid. Its Boolean wave is checked against which sites the installed update reaches, under supplied fixtures.

Keep the dark sphere and stand as other encounters in the hall. Carry the occupied addresses, reached set and explicit contact rule onward. Caves / Mazes will ask how to construct an interior for a body, after this signal has needed only a relation.
'''
(M/'tutorial.md').write_bytes(text.encode('utf-8'))
original=(R/'doc/book/iterations/2026-10-09-percolation-a-contact-rule/before/commons/maps/PG_Percolation_Network/final.md').read_text(encoding='utf-8')
original=re.sub(r'\n```gdscript\n.*?\n```\n','\n',original,flags=re.S)
original=original.replace('those on the side facing the source','those reached on the opposite face')
original=original.replace('This is an explicit local definition, not a universal meaning of nearness.', 'This is an explicit local definition, not a universal meaning of nearness.\n\nYou can admit that corner without moving either cube. A relation becomes available while the bodies keep their places. What counted as an isolated object was partly a decision about its neighbours.')
(M/'final.md').write_bytes(original.encode('utf-8'))
print('Wrote complete Percolation tutorial and targeted reflection edit.')
