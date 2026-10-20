# Introduction — shafts only, 2026-10-20

User: remove the understructure, use the elevator shafts for danger, KISS.

Removed the five additional lethal-pit surfaces/volumes from introduction_mezzanine.gd and the floor2 basin cuts from the shared trial rooms.json. The original floor returns beneath the growing cube and in the side aisles. The two original elevator shafts, steel route, cubes, wedges and three transformation mechanisms remain. There are now seven editable assembly parts (three instruments and four captions), plus the unchanged 241 construction records.

This deliberately allows walking around the lesson on the ordinary floor. The shaft crossings retain natural fall danger; no artificial side-aisle kill zones enforce the route.

Saved through the revision-checked API; same layout and Desktop backup for desktop/VR. Exported native editor models without failures. No text changes, other trial-floor changes or curated tower changes.

tools/test_introduction_shafts.py: 122 production desktop/synthetic-XR checks passed, including continuous route, adjustable bank, safe restored floor at centre and side aisles, fatal falls from the raised route into both shafts, restart and unchanged construction. Physical headset not tested.

The previous playtest process started by this chat was replaced with the updated floor2 desktop trial.
