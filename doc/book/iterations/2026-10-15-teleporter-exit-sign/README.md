# Exit sign on the exit

2026-10-15. Palle: “put the exit sign in the exit and remove it from the wall.”

Random Definition now mounts the existing green EXIT sign on the next-hall
teleporter lintel, above the Random Entropy destination label. The map refuses
the old decorative wall exit signs with `museum.props_deny`, and enables the
attached sign with `museum.portal_exit.exit_sign = true`. Other halls keep their
existing signage. Portal placement, clearance and crossing behavior are unchanged.

The isolated native museum loaded successfully; 5/5 placement and capture checks
passed. There is exactly one exit-sign instance in the hall, parented to
`HallPortals/NextHall`. Both rendered views were inspected for mounting and text
separation. Runtime evidence and source manifest are in
`ada_run/encounter_pilot/Random_Definition/teleporter-exit-sign/`.

Reload the hall to apply the change. No commit or push was requested.
