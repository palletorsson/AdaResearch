# Following Clark into the code

## A work, not an artist-shaped category

The documented anchor is Lygia Clark’s **Bicho desfolhado (Husked Creature)**, dated 1960, with the Reina Sofía example produced in 1973. Its recorded materials are aluminium sheet and hinges. The museum connects its organic character to the participant’s interaction, rather than resemblance to an animal. [Collection record](https://www.museoreinasofia.es/en/collections/artwork/bicho-desfolhado-husked-creature/).

MoMA’s discussion of the *Bichos* emphasises instability, manipulability and the absence of an ideal shape or privileged front and back. These conditions matter when translating the work into an interface: a fixed root and a reset command are substantial additions. [MoMA audio transcript, in Portuguese](https://www.moma.org/audio/playlist/181/2429).

Luis Pérez-Oramas places Clark’s hinge in relation to the seam or interval between surfaces. His account also questions a simple story in which flat painting merely escapes into three dimensions. This gives the study a more precise question: what can a relation between planes do? [MoMA, “If You Hold a Stone,” part 2](https://post.moma.org/part-2-lygia-clark-if-you-hold-a-stone/).

These sources establish a working relation, not an exact digital reconstruction. Another catalogue entry, *Máquina* (1962), describes 24 shaped plates; our existing artifact uses six identical rectangles. A visual resemblance cannot establish equivalence of construction. [Clark archive](https://portal.lygiaclark.org.br/acervo/124/maquina).

## What the existing artifact supplied

`bicho_hinge` already constructs six plates in a branching tree, with five bounded rotations. Child plates inherit their ancestors’ transforms. Releasing a plate retains the last angle. The initial pose is selected by a deterministic search that rejects sampled clashes with the plinth and floor.

It also fixes the root to a support, gives thin plates a larger XR grab volume, assigns angular stops and searches for an opening pose that reads well. The object already carries editorial decisions. They are useful to inspect because they are concrete.

## Three possible studies, and the one we chose

- **Widen one stop.** Keep the tree and change one angular limit. This exposes what the joint permits, but current kinematics can allow plates to intersect.
- **Remove the fixed support.** Allow the whole assembly to be handled. This would move closer to physical handling, but requires a tested arrangement of bodies, joints, contact and pickup.
- **Change what happens after release.** Keep the same assembly and compare a retained pose with a return to its starting angles. This can be tested with the existing artifact and makes an interface decision consequential.

We chose the third. It does not require a reward, a target silhouette or another object. One setting changes what the visitor’s action is allowed to leave behind.

## The code changed the argument

The previous source and registry described the reachable angles as a transformation group and claimed that adjusting a parent and child in reverse order must produce different final poses. The implementation did not support that claim.

For this model, every plate transform is computed from the same final joint-angle vector. Assigning those independent values in a different order does not change the resulting product. The order of factors in the hierarchy remains fixed. Bounded angles form a configuration domain; they are not a group closed under composition.

The native probe confirms the same final plate transforms for both adjustment orders. Recording one corner reveals different intermediate paths. The trace therefore gives us a stronger connection to the earlier chapter: a final shape does not contain a complete account of the movement that reached it.

The pointer test found a second, practical error. Godot’s positive local-X rotation takes +Z toward −Y. The old `atan2(p.y, p.z)` reversed that convention, so the mouse gesture and hinge motion opposed one another. A direction-sensitive test failed before the correction; `atan2(-p.y, p.z)` follows the intended turn and passes the native pointer and actual mouse-routing tests.

## The critical opening

“Leave it” permits a range of forms to remain without grading them against a completed silhouette. “Return it” allows a visitor’s action for a while and then reinstates a chosen state. That distinction is our question for the digital study, not an intention retrospectively attributed to Clark.

A queer reading can begin with that absence of a required final body and then inspect the limits that remain. Which relations are permitted? What is fixed so firmly that the visitor cannot put it into question? Five flexible joints still depend on a root we have bolted down. Openness is particular, designed and testable.

## What the evidence supports

The native report records 29 focused checks: production scene transforms against their solver; carried and unaffected branches; retained angles; authored limits; return policy; equal endpoints and unequal corner paths; production pointer direction and release; physics-ray picking; real mouse events; and GUI selection. Captures were rendered in Godot 4.6 with GL Compatibility on the available desktop GPU.

The portable project copies the production specimen and three dependencies byte-for-byte. The viewer substitutes a quieter metallic finish, highlights one plate and supplies the room, camera, input panel, return policy and optional trace. Those are declared apparatus, not changes to Clark’s work. The return is a timed interpolation, not a spring simulation.

No headset, main-museum installation, material validation or learner trial was performed. No plate-to-plate collision solver was added. Pose retention lasts within this running scene; it is not a saved record across sessions.

## Where it leads next

The next substantial experiment is **releasing the fixed root**. Keep the existing joint arrangement and compare the supported assembly with a whole object that can be lifted. The test must include its weight, contact and how the hand transfers motion through it. That belongs with Form Finding and physical constraints. It should begin with a small two-plate system before extending the full tree.

The writing can then ask what changed when the support stopped being guaranteed. That question will follow the tested behaviour.
