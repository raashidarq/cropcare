# Supabase Auth: email via Resend, and phone OTP

A runbook. Follow it in order — later steps assume earlier ones.

Two things this decides for you up front, with reasoning, because both are
easy to get wrong in a way you only discover in production:

- **Email: yes, and it is genuinely free.** Resend's free tier is 3,000
  emails/month and 100/day. For an MVP that is not a constraint.
- **Phone OTP: not for the MVP.** Every SMS provider Supabase supports bills
  per message; there is no free tier anywhere. Your backend already has
  `PHONE_AUTH_ENABLED` defaulting to `false`, and that was the right call.
  Section 6 documents the path for when you want it.

---

## 0. Prerequisite: you need a domain

**Resend cannot send to arbitrary addresses until you verify a domain.** The
sandbox sender (`onboarding@resend.dev`) only delivers to the email address on
your own Resend account — fine for a smoke test, useless for real users.

If you do not own a domain yet, get one before starting. A `.com` or a `.lk`
is around $10–15/year, and it is the one unavoidable cost in this document.
Everything else here is free.

You will send from something like `no-reply@cropcare.lk`. The mailbox does not
need to exist — you are sending, not receiving.

---

## 1. Why not Supabase's built-in email

Supabase ships an SMTP sender so signup works out of the box. Its limits:

| | Built-in | With custom SMTP |
|---|---|---|
| Rate | **2 messages/hour** | 30/hour (raisable) |
| Recipients | **Only your own team members** | Anyone |

The second row is the one that matters. The built-in sender will not deliver
to a farmer's address at all. It exists for local testing.

---

## 2. Set up Resend

