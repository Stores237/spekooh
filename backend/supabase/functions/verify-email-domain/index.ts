// Supabase Edge Function: real-time email verification for account
// registration. Checks (1) the address is syntactically valid and (2) its
// domain actually has mail-exchange (MX) records — i.e. can receive mail at
// all — before Django lets someone register with it. This catches typo'd
// domains (gmial.com), made-up ones, and disposable-looking non-domains at
// signup time, which no amount of client-side regex can.
//
// Deliberately does NOT verify a specific mailbox exists (that needs an
// actual "click this link" or "enter this code" round trip — see
// apps.accounts.models.PasswordResetCode for that same pattern already
// used for password reset; a matching EmailVerificationCode flow is the
// natural next step here once a real email-sending provider is wired in —
// see TODOS.md). MX-record verification is what's achievable with zero
// third-party credentials, deployed and tested right now.
//
// Auth: not a Supabase-session-authenticated call (Django calls this
// server-to-server, not on behalf of a logged-in Supabase user), so JWT
// verification is disabled for this function (see supabase/config.toml).
// Instead, a shared secret (EMAIL_VERIFY_SHARED_SECRET, set via
// `supabase secrets set`) gates it — without this, anyone who found the
// URL could use it as a free anonymous DNS-lookup proxy.

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

Deno.serve(async (req: Request) => {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-verification-secret",
  };

  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const expectedSecret = Deno.env.get("EMAIL_VERIFY_SHARED_SECRET");
  if (expectedSecret && req.headers.get("x-verification-secret") !== expectedSecret) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  let email: unknown;
  try {
    ({ email } = await req.json());
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (typeof email !== "string" || !EMAIL_RE.test(email)) {
    return new Response(JSON.stringify({ valid: false, reason: "malformed_email" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const domain = email.split("@")[1];
  try {
    const mxRecords = await Deno.resolveDns(domain, "MX");
    if (mxRecords.length === 0) {
      return new Response(JSON.stringify({ valid: false, reason: "no_mx_records" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    return new Response(JSON.stringify({ valid: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch {
    // NXDOMAIN or any other DNS resolution failure — domain can't receive mail.
    return new Response(JSON.stringify({ valid: false, reason: "domain_not_found" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
