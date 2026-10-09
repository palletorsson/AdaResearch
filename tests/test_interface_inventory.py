"""Regression checks for evidence boundaries; these are not VR usability tests."""
import importlib.util
from contextlib import redirect_stderr, redirect_stdout
import io
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('inventory', Path(__file__).resolve().parents[1] / 'tools/interface_inventory.py')
inv = importlib.util.module_from_spec(spec)
spec.loader.exec_module(inv)


class InventoryTests(unittest.TestCase):
    def test_comments_strings_and_input_do_not_become_buttons(self):
        rows, _, _ = inv.gd_evidence('''# Button.new()\nvar poem = "Button.new() # add_slider()"\nif Input.is_action_pressed("button"):\n    pass\n''')
        self.assertEqual([r['kind'] for r in rows], ['input_poll'])

    def test_factory_definition_is_not_a_call(self):
        rows, _, _ = inv.gd_evidence('''func add_button(label):\n    pass\nvar b = panel.add_button("GO")\n''')
        self.assertEqual([r['kind'] for r in rows], ['factory_definition', 'factory_call_candidate'])

    def test_multiple_native_constructors_on_one_line(self):
        rows, _, _ = inv.gd_evidence('var a = HSlider.new(); var b = Button.new()')
        self.assertEqual([r['family'] for r in rows], ['slider', 'button'])

    def test_text_labels_are_not_certified_screens(self):
        rows, _, _ = inv.gd_evidence('var l = Label3D.new()')
        self.assertEqual(rows[0]['family'], 'text_surface')

    def test_configuration_and_signals_separate(self):
        rows, _, _ = inv.gd_evidence('''var row = {"type": "slider_h"}\ncontrol.value_changed.connect(_changed)\n''')
        self.assertEqual({r['kind'] for r in rows}, {'signal_connection', 'config_widget_candidate'})

    def test_scene_attributes_order_and_passive_name(self):
        rows, _ = inv.scene_evidence('''[gd_scene format=3]\n[node parent="." type="Button" name="Go"]\n[node name="ButtonBacking" type="MeshInstance3D" parent="."]\n''')
        self.assertEqual([r['kind'] for r in rows], ['scene_node', 'node_name_hint_only'])

    def test_multiline_embedded_script_does_not_parse_fake_nodes(self):
        text = '''[gd_scene format=3]\n[sub_resource type="GDScript" id="Script_1"]\nscript/source = "extends Node3D\n# [node name=\\"Fake\\" type=\\"Button\\"]\nfunc _ready():\n    var x = Button.new()\n"\n[node name="Root" type="Node3D"]\n'''
        rows, scripts = inv.scene_evidence(text)
        self.assertEqual(rows, [])
        self.assertEqual(len(scripts), 1)
        self.assertEqual(inv.gd_evidence(scripts[0][2])[0][0]['kind'], 'native_constructor')

    def test_graph_has_no_shallow_depth_limit_and_handles_cycle(self):
        graph = {'a': {'b'}, 'b': {'c'}, 'c': {'d'}, 'd': {'a'}}
        self.assertEqual(inv.descendants('a', graph), {'a', 'b', 'c', 'd'})

    def test_repeated_dependency_is_one_source_not_two_live_controls(self):
        graph = {'a': {'b', 'c'}, 'b': {'slider'}, 'c': {'slider'}}
        self.assertEqual(len(inv.descendants('a', graph)), 4)

    def test_configured_tokens(self):
        self.assertEqual(inv.token_key('slider#offset:0,1,0'), 'slider')
        self.assertEqual(inv.token_key('slider:90:1#foo:bar'), 'slider')

    def test_uid_and_relative_reference(self):
        self.assertEqual(inv.resolve_ref('uid://a', 'x.gd', set(), {'uid://a': 'x.gd'}), 'x.gd')
        self.assertEqual(inv.resolve_ref('../b.gd', 'dir/a.gd', {'b.gd'}, {}), 'b.gd')

    def test_native_subclasses_and_custom_named_definitions(self):
        rows, _, _ = inv.gd_evidence('extends Label3D\nclass_name WristReadout\n')
        self.assertEqual([r['kind'] for r in rows], ['native_base_definition', 'named_class_definition_candidate'])

    def test_configured_widget_recipes(self):
        rows = inv.config_evidence('{"type": "slider_h", "description": "a button", "widget": "screen"}')
        self.assertEqual([r['family'] for r in rows], ['slider', 'display_candidate'])

    def test_baked_text_rendering(self):
        rows, _, _ = inv.gd_evidence('canvas.draw_string(font, position, text)')
        self.assertEqual(rows[0]['kind'], 'text_drawing_candidate')

    def test_census_links_artifact_to_configured_map_without_counting_unmatched_files(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            fixtures = {
                'commons/a.gd': 'extends Node3D\nfunc _ready():\n    var b = Button.new()\n',
                'commons/empty.gd': 'extends Node3D\n',
                'commons/a.tscn': '[gd_scene format=3]\n[ext_resource type="Script" path="res://commons/a.gd" id="a"]\n[node name="Root" type="Node3D"]\nscript = ExtResource("a")\n',
                'commons/artifacts/registry/a.json': json.dumps({'artifacts': {'sample': {'scene': 'res://commons/a.tscn'}}}),
                'commons/maps/curriculum_spine.json': json.dumps({'spine': {'sequences': [{'name': 'sample'}]}}),
                'commons/maps/sequences/sample.json': json.dumps({'sequences': {'sample': {'maps': ['Hall']}}}),
                'commons/maps/Hall/map_data.json': json.dumps({'layers': {'interactables': [['sample#offset:0,1,0']]}}),
            }
            for name, content in fixtures.items():
                p = root / name
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_text(content, encoding='utf-8')
            with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
                inv.run(root, root / 'report')
            def read(name):
                return json.loads((root / 'report' / (name + '.json')).read_text())
            self.assertEqual(read('summary')['evidence_files'], 1)
            self.assertEqual(read('summary')['errors'], [])
            self.assertEqual(read('artifacts')[0]['families'], ['button'])
            self.assertEqual(read('map-placements')[0]['key'], 'sample')
            self.assertTrue(read('map-placements')[0]['in_spine'])


if __name__ == '__main__':
    unittest.main()
