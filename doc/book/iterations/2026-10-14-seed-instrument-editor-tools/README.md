# Seed instruments use the normal editor tools

Palle: “it should be drag remove etc like the other”.

The previous markers always selected Move, so Remove could not act on them. Markers now obey the current toolbar tool and use the ordinary artifact colour and initials. Move supports dragging and click-then-click placement. A drag threshold prevents a layout shift after selection from turning a click into a move. Occupied instrument cells also count as occupied when placing or moving another artifact.

The instrument inspector includes X, Z, rotation, height, scale, apply, revert, remove and close. Remove works both from the toolbar and inspector. Removed instruments appear in the ordinary palette for placement back into the hall. All operations use the existing map-cell save, automatic apply and undo workflow.

`part_<id>:x,z,yaw[,height,scale]` remains on the seed bench's map cell. Existing three-value poses still work. `part_<id>_removed:true` removes the instrument while retaining its pose for undo or re-add. The runtime disables its visible surfaces, processing, collision layers/masks, picking and rigid-body motion, restoring original settings when added back. Shared seed references remain available so the remaining exhibit can replay even when all three instruments are removed.

The user's latest map positions were preserved: frame study `(3.5,3.5)`, source console `(3.5,8.5)`, movement sampler `(3.5,16.5)`. Browser tests ran with automatic apply temporarily off; all test edits were undone and the original automatic-apply setting restored. The map's hash remained unchanged.

Verification:

- **30/30 native checks**: each instrument's removal, collision/picking removal, exact restoration, independent height/scale/rotation, shared replay, and removal surviving fresh scene load. No script errors.
- **16/16 web tests**: storage, removal/re-add/undo, tool routing, stale-save refusal, native/editor coordinate agreement and strip-cache behavior.
- Scoped TypeScript compilation passed; research inventory refreshed and plan validation passed **61/61**.
- Live browser actions verified Move drag, selection without movement, normal Remove, Undo, palette re-add, height and scale. Screenshot capture returned white images, so the verification uses the visible DOM/accessibility state; it is not screenshot evidence. No headset test.

`before/` holds pre-change files. `web/` holds final files from the sibling `ada_encyclopedia` repository. `museum.json`, `museum.log` and `verification.json` record the checks. No commit or push was requested.
