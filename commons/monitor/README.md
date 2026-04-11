# Monitor — In-Game Display Systems

Camera-based monitor displays and message consoles for VR environments.

## Files

| File | Description |
|------|-------------|
| `monitorsystem.gd/.tscn` | `GameMonitorSystem` — 4 SubViewport camera monitors (overhead, third-person, mirror, side) |
| `cctv.gd/.tscn` | `CCTVMonitor` — single SubViewport display showing a target scene, configurable via grid system |
| `VRconsole.gd/.tscn` | VR message console — connects to `GameManager.console_message_added` signal |
| `MessageItem.gd/.tscn` | Individual message entry for VRconsole |
| `2d_in_3d_monitor.tscn` | 2D UI rendered on a 3D surface via SubViewport |
| `infokiosk.tscn` | Information kiosk display scene |
