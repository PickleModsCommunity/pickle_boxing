# pickle_boxing v1.1.2

## Fixes

- Use server-observed damage for hits and bound knockout recovery and timeouts.
- Prevent canceled match stages from continuing and validate fighter profiles and sessions.
- Record match results once, including ties and forfeits, with recovery for pending results.
- Improve fighter, camera and scene cleanup, and move photo upload credentials to server-only configuration.
- Migrate persistence to oxmysql and tighten UI text handling and external asset integrity.

## Upgrade notes

- Requires oxmysql and ox_lib; mysql-async is no longer the persistence dependency.
- Start the selected ESX/QBCore framework before boxing and restart boxing after a framework restart. Dynamic framework rebinding remains unimplemented (BX-023).
- For existing latin1 databases, back up the database and apply _INSTALL/sql/utf8_migration.sql.
- Configure screenshot upload credentials in server_config.lua when using fighter photos.

## Package and validation

- The ZIP contains one pickle_boxing/ folder with the complete resource, installation files, license and runtime NUI assets where applicable. Unbuilt web/ sources, node_modules/ and Git metadata are excluded.
- Required local NUI scripts and stylesheets were checked before packaging. Prior remediation validation passed targeted mocked regressions and Lua/JavaScript syntax checks; this is not a live FiveM integration test.
- Test the resource with your installed frameworks, inventory, database and other integrations before use. Transactions spanning framework persistence, SQL and local KVP still have crash-recovery boundaries.

Source: [audit remediation PR #2](https://github.com/PickleModsCommunity/pickle_boxing/pull/2), branch `fix/audit-remediation`. This release includes the PR changes without merging the PR.