1. Sign up at [resend.com](https://resend.com). No card needed for the free
   tier.
2. **Domains → Add Domain.** Enter your domain.
3. Resend gives you DNS records. Add all of them at your registrar:

   | Record | Purpose |
   |---|---|
   | `MX` (for the bounce subdomain) | receives bounces so Resend can track deliverability |
   | `TXT` — SPF | says Resend is allowed to send as you |
   | `TXT` — DKIM | cryptographically signs your mail |

   Add a **DMARC** record too. Resend does not require it; inbox providers
   increasingly do, and without it your mail is far more likely to be filtered:

   ```
   Type:  TXT
   Name:  _dmarc
   Value: v=DMARC1; p=none; rua=mailto:dmarc@yourdomain.lk
   ```

   Start at `p=none` — it monitors without affecting delivery. Move to
   `p=quarantine` once the reports show only your own mail passing.

4. Wait for verification (usually minutes, up to a few hours). **Do not
   continue until the domain shows Verified.**
5. **API Keys → Create API Key.** Give it *Sending access* only. Copy it now;
   it is shown once.

---

## 3. Point Supabase at Resend

Two routes. The first is less error-prone.

### Route A — the official integration (recommended)

Supabase and Resend maintain a
[first-party integration](https://resend.com/docs/send-with-supabase-smtp)
that creates the API key and fills in the SMTP fields for you. Use it unless
you have a reason not to.

### Route B — manual SMTP

**Supabase Dashboard → Authentication → Emails → SMTP Settings**, enable
custom SMTP, and enter:

| Field | Value |
|---|---|
| Host | `smtp.resend.com` |
| Port | `587` |
| Username | `resend` |
| Password | *your Resend API key* |
| Sender email | `no-reply@yourdomain.lk` |
| Sender name | `CropCare` |

The username really is the literal string `resend`.

### Then raise the rate limit

**Authentication → Rate Limits.** Custom SMTP starts at **30 emails/hour**,
which is not the same as Resend's 100/day and will bite first. Raise it to
something that fits your Resend allowance — 100/hour is reasonable, and the
daily cap still protects you.

---

## 4. Decide: email confirmation on or off

**Authentication → Providers → Email → "Confirm email".**

This is a real product decision, not a checkbox.

**Off** — signup returns a session immediately, the farmer is straight into
the app. One step. Anyone can register with an address they do not own.

**On** — the farmer must open an email and click a link before they can sign
in. Blocks fake addresses. Also blocks anyone who mistypes their address,
cannot get to email on the phone they are holding, or is standing in a field
with no signal.

**For this app I would turn it off.** The audience is offline-first, often on
a shaky connection, and the account exists to back up scans — not to protect
anything an attacker would want. An unverified address costs you nothing; a
farmer who cannot get past signup costs you the user.

The backend already handles both. `POST /auth/register` returns a session when
one exists, and a `401` telling the farmer to confirm when Supabase withholds
it — so turning confirmation on does not break anything, it just adds a step.

---

## 5. The emails themselves

**Authentication → Emails → Templates.** Supabase gives you Confirm signup,
Invite, Magic Link, Change Email Address, and Reset Password.

### The language problem — read this before writing any copy

CropCare is trilingual. Supabase templates are **one template per email type,
with no access to the user's language**. A farmer who has used the app
entirely in Sinhala will get an English email.

Three options:

1. **English only.** Simplest. Wrong for a third of your users.
2. **All three languages in one email**, stacked, English first. No
   infrastructure, works today, and it is what multilingual public services
   commonly do. **Recommended for the MVP.**
3. **Send Email Hook** — a Supabase Edge Function that picks the language from
   user metadata. Correct, and more moving parts than an MVP needs.

The templates below use option 2.

### Best practices these follow

- **Tables, not divs.** Outlook renders with Word's engine and ignores modern
  CSS layout.
- **Inline styles.** Gmail strips `<style>` blocks in some contexts.
- **600px maximum width.** The de facto standard; anything wider gets clipped.
- **No images, no logo.** Images are blocked by default in most clients, so an
  image-led auth email arrives blank. Text-only also renders instantly on a
  slow connection.
- **One call to action.** A second link halves the chance of the first being
  clicked.
- **The URL in plain text as well as a button.** Buttons fail; a copyable link
  does not.
- **State the expiry.** "This link works for 1 hour" prevents the support
  question.
- **A "did not request this" line.** Standard for a reason.
- **No tracking pixel, no unsubscribe.** These are transactional emails.
  Tracking them is bad practice, and an unsubscribe link on a password reset
  is actively harmful.
- **Explicit colours on every element.** Some clients apply a dark-mode
  inversion; unspecified colours become unreadable.
- **`lang` attributes per section** so screen readers switch pronunciation.

### Subject lines

Set these in the template editor. Plain, no marketing tone, no emoji — those
push transactional mail toward spam filters.

| Template | Subject |
|---|---|
| Confirm signup | `Confirm your CropCare account` |
| Magic Link | `Your CropCare sign-in link` |
| Reset Password | `Reset your CropCare password` |
| Change Email | `Confirm your new CropCare email address` |

### Template — Confirm signup

Paste into the Confirm signup template. The others follow the same shape;
swap the heading, body sentence and `{{ .ConfirmationURL }}` variable.

```html
<!doctype html>
<html lang="en">
  <body style="margin:0;padding:0;background-color:#faf9f7;">
    <!-- Preheader: shown in the inbox list, hidden in the body. -->
    <div style="display:none;max-height:0;overflow:hidden;color:#faf9f7;">
      Confirm your email address to finish setting up CropCare.
    </div>

    <table role="presentation" width="100%" cellpadding="0" cellspacing="0"
           style="background-color:#faf9f7;padding:24px 12px;">
      <tr>
        <td align="center">
          <table role="presentation" width="600" cellpadding="0" cellspacing="0"
                 style="max-width:600px;width:100%;background-color:#ffffff;
                        border:1px solid #d5d0c9;border-radius:12px;">
            <tr>
              <td style="padding:32px;font-family:Arial,Helvetica,sans-serif;">

                <p style="margin:0 0 24px;font-size:18px;font-weight:bold;
                          color:#1b5e20;">CropCare</p>

                <!-- English -->
                <div lang="en">
                  <h1 style="margin:0 0 12px;font-size:20px;line-height:1.3;
                             color:#1c1b1a;">Confirm your email address</h1>
                  <p style="margin:0 0 20px;font-size:15px;line-height:1.6;
                            color:#4a4643;">
                    Tap the button below to finish setting up your CropCare
                    account. This link works for 1 hour.
                  </p>
                </div>

                <table role="presentation" cellpadding="0" cellspacing="0"
                       style="margin:0 0 20px;">
                  <tr>
                    <td style="background-color:#1b5e20;border-radius:8px;">
                      <a href="{{ .ConfirmationURL }}"
                         style="display:inline-block;padding:14px 28px;
                                font-family:Arial,Helvetica,sans-serif;
                                font-size:16px;font-weight:bold;
                                color:#ffffff;text-decoration:none;">
                        Confirm my email
                      </a>
                    </td>
                  </tr>
                </table>

                <p style="margin:0 0 28px;font-size:13px;line-height:1.6;
                          color:#4a4643;">
                  If the button does not work, copy this address into your
                  browser:<br>
                  <span style="color:#1b5e20;word-break:break-all;">
                    {{ .ConfirmationURL }}
                  </span>
                </p>

                <hr style="border:none;border-top:1px solid #d5d0c9;
                           margin:0 0 24px;">

                <!-- Sinhala -->
                <div lang="si">
                  <h2 style="margin:0 0 8px;font-size:16px;color:#1c1b1a;">
                    ඔබගේ විද්‍යුත් තැපැල් ලිපිනය තහවුරු කරන්න
                  </h2>
                  <p style="margin:0 0 24px;font-size:14px;line-height:1.7;
                            color:#4a4643;">
                    ඔබගේ CropCare ගිණුම සම්පූර්ණ කිරීමට ඉහත බොත්තම ඔබන්න.
                    මෙම සබැඳිය පැයක් සඳහා වලංගු වේ.
                  </p>
                </div>

                <!-- Tamil -->
                <div lang="ta">
                  <h2 style="margin:0 0 8px;font-size:16px;color:#1c1b1a;">
                    உங்கள் மின்னஞ்சல் முகவரியை உறுதிப்படுத்தவும்
                  </h2>
                  <p style="margin:0 0 24px;font-size:14px;line-height:1.7;
                            color:#4a4643;">
                    உங்கள் CropCare கணக்கை முடிக்க மேலே உள்ள பொத்தானை
                    அழுத்தவும். இந்த இணைப்பு ஒரு மணி நேரம் செல்லுபடியாகும்.
                  </p>
                </div>

                <hr style="border:none;border-top:1px solid #d5d0c9;
                           margin:0 0 20px;">

                <p style="margin:0;font-size:12px;line-height:1.6;
                          color:#79746e;">
                  If you did not create a CropCare account, you can ignore this
                  email — nothing will happen.<br>
                  ඔබ CropCare ගිණුමක් සාදා නොමැති නම්, මෙය නොසලකා හරින්න.<br>
                  நீங்கள் CropCare கணக்கை உருவாக்கவில்லை என்றால், இதைப்
                  புறக்கணிக்கவும்.
                </p>

              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>
```

For the other templates, change:

| Template | Variable | Heading |
|---|---|---|
| Magic Link | `{{ .ConfirmationURL }}` | Your sign-in link |
| Reset Password | `{{ .ConfirmationURL }}` | Reset your password |
| Change Email | `{{ .ConfirmationURL }}` | Confirm your new address |

> **Sinhala and Tamil above are unreviewed**, like the rest of the app's
> translations. Get a native speaker to read them before release — an email is
> harder to correct after the fact than a screen.

---

## 6. Phone OTP — the honest position

**Every** SMS route costs money. There is no free tier:

| Provider | Notes |
|---|---|
| Twilio | Best supported. Reported as expensive for Sri Lanka. |
| MessageBird / Vonage | Built in; compare per-message rates for `+94`. |
| TextLocal | Community-supported. |
| Local Sri Lankan aggregator | Usually cheapest for `+94`, needs the Send SMS Hook. |

For a non-standard provider, Supabase's
[Send SMS Hook](https://supabase.com/docs/guides/auth/auth-hooks/send-sms-hook)
replaces the built-in sender with your own function. The same hook can deliver
over **WhatsApp** instead of SMS — worth noting, since this app already uses
WhatsApp for expert escalation, so your users have it. WhatsApp Business API
is also paid, but the per-message economics differ.

**Leave `PHONE_AUTH_ENABLED=false` on Render.** The backend already returns a
clear 403 — *"Phone sign-in is not available right now — please use email"* —
and gates it before touching the rate limiter or Supabase, so nothing is
charged or leaked while it is off.

When you do enable it: set the provider credentials in **Authentication →
Providers → Phone**, set `PHONE_AUTH_ENABLED=true`, and re-check the rate
limits, because SMS costs money per attempt and a loose limit is a bill.

---

## 7. Verify it works

In order. Stop at the first failure.

1. **Domain shows Verified** in Resend.
2. **Send a test** from Supabase → Authentication → Emails → SMTP Settings.
3. **Register through the app** with a real address and confirm the email
   arrives — not from the dashboard, from the actual signup path.
4. **Check Resend → Logs.** Confirm `delivered`, not `bounced` or `complained`.
5. **Check the spam folder.** If it landed there, your DNS is incomplete —
   revisit DMARC.
6. **Open it on a phone**, which is where it will actually be read. Check the
   Sinhala and Tamil render (missing glyphs show as boxes).
7. **Test with images disabled** — it should be perfectly readable, because
   there are none.

Send yourself one of each template. Four emails, ten minutes, and it is the
only way to know the variables interpolated correctly.

---

## 8. Watch out for

- **Resend's daily cap (100) bites before the monthly one (3,000).** A demo
  day with a hundred signups exhausts it.
- **Supabase's own rate limit is separate** and defaults to 30/hour. Both must
  allow the traffic.
- **One verified domain on the free tier**, so a separate staging domain means
  paying.
- **30-day log retention.** A deliverability problem older than a month is
  invisible.
- **The API key is a sending credential.** It lives in Supabase's SMTP config
  and nowhere else — never in the app, never in the repo.
- **`p=quarantine` too early** will silently bin your own mail. Sit at
  `p=none` until the reports are clean.

---

## Sources

- [Supabase — Send emails with custom SMTP](https://supabase.com/docs/guides/auth/auth-smtp)
- [Resend — Send emails using Supabase with SMTP](https://resend.com/docs/send-with-supabase-smtp)
- [Resend — Configure Supabase to send from your domain](https://resend.com/blog/how-to-configure-supabase-to-send-emails-from-your-domain)
- [Resend — Account quotas and limits](https://resend.com/docs/knowledge-base/account-quotas-and-limits)
- [Supabase — Phone Login](https://supabase.com/docs/guides/auth/phone-login)
- [Supabase — Send SMS Hook](https://supabase.com/docs/guides/auth/auth-hooks/send-sms-hook)
