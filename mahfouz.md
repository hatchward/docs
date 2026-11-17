# Mahfouz tickets

Connect Mahfouz in **Integrations**, then choose a Mahfouz database as the project's
board in the project editor. Each row of the database is a ticket. Connecting an
account or importing tickets does not start a runner. Execution requires an
explicitly published policy.

## Connect

Mahfouz integrations need a paid Mahfouz plan, Pro or Max. On Free, Mahfouz's consent
page says integrations aren't available and makes no grant.

Mahfouz's consent page asks which repositories to share. Each repository is a vault,
and Hatchward reaches only the vaults you pick there. Pick every vault whose databases
you want as boards. You can connect several Mahfouz accounts; each connection is the
Mahfouz account you signed in with, and one Mahfouz account can be connected to only
one Hatchward account.

## Choose a database

The board picker lists every database in every vault the connection reaches, except
vaults your Mahfouz plan has paused. Rows are the database's direct child notes, and
their frontmatter attributes are the ticket's fields:

| Mahfouz attribute | Use in Hatchward |
| --- | --- |
| The row's title | The ticket title |
| Select | The status: map its options to Hatchward states |
| Multi-select | Labels |
| Relation to the People database | Assignees |
| Text, email, phone, number, checkbox, URL, date | Fields for filters and routing |

Colour, font, media, rollups and relations to other databases can't be mapped.

A select option has no separate id in Mahfouz: its value is its text. Renaming an
option in Mahfouz changes it on every row, so a mapping that names the old value no
longer validates. The next publish or sync reports it; map the new value and publish.

## Import and execution

Publish the board and mappings, then use **Sync now** for one import or enable
recurring import. The first import reads every row; later imports read only the rows
changed or removed since the last one, and a removed row's ticket becomes ineligible.

Recurring imports run every 30 minutes, not every 5 as for Notion. Each import keeps
the vault's Mahfouz container running, which counts against the Mahfouz plan's
monthly container hours: polling a vault every 5 minutes uses about 720 hours a
month, more than Pro's 300. Every 30 minutes uses about 240.

Execution requires a fresh completed import. For a Mahfouz board the maximum source
age defaults to 3,600 seconds, so a board synced every 30 minutes stays fresh. Keep
it above the sync interval. Everything else about execution works as it does for
[Notion](notion.md#import-and-execution): **Import only** collects tickets without
assigning work, and an enabled project still needs an enrolled, connected, compatible
runner and available capacity.

## Row changes and comments

An assignment can change the status, add an assignee or a label, replace or append
to the row's body, and comment, within the published project's allowed actions.
Changes go through Hatchward with the assignment's authorization; runners never hold
Mahfouz credentials.

Every write names the row version Hatchward read. If someone changed the row since,
Mahfouz refuses the write, the row keeps their change, and the action needs
attention. Hatchward never overwrites a concurrent edit.

Every write also carries a retry key. If Hatchward can't tell whether a write landed,
it resends the same request with the same key within a day, and Mahfouz makes the
write at most once. After that it reads the row back instead. Each comment ends with
the run and operation it came from, so a comment can be found again.

Body changes replace or extend the row's Markdown body. A change to the first heading
renames the row in Mahfouz, so Hatchward doesn't edit titles, and it appends only at
the end of the body.

## A vault removed from the connection

Removing a vault from Hatchward's access in Mahfouz breaks the imports of boards in
that vault: their projects report lost permission. Mahfouz's consent page can't be
opened with a vault already picked, so reconnect Mahfouz from **Integrations** and,
on the consent page, pick every vault your boards are in. Reconnecting the same
Mahfouz account repairs the existing connection.

## Operator configuration

Hatchward runs one environment, production, and connects to Mahfouz's production
platform. Register Hatchward's OAuth client once, after Mahfouz's production release
includes its integration API:

```bash
bun run apps/api/scripts/register-mahfouz-client.ts --console-origin https://dash.hatchward.dev
```

The script registers `https://dash.hatchward.dev/integrations/callback/mahfouz` with
the scopes `vaults:read vaults:write`, and prints the client id, and the secret if
Mahfouz issued one. Registering again creates a new client id, and grants belong to a
client id, so run it once. Store the values in Bitwarden Secrets Manager and provision
Worker secrets through the approved deployment process.

| Binding | Value |
| --- | --- |
| `MAHFOUZ_OAUTH_CLIENT_ID_V1` | The registered client id. Without it, Mahfouz isn't offered. |
| `MAHFOUZ_OAUTH_CLIENT_SECRET_V1` | The client secret, when Mahfouz issued one |
| `MAHFOUZ_SYNC_INTERVAL_SECONDS` | Optional. Seconds between recurring imports, 300 to 3,000; 1,800 when unset |

`MAHFOUZ_PLATFORM_ORIGIN`, `MAHFOUZ_API_ORIGIN` and `MAHFOUZ_PERMALINK_ORIGIN` override
Mahfouz's production origins (`https://platform.mahfouz.app`, `https://api.mahfouz.app`
and `https://l.mahfouz.app`). Leave them unset in production.

`MAHFOUZ_OAUTH_CLIENT_ID_V1` is also the launch switch: until it is set, no one is
offered Mahfouz, and unsetting it withdraws the offer.

Mahfouz deletes a registration that no token request has used for 30 days. Every
Mahfouz connection then reports a configuration problem, and the Datadog monitor
**Mahfouz client registration expired** fires. Register again, rotate the client id
(and secret), and ask people to reconnect: grants belong to a client id, so the old
ones don't carry over.

Mahfouz has no token revocation endpoint. Disconnecting in Hatchward deletes its
stored credential at once and records the provider revocation as unavailable; to end
the grant in Mahfouz too, remove Hatchward under **Settings → Integrations** in
Mahfouz.

## Verify production

There is no staging environment, so the first end-to-end check runs in production.
Set the client id, then, before announcing Mahfouz, use a test account on a paid
Mahfouz plan with a disposable vault and grant Hatchward that vault. Run the canary:

```bash
bun run apps/api/scripts/mahfouz-canary.ts --refresh-token-out <file>
```

It reads `MAHFOUZ_CANARY_REFRESH_TOKEN`, `MAHFOUZ_CANARY_RESOURCE` (`<vault>:<database>`)
and `MAHFOUZ_CANARY_ROW` with the bindings above. It refreshes the grant, checks the
account and vault, reads the board, writes the canary row and comments, and reads both
back. Mahfouz rotates the refresh token on every use, so the script writes the next one
to the file before anything else: store it before the next run.

The canary does not replace a full check: connect through the console, publish a
board, import, run an assignment with an enrolled test runner, and confirm its status
change and comment in Mahfouz.
