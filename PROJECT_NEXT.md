# 2026-10-22 — Longhorn stalled native recovery tracking and bounded manager repair0.3.2

OwnerclarifiesLonghornalreadyownsreplicas;TESSERAmustdetectprolongednativefailureandrestorestalledservice. Implementedoptional longhorn-stall-recovery adapter andconcreteNCS900s policy, namedoptionalnamespaceRBAC/configappend. PersistentpervolumeUIDevidenceinexistingsharedledger:3samples, lastprogress, activeengineRWreplicacount/rebuildStatushighwatermarks; noresourceVersionnoise/oscillationtimerreset; >600sAPIobservationgapresetscontinuity. Respectsmax(policythreshold,nativereplica-replenishment-wait-interval+300s). Idleunuseddetachedvolumesexcluded; desiredattachmentnotattachedtracked; unknownengineevidenceexplicit.4policiesallowed,roundrobinsampletimingdocumented.

Oneautomaticmanagerrepaironly:stalledattacheddegradedvolumeownedbytargetnode/currentNodeIDmatch, runningactiveengine>=1RWreplica,exactverifiedlonghorn-managerDaemonSetownership,exactly1notReadyrepeatedCrashLoopmanager>=3restarts,>=2Readypeers,allnodesfreshReady/nopressure. PersistintentbeforePDB/UID/RVeviction;6hourattemptcooldown/max20receiptsincludinguncertainresponse. Healthycontrollersnotrestarted; noengine/replicadeletion/volumewrites/force-detach/salvage/diskchanges. Reportsstalledblockersincludingcapacity/scheduling/network/attachment; evictionacceptednotrestorationverified; continuesvolumestatusobservations. ApplicationIOunverified. FixController.save toretainPUTreturnedresourceVersionformultipleCASintent/receiptwriteswithinonecycle; regressiontestincluded,alsofixesRedisadaptermulti-savepath.

114tests pass including15newLonghornprogress/stall/oscillation/identity/APIgap/nativewait/controlleraction/safety/CAScases. Kitoutputs/TESSERA-Operator-0.3.2-Build-Kit.zip SHA25661152a52cc5ce7eb844f2cc9a09451e6b857f565813e764038485dc2c07f9867. Source/imageDockerfile/runtime/testgate/HApatchversionsupdated. NoLinuximagebuild/import/deployment/Longhornliveacceptanceexecutedbyagent. LONGHORN.md documentsactivationviaoptionalRBAC+configure-redis.py --policy longhorn-policy-ncs.json (helpernowgeneric) preservingexistingPG/Redisconfig/ledger. NativeGaleraactivation/fullquorumrestore,MetalLB/kube-vipdedicatedrecoveryremainpendingearlierevidence; donotclaimfullstackrestoration.
# 2026-10-22 — Operator0.3.1 Redis transport and three-node API HA prepared

Live owner outputs: all3Sentinels agree mymaster172.30.1.1:6379 epoch0,2slaves,2otherSentinels,quorum2; native RedisReplication.status.masterNode=tessera-redis-ha-1. Replica2 nowReady after transientLonghorn attach delay; INFOslave confirms same primary, linkup, no sync, replid69382294734969c399393167fbcdea5a547530a6. Pod0 current replication not yet reconfirmed. Sentinel explicitly logs withoutTLS; pods lackcertmounts, plaintextINFOworks. Earlier user TLS assumption superseded by observedconfiguration. CorrectSentinelCLI maps REDIS_PASSWORD to REDISCLI_AUTH incontainer without exposingvalues. Secretconfirmed tessera/tessera-redis-auth/password. Added explicit tlsboolean (noautomaticdowngrade), concreteNCS policy, namedoptionalRedisRBAC/configmergehelper preservingPGconfig/ledger, redis-py8setflaghandling, reachableSentineldisagreementgate, healthyPodsplitprimarydetection, stablecooldown, fullconfirmed/evicting/waiting/completed tests. NoRedisactivation/liveacceptance yet.

User explicitlyrequests3operatorreplicas withrequiredanti-affinity andwill manuallyimportimageoneachnode. Added HAstrategicpatch scoped3knownhostnames,3replicas,requiredhostnameanti-affinity/controlplanetoleration,imageNever,rollingmaxSurge0/maxUnavailable1; existingargs/configpreserved. DefaultAPIusesinclusterService,notSSHkubeconfig/VIPdirectly. Explicit3directAPIIPfallbacks viaTESSERA_API_ENDPOINTS withCA/hostnameverification, boundedGETtransport/5xxfailover, noRBACmasking. Writespreflightreadselectreachableendpoint andneverblindlyreplayuncertainmutations.120sCASLeaseleadertakeover. RequirescertificateSANs/controlplanequorum/network; doesnotrepairkube-vip or guaranteeetcdavailabilityafterquorumloss. OwnerreportsVIPissueafterdirectshutdownofnode61; actualkube-viprootcauseunverified.

99tests pass plusHApatch/policyvalidation. Kitoutputs/TESSERA-Operator-0.3.1-Build-Kit.zip;imagebuild/import/deploypendingowner. Addedinspect-recovery.sh fornativeMariaDBstatus/Secretkeynames/services/Longhornvolumes/MetalLBconfig/APIEndpoints(noSecretvalues). UserexpandsprioritytoMariaDBGalera,Longhorn,MetalLB. Galerasinglemembercodealreadyexistsbutnotconfigured/liveaccepted;wholequorumbootstrapnotimplemented. Longhorn/MetalLBremainobserveonly;needinstalledconfigurationevidencetodevelopnativeactions. UserfutureVMware, wantsservicerestoreonsurvivingnodesnotnodereplacement; nofencingproviderconfigured. DeadhostforcePoddelete/Longhorndetachremainunimplementedwithoutpositiveisolation/storageownershipevidence. Do notclaimfullstackautomaticrestoration. Nextownerbuild/importallnodesandapplyHApatch;collectinspect-recoveryoutputandprobeRedisfromoperatorbeforepolicyactivation;implementGalera/fullstorage/networknative-recoverypolicyfromevidence.
# 2026-10-22 — Redis replica recovery 0.3.0 implemented; activation pending

Added redis_recovery.py and optional redis-replica-replace policy using verified TLS/client certificates and exact named Kubernetes Secret, three configured Sentinel endpoints, majority CKQUORUM/primary epoch agreement, authoritative primary plus streaming survivor INFO identity/lag, all involved node readiness/fresh leases. Three confirmations/120 seconds before persisted intent and UID/RV-precondition PDB-respecting eviction; verifies replacement Pod UID, readiness and replication before completed. 15-minute action budget, six-hour cooldown, retained bounded receipts; no forced deletion/promotion/PVC mutation. Eight new authority tests; total86 pass. Packaged source kit0.3.0; not image-built/deployed/live tested. Redis configuration deliberately not enabled; actual master name, services, Secret/key names/client certificate arrangement remain unknown. User confirms Redis TLS and kube-vip API VIP10.0.1.60. Node2 kubectl reports no route to VIP; provided per-command direct API readiness/routing checks in operator/REDIS.md. Dead-host stuck termination remains unimplemented without verified hard fencing/storage detach integration; do not claim it is solved. Need live configuration metadata, kube-vip diagnosis and fencing provider details next. PostgreSQL live recovery acceptance remains recorded separately.
# 2026-10-22 — PostgreSQL automatic recovery verified live

Owner final SQL confirms tessera-postgres-2 and tessera-postgres-3 both streaming asynchronously from primary1, with identical replay_lsn 1/57001038. Operator /status at 2026-10-22T08:36:43.244139+00:00 reports recovery/postgres-recovery healthy, reason recovery verified; six-hour cooldown, operation e3b10bed-2b64-4ab8-b0a4-6f98d1ecac2f. Live recovery acceptance for this single divergent CNPG replica is complete after upgrading to 0.2.1. This supersedes pending final verification in preceding entries. Six-hour cooldown is the configured action throttle, not ongoing recovery. Retained divergent directory remains same-PVC preservation rather than independent backup. Redis terminating/dead-node recovery, hard fencing, Galera live activation/acceptance, HA image distribution and independent backup remain outstanding; do not claim universal automatic recovery.
# 2026-10-22 — Operator 0.2.1 live CNPG handoff succeeds to Pod Ready

Owner build output confirms embedded test/config gate passed, OCI manifest sha256:34c49071be71bc21edf01db3fe57579b243c5757e10bd7d9fec03489c40a5b4b imported, optional recovery RBAC upgraded without resetting ConfigMap ledger or Lease, and Deployment rollout succeeded. Existing operation resumed: tessera-postgres-3 was created and became 1/1 Running in 22 seconds with zero restarts; original primary and replica2 remained Ready. Completed native join Job remains normal evidence. This validates the corrected native PVC ownership handoff to Pod Ready; final SQL streaming and recovery phase completed are still awaiting owner output. Do not equate Pod Ready with final recovery acceptance. Retained divergent pgdata directory is on the same PVC, not an independent backup. Other recovery adapters and node fencing remain subject to earlier documented limits.
# 2026-10-22 — Live0.2.0 CNPG hand-off bug;0.2.1 prepared

Owner live recovery op e3b10bed-2b64-4ab8-b0a4-6f98d1ecac2f reachedunfencing;fences[] cleared; originalPVCPVCUIDd31019c0-6bbb-48c9-8944-adb6c9e84d18 remainsownerless/cnpg.io/pvcStatusdetached withoperationmarker. JoinJobtessera-postgres-3-join succeeded12s, only2realDBPods. Nativejoinlogs explicitlyrenameoldpgdata to /var/lib/postgresql/data/pgdata_20261022T080500Z thenpg_basebackup timeline7completed. Thus olddirectoryretainedonsamevolume; not anindependentcopy andnotproof ofdurablebackup. CSI snapshotapi-resources outputempty; noCSI snapshotsavailable. Earlier claimmetadataalonepreservesindependentcopywasincorrect; do notdeletevolume/Job orclaimnewreplicaready.

Read exactCNPGv1.30.1source(commit2a35abb) into.artifacts/cnpg-1.30.1: internal/controller/cluster_status.go indexesmanagedPVCsbyowner; persistentvolumeclaim/status.go MarkPVCReadyForCompletedJobs onlyprocessesmanagedPVCs. RemovingClusterownerRef preventsnativecompletedJob->PVCready->databasePodhandoff whilejobitselfcanreuseoldPVC. Additionalbug: TESSERApods() countedJobPods asDBmembers; waitingcheckedonlynameabsence ratherthanoldUIDgone.0.2.1fixesall: filterdirectClusterownedinstancePods, recognizenewUIDsamename, verifyownedfreshcompletedjoinJob/PVCUID/sourceauthority/nodehealth andnative logsconfirmold-directoryrename+completedbasebackup;restoreverifiedClusterownerreferenceonly(CAS/leader),letCNPGmarkPVCready/createPod;neverfabricateReady/removefinalizers/deletePVC. AddscopedbatchJobsGET. Keepoldledger/config/Lease;existingoperationresumesat unfencing. Oldretaineddirectory remainsunderreusedPVC/nativeownership andneeds independentexport;nozero-lossbackupclaim.

78tests pass includinglive-shapedcompletedJobcount/samenameUID/handoff/jobownership/PVCidentity/archiveproof/current3replicationtests. Newsourcekit outputs/TESSERA-Operator-0.2.1-Build-Kit.zip; newimagebuild/import/rollout/nativehandoffacceptancepending onownerhost. Deployed0.2.0stillactive. UpgradeoptionalRBAC+imageonly, noledgerreset/nogenericmanifestreapply. Do notaskuser todeletecompletedJob/PVC asfix. Independent snapshotpolicy remainsfutureprerequisite, notimplemented/installed here. CurrentPGsource1/replica2healthy verified; otherDBrecovery notenabled.
# 2026-10-22 — Live0.2.0 PostgreSQL WebSocket probes pass

Owner executesrecovery.APIinsideappsDeployment successfully. NativeSQLprimarytessera-postgres-1 hasexpectedSystemID7697134515630092313/timeline7; primaryreportsreplica2streaminglag0. Replica2SQLconfirmsrecoverytrue/sameID/timeline7/receiverstreaming. Confirmsnewimageimport/deploymentandoptionalexecRBACworked; supportsactivationofpreviouslyauthorizedPGrecoverypolicy. Do notinferGaleraorRedisrecoveryreadiness. NextpatchonlyexistingConfigMaprecovery.json andDeploymentargs toenablePGautoactions; retaincurrentsingle-nodeaffinity/replicasuntilimageimportconfirmedallnodes. Do notapplyHA2patchprematurely. MonitorpersistedoperationphasesandretainedPVC; nativefencing/eviction/replacementstillunverifieduntilreportedcompletion. No freshapprovalrequiredforauthorizedpolicy; no actualactivationexecutedbyagent.
# 2026-10-22 — Operator0.2.0 Linux OCI image built

Owner BuildKit output confirms69.4s16/16success using Ubuntu26.04basec098726dd9b9733f3e885f8de0ef375206a311b0a317eadc40d347b1115fb944. Runtime includesmonitor.py/recovery.py; embeddedunit/configvalidationRUNpassed. OCI manifest1b8cae1fe56df4113ae003b455e21f6e9692a34ebc0c20eaa91e1ce9c856d5c6, config6ce533a7d614267736532f47bbe3c198eee6e1ac925ebbdcad9c5cf43b6d1005. Plainuser build failed rootownedsocketpermission; sudoPATHbuild succeeded, no socketchmodrequired. Newimage import/finalvalidation/nativeSQLWebSocket/RBAC/recoveryacceptance stillpending. Next import onbuildnode and updateexistingpinnedDeploymentimageonly (no--recovery-config yet), applyoptionalPGpermissions/ledger and testfixedSQLprobes read-only beforeactivating policy; distributeimageallnodes beforeHApatch. Existing deployed0.1.0observe baseline untilownerappliesupgrade; noautomaticrecoveryexecuted frombuildalone.
# 2026-10-22 — Recovery transport/RBAC final verification

