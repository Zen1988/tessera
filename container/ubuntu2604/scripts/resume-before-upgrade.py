#!/usr/bin/env python3
"""Continue only a stopped deployment checkpoint whose native Job is absent."""
import argparse
import copy
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import time
import uuid

HERE=Path(__file__).resolve().parent

def load_module(name,path):
 spec=importlib.util.spec_from_file_location(name,path);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module

helper=load_module('resume_release_helper',HERE/'upgrade-deploy.py')
common=load_module('resume_target_check',HERE/'recover-179-to-184.py')

def active_runners(state):
 """Require the old local helper to stop; do not kill it or steal a live run."""
 if os.name!='posix':return []
 if not Path('/proc').is_dir():raise ValueError('Cannot verify old local helper is stopped')
 found=[]
 for process in Path('/proc').glob('[0-9]*'):
  try:
   args=[part.decode() for part in (process/'cmdline').read_bytes().split(b'\0') if part]
   if not any(Path(part).name=='upgrade-deploy.py' for part in args) or '--state-directory' not in args:continue
   target=Path(args[args.index('--state-directory')+1])
   if not target.is_absolute():target=(process/'cwd').resolve()/target
   if target.resolve()==state:found.append(process.name)
  except (FileNotFoundError,PermissionError,UnicodeError,IndexError):continue
 return found

def validate_manifest(saved):
 pod=saved['spec']['template']['spec'];containers=pod.get('containers',[])
 if len(containers)!=1 or containers[0].get('args')!=['upgrade'] or containers[0].get('command'):
  raise ValueError('Expected original controlled upgrade command')
 if [c['name'] for c in pod.get('initContainers',[])]!=['stage-upgrade']:raise ValueError('Missing isolated staging')
 if saved['spec'].get('backoffLimit')!=0:raise ValueError('Expected no native retries')
 main=containers[0]
 if not any(e.get('name')=='TESSERA_UPGRADE_QUIESCED' and e.get('value')=='1' for e in main.get('env',[])):raise ValueError('Quiescence contract missing')
 if not any(m.get('name')=='tessera-upgrade-bundle' and m.get('mountPath')=='/opt/tessera/upgrade-bundle' and m.get('readOnly') for m in main.get('volumeMounts',[])):raise ValueError('Read-only bundle missing')
 matches=[v['persistentVolumeClaim']['claimName'] for v in pod.get('volumes',[]) if v['name']=='tessera-upgrade-bundle']
 if len(matches)!=1:raise ValueError('Ambiguous bundle PVC')
 return main,matches[0]

