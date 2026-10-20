# A repeated image, another way through — implementation

Sources: mirrored_cellular_automata.gd::update_grid, apply_quad_symmetry; RhizomaticMazeGenerator.gd::connect_as_tree, generate_primary_connections, sever_network.

The opt-in `pg_workshop_console` binds the named artifacts within its own museum hall; controls are implemented in commons/artifacts/timing_machines/pg_workshop.gd. Six push buttons occupy one compact 3×2 desk with an inclined translucent readout. RULE reveals the implementation card. Actions are guarded while a rebuild is in progress.

Hold a cellular input while changing copying; separately compare connections over fixed seeds.

For the quadrant arrangement, the operation reads a cell from one quarter and writes its value to corresponding positions elsewhere:

```gdscript
new_grid[y][grid_size - 1 - x] = value
new_grid[grid_size - 1 - y][x] = value
```

There are consequences at the edges of this promise. This study uses an odd-sized grid; its centre row and column do not belong to every copying loop. The rotational operation also converts floating-point positions into integer addresses. A symmetrical intention still passes through a particular implementation.

STEP performs one cellular update and then its selected symmetry operation. In this desk study, eligible births and deaths have probability one, so the comparison isolates the update and copying rules. HOLD can keep that new result as the input for the next comparison. Cycling STENCIL to none restores the held field with copying disabled; it does not erase what you chose to hold.

Now move your attention from the surface to the network beside it. NETWORK changes the connection policy over six fixed starting positions. The opening is a tree. Its unique connections give one connected component and no cycle. The next policy admits more nearby connections; the third severs connections across a central gap and separates the remaining pieces.

Watch the counts before deciding what the silhouette means. The desk reports distinct undirected connections, components and independent cycles. The generator may store an edge in both directions; those duplicate records do not create another physical route. For this finite undirected graph, the cycle count is `edges - nodes + components`.

Changing NETWORK preserves the six initial positions. The severed result subsequently displaces positions as part of making its gap, so the final coordinates are not all held fixed. This is a comparison of construction policies, not a claim that every visible difference came from deleting one edge.

SURFACE alternates the bare connections with the tunnel surfaces constructed around them. The specimen's collision is disabled in both views: it is an observation model, not a secretly solid set of invisible tubes. Its gaps and curved surfaces are available to examine before we develop a full bodily traversal. A thick skin can obscure connections that were obvious in the skeleton.

Space: the inherited structure is retained in a larger surround; relocated objects have an independent museum aisle. Source zeros remain present and receive explicitly listed museum.floor_cells covers. The floor audit records offsets and covers. Raised historic cells are retained witnesses, not universally certified decks.

Validation: see doc/space/pg-sequence-2026-09-15 and ada_run/pg-review-2026-09-15. Report actual runtime checks separately from outstanding human headset/clearance review.


## Reconstructed tutorial — 9 October 2026

Full reflection.gd/panels.gd/unchanged Sculpted point_body.gd. Held nested array deep-copied with duplicate(true); result independently copied. Each reflect starts from held, copies upper-left n/2 rows/columns to three partners using n-1-address. Production quadrant operation deliberately leaves odd centre cross unchanged. Complete INCLUDE_AXES=true variant extends limit by n%2; centre maps to itself. Five-by-five fixture baseline13ones, edited13ones; four changed cells between results. Baseline6diffsfrominput, edited10diffsfrominput. Predict centre row0,1,1,1,0 andcolumn1,0,1,0,1. Even fields unaffected by includeaxes.

Three-file host builds fifty .144m-wide box faces spaced.16m, zthickness.04. Dark/light=0/1; dark/lightpink=0/1 oncentreaxes. Leftinput/rightresult. Action/SPACEreflect,Voriginal,Mflipresult[2][4],Hholdresult,Rresetfixture. Moveheldpointdoesnotcopy;releasephysicsparkslocal(0,1.1,1.2). No undeclaredscene nodes, no learnercollision. Temporarymaplocal(8.5,0,6.5),yaw180;approach(8.5,0,4.5). Production unchanged.

29 exactprintedchecksPASS. 32fullfieldcomparisons (sizes1,2,3,4,5,6,7,31 xfourfixturesincludingdistinctaddressvalues) matchproduction apply_quad_symmetry. Independentdestinationoracle checks alladdresses; input/caller nonmutation, idempotence, even/oddaxes, sample predictions, snapshotofresultalias, fullhost50cells/materialdatamatch,HOLD/M/RESET/keyboard, suppliedactualXRToolspick/action/drop undertranslatedrotatedhost. Entire studentedit andthreecompletefaultyhosts tested; wrongrowalias,offbyonepartner,notrestoringheld rejected. NoSCRIPT/Parseerrors acceptedlogs; existingprojectUID/rendererwarnings retained.

35 nativechecksPASS. Realpointer STEP,HOLD,STENCIL,NETWORK,SURFACE,RULE; actualfield31x31 opens182live, STEPnone229live, heldquad233live. Printedreflection matchesactualheldarray. STEPcheckedasLife(displayed)thenquad withfixedborder/probabilities1; heldunchanged. Cyclingnone restoresheld rather thanlatestgeneration. Actualnetwork6nodes:tree5edges/1component/0cycles;rhizome11/1/6;severed2/4/0. Metrics deduplicate undirected records; seedpositionspreserved, severedfinalnodesmaymove. Bothsurfaceandbareviews collisiondisabled. Fullstudentbaselineandaxisvariant runintheexistingroom, suppliedXRTools action/releaseverified. Elevennativeimages includeheldstateAFTERSTEP/HOLD beforequad;firstcamera receiptretainedwhereopeningandquadinputdiffered. Captions distinguish opening,held,andreflected states.

Sidebypass254capsules supported=True,clear=True;startbesidedeskat(20,0,3.5),x28to44.5,rearx16.5toexit46.5. Authoredentry(16.5,.05,1.5)stillblockedbydesk. Locallearneranddeskapproachesclearandsupported. Notfullportal/playertraversal;networkspecimen deliberatelynoncolliding. Overheadshowsclearprincipalstations,effectofvisuallydominantpatterntunnel,andveryemptyrearcourt. Noarchitecturechange. Cameraexposure.45. Beforethreeimages/finaleleven. Noheadset/Quest/independentstudent/browserlayoutacceptance.

Canonicalfinalcodeexcerptreplacedwithproseandcentre-crossobservation;existingnetworkreflection/footnote/SoftBodieshandoffretained. Onlytargetexecutionplanrowupdated,draftretained; dependencies now Sculpted Forms/CA Introduction, no prerequisite symmetry or graph course. Algorithm/scene/workshop/map/sequencehashesprotected;runtimeplantargetrowunchanged. Review doc/book/iterations/2026-10-09-mirrored-a-copy-kept/index.html. Next:wholeProceduralGenerationreadings/review.
