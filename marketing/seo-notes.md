# SEO / distribution notes

Source of the approach: *How DissectMac Gets Users From Around the World* by Kapil of DissectMac
(https://dissectmac.com/blog). The PDF itself is **deliberately not committed** — it is someone
else's document, and `/*.pdf` is git-ignored for that reason; keep your copy locally. Its three
levers are a site built for search, an SEO audit tool, and directory listings. This file records
what is done in the repo and what can only be done by a human with a login.

## Done, in the repo

| Playbook item | Where it lives |
|---|---|
| One page per search intent | `docs/offline-dictionary-windows.html`, `docs/look-up-words-while-reading.html`, `docs/dictionary-popup-for-pdf-windows.html`, `docs/dictionary-popup-alternatives-windows.html` |
| Direct answer near the top | The `.answer` block on each article page; the bolded first sentence under the hero on `docs/index.html` |
| Schema markup | `SoftwareApplication` + `FAQPage` on `docs/index.html`; `BreadcrumbList` + `Article`/`HowTo` + `FAQPage` on each article page |
| Fast pages | No webfont, no framework, no third-party script. `index.html` keeps its CSS inline; article pages share one same-origin `docs/assets/article.css`. The only cross-origin request on any page is the GoatCounter pixel |
| AI-search readiness | `docs/llms.txt`, plus `max-snippet:-1` robots meta so an overview may quote the answer paragraph in full |
| Sitemap | `docs/sitemap.xml`, all five URLs, `<lastmod>` bumped by hand |
| IndexNow | Key file `docs/9a1cfd86bf22913fb2d927b51f92a7fe.txt`, submitter `scripts/submit-indexnow.ps1` |
| Directory copy, unique per site | `marketing/directory-listings.md` |
| Measurable downloads | Already true: every button points at the GitHub release asset, which is counted. Read it with `scripts/download-stats.ps1` |

## Needs a human with a login

- **Google Search Console** — the property is verified by the meta tag in `docs/index.html`.
  Submit `sitemap.xml` once, then read the Queries report weekly. Without it you are guessing
  which pages to write next.
- **Bing Webmaster Tools** — add the site, easiest via *Import from Google Search Console*. Bing
  backs ChatGPT search, so it now matters on its own. If it asks for a meta tag, put the
  `msvalidate.01` tag next to the Google one in `docs/index.html`.
- **PageSpeed Insights** — https://pagespeed.web.dev, check both the mobile and desktop tabs after
  any page change. What usually kills the score is analytics and chat widgets; this site has
  neither, and should stay that way.
- **claude-seo** (the audit tool the playbook recommends), free and open source:

  ```
  /plugin marketplace add AgriciDaniel/claude-seo
  /plugin install claude-seo@agricidaniel-claude-seo
  /seo setup
  /seo audit https://ishpreet36752.github.io/WordMeaning/
  ```

  Its audit will list dozens of items; roughly six will matter. Fix those, wait two weeks, re-run.
- **The listings themselves** — `marketing/directory-listings.md` has the copy and a checklist.
  One weekend of work, and the backlinks stay.

## Waiting on the macOS build

The playbook this came from is a Mac app's playbook, and half its highest-intent directories are
Mac-only: MacUpdate, Softpedia Mac, Uptodown Mac, r/macapps, AlternativeTo's Mac filter. Those open
up when `mac/` is verified on real hardware — **not before**. Listing an untested build on a
directory that reviews submissions is how a listing gets removed and an account gets flagged.

Order: verify the .app on a Mac → cut a release with the `.dmg` → add the download to the site →
then submit anywhere Mac-specific. Until then the site says Windows, because that is what is true.

## Rules for this site specifically

- **New page? Give it its own GoatCounter `p=`.** The pixel's path is hardcoded per page; a copied
  one silently files its hits under another page. Also add the URL to `docs/sitemap.xml`, bump
  `<lastmod>`, and run `scripts/submit-indexnow.ps1`.
- **Every download link points at the GitHub release asset.** Pages counts nothing; releases are
  counted. A mirror under `docs/` would make the number wrong and untraceable.
- **Keep the pages self-contained.** No webfonts, no third-party JavaScript, no tag manager. The
  privacy claim on the front page has to be true of the site as well as the program.
- **If the site moves to a custom domain**, update the canonical, `og:url`, `og:image`,
  `twitter:image`, every JSON-LD `url`/`image`/`downloadUrl`/`installUrl`, `docs/sitemap.xml`,
  `docs/llms.txt`, and `$SiteRoot`/`$HostName` in `scripts/submit-indexnow.ps1`. `docs/robots.txt`
  starts working at that point, since crawlers only read it at a domain root.
