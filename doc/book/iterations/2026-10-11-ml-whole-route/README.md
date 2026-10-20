# Eight Machine Learning halls — review bundle

Open index.html for the route, actual museum images and review. Open parallel.html to read each tutorial on the left and final.md on the right. tutorial.md and final.md contain the complete sequences as separate files; halls/ holds each chapter. Links and Evolution's figure are made relative for offline reading; the source register hashes the canonical repository originals.

learner/ contains exact printed Godot files for every hall, including each declared carried dependency. This is not a standalone Godot project. It requires the existing AdaResearch_46 project, Godot 4.6, XR Tools, museum runtime and RackTemplates. Put the chapter's files in its documented res://doc/book/studies/ folder and use its supplied museum launcher. supplied-museum/ includes those launchers. Existing room artifacts remain in the full project.

Inside that project, run:

    python tools/review_ml_sequence.py
    python tools/test_ml_feedback_artifacts.py
    python tools/publish_ml_sequence_review.py

The first command reconstructs all eight tutorials, compares extracted files to working studies, runs their native Godot assertions, and exercises the ONE and A/B file handoffs. Reproduction scripts are retained under reproduction/ at their repository paths; probes expect the dated review folders at the same paths as in Ada. The native room captures require tools/run_encounter_probe.py and the existing museum. This ZIP contains evidence from their individual runs; it does not include the entire game or a headset test.

Read REVIEW.md for what changed and what remains untested. The new handoff probe uses private fixture files under this review directory, not the visitor's saves. Reports label synthetic inputs and author-informed reconstruction explicitly. Feedback should distinguish numerical behaviour, sufficiency of explanation, progression, reflective claims and physical usability.
