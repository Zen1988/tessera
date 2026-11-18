# Mounted configuration

Config.pm is environment-owned and mounted separately by Secret in this deployment. Leave that Secret unchanged when Config.pm is unchanged. Do not replace it with another host's sample.

The tessera-generated-config PVC mounts /opt/otobo/Kernel/Config/Files and can hide newer image XML. The controlled package/configure flow must reconcile package XML and regenerate/deploy this site's native configuration. Web and daemon workers need matching code/configuration before traffic resumes.

A coordinated copy through a current web pod into Files/XML writes the shared PVC. A host folder such as /opt/tessera/Config/Files/XML is only staging unless the manifest explicitly mounts it.

Do not transfer generated ZZZAAuto.pm, ZZZACL.pm or ZZZProcessManagement.pm from another environment. Do not replace the entire Config directory.

New XML since 0.1.0 includes TESSERAUtilities.xml and TESSERAChangeClassification.xml. Base 0.1.5 also changes TESSERACustomerNetworkSimulation.xml descriptions, retaining legacy Bindings for saved analyses. Prefer the matching upgrade bundle to manual copies. Review custom file overrides and verify effective settings rather than assuming a restart imports definitions.


Application Navis is a native GO Dynamic Field/class-page addition installed by the OPM bootstrap, not an XML-only change. Run the normal package upgrade; copying XML cannot create it. Existing Application layouts and field values are preserved, with incompatible Navis names/pages rejected for review.
