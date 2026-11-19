"""Failure-injection tests: a bad/interrupted export must preserve the live edition."""
import json
import os
from pathlib import Path
import struct
import tempfile
import unittest
from unittest.mock import patch

from void_model_publication import publish_models, editor_directory


class PublicationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.stage = self.root/'stage'; self.stage.mkdir()
        self.public = self.root/'public'; self.public.mkdir()

    def export(self, body=b'old!'):
        (self.stage/'piece.glb').write_bytes(struct.pack('<4sII',b'glTF',2,12+len(body))+body)
        return {'floors':{'152':{'artifacts':{'piece':{'model':{'url':'/void-models/piece.glb'}}}}}}

    def test_versions_preserve_previous_geometry_and_other_floors(self):
        initial=self.export()
        initial['floors']['155']={'artifacts':{}}
        first=publish_models(self.stage,initial,self.public)
        first_url=first['floors']['152']['artifacts']['piece']['model']['url']
        second=publish_models(self.stage,self.export(b'new!'),self.public)
        second_url=second['floors']['152']['artifacts']['piece']['model']['url']
        self.assertNotEqual(first_url,second_url)
        self.assertEqual((self.public/Path(first_url).name).read_bytes()[-4:],b'old!')
        self.assertEqual((self.public/Path(second_url).name).read_bytes()[-4:],b'new!')
        self.assertEqual(json.loads((self.public/'manifest.previous.json').read_text()),first)
        self.assertIn('155',second['floors'])

    def test_invalid_or_missing_asset_cannot_replace_manifest(self):
        publish_models(self.stage,self.export(),self.public)
        before=(self.public/'manifest.json').read_bytes()
        record=self.export()
        (self.stage/'piece.glb').write_bytes(b'broken')
        with self.assertRaises(ValueError): publish_models(self.stage,record,self.public)
        self.assertEqual((self.public/'manifest.json').read_bytes(),before)
        (self.stage/'piece.glb').unlink()
        with self.assertRaises(ValueError): publish_models(self.stage,record,self.public)
        self.assertEqual((self.public/'manifest.json').read_bytes(),before)

    def test_interrupted_manifest_commit_preserves_live_export(self):
        publish_models(self.stage,self.export(),self.public)
        before=(self.public/'manifest.json').read_bytes()
        replace=os.replace
        def fail_commit(source,destination):
            if Path(destination)==self.public/'manifest.json': raise OSError('simulated interrupted commit')
            replace(source,destination)
        with patch('void_model_publication.os.replace',side_effect=fail_commit):
            with self.assertRaises(OSError): publish_models(self.stage,self.export(b'new!'),self.public)
        self.assertEqual((self.public/'manifest.json').read_bytes(),before)
        self.assertEqual((self.public/'manifest.previous.json').read_bytes(),before)

    def test_wrong_editor_mount_fails_without_touching_it(self):
        mount=self.root/'web/public/void-models';mount.mkdir(parents=True)
        proof=mount/'keep.txt';proof.write_text('preserve')
        with patch.dict(os.environ,{'ADA_ENCYCLOPEDIA_ROOT':str(self.root/'web'),'ADA_GENERATED_ROOT':str(self.root/'generated')}):
            with self.assertRaises(RuntimeError): editor_directory()
        self.assertEqual(proof.read_text(),'preserve')


if __name__=='__main__': unittest.main()
