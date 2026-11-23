"""Compare a fetched Navis OpenAPI against actual packaged TESSERA routes/requests."""
from pathlib import Path
import argparse,base64,json,re,subprocess,tempfile,xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--openapi',type=Path,required=True);p.add_argument('--package',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    api=json.loads(a.openapi.read_text(encoding='utf-8-sig'));baseline=json.loads((ROOT/'docs/reference/navis/openapi.json').read_text())
    current=json.loads(json.dumps(api));prior=json.loads(json.dumps(baseline));current['info'].pop('version');prior['info'].pop('version')
    assert current==prior,'Navis contract changed beyond version metadata; review before acceptance'
    root=ET.parse(a.package).getroot();payload={n.get('Location'):base64.b64decode(n.text) for n in root.findall('./Filelist/File')}
    with tempfile.TemporaryDirectory() as temp:
        stage=Path(temp)
        for n in ['Kernel/System/TESSERA/IntegrationOnboarding.pm','Kernel/System/TESSERA/IntegrationAuth.pm','Kernel/System/TESSERA/NavisPlan.pm']:
            target=stage/n;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(payload[n])
        perl="""use JSON::PP;use Kernel::System::TESSERA::IntegrationOnboarding;use Kernel::System::TESSERA::NavisPlan;
my $P=Kernel::System::TESSERA::NavisPlan->new();my %A=(OnDemand=>1,Namespace=>'network-a',CallerID=>'tessera-'.('a'x40),Flow=>{source=>'192.0.2.10',destination=>'198.51.100.5',protocol=>'tcp',destination_port=>443,action=>'allow'});
print JSON::PP->new->canonical->encode({routes=>Kernel::System::TESSERA::IntegrationOnboarding::NavisRoutes(),requests=>[$P->Request(%A),$P->Request(%A,TopologyName=>'application 1')]});"""
        out=subprocess.run(['perl','-I'+str(stage),'-e',perl],capture_output=True,text=True,check=True);actual=json.loads(out.stdout)
    checked=[]
    for name,route in actual['routes'].items():
        path=re.sub(r':([A-Za-z]+)',lambda m:'{'+{'Name':'name','BuildID':'build_id','CollectionRunID':'collection_run_id','IngestionID':'ingestion_id','CallerSessionID':'caller_session_id'}[m[1]]+'}',route['Path'])
        op=api['paths'][path][route['Method'].lower()]
        status=str(route.get('SuccessStatus',200));assert status in op['responses'],(name,status,list(op['responses']))
        qs={n['name'] for n in op.get('parameters',[]) if n['in']=='query'};assert set(route.get('QueryParameters',[]))<=qs,(name,qs)
        checked.append({'name':name,'path':path,'success_status':int(status)})
    schema=api['components']['schemas']['TraceRequest']
    for req in actual['requests']:
        assert set(req)<=set(schema['properties']);assert set(schema['required'])<=set(req)
        assert 'graph_build_id' not in req and 'topology_version_id' not in req
        assert type(req['destination_port']) is int
    assert 'topology_name' not in actual['requests'][0];assert actual['requests'][1]['topology_name']=='application 1'
    result={'package_version':root.findtext('Version'),'navis_commit':'ed4ba3e312bd24b0afabc2a2b2949e0aaa9c75a8','navis_version':api['info']['version'],'api_paths':len(api['paths']),'only_openapi_change':'info.version','route_checks':checked,'request_checks':2,'customer_graph_id_required':False,'live_acceptance':False}
    a.output.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({'routes':len(checked),'requests':2,'passed':True}))
if __name__=='__main__':main()
