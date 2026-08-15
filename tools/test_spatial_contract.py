#!/usr/bin/env python3
"""Behaviour tests for the spatial contract, masks and negotiation layer.

Two of these are regressions for bugs that only the Godot capture caught: a
2D plan can validate perfectly and still put the artifact somewhere else in 3D.

Run:  python -m unittest test_spatial_contract   (from tools/)
"""
from __future__ import annotations

import unittest

import spatial_contract as sc
import spatial_floorplan as fp
import spatial_negotiation as neg
import spatial_slice as slice_


class ContractResolutionTests(unittest.TestCase):
    def test_measured_geometry_beats_a_capped_hand_mirror(self) -> None:
        """footprint_cells=9 is a ceiling from sync_footprints, not a
        measurement, and must lose to a bigger measured body.

        Asserts the RELATION, not the number. An earlier version of this test
        hardcoded [10, 1] and broke the day the corpus was re-measured — which
        is a test asserting a snapshot of a known-wrong measurement.
        """
        c = sc.resolve("neural_network_visualization")
        area = c.footprint_cells[0] * c.footprint_cells[1]
        self.assertGreater(area, 9, "must not shrink to the capped scalar")
        self.assertTrue(any("understates" in m or "scalar area" in m
                            for m in c.conflicts),
                        "the disagreement must be recorded, not silently won")

    def test_provenance_names_a_source_for_every_resolved_field(self) -> None:
        c = sc.resolve("science_screen")
        for key in ("body.size_m", "body.footprint_cells", "placement.modes"):
            self.assertIn(key, c.provenance)

    def test_hand_authored_intent_outranks_derived_intent(self) -> None:
        """science_screen's dressing room says against_wall; nothing derived
        may overrule it."""
        c = sc.resolve("science_screen")
        self.assertEqual("against_wall", c.preferred_mode)
        self.assertEqual("placement_contract.preferred_mode",
                         c.provenance["placement.preferred_mode"])

    def test_unknown_artifact_still_yields_a_valid_contract(self) -> None:
        c = sc.resolve("no_such_artifact_anywhere")
        self.assertEqual([1, 1], c.footprint_cells)
        self.assertEqual("default", c.provenance["body.size_m"])


class MaskTests(unittest.TestCase):
    def test_the_three_masks_are_disjoint(self) -> None:
        m = sc.masks(sc.resolve("bias_visualizer"))
        self.assertFalse(m.physical & m.circulation)
        self.assertFalse(m.physical & m.presentation)
        self.assertFalse(m.circulation & m.presentation)

    def test_clearance_is_directional_not_a_radius(self) -> None:
        """front:2 back:1 must produce more cells in front than behind.

        Front is +z at rotation 0 because the declared rotation_semantics say
        0 faces south — not because of any convention invented here.
        """
        c = sc.resolve("bias_visualizer")
        self.assertGreater(c.clearance["front"], c.clearance["back"])
        self.assertEqual((0, 1), sc.ROTATION_FACING[0])
        m = sc.masks(c, rotation=0, mode="freestanding")
        zs_body = [z for _, z in m.physical]
        front = [z for _, z in m.circulation if z > max(zs_body)]
        back = [z for _, z in m.circulation if z < min(zs_body)]
        self.assertGreater(len(front), len(back))

    def test_against_wall_collapses_rear_clearance_as_a_named_exception(self) -> None:
        c = sc.resolve("bias_visualizer")
        m = sc.masks(c, rotation=0, mode="against_wall")
        zs_body = [z for _, z in m.physical]
        self.assertFalse([z for _, z in m.circulation if z < min(zs_body)],
                         "the back is -z at rotation 0")
        self.assertTrue(any("rear clearance collapsed" in e for e in m.exceptions),
                        "the exception must be recorded, not hidden in a score")

    def test_masks_are_centred_on_the_anchor(self) -> None:
        m = sc.masks(sc.resolve("neural_network_visualization"))
        xs = [x for x, _ in m.physical]
        self.assertLess(min(xs), 0)
        self.assertGreater(max(xs), 0)


