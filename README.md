# NEWSKILL PRO — Building Brands Through Visual Power

Responsive website starter for NEWSKILL PRO. Uses the black, gold/yellow and white brand palette.

## Current status

- Public marketing site: implemented in `index.html`.
- Login, registration, email verification, password reset, logout and basic account dashboard UI: wired to Supabase Auth **when configured**.
- Project request/profile/file upload code: depends on the SQL schema and private Storage bucket below.
- Admin UI: checks the trusted `app_metadata.role === "admin"` claim. Registration metadata is never used to grant admin.
- GitHub Pages workflow: included. Enable Pages with **GitHub Actions** in repository Settings → Pages.
- This is a starter, not yet a production-complete order management system. Quotations, invoices, revisions, notifications and full admin CRUD need additional implementation and testing.

## Deploy static site to GitHub Pages

1. Open this repository's **Settings → Pages**.
2. Under **Build and deployment**, select **GitHub Actions** as the source.
3. The included workflow deploys on pushes to `main`. Check **Actions** for the deployment result.
4. The project URL should be `https://saidudauda.github.io/newskill.com/` after a successful workflow. A custom domain can be connected separately.

GitHub Pages is static hosting. It cannot safely host a server-side auth service or database. Do not put service-role keys, SMTP credentials, or other secrets in this repository.

## Configure Supabase (required for real accounts)

1. Create a Supabase project at https://supabase.com/.
2. In Project Settings → API, copy the **Project URL** and the publishable/anon key.
3. In Supabase Authentication → URL Configuration, add the deployed GitHub Pages URL to Site URL and Redirect URLs, e.g. `https://saidudauda.github.io/newskill.com/**`. Also add localhost for development if needed.
4. In Authentication → Email, configure verification and password-reset email delivery. Confirm the sender/domain settings before production.
5. In Authentication → Rate Limits, configure sensible limits and SMTP as appropriate.
6. Copy `config.example.js` to `config.js`, replace placeholders, and commit the file only with the public URL and publishable/anon key. These values are designed to be public; security must come from RLS policies. Never use the service-role key in browser code.
7. Run `supabase/schema.sql` in the Supabase SQL Editor.
8. Create a **private** Storage bucket named `project-files` with a 10 MB file-size limit and allowed MIME types appropriate to the business. Apply the Storage policies in `supabase/schema.sql`.
9. Test sign-up, email verification, login, logout, reset link, profile edit, request creation, file access as a second customer, and deletion-request flow.

### Granting administrator access securely

Do **not** set an admin role from the public sign-up form, user-editable metadata, or a public table. Only a trusted project owner using the Supabase Dashboard or a secured server-side Admin API should set the user's `app_metadata.role` to `admin`. Never expose the service-role key to the browser. Re-login/refresh the session after role changes. Database RLS policies must independently enforce permissions.

## Features included in this starter

- Responsive landing page, services, portfolio concept tiles, workflow and contact section
- Sign-up with name, email, phone, password confirmation, password guidance and Terms/Privacy consent
- Email verification flow through Supabase Auth
- Login with show/hide password and reset-password email
- Secure session handling via Supabase Auth client
- Basic customer dashboard, profile updates, project request submission, private upload attempt and project list
- Account deletion request record (a request only; actual deletion needs a verified operator workflow)
- Admin navigation gated by trusted auth app metadata

## Production work still needed

- Implement admin CRUD and audit logging, with server-enforced authorization for every privileged action
- Quotation, invoice, payment, revision, notification and messaging data models/workflows
- Secure account deletion orchestration covering Auth user, profile, projects and uploaded files, with legal retention checks
- Anti-spam controls / CAPTCHA or an equivalent verified challenge for public forms
- Configure and test SMTP, OAuth provider(s), backup/restore, monitoring and incident response
- Replace concept portfolio tiles with approved work and confirm official WhatsApp number, business address, contact email and final legal copy
- Add automated accessibility, browser, RLS and security tests; do not use real customer information until reviewed

## Files

- `index.html` — static frontend
- `config.example.js` — safe public client configuration template
- `supabase/schema.sql` — starter schema and row-level security policies
- `.github/workflows/deploy.yml` — GitHub Pages deployment
