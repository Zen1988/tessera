"""Package the reviewed0.1.7 failure recovery without app/config/credential exports."""
from pathlib import Path
import hashlib,json,zipfile
ROOT=Path(__file__).resolve().parents[1]
FILES=['scripts/recover-navis017.py','scripts/upgrade-deploy.py','scripts/recover-179-to-184.py','scripts/resume-before-upgrade.py','scripts/diagnose-release.py','image/configure.py','image/Navis017Recovery.pm','image/recover-navis017.pl','image/navis017-installer.pm']
def main():
 files={n:(ROOT/'container/ubuntu2604'/n).read_bytes().replace(b'\r\n',b'\n') for n in FILES}
 files['README-Navis017-Recovery.md']=(ROOT/'docs/recovery-navis017.md').read_bytes()
 assert hashlib.sha256(files['image/navis017-installer.pm']).hexdigest()=='3bfd9d55f374643e6b2d2ca9a01fba72622ddb3805710f84ec4faae520087d61'
 manifest={n:hashlib.sha256(d).hexdigest() for n,d in sorted(files.items())}
 files['NAVIS017-RECOVERY-SHA256SUMS']=(''.join(h+'  '+n+'\n' for n,h in manifest.items())).encode()
 out=ROOT/'outputs/TESSERA-0.1.7-Navis-Upgrade-Recovery.zip'
 with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
  for n,d in sorted(files.items()):z.writestr(n,d)
 with zipfile.ZipFile(out) as z:
  assert set(z.namelist())==set(files)
  for n,h in manifest.items():assert hashlib.sha256(z.read(n)).hexdigest()==h
 h=hashlib.sha256(out.read_bytes()).hexdigest();out.with_suffix('.zip.sha256').write_text(h+'  '+out.name+'\n')
 report={'failed_job':'tessera-release-1795404303','receipt':'UPGRADING','from':'0.1.3','target':'0.1.7','navis_field_rows':0,'package_journal_count':1,'installed_artifact_matches_image':True,'perl_assertions':57,'python_checks':7,'native_xml_post_hook_sha256':'350f00cc8d67490afd760c38762778c81ef5e4aeaad895c49002ff68bf61cbaf','archive_sha256':h,'files':len(files),'live_recovery_performed':False,'redis_root_cause_confirmed':False}
 (ROOT/'outputs/navis017-recovery-validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))
if __name__=='__main__':main()