def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--state-directory',required=True);args=parser.parse_args()
 state=Path(args.state_directory).resolve()
 runners=active_runners(state)
 if runners:raise ValueError('Original upgrade helper still running; stop it with Ctrl-C first (PID '+','.join(runners)+')')
 def load(name):return json.loads((state/name).read_text())
 saved=load('upgrade-job.json');original_claim=load('maintenance-lock.json');main_container,pvc=validate_manifest(saved)
 namespace=saved['metadata']['namespace'];name=saved['metadata']['name'];prefix=['kubectl','-n',namespace]
 def get(*parts):return json.loads(subprocess.check_output(prefix+['get',*parts,'-o','json'],text=True))
 def run(*parts):subprocess.run(prefix+list(parts),check=True)
 def write(verb,obj,dry=False):subprocess.run(prefix+[verb]+(['--dry-run=server'] if dry else [])+['-f','-'],input=json.dumps(obj),text=True,check=True)
 def absent_job():
  raw=subprocess.check_output(prefix+['get','job',name,'--ignore-not-found','-o','json'],text=True)
  if raw.strip():raise ValueError('Native upgrade Job already exists; no automatic replay/resume allowed')
 absent_job()
 lock=get('configmap',helper.LOCK_NAME)
 if lock.get('metadata',{}).get('labels',{}).get('app.kubernetes.io/managed-by')!='tessera-release-helper' or lock.get('data')!=original_claim.get('data') or lock['data'].get('phase')!='LOCKED':raise ValueError('Saved maintenance ownership no longer matches')
 for job in get('jobs')['items']:
  if job['spec']['template']['metadata'].get('labels',{}).get('tessera-release-upgrade') and not (common.terminal(job,'Complete') or common.terminal(job,'Failed')):raise ValueError('Another release/diagnostic Job is active')
 workloads=[]
 for filename in ('web-before.json','daemon-before.json'):
  before=load(filename);current=get('deployment',before['metadata']['name']);common.same_target(current,before)
  if current['spec']['template']['spec']['containers'][0]['image']!=before['spec']['template']['spec']['containers'][0]['image']:raise ValueError('Workload image changed since checkpoint')
  if current['spec'].get('replicas',1) not in (0,before['spec'].get('replicas',1)):raise ValueError('Workload replica intent changed')
  workloads.append(before)
 names={d['metadata']['name'] for d in workloads}
 if any(h['spec']['scaleTargetRef']['name'] in names for h in get('hpa')['items']):raise ValueError('Resolve HPA ownership first')
 bundle=get('pvc',pvc);labels=bundle['metadata'].get('labels',{})
 if labels.get('app.kubernetes.io/managed-by')!='tessera-release-helper' or labels.get('tessera-upgrade-bundle')!='true':raise ValueError('Requires dedicated helper-managed bundle PVC')
 uid=bundle['metadata']['uid']
 out=state/'resume-before-upgrade';out.mkdir(mode=0o700,exist_ok=False)
 def save(filename,value):
  with (out/filename).open('x',encoding='utf-8') as stream:
   os.chmod(stream.name,0o600);json.dump(value,stream,indent=2)
 save('upgrade-job.json',saved);save('original-bundle-pvc.json',bundle)
 write('create',saved,dry=True)
 lock['data']['owner']=uuid.uuid4().hex;save('maintenance-lock.json',lock);write('replace',lock)
 print('Continuation state:',out,'\nNative Job:',name,flush=True)
 for d in workloads:
  print('Will restore',d['metadata']['name'],'replicas:',d['spec'].get('replicas',1),flush=True)
  run('scale','deployment/'+d['metadata']['name'],'--replicas=0')
 for d in workloads:
  def writers():return helper.workload_pods(get('pods','-l',helper.selector(d))['items'])
  pods=writers()
  if pods:run('wait','--for=delete',*['pod/'+p['metadata']['name'] for p in pods],'--timeout=600s')
  if writers():raise ValueError('Writers remain; native Job not started')
 current=get('configmap',helper.LOCK_NAME)
 if current['data']!=lock['data']:raise ValueError('Maintenance owner changed before native Job')
 absent_job();write('create',saved)
 deadline=time.monotonic()+1860
 while time.monotonic()<deadline:
  status=get('job',name)
  if common.terminal(status,'Failed'):
   subprocess.run(prefix+['logs','job/'+name,'-c',main_container['name'],'--tail=100'],check=False)
   raise ValueError('Native Job failed; preserve all claims and evidence')
  if common.terminal(status,'Complete'):break
  time.sleep(5)
 else:raise ValueError('Native Job not complete; inspect it before any retry')
 for d in workloads:
  target='deployment/'+d['metadata']['name'];container=d['spec']['template']['spec']['containers'][0]['name']
  run('set','image',target,container+'='+main_container['image'])
  run('scale',target,'--replicas='+str(d['spec'].get('replicas',1)))
  run('rollout','status',target,'--timeout=600s')
 current=get('configmap',helper.LOCK_NAME)
 if current['data']!=lock['data']:raise ValueError('Maintenance owner changed before completion')
 helper.cleanup_bundle(prefix,out,name,main_container['name'],pvc,uid)
 current=get('configmap',helper.LOCK_NAME)
 ready=helper.maintenance_lock(current,namespace,lock['data']['owner'],'READY');save('maintenance-ready.json',ready);write('replace',ready)
 print('Upgrade and saved replica restoration complete. State:',out)

if __name__=='__main__':
 try:main()
 except ValueError as error:raise SystemExit('Continuation stopped: '+str(error)+'. Preserve state/claims; do not blindly retry.') from None
 except (Exception,KeyboardInterrupt):raise SystemExit('Continuation stopped. Preserve Job, PVC and private state; inspect before retry.') from None
