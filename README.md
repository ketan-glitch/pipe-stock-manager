# Pipe Stock Manager

Minimal React + Vite single-page stock manager, backed by Supabase. Preloaded with the 40 pipe-cleaner colours and 10,000 initial pieces.

## 1. Configure Supabase
1. Create a Supabase project.
2. Open SQL Editor and run the complete `supabase/schema.sql` file.
3. Copy your Project URL and publishable key from the Supabase project API settings. The older client-safe `anon` key also works.
4. Never use the service-role key or a secret key in frontend code.

## 2. Run locally
Install Node.js LTS, then run:

```sh
npm install
cp .env.example .env
```

Edit `.env` with your actual values:

```env
VITE_SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Then run `npm run dev` and open the local URL shown by Vite.

## 3. Create and authorize your account
1. In the app choose **Create account** and register your email/password. Confirm your email if Supabase requires it.
2. In Supabase Dashboard → Authentication → Users, copy the account UUID.
3. Run this in SQL Editor, replacing the placeholder:

```sql
insert into public.authorized_users(user_id,note)
values ('PASTE-YOUR-AUTH-USER-UUID-HERE','Inventory owner')
on conflict(user_id) do nothing;
```

Only UUIDs in `authorized_users` can view inventory or make stock changes. Add another user's UUID in the same way if you want to give them access.

## 4. Deploy on GitHub Pages
1. Create a GitHub repository and upload/push all project files to its root. Do not commit `.env`.
2. In repository Settings → Secrets and variables → Actions → Variables, add `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY`.
3. In Settings → Pages, choose **GitHub Actions** as the source.
4. Push to `main`. The workflow builds and deploys the app; use the Pages URL shown by GitHub.

Vite uses `base: './'`, supporting a project URL such as `https://USERNAME.github.io/pipe-stock-manager/`.

## Security notes
- Publishable/anon keys are designed for frontend use; RLS and the authorization allowlist protect the data.
- Do not expose service-role or secret keys.
- Stock changes use a database function that validates quantities and updates inventory + movement history in one transaction.
- Seed inserts do not overwrite quantities when the SQL script is rerun...
