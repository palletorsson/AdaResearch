# Crisis Synthesis — a model that can be answered

This hall ends Foundations Crisis and introduces the QFEP Laboratory. It brings distinct examples into relation: changing a model's terms, iterating a recurrence, describing a room inside itself, and returning to membership, proof, construction and contradiction. These examples do not jointly prove QFEP.

## Encounter order

1. Read `qfep_formula_3d`. Its three buttons select F, lambda or phi, and put a question beneath the term.
2. Move `lambda_slider` and `phi_slider`. Their signals update the local formula's colours and numeric readout. The sliders retain their own visual effects. Their `calibration:dispute` plates show competing preferred settings.
3. Use the independent `r` slider beside `bifurcation_diagram`. Compare fixed-point, period-two, period-four and period-three samples.
4. Walk into `goedel_atrium` and find the model of the doorway just crossed.
5. Return to `russell_paradox_workbench`, then compare the plaque, box, staircase and sphere.

The formula, its two rails, the recurrence, the atrium and the Russell workbench carry the main investigation. The smaller returning works remain available as comparisons. No artifact family has been removed.

## A display and a calculation

The formula reads:

```
QFE = F − λE(S) + φΔE(S,t)
```

Its optional `reading_study:on` mode creates a reachable term console and binds the two sliders within this museum hall. It changes a reading apparatus. It does not calculate F, entropy or QFE; it does not change player physics or broadcast an r value.

For an operational QFEP model, specify the states S, probabilities, definition of F, units, time interval, objective direction and update law. Delta denotes a difference; a rate also requires division by elapsed time. A positive coefficient is not intrinsically an instruction to welcome change. The colour bands are authored interpretations.

The logistic artifact performs a separate recurrence:

```gdscript
x = r * x * (1.0 - x)
```

`visitor_control:on` enables its r rail and yellow orbit column. Each selection begins at x = 0.5, skips 512 iterations and displays the next 128. The full background diagram retains its existing coarser sampling. The readout checks the tail of the selected sample for periods 1–16 with tolerance 0.000001. “No short repeat detected” is a statement about that sample, not a proof of chaos.

Useful stops are r = 2.9, 3.2, 3.5 and 3.83. The source also exposes a revealing exception: at r = 4 and x = 0.5, the orbit reaches 1 and then 0. A parameter alone does not determine every initial condition's itinerary. See [Rutgers' logistic-map notes](https://www.physics.rutgers.edu/grad/509/Logistic%20map.html).

## The recursive room

`goedel_atrium` builds a room, then places a tenth-scale copy on its central plinth. This placement uses room_size = 6 metres and the existing default recursion depth 2. The nested copies are finite. Its wall identifies the work as a spatial metaphor; self-description alone does not prove incompleteness.

The Russell workbench enables its existing membership controls. The returning sphere uses `hold_both:on`, so observation or cycling does not collapse the two readings. Their source explanations and the earlier chapters supply the conceptual distinctions.

## Space and references

The authored map is a level 19 by 24 grid, with a three-cell entrance and exit and a six-metre atrium in the right-hand bay. This replaces the raised central mound that translated into an obstruction in the museum. All ten existing artifact families remain. No automatic sculpture or plinth is added in this hall.

- Formula and reading apparatus: `commons/interfaces/qfep/formula_display/`.
- Local rails: `commons/interfaces/qfep/lambda_slider.gd` and `phi_slider.gd`.
- Recurrence and r control: `commons/interfaces/foundations/bifurcation_diagram.gd`.
- Recursive room: `commons/artifacts/goedel_atrium/goedel_atrium.gd`.
- Placement and prose: this directory's `map_data.json` and `final.md`.
- Research argument: [Entropic Morality](../../../doc/research/qfep/entropic-morality.md).
- Verification and images: [dated encounter review](../../../doc/book/iterations/2026-09-20-crisis-synthesis-review/SUMMARY.md).

The controlled desktop museum probe checks specified routes, signal paths and sampled orbits. Tracked-hand reach, headset legibility and learner interpretation still require a visit.


<!-- study-spine:sentence_authority -->

## Installed application: Permission at three scales

`sentence_authority` occupies a new adjoining bay, after the existing encounters. Cell [11, 34], rotation 180°, museum adapter `res://commons/artifacts/spine_studies/sentence.tscn`. Original response to Jenny Holzer; no claim of exact reconstruction.

Change one sentence once; follow the same words across label, strip and wall. Reuses loop, array, inscription, limit; adds no prerequisite node. The display and main-player controls are supplied.


<!-- study-reference:sentence_authority -->

### Reference and scope

Holzer circulated statements in different public formats. The installation uses original Ada sentences; changing their scale or rhythm does not establish their truth and is not an illustration of an incompleteness proof.

[MoMA: Jenny Holzer, Truisms](https://www.moma.org/collection/works/63755).
