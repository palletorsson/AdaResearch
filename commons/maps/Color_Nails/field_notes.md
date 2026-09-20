

## 2026-09-09 — configuration recovered and enclosed

Source: a36f33c996004abcdc67ea2a0ac3fce72eba42fd. Original size [7, 13]; enclosure [15, 21]; every original structure and utility cell preserved at offset (4,4). The real GridSystem retains grid-dependent colour behavior, inside perimeter walls, with no staged glass arena or fire.

Neutral matte grid surfaces; quiet edges, no emission. Historical authored colours still apply.

Source layouts and prior manuscripts are archived in `doc/space/color-recovery-2026-09-09`. Runtime grid and placement checks pass; headset walkthrough remains unverified.
## 2026-09-10 — Grand / Petit salon

Built nail_salon from the existing right-hand mesh, presented as a 4.3 m surreal client and a 32 cm display hand. A manicure table, velvet stools, brass cuff, polish bottles and file provide the petite counterpart. The two existing primary RGB controllers remain at human reach (boxes y=0.9–1.4). Nails face the table. Both hands receive nail and skin colour changes through existing GameManager signals, with separate material overrides.

Kept the 15 × 21 metre outer enclosure; cleared internal height obstacles and removed dark_sphere. Replaced the disconnected hand_model with nail_salon, retained as secondary. Moved supporting exhibits to the sides and reduced the brick-wall study to 0.4 scale. Reserved the working area against automatic museum sculptures. Previous map and documents: `doc/space/nail-salon-2026-09-10/before/Color_Nails/`.

Thirty desktop museum assertions pass, including placement, same source mesh at both scales, distinct material surfaces, two reachable RGB boxes, real pickable-point motion with a supplied grabber, propagated colour values and both side-route body sweeps. Report: `ada_run/probe_nail_salon.json`. Capture: `ada_run/nail_salon_museum.png`. Test samples use pink nails and teal skin; saved player colours are restored afterward. No tracked-hand or headset-comfort claim is made. Startup retains the existing unknown UID warning; no script errors occurred in the final tested run.

The book now invites a comparison of the same colour at two scales. The display hands work without tracked controllers, while player-hand connectivity remains a separate question. Reusable method: expose one material address on two differently scaled receivers, and keep the controls within bodily reach.

## 2026-09-10 — Open control plinths

Moved both RGB interfaces onto separate open plinths in front of the salon, at grid (5,14) and (9,14). The control volumes remain y=0.9–1.4 m, with no table or canopy between the visitor and the colour point. The auxiliary palette display now builds its glass case before spawning balls, with its spawn area restricted to that case. The scene's previous 10 m spawn area could put balls directly into the approach and the RGB boxes.

The extended museum probe passes 35 checks, including contained ball bodies, separate nail/skin changes and both side routes. Updated evidence: `ada_run/probe_nail_salon.json` and `ada_run/nail_salon_museum.png`. Tracked-hand reach remains untested.
