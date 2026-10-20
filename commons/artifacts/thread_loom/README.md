# Follow the Thread

A working geometric hand loom in **Tiling → Symmetry Seventeen**, cell `[16,21]`. It joins the existing machines; it replaces none of them.

Take the brass shuttle from the lit side. Carry it horizontally through the opening between raised and lowered warp threads. At the other side, press the held shuttle's trigger or **BEAT** beside the frame. The reed moves and one weft pass joins the cloth. Return in the opposite direction for the next pass.

- Twelve cream warp threads; one continuous pink weft path.
- The four-by-four lift draft repeats across the warp. Lit means warp above weft. PLAIN and TWILL supply two starting drafts; individual buttons change a crossing instruction.
- Four woven passes are supplied at entry. RESET makes an empty warp. The sample holds at most 24 passes.
- A pass snapshots its draft when the shuttle reaches the opposite edge. Changes affect future passes; committed crossings retain their earlier choices.
- Draft editing locks during a pass or while it waits for beating. A partial, interrupted or jumping traversal cannot add fabric.
- PASS provides a guided shuttle traversal using the same path validator. BEAT still commits it separately.
- UNDO removes the pending or latest committed pass. This is an editing operation, not a physical unraveling simulation.
- Desktop pickup uses the museum's existing grab hooks. XR uses XRToolsPickable and its trigger action.

The yarn is tube geometry, visible from either side. There is no fabric image plane. Prescribed thread paths and take-up show the construction; yarn friction, tension, collision response, knotting and cloth mechanics are not simulated. The shuttle's centre must follow the shed corridor; it is not a full swept-volume yarn collision solver.

The learner's point returns as a pickup interface; arrays record crossing choices, and loops construct repeated thread geometry. The sequence's main tutorial remains about symmetry. This loom is a wider material encounter, not a new compulsory lesson or a claim that knitting and weaving are the same operation.

Runtime tests: `tools/probes/thread_loom_test.gd`. Museum placement/capture: `tools/probes/thread_loom_museum.gd`. Evidence and native images: `doc/book/iterations/2026-10-09-thread-loom/`. Synthetic XR controller tests exercise the actual pickup and trigger code; physical headset ergonomics still need a playthrough.
