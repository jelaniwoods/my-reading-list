# Reading List — implementation notes

Behavior that the Foundation Plan requests but the current First Draft release does not fully generate.
These notes are not Compiler input. Read `.firstdraft/gaps.json` separately as the authority on support gaps.

## Agreed requirements

### New books start unfinished

- **Requirement:** a book's Finished checkbox starts unchecked. The Plan authors `book.finished` as a required
  Boolean with literal default `false`. The reviewed GapSet reports that this default is not applied
  (`foundation_plan.gap.field_modifier.default` at `book.finished`).
- **Needed:** make `false` the real default at the model and database levels, for example with a migration that
  sets the column default to `false`. The New Book form's checkbox should then start unchecked.
- **Acceptance examples:**
  - Opening New Book on the web, iPhone, or Android shows Finished unchecked.
  - Saving a book with only a title and author succeeds, and the book shows Finished = No.
  - `Book.new.finished` is `false` in the Rails console.

## Context

- This is a public demonstration with disposable data and no accounts. Anyone can list, view, add, edit, and
  delete books on the web, iPhone, and Android. Do not add authentication.
- Do not publish to GitHub or deploy unless the owner asks separately.

## Open questions

None.
