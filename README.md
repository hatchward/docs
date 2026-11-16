# hatchward.dev

The website and documentation for [hatchward](https://hatchward.dev), served by
GitHub Pages from `main` (Jekyll, the build GitHub Pages runs itself). A change
is live a minute or so after it merges.

## Files written by hatchward/core

hatchward/core's `publish-docs` workflow writes these files. Don't edit them
here: the next publish overwrites them, and the copy in core is the one that is
reviewed and tested.

| File | Source in hatchward/core | Published |
|---|---|---|
| `errors.md` | generated from the CLI's error registry | from the latest release |
| `install.sh` | `etc/site/install.sh` | from the latest release |
| `license.md` | generated from `LICENSE` | when `LICENSE` changes on `main` |
| `_includes/changelog.md` | `CHANGELOG.md`, through `bin/public-changelog` | when `CHANGELOG.md` changes on `main` |

To change one of them, open a pull request in hatchward/core.

## Page addresses

A page's canonical address is its `.html` file: `https://hatchward.dev/errors.html`.
Link to that form. GitHub Pages also serves it without the extension
(`/errors`), and `/errors/` redirects to it, keeping any `#section`. The
redirects are listed under `defaults:` in `_config.yml`, so a new page that
should answer at `/<page>/` needs an entry there.

## Everything else

The rest of the site is maintained here:

- Pages are Markdown at the root (`install.md`, `notion.md`, …) plus `index.html`.
- Navigation and its order live in `_data/nav.yml`. A page that isn't listed there
  is still published, just not linked.
- Layouts, includes and styles are in `_layouts/`, `_includes/` and `assets/`.

## Preview locally

```sh
bundle install
bundle exec jekyll serve
```

`Gemfile` is for local preview only; GitHub Pages builds with its own pinned
`github-pages` gem.
