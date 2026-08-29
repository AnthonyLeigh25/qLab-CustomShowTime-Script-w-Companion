# Contributing

Conventions for this repo. Worth a read before a commit.

## Commits

- Author and committer are `AnthonyLeigh25 <anthony.leigh@aurora-services.co.uk>`.
  Set it locally with:

  ```
  git config user.name "AnthonyLeigh25"
  git config user.email "anthony.leigh@aurora-services.co.uk"
  ```

- A commit message is the change and nothing else. No trailers, no
  `Co-Authored-By`, no links to whatever you had open while writing it. If a
  line would not help somebody reading `git log` in a year, leave it out.
- Subject line in the imperative, under about 72 characters. Then a blank line
  and a body saying why, where that is not obvious.

## Writing style, code and docs

- Plain hyphens only. No em dashes, en dashes or other typographic dashes,
  anywhere: comments, commit messages, docs, or anything the operator sees on
  screen. AppleScript's `¬`, `≤` and `≥` are syntax, not typography, and stay.
- Comments say why, not what. Skip narrating the next line.
- Keep them short and plain. Two clear sentences beat one clever one.
- Comments stay lowercase. Headings and prose in the docs are normal sentence
  case.
