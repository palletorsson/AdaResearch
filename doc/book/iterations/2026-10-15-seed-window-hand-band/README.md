# Seed windows: controls between the first two rows

Palle requested the interface between rows one and two so the VR hand can reach it. Counting upwards, START is the first row and REPLAY the second. The interface centre is now 1.63 m above the floor. The source display shares this band; the controls remain built into the cabinet.

The first window now begins 0.10 m above the floor. A wider band separates it from REPLAY, leaving space for the complete interface without covering glass or readouts. The upper two windows retain their narrow frame spacing. The three-way comparison, seed values, mapping and draw-order controls are unchanged.

[Tests](test.log): PASS. Checks measure the rendered window bounds to verify that the entire interface fits between START and REPLAY. All seven button targets and both sliders' collision geometry stay within 0.60–1.80 m. Actual XR Tools collision hands press REPLAY and +1 DRAW, withdraw successfully and leave the standing viewpoint fixed. Seed comparison, save/restore, resolution, single-body rebuilding and legacy placement checks also pass.

Native views inspected: [whole instrument](windows.png), [interface](controls.png). Physical headset comfort remains for Palle to judge. The previous lower-interface trial remains in the [body iteration](../2026-10-15-seed-window-body/README.md).
