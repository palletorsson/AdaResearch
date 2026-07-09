# Template hybrid research — specialists vs cross-taste hybrids

Seed 23, 8 offspring per cross (24 hybrids + 3 specialists).
Generalist score = MIN fitness across the three tastes.

| room | parents | capacity | drama | intimacy | generalist | mean |
|---|---|---|---|---|---|---|
| HYB_CAPxINT_7 | capacity×intimacy | 61.6 | 60.02 | 64.12 | **60.02** | 61.91 |
| HYB_CAPxINT_4 | capacity×intimacy | 61.6 | 59.95 | 64.05 | **59.95** | 61.87 |
| HYB_CAPxINT_3 | capacity×intimacy | 61.6 | 56.0 | 60.5 | **56.0** | 59.37 |
| HYB_DRAxINT_6 | drama×intimacy | 55.6 | 58.48 | 57.27 | **55.6** | 57.12 |
| HYB_DRAxINT_7 | drama×intimacy | 55.6 | 57.35 | 61.65 | **55.6** | 58.2 |
| HYB_CAPxINT_5 | capacity×intimacy | 59.6 | 53.12 | 62.73 | **53.12** | 58.48 |
| SPEC_INT | intimacy | 59.6 | 52.92 | 70.92 | **52.92** | 61.15 |
| SPEC_CAP | capacity | 61.6 | 62.45 | 52.05 | **52.05** | 58.7 |
| HYB_DRAxINT_8 | drama×intimacy | 51.6 | 59.55 | 54.45 | **51.6** | 55.2 |
| HYB_CAPxINT_2 | capacity×intimacy | 55.6 | 56.27 | 50.28 | **50.28** | 54.05 |
| HYB_CAPxINT_6 | capacity×intimacy | 55.6 | 52.33 | 49.93 | **49.93** | 52.62 |
| HYB_CAPxDRA_5 | capacity×drama | 61.6 | 62.5 | 49.9 | **49.9** | 58.0 |
| HYB_CAPxDRA_8 | capacity×drama | 61.6 | 62.38 | 49.78 | **49.78** | 57.92 |
| HYB_DRAxINT_2 | drama×intimacy | 47.6 | 54.7 | 55.5 | **47.6** | 52.6 |

## Finding

**The hybrid wins.** HYB_CAPxINT_7 (capacity×intimacy) tops the generalist table at 60.02 vs the best specialist's 52.92 (SPEC_INT). Genome: form=basilica, light=dramatic, niches every 4, podium ring, floating walls 3. Cross-taste breeding finds rooms that hold capacity, drama AND intimacy at once — the taste populations should touch.

Walk them: /map-viewer?map=TemplateLab_HYB_GEN and TemplateLab_SPEC_CAP/DRA/INT.

## Robustness (two seeds)

Seed 11: the SPECIALIST held (SPEC_INT best generalist at 55.6; no hybrid beat it).
Seed 23: the HYBRID won decisively (HYB_CAPxINT_7 at 60.02 vs SPEC_INT 52.92).

The split verdict is itself the finding, plus two patterns that held on BOTH seeds:

1. **capacity×intimacy is the productive cross.** CAPxINT children dominate the
   generalist top of the table on both seeds; CAPxDRA children consistently crater
   on intimacy (drama's long vistas are intimacy's enemy — the two tastes pull the
   genome in opposite directions and their children inherit the tension unresolved).
2. **The intimacy champion is the strongest specialist-generalist.** Its fitness
   already contains the walkability terms (reach, approach, order), so breeding FOR
   intimacy quietly breeds for well-formed rooms overall.

**Recommendation for the engine:** let the capacity and intimacy populations
exchange migrants (a few crossover children per generation); keep drama isolated —
it is a genuine specialist taste whose rooms should not be averaged. The generalist
champion (basilica 24×13, ring podiums, niches every 4, three floating MoMA walls,
dramatic light) is walkable at /map-viewer?map=TemplateLab_HYB_GEN.
