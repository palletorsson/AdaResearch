# What the split words are actually disagreeing about

Measured 2026-08-12 over every `dna.axes` block in `commons/artifacts/registry/`.

**94 axis words are declared with more than one value list.** That number has been
carried around as "78 words split" and treated as one problem. It is four problems,
and only one of them needs a ruling about meaning.

| | count | what it is | needs |
|---|---:|---|---|
| genuinely different | **68** | one word, two or more different questions | a ruling |
| reorder only | 15 | same values, different declaration order | a decision, not a debate |
| subset | 11 | one member drops values another keeps | usually fine |
| first value only | ~0 | agree on the tail, disagree on the null case | see `regime` below |

## The 15 reorderings are not cosmetic

`build_dna_gallery` sweeps the first two declared axes as a matrix and **trims value
lists from the end** to fit `--max`. Two declaration orders therefore mean two
different values get dropped first, and the same family swept at the same budget is
measured *on different values* depending which member you happened to pick.

`slack` is the clearest case: eleven members, the same five values —
`spline · chord · catenary · festoon · truss` — with nine starting at `spline`, one at
`catenary`, one at `chord`. `taxonomy` has the same shape: six members at
`table|ladder|stack|heap`, one at `stack|ladder|table|heap`.

Normalising these needs no decision about what the words *mean*, only about which order
wins. It is held here rather than done because reordering changes which values a capped
sweep measures, and that is a change to every past and future measurement of those
families — not a tidy-up.

Words affected: `address`, `anchorage`, `cohort`, `curve`, `fusion`, `house`, `ladder`,
`mounting`, `residue`, `slack`, `taxonomy`, and four others.

## `regime` is not thirteen meanings

15 members, 13 vocabularies — the worst number in the corpus, and it is misleading.
Eight of the fifteen sit in three clusters that agree on the **entire tail**:

| members | tail | and disagree only on the first value |
|---:|---|---|
| 3 | `…underdamped · critical · overdamped` | `all` / `free` / `ringing` |
| 3 | `…elastic · dead · inelastic` | `mixed` / `stock` |
| 2 | `…stable · cascade · chaos · period3` | (agreed) |

So `harmonic_motion_demo`, `spring_demo` and `mass_spring_damper` do not disagree about
damping at all. They agree completely, and disagree about **what to call the case where
nothing is damped** — one calls it `all`, one `free`, one `ringing`. Same for the three
restitution artifacts: `mixed` against `stock`.

That is a one-line ruling, not a taxonomy project.

The remaining seven are the real "one word, many meanings" problem, and they are seven
artifacts rather than thirteen vocabularies: `DualBallFMController` (timbre presets),
`VectorForces` (scenario names), `control_pendulum` (adds `resonance`),
`homogeneous_coordinates` (transform class), `rotation_gimbal` (proximity to gimbal
lock), `stretch_bench` (kind of transform), `turing_pattern_generator` (pattern
morphology). Nothing connects those but the word.

**This pattern does not generalise.** Checked corpus-wide: exactly two clusters, both in
`regime`, show the agree-on-tail-disagree-on-first shape. It is a fact about the damping
and restitution families, not about how the corpus names things.

## `support` is a pool, not eight meanings

10 members, 8 vocabularies, but the members draw 3–4 terms from one 16-term pool:
`stand`(6), `none`(5), `frame`(5), `pylon`(4), `cabinet`(4), `bracket`(3), `gantry`(2),
`cradle`(1). `code_display` and `tt` are identical; `fire_extinguisher` and
`fire_hose_box` are identical.

Each object declaring the mountings it can actually take is defensible design. The cost
is that the word cannot be swept across the family — there is no common list to vary.

Two members are not in the pool at all and are about **display context** rather than
mounting hardware: `double_helix_scene` (`monument|bench|vitrine|terrace`) and
`pollock_painting_in_3d` (`floor|table|easel|wall`). Those two are a different word
wearing this one.

## What is being asked for

1. Which order wins for the 15 reorder-only words. Mechanical once decided.
2. What the undamped/perfectly-elastic case is called. One word, six artifacts.
3. Whether `support`'s two display-context members should be renamed off the word.

The 68 genuinely-different words are not on this list. They are a larger question about
whether a shared axis vocabulary is a goal of this corpus at all, and nothing here should
be read as assuming it is.