69tests pass after websockettransport/failover/PVCidentity/fence/crashresume cases; pinnedwebsocket-client1.9.2import dependency verified in workspace. OfficialKubernetes1.37WebSocketexec requires syntheticCREATE aswell asGET; correctedoptionalRole onlypods/exec to get/create, ordinaryPod/logs remainget. StateConfigMapmanifestomitsdata to preserveprogress; HApatchrequiresdistinctnodesviaPodAntiAffinity. Sourcekit0.2.0regenerated. Stillnotbuilt/deployed/live-native-tested. Owner earlier SQLconfirmsCNPGprimary1timeline7, replica2timeline7 streamingasync withsent/flush/replay all1/450020C8; verifiedexpectedSystemID7697134515630092313includedpolicy. MariaDBSecretnameknownroot; keynames/CAkey/mTLSrequirement/GaleraUUID/nativeCRDversion stillneeded. Deployed0.1.0 remainsobserve-only untilnewbuild/config/RBACactivation. NoSQLcredentialcreatedorSecretvaluesreadbyagent.
# 2026-10-22 — Operator0.2.0 automatic recovery code prepared

- Owner explicitly requires unattended crash recovery using node/network/storage evidence and log diagnosis, including Galera; authorizes reading Kubernetes root Secret. Confirmed mariadb/tessera-mariadb-root. Secret metadata list contains mariadb CA/bundle/client/server certs and postgres awx-db-auth plus CNPG CA/replication/server certs; no obvious PostgreSQLsuperuser password Secret. Do not use AWXappcredentials as administrative identity or assume missing rootSecret. No secret values read/pasted.
- Implemented recovery.py optional-controller and CLI --recovery-config, version0.2.0 Ubuntu26.04. Persistent precreated ConfigMap operation ledger and CASLease in apps; no operator DB/PVC. Known log signatures, >=3observations across120s, onefailedmember only,3knownmembers, allnodeReady/fresh<=60s Lease/no pressure, dualsurvivorDBquery/correctidentity/quorum/replication beforeaction. PostgreSQLuses fixed readonly local psql via TLS WebSocket exec (websocket-client1.9.2); no database password required. Galerauses exactnamedSecretGET rootpassword/publicCA, verifiedTLS, never secretvaluesinargv/logs. Keynames/TLSSANs/GaleraUUID/nativeCRD stillunverified; mTLSclientcert not implemented, soGalera notenabled yet.
- CNPGadapter followsv1.30.1native destroy--keep-pvcmetadata semantics: nativefence, sourcePVCUID/ownershipchecked, removeonlymatchingClusterownerRef and markcnpg.io/pvcStatusdetached withreceipt, gracefulPDB/UID-preconditioneviction, nativeCNPGreplacement, removeownfence andverifyall3SQL/streaming. NoPVCdelete/wipe/forcePoddelete/promotion/automaticdivergenttransactionmerge. Existing divergentvolume retained. Logerror itself isnot sufficientauthority. Primarychange pauses/reconfirms3times120s thenresumes automatically. Galeraadapter only restartsone recognizedfailedjoinmember while2membersconfirm sameUUIDPrimary/Synced; nativeoperatorhandlesSST. Fullquorumloss/emptyUUID/unknownseqno/forcedbootstrap nothandled bythisroutine.
- Added separate optionalnamespaceRBAC, namedCM/Leaseupdateonly; postgresClusterupdate/podlogs/getexec/PVCmetadataupdate/eviction; MariaDBsecretsGET restrictedroot+bundle, noSecretlist. Configpatchenablesonlyverifiedpostgrescluster/systemID7697134515630092313. HAdeploymentpatch2replicasrequirednodeanti-affinity/removesoldnodepin; distribute0.2.0image onallnodesbeforeactivation. StateConfigMapmanifestomitsdataandLeaseomitsholderfields to preserve existingruntimeprogress onrepeatapply/upgrades. Monitorconfigpatchpreservesoriginalconfig. No livepermissions/applicationschanged.
-69tests pass: originalhealth40 plus policy/state-machine/leadership/crashresume/losteviction/sourcefailover/PVCidentity/fence/quorum/transportsecurity regressions. RealWebSocketclient1.9.2download/import available locally; fakeAPI/sockettests only, no nativeCNPG/Galera/PDB or realWebSocketintegration/recoveryacceptance. Sourcekit outputs/TESSERA-Operator-0.2.0-Build-Kit.zip and operator/RECOVERY.md. No0.2.0imagebuild/deploy yet; deployed0.1.0 remainsobserve-only. Need ownerhostbuild/import and isolatedacceptance. Rootnativepermissions are administrative evenwithfixedcommands; moduleisnotgeneralAIshellexecutor.
- Limits: standalonein-clusteroperator stillrequiresAPI/controlplane/storage, noindependentnodeprobeagent, nohardnodefencing/powercontrol/fullclusterbackuprestore, noRedis/Sentinel/AWXautomaticadapter/scalingyet. Two-houractionbudget/sixhourcooldown/20receipts boundretries; failuresretrywithoutper-actionuserapproval but stopdestructivesteps whenauthorityambiguous. NativewholeclusterGalera recovery mustbeverifiedseparately. Never claim universalrestore or zeroRPOforasyncreplication. Next verifyMariaDBSecretkeynames/publicCA/TLS/nativeCRD/UUID, buildnewimageonuserhost, distribute, applyoptionalpolicy/RBAC deliberately andverifyactualrecovery preservingPVC3.
# 2026-10-22 — PostgreSQL member3 timeline divergence confirmed

Owner previous-container logs establish fatal PostgreSQLstartup error: requested timeline6 is not a child of this server history. Member3 checkpoint1/3700AD08 timeline5 lies beyond timeline6 fork1/35002630. SystemID7697134515630092313. Postmaster exits1; earlier manager-container Completed0 was not PostgreSQLsuccess. Initial health-server TLS no-certificate messages precede successful cert preload and are not the observed fatal cause. Diverged history is established; cause/promotion history/authoritative branch/data-loss exposure not yet established. No automatic deletion/rewind/reseed/promotion authorized from these logs. Next inspect CNPG status and both surviving members recovery/timeline/replication, preserve member3PVC. CNPGnative recovery/pg_rewind or rebuild requires confirmed source authority and preservation of potentially unique divergent data. See officialCNPG1.30failure_modes and PostgreSQL18pg_rewind. Operator0.1.1remains prepared, deployed0.1.0observer has no recovery actions.
# 2026-10-22 — Observer0.1.1 reporting fixes prepared; PostgreSQL cause pending

Owner diagnostics: MetalLB speaker actual desired/current/ready/available3; observer0.1.0 uses obj.kind to select DaemonSet fields, but list items can omit kind. Fixed by passing known resource kind from endpoint; explicit desiredNumberScheduled/numberReady now used. Successful empty PVC lists no longer unknown; API403/errors remain unknown. Bound PVC conditionUnused=True/NoPodsUsingPVC is informational, not degradation; genuine resize/other conditions retained. Longhorn test volume is detached with robustnessunknown and unusedPVC; retain unknown runtime robustness, clarify reason, do not infer repair need or certify durability.

Postgres18.6 tessera-postgres-3 on node2 (CNPG1.30.1 replica) starts/exits roughly1second, previous exit0Completed,8restarts; attached volume and successful init, no OOM indication in supplied describe. Startup connection-refused is downstream symptom. Need previous postgres-container logs before cause/recovery. Do not kill/reseed/promote or change native operator from these observations.

Prepared separate operator0.1.1 kit (Ubuntu26.04, same read-only boundary),40tests pass including4 regression tests for empty inventory/access denial/UnusedPVC/DaemonSet counting. Versioned archive root tessera-operator-0.1.1 avoids mixing built0.1.0 sources/dist; regenerated manifests reference0.1.1 and removed old0.1.0validateddigest annotation. ApplicationSOPM/OPM180 unchanged. Live deployed image remains0.1.0 until owner builds/imports/smoke-tests then sets image. No0.1.1image build/deploy yet. Source kit outputs/TESSERA-Operator-0.1.1-Build-Kit.zip. Operator protocol checks remain unconfigured and automation disabled.
# 2026-10-22 — Operator deployed; live metrics confirmed

Owner output confirms apps namespace created,39-resource observe manifest applied and deployment tessera-operator successfully rolled out. CPU/memory samples across application/control-plane namespaces and fresh:true confirm live API/resource-metrics collection. Owner-pasted single JSON log line begins mid-record (22762chars remainder); node/Longhorn/MetalLB summaries cannot be certified from that truncated excerpt. PostgreSQL/Redis/Sentinel explicitly unknown because no protocol endpoints configured, as intended. Metrics healthy means sample collection, not service/replication health. Next obtain compact live /status summary through in-Pod Python loopback request, then configure verified protocol endpoints/TLS/monitoring credentials. No automated recovery/scale actions enabled. Earlier serverdryrun failed because dryrun Namespace was not persisted; separate apps creation fixed prerequisite. Future fresh-install instructions must create namespace before full serverdryrun.
# 2026-10-22 — Owner cluster inventory and prepared observer manifest

Owner confirms3 Ready control-plane nodes k8s.ncs.local10.0.1.61/k8s2.62/k8s3.63, Kubernetes1.37.1, containerd2.4.2, Rocky10.2. Actual components: tessera(web/daemon/Redis3+Sentinel3), mariadb(Galera3, native mariadb-system operator), postgres(CNPG3, cnpg-system operator), awx(nativeAWXoperator), longhorn-system, metallb-system, kube-system(Cilium/metrics-server), elastic-system/elasticsearch, forgejo and default test workloads. Snapshot all MariaDB1/2ready, postgres3 CrashLoop, TESSERAweb/daemon failing and Forgejo initializing; cause not established by inventory. All listedPVCs Bound does not prove healthy I/O.

Prepared operator/k8s-ncs-observe.yaml via render_ncs_manifest.py:39 unique resources, creates apps, scoped read-only Roles/Bindings for observed namespaces, existing health code/config validated, no protocol targets/SecretsAPI/publicService/PVC. Image docker.io/library/tessera-operator:0.1.0 with Never pull and required node-name affinity k8s.ncs.local (only verified local image import); specific control-planeNoSchedule toleration. No HA claim until image distributed/registry and scheduling relaxed. Captures verified image digest in annotation. No image rebuild required: manifest/config only; existing health image unchanged. Updated source build-kit. Next transfer YAML, serverdryrun/apply/rollout/log acceptance. No live apply executed by agent. ActualTLS/monitorcredentials/GaleraUUID/PostgresSystemID/Sentinelmaster-name and consensus still unverified; native operators retain lifecycle ownership.
# 2026-10-22 — Operator containerd import and final-image validation confirmed

Owner output confirms OCI archive SHA check OK, import into containerd namespace k8s.io with manifest85517323bcbc858affc8b6a317855a76dc36a3fb8600160ab2829b1c4beb34de, and readonly final-image execution returns configuration valid. Image docker.io/library/tessera-operator:0.1.0 now built/imported/validation-tested on owner host. No live operator deployment, real target configuration, VA scan or cross-node image availability confirmed. Next: read-only Kubernetes node/Pod/Service/PVC inventory to confirm apps placement, installed component namespaces, per-member endpoints and image distribution before deliberate observe-only deployment. Password SSH remains owner-operated separate session.
# 2026-10-22 — Operator Ubuntu26.04 OCI build succeeded on owner host

Owner-pasted BuildKit output confirms121.1s successful15/15 build on k8s.ncs.local, linux/amd64. Actual kit directory is $HOME/tessera-operator/tessera-operator. Ubuntu26.04 base digest c098726dd9b9733f3e885f8de0ef375206a311b0a317eadc40d347b1115fb944; image manifest digest85517323bcbc858affc8b6a317855a76dc36a3fb8600160ab2829b1c4beb34de; config digest990b1cda8b1f0b91dd7680675f4986d3f4f5ea291010e9110f91d5c996bdfacc. Embedded unit-test/config-validation RUN succeeded; OCI archive exported and wrapper reports success. This supersedes prior no-image-built status. ctr import, final readonly image execution, size/scanner results, deployment and live protocol/CNI acceptance remain unverified. Next: verify archive SHA, explicit ctr k8s.io import and readonly --validate; no rollout inferred from build success.
# 2026-10-22 — Latest Ubuntu LTS and security refresh

Owner requests newer Ubuntu to avoid retirement/VA concerns. Updated operator image FROM ubuntu:26.04 (current LTS); supersedes24.04 selection. Official Ubuntu lifecycle lists26.04 standard security maintenance through May2031;24.04 remains maintained through2029, not near immediate retirement.26.10 is newer interim release but shorter lifecycle, so latestLTS selected for this long-lived service. Docker build now pulls/no-cache; BuildKit uses image-resolve-mode=pull/no-cache; Dockerfile upgrades installed APT packages before minimal runtime install. Final image scan still required; latest base is not a no-CVE guarantee. Current local tests use Python3.12; actual26.04/Python/runtime/image build gate and scanner acceptance remain owner-host pending. No live cluster/app-package change.
# 2026-10-22 — Ubuntu operator image base selected

Owner accepts Alpine or Ubuntu. Selected Ubuntu24.04 for initial operator image; Dockerfile now installs Python3/venv/CA certificates without recommended packages, clears APT indexes, uses dedicated /opt/venv, retains separate verification stage and nonroot read-only runtime contract. Supersedes earlier Python-slim/Debian base, no application code/package changes. Alpine remains an alternative, not a second build. Regenerated build kit; no actual Linux image build yet. Follow operator/CONTAINERD.md on containerd-only host. Resource/image size still needs measurement.
# 2026-10-22 — Containerd-only operator build path

- Owner provides zen@10.0.1.61 and confirms x86_64 with /usr/bin/ctr only (no nerdctl/buildctl/docker). SSH host reachable and user entered password in separately opened PowerShell window; agent noninteractive SSH remains unauthenticated. No password captured or key installed; no remote build/deploy executed.
- Added operator/build-containerd.sh exporting OCI archive through a separate BuildKit socket, with metadata/SHA256/explicit image reference, existing/partial archive refusal and no automatic import/push. CONTAINERD.md contains local SCP transfer, official BuildKit0.34.1 amd64 checksum-verified download/install of only buildctl/buildkitd, foreground containerd-worker in isolated tessera-buildkit namespace, explicit ctr k8s.io import and readonly final-image validation. No Docker install/containerd restart/cluster deployment required by this path.
- Official GitHub release API reports amd64 tar SHA256 a59539daf547fe0958efe2d07e41c0a6944e1112a66d7e519ec1cf5b673ef15b. Verified script syntax and3 fake-builder scenarios: successful artifact/SHA, overwrite rejection, failed build does not publish final archive. These are wrapper tests, not a real image build. Source build-kit regenerated; actual BuildKit installation/build/import/runtime acceptance remain pending on owner's host. See operator/CONTAINERD.md. Earlier Docker-only build direction is superseded for this host; baseline36 health tests remain unchanged.
# 2026-10-22 — Operator implementation acceptance next

