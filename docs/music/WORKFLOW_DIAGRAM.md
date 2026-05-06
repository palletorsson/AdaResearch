# Creation Loop - Visual Overview

```
                            ╔═══════════════════════════════════════════╗
                            ║           CREATION LOOP                    ║
                            ╚═══════════════════════════════════════════╝

     ┌──────────────────────────────────────────────────────────────────────────┐
     │                                                                          │
     │    ╭─────────────╮         ╭─────────────╮         ╭─────────────╮       │
     │    │             │         │             │         │  BRILLIANT  │       │
     │    │  🔬 RESEARCHER │────▶│  📚 TEACHER  │────▶│  🎓 STUDENT  │       │
     │    │             │         │             │         │             │       │
     │    ╰─────────────╯         ╰─────────────╯         ╰──────┬──────╯       │
     │          ▲                                                 │              │
     │          │                                                 ▼              │
     │          │                                         ╭─────────────╮       │
     │          │                                         │             │       │
     │          └─────────────────────────────────────────│ 📊 EVALUATOR │       │
     │                         feedback                   │             │       │
     │                                                    ╰──────┬──────╯       │
     │                                                           │              │
     └───────────────────────────────────────────────────────────┼──────────────┘
                                                                 │
                                                                 ▼
                                                         ╭─────────────╮
                                                         │  📦 ARCHIVE │
                                                         │   (if good) │
                                                         ╰─────────────╯


═══════════════════════════════════════════════════════════════════════════════


                              ROLE RESPONSIBILITIES

    ┌─────────────────────────────────────────────────────────────────────────┐
    │                                                                         │
    │   🔬 RESEARCHER                      📚 TEACHER                         │
    │   ─────────────                      ──────────                         │
    │   • Study reference tracks           • Create song configs              │
    │   • Analyze production               • Write code examples              │
    │   • Document techniques              • Define parameters                │
    │   • Find patterns                    • Map words → synth                │
    │                                                                         │
    │   OUTPUT:                            OUTPUT:                            │
    │   → SONG_IDENTITIES.md              → songs/*.json                     │
    │   → SYNTH_RESEARCH.md               → synth code                       │
    │                                                                         │
    ├─────────────────────────────────────────────────────────────────────────┤
    │                                                                         │
    │   🎓 BRILLIANT STUDENT               📊 EVALUATOR                       │
    │   ─────────────────────              ────────────                       │
    │   • Generate audio                   • Compare to references            │
    │   • Apply parameters                 • Run TrackScorecard               │
    │   • Experiment creatively            • Score quality                    │
    │   • Push boundaries                  • Suggest improvements             │
    │                                                                         │
    │   OUTPUT:                            OUTPUT:                            │
    │   → Audio stream                     → Scores (0-10)                    │
    │   → Novel combinations               → Specific feedback                │
    │                                                                         │
    └─────────────────────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════════


                              ITERATION FLOW

    Iteration 0 (Bootstrap):
    ────────────────────────
    
    [Genre Request] ──▶ 🔬 ──▶ 📚 ──▶ 🎓 ──▶ 📊 ──▶ [First Score]
                        │                              │
                        └────── initial research ──────┘


    Iteration N (Refinement):
    ─────────────────────────
    
    [Specific Issue] ──▶ 🔬 ──▶ 📚 ──▶ 🎓 ──▶ 📊 ──▶ [Improved Score]
          ▲                                              │
          └──────────── targeted feedback ───────────────┘


    Convergence:
    ────────────
    
    Score > 8/10? ──yes──▶ 📦 ARCHIVE ──▶ [Done]
         │
         no
         │
         ▼
    [Next Iteration]


═══════════════════════════════════════════════════════════════════════════════


                              QUALITY DIMENSIONS

    ┌────────────────┬───────────────────────────────────────────────────────┐
    │   Dimension    │   Question                                            │
    ├────────────────┼───────────────────────────────────────────────────────┤
    │ Authenticity   │ Does it sound like the target genre?                  │
    │ Coherence      │ Do all elements work together musically?              │
    │ Interest       │ Does it hold attention over time?                     │
    │ Technical      │ Clean mix? Proper levels? No clipping?                │
    │ Innovation     │ Any novel or surprising elements?                     │
    └────────────────┴───────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════════


                              FILE LOCATIONS

    docs/music/
    ├── CREATION_LOOP.md        ◀── Full architecture doc
    ├── SONG_IDENTITIES.md      ◀── Research output
    ├── WORKFLOW_DIAGRAM.md     ◀── This file
    │
    docs/
    └── SYNTH_RESEARCH.md       ◀── Techniques + track suggestions
    
    songs/
    ├── {genre}.json            ◀── Current configs (Teacher output)
    └── archive/
        ├── ARCHIVE_INDEX.json  ◀── Version history
        └── {genre}_v{N}.json   ◀── Archived versions


═══════════════════════════════════════════════════════════════════════════════
```
