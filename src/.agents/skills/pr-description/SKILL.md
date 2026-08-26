---
name: pr-description
description: Write or update a pull/merge request's title and body so they describe only the final diff being merged — never internal review back-and-forth, reverted fixup commits, or session/chat narrative. Use whenever drafting or revising a PR/MR/CR title or description.
---

# PR description

Write the title and body from the actual final diff, not from memory of
the session. Reviewers see only the diff — the story of how you got
there (review rounds, fixup commits, reverted commits, an "addressed
feedback" section) is noise they didn't ask for.

Before drafting: get the real diff (base vs. branch tip), and read any
existing description or template so you don't overwrite content that
isn't yours to rewrite.

Before publishing, check the draft against the diff: does every claim
actually appear in it? Is anything reverted or already-superseded still
mentioned? Is scope understated, or is placeholder text left unfilled?
