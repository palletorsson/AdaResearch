# Random Space: raised violet floor

The author requested a higher noise floor and another colour. This applies to the existing `random_space` ground in Random_Space.

- Raised only this museum placement by 0.20 m using the existing per-instance offset. Its 1.4× scale, random seed, local mesh and distribution remain identical. Measured world height now ranges from 0.0326 m to 0.3678 m above the hall floor.
- The placement chooses violet `6b427d` and reduces emission from 0.42 to 0.02. The shared script now accepts its existing material exports through map config; a material-only change does not regenerate mesh or collision. Other placements retain the original defaults.
- Raised the small cellular display's support from 0.35 m to 0.40 m, keeping it above the highest part of the ground. The entropy gauge and noise mixer remain in place.
- Revised only the obsolete pale-patches description and current companion staging notes. Replaced the chapter photograph with a new native PNG; previous review evidence is retained.

Native final run: 8 checks pass, exit 0, no GDScript errors. Visible and collision triangles match. The complete local vertex hash matches the before run. Both photographs use the same eye-height camera positions. Original scene resource unchanged. Existing engine warnings remain in the logs. This does not close the separate navigation-planner or headset-route tasks.
