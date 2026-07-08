# GATE ECE Tracker

A private, multi-user GATE ECE syllabus, PYQ, notes, and mock-test tracker.

The UI remains a lightweight static app. Authentication and per-user data storage are handled by Supabase Auth and Supabase PostgreSQL with Row Level Security.

## What Changed

The original app saved one shared JSON object through `/api/state`, so every visitor read and overwrote the same tracker. The app now saves user-owned rows in Supabase:

- `user_progress` for chapter completion
- `user_notes` for private chapter notes
- `user_pyq_progress` for PYQ counts
- `mock_tests` for mock test history and remarks
- `user_settings` for preferences and exam date
- `study_sessions` for future study-hour tracking

The shared syllabus lives in `subjects` and `chapters`.

## Requirements

- A free Supabase project
- A free Vercel project, or any static host
- Node.js only for generating `supabase-config.js` during deployment

## Supabase Setup

1. Create a Supabase project.
2. Open the SQL editor.
3. Run `supabase/migrations/001_initial_schema.sql`.
4. In Supabase Auth, enable:
   - Email/password
   - Google provider
   - GitHub provider
5. Add these redirect URLs in Supabase Auth settings:
   - `http://localhost:3000`
   - Your Vercel production URL

## Environment Setup

Copy the example values:

```bash
cp .env.example .env
cp supabase-config.example.js supabase-config.js
```

Set:

```bash
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-public-anon-key
```

For local static use, edit `supabase-config.js` directly. The anon key is public by design; RLS is the security boundary.

## Running Locally

```bash
npm run dev
```

Open the local URL printed by the static server.

## Vercel Deployment

1. Import this repository into Vercel.
2. Add environment variables:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
3. Use the build command:

```bash
npm run build
```

4. Use the output directory:

```text
.
```

The build script writes `supabase-config.js` from Vercel environment variables.

## Security Model

- Supabase Auth owns user identities in `auth.users`.
- Every user-owned table has RLS enabled.
- Each user-owned table has SELECT, INSERT, UPDATE, and DELETE policies requiring `user_id = auth.uid()`.
- The frontend never sends another user's ID.
- User IDs default to `auth.uid()` in PostgreSQL.
- Input lengths and numeric ranges are constrained in the database.
- Browser rendering escapes user-controlled text to reduce XSS risk.
- No service-role key or secret is used in the frontend.

## Migration From Old Backups

Existing exported JSON backups can still be imported from the app footer after login. Import maps old fields into the signed-in user's Supabase rows.

The old Netlify Blob function has been removed because it stored shared global state.

## Architecture

```text
index.html
  Static UI, auth screens, Supabase client, tracker logic

supabase-config.js
  Runtime public Supabase URL and anon key, generated or copied locally

supabase/migrations/001_initial_schema.sql
  Tables, seed syllabus, constraints, RLS policies

scripts/create-runtime-config.mjs
  Vercel build helper for runtime config
```

## Verification Checklist

- Each account signs in through Supabase.
- Progress rows are scoped by `auth.uid()`.
- Notes are scoped by `auth.uid()`.
- PYQ statistics and mock stats load only from the signed-in user's rows.
- RLS blocks cross-user reads and writes.
- No shared `/api/state` or Netlify Blob storage remains.
- No secrets are hardcoded.
