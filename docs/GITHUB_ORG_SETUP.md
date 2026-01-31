# GitHub organization setup for Zixir

Use this guide to create a **Zixir-lang** organization and move the language repo there for a clean URL: **https://github.com/Zixir-lang**.

---

## 1. Create a new organization

1. Go to [GitHub](https://github.com) and sign in.
2. Click your **profile picture** (top right) → **Your organizations**.
3. Click **New organization** (or go to [github.com/organizations/plan](https://github.com/organizations/plan)).
4. Choose **Create a free organization**.
5. **Organization name:** `Zixir-lang` (URL: `github.com/Zixir-lang`).
6. Contact email, then **Next**.
7. **My personal account** (or your choice), then **Next**.
8. Skip “Invite members” if not needed → **Complete setup**.

Your org URL: **https://github.com/Zixir-lang**

---

## 2. Transfer the repository (recommended)

Moving a repository to **Zixir-lang/Zixir** keeps stars, issues, and release history.

1. Open the repository you wish to transfer (the source repo) in your browser.
2. Go to **Settings** (repo tab).
3. Scroll to **Danger Zone**.
4. Click **Transfer ownership**.
5. **New owner:** type `Zixir-lang` (your org).
6. **Repository name:** `Zixir` (so URL is `github.com/Zixir-lang/Zixir`).
7. Type the repo name to confirm.
8. Click **I understand, transfer this repository**.

After transfer:

- Repo URL: **https://github.com/Zixir-lang/Zixir**
- Your personal org is unchanged; you stay in both.

---

## 3. Or: create a new repo under Zixir-lang (no transfer)

If you prefer a **new** repo instead of transferring:

1. Go to [github.com/organizations/Zixir-lang/repositories/new](https://github.com/organizations/Zixir-lang/repositories/new) (or **Zixir-lang** org → **Repositories** → **New**).
2. **Repository name:** `Zixir`.
3. **Public**, add README if you want, then **Create repository**.
4. Add the new repo as a remote and push your local branch:
   ```bash
   git remote add zixir https://github.com/Zixir-lang/Zixir.git
   git push zixir master
   ```
5. You’ll have two repos until you archive or delete the old one.

---

## 4. After repo is under Zixir-lang org

### Update this project to use the new URL

Run from the repo root (or ask your tooling to apply the same changes):

- **Git remote:**  
  `git remote set-url origin https://github.com/Zixir-lang/Zixir.git`
- **README:** use `Zixir-lang/Zixir` and `https://github.com/Zixir-lang/Zixir`.
- **mix.exs:** set `@source_url "https://github.com/Zixir-lang/Zixir"`.
- **Other docs:** any link to the repo should use `https://github.com/Zixir-lang/Zixir`.

### Improve visibility on GitHub

- **Repo description:** e.g.  
  `Zixir: small, expression-oriented language and three-tier runtime (Elixir + Zig + Python) for AI automation`
- **Topics:** `programming-language`, `language`, `compiler`, `elixir`, `zig`, `python`, `ai`, `apache-2-0`.
- **Pin:**  
  - **Your profile:** Profile → **Customize your pins** → add **Zixir-lang/Zixir**.  
  - **Zixir-lang org:** Org profile → **Pin repositories** → add **Zixir**.

---

## 5. Keep both organizations

- You can be in your personal org and **Zixir-lang** at the same time.
- Only the repo moves (or you have a new repo under Zixir-lang).
- The “clean” language URL is **https://github.com/Zixir-lang** (org) and **https://github.com/Zixir-lang/Zixir** (repo).
