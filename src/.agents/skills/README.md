# Codex user skills

User skills are maintained under `src/.agents/skills/<skill-name>/` and installed
under `~/.agents/skills/` by `config.sh`.

`config.sh` creates one symbolic link per skill directory. For example:

```text
~/.agents/skills/gh-run-safely
  -> ~/dotfiles/src/.agents/skills/gh-run-safely
```

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
