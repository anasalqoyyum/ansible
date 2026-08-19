# Refactoring

You own behavioral equivalence and the simpler shape.

1. Define the behavior that must remain stable and the structural result that should improve.
2. Ground callers, invariants, and tests. Establish a focused safety net.
3. Write the throughput checkpoint. Separate independent moves and keep shared caller migration under one owner.
4. Subtract before adding. Delete or inline dead and shallow layers before extracting anything new.
5. Move one coherent unit at a time and verify after each unit.
6. Migrate callers and delete the legacy internal API in the same wave unless compatibility is explicit scope.
7. Compare behavior before and after. Run static checks and inspect the diff for accidental feature work.
8. Apply `no-comments`. Publish only when explicitly requested.

Report the preserved behavior, removed concepts, new ownership shape, and verification.
