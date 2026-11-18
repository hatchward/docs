# GitHub Projects

Connect GitHub in **Integrations**, then choose an organization's GitHub Project
(Projects v2) as the project's board in the project wizard. Each item in the Project is
a ticket. Publishing a board and syncing it import tickets; they don't start work on
their own.

## Connect

Only Projects owned by an organization can be connected. Personal Projects aren't
supported.

Connecting installs Hatchward's GitHub App on the organization and then asks you to
authorize it. The GitHub user who authorizes must be an active owner of that
organization.

Disconnecting stops any new access to GitHub. Reconnecting the same
installation repairs the existing connection rather than creating a new one.

## Choose a project

Select a Project, or paste its URL. Then:

1. Map the Project's single-select status field to Hatchward states.
2. Choose which statuses make an item eligible for work.
3. Preview the items Hatchward would import, then publish.

Status options are matched by GitHub's option id, not their label, so two options with
the same name stay distinct. The preview doesn't publish anything or start work.

## What is imported

Hatchward imports the Project's issues, pull requests and draft issues.

| Item | Imported as |
| --- | --- |
| An issue with an eligible status | An eligible ticket |
| A draft issue with an eligible status | An eligible ticket |
| A pull request | A ticket that is never eligible |
| An archived item | A ticket that is never eligible |
| An item without an eligible status | A ticket that is not eligible |
| An item in a repository the App can't read | Hidden |

## Import and sync

A published project has **Sync now**, **Pause** and **Resume**. Hatchward polls the
Project for changes; it doesn't need webhooks. Each import reads a bounded number of
items at a time and picks up where an interrupted one stopped. An item that seems to be
missing is checked again before its ticket is removed.

To collect tickets without assigning any work, keep agent dispatch disabled for the
project.

## Item changes and comments

An assignment can ask Hatchward to:

- change the item's status in the Project
- change its title or Markdown body
- comment on an issue or pull request

Draft issues can't take comments. Each change is checked against the permissions the
connection has for that item, and a connection can be able to read a Project without
being able to change anything in it.

A body change sends the whole new body, at most 65,536 bytes of UTF-8, together with a
hash of the body the assignment started from. If the body has changed since, refresh
the assignment's content before editing it again.

GitHub has no way to make a write conditional on the current value. Hatchward reads the
current value, writes, then reads the result back, but a person editing the item
between those steps can still collide with the change. If Hatchward can't tell whether a
comment was posted, it keeps the comment to reconcile later and doesn't post it again
by itself.

## Operator configuration

Register a GitHub App for Hatchward with these permissions:

| Permission | Access | What it allows |
| --- | --- | --- |
| Organization: Members | Read | Checking that the authorizing user owns the organization |
| Organization: Projects | Read | Reading Projects and their items |
| Organization: Projects | Write | Status changes, and title and body changes to draft issues |
| Repository: Issues | Read; write for changes | Title, body and comment changes on issues |
| Repository: Pull requests | Read; write for changes | Title, body and comment changes on pull requests |

Give the App access to every repository whose items should be visible. Use
`/integrations/callback/github` on the console's origin (`HATCHWARD_CONSOLE_ORIGIN`) as
the callback for both installation and user authorization.

The API needs these bindings:

| Binding | Value |
| --- | --- |
| `GITHUB_APP_ID_V1` | The GitHub App's id |
| `GITHUB_APP_SLUG_V1` | The GitHub App's slug |
| `GITHUB_APP_CLIENT_ID_V1` | The App's OAuth client id |
| `GITHUB_APP_CLIENT_SECRET_V1` | The App's OAuth client secret |
| `GITHUB_APP_PRIVATE_KEY_V1` | The App's PEM signing key |
| `HATCHWARD_INTEGRATION_CREDENTIAL_KEY_CURRENT_VERSION` | The active credential key version, `1` to start |
| `HATCHWARD_INTEGRATION_CREDENTIAL_KEY_V1` | A 32-byte key, base64url-encoded |

Until they are set, GitHub Projects can't be connected. Store the values in Bitwarden
Secrets Manager and provision Worker secrets through the approved deployment process.
Never put them in repository files, command-line arguments, browser configuration or
GitHub Actions secrets of their own.

Signing in to Hatchward with GitHub is a separate integration: its credentials can't
stand in for the App's.

## Verify before enabling

Before turning GitHub Projects on for everyone, connect a dedicated test Project and
check each of these:

- installing the App on an organization
- the organization-owner check
- an item from a private repository
- an import
- each change an assignment can make
- removing the App's access, then reconnecting

Local test fixtures check Hatchward's code, not the registered App or GitHub's live
permissions.
