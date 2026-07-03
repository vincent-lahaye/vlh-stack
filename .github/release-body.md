# oh-my-claudecode v4.15.2: HUD, hooks, and workflow reliability fixes

## Release Notes

Patch release focused on default HUD correctness, hook timeout reliability, Windows/path handling, and workflow guardrails since v4.15.1.

### Highlights

- Fix fresh/default HUD config so the `focused` preset is applied even when `settings.json` has no `omcHud` key (#3400, fixes #3399).
- Raise and align UserPromptSubmit hook timeout handling so the skill-injector/keyword-detector path fails open before Claude Code discards output (#3398).
- Respect `OMC_STATE_DIR` for learner skill-session state paths (#3397).
- Improve slow team worker startup tolerance and HUD rate-limit detection (#3395, #3392).
- Fix setup legacy hook warnings, keyword detector informational occurrence scanning, quoted keyword exemptions, and Windows hook child-process hiding (#3389, #3386, #3385).
- Improve HUD/model/currency/cwd behavior and Windows path handling (#3375, #3367, #3360, #3359, #3357).
- Support Claude Sonnet 5 defaults and correct model-routing counting in indented code blocks (#3370, #3364).
- Clarify install tracks and update the Discord invite in docs (#3362, #3373).

### Install / Update

The npm CLI and the Claude Code marketplace/plugin are separate install tracks, not either/or replacements. Update whichever track you use; if you have both installed, update both. CLI-dependent skill paths such as `ask`, `ccg`, and CLI-backed `team` require the `omc` CLI from the npm package.

**CLI / runtime:**

```bash
npm install -g oh-my-claude-sisyphus@4.15.2
```

**Claude Code plugin:**

```text
/plugin marketplace update omc
```

**Full Changelog**: https://github.com/Yeachan-Heo/oh-my-claudecode/compare/v4.15.1...v4.15.2

## Contributors

Thank you to all contributors who made this release possible!

@Yeachan-Heo @qitiandashenggogogo
