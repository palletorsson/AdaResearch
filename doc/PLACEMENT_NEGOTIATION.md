# Placement Negotiation v1

Placement negotiation makes the agreement between an artifact and the museum
explicit. It explains existing spatial decisions before the system is allowed to
author new rooms automatically.

## Inputs

The negotiator reads four sources:

| Concern | Source |
|---|---|
| Measured artifact body | `ada_run/museum_aaa_pass/report.json` |
| Hard and preferred spatial claims | `commons/artifacts/dressing_rooms/*.json` |
| Available cells, walls, support, and expansion | `ada_run/museum_aaa_pass/negotiation_offers.json` |
| Named cross-layer rules | `commons/data/placement_rules_v1.json` |

The floorplan offer is deliberately separate from the artifact contract. The
artifact cannot claim that a wall exists, and the floorplan cannot weaken an
artifact's hard interaction zone without producing a failed rule.

## Three zones

1. **Occupied body** is measured runtime geometry. It is never negotiable.
2. **Hard zone** is the smallest valid support, interaction, and circulation
   envelope. A placement that cannot supply it is rejected unless a named,
   artifact-authored exception applies.
3. **Preferred zone** is the ideal room. It may be traded away, but the decision
   record must name the compromised soft rule.

The overlay uses magenta for body, cyan for hard space, amber for preferred
space, and a dashed grey line for the floorplan's original offer.

## Decisions

The v1 action vocabulary is:

- `accept` — the offer already satisfies the contract.
- `rotate` — use an allowed artifact orientation.
- `move` — change to an allowed placement mode.
- `grow` — expand the floorplan offer.
- `shrink` — release unjustified surplus space.
- `apply_wall_exception` — waive rear clearance only when the artifact declines
  rear interaction and circulation.
- `reject` — at least one hard rule cannot be repaired by the offered moves.

Every output contains the initial offer, final room, action list, and ordered
`rules_used` evidence. `reject` is a valid result; the solver must never invent a
wall, support, rotation, or clearance to force acceptance.

## Run and validate

```powershell
python tools\placement_negotiator.py --check
python tools\placement_negotiator.py
```

`--check` evaluates the seeded decisions without writing files. The normal run
writes:

- `ada_run/museum_aaa_pass/negotiation_report.json`
- `ada_run/museum_aaa_pass/negotiation/origin.png`
- `ada_run/museum_aaa_pass/negotiation/lambda_slider.png`
- `ada_run/museum_aaa_pass/negotiation/platonicsolids.png`

## Composer dry-run gate

The room composer can now derive offers from its real candidate layout and
submit them to the same rules before any map is written:

```powershell
python tools\compose_map_from_dressing_rooms.py `
  --name Museum_AAA_Featured_Pass `
  --rooms origin lambda_slider platonicsolids `
  --negotiate-dry-run --png
```

The gate reads each candidate room's rotated dimensions, anchor, wall edges,
support, free expansion strips, and circulation ring. It writes evidence to
`ada_run/composer_negotiation/<map>/`:

- `floorplan_offers.json`
- `negotiation_report.json`
- `candidate_map.png` when `--png` is supplied
- one rule overlay per artifact under `overlays/`

An accepted run exits 0. A rejected placement or missing contract exits 1. In
both cases `map_written` is `false`, and `commons/maps/<map>/map_data.json` is
not created or changed. The current gate is intentionally limited to artifacts
with a placement contract and a measured entry in the supplied release report.

## Seed decisions

- **Origin:** grow a valid 3 × 3 m minimum offer to the preferred 5 × 5 m
  complete-orbit room.
- **Lambda Slider:** shrink a 5 × 3 m wall offer to its solitary 3 × 3 m bay and
  apply the explicit zero-rear-clearance exception.
- **Platonic Solids:** grow a valid 9 × 5 m minimum offer to the wall-free
  11 × 7 m island room.

These cases exercise growth, release of surplus space, wall negotiation, support
matching, rotation, neighbor exclusion, and complete-orbit circulation without
changing the canonical maps.