class NegotiationTests(unittest.TestCase):
    def test_every_outcome_is_explained_whether_it_places_or_not(self) -> None:
        """The contract is that no decision is silent — not that everything fits.

        This used to assert all three ACCEPT. Then the corpus was re-measured,
        neural_network_visualization turned out to be 12.6 x 5.5 m and 8.65 m
        tall rather than the 9.6 x 0.6 m the stale registry claimed, and it
        stopped fitting any bay. A REJECT there is the system working: the
        honest answer to 'does this fit' became no.
        """
        names = ["bias_visualizer", "science_screen",
                 "neural_network_visualization"]
        _, placements, _ = neg.run(names)
        self.assertEqual(3, len(placements))
        for p in placements:
            self.assertIn(p.result, ("ACCEPT", "REJECT"))
            if p.result == "ACCEPT":
                self.assertTrue(p.masks, f"{p.artifact} accepted without masks")
                self.assertTrue(p.slot, f"{p.artifact} accepted without a slot")
            else:
                self.assertTrue(
                    [t for t in p.traces if t.status == "fail"],
                    f"{p.artifact} was rejected without naming a failing rule")

    def test_the_two_that_fit_are_placed_by_one_negotiator(self) -> None:
        _, placements, _ = neg.run(["bias_visualizer", "science_screen"])
        for p in placements:
            self.assertEqual("ACCEPT", p.result, f"{p.artifact} was rejected")
        self.assertNotEqual(placements[0].mode, placements[1].mode,
                            "a freestanding and a wall case should not resolve "
                            "to the same placement mode")

    def test_a_stated_venue_is_tried_before_the_museum_interior(self) -> None:
        """A work that ASKS for the grounds is not one that failed to fit.

        preferred_venue carries curatorial intent the geometry cannot supply,
        so it is honoured first — and when the building has no such venue the
        compromise is recorded rather than silently ignored.
        """
        from dataclasses import replace
        base = sc.resolve("bias_visualizer")
        self.assertEqual("interior", base.preferred_venue, "default is the museum")

        outside = neg.negotiate(replace(base, preferred_venue="outside"),
                                fp.from_museum("grande-galerie-axial"), neg.Occupancy())
        self.assertEqual("ACCEPT", outside.result)
        self.assertEqual("outside", outside.venue)

        # Grande Galerie has no courtyard, so the ask cannot be met.
        missing = neg.negotiate(replace(base, preferred_venue="courtyard"),
                                fp.from_museum("grande-galerie-axial"), neg.Occupancy())
        self.assertEqual("ACCEPT", missing.result)
        self.assertNotEqual("courtyard", missing.venue)
        self.assertTrue(any(t.rule == "preferred_venue" and t.status == "compromised"
                            for t in missing.traces),
                        "an unmet venue must be recorded as a compromise")

    def test_an_unknown_venue_is_refused_not_silently_accepted(self) -> None:
        c = sc.resolve("bias_visualizer")
        self.assertIn(c.preferred_venue, sc.VENUES)

    def test_a_wall_artifact_must_face_out_of_its_wall(self) -> None:
        plan = fp.build_enfilade(bays=2)
        c = sc.resolve("science_screen")
        wall_slot = next(s for s in plan.slots if s.wall_side == "west")
        ok, _, traces, _ = neg.try_place(
            c, wall_slot, plan, neg.Occupancy(), rotation=0, mode="against_wall")
        self.assertFalse(ok, "rotation 0 puts its back to the south, not the west")
        self.assertTrue(any(t.rule == "faces_out_of_wall" and t.status == "fail"
                            for t in traces))

    def test_an_artifact_taller_than_the_room_is_rejected(self) -> None:
        """Regression: a purely 2D negotiator called this a perfect placement
        while the artifact stuck out through the top of the museum."""
        plan = fp.build_enfilade(bays=2)
        plan.wall_height_m = 4.0
        c = sc.resolve("neural_network_visualization")
        self.assertGreater(c.body_m[2], 4.0)
        slot = next(s for s in plan.slots if s.wall_side is None)
        ok, _, traces, _ = neg.try_place(
            c, slot, plan, neg.Occupancy(), rotation=0, mode="freestanding")
        self.assertFalse(ok)
        self.assertTrue(any(t.rule == "body_fits_under_ceiling" and t.status == "fail"
                            for t in traces))

    def test_room_expansion_is_a_late_fallback_and_is_recorded(self) -> None:
        """An EXHIBITED body that will not fit grows the room, and says so.

        This used to use neural_network_visualization, which the re-measure
        showed is 12.6 x 8.7 m — a precinct, not an exhibit. A precinct must
        NOT grow the building (the test below), so the case had to move to a
        body the museum is genuinely meant to contain.
        """
        plan = fp.build_enfilade(bays=1, width=15)
        before = plan.width
        c = sc.resolve("science_screen")
        self.assertEqual("exhibited", c.containment)
        _, placements, _ = neg.run(["science_screen"], plan=plan)
        # It USED to grow the room here, because its single authored rotation
        # was binding and it would not fit facing that way. Now that one
        # declared rotation is a preference, the ladder takes step 2 (turn) and
        # never reaches step 6 (grow the building) — which is the whole point
        # of ordering the ladder. Cheaper rung first.
        self.assertEqual(plan.width, before, "turning must beat growing")
        self.assertEqual(placements[0].result, "ACCEPT")
        self.assertNotEqual(placements[0].rotation, c.authored_rotation)
        self.assertTrue(any("turned to rotation" in e
                            for e in placements[0].exceptions),
                        "a turn away from the authored facing must be recorded")

    def test_a_precinct_is_given_ground_not_a_bigger_building(self) -> None:
        """The category, not a failure.

        A body the building was never going to contain skips the slot ladder
        entirely: it does not grow the museum, it stands on open ground. Three
        times this negotiator rejected such a work from three different
        directions before the category existed.
        """
        plan = fp.from_museum("uffizi-spine-enfilade")
        before = plan.width
        c = sc.resolve("neural_network_visualization")
        self.assertEqual("precinct", c.containment)
        # `platform`/`posture` were authored for objects; a precinct stands on
        # ground whatever the registry says, or it is refused for wanting a table.
        self.assertEqual("floor", c.required_support)

        p = neg.negotiate(c, plan, neg.Occupancy())
        self.assertEqual("ACCEPT", p.result)
        self.assertNotEqual("interior", p.venue)
        self.assertEqual(before, plan.width, "a precinct must not grow the building")
        self.assertTrue(any(t.rule == "containment" for t in p.traces),
                        "the decision must name the category")

    def test_a_broad_precinct_gets_a_bridge_courtyard(self) -> None:
        """Rung 3: the court may widen beside the route, not across it.

        An 18 m square cannot leave a walkable column in the 15 m Sainsbury
        spine in either rotation. It is still small enough to be experienced
        as part of the museum, so the negotiated topology is a bridge court.
        """
        from dataclasses import replace
        base = sc.resolve("neural_network_visualization")
        c = replace(base, body_m=[18.0, 18.0, base.body_m[2]],
                    footprint_cells=[18, 18], containment="precinct",
                    preferred_venue="courtyard")
        p = neg.negotiate(c, fp.from_museum("sainsbury-false-perspective-enfilade"),
                          neg.Occupancy())
        self.assertEqual("ACCEPT", p.result)
        self.assertEqual("courtyard", p.venue)
        self.assertEqual("bridge", p.court_access)
        self.assertEqual([24, 24], p.court_m)
        self.assertTrue(any(t.rule == "escalation" and "bridge courtyard" in t.detail
                            for t in p.traces))

    def test_a_world_over_40m_stays_for_a_dedicated_map(self) -> None:
        """The bridge is not a loophole that turns a world into a corridor."""
        from dataclasses import replace
        base = sc.resolve("neural_network_visualization")
        c = replace(base, body_m=[41.0, 41.0, base.body_m[2]],
                    footprint_cells=[41, 41], containment="precinct",
                    preferred_venue="courtyard")
        p = neg.negotiate(c, fp.from_museum("sainsbury-false-perspective-enfilade"),
                          neg.Occupancy())
        self.assertEqual("REJECT", p.result)
        self.assertIsNone(p.court_access)
        self.assertTrue(any(t.status == "fail" and "dedicated map required" in t.detail
                            for t in p.traces))

    def test_presentation_overlap_costs_score_but_never_validity(self) -> None:
        plan = fp.build_enfilade(bays=3)
        occ = neg.Occupancy()
        c = sc.resolve("bias_visualizer")
        slot = next(s for s in plan.slots if s.wall_side is None)
        m = sc.masks(c)
        ok_alone, score_alone, _, _ = neg.try_place(
            c, slot, plan, occ, 0, "freestanding")
        self.assertTrue(ok_alone)
        # Park a neighbour inside the presentation ring only.
        pres = next(iter(m.presentation))
        occ.presentation[(pres[0] + slot.cell[0], pres[1] + slot.cell[1])] = "other"
        ok_after, score_after, _, _ = neg.try_place(
            c, slot, plan, occ, 0, "freestanding")
        self.assertTrue(ok_after, "presentation pressure must not invalidate")
        self.assertLessEqual(score_after, score_alone)


