# Contributing

Conventions for this repo. Worth a read before a commit.

## Commits and pull requests

- Author and committer are `AnthonyLeigh25 <anthony.leigh@aurora-services.co.uk>`.
  Set it locally with:

  ```
  git config user.name "AnthonyLeigh25"
  git config user.email "anthony.leigh@aurora-services.co.uk"
  ```

- A commit message is the change and nothing else. No trailers of any kind, no
  `Co-Authored-By`, no links back to whatever you had open while writing it. If
  a line would not help somebody reading `git log` in a year, leave it out.
- Subject line in the imperative, under ~72 characters, then a blank line and a
  body explaining why where it isn't obvious.

## Writing style, code and docs

- Plain hyphens only. No em dashes, en dashes or other typographic dashes in
  comments, commit messages, documentation or anything the operator sees on
  screen. AppleScript's own `¬`, `≤` and `≥` are syntax, not typography, and
  stay as they are.
- Comments explain intent, not mechanics. Say why a thing is done that way,
  skip narrating what the next line does.
- Keep them lowercase and conversational.
