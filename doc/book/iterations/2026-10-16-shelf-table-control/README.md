# One NEXT button on the table

16 October 2026. Palle asks to integrate the controls into the table as a protruding appendix, with one NEXT button.

The installed Random Definition shelf now has a 56 cm wide, 46 cm deep tabletop extension, overlapping the existing front edge by 6 cm. It shares the tabletop material and height and has matching collision. One rectangular NEXT button faces upward; its label moves with the button cap. The four floating hall controls and their status line are removed.

NEXT advances the same retained value through position, scale, rotation and hue; the eight-value sequence wraps. The standalone learner preview retains its research controls, and the recording helper remains available programmatically. Shared seed behaviour, artifact placement, final text and first 48-value pilot are unchanged.

The [native view](shelf-in-hall.png) was inspected. [40 checks pass](museum-report.json): the original hall integration checks plus the single control, joined surface, upward orientation, collision and attached label. Only NEXT is exercised through a physical button signal; replay/save/load checks use the retained helper API. This is not a headset trial. The existing museum cleanup warning about leaked ObjectDB instances remains; no script errors occurred.

Reproduce:

```powershell
python tools/run_encounter_probe.py Random_Definition --sequence randomness --render --no-bridges --output-tag shelf-table-control --probe doc/book/iterations/2026-10-16-shelf-table-control/museum_probe.gd
```
