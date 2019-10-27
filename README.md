# noprs

GitHub webhook for closing all new GitHub PRs with a custom message.

## Motivation

GitHub does not support [deactivating pull requests][dear-github #84].
However, some organization do not want to use the GitHub PR feature and
only use GitHub as a read-only git mirror.

Inspired by [PRBot][PRBot github], used in the GitHub
[Linux repository][linux github], this repository provides an automation
for closing all new pull requests. It differs from PRBot in the
following ways:

1. It uses [GitHub webhooks][github webhooks] and does not require a cronjob.
2. It optionally closes the GitHub PR in addition to adding a configurable comment.
3. It is written in [hy][hy homepage].

## Installation

`noprs` has the following dependencies:

1. [PyGithub][pygithub homepage]
2. [hy][hy homepage]

After the dependencies have been installed, the script can be invoked
directly from the repository. If desired, it can also manually be copied
to an element in `$PATH` as an executable script.

## Usage

`noprs` is configured via two environment variables:

1. `GITHUB_ACCESS_TOKEN`: Must be set to a GitHub API access token.
2. `GITHUB_WEBHOOK_SECRET`: Must be set to the GitHub webhook secret.

After these environment variables have been set, start `noprs`:

	$ hy noprs.hy -a localhost -p 8080 -c my-comment.md

Afterwards, register the webhook on GitHub, either for an entire
organization or a single repository. The `Content-Type` must be set to
`application/json` and the webhook must only deliver PR events.

Test if everything works as expected by creating a new GitHub PR.

## License

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero
General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.

[dear-github #84]: https://github.com/dear-github/dear-github/issues/84
[PRBot github]: https://github.com/ajdlinux/PRBot
[linux github]: https://github.com/torvalds/linux/
[github webhooks]: https://developer.github.com/webhooks/
[hy homepage]: https://docs.hylang.org
[pygithub homepage]: https://github.com/PyGithub/PyGithub
