# TAO checkpoint, 2026-11-25

TAO targets AWX 24.6.1 on Rocky Linux 10 with TESSERA branding. The branded Vite and Lingui 4 application candidate built successfully. Installed template links and collected static files were checked. The earlier Lingui 4 Jest run covered 544 passing suites and one skipped suite, including a focused retry with the Workflow Output Navigation ref fix.

The current ESLint 10 checkout is `awx-vite-eslint10` on the build host. Its full and production npm audits previously exited zero for lockfile SHA-256 `6393786e2a9c0c3140c79d18cfc58bd77ef68410cb1df6373bcc78e7b9e8a1e9`. Host lint verified 262 configured rules and the Vite styled-components CSS prop transform. The latest confirmed result is 22 errors and zero warnings after the ScheduleDetail OUIA, autofix, unused catch binding and Jest asyncFlush changes.

The reviewed autofix is in `outputs/TESSERA-TAO-ESLint-Autofix-r1.patch`. On the build host, the asyncFlush Promise executor now uses a block body and still calls `setImmediate(resolve)`.

Start the next session by applying `vite/fix-tao-import-cycles.py` to the ESLint 10 checkout and rerunning `vite/check-tao-eslint10.sh`. The two direct imports are expected to clear nine cycle reports. Then tighten the 13 remaining PropTypes declarations against their call sites.

Rerun regression tests for the updated checkout, including Schedule, Credential Plugins and Job Output. Final runtime image assembly, OS and Python scans, browser acceptance and operator deployment are pending.
