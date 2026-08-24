# Principal-Wall Prop Negotiation Report

## Rules used

- Wall centre: 20-80% width, reserved for artifact claims or book/feature content.
- Side rails: 0-18% and 82-100% width; support props live here.
- Exit signs: upper side rail, within 1.25 m horizontally of an entrance/exit anchor.
- Fire extinguishers: grounded in the low side rail, within 1.25 m of an exit.
- Material boxes: grounded in a corner, within 0.75 m of its corner anchor.
- Interactive controls: centre height 0.75-1.35 m.
- Accepted rectangles may not overlap one another.

## Decisions

| Bay | Artifact | Disposition | Accepted | Rejected |
|---|---|---|---|---|
| bay_01 | `origin` | freestanding_hero_with_feature_field | station_panel, exit_sign, fire_extinguisher | none |
| bay_02 | `lambda_slider` | wall_hero_with_side_rails | emergency_button, station_panel, exit_sign, fire_extinguisher | none |
| bay_03 | `phi_slider` | host_mounted_with_feature_field | station_panel, exit_sign, fire_extinguisher | none |
| bay_04 | `platonicsolids` | freestanding_hero_with_feature_field | station_panel, station_crates, exit_sign, fire_extinguisher | none |
| bay_05 | `random_walk_leash` | freestanding_hero_with_feature_field | station_panel, exit_sign, fire_extinguisher | none |
| bay_06 | `shannon_entropy_meter` | wall_hero_with_side_rails | exit_sign, fire_extinguisher | none |
| bay_07 | `harmonic_distance_table` | host_mounted_with_feature_field | station_panel, exit_sign, fire_extinguisher | none |
| bay_08 | `pattern_loom` | freestanding_hero_with_feature_field | station_panel, exit_sign, fire_extinguisher | none |
| bay_09 | `gradient_descent_visualization` | protected_environment | exit_sign, fire_extinguisher | station_panel (artifact_contract_protects_the_full_environment) |
| bay_10 | `neural_network_visualization` | protected_environment | exit_sign, fire_extinguisher | station_panel (artifact_contract_protects_the_full_environment) |

## Runtime result

- Accepted props: 29
- Rejected requests: 2
- Compiled clusters: 10
- New floor area: 0 m2
- Public spine consumed: 0 m
