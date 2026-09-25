# Instructor workspace and qualification routing: rollout checklist

The instructor work spans two repos (this one and S@Learn) and three deploy targets, and
**merging is not deploying** for any of them. This file is the order to do it in, and how to
check each step. Written 2026-09-25, against the state described below.

## What shipped (all merged)

- **Spekooh** (#169): fresh 15-minute paper links, earnings, the richer `new_request` payload,
  and **qualification-aware routing** (`instructor_profile_update` webhook event,
  `partner/categories/` endpoint).
- **S@Learn** (#11): the instructor workspace (inbox, request page with the paper inline, draft
  autosave, earnings). (#12): the Qualifications tab that pushes an instructor's levels to Spekooh.

## The one behaviour that can bite

Routing **fails closed**. `route_next_instructor` skips any queued instructor whose cached
profile does not list the paper's category, or who has no cached profile at all. Until every
queued instructor has saved their qualifications in S@Learn, a paper for their subject can land
in **Unassigned** (an admin-queue ticket). That is deliberate: it stops a secondary-level
instructor being offered a university paper. It is also why the order below matters.

## State on 2026-09-25

| Piece | State |
| --- | --- |
| Spekooh backend, staging | Live with all new endpoints. Migrations run at container start. |
| Spekooh backend, production | Not deployed (`autoDeploy: false`; see `RENDER_PRODUCTION.md`). |
| S@Learn frontend (Vercel) | Live with the new UI (auto-deploys on merge). |
| Edge functions `spekooh-webhook`, `spekooh-respond` | Deployed, **old versions**. |
| Edge functions `spekooh-paper-link`, `spekooh-earnings`, `spekooh-qualifications` | **Not deployed.** |
| S@Learn migrations `0063`, `0064` | **Unconfirmed.** |

While the functions are missing, the live UI degrades: the paper viewer says "no longer
available", and Earnings and Qualifications show load errors. Nothing is lost; deploy forward.

## Order

1. **Confirm or apply the S@Learn migrations.** In the Supabase SQL editor (read-only check):
   ```sql
   select to_regclass('public.spekooh_instructor_qualifications') as m0064,
          (select count(*) from information_schema.columns
            where table_name = 'spekooh_marking_requests'
              and column_name in ('exam_year', 'decline_reason', 'draft_content')) as m0063_cols;
   ```
   `m0064` must be non-null and `m0063_cols` must be `3`. If not, run
   `supabase/migrations/0063_spekooh_instructor_workspace.sql`, then `0064_...sql`, in the same
   editor. Both are additive. `0063` is idempotent; `0064` is a plain `create table`, so it errors
   harmlessly if already applied.
2. **Deploy the five functions** from the S@Learn repo, with your Supabase token in your own
   shell (never pasted into chat or a ticket):
   ```
   supabase functions deploy spekooh-webhook --no-verify-jwt --project-ref <ref> --import-map supabase/functions/deno.json
   supabase functions deploy spekooh-respond spekooh-paper-link spekooh-earnings spekooh-qualifications --project-ref <ref> --import-map supabase/functions/deno.json
   ```
   Only the webhook skips JWT verification (Spekooh authenticates it with the signed header). The
   import map must be passed explicitly or the bundler can't resolve `@supabase/supabase-js`.
   No new secrets: they reuse `SPEKOOH_WEBHOOK_URL`, `SPEKOOH_WEBHOOK_SECRET`,
   `SPEKOOH_PARTNER_ID`.
3. **Verify the functions exist.** An unauthenticated POST returns 401/403 when deployed and 404
   when missing:
   ```
   for f in spekooh-webhook spekooh-respond spekooh-paper-link spekooh-earnings spekooh-qualifications; do
     printf "%-24s " $f; curl -s -o /dev/null -w "%{http_code}\n" -X POST -H 'Content-Type: application/json' -d '{}' "https://<ref>.supabase.co/functions/v1/$f"
   done
   ```
4. **Every queued instructor saves their qualifications** (S@Learn → Spekooh Marking →
   Qualifications). Until they do, Spekooh skips them. Spot-check in the Spekooh admin: the
   subject queue screen shows a "Qualified for" column per row ("No profile on file yet" means
   they haven't saved).
5. **Test one paper end to end on staging** before trusting it: route it, accept it as an
   instructor, open the paper inline, submit a guide, check the earnings.

## Things to check that are easy to miss

- The Spekooh `PartnerCredential` (partner id `s-learn`) must carry the **same secret** as
  S@Learn's `SPEKOOH_WEBHOOK_SECRET`, on every environment.
- The S@Learn database host (`db.<ref>.supabase.co`) is **IPv6-only**. From an IPv4-only machine,
  use the session pooler on port 5432 (not 6543: transaction mode breaks migration pushes), and
  percent-encode the password.
- Migrations are additive and nullable, so an out-of-order state is recoverable. If a function
  misbehaves, redeploy the previous version; nothing here rewrites data.

## When Spekooh production goes live

The same order applies: deploy the backend (migrations run at start), then repeat steps 3-5
against production. Do not route real papers until step 4 is complete.
