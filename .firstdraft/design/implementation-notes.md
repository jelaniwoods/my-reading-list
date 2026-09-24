# Reading List — implementation notes

Behavior that the Foundation Plan requests but the current First Draft release does not fully generate.
These notes are not Compiler input. Read `.firstdraft/gaps.json` separately as the authority on support gaps.

## Agreed requirements

None outstanding.

## Completed

### New books start unfinished (done 2026-09-24)

- The reviewed GapSet reported that `book.finished`'s authored default `false` was not applied
  (`foundation_plan.gap.field_modifier.default`). Migration
  `db/migrate/20260924220000_default_books_finished_to_false.rb` now sets the column default to `false`.
- Covered by `spec/models/book_spec.rb` ("starts unfinished"; "saves as unfinished when finished is not given").
  `.firstdraft/gaps.json` is the retained compile-time record and is intentionally left unchanged.

## Context

- This is a public demonstration with disposable data and no accounts. Anyone can list, view, add, edit, and
  delete books on the web, iPhone, and Android. Do not add authentication.
- The owner published the source to a public GitHub repository and deployed it to Render (free plan) with a
  Neon database. Treat further deploy changes as owner decisions.

## Open questions

None.
