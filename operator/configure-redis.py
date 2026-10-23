"""Append an explicit recovery policy without replacing existing recovery policies.

Run locally with kubectl configured. Writes config only; never reads credential Secrets.
"""
import json
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parent
import argparse
parser=argparse.ArgumentParser()
parser.add_argument('--policy',default='redis-policy-ncs.json')
args=parser.parse_args()
policy = json.loads((root / args.policy).read_text())
obj = json.loads(subprocess.check_output(['kubectl','-n','apps','get','configmap','tessera-operator','-o','json']))
config = json.loads(obj.get('data',{}).get('recovery.json','{"namespace":"apps","policies":[]}'))
if config.get('namespace') != 'apps' or not isinstance(config.get('policies'),list):
    raise SystemExit('Unexpected existing recovery configuration; unchanged')
existing = [p for p in config['policies'] if p.get('name') == policy['name']]
if existing and existing != [policy]:
    raise SystemExit('A different policy already exists; unchanged')
if not existing:
    config['policies'].append(policy)
from recovery import validate
validate(config)
# JSON Patch tests resourceVersion before replacing only recovery.json; no ledger access.
patch = [{'op':'test','path':'/metadata/resourceVersion','value':obj['metadata']['resourceVersion']},
         {'op':'add','path':'/data/recovery.json','value':json.dumps(config,indent=2)}]
subprocess.run(['kubectl','-n','apps','patch','configmap','tessera-operator','--type=json','-p',json.dumps(patch)],check=True)
print('Recovery policy configured; existing policies retained. Restart deployment after probe validation.')
