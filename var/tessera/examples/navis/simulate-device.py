"""Offline executor fixture: consumes a TESSERA intent; has no network client."""
import json
import sys


def simulate(plan):
    platform, context, draft = plan['Platform'], plan['Context'], plan['Draft']
    fields = {'panos': ('vsys', 'source_zone', 'destination_zone'),
              'aci': ('tenant', 'source_epg', 'destination_epg', 'contract'),
              'nsx': ('domain', 'source_group', 'destination_group', 'applied_to', 'policy')}[platform]
    missing = [key for key in fields if not isinstance(context.get(key), str) or not context[key].strip()]
    if platform == 'panos':
        for key in ('source_zone', 'destination_zone'):
            if draft.get(key) != context.get(key) or draft.get(key + '_status') != 'resolved':
                missing.append(key + '_resolution')
    if draft.get('protocol') in ('tcp', 'udp') and draft.get('destination_port') is None:
        missing.append('destination_port')
    return {'PlanID': plan['PlanID'], 'Target': plan['Target'], 'Platform': platform,
            'Status': 'ENRICHMENT_REQUIRED' if missing else 'SIMULATED',
            'Changed': False, 'Verified': False, 'Missing': missing,
            'RuleReference': None if missing else 'simulation-' + plan['PlanID'][:16],
            'Operation': {'panos': 'security_rule', 'aci': 'contract_filter', 'nsx': 'dfw_rule'}[platform]}


if __name__ == '__main__':
    try:
        raw = sys.stdin.buffer.read(1048577)
        if len(raw) > 1048576:
            raise ValueError('budget')
        print(json.dumps(simulate(json.loads(raw))))
    except Exception:
        print(json.dumps({'Status': 'FAILED', 'Simulation': True}))
        sys.exit(1)
