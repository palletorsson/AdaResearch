# First maps / adaptation trials

Open <http://localhost:3003/void-trials>.

Created a source-backed brief for the first map in all 25 current sequences.
The 197 original artifact placements resolve to existing scene files. No new
Void floor or artifact behaviour was built in this change. The curated tower
layout is unchanged; choosing separate trials versus appended floors is pending.

The board includes the encounter, bring/learn/carry lineage, selected originals,
spatial adaptation, observable test and later-map exceptions. The capacity
register distinguishes existing implementation from untested transfers.
Observations save to `commons/void/trials/reviews.json`, with backups and stale
write protection. A source fingerprint flags changed briefs, map/text sources
and referenced scene files. It does not cover their complete dependency trees.

Verified: all 25 source inventories, ten persistence/conflict/validation checks,
zero scoped TypeScript diagnostics, HTTP inventory, browser next/previous,
browser save and matching saved file. The first saved note is a source finding
for Trans_Pre, explicitly not a native or physical headset test. `board.png`
shows the actual web interface.

Next: choose trial placement and adapt Trans_Pre. Test the original pickup modes
and local animation after relocation before treating them as a reusable capacity.
