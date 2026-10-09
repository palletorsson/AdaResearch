# Shared field experiment

The primary flow_field_painter is mounted at y=1.05 with scale2.5. Its opt-in shared_field lesson aligns the backing canvas with the XZ trails, uses80 particles and seed43, and starts with field evolution held. ARROWS reveals24 glyphs; FIELD TIME toggles only the field clock. Existing SCALE, SPEED, RESET and SEED controls remain. Both glyphs and particle updates call field_direction. In lesson mode SCALE affects the noise frequency once; legacy instances retain their existing sampling behavior. Arrow geometry refreshes at10Hz; particles update every frame. Opposite edges wrap; the stored trail can draw across that seam, and the noise itself is not periodic.

This is prescribed advection, not a force or gradient model. The standalone vector_field_visualizer, vector_field_grid and other supporting artifacts are independent examples. Never write that their arrows steer these particles.
