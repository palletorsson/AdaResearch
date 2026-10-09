# Claude writing handoff

Read the prepared page at http://localhost:3003/book-review/doc/book/iterations/2026-09-23-writing-next/index.html.

Complete packets and ZIPs live here under packages/. The iterations directory is a reading mirror because the server does not serve handoffs/ or ZIP downloads. Upload the local ZIP and its review.md to online Claude, or give local Claude the packet directory and COPY_TO_CLAUDE.md.

Start with SoftBodies_Cloth_Physics. Other packets are separately bounded alternatives. No canonical chapters changed and nothing was sent to Claude.

build_packages.py creates frozen packages and refuses existing package folders. add_neighbours.py adds adjacent chapters and rebuilds manifests and ZIP hashes. build_page.py renders the page. Publication copies the page, assessment, brief and per-packet assignment/review/prompt into doc/book/iterations/2026-09-23-writing-next. verify_packages.py checks current source equality, package hashes and the reading mirror/links; the report is verification.json in both locations.
