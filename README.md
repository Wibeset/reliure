# Reliure — site

One-page site for the Reliure iOS app, served by GitHub Pages. Static HTML/CSS, no build step.

- `index.html` — English (default)
- `fr/index.html` — French
- `assets/` — shared stylesheet and icons

Layout follows cronicle.me: logo and name on the left of the nav, language / App Store / QR code on the right; a large serif headline (Instrument Serif, Google Fonts); a scroll tour where the phone stays pinned while four screens go by (Home, Continue reading, Add a book, Statistics), each with a callout whose line points at a spot on the screen (`assets/tour.js`); a mission sentence; four highlights in a 2 × 2 grid; a closing CTA; and a footer ending on an oversized wordmark. Both language pages share the same markup, so edit them together.

Colors come from the app's asset catalog (`rendu-ios/Reliure/Resources/Assets.xcassets`); dark mode follows the system setting.

## Before launch

- Replace `idXXXXXXXXXX` in both pages with the App Store ID.
- Replace the `.qr` placeholder with a QR code of the App Store link.
- Replace the four `.screen` placeholders in the tour with real screenshots, then adjust each callout's `--x` / `--y` (percent of the phone's width / height) so the line lands on the right spot.

## Deploy

`.github/workflows/pages.yml` publishes the site on every push to `main` (or by hand from the Actions tab). It copies only `index.html`, `fr/`, `assets/`, `CNAME` and `.nojekyll` into the published artifact.

One-time setup:

1. Push the repo to GitHub.
2. Settings → Pages → Source: **GitHub Actions**.
3. Settings → Pages → Custom domain: `reliure.me` (the `CNAME` file alone isn't enough when deploying with Actions), then tick **Enforce HTTPS** once the certificate is issued.
4. DNS at the registrar:
   - apex `reliure.me`: `A` records `185.199.108.153`, `185.199.109.153`, `185.199.110.153`, `185.199.111.153` (and `AAAA` `2606:50c0:8000::153` … `2606:50c0:8003::153` for IPv6)
   - `www`: `CNAME` to `<github-user>.github.io`

The pages use root-relative `hreflang` links (`/`, `/fr/`), so they expect to be served at the domain root, as with the custom domain above.
