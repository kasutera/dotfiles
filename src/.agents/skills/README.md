# User skills

Skill sources are maintained under `src/.agents/skills/<skill-name>/`. Their home
installation destinations are listed in
`src/.agents/skill-destinations.sh` and processed by `config.sh`.

The validation and symlink functions live in the repository root's
`skill-functions.sh`; normally, adding a skill only requires editing the
configuration, not the installer code.

The configuration is a Bash file containing one `skill` call per destination:

```bash
skill <skill-name> <relative-path-under-$HOME>
```

The installer creates one directory-level symbolic link for each call. For
example:

```bash
skill gh-run-safely .agents/skills
```

```text
~/.agents/skills/gh-run-safely
  -> ~/dotfiles/src/.agents/skills/gh-run-safely
```

The same skill can have multiple destinations by adding multiple calls:

```bash
skill example-skill .agents/skills
skill example-skill .claude/skills
```

The destination must be one of these paths relative to `$HOME`:

- `.agents/skills`
- `.claude/skills`

`skill-functions.sh` rejects every other destination before installation.

The configuration selects filesystem destinations, not agents. It cannot prevent
another agent from discovering a skill placed in a directory that agent scans.

`config.sh` sources the configuration first in validation mode and then in
installation mode, so all entries are checked before any files change. It
rejects missing `SKILL.md` files, unlisted skill directories, malformed skill
names, and invalid destinations. Every skill added under `src/.agents/skills/`
therefore needs at least one `skill` call.

## Adding a skill

1. Create `src/.agents/skills/<skill-name>/SKILL.md`. The directory name and the
   frontmatter `name` must use the same lowercase hyphenated skill name.
2. Add one or more `skill` calls to `src/.agents/skill-destinations.sh`.
3. Check the installer before running it:

   ```sh
   bash -n config.sh
   git diff --check
   ```

4. Run `./config.sh`. It creates or updates one directory-level link per
   `skill` call.

This file is a dotfiles installer configuration, not part of the Agent
Skills standard. Keep it outside the skill directories so the skill packages
remain portable.

Do not create symbolic links for individual files such as `SKILL.md` or
`agents/openai.yaml`. The official documentation states that Codex supports
symbolically linked skill folders, but does not state that individual skill
files are supported:

<https://learn.chatgpt.com/docs/build-skills#where-codex-loads-local-skills>

## Local verification

Verified on 2026-08-11 with `codex-cli 0.147.0` using an isolated
`.agents/skills` directory and a regular-file control skill.

| Layout | `codex debug prompt-input` | Explicit invocation |
| --- | --- | --- |
| The complete `<skill-name>/` directory is a symbolic link | Skill was listed | Skill instructions were executed |
| `<skill-name>/` is a directory and its individual files are symbolic links | Skill was absent while the control skill was listed | Codex reported that the skill was unavailable |

This result is specific to the tested CLI version. Keep the directory-level
link as the supported installation boundary and re-run the discovery check when
changing that layout or upgrading Codex if behavior is in doubt.
