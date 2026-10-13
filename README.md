# Gallerist — hosted application starter

This is a **deployable foundation**, not a completed AI agent. It contains Next.js UI, Supabase email/password authentication, row-level-secured artwork/gallery/approval tables, and a conversational **command-based** interface. Gmail, Drive, image uploads, invoice features, real LLM calls, automated actions and gallery assignment UI are not yet implemented.

## Local setup
1. Install Node.js 20+.
2. Create a Supabase project at https://supabase.com and open SQL Editor.
3. Run `supabase/schema.sql` to create the tables and ownership policies.
4. Copy `.env.example` to `.env.local` and fill in your Supabase Project URL and publishable/anon key (not the service-role key).
5. Run `npm install` and `npm run dev`.
6. Open http://localhost:3000 and create an account. Confirm the email if Supabase requires it.

## Hosting
1. Push this directory to a private GitHub repository.
2. Import the repo at https://vercel.com/new.
3. Add `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` in Vercel environment settings.
4. Deploy. Add your Vercel production URL to Supabase Authentication > URL Configuration (Site URL / redirect URLs).
5. Disable public sign-ups after creating your account if this is a personal-only deployment; review authentication settings and test sign-in/sign-out before storing real personal records.

## Security and current limitations
- Database row-level security isolates user-owned records; artwork assignment uniqueness is enforced in SQL, including concurrent writes.
- Assignment creation is **not exposed in this UI** yet. Build it with a server-side approval workflow before use. Never directly allow an LLM to mutate the database.
- Approval buttons change only approval status; no action is executed.
- This foundation has no Gmail/Drive authorization and no actual AI model integration.
- Do not import collector personal data until a privacy policy, backups, deletion/export controls, and security review are in place.
- Do not assume Supabase or Vercel are free indefinitely; review current pricing and usage before deployment.
- Test with dummy records first. Production deployment requires end-to-end tests, operational monitoring and recovery procedures.

## Next milestones
1. Add authenticated server actions with idempotent approval execution and audit log.
2. Add artwork photo storage with private signed URLs and gallery assignments through a transactional API.
3. Add real LLM service with read-only tools, explicit approval for mutations, prompt-injection safeguards.
4. Add Google OAuth/Gmail/Drive with minimum scopes, token encryption, consent and privacy controls.
5. Migrate vetted Hodgins Studio records from JSON with deduplication and status verification.
