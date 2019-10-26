# pr-deactivater

Closes all new GitHub PRs for an organization.

## Motivation

GitHub does not support [deactivating pull requests][dear-github #84].
However, some organization do not want to use the GitHub PR feature and
only use GitHub as a read-only git mirror.

Inspired by [PRBot][PRBot github], used in the GitHub
[Linux repository][linux github], this repository provides an automation
for closing all new pull requests. It differs from PRBot in the
following ways:

	1. It uses [GitHub webhooks][github webhooks] and does not
	   require a cronjob.
	2. It optionally closes the GitHub PR in addition to adding a
	   configurable comment.
	3. It is written in [hy][hy homepage].

## Usage

To-do.

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
[github webhook]: https://developer.github.com/webhooks/
[hy homepage]: https://docs.hylang.org