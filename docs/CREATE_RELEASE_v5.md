# Create GitHub Release v5.0.0

To show **v5.0.0** under [Releases](https://github.com/Zixir-lang/Zixir/releases), create a release from the tag after committing and tagging.

---

## 1. Commit and tag (from repo root)

```powershell
git add -A
git status
git commit -m "Release v5.0.0: portable CLI, setup fixes, signature test, test task, PowerShell script"
git tag v5.0.0
git push origin main
git push origin v5.0.0
```

(Use your default branch name if not `main`.)

---

## 2. Publish the release

### Option A: GitHub CLI (one command)

1. Install [GitHub CLI](https://cli.github.com/) and log in: `gh auth login`
2. From repo root:
   ```powershell
   .\scripts\publish-release-v5.ps1
   ```
   Or directly:
   ```bash
   gh release create v5.0.0 --repo Zixir-lang/Zixir --title "v5.0.0 — Portable CLI, setup fixes, and redeploy" --notes-file RELEASE_NOTES_v5.0.0.md
   ```

### Option B: GitHub website (manual)

1. Open **https://github.com/Zixir-lang/Zixir/releases/new**
2. **Choose a tag:** select **v5.0.0** (or type `v5.0.0` and create from existing tag).
3. **Release title:** `v5.0.0 — Portable CLI, setup fixes, and redeploy`
4. **Description:** Paste the contents of [RELEASE_NOTES_v5.0.0.md](../RELEASE_NOTES_v5.0.0.md).
5. Leave “Set as the latest release” checked if you want v5.0.0 to be the default.
6. Click **Publish release**.

---

After that, v5.0.0 will appear under https://github.com/Zixir-lang/Zixir/releases with source zip/tarball attached.
