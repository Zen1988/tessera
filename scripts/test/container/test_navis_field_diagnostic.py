import importlib.util
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[3]
spec=importlib.util.spec_from_file_location('navis_diag',ROOT/'container/ubuntu2604/scripts/diagnose-navis-field.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class DiagnosticTest(unittest.TestCase):
 def test_direct_metadata_is_read_only_and_bounded(self):
  code=m.FIELD_METADATA
  self.assertIn('SELECT id, name, field_type, object_type, valid_id, config FROM dynamic_field',code)
  self.assertNotRegex(code,r'(?i)\b(?:INSERT|UPDATE|DELETE|ALTER|DROP)\b')
  self.assertNotIn('print $Config',code);self.assertNotIn('DynamicFieldGet',code)
  self.assertIn('navis_field_rows=',code);self.assertIn('navis_field_multivalue=',code)
 def test_program_retains_read_only_plan_and_stage(self):
  d=m.load_diagnostic();program=d.diagnostic_program(True)
  self.assertIn('navis_field_rows=',program);self.assertIn('ReconcilePackages($Inventory,$DB,$Package',program)
  self.assertIn('package_journal_count=',program)
 def test_only_failed_job_can_be_cloned(self):
  d=m.load_diagnostic()
  with self.assertRaises(ValueError):d.diagnostic_job({'status':{}},'tessera','test',True)
if __name__=='__main__':unittest.main()
