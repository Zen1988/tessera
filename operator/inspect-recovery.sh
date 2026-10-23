#!/usr/bin/env sh
set -eu
printf '%s\n' '=== MariaDB identity and native recovery status ==='
kubectl -n mariadb get mariadbs -o json | jq '.items[] | {name:.metadata.name,uid:.metadata.uid,replicas:.spec.replicas,rootPasswordSecretKeyRef:.spec.rootPasswordSecretKeyRef,galera:.spec.galera,tls:.spec.tls,status:.status}'
printf '%s\n' '=== MariaDB Secret key names only ==='
kubectl -n mariadb get secrets -o json | jq '.items[] | select(.metadata.name | startswith("tessera-mariadb")) | {name:.metadata.name,keys:(.data // {} | keys)}'
printf '%s\n' '=== MariaDB services ==='
kubectl -n mariadb get services -o wide
printf '%s\n' '=== Longhorn volumes ==='
kubectl -n longhorn-system get volumes.longhorn.io -o json | jq '.items[] | {name:.metadata.name,nodeID:.spec.nodeID,replicas:.spec.numberOfReplicas,state:.status.state,robustness:.status.robustness,currentNodeID:.status.currentNodeID,conditions:.status.conditions}'
printf '%s\n' '=== Longhorn and MetalLB workloads ==='
kubectl -n longhorn-system get pods -o wide
kubectl -n metallb-system get pods -o wide
printf '%s\n' '=== MetalLB advertisement configuration ==='
kubectl -n metallb-system get ipaddresspools.metallb.io,l2advertisements.metallb.io,bgpadvertisements.metallb.io,bgppeers.metallb.io -o yaml
printf '%s\n' '=== API addresses used by Kubernetes Service ==='
kubectl -n default get endpointslice -l kubernetes.io/service-name=kubernetes -o wide
