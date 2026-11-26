# Credentials store: principles

Applies to `~/credentials/`, the host-only credential store (never a Git repository). Identity, sharing, and mount rules are in the [fleet policy](../workspace/AGENTS.md) (installed: `~/workspace/AGENTS.md`). This file states principles only. It is published with `geonu/dot`, so it never names services, accounts, file names, inventories, or migration status.

## Where the details live

- Identity-specific inventory, classifications, and procedures belong to the claw repo that uses that identity, in a private document.
- The host-local `~/credentials/README.md` (untracked) maps each identity to that document. Read it before changing anything under an identity directory.
- No inventory or procedure detail goes into this file or any other file in `geonu/dot`.

## Principles

1. **Credentials only.** Keep only material a tool reads to authenticate, in one directory per tool under `<identity>/` (directories `0700`, files `0600`). Backups, dumps, snapshots, runtime state, logs, scripts, and rollback copies (including old secret copies) do not belong here.
2. **Know the class, respect the writer.** Every credential is one of:
   - *static secret*: issued by a person; its source of truth is the password manager;
   - *refreshing token store*: rewritten by its tool; the file is the source of truth;
   - *user session*: created by a login flow; the file is the source of truth.
   Each store has exactly one writer. Never copy a refreshing token or session elsewhere, and never let two hosts or mounts write the same store.
3. **Password manager for static secrets.** 1Password holds static secrets, one vault per identity. A person renders them into place on the host (for example with `op inject` from reference-only templates); consumers keep reading the rendered file. Unlock tokens and service-account tokens never live on disk, in a claw, a scheduled job, or a container.
4. **Never reveal values.** Do not print, search, echo, or paste secret values into chat, logs, commands, or commits. Inspect by name, mode, timestamp, or key name only.
5. **Least exposure.** Mount the narrowest tool directory into a claw, read-only unless the tool must refresh. Code takes credential paths from configuration or the mount; it never embeds values.
6. **Changes need approval.** Moving, deleting, or bulk-copying anything here is hard to reverse; get explicit approval for the exact target.
7. **Exposure means rotation.** A value that leaked is compromised: stop using it, revoke or rotate it at the issuer, then re-render or re-authenticate. Deleting a file is not revocation.
8. **Recovery by class.** Static secrets come back from the password manager; token stores and sessions come back by re-authenticating. Copy a token store or session between hosts only through an encrypted out-of-band channel, and keep one writer.