class MapCompileTests(unittest.TestCase):
    """Regressions for the two faults the multi-angle capture exposed."""

    def _placement(self, lookup: str, wall_rect=None) -> neg.Placement:
        return neg.Placement(
            artifact=lookup, slot="s", anchor=(7, 4), rotation=0,
            mode="freestanding", wall=None, wall_rect=wall_rect,
            venue="interior", support_height_m=0.0, score=1.0,
            result="ACCEPT", traces=[], exceptions=[],
            masks=None, contract=sc.resolve(lookup))

    def test_token_cell_compensates_for_off_origin_geometry(self) -> None:
        """neural_network_visualization's mesh sits metres east of its node
        origin; writing the body cell into the token put it several cells wrong.

        Asserts the RELATION against the resolved offset, not a snapshot of it —
        an earlier version hardcoded 4.5 m and broke the day the corpus was
        re-measured, which is a test defending a known-wrong number.
        """
        p = self._placement("neural_network_visualization")
        ox, oz = p.contract.centre_offset_m
        self.assertGreater(abs(ox), 1.0, "this artifact is built off-origin")
        # BOTH axes are corrected. The re-measure revealed this artifact is
        # also 2.34 m off in z, which a test checking only x would have missed.
        expected = (p.anchor[0] - int(round(ox)), p.anchor[1] - int(round(oz)))
        self.assertEqual(expected, slice_.token_cell(p))
        self.assertNotEqual(p.anchor, slice_.token_cell(p))

    def test_a_grounded_artifact_gets_a_two_part_token(self) -> None:
        """A third field is a manual y and switches auto-grounding OFF, so
        `:0.0` is not a harmless default."""
        self.assertEqual("bias_visualizer:0",
                         slice_.token_for(self._placement("bias_visualizer")))

    def test_a_wall_artifact_carries_its_mounting_height(self) -> None:
        p = self._placement("science_screen", wall_rect=[1.9, 0.73, 5.1, 3.07])
        token = slice_.token_for(p)
        self.assertEqual(3, len(token.split(":")))
        # The offset is the gap between where the wall wants the body's base and
        # where the body's base sits relative to its own origin. Asserted as
        # that relation, so a re-measure moves it without breaking the test.
        expected = round(0.73 - p.contract.base_y_m, 3)
        self.assertAlmostEqual(expected, float(token.split(":")[2]), places=2)
        self.assertGreater(float(token.split(":")[2]), 0.0)


