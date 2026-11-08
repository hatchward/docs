# Notion tickets

Connect Notion in **Integrations**, then choose the connection and ticket source in
the project editor. Connecting a workspace or importing tickets does not start a
runner. Execution requires an explicitly published policy.

## Choose a source

Notion's OAuth page picker controls which content the connection can access. Share
the source you intend to use; the grant does not provide unrestricted access to
the workspace. See [Notion's public connection guide](https://developers.notion.com/guides/get-started/public-connections).

- **Database:** choose its underlying data source. Each row is a ticket. Map the
  title and status/select property, eligible status options, routing and permitted
  transition targets. A database with several data sources requires an explicit
  choice.
- **Page:** each direct child page is a ticket. The container, to-do blocks and
  nested descendants are not additional tickets. Child pages expose the synthetic
  source state `imported`; they do not have a fabricated Notion status column.

Search results can be incomplete. Paste a Notion URL or ID to resolve a source
directly, then preview tickets before publishing. Unsupported or omitted content
is identified in the imported snapshot.

## Import and execution

Publish the source and mappings, then use **Sync now** for one import or enable
recurring import. Recurring imports normally run every five minutes; failures and
provider throttling can delay them. The project shows import progress, the last
successful import and errors.

In the project's agents and execution settings, keep **Import only** to collect
tickets without assigning work, or explicitly enable runner execution and publish
the change. Configure the repository, agent image, eligibility and routing first.
An enabled project still requires an enrolled, connected, compatible runner and
available project, account and runner capacity.

Execution requires a completed scan of the current published source. The maximum
source age defaults to 600 seconds and can be set from 60 to 3,600 seconds. A new
scan blocks new admission until it completes; reconnecting or changing the source
does not reuse an old successful scan as proof of freshness.

Pausing recurring import leaves a still-fresh completed snapshot usable for
execution. To stop new assignments, publish **Import only**. Already accepted or
running assignments retain their existing lifecycle. Ordinary edits and resyncs
do not rerun a completed ticket.

Projects are separate execution domains. Enabling two projects against the same
Notion source can run the same ticket in both projects; there is no cross-project
deduplication. Review other source bindings before enabling execution.

The execution panel reports the published policy and scheduler status. A fresh
source does not guarantee runner availability. Follow the reported source,
membership, compatibility, capacity or account restriction before retrying.

## Page changes and comments

The published project's allowed actions limit what an assignment may request:
status transitions, comments, existing title/block updates and content appends.
Plain child-page sources do not support status-column transitions. Provider
credentials stay in the hosted service, and actions use assignment authorization.

Changes are checked against the observed source, but Notion writes are not an
atomic compare-and-swap with human edits. A conflict requires a fresh observation.
An uncertain comment or append is reconciled rather than blindly repeated; an
unresolved outcome is not proof that the write failed or succeeded.

## Operator configuration

Create a Notion public OAuth connection and register
`<HATCHWARD_CONSOLE_ORIGIN>/integrations/callback/notion` as a redirect URI. Enable these
[Notion capabilities](https://developers.notion.com/reference/capabilities):

| Capability | Hatchward use |
| --- | --- |
| Read content | Discover sources and import tickets |
| Update content | Change status, titles and existing blocks |
| Insert content | Append blocks to existing ticket pages |
| Insert comments | Add assignment-attributed comments |
| Read comments | Reconcile uncertain comment delivery |

User email access is not required. Changing connection capabilities requires users
to authorize the connection again. Follow Notion's
[OAuth authorization guide](https://developers.notion.com/guides/get-started/authorization).

Configure these Worker bindings for the intended environment:

| Binding | Value |
| --- | --- |
| `HATCHWARD_CONSOLE_ORIGIN` | Deployed console origin used for the callback |
| `NOTION_OAUTH_CLIENT_ID_V1` | Public connection client ID |
| `NOTION_OAUTH_CLIENT_SECRET_V1` | Public connection client secret |
| `HATCHWARD_INTEGRATION_CREDENTIAL_KEY_CURRENT_VERSION` | Active custody key version, `1` or `2` |
| `HATCHWARD_INTEGRATION_CREDENTIAL_KEY_V1` / `HATCHWARD_INTEGRATION_CREDENTIAL_KEY_V2` | Required key versions: 32-byte AES keys encoded as unpadded base64url |
| `HATCHWARD_NOTION_BOARD_ACTIONS` | `transition,comment,update_content,append_content`, narrowed only deliberately |

An empty action binding advertises no write actions. Keep previous custody keys
available while stored credentials still need them. Store real credentials in
Bitwarden Secrets Manager and provision Worker secrets through the approved
deployment process; do not put values in Git or individual GitHub Actions secrets.

## Verify an environment

Use a disposable, explicitly authorized Notion source. Connect through OAuth,
select and publish it, import, and check the source identity and ticket count.
Enable execution only with an enrolled test runner and a suitable agent image.
Verify a terminal result, capacity release, a mapped transition, title/block
update, append and comment by reading Notion back. Resync and confirm completed
work does not restart, then disconnect the disposable connection.

Fixture-based Worker and browser checks do not replace this live verification.
A real runner check must also prove its runtime enforces the configured resource
ceilings; accepting a Docker flag alone is insufficient evidence.
