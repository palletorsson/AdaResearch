# Player — Avatar and Input Systems

Player customization, input handling, and HUD components attached to the XR rig.

## Files

| File | Description |
|------|-------------|
| `PlayerCustomization.gd` | Progressive avatar system — unlockable features (hands, skin/nail color, IK arms, dresses, accessories) |
| `WristStatsDisplay.gd` | Wrist-mounted HUD showing map name, XP, health |
| `joystick_deadzone_fix.gd` | Applies deadzone correction to XR controller joystick input |
| `velocity_deadzone.gd` | Filters low-velocity movement to prevent drift |
| `pickup_xp_listener.gd` | Listens for artifact pickup events and awards XP |
| `stuck_detector.gd` | Detects when the player is stuck and offers recovery options |