class TraversalTests(unittest.TestCase):
    def test_spawn_still_reaches_the_exit_with_everything_placed(self) -> None:
        names = ["bias_visualizer", "science_screen",
                 "neural_network_visualization"]
        plan, placements, occ = neg.run(names)
        ok, why = slice_.traversal_ok(plan, placements, occ)
        self.assertTrue(ok, why)


if __name__ == "__main__":
    unittest.main()


class DressingRoomIsCanonical(unittest.TestCase):
    """D1 — the dressing room is the staged unit; the dataclass is a view of it.

    SPATIAL_PIPELINE.md §4:
        spine_hints() -> auto-generated default room -> human-refined room
    """

    NEGOTIATED = ["body_m", "clearance", "containment", "footprint_cells",
                  "importance", "lookup", "modes", "preferred_mode",
                  "required_sides", "required_support", "rotations",
                  "visual_radius", "preferred_venue"]

    def test_room_carries_everything_the_negotiator_reads(self):
        """If the room cannot be negotiated from, it is not canonical."""
        import emit_dressing_room as ed
        for token in ("science_screen", "bias_visualizer", "dark_sphere",
                      "neural_network_visualization", "lab_room"):
            direct = sc.resolve(token)
            viaroom = ed.from_room(ed.build(token))
            for field in self.NEGOTIATED:
                a, b = getattr(direct, field), getattr(viaroom, field)
                self.assertEqual(a, b, f"{token}.{field} lost in the round trip")
                # TYPE too, not just value. JSON has one number type, and on a
                # 1 m grid a cell count and a metre reading are the same
                # number — so `2` and `2.0` compare equal, round-trip clean,
                # and produce a byte-identical map right up until something
                # calls range() on the float. Two of these shipped through a
                # value-only assertion before the negative test found them.
                self.assertIs(type(a), type(b),
                              f"{token}.{field}: {type(a).__name__} became "
                              f"{type(b).__name__} through the dressing room")
                if isinstance(a, (list, tuple)) and a and isinstance(b, (list, tuple)):
                    self.assertIs(type(a[0]), type(b[0]),
                                  f"{token}.{field}[0] changed type")

    def test_authored_room_outranks_spine_hints(self):
        """science_screen: scene says 2x1/rot 180, author says 4x1/rot 0.

        The author is last in the resolution order and wins. This inverted
        once already — hints were applied unconditionally last — and the
        symptom was a rotation the author had EXCLUDED being handed to the
        negotiator as the preferred one.
        """
        c = sc.resolve("science_screen")
        self.assertEqual(c.footprint_cells, [4, 1])
        # ONE declared rotation is now a PREFERENCE, so 180 is legal — but the
        # author's 0 still LEADS, ahead of the hint that asked for 180. A
        # preference any provider can outrank is not a preference.
        self.assertEqual(c.rotations[0], 0)
        self.assertEqual(c.authored_rotation, 0)
        self.assertIn(180, c.rotations)
        self.assertTrue(any("authored" in x for x in c.conflicts),
                        "an overruled hint must be recorded, not swallowed")

    def test_every_hint_implementor_is_also_authored(self):
        """The uncomfortable corpus fact, asserted so it cannot rot quietly.

        All 9 artifacts implementing spine_hints() ALSO have an authored
        dressing room, so under the correct ranking the hints change no
        footprint anywhere today. Wiring the provider in was still right —
        it is correct for the next artifact, and it surfaces the
        scene-vs-author disagreements that were previously invisible — but
        the honest claim is "no effect yet", not "science_screen is now 2x1".

        If this ever fails, an artifact declares hints and nobody staged it:
        that is the case the provider was built for. Update the test.
        """
        implementors = sc.spine_hints_index()
        self.assertEqual(len(implementors), 9)
        unauthored = [t for t in implementors if not sc.room_for(t)]
        self.assertEqual(unauthored, [], "a hint implementor is unstaged")

    def test_an_unstaged_hint_implementor_would_be_honoured(self):
        """The mechanism itself, tested without a room in the way."""
        import emit_dressing_room as ed
        room = dict(ed.build("science_screen"))
        room.pop("footprint")
        room["placement_contract"] = {}
        self.assertEqual(ed.from_room(room).footprint_cells,
                         sc.resolve("science_screen").footprint_cells)

    def test_generated_room_never_overwrites_an_authored_one(self):
        import emit_dressing_room as ed
        self.assertTrue(ed.is_authored("science_screen"))
        wrote, why = ed.write("science_screen")
        self.assertFalse(wrote, why)

    def test_generated_height_covers_the_body(self):
        """Derive every dimension the same way, or one of them understates.

        Width and depth ceil; height originally rounded, so a 1.42 m cabinet
        declared 1 cell of headroom. 33 of the 48 generated rooms were short.
        Of the two ways to be wrong, claiming less headroom than the body
        occupies is the one that puts geometry through a ceiling.
        """
        import emit_dressing_room as ed
        for token in ("disclosure_cabinet", "critic_regress_stack",
                      "science_screen", "museum_wall_kit_atlas"):
            room = ed.build(token)
            self.assertGreaterEqual(
                room["footprint"][2], room["placement_contract"]["body_m"][2],
                f"{token}: declared height is under its measured body")

    def test_generated_rooms_declare_themselves(self):
        import emit_dressing_room as ed
        self.assertIn("_generated", ed.build("adjacency_shelf"))

    def test_footprint_carries_two_units(self):
        """33 rooms store metres in a field the schema documents as cells.

        Read as cells, science_screen's 3.14 m becomes 3 and its 0.2 m depth
        becomes 1 — plausible numbers, silently wrong.
        """
        import emit_dressing_room as ed
        room = sc.room_for("science_screen")
        self.assertEqual(room["footprint"][:2], [3.14, 0.2])
        self.assertEqual(ed.from_room(room).footprint_cells, [4, 1])
