# Notes on DB
Some quick notes on how to interpret NetBackup OpsCenter Analytics DB.

## Table: domain_media
Interesting columns and their explaination

### Column *status*
Statuscode | Meaning
--- | ---
8 | Full
0 | Active
512 | Active MPX
552 | Full MPX
17 | Frozen
9 | Frozen Full
513 | Frozen MPX