Observe-only 0.1.0 is implemented in operator/; supersedes earlier no-implementation design notes. User confirms apps namespace, independent IN-CLUSTER application, no public exposure. No image built yet: no Docker/Podman/installedWSL here; build host/repository question pending. Source build kit outputs/TESSERA-Operator-0.1.0-Build-Kit.zip is not an image. On Linux builder run sh build.sh to execute embedded tests/build/nonroot validation/export image archive. Then configure real per-member TLS endpoints/verified IDs/monitor-only Secret mounts and namespaces/RBAC; dryrun before deliberate install.36 tests pass, no live acceptance. Remove only confirmed implemented design items from pending scope: basic health adapters/metrics/internal deployment are done; distributed network evidence, consensus/fencing/rejoin, shutdown and scaling remain pending. See operator/README.md and latest PROJECT_STATUS.md; no OPM changes.
# 2026-10-22 — Operator membership recovery and infrastructure evidence

- Owner confirms intended-cluster membership recovery must check node status and operator-local network health. Extended docs/tessera-operator-design.md with observer/API/DNS, fresh node heartbeats, independent network perspectives, storage/process and service-quorum evidence. Optional unprivileged per-node probes proposed; no deployment made.
- Controlled isolate/fence/stop/rejoin requires corroborated authority, preserved volumes, bounded retries and verified synchronization. Unreachable node is not proof its writer stopped; endpoint removal is not fencing. Observer isolation, partition, stale evidence or ambiguous quorum blocks destructive recovery. Native topology managers retain election ownership. Separate policy required for destructive reseeding/rebootstrap. Design only; implementation and partition acceptance tests pending.
# 2026-10-22 — Standalone TESSERA Operator initiative

See docs/tessera-operator-design.md. Confirmed requirements: standalone, no own DB/PVC, small image, independent multi-service health, utilization and controlled scaling. Proposed Go implementation is separate from OPM. Begin with read-only real workload/version/owner/endpoint/Redis-data inventory and observe-only web/daemon/Redis adapters; diagnose Redis terminating before remediation. Planned shutdown must complete before nodes/control-plane/storage stop; in-cluster controller cannot guarantee action during total outage. Preserve native operator/Sentinel/HPA ownership, quorum and daemon single-active behavior. No implementation/deployment yet; keep this pending design until verified implementation is recorded in PROJECT_STATUS.md.
# Immediate — apply reviewed shared generated-asset cache fix

Confirmed same3 web imageIDs/UID10001:GID33/writable dirs but requiredModuleJS file missing ononePod. Owner approves shared RWX JS/CSS + Redis application cache separation and requests toolkit. Dedicated TESSERA-Shared-Loader-Cache-Kit.zip and full generic kit include new Longhorn1GiRWX PVC, current-Deployment patch generator and guide. No prepare/imagebuild required. Extract onK8s adminhost, save private webDeploymentJSON, generate narrow patch (autodetectcurrentimage/container), createBoundPVC, serverdryrun, controlledpatch/rollout. Initnonrootcreatesonlynewcachepaths; preserveexistingfsGroup/privatecredentials/config/runtimepaths. Add customskins explicitly. Verify everyPod sameassetfile/hash, HTTP200JS/CSSproperMIME and actuallogin, then approvedPodreplacementtest. Keepnosniff, noRedisflush/chmod777.5localtests pass; realLonghornandgatewayacceptance pending, no live mutations/centralpush. Older emptyDir-cache guidance superseded.

# Immediate — diagnose web login generated-asset failures across Pods

Owner login styled after multiple refreshes but Sign In inert; current screenshot still404/MIME HTML for ModuleJS_3d7fcdd...js and ResponsiveCSS. Native login button disabled until Core.Customer.Login.Init enables it, so restore missing JS delivery first. Compare every Running app=tessera-web Pod imageID, matching ModuleJS file in var/httpd/htdocs/js/js-cache, writable js/AgentCSS/CustomerCSS cache directories and effective shared/private mounts. Redis minified/checksum cache is not shared filesystem asset storage. Prior sample Pod-security patch uses emptyDir caches, which is insufficient alone for arbitrary multi-Pod asset routing; investigate and correct distribution after runtime evidence. Do not disable nosniff, force login submission, flushRedis or scale production down blindly. No cluster mutation or speculative image/application patch yet.

# Immediate — rebuild/deploy default server-verified HTTPS

Owner explicitly chooses image-baked SSLVerifyClient none instead of Apache ConfigMap overrides for Cilium. image/apache/tls.conf now server-only HTTPS; TLS protocols/cert/key paths intact. Build new immutable automatic revision, deploy image deliberately; oldr1/r2 remain unchanged. Current web patch only mounts TLS Secret; old override duplicate removed and targeted cleanup patch provided for previously mounted config. Keep backend CA trust ConfigMap/BackendTLSPolicy plus Cilium ingress policy; no client cert key required. Run actual Apache+gateway positive/CA-name rejection and access-denial acceptance. No live mutations or central push yet; historical default-mTLS/override directions below superseded. Version-independent prepare/build rules still apply (old prepared kits missing release.json need fresh preparation).

# Immediate — version-independent toolkit host acceptance

Owner requested installed TESSERA-Base version detection + base/r1/r2. Generic kit now uses installed registry SELECT-only detection before/after prepare, dependencies/release.json, Python automatic revision allocator + persistent home-local state/flock/local Docker tags and receipts. Follow examples/AUTO-VERSIONING.md; fresh prepare once for this toolkit/new app versions, repeat build only for revisions. No guessing from latest OPM or old app folder; oldprepared missingrelease metadata requires fresh staging.30 tests pass/3 POSIX skips; native Linux registry/flock/Docker acceptance pending. Genericarchive TESSERA-Ubuntu26.04-Container-Toolkit.zip; current application180 unchanged, example185 not a release. Keep state across extractions/cleanup; coordinate multiple builders centrally and registry immutability, no global uniqueness guarantee from local state. No central push/live deployment done for this work. Continue HTTPS/configure/Longhorn acceptance below.

# Immediate — review Cilium Gateway backend HTTPS opt-in

Owner manifests identify Gatewaytessera-gateway10.0.1.72 HTTPS443 hostname tessera.ncs.local, publicSecrettessera-gateway-tls; HTTPRoute tessera-web currentlyService80->Pod80 withTESSERA_ROUTE Session cookie, no BackendTLSPolicy. Prepared examples/cilium-gateway artifactset/README for explicit server-only TLS override + Cilium CA/SNI validation portal.tessera.local + ingress-only8443 policy, ports443->8443 and narrow route patch. Default image mTLS remains; no live changes. Confirm actual web container name/image/probes and current config success, review policies/additive allows, use isolated rehearsal or maintenance window; steps not atomic. No automatic runtime TLS downgrade or certificate regen. Public Gateway unchanged. Underlying r1 image build/Longhorn acceptance still needs owner confirmation. Removing /otobo, trusted proxy headers, cookie/auth audit and real failover remain pending.

# Immediate — resume r1 build after test-directory traversal fix

Owner prepare succeeded5531 files, actual Docker build passed check-source as otobo; final test script open failed EACCES at /opt/tessera/tests/test-configure.py. Dockerfile now explicitly chmod0555 test directory/0444 script after COPY before USER. Patch extracted Dockerfile and rerun build only; no reprepare/no cache clearing/no root test bypass. Confirm8 nonroot configure regressions and image modules pass, then actual Longhorn scratch/controlled native configure as documented. Central publication through7c49c1fb verified; additional traversal fix needs subsequent publication.

# Immediate — build image180-r1 and verify nonroot Longhorn configure

Updated kit container/ubuntu2604 fixes unreadable distribution source and cp -a metadata errors. Default image tag0.0.180-r1-ubuntu26.04, applicationOPM180 unchanged. Owner requires otobo:www-data: UID10001/GID33, immutable distribution root:www-data0550/0440, source otobo:www-data read-only modes and selected writable dirs0750. Existing K8s runAsGroup/fsGroup10001 manifests need deliberate alignment to33 for r1 (including configure/debug), no automatic live changes. Follow examples/CONFIGURE-R1.md. Build executes check-source and8 fixture configure regressions as actual otobo UID; local24 tests pass/2 POSIX skips only. Then test scratch subdirectories on actual Longhorn as10001 and controlled real configure Job with external Config/secrets/SAME shared volume, preserve fingerprint guard and backups. No Redis/PVC replacement/schema change. HTTPS cert/key/publicCA external Secret mount; CA private key never in image/Pod. Owner now explicitly requests central upload including pending7801a983 checkpoint and r1; use reviewed normal non-force publication and verify success.

# Immediate — Kubernetes daemon generated configuration and node evictions

Owner cluster has3 Running web Pods and1 desired daemon blocked by missing generated config; daemon mounts only external Config.pm and Redis Secret, no Kernel/Config/Files shared volume. No configure Job/app config PVC listed. Many old daemon Pods Evicted on k8s.ncs.local; investigate exact eviction reason separately. Read-only next checks already provided: web deployment mounts/volumes, web+daemon actual imageIDs, evicted Pod status message, generated filenames/permissions in working web. Preserve existing working configuration; backup copied folder is sensitive and does not fix runtime mounts. Then prepare one controlled configure Job and shared config volume for web/daemon; no empty marker/file bypass or per-replica config rebuild. Current180 unchanged. Sentinel discovery unimplemented; proposed infrastructure primary endpoint still requires tested operator/proxy implementation and persistent connection failover tests. Central checkpoint requested by owner includes source/tests/docs/current180 release, excludes local temp/historical duplicate outputs.

# Immediate — resume Docker build after Apache prompt fix

Owner successfully reached Docker Apache setup; a2dismod autoindex prompted and aborted unattended build. Dockerfile now uses a2dismod -f for intentional removal. Patch extracted Dockerfile then rerun build.sh; no prepare, no --no-cache and no live Apache change needed. Actual image/runtime acceptance remains pending.

# Immediate — retry preparation after S/MIME test fixture exclusion

