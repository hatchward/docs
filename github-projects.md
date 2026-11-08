# GitHub Projects

Connect an organization-owned GitHub Project (Projects v2) from Integrations,
complete GitHub installation and user authorization, then select the connection
in the project wizard. The authorizing GitHub user must be an active owner of
the installation's organization. Personal Projects need a separate authorization
flow and are outside this integration.

Select a Project, map its single-select status field, choose eligible statuses,
and preview the imported items before publishing. Project URLs can be pasted
directly. Status choices use GitHub option IDs, so identical labels remain
distinct. Preview does not publish a revision or start work.

Imports include issues, pull requests, and draft issues. Inaccessible content
is hidden; archived items, pull requests, and items without an eligible mapped
status remain ineligible for scheduling. Keep agent dispatch disabled when the
project should only import tickets. Publishing and synchronization do not
enable an unfinished runner execution path.

Published projects provide Sync now, Pause, and Resume controls. Polling imports
changes in bounded pages, resumes interrupted scans, and verifies missing
memberships before removing them. A disconnected connection stops new provider
access; reconnecting the same installation preserves the connection identity.

Hosted assignments can request enabled, supported updates: project status,
title and Markdown body, and issue or pull-request comments. Draft issues do
not support comments. Permission checks apply to each item and action, and a
readable connection may have no write capabilities. Body edits require a
complete snapshot of at most 65,536 UTF-8 bytes and the expected hash. Refresh
the assignment content before editing a changed snapshot.

GitHub does not expose an atomic expected-hash condition for these writes.
Hatchward checks the current value before writing and reads the result back,
but a human edit between those requests can still race. An uncertain comment
delivery is retained for reconciliation and is not automatically reposted.

## Operator configuration

Configure a GitHub App with organization Members read access and Projects read
access. Projects write enables project status and draft title/body updates.
Repository Issues and Pull requests permissions control their corresponding
content edits and comments. Grant access to repositories whose items should be
visible. Use the console integration callback `/integrations/callback/github`
under the deployment's `HATCHWARD_CONSOLE_ORIGIN` for both setup and user authorization.

The API requires these environment bindings:

| Binding | Value |
| --- | --- |
| `GITHUB_APP_ID_V1` | GitHub App ID |
| `GITHUB_APP_SLUG_V1` | GitHub App slug |
| `GITHUB_APP_CLIENT_ID_V1` | GitHub App OAuth client ID |
| `GITHUB_APP_CLIENT_SECRET_V1` | GitHub App OAuth client secret |
| `GITHUB_APP_PRIVATE_KEY_V1` | PEM signing key |
| `HATCHWARD_INTEGRATION_CREDENTIAL_KEY_CURRENT_VERSION` | Active custody-key version, initially `1` |
| `HATCHWARD_INTEGRATION_CREDENTIAL_KEY_V1` | Base64url-encoded 32-byte custody key |

Real secrets belong in environment-scoped Bitwarden Secrets Manager entries,
then Worker secret bindings. Do not put values in repository files, command-line
arguments, browser configuration, or individual GitHub Actions secrets. Missing
configuration keeps connection endpoints unavailable. Existing GitHub sign-in
credentials are a separate integration and do not substitute for App credentials.

Apply D1 migrations `0012` (board runtime), `0013` (temporary-token cleanup),
and `0014` (shared scan budget), then run the schema assertion before
deploying the API. Existing scheduler Durable Objects install their additive
tables on initialization. The provider-operation queue also carries credential-free
sync pointers; the existing scheduled handler repairs interrupted source changes
and enqueues due imports. Webhooks are not required for this polling integration.

Before production enablement, exercise an organization installation, owner
verification, private-repository item visibility, an import, each enabled update,
permission loss, and reconnect against a dedicated test Project. Local HTTP
fixtures verify the integration code but do not verify the registered App or
live GitHub permissions.
