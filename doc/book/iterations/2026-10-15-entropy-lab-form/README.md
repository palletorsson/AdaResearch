# Two accounts, one laboratory instrument

Palle asked for the Shannon–Boltzmann setup to resemble the local [surreal laboratory gallery](http://127.0.0.1:3003/surreal-lab-gallery). The reference was inspected in the browser and its procedural material helpers read in `commons/artifacts/surreal_lab/surreal_lab.gd`.

The existing bench now has a dark steel cabinet, a lit plinth, open specimen trays with glass sides, luminous A/B occupants, numbered sockets, and two round instrument housings. Their scales retain separate units. The Boltzmann pointer, illuminated ticks and bar follow the computed S_B/k_B; the Shannon dial remains at one bit for the fixed 8/8 colour inventory. The front model plate explicitly identifies the configuration model and absence of heat/temperature dynamics. No flicker or decorative random motion enters the experiment.

The core `compartment_model.gd`, experiment controls, random generator and record schema are unchanged. The taller title/dials increase the registered height from 2.2 to 2.6 metres; the ground footprint and hall position stay the same. The tutorial and final receive short situated-description updates, preserving the room/text order and the 48-value bench as first research pilot.

## Evidence

- [55 apparatus checks](verification.json), including 52 existing checks plus zero/full dial positions and a same-k comparison.
- [55 reconstructed-scene checks](reconstruction/verification.json), using the printed model and declared host files. This is executable reconstruction, not a learner trial.
- [16 hall checks](museum-report.json), including supported approach, reachable controls and saved replay in the authored Random Entropy hall.
- Before/after native captures in the [comparison](index.html). Camera framing differs slightly to accommodate the taller instrument. These are saved images, not a web simulation.

The initial visual inspection found the lower model plate partly hidden behind the event display. Moving it down exposed the complete description; the final hall image records the repair. Physical headset comfort and Quest performance remain untested. The native log retains the inherited Jolt shape-bias warning.

## Reproduce

From the Ada Research root:

```powershell
python -X utf8 doc/book/iterations/2026-10-15-entropy-lab-form/run.py --render
python -X utf8 doc/book/iterations/2026-10-15-entropy-lab-form/reconstruct.py
python -X utf8 tools/run_encounter_probe.py Random_Entropy --sequence randomness --render --no-bridges --output-tag entropy-lab-form --probe doc/book/iterations/2026-10-15-entropy-lab-form/museum_probe.gd
python -X utf8 doc/book/iterations/2026-10-15-entropy-lab-form/publish.py
```

For live controls, run `commons/artifacts/entropy_compartments/preview.tscn` with F6 or revisit Random Entropy in the desktop museum. This is the same registered `entropy_compartments` artifact.
