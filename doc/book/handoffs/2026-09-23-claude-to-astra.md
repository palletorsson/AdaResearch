# For Astra — what changed today, and what must not be written

23 September 2026, from the Opus session. Nothing here is committed. Everything is in the working tree.

This is the file to read before touching any of the halls below. It is not a summary of my work; it is the part of it that constrains yours.

---

## 1. Six final.md files moved under you

| hall | what happened |
|---|---|
| `Point_One` | epigraph promoted to the top; the "~~you~~ are here" passage is now a gesture — the struck word lifts off the floor |
| `Point_Triangle_Context` | opens with the carried bend from Trace; the prescribed L follows as the controlled case |
| `Primitives_Melencolia` | new closing section reading the frame counter against Point_One |
| `Trans_Body` | the `carve_grid` cut now persists, so the hall's closing question is answerable |
| `SoftBodies_Cloth_Physics` | rewritten, 357 → 796 words |
| `ML_Sequence_Memory` | rewritten, 410 → 591 words |

You had already revised Point_One, Point_Triangle_Context and Trans_Body while I was working; I edited around your changes and did not touch the `bite_m` passage or the figure you added. If we collided anywhere, your version is the one to keep — say so and I will redo mine on top.

---

## 2. Capabilities that are new, so prose may now claim them

Each is gated on a word key, so only the named hall has it.

- **`#carry:trace`** on `draw_triangle_faces` (Point_Triangle_Context) — the tool opens holding the visitor's own drawing from Trace, reduced to six corners and flattened.
- **`#leak:keep`** on `carve_grid` (Trans_Body) — the cut survives the room unloading and is restored on the next arrival, from the union of every previous visit.
- **`SUPPORT`** on the soft workshop console (SoftBodies_Cloth_Physics) — cycles the cloth's suspension through gantry / none / hoop / mast / wall. Five rigs existed and nothing selected any of them.
- **`#recurrent:on`** on `lstms_vr` (ML_Sequence_Memory) — a real computed cell state, `c = f·c + i·x`, `h = o·c`.

**A word value, never a number.** `#key:number` is reread as rotation shorthand unless the key is in `CONFIG_PARAM_NAMES`. That is why these read `on`, `trace`, `keep`.

---

## 3. Claims circulating in or near the book that are FALSE

These came out of adversarial verification. Please do not write any of them.

- **"After RELEASE only REBUILD restores the full edge"** (cloth). `PINS` is `(pin_mode+1)%2`; from released, the first press gives corners and the second gives the full edge. Measured: 2 then 8 points.
- **"The cloth does not move when the frame changes."** I wrote this and it is wrong. A free vertex moves 0.031 m in 30 frames with no frame change at all. What is true is narrower: *the held edge* does not move. The prose now claims only that.
- **"The 2026-09-15 soft acceptance receipt validates the pin comparison."** Three of its five recorded source hashes now differ, and the harness presses each control once in list order, so every cloth assertion is measured after REBUILD in mode 0 only.
- **The hem height in Cloth Physics.** Rest arithmetic gives 0.15 m; auto-grounding may lift it to 1.90 m. Unsettled, so the prose no longer states it. Palle has a session on this — wait for it.
- **`wall` is not another inert frame.** It is the one suspension whose geometry reaches into the cloth's own volume, and the one you cannot walk through. It has its own paragraph for that reason.

---

## 4. Signs standing over things that do not exist

Worth knowing before writing near them.

- `lstms_vr` hangs `CELL STATE / Long-term Memory` and `HIDDEN STATE / Short-term Memory` over nothing, in every placement. In ML_Sequence_Memory they are now true. In `MachineLearning_LSTMs` and `Ribbon_Machinelearnin_01` they are still false, because the repair is gated.
- The same artifact's `@identity` header states the LSTM equation as its essence and does not implement it, except under the new key.
- `backface_curtain` — a theatre curtain, pleats and gold hem, absent from behind because every face is one-sided — is finished and placed in **zero maps**. So are `radial_inside`; `rhizome_inside` is in one.

---

## 5. Material you may find useful

`doc/EDGE_INVENTORY.md` — 59 authored edges across the corpus, each with file, line, the verbatim declaration, what escapes it, and whether the remainder survives. 18 of them are already named somewhere in the book's prose, with the quote recorded. If you want a concrete detail for a hall, the entry for its artifact probably has one, already verified.

Companion plate: `/evidence/edge-icons/edge-icons-plate.svg`, thirteen kinds of refusal.

---

## 6. The thing I would most like checked

`doc/book/iterations/claude-softbodies-softbodies_cloth_physics-pilot/DECISIONS.md` and the ML equivalent both record a correction to my own work, found by a review panel after I had already shipped the prose. In both cases the error was the same shape: **I measured something that could not have come out otherwise and reported it as proof.**

If you read the two revised halls and find a sentence that sounds like it was measured but was not, that is the failure mode to look for, and I would rather hear it from you than have it stand.
