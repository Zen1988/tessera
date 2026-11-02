import copy
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location('loader_cache_patch', ROOT / 'container/ubuntu2604/scripts/loader-cache-patch.py')
patcher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(patcher)


def deployment():
    return {'kind': 'Deployment', 'metadata': {'name': 'tessera-web', 'namespace': 'tessera'},
            'spec': {'replicas': 3, 'template': {'spec': {
                'securityContext': {'runAsUser': 10001, 'runAsGroup': 33, 'fsGroup': 10001},
                'containers': [{'name': 'actual-web-name', 'image': 'registry/tessera@sha256:fixture',
                                'imagePullPolicy': 'IfNotPresent', 'args': ['web'],
                                'env': [{'name': 'PRIVATE_FIXTURE', 'value': 'do-not-copy-this-fixture'}],
                                'readinessProbe': {'tcpSocket': {'port': 8443}},
                                'volumeMounts': [{'name': 'old-cache', 'mountPath': patcher.HOME + '/js/js-cache'},
                                                 {'name': 'config', 'mountPath': '/opt/otobo/Kernel/Config.pm'}]}],
                'volumes': [{'name': 'old-cache', 'emptyDir': {}},
                            {'name': 'config', 'secret': {'secretName': 'existing-config'}}]}}}}


class LoaderCachePatchTest(unittest.TestCase):
    def test_shared_paths_preserve_existing_configuration(self):
        source = deployment()
        original = copy.deepcopy(source)
        result = patcher.generate(source)
        pod = result['spec']['template']['spec']
        self.assertEqual(source, original)
        self.assertNotIn('replicas', result['spec'])
        self.assertNotIn('do-not-copy-this-fixture', json.dumps(result))
        web = pod['containers'][0]
        self.assertEqual(web['name'], 'actual-web-name')
        self.assertEqual(set(web), {'name', 'volumeMounts'})
        self.assertEqual(len(web['volumeMounts']), 3)
        self.assertEqual({m['name'] for m in web['volumeMounts']}, {patcher.VOLUME})
        self.assertEqual({m['subPath'] for m in web['volumeMounts']}, {'js', 'css-Agent-default', 'css-Customer-default'})
        self.assertTrue(all(m['readOnly'] is False and m['subPathExpr'] is None for m in web['volumeMounts']))
        self.assertTrue(all(m['mountPath'].endswith(('js-cache', 'css-cache')) for m in web['volumeMounts']))
        self.assertEqual(pod['securityContext']['fsGroup'], 10001)
        self.assertEqual(pod['volumes'], [{'name': patcher.VOLUME, 'persistentVolumeClaim': {'claimName': patcher.VOLUME}}])

    def test_nonroot_initialization_reuses_web_image_and_confines_writes(self):
        pod = patcher.generate(deployment())['spec']['template']['spec']
        init = pod['initContainers'][0]
        self.assertEqual(init['image'], 'registry/tessera@sha256:fixture')
        self.assertEqual(init['securityContext']['runAsUser'], 10001)
        self.assertEqual(init['securityContext']['runAsGroup'], 33)
        self.assertFalse(init['securityContext']['allowPrivilegeEscalation'])
        self.assertEqual(init['securityContext']['capabilities']['drop'], ['ALL'])
        self.assertEqual(init['command'], ['/bin/sh', '-ec'])
        self.assertNotIn('chmod', init['args'][0])
        self.assertNotIn('chown', init['args'][0])
        self.assertNotIn('/opt/otobo', init['args'][0])
        self.assertEqual(init['volumeMounts'][0]['mountPath'], '/loader-cache')

    def test_custom_skin_and_traversal_rejection(self):
        result = patcher.generate(deployment(), skins=['Customer/acme', 'Customer/acme'])
        mounts = result['spec']['template']['spec']['containers'][0]['volumeMounts']
        self.assertEqual(len(mounts), 4)
        self.assertEqual(mounts[-1]['subPath'], 'css-Customer-acme')
        for invalid in ('Customer/../etc', 'Customer/x;id', 'Agent/a/b', 'Anything/default'):
            with self.assertRaises(ValueError):
                patcher.generate(deployment(), skins=[invalid])

    def test_container_selection_and_uid_fail_closed(self):
        source = deployment()
        source['spec']['template']['spec']['containers'].append({'name': 'sidecar', 'image': 'other'})
        self.assertEqual(patcher.generate(source)['spec']['template']['spec']['containers'][0]['name'], 'actual-web-name')
        with self.assertRaises(ValueError):
            patcher.generate(source, container='does-not-exist')
        with self.assertRaises(ValueError):
            patcher.generate(source, uid=0)
        with self.assertRaises(ValueError):
            patcher.generate(source, gid=10001)

    def test_reserved_volume_cannot_replace_another_claim(self):
        source = deployment()
        source['spec']['template']['spec']['volumes'].append({'name': patcher.VOLUME, 'persistentVolumeClaim': {'claimName': 'business-data'}})
        with self.assertRaises(ValueError):
            patcher.generate(source)


if __name__ == '__main__':
    unittest.main()
