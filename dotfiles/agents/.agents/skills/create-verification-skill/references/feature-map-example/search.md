# Search

## Sub-features

- Find an existing record by its visible name.
- Show an empty result when no record matches.

## How to get to it (user POV)

Sign in with the seeded reader account and open Search from the main navigation.

## Driving it with the verification harness

Enter a known record name in the field labelled Search and submit. Confirm the result links to that record. Repeat with a string absent from the fixture and confirm the empty-state message and unchanged record count.

## Gotchas

Search indexing may lag behind fixture creation. Wait on the documented readiness condition rather than a fixed delay.