Owner prepare failed on scripts/test/sample/SMIME private .asc fixtures; app/ was never published. Updated source.exclude excludes /scripts/test/***, Docker/audit also reject it, private-key detector remains strict. Updated ZIP available. In extracted kit apply that exclusion (or extract updated source kit), rerun prepare successfully THEN build. Do not bypass audit, copy Config or assume absent app means installed source missing.18 Python checks/build Bash syntax pass; actual Linux preparation/image acceptance still pending.

# Current task — Apache HTTPS container acceptance and root URL routing

Use updated container/ubuntu2604 full kit; Apache2.4/mod_perl/prefork HTTPS8443 default, only tessera.conf enabled, no Nginx migration. Follow examples/HARDENING.md and future pod-security-patch.yaml (patch requires existing Config/generated/durable volumes). Build/run isolated Ubuntu image, verify full Apache config/TLS/mTLS, web+daemon authentication/cache/stop, writable paths under Restricted settings and all uploads/integrations. No actual image built locally. Preserve installed180 source; do not reinstall packages. SSH zen@10.0.1.33 currently authentication denied; no live changes authorized. Requested removal of /otobo remains outstanding: native PSGI explicitly mounts it; design Custom-compatible routing and verify links/redirects/API/CSRF/assets/portal host separation without core rewrite assumptions. Current Apache root handler does not satisfy it. Repackage kit after further changes.

# Current task — run installed-host Ubuntu26.04 image kit and internal PKI

Owner confirms180 already installed; use container/ubuntu2604 complete image kit and outputs/TESSERA-180-Ubuntu26.04-Container-Kit.zip. Do NOT reapply180 OPM or use older restoration staging/179-base delta as primary workflow. Host Ubuntu26.04.1/resolute confirmed; no need ask OS again. prepare copies installed source as-is with exclusions, CPAN requirements from installed CheckModules, full Dockerfile rebuilds apt/Perl dependencies. Optional site entrypoint path can be supplied to prepare, otherwise provided native web/daemon wrapper is used. Shared generated-config volume and explicit configure step precede startup; no automatic schema migration.17 tests+7 Bash syntax+2 Perl syntax pass; actual Docker/Linux runtime build remains unrun here.

Internal PKI decisions confirmed: public/customer CA terminates at ingress; TESSERA internal CA protects backend/component traffic, not public browsers. RSA8192 ALL production keys,3-year calendar expiry, leaves capped by issuer expiry. SANs tessera.local/portal.tessera.local, daemon.tessera.local, redis.tessera.local, db.tessera.local plus separate ingress-client identity. Run PKI tool on host outside build context, encrypted root key offline, no keys baked into image/ZIP. Internal mTLS proxy provided; future DB/Redis templates not activated. Current180 Redis authentication lacks TLS constructor plumbing—do not imply cert files alone enable transport encryption. Verify private DNS, ingress SNI/trust/client cert and server/client TLS before enforcement. MariaDB remains planned inside Kubernetes. No live deployment/data/credential mutation authorized by artifact creation.

# Later Kubernetes migration — discovery and decisions next

Confirmed update: MariaDB will run INSIDE Kubernetes too. Earlier externalDB-first proposal is superseded. Follow revised in-cluster DB section and restore/cutover plan; decide MariaDB version/topology/operator/storage class/capacity/backup target/RPO/RTO. Do not ask database placement again. No deployment or data-migration authorization.

User requests full later migration plan; completed docs/kubernetes-migration-plan.md and Linux staging review/tool/transfer kit recorded PROJECT_STATUS.md. Do not reconstruct plan or assume deployment authorization. Next inventory effective LIVE ArticleStorage/ArticleDataDir and historical DB/FS/S3 data, VirtualFS per-record backends (CMDB/governance/MELT/photos), sessions/queues/spools/generated config and integrations. Local exported ticket configDB/default VirtualFSDB are not proof of live/historical DB-only storage. Keep attachments out of image, preserve them in durable DB or migrated shared storage; verify old/new content after Pod/node replacement. Do not delete old files.

Confirm cluster/storage/MariaDB topology, entrypoint/Dockerfile/base dependencies, availability/scale, RPO/RTO/window. MariaDB placement is confirmed in-cluster. Revised host staging kit provided;5 Python fixture tests pass/1 Unix skip, no Linux host execution. Preserve180 OPM identity. Implement actual image/config-generation/upgrade locking/manifests only after inventory; isolated rehearsal before quiesced cutover and consistent rollback. No production migration, data mutation or deployment requested.

# Build 180 — container build and live acceptance pending

Custom integration/source package complete: owner-supplied Desktop/Redis.pm adapted under Custom/Kernel/System/Cache/Redis.pm, core untouched, existing179 secret modules unchanged. Details and completed work PROJECT_STATUS.md/docs/build-180-redis-integration.md.180 unsigned/not installed;340 payloads, all339 baseline entries preserved.75 assertions pass/7 Linux skips; all3 modules compile. Do not ask for recovered Redis source again.

Next obtain exact existing TESSERA179 image digest/entrypoint and container build environment; verify proposed runtime/first-copy paths, build versioned180 image from sanitized outputs/build-180/container, inspect base layers for old secrets/logs/caches, verify inherited entrypoint/CMD/USER and both web/daemon arguments. No Docker/Podman/nerdctl/kubectl locally; image not built. Sign180 through existing CODESECURITY release workflow before production release. In isolated Linux staging test actual runtime-user reads, real Redis AUTH/cache/TTL/cleanup, rotation/failure/recovery and ongoing Web/Daemon jobs. Initial installation needs controlled process replacement to load the Custom override; subsequent Redis credential refresh uses the existing connection implementation. DB rotation still requires rollout. No live deployment changes authorized. Do not claim zero downtime or image-wide absence of historical credentials without validation.

# New setup remaining stages — after 0.0.178

Organization stage implemented: Admin New setup -> create first Organization name/description -> add more or finish organization setup. Durable progress, request deduplication and backend authorization included; details PROJECT_STATUS.md/docs/new-setup-wizard.md.178 unsigned/not installed,108 checks pass; live MariaDB/browser/admin registration acceptance pending. Do not recreate completed organization-stage design work.

Next implement ticket-prefix/numbering reset, separate ticket/asset/governance reset controls and CSR lifecycle, then Central ingestion/confidential disclosure and whole-platform Docker missing/empty/partial/existing database runner/readiness. Existing confirmed requirements: docs/agent-system-setup-design.md and docs/docker-startup-upgrade-design.md. Organization completion is not complete platform setup. Active-only seeds integrated177;11 definitionless active labels are planned features, not export blockers. No live deployment requested.
# Shared portal error format — 0.0.174 prepared, 2026-10-15

Standard customer/public error/warning/permission/fatal handlers now share portal card/sidebar layout; completed implementation275 checks in PROJECT_STATUS.md/docs/customer-portal-security.md.174 unsigned/not installed. Next install/hard refresh, verify one shell/sidebar for signed full errors, fragments remain embedded, ordinary warning no attack log, actual403/request400 and normal successful submission. Confirm security rejection retains reference/internal note. Anonymous errors must not expose authenticated navigation/backend diagnostics. Fatal exceptions now500; stage AJAX/dialog compatibility without deliberately crashing production. Common CSS migration preserves admin arrays/repeated installs. Apache/proxy-generated/custom JSON errors remain outside shared handlers. Then resume wider portal injection/CSP work.

# Actual security page styling — 0.0.173 prepared, 2026-10-15

Owner172 screenshot unstyled: confirmed login-only Branding loader mistake, fixed in173 via dedicated module CSS registration plus bootstrap deploy. Completed fix/tests in PROJECT_STATUS.md/docs/customer-portal-security.md.220 checks pass;173 unsigned/not installed by agent. Next install173, verify SysConfig deployment, hard refresh/reopen action URL and inspect large red403/yellow warning/sidebar/card plus attempted action or explicit missing label. Check actual CSS/generated bundle and HTTP403, agent internal audit note with reference. Do not substitute local directly-linked preview for live loader acceptance. Then resume remaining portal injection/CSP work.

# Security rejection UI/audit — 0.0.172 prepared, 2026-10-15

Owner installed171 and confirmed GET denial.172 prepares themed real403 with sidebar/red code/yellow alert/own actor+action+reference and structured system event plus agent-only internal audit note for readable tickets.201 checks/local desktop+mobile preview pass; completed detail PROJECT_STATUS.md/docs/customer-portal-security.md. Next install172/hard refresh and repeat GET: Network403, page styling, same event reference in agent internal note and TESSERA_SECURITY log. No state/governance changes. Valid normal form must still succeed.172 unsigned/not installed by agent. Then resume fragment-script removal, injection/CSP and integrity coverage. Previous171 install-pending instruction is superseded by owner's confirmation.

# Customer portal hardening — 0.0.171 prepared, 2026-10-15

First CSRF/method fix complete,174 checks pass; details in PROJECT_STATUS.md and docs/customer-portal-security.md. Do not install/sign now unless requested;171 unsigned, installed/signed170 preserved. Next trace assessment/diagnosis generated HTML/data contexts and replace CustomerTicketZoom fragment ExecuteScripts with explicit external trusted initialization, then malicious-content regressions. Continue ActivityDialog, articles, uploads, API/lookups and customer permission boundaries. Extensionless /portal-style URL possible but exact URL/config undecided; no Python rewrite required, no routing changed. Browser compatibility/CSRF form acceptance and security guard deployment remain pending.

# App integrity and CSP staging — 2026-10-15

Prepared independent CODESECURITY runtime and tests recorded in PROJECT_STATUS.md; deployment guide `C:\Users\Zen\OneDrive\Documents\CODESECURITY\runtime\DEPLOYMENT.md`. Current Linux Apache/PSGI, future Docker. Next stage actual entry point and SELECT-only MariaDB signed-manifest source, test request/startup denial and preserved article sandbox CSP. Close exact-load/Custom/cache/generated static/CLI/daemon bypasses before claiming full code-execution integrity. CSP currently report-only; observe browser violations, refactor trusted script initialization and introduce trusted-site nonces before enforcement. No live guard/database changes, new signed package or root/admin-control work performed. Existing0.0.170 remains signed and byte-unchanged.

# First publisher signature — 0.0.170 prepared, 2026-10-15

Completed duplicate removal/rebuild/key setup/badge tracing recorded in PROJECT_STATUS.md; previous duplicate-repair priority below is superseded. Owner signing completed; independent signature/public-key/exact OPM verification passed on 2026-10-15. Completed evidence is in PROJECT_STATUS.md. Next integrate protected public-key trust and verification before OTOBO install hooks, with distinct publisher-signature status; native OTOBO verified badge depends on its cloud authority and cannot be earned by our signature alone. No install/runtime enforcement implemented yet.

# Release signing follow-up — 2026-10-15

Independent local signer implemented in `C:\Users\Zen\OneDrive\Documents\CODESECURITY`; completed work and boundaries recorded in PROJECT_STATUS.md and that project's README. Next: remove duplicate customer Branding.css file-list entry from authoritative SOPM in a separately validated new release, rebuild OPM, choose production encrypted key custody and protected NTFS access, then implement trusted public-key verification before package installation hooks and later runtime integrity checks. Do not add signer/private keys to TESSERA or generate approval hashes during install. No production package signed and no key generated. Source temporarily stays in OneDrive at user's request before device repair; verify encrypted recovery copy before future deletion. Web injection prevention and governance approval are independent workstreams.

# Immediate follow-up — native calendar initialization, 0.0.169 prepared

Install169/hard refresh, then enter Calendar from Dashboard/List. Verify first October bars/list without navigation. Native APP_MODULE startup fixes the document-ready-before-Core.Config ordering defect;168 retries alone were insufficient. Check agent calendar too. Completed source/regression and live reproduction are recorded in PROJECT_STATUS.md.

# Immediate follow-up — first Calendar load, 0.0.168 prepared

Install168/hard refresh and open Calendar directly. Verify events load without switching months and repeat month/week/day navigation. If both attempts fail, capture Events HTTP status/response and matching `Customer Tickets calendar events failed` system-log entry; deployed cause remains unproved. Completed recovery/performance changes and validation are in PROJECT_STATUS.md.

# Immediate follow-up — calendar selected-period list, 0.0.167 prepared

Install167/hard refresh. Verify October5 ticket0032 against its displayed execution range in October and September; September panel excludes October-only events, while a real cross-month span remains listed. Check cached month/week/day navigation and local range labels. Exact live ticket dates remain unverified. Completed implementation/testing is in PROJECT_STATUS.md.

# Immediate follow-up — customer calendar 0.0.166 prepared

Install166 and hard-refresh Tickets Calendar. Confirm `>` between ticket number/title and standard category badges match the configured front-page colors. Check long titles/badge wrapping at desktop/mobile widths and retained master permissions. Completed code/testing is recorded in PROJECT_STATUS.md. Earlier calendar acceptance below remains pending where applicable.

# Immediate follow-up — customer calendar 0.0.165 prepared

Install 165 and hard-refresh customer Tickets Calendar. Confirm events load for IPC, check OTOBO system log if the generic error persists, and verify Change/Incident/ServiceRequest children group under the master number. For a master the user cannot read, confirm number-only heading and no title, link, or hidden sibling ticket. Verify readable master link and mobile panel layout. Completed code and tests are in PROJECT_STATUS.md and docs/ticket-calendar.md.

# Immediate follow-up — customer calendar CSS 0.0.164 prepared

Install 164 and hard-refresh the customer Tickets Calendar. Verify native FullCalendar day grid and compact prev/next/today/month/week/day toolbar, legend/event colors, desktop/mobile layout and ticket links. The installed163 screenshot showed missing customer-skin FullCalendar CSS; 164 packages it. Live visual acceptance is pending. Details in PROJECT_STATUS.md.

# Immediate follow-up — customer Tickets Calendar 0.0.163 prepared

Install 163, deploy its CustomerTicketOverview loader setting, and verify Dashboard / List / Calendar tabs. Check type colors and legend at desktop/mobile widths, browser-local times, IPC dense calendar, ticket links, and direct Events URL for two customer users with different SupportAssignments. Confirm forbidden titles and counts do not leak. Completed implementation/tests in PROJECT_STATUS.md and docs/ticket-calendar.md; no live acceptance claimed.

# Immediate follow-up — 0.0.162 prepared

Install 162 for Incident events anchored to native ticket Created time (manual and automated creation). Verify an Incident whose ActualStart is later still begins at Created, along with the 161 calendar permission and layout acceptance below. No new timestamp field or migration is needed. Completed work is in PROJECT_STATUS.md.

# Immediate follow-up — ticket calendar 0.0.161 prepared

Install 161 and deploy its frontend/loader/navigation SysConfig. Verify a planned Change, active Incident and closed ServiceRequest on month/week/day; edit dates/state and refresh. Test two agents in different queue groups plus a privileged agent: direct Events URL, event list and ticket zoom must all agree. Confirm browser-local timezone and responsive layout. Calendar design and completed tests are in PROJECT_STATUS.md and docs/ticket-calendar.md. No live installation or permission acceptance is claimed.

# Immediate follow-up — 0.0.160 prepared

Install 160, retry Control 4600 and confirm risk creation per entitlement support profile. Verify article table and body timestamps after setting UserDefaultTimeZone to Asia/Singapore and/or user preference to the viewer's zone. Implement safe browser timezone detection and preference enrollment on first website visit; OTOBO currently only prompts the user. Do not change database OTOBOTimeZone. Completed 160 design and tests are in PROJECT_STATUS.md.

# Active EOS risk and Control acceptance —159 prepared, 2026-10-13

Install159 and reload web/daemon workers. Confirm SysConfig deployment and Run now. Control4599 (Dell VxRail E560) should complete Pass cleanup using MELT `Resolved`. Control4600 (Dell VxRail E560F) should expose the precise `APPLICATION::DEFAULT` resolver failure in its error article, because seven of ten affected Workloads lack ContractEntitlement while Application1493 visibly maps the default role to SupportProfile1063. Correct that verified resolver/data issue, then rerun and confirm distinct entitlement/default Risks, LastRun, and article timestamps in configured OTOBOTimeZone. Do not claim complete risk acceptance from Risk23 alone.

# Active entitlement-risk acceptance —156 prepared, 2026-10-13

Entitlement-covered technology SupportProfile partitions and missing-entitlement APPLICATION::DEFAULT fallback implemented; completed design/tests in PROJECT_STATUS.md and docs/entitlement-risk-partitions.md. Install156/reload workers, then apply paired EOS FieldAsssignment and Framework MasterTicket examples. Verify separate overlapping-team risks, stable reruns, correct fresh master owners and default fallback; no live156 acceptance claimed. Preserve old ledgers and administrator service/customer values.

# Active CI literal reference acceptance —155 prepared, 2026-10-13

155 fixes154 missing SQL quotation marks and adds CI owning-field error context plus database-executed/native CI tests. Details in PROJECT_STATUS.md. Install155/reload workers and retry original name-based TechnologyProfile/Product imports.154 is superseded; no live155 acceptance claimed. Preserve reference uniqueness/permission checks and authored names.

# Active literal reference acceptance —154 prepared, 2026-10-13

Literal GovernanceObject names/numbers implemented; completed design/testing recorded in PROJECT_STATUS.md and docs/governance-reference-literal-names.md. Install154/reload workers and retry original name-based TechnologyProfile retry9, verifying parent913. Number workaround is superseded after deployment. No review-only tabs should be imported. Live154 acceptance pending.

# Active Control run evidence acceptance —153 prepared, 2026-10-13

ON NO AFFECTED and automatic error articles are implemented; details/reference in PROJECT_STATUS.md and docs/control-run-outcomes.md. Install153/reload workers, then update live EOS YAML and verify zero-asset completion/error evidence. Missing Application findings are errors, not empty scans; Control4141 data/hydration investigation remains pending. No deployment or live YAML change claimed.

# Active EOS acceptance priority —152 prepared, 2026-10-12

Live EOS767 scripts use Sets and have correct one-year condition. Missing RiskStmt restored from original workbook through native UI.152 prevents unresolved import refs from silently clearing selections and updates discovery Set event names. Next install152/reload web+daemon workers and verify14G Control evaluation, affected assets/Application grouping, RiskStatement Framework and actual risk result. Exact original reference lookup failure still unproven. Details in latest PROJECT_STATUS.md.
# Active import validation priority —151 prepared, 2026-10-12

Blank ControlObjective script Set workbook cells were rejected as non-list values, independent of Mandatory.151 accepts explicit empty cells as empty Sets while retaining populated-data validation and omitted-column preservation. Install151, reload web workers, retry corrected v2 workbook, verify source-bearing and empty records. See latest PROJECT_STATUS.md for tests and decisions. Live151 acceptance pending.
# Current validation priority — 2026-10-12

Installed150 Framework1603 Save is verified after user cache cleanup and web service/container restart: two successful Save/reopen cycles, exact script/index retention, editor closed. Completed evidence and decisions are in PROJECT_STATUS.md. No151 fix needed for this observed mixed-runtime issue. Control Save and EOS import recovery remain unverified; do not infer their acceptance from the Framework check. Keep index uniqueness/consecutive validation within each owning Set.
# Import recovery priority — 2026-10-12

Latest prepared package149 guards GovernanceObject script Set import collisions and missing definitions. Next: install149, update/reopen the EOS one-row recovery, verify both programs persist, then use ControlObjective/Framework v2 workbooks and SecurityAdvisory v2. Never reuse v1 workbooks with blank legacy member columns. Details/tests recorded in PROJECT_STATUS.md. Live persistence remains unverified.

# Current follow-up — 2026-10-12

Ordered script Sets (1–99), migration workbooks and Assessment section routing are implemented in prepared0.0.148; details moved to PROJECT_STATUS.md and docs/ordered-script-blocks.md. Remaining: live package installation/import acceptance, verify existing administrator-owned Template Pages/GovernanceRole field layout against current exports, and native Excel/OTOBO form acceptance. Do not repeat completed storage/runtime work or overwrite authored definitions. Security review/assignment gates, MFA and email design remain pending below.

# TESSERA Project Next Focus

## Current accepted baseline — 0.0.129

- User confirms129 works and accepts the accumulated functional baseline. Approval recovery0052 is implemented and accepted; completed design, source and validation are recorded in PROJECT_STATUS.md. Continue from latest129 SOPM/OPM, not earlier repair assumptions.
- Remaining targeted checks: future fresh-cycle approval capture persists master outcome/date/marker, idempotent fresh/upgrade/reinstallation, and final OTOBO11.1 compatibility when stable. Prior detailed live checklists below are historical/unverified specifics and must not override this accepted baseline.


## Approval gate and session greeting — 0.0.128 live acceptance

- Install128 and hard refresh. Pending risk parent must be absent from Risk list, all dashboard counts/charts/matrices and export even after Assessment submits. Complete the required final Book-governed approval normally; its master decision marker/outcome/date should make submitted rows eligible. Do not backfill approvals or alter immutable history to force display. Approved missing/expired dates retain Review required behavior.
- Fresh login: choose emoji, see message for4 seconds, then card disappears. Immediately navigate elsewhere and return: no prompt. Refresh/another tab same login: no prompt; logout/new login: prompt again. Browser receives HttpOnly temporary dismissal cookie with no mood/message content. Verify desktop/mobile card edges align with dashboard boxes; native tiles and other controls remain usable. Newly discovered uses Assessment native Created.


## Profile preference layout — 0.0.126

- Install126/hard refresh. Check Current photo label above preview, Upload photo label above file picker, visible small removal checkbox with single label, laptop/mobile wrapping and working upload/removal. Other preferences retain native layout.


## Avatar action pointer path — 0.0.125

- Install125/hard refresh. Hover avatar, cross gap to gear then Logout; controls must remain clickable until pointer leaves whole row. Confirm hidden controls do not block page and keyboard focus/touch still works.

## Photo registration — 0.0.124 deployment

- Install124 to repair missing NavBarName in123 registration; deploy photo settings if pending and hard refresh. Verify profile preferences/upload/remove and stable sidebar controls. Includes123 owner mapping; existing Framework YAML still needs explicit assignment. No unrelated access settings overwritten.

## Ownership and profile deployment — 0.0.123

- Install123/hard refresh. Confirm Preferences/Profile photo upload/remove, stable avatar and gear right/logout next right on hover/focus/touch. GD required. Verify unrelated preferences preserved.
- Add `ZTicket-OwnerGroup: '"APPLICATION::DEFAULT"'` under RETURN/FIELD ASSIGNMENTS in applicable Framework ZRM-MasterTicket; full example docs/examples/framework/risk-master-ticket.yml. Fresh Risk SR stores Application default RoleMap SupportProfile before orchestration and retains it during assessment/remediation. Missing/ambiguous resolution prevents creation. Existing0050 unchanged; no snapshot backfill.


## Ticket dashboard date/type — 0.0.122 deployment

- Install122, hard refresh. Verify all five drilldowns show Ticket type before Ticket number, populated UTC creation dates, oldest-first rows and corrected seven-day count including held tickets. No ticket data changes required.

## Customer profile photo — 0.0.121 deployment

- Install121 (declares GD2.0 server resize dependency), hard refresh. In Preferences/Profile photo upload JPEG/PNG and verify128px square preview/navigation photo across refresh; remove returns initials. Check gear right of avatar on hover/keyboard focus, stable picture, touch layout and logout access. Verify another customer continues to see only own photo. No live account writes made by agent.121 includes120 clickable metrics and rolling closure window.


## Ticket metric drilldowns — 0.0.120 deployment

- Install120 and hard refresh Tickets. Click each of the five cards and check matching count/list, oldest creation date first, OwnerGroup names and source links. Closed window label should show prior calendar-month day through today UTC; verify a long-existing ticket closed recently is included and an earlier closure excluded. Failed remains all-time closed unsuccessful. Retains119 right-header toggles and118 searches. No workflow action required.


## Overview consistency and Ticket dashboard — 0.0.119 deployment

- Install119, hard refresh Tickets/Assets/Risk. Verify header New Ticket then Export Tickets, single export action, List/Dashboard toggle immediately to the right of blue Export and Dashboard default. Search should appear only in List: existing ticket fulltext, Asset name/number/tag/type and Risk configured display values. Verify list filter/pagination/export retain context.
- Check five Ticket cards against permitted All tickets: nonclosed including hold, unclosed at least7 days, all closed, only closed unsuccessful, directly IPC-delegated tickets. Click seven-day count and verify oldest-first creation date, readable OwnerGroup and links. Verify wide/narrow layouts and empty result lists. No workflow action needed for inspection.119 includes118/117 matrix compaction and earlier paired dashboard changes.


## Dashboard — 0.0.117 deployment

- Install117 and hard refresh. Check compact matrices show every impact column side by side at laptop width, labels wrap, and nonzero cells still expand links. Assets/CMDB and Risk Register default Dashboard; Export stays top-right. Verify paired Inherent/Residual Category and Risk Category charts and Framework-coloured matrices; selecting a category updates both, each cell opens its Assessment links. Summary counts are shared once. Check narrow-screen stacking, long labels, empty scope and configured Excel export. Includes115/116 dashboard changes; no separate earlier installation needed.
- Scope and limits recorded in Status: visible governed Assessment rows across Current/Review, New by Assessment created date, current Framework definitions, unavailable Framework/scales cannot generate matrix. Live visual acceptance pending.


## Assessment encoding — 0.0.114 deployment

- Install114 (includes113), refresh Assessment0047 Ticket330. Confirm custom rows render and Framework scales load. Assessment template malformed UTF-8 repaired; restart cycle confirmed by user screenshot. No submission required for view verification.


## Evidence wrapping — 0.0.113 deployment

-112 submission now confirmed by user screenshot.113 fixes wrapping for future execution/diagnosis articles; existing immutable article HTML is not rewritten. Verify new snapshot long labels wrap without overlapping values at laptop/narrow width. Downstream Unsuccessful lifecycle behavior remains independent live verification.


## Actual runtime form — 0.0.112 deployment

- Install112; agent reproduced111 failure and confirmed actual runtime form lacked FormID. After refresh/reopen, inspect populated FormID in named ZTSMRuntimeActionTreat form, search/reselect reference and retry user-authorized treatment. Live112 success not yet verified. No reference validation relaxation.


## Runtime reference validation — 0.0.111 deployment

- Install111, Ctrl+Shift+R, reopen treatment and reselect reference through search so cached allowed IDs bind to populated FormID. Retry intended treatment. Existing110 field-specific errors retained. Live end-to-end validation still pending.


## Treatment submission — 0.0.110 deployment

- Install110, refresh and reopen form to obtain proper FormID, reselect Treatment Ticket via search, fill work/outcome, then retry intended submission. If rejected, field-specific error should identify validation cause. No permission/reference validation relaxed. Live retry pending.


## Remediation plan guidance — 0.0.109 deployment

- Install109 directly (108 is superseded), Ctrl+Shift+R, reopen treatment. Plan remains visible with no checkbox and no acknowledgement error on submission; existing required treatment fields still enforced.27 implementation checks recorded in Status.


## Risk-plan acknowledgement — 0.0.108 deployment

- Install108, Ctrl+Shift+R and reopen treatment form. Checkbox I have reviewed the mapped risk treatment plan above must appear beneath mapped plan and respond to label click/Space. Unchecked submission should remain in form with required validation; checked allows normal validation. Avoid submitting test workflow merely for visual inspection. Existing server requirement remains enforced.


## Runtime dropdown alignment — 0.0.107 deployment

- Install107 and Ctrl+Shift+R. Check Outcome selected text stays inside its inner control before/after hover, focus, change and clear; reopen dropdown and verify options still usable. Verify Remarks label and narrower layout. CSS-only patch; no submission required.


## Runtime hover and Result — 0.0.106 deployment

- Install106, Ctrl+Shift+R, reopen0045. Verify hover/focus on Risk Treatment Ticket keeps its label on border, Result shows plain Step/Result, and tall empty wrapper is gone. Plan already confirmed visible with105. Live visual checks pending; no submission required.


## Remediation follow-up — 0.0.105 deployment

- Install105 and Ctrl+Shift+R; reopen0045. Confirm Assessment0043 plan test is displayed, Result default has plain Step/Result, and labels/textarea align.104 follow-up supersedes the104 acceptance steps. No submission needed to inspect. Current lookup collects matching successful assessments under the same parent; future iteration selection should be coordinated with execution role evidence policy if remediation retries accumulate assessments.


## Remediation rendering — 0.0.104 deployment

- Install104, Ctrl+Shift+R and reopen0045 treatment action. Verify matching Assessment plan text appears, Result default shows Step/Result without HTML tags, and labels/textarea align on laptop and narrower screens. No submission needed for visual check. If plan remains missing, inspect persisted Assessment origin/statement/row values; only the confirmed scalar extraction defect was corrected.


## Universal role lookup — 0.0.103 deployment

- Install103. Existing managed TESSERA-ACTIVITY-ROLELOOKUP loses its old type allowlist; runtime excludes master types using ZTSM::RequestType. Rerun the role lookup job once for existing pending0045 and verify OwnerGroup resolves via TICKET::ASSESSOR YAML from closed Assessment0043 to ICA::ATFM::CLOUD. Fresh execution types should require no job filter edit; catalog master types remain excluded, closed/held evidence untouched. No live install/assignment change performed.

## Framework scales — 0.0.102 deployment

- Install102 and Ctrl+Shift+R. Set Framework ZRM-LikelihoodScale/ZRM-ImpactScale to positive integer maxima, and ensure catalog classes contain valid numeric names1 through intended maximum. Verify3×5 then10×10 choices on both inherent/residual fields, preserved valid selection, out-of-range reselection, calculated products and authored matrix badges. Missing/invalid Framework scales must block submission. No package install or live Framework/catalog updates performed by agent.
- Scale implementation complete; remaining Framework design is immutable version/config evidence and selected-Framework origin scoring. Historical101 scale design entry below is superseded by102.

## Assessment classification — 0.0.101 deployment and Framework scales

- Install101 and Ctrl+Shift+R. Verify dropdown score changes and Framework overrides update inherent/residual labels/colours; authored9 Low agrees with Register. Test missing rules neutral and new article labels. Implementation checks recorded in PROJECT_STATUS.
- Design Framework-specific allowed likelihood/impact scales (user proposes3×3/5×5), render choices from explicit scale metadata and validate submissions server-side. Do not infer scales from severity score bands or invent Dynamic Fields before export/schema agreement. Current101 does not restrict dropdown values.

## Risk Register Framework colours — 0.0.100 deployment

- Install100 and Ctrl+Shift+R. For submitted eligible Assessment rows, verify inherent/residual score badges use selected ZRM-Framework RiskMatrix and severity colours/names. Unmapped/missing rules remain neutral. Excel values stay unchanged. Implementation42 assertions in PROJECT_STATUS. User confirms99 replacement ticket exists.
- Remaining design: immutable submission-time Framework matrix/version snapshot and selected-Framework calculation. Current display uses current matrix explicitly; no historical score rewriting.

## Cancelled Risk Management restart — 0.0.99 deployment

- Install99. With TESSERARiskMasterTicket scheduler enabled and daemon running, next five-minute reconciliation should replace cancelled master0037 for still-active Risk21. Verify one new master and Assessment, previous-cycle link and retained0037/0041 cancellation history. Repeated scheduler delivery must reuse the fresh active master. No live restart or install was performed by the agent.

## Assessment Framework selection — 0.0.98 deployment

- Install98 and Ctrl+Shift+R. Set TESSERA::RiskAssessment::DefaultFramework to exact existing Asset Risk Management. Retain administrator Set Include mandatory rules. Apply optional ZRM-Framework mapping to Framework ZRM-MasterTicket using docs/risk-assessment-framework.md; no live YAML was modified. Start a fresh case and verify default, statement/clear fallback, manual override/reopen, mapped Framework inheritance, mandatory block and article name.
- Old test master0037 and active treatment0041 are cancelled; completed assessment/approval history retained. User will redo assessment. Do not delete or silently rewrite evidence.
- Pending enhancement: execute selected per-row Framework scoring/matrix/colour rules and capture immutable Framework version/config evidence. Current98 adds selection/persistence/mapping only; do not claim that selecting a different Framework changes calculations or colours. Trace latest Framework exports and authored rule schema before implementation.

## Risk Register configuration recovery — 0.0.97 deployment

- Install97. Open TESSERA::RiskRegister::Columns; restore default if96 invalid empty-row override persists, save and deploy. Expect native YAML editor with13 initial mappings. Verify deployment and report/export;21 checks recorded in PROJECT_STATUS.

## Configurable Risk Register — 0.0.96 deployment

- Install96 and Ctrl+Shift+R. Verify assessment risk rows and child links, mapped scores/action/plan, master governance context, Excel selected-view export and non-IPC visibility. Configure TESSERA::RiskRegister::Columns using docs/risk-register-sysconfig.md; no inferred org mapping or residual exposure conversion. Implementation and97 assertions recorded in PROJECT_STATUS.

## Remarks label — 0.0.95 deployment

- Install95 and Ctrl+Shift+R; verify shared Approval Remarks label aligns near the left border on laptop/narrow view. Includes94 replay guard; fresh assessment progression test remains pending.

## Chapter completion replay — 0.0.94 deployment

- Install0.0.94. Use a fresh assessment to verify completion creates Approval and waits, without spawning treatment early. Repeat delivery must not advance an already-changed Book/level/iteration. Implementation and50 checks recorded in PROJECT_STATUS. Existing master320/Treatment324 need controlled recovery before reusing that case; no automatic data repair is included. Verify authored Book behavior for RiskAccepted after final approval separately.

## Risk Register — 0.0.93 UI deployment

- Install0.0.93 and Ctrl+Shift+R. First verify header, tabs and card align in native portal content area, clear fixed sidebar and work on laptop/mobile. Functional tests can follow separately. Refresh customer portal. Verify new Risk Register button, Current / Review required tabs, master-only inclusion, closed accepted current records, exact365-day expiry and missing-date review. Confirm requester/governed participant visibility and denied queue/company-only accounts. Implementation, date assumptions and121-test evidence recorded in PROJECT_STATUS.
- Test final governed Approval completion writes master RiskAssessmentOutcome plus existing ITSMDecisionDate; replay must preserve date, renewed approval establishes a new date. Legacy missing master decisions remain Review required, without implicit child recommendation backfill. Annual reviews use existing governed ticket interaction; no automatic renewal or reassessment launch.

## EOSL name mapping activation

- Apply docs/examples/controlobjective/product-eosl-risk-name-update.yml to EOSL ControlObjective ZRM-FieldAssignment; next failing evaluation should include the source Product name. Shared Risk identity is preserved, so the name represents the latest evaluated Product. Implementation and108-test validation recorded in PROJECT_STATUS; live activation pending.

## Asset dashboard — 0.0.91 deployment

- Install0.0.91 and refresh Your Assets. Verify List/Dashboard beside Export, distribution counts/percentages by displayed Asset Type, and unique assets tagged in accessible active Risk Management tickets. Both views must follow current filters and entitlement; closed tickets must not contribute. Implementation/tests recorded in PROJECT_STATUS; live dashboard visual acceptance pending.
- User confirms0.0.90 Name/header alignment. Grouped Excel implementation remains unchanged; download acceptance is still pending.

## Multiple asset entitlements — 0.0.88 deployment

- Install0.0.88 and verify Zen sees iaas-ext-aci-node1 through its ATFM Management entitlement despite the additional Network Management entitlement. Check detail and list agree, and unrelated assets remain excluded. Implementation in PROJECT_STATUS; Workload ldcphiaasesx204 is user-confirmed visible after complete-candidate fix.

## Customer navigation — 0.0.87 deployment

- Install0.0.87 and refresh customer portal. Company Tickets should be absent while personal Tickets and entitled Assets remain available. Implementation recorded in PROJECT_STATUS; package includes complete asset lookup0.0.86.

## Complete customer asset list — 0.0.86 deployment

- Implementation and live entitlement trace recorded in PROJECT_STATUS. Install0.0.86 and verify Zen sees ldcphiaasesx204 through the matching PMT entitlement/read assignment. Check counts, pagination and export include all authorized matches beyond1000; denied assets remain excluded. Candidate completeness is implemented without raising permission scope; large-CMDB performance optimization remains future work.

## Assessment reference picker — 0.0.85 deployment

- Implementation is recorded in PROJECT_STATUS. Install 0.0.85 (includes input-relative button alignment), refresh browser assets and verify Risk Statement uses the existing search-button modal, display text is read-only, Apply updates defaults and required validation uses selected IDs. Repeat for added rows and target references.

## Assets navigation — 0.0.83 deployment

- Customer dashboard response is user-confirmed restored after the 0.0.83 correction was supplied; details are in PROJECT_STATUS. Remaining check: Assets is hidden without a matching CMDB read assignment and visible for authorized customers; direct URLs retain backend entitlement enforcement.

## Acknowledgment checkbox UI — 0.0.81 deployment

- Delegation GUI fix is user-confirmed; implementation and acceptance are recorded in PROJECT_STATUS. Shared override/recovery controls and detailed keyboard/unchecked-submit coverage remain unconfirmed. No live action submitted by the agent.

## Namespace editor compatibility review — 2026-10-06

- Set/Group namespace lookup and absent-input preservation are implemented in 0.0.77; details are in PROJECT_STATUS. Namespace ZRM / Name RiskAssessment is restored live. Install 0.0.80 to correct the empty-hash lookup fallback, then verify existing Assessment values load.
- Review legacy GeneralCatalog, Queue, SLA, Type and MasterSlave editors for the same issue; determine installed ownership before changes. Preserve field IDs, Include rules, values and explicit administrator choices. No automatic bulk renaming.

## RiskAssessment 0.0.80 deployment

- Runtime now prefers unprefixed `RiskAssessment` with legacy lookup compatibility; implementation details are recorded in PROJECT_STATUS. Install 0.0.80 (includes prior fixes) and verify existing Assessment 321 loads its stored values without recreation. Missing-name detection now matches OTOBO empty-hash behavior.

## Earlier Apache exception

- Required-field behavior is user-tested and reported working; implementation and acceptance are recorded in PROJECT_STATUS.
- The earlier Apache 500 still has no matching server exception available. Investigate if it recurs; do not claim its root cause was confirmed.

## EOSL Product Control and Grouped Risk — Corrected 2026-09-28

- Product is the Control target. The authored PolicyFilter selects Product
  ConfigItems; discovery creates/reuses one Control per Product. The current
  live and packaged filter does this. `ZRM-CIInstance` identifies that Product.
  `ZRM-GOInstance`, `ZRM-TKInstance`, and `ZRM-MOInstance` retain their target
  object meanings and are not grouping slots.
- Evaluate each due Product Control against its EOSL date. Empty EOSL returns
  N/A. On failure, the authored evaluation finds affected assets. Risk grouping
  then uses scenario, RiskStatement and Application as the stable identity.
  The Risk display name for this policy is like `IS-4: EOSL: IaaS Extension`.
  A second failed Product in the same group reuses the Risk and unions related
  ConfigItems. The Application is recorded in `MELT-RelatedGO`; the statement
  is recorded in `MELT-RiskStmt`.
- The old `MELT-Reference` included Product ID. The revised assignment removes
  it, tests shared Risk reuse, and is now saved on live ControlObjective 767.
  Package 0.0.56 is installed. Risk 21 was created for the ICA IaaS Extension
  group at 15:50 SGT on 28 September and reused on the next day's evaluations.
  Nine older asset-level Risks remain after the user deleted Risk 19. They have no grouped
  reference, Application or RiskStatement fields, so review their lifecycle
  and reconcile them with Risk 21 before treating the visible active Risk count
  as the count of current grouped risks.
- `MELT` 0.0.25 is installed. Normal Delete links now show a confirmation
  page; dialog calls use `AJAX=1`. Risk 19 was deleted, and grouped Risk 21
  remained present in the live SQL check.
- `MELT-Control` is currently single-valued. Keep its first Control and record
  every contributing Control in Risk activity evidence. Do not present it as a
  complete list of failed Controls.

## Risk Calculation Framework - deployment and live verification

- 0.0.70 is built locally; OTOBO still has 0.0.69 installed. Obtain action-time
  approval before uploading/installing the package.
- After installation, allow scheduled Risk master reconciliation to backfill
  Assessment 312. Verify the YAML-authored automatic calculation article on
  Assessment 312 and parent ServiceRequest 311 before the engineer submits.
  Confirm base dimensions, raw/effective factors, factor chains, adjusted
  decimals, ceiling results, and Framework score are readable and separate from
  the later assessment matrix/article.
- Framework 1597 (Application Risk Management) scores once from the Application
  context. Framework 1599 (Asset Risk Management) scores per applicable asset.
  Both article templates are authored in their Framework's
  `EVIDENCE.AUTOMATION ARTICLE` YAML. Keep the standalone scoring YAML and
  GovernanceObject exports in `docs/examples/framework/` synchronized with the
  live objects.
- Confirm linked-ticket read access for Abdul Malik and other support-profile
  participants while verifying they cannot perform another assignee's task.
  Also check child ServiceRequest `CustomerID` propagation and AdminLog after
  reconciliation.
- Future methodology decisions: define Platform's separate factor
  contribution, residual scoring from mitigation Controls and rating
  thresholds, and how to migrate historical per-asset EOSL Risks or remove
  recovered ConfigItems. Existing grouped runtime preserves historical
  contribution and raises severity only.
- Framework applicability and scoring formulas remain authored governance
  rules. Do not infer a Framework from Policy ancestry or use the superseded
  Application MAX aggregation draft.


## ControlObjective Evaluation - Deployment and Next Decisions

User confirmed 0.0.46 live discovery creates Controls. Local 0.0.47 implements authored
VERSION 1 evaluation, calendar expressions, descendant/reference traversal and asset Risk
assignment. Completed design is recorded in PROJECT_STATUS and the architecture document.

- Install/test 0.0.47 with packaged evaluation/assignment YAML. Verify due dispatch, missing
  date N/A, Pass short circuit, descendant impact, four asset classes and shared Risk reuse.
- Confirm fresh install, upgrade/reinstall and actual daemon execution. Adapter tests do not
  constitute live validation. Exercise limits before scanning large populations.
- Define Risk resolution/reopening and contribution lifecycle. Passing checks perform no
  descendant scans and do not close existing Risks; preserve history.
- Define retirement/evaluation eligibility for historical Controls after PolicyFilter narrows.
- Paginated discovery and further traversal operators remain future work; current discovery
  maximum is 1000 and overflow fails rather than truncates.
- CustomerUser remains deferred. Ticket discovery works; descendant traversal currently
  requires a class-based CMDB/GovernanceObject/MELTObject target.
- Keep business conditions, target classes, paths, thresholds and assignments in authored
  policy. Never add Product/EOSL-specific engine branches or invent Dynamic Fields.

## Asset Import Through Service Request

### Confirmed boundary

- The customer Assets page provides export only; it must not directly import, create, overwrite, or merge ConfigItems.
- Asset import will be introduced later through a governed Service Request workflow with reviewable execution evidence.
- DynamicField Set and DynamicField Group payloads use JSON within their spreadsheet cells so repeated and nested values remain intact.

### Identity reconciliation

- Prefer a defined Asset Tag as the strongest business identity check.
- Then evaluate ConfigItem number and other class-appropriate identifiers.
- A likely match must produce a duplicate/merge suggestion for review; it must not silently create a second asset or overwrite/merge the existing asset.
- The eventual SR must record the match evidence, selected resolution, and merge/update result.

## Incident Diagnosis Loop and Iteration Runtime

### Objective

Implement Incident Diagnosis as a first-class, loop-capable workflow stage.

Incident handling is different from Service Request / Change because the required recovery action may not be known at the beginning. Incident workflow must support repeated investigation cycles until recovery is verified.

```text
Incident Raised
→ Diagnose
→ Assess
→ Endorse
→ Approve
→ Resolve
→ Verify
→ if verification fails, return to Diagnose with next iteration
```

Previous diagnosis, assessment, resolution, and verification records must remain as evidence. The system must not overwrite previous attempts.

---

## 1. Parent Incident Intake Fields

Requester-provided incident information belongs to the parent Incident ticket.

| Field | Purpose | Provided By |
|---|---|---|
| `ZIN-Observed` | What behavior / issue was observed | Requester |
| `ZIN-ErrorMessage` | Error message, alert, screenshot description, log snippet, or symptom evidence | Requester |
| `ZIN-AffectedCI` | Affected CI / system / component reported by requester | Requester |
| `ZIN-Iteration` | Current incident investigation iteration | System |

Important rule:

```text
ZIN-Observed, ZIN-ErrorMessage, and ZIN-AffectedCI belong to the parent Incident ticket.
They are requester-provided intake fields.
They must not be treated as diagnoser input fields.
```

Diagnosis child tickets may display these parent values as read-only context, but must not overwrite them.

---

## 2. New State: `diagnose`

A new lifecycle state/stage exists:

```text
diagnose
```

When parent Incident enters `diagnose`, it should run BlueBook normally.

Expected runtime behavior:

```text
Parent Incident Stage = diagnose
→ StateBookReader detects diagnose stage
→ BlueBookReader loads BlueBook chapters for diagnose
→ BlueBookReader creates child Diagnosis tickets
```

Diagnosis is normal BlueBook orchestration, but Diagnosis child ticket rendering and submission require special handling.

---

## 3. New Ticket Type: `Diagnosis`

Add / use new ticket type:

```text
Diagnosis
```

Diagnosis is similar to Assessment as a child workflow ticket, but it has a dedicated diagnosis form.

When:

```text
TicketType = Diagnosis
```

the portal should load the custom diagnosis form based on:

```text
release/next/ideal.jpg
```

The form is for diagnoser input only.

---

## 4. Diagnosis Child Ticket Fields

Diagnosis child tickets capture diagnoser investigation result.

| Field | Purpose | Provided By |
|---|---|---|
| `ZIN-Diagnosis` | What the diagnoser checked, found, ruled out, or reasoned | Diagnoser |
| `ZIN-Outcome` | Structured diagnosis outcome | Diagnoser |
| `ZIN-Plan` | Proposed recovery / workaround / next action plan | Diagnoser |
| `ZIN-Summary` | Short diagnosis summary | Diagnoser |
| `ZIN-Iteration` | Current incident iteration copied from parent | System |

Do not include these as diagnoser-editable fields:

```text
ZIN-Observed
ZIN-ErrorMessage
ZIN-AffectedCI
```

Diagnosis form may display parent incident context as read-only:

```text
Observed issue: parent.ZIN-Observed
Error message: parent.ZIN-ErrorMessage
Affected CI: parent.ZIN-AffectedCI
Current iteration: parent.ZIN-Iteration
```

---

## 5. Governance Role: `DIAGNOSE`

For all diagnosis BlueBook chapters / diagnosis child tickets, add governance role:

```text
GovernanceRole = DIAGNOSE
```

This separates diagnosis from assessment.

```text
Diagnosis = investigate incident symptom / cause / applicability
Assessment = assess proposed action / risk / feasibility
```

Do not reuse `ASSESS` for diagnosis.

---

## 6. Diagnosis Outcome Logic

If diagnosis outcome is:

```text
ZIN-Outcome = Not Applicable
```

or:

```text
ZIN-Outcome = Recovered
```

then it should not generate follow-up recovery/action task from that diagnosis.

If diagnosis outcome is actionable, such as:

```text
Symptom Observed
Cause Observed
Root Cause Observed
Severity Confirmed
```

then the system should generate the next task set for that diagnosis result.

Core rule:

```text
Only actionable diagnosis outcomes should proceed into task generation.
Not Applicable and Recovered do not spawn recovery/action tasks.
```

---

## 7. Multi-Diagnoser Handling

Diagnosis is different from Assessment because multiple teams may diagnose the same incident in the same iteration.

Example:

```text
Iteration 1:
- Network Diagnosis → Not Applicable
- Server Diagnosis → Symptom Observed
- Application Diagnosis → Cause Observed
```

When diagnosis children complete, parent logic should pull all Diagnosis child tickets where:

```text
ParentTicketID = current parent
ZIN-Iteration = current parent ZIN-Iteration
TicketType = Diagnosis
```

Then evaluate their outcomes.

```text
If ZIN-Outcome is Not Applicable or Recovered
→ no action task generated from that diagnosis

If ZIN-Outcome is actionable
→ generate next task based on StateBook / BlueBook runtime logic
```

There may be multiple actionable diagnosis tickets in the same iteration. Do not collapse diagnosis into a single winner too early.

---

## 8. Propagate `ZIN-Iteration` to Incident Children

Every incident child ticket created by BlueBook should inherit:

```text
ZIN-Iteration = parent.ZIN-Iteration
```

This applies to:

```text
Diagnosis
Assessment
Endorsement
Approval
Resolve Task
Verification
```

For Service Request / Change, this field can be absent or default to `1`, but it must not break existing flows.

---

## 9. BlueBook Runtime Must Compare Iteration

Current runtime matching may use:

```text
ParentTicketID
Stage
BlueLevel
BlueRecordID
```

For incident, this is not enough.

When `ZIN-Iteration` exists, runtime identity must include it:

```text
ParentTicketID
Stage
BlueLevel
BlueRecordID
ZIN-Iteration
```

Why:

```text
Iteration 1 diagnose task completed
Verification failed
Parent returns to diagnose
Iteration becomes 2
BlueBook must create new diagnose child tasks
```

Required rule:

```text
If ZIN-Iteration exists on parent ticket, BlueBook child lookup and synchronization must include ZIN-Iteration.
```

---

## 10. StateBook Must Compare Iteration

StateBookReader also needs to be iteration-aware.

For incident loopback:

```text
Parent Stage = diagnose
Parent ZIN-Iteration = 2
```

StateBook must not treat previous `diagnose` completion from iteration 1 as current completion.

Required rule:

```text
If ZIN-Iteration exists, StateBook stage completion / transition checks must consider current iteration.
```

---

## 11. Incident Verify Failed Logic

For Incident verification, add special handling.

If verification outcome is failed, not resolved, partially resolved, worsened, or cannot verify:

```text
Verification failed
→ increment parent ZIN-Iteration
→ set parent stage/state back to diagnose
→ trigger StateBookReader / BlueBookReader again
→ create new Diagnosis child tickets for next iteration
```

Example:

```text
Current parent:
ZIN-Iteration = 1
Stage = verify

User submits:
VerificationOutcome = Not Resolved

System updates parent:
ZIN-Iteration = 2
Stage = diagnose
```

This is not ticket reset. This is controlled incident loopback.

---

## 12. Incident-Specific Verify Action

Existing verify action may be too generic for Service Request / Change.

Add or customize verify action for Incident ticket type.

Behavior:

```text
If parent TicketType = Incident
AND VerificationOutcome != Resolved
→ increment ZIN-Iteration
→ set Stage = diagnose
→ trigger orchestration again
```

If resolved:

```text
VerificationOutcome = Resolved
→ proceed to closure
→ final resolution copied from last successful resolve task
```

Recommended verify outcomes:

```text
Resolved
Partially Resolved
Not Resolved
Worsened
Cannot Verify
```

Loopback outcomes:

```text
Partially Resolved
Not Resolved
Worsened
Cannot Verify
```

Closure outcome:

```text
Resolved
```

---

## 13. Final Resolution Rule

For incident closure, parent final resolution should come from:

```text
latest successful verified resolution iteration
```

Rule:

```text
Final Resolution = resolution from last iteration where verification outcome = Resolved
```

Earlier attempts remain evidence only.

---

## 14. SLA V1 Rule

Incident SLA calculation should remain simple for the first version.

Parent Incident SLA:

```text
Incident Created Time
→ Final Verified Resolved Time
```

Severity determines SLA target.

```text
Severity → SLA Target
Actual Duration → compare against SLA Target
```

If SLA fails:

```text
SLA Justification Owner = last verified resolving team
```

This team is not automatically blamed. They become the explanation owner because their action finally restored the service.

Earlier diagnosis / routing / failed attempts remain evidence for IPC review.

---

## 15. Minimal Implementation Order

### Step 1 — Data Model

Parent Incident fields:

```text
ZIN-Observed
ZIN-ErrorMessage
ZIN-AffectedCI
ZIN-Iteration
```

Diagnosis child fields:

```text
ZIN-Diagnosis
ZIN-Outcome
ZIN-Plan
ZIN-Summary
ZIN-Iteration
```

Downstream linkage fields:

```text
ZIN-SourceDiagnosisTicketID
ZIN-SourceDiagnosisIteration
ZIN-SourceDiagnosisOutcome
```

Add ticket type:

```text
Diagnosis
```

Add governance role:

```text
DIAGNOSE
```

### Step 2 — Diagnosis Form

When:

```text
TicketType = Diagnosis
```

render custom diagnosis form based on:

```text
release/next/ideal.jpg
```

The form should:

```text
display parent incident intake fields as read-only context
allow diagnoser to submit only diagnosis fields
write diagnosis fields to child Diagnosis ticket
```

### Step 3 — Parent Incident Initialization

When parent Incident is created:

```text
ZIN-Iteration = 1
```

### Step 4 — BlueBook Iteration Awareness

Update child lookup / duplicate prevention / synchronization to include `ZIN-Iteration` when present.

### Step 5 — StateBook Iteration Awareness

Update stage completion / transition logic to include `ZIN-Iteration` when present.

### Step 6 — Diagnosis Result Aggregation and Expansion

When diagnosis children complete, pull all diagnosis children for:

```text
ParentTicketID
Current ZIN-Iteration
TicketType = Diagnosis
```

Filter out:

```text
Not Applicable
Recovered
```

For remaining actionable diagnosis results:

```text
generate one downstream task per actionable Diagnosis child
copy source Diagnosis OwnerGroup into generated task OwnerGroup
copy source Diagnosis linkage fields
avoid duplicate task creation using iteration + source diagnosis key
```

### Step 7 — Incident Verify Failed Loopback

For incident verification failure:

```text
increment ZIN-Iteration
set Stage = diagnose
trigger orchestration again
```

---

## 16. Do Not Break Existing SR / Change

Iteration must be backward-compatible.

```text
If ZIN-Iteration is missing:
    existing behavior remains unchanged

If ZIN-Iteration exists:
    include it in BlueBook / StateBook runtime comparison
```

---

## Final Design Principle

```text
Incident is loop-capable.
Requester observation stays on the parent Incident ticket.
Diagnoser input stays on child Diagnosis tickets.
Each failed verification creates a new investigation iteration.
Each iteration creates new child tickets.
Previous child tickets remain evidence.
BlueBook and StateBook must be iteration-aware.
Diagnosis is a first-class ticket type with GovernanceRole = DIAGNOSE.
Actionable diagnosis count drives downstream task count.
Source Diagnosis OwnerGroup drives downstream task OwnerGroup.
```

ERROR: OTOBO-CGI-25 Perl: 5.38.2 OS: linux Time: Wed Jul  8 08:13:46 2026

 Message: ZTSMBlueBookReader: Parsed records TicketID=214 BlueBook=165 Count=2 FirstBlueLevel=1

 RemoteAddress: 127.0.0.1
 RequestURI: /

 Traceback (6482):
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookReader::Run Line: 590
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader::Run Line: 727
   Module: Kernel::System::ProcessManagement::Process::ProcessTransition Line: 585
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 125
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 158
   Module: (eval) Line: 289
   Module: Kernel::System::EventHandler::EventHandler Line: 283
   Module: Kernel::System::EventHandler::EventHandlerTransaction Line: 380
   Module: Kernel::System::ObjectManager::ObjectEventsHandle Line: 461
   Module: Kernel::System::ObjectManager::ObjectsDiscard Line: 509
   Module: Kernel::System::ObjectManager::DESTROY Line: 679
   Module: (eval) Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 159
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 145
   Module: Plack::Middleware::HTTPExceptions::try {...}  Line: 20

ERROR: OTOBO-CGI-25 Perl: 5.38.2 OS: linux Time: Wed Jul  8 08:13:46 2026

 Message: ZTSMBlueBookReader: Evaluate record spawn TicketID=214 BlueBook=165 BlueLevel=1 Chapter=BR-001 Profile=59 Role=13 Type=Diagnosis Activity=Cloud Healthcheck & Diagnosis

 RemoteAddress: 127.0.0.1
 RequestURI: /

 Traceback (6482):
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookReader::Run Line: 628
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader::Run Line: 727
   Module: Kernel::System::ProcessManagement::Process::ProcessTransition Line: 585
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 125
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 158
   Module: (eval) Line: 289
   Module: Kernel::System::EventHandler::EventHandler Line: 283
   Module: Kernel::System::EventHandler::EventHandlerTransaction Line: 380
   Module: Kernel::System::ObjectManager::ObjectEventsHandle Line: 461
   Module: Kernel::System::ObjectManager::ObjectsDiscard Line: 509
   Module: Kernel::System::ObjectManager::DESTROY Line: 679
   Module: (eval) Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 159
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 145
   Module: Plack::Middleware::HTTPExceptions::try {...}  Line: 20

Odd number of elements in hash assignment at /opt/otobo/bin/psgi-bin/../../Kernel/System/ProcessManagement/TransitionAction/ZTSMBlueBookReader.pm line 341.
ERROR: OTOBO-CGI-25 Perl: 5.38.2 OS: linux Time: Wed Jul  8 08:13:46 2026

 Message: ZTSMBlueBookReader: Support profile owner group resolution TicketID=214 ChildTicketID=215 Profile=59 OwnerGroup=59

 RemoteAddress: 127.0.0.1
 RequestURI: /

 Traceback (6482):
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookReader::Run Line: 724
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader::Run Line: 727
   Module: Kernel::System::ProcessManagement::Process::ProcessTransition Line: 585
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 125
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 158
   Module: (eval) Line: 289
   Module: Kernel::System::EventHandler::EventHandler Line: 283
   Module: Kernel::System::EventHandler::EventHandlerTransaction Line: 380
   Module: Kernel::System::ObjectManager::ObjectEventsHandle Line: 461
   Module: Kernel::System::ObjectManager::ObjectsDiscard Line: 509
   Module: Kernel::System::ObjectManager::DESTROY Line: 679
   Module: (eval) Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 159
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 145
   Module: Plack::Middleware::HTTPExceptions::try {...}  Line: 20

Odd number of elements in hash assignment at /opt/otobo/bin/psgi-bin/../../Kernel/System/ProcessManagement/TransitionAction/ZTSMBlueBookReader.pm line 741.
ERROR: OTOBO-CGI-25 Perl: 5.38.2 OS: linux Time: Wed Jul  8 08:13:46 2026

 Message: ZTSMBlueBookReader: Evaluate record spawn TicketID=214 BlueBook=165 BlueLevel=1 Chapter=BR-002 Profile=58 Role=13 Type=Diagnosis Activity=Network Healthcheck & Diagnosis

 RemoteAddress: 127.0.0.1
 RequestURI: /

 Traceback (6482):
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookReader::Run Line: 628
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader::Run Line: 727
   Module: Kernel::System::ProcessManagement::Process::ProcessTransition Line: 585
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 125
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 158
   Module: (eval) Line: 289
   Module: Kernel::System::EventHandler::EventHandler Line: 283
   Module: Kernel::System::EventHandler::EventHandlerTransaction Line: 380
   Module: Kernel::System::ObjectManager::ObjectEventsHandle Line: 461
   Module: Kernel::System::ObjectManager::ObjectsDiscard Line: 509
   Module: Kernel::System::ObjectManager::DESTROY Line: 679
   Module: (eval) Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 159
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 145
   Module: Plack::Middleware::HTTPExceptions::try {...}  Line: 20

Odd number of elements in hash assignment at /opt/otobo/bin/psgi-bin/../../Kernel/System/ProcessManagement/TransitionAction/ZTSMBlueBookReader.pm line 341.
DBD::mysql::db do failed: Duplicate entry 'ZT6b18f4bf16a871a564821783498426' for key 'ticket_number_counter_uid' at /opt/otobo/bin/psgi-bin/../../Kernel/System/DB.pm line 621.
ERROR: OTOBO-CGI-25 Perl: 5.38.2 OS: linux Time: Wed Jul  8 08:13:46 2026

 Message: Duplicate entry 'ZT6b18f4bf16a871a564821783498426' for key 'ticket_number_counter_uid', SQL: '
            INSERT INTO ticket_number_counter
                (counter, counter_uid, create_time)
            VALUES
                (0, ?, ?)'

 RemoteAddress: 127.0.0.1
 RequestURI: /

 Traceback (6482):
   Module: Kernel::System::Ticket::Number::TESSERAIdentity::_ScopedTicketNumberCounterAdd Line: 316
   Module: Kernel::System::Ticket::Number::TESSERAIdentity::TicketNumberBuild Line: 57
   Module: Kernel::System::Ticket::NumberBase::TicketCreateNumber Line: 399
   Module: Kernel::System::Ticket::TicketCreateNumber Line: 280
   Module: Kernel::System::Ticket::TicketCreate Line: 587
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookReader::Run Line: 685
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader::Run Line: 727
   Module: Kernel::System::ProcessManagement::Process::ProcessTransition Line: 585
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 125
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 158
   Module: (eval) Line: 289
   Module: Kernel::System::EventHandler::EventHandler Line: 283
   Module: Kernel::System::EventHandler::EventHandlerTransaction Line: 380
   Module: Kernel::System::ObjectManager::ObjectEventsHandle Line: 461
   Module: Kernel::System::ObjectManager::ObjectsDiscard Line: 509
   Module: Kernel::System::ObjectManager::DESTROY Line: 679
   Module: (eval) Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 159
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 145
   Module: Plack::Middleware::HTTPExceptions::try {...}  Line: 20

DBD::mysql::db do failed: Column 'tn' cannot be null at /opt/otobo/bin/psgi-bin/../../Kernel/System/DB.pm line 621.
ERROR: OTOBO-CGI-25 Perl: 5.38.2 OS: linux Time: Wed Jul  8 08:13:46 2026

 Message: Column 'tn' cannot be null, SQL: '
            INSERT INTO ticket (tn, title, type_id, queue_id, ticket_lock_id,
                user_id, responsible_user_id, ticket_priority_id, ticket_state_id,
                escalation_time, escalation_update_time, escalation_response_time,
                escalation_solution_time, timeout, service_id, sla_id, until_time,
                archive_flag, create_time, create_by, change_time, change_by)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 0, 0, 0, ?, ?, 0, ?,
                '2026-07-08 08:13:46', ?, '2026-07-08 08:13:46', ?)'

 RemoteAddress: 127.0.0.1
 RequestURI: /

 Traceback (6482):
   Module: Kernel::System::Ticket::TicketCreate Line: 619
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookReader::Run Line: 685
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader::Run Line: 727
   Module: Kernel::System::ProcessManagement::Process::ProcessTransition Line: 585
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 125
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 158
   Module: (eval) Line: 289
   Module: Kernel::System::EventHandler::EventHandler Line: 283
   Module: Kernel::System::EventHandler::EventHandlerTransaction Line: 380
   Module: Kernel::System::ObjectManager::ObjectEventsHandle Line: 461
   Module: Kernel::System::ObjectManager::ObjectsDiscard Line: 509
   Module: Kernel::System::ObjectManager::DESTROY Line: 679
   Module: (eval) Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 159
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 145
   Module: Plack::Middleware::HTTPExceptions::try {...}  Line: 20

ERROR: OTOBO-CGI-25 Perl: 5.38.2 OS: linux Time: Wed Jul  8 08:13:46 2026

 Message: ZTSMBlueBookReader: TicketCreate failed ParentTicketID=214 BlueBook=165 BlueLevel=1 Chapter=BR-002 Type=Diagnosis RawType=493 Queue=IPC

 RemoteAddress: 127.0.0.1
 RequestURI: /

 Traceback (6482):
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookReader::Run Line: 701
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader::Run Line: 727
   Module: Kernel::System::ProcessManagement::Process::ProcessTransition Line: 585
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 125
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 158
   Module: (eval) Line: 289
   Module: Kernel::System::EventHandler::EventHandler Line: 283
   Module: Kernel::System::EventHandler::EventHandlerTransaction Line: 380
   Module: Kernel::System::ObjectManager::ObjectEventsHandle Line: 461
   Module: Kernel::System::ObjectManager::ObjectsDiscard Line: 509
   Module: Kernel::System::ObjectManager::DESTROY Line: 679
   Module: (eval) Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 159
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 145
   Module: Plack::Middleware::HTTPExceptions::try {...}  Line: 20

ERROR: OTOBO-CGI-25 Perl: 5.38.2 OS: linux Time: Wed Jul  8 08:13:46 2026

 Message: ZTSMBlueBookReader: BlueBook orchestration started TicketID=214 BlueBook=165 BlueLevel=1 Created=1

 RemoteAddress: 127.0.0.1
 RequestURI: /

 Traceback (6482):
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookReader::Run Line: 832
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader::Run Line: 727
   Module: Kernel::System::ProcessManagement::Process::ProcessTransition Line: 585
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 125
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 158
   Module: (eval) Line: 289
   Module: Kernel::System::EventHandler::EventHandler Line: 283
   Module: Kernel::System::EventHandler::EventHandlerTransaction Line: 380
   Module: Kernel::System::ObjectManager::ObjectEventsHandle Line: 461
   Module: Kernel::System::ObjectManager::ObjectsDiscard Line: 509
   Module: Kernel::System::ObjectManager::DESTROY Line: 679
   Module: (eval) Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 159
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 145
   Module: Plack::Middleware::HTTPExceptions::try {...}  Line: 20
# TESSERA English YAML Script Engine Next Increment

- Add `MELTObject` as a native `SEARCH FOR` object type when MELT is installed, while retaining fail-closed behavior when it is absent.
- Add class-definition-backed authoring validation so every `WHERE` and `RETURN FIELD` name is verified against the selected exported class before execution.
- Make reference comparisons object-aware. For example, authored `ZTicket-Parent EQUALS CURRENT TICKET` must compare Ticket references semantically; scripts must not expose or require `TICKET.TicketID` merely because the Ticket reference driver persists an internal identifier.
- Use `TicketType` as the canonical TESSERA ticket property in authored scripts. The ScriptEngine adapter maps `TicketType` to OTOBO's native `Type`/`Types` APIs internally; authors must not use the backend search parameter name as if it were a TESSERA field.
- Add walkable reference paths with fixed traversal and cycle-safe recursive traversal using explicit maximum depth.
- Add bounded `FOR EACH`, collection `SELECT`, and `ALL` / `ANY` / `NONE` quantifiers without permitting unrestricted writes inside iteration.
- Add declared inputs, local `STATIC`/runtime variables, typed collections, and return-type verification against the actual returned object class.
- Add a future-safe `CALL` capability for registered external connectors. Define connector manifests, typed request/response schemas, authentication references, permission scopes, timeouts, retry/idempotency rules, secret redaction, audit evidence, and fail-closed error results before enabling any external endpoint.
- Keep `CALL` declarative and allowlisted; scripts must never supply arbitrary URLs, credentials, Perl, SQL, shell commands, or dynamically selected runtime modules.
- Migrate the remaining permission consumers behind the synchronous ScriptEngine-backed GovernanceRole resolver. GenericAgent and TransitionAction RoleDirector now share its typed return contract.
- Generalize the implemented bounded evidence-assignment operation into composable `FOR EACH` and collection `SELECT` grammar. Preserve the 0.0.4 behavior for semantic parent references, current/previous/empty iteration selection, typed assignment DTOs, and deduplication.
- Extend the implemented simple Control cycle frequencies with calendar ranges, named business calendars, calendar-exact month/year arithmetic, and explicit timezone semantics.
- Add catalog-name-to-score mappings without exposing GeneralCatalog IDs in authored policy or evidence.
- Add YAML parser diagnostics with source line/column and authoring-time validation on GovernanceRole and ControlObjective save.
- Extend failure field-assignment authoring with line/column diagnostics and richer calculated-value functions while retaining explicit `ZRM-CreateRisk` gating.
- Add focused automated tests for native backend permissions, invalid class fields, temporal month-end behavior, duplicate object-name ambiguity, traversal cycles, collection coercion, and GenericAgent article deduplication.

## Security advisory risk conversion follow-up

Security advisory selection-to-RiskStatement/ControlObjective grouping is implemented through ST-5 in0.0.142. Remaining design: impact/recommendation transfer and exploitability questionnaire-to-score mapping, then a vulnerability-specific calculation through the selected Framework. General ALL/ANY conditions remain a future ScriptEngine increment; do not evaluate customer-authored scripts during advisory submission. Portal capability is reserved TESSERA::CMDB::SECOPS, separate from CMDB::READ. Verify live install and customer SupportAssignments before treating portal availability as accepted.

## Vulnerability framework follow-up — ST-5 implemented 2026-10-09

ST-5 executable discovery/evaluation/group creation is deployed in0.0.142 and live verified. See PROJECT_STATUS.md and docs/vulnerability-policy-authoring.md. Remaining design: vulnerability-specific Framework likelihood/impact formula (user deferred), and optional recovery/downgrade/shared-risk resolution policy. Preserve current Application-context RMF scorer and workflow until that calculation is confirmed.

2026-10-09 update: vulnerability questionnaire Framework calculation is implemented/deployed in0.0.144. Both products, Framework scales, two ceiling stages and minimum1 confirmed. Remaining next: verify user-created live assessment evidence and consider per-CVE questionnaire scope/prefill; reusable AI authoring MD remains paused. See PROJECT_STATUS.md.

## Monday 2026-10-12 — full YAML authoring Markdown

User confirmed: save and commit current implementation now; begin the full portable Markdown authoring guide on Monday. Guide must cover actual exported classes/fields, grammar, syntax, supported operations, validation, examples and intention-to-YAML instructions for organization users, Gemini and ChatGPT projects. Include questionnaire and Application scoring, evidence,3800-character field limit and tested scalar anchors. Do not generate the full guide before Monday. Latest live Framework save verified; new live assessment evidence remains to verify.


## 2026-10-12 AOE security foundation priority

Parser/runtime hardening is prepared in0.0.147; completed details in PROJECT_STATUS.md and docs/policy-script-security-foundation.md. Architect is creating required fields/objects; integrate only verified export names. Next: typed capability/transitive effect registry, immutable submission/review/publication versions, independent reviewer authority, backend save/import/API/direct-field activation gate and runtime identity/capability/record scope checks. Negative bypass tests must pass before privileged connectors or AOE execution. Full AOE design remains pending.


## 2026-10-12 Protected permission objects — confirmed review flow

- User identifies SupportAssignment and ContractEntitlement as protected permission-affecting objects. Exact reserved capabilities TESSERA::SYSTEM and TESSERA::SECURITY may change these directly without mandatory security review, within separately authorized target scope. Other identities must submit a review request; no protected mutation while pending. This bypass applies to these two objects, not arbitrary sensitive effects. Reserved TESSERA roles never execute resolver scripts.
- Initial review request is a restricted backend record managed through the agent portal, not an ordinary customer/frontend ticket. Agent release publishes a linked frontend security-review ticket; release alone is not security approval or authorization to execute.
- TESSERA::SECURITY is the corporate security review capability. Its review ticket scope must be explicitly assigned; it does not grant blanket operational/customer ticket visibility. Approval remains independent of authorship, even if author also has reviewer capability. Direct-bypass actions still require audit and runtime target authorization.
- Pending record, released ticket, decision and runtime attempt must link the same immutable definition/version/hash, proposed changes, author and target scope. Changed content invalidates prior release/approval. Deny alternate save/import/API/direct-field bypass paths. Deduplicate release so one request produces one review ticket.
- Exact agent release capability, review service/Book routing, new schema names and corporate security SupportAssignments remain unconfirmed. Do not invent fields or hardcode a queue. This is confirmed design, not implemented runtime. No package changes or live role/object creation in this update.


## 2026-10-12 Reserved security capability assignment boundary

- User confirms TESSERA::SYSTEM and TESSERA::SECURITY may be assigned only through the backend agent portal. Apply to granting, changing or revoking assignments carrying either capability; protect equivalent indirect assignment paths.
- Enforce at backend assignment write boundaries, not UI hiding. Customer portal, automation/YAML, import/API and direct-module writes cannot grant these capabilities through an alternate path. Agent portal access alone is insufficient: an independently authorized role-management actor and authenticated request context are required. Do not trust a caller-supplied Source or portal flag as authorization.
- Capability use and capability assignment are distinct permissions. Possession of either capability does not automatically authorize granting it to self or others. Their direct-change exception for SupportAssignment/ContractEntitlement cannot bypass this more specific reserved-capability assignment restriction.
- Audit actor, target account, capability, scope, before/after and decision. Exact role-management authorization remains to be confirmed; deny ambiguous authorization. Design recorded only; runtime enforcement remains pending.


## 2026-10-12 Agent security 2FA and custom email initiative

- User requests adding reserved-role security and proposes special agent-portal2FA plus new custom email engine: copy/save images and rich content, portal links returning to intended context after login/futureSSO. Requirements and source-aligned implementation sequence recorded in docs/agent-security-and-portal-email-design.md.
- Discovery: existing Auth.pm/TOTP adapter supports agent login factors but lacks the proposed operation-bound fresh proof. Email.pm already supports HTML/plain-text and CID inline images; reuse transport underneath new authoring/rendering/template layer. No email or MFA configuration changed.
- Reserved-role protection must cover native object/version/direct-field writes and GovernanceRole rename/creation paths, not just portal form. Exact role-management actor still requires user decision; no all-agent/self-assignment assumption. Ordinary assignment compatibility requires tests before claiming no effects.
- Pending clarifications: role administrator, MFA action scope and first email example. Next: implement shared backend authorization after these choices; then action-bound MFA and image-capable editor/template delivery with registered portal deep links. Email links navigate only; scanner/GET must never mutate; authenticated explicit portal action and fresh permissions required. No new schema names invented, no roles granted or mail sent. This update is design/discovery, not enforcement deployment; package147 remains prepared.
## 2026-10-13 External automation completion contract

Implemented in package158: durable execution row, OTOBO GenericInterface outbound task, idempotently installed provider callback web service, exit-code branching, registered continuation, timeout reconciliation and ControlObjective handler. Recorded in PROJECT_STATUS.md and docs/async-execution-contract.md. Remaining integration: configure a requester web service for each external system, attach a trusted workflow step to `AsyncExecution->Start`, and verify a live remote callback. Keep arbitrary YAML external effects disabled until the separate AOE publication/capability gate is implemented. After 158 installation, deploy corrected `Frontend::Module###AgentControlObjectiveRun` and verify the action in live SysConfig.








# Agent New setup and Central — 2026-10-19

Requested agent entry point: ticket numbering reset/existing SysConfig prefix prompt; CSR create/complete/renew; CMDB remove/reset; Central automatic missing-human identity creation without credentials or login. Design and pending decisions: docs/agent-system-setup-design.md. Clarify CSR/Central meaning, ticket reset semantics, CMDB scope and trusted identity source before dependent implementation. Never execute reset during install/upgrade or grant login/capabilities through provisioning. No runtime/package changes made.

