_Created by Claude [[2026-09-08]]_

# LaTeX + VS Code workflow

Local files, normal git repo, Overleaf only as a review copy for the supervisor. System: [[P1 Linux (CachyOS + KDE) Installation]]. References: [[Zotero Nextcloud Sync Setup and Usage]].

## Install

- `paru -S texlive-meta texlive-bibtexextra biber`
- `paru -S texlive-binextra` — `latexdiff`, `latexmk`, `chktex`
- `paru -S poppler` — `pdftoppm`/`pdfinfo`, lets Claude Code rasterize the PDF and look at it
- VS Code: **LaTeX Workshop** (James Yu), **LTeX+** (LanguageTool that understands LaTeX markup)
- `texlive-meta` already covers siunitx, mhchem, chemfig, pgfplots, biblatex-phys, todonotes

## Repo structure

```
thesis/
├── main.tex            # documentclass + \include list only
├── preamble.tex        # packages & their config
├── macros.tex          # own notation, \input from preamble
├── frontmatter/        # titlepage, abstract, abstract_german, declaration
├── chapters/           # 01-abc.tex ...
├── figures/
├── references.bib      # auto-written by Zotero BBT, commit anyway
├── .latexmkrc
├── .vscode/settings.json
├── .gitignore
└── CLAUDE.md
```

- `\input` for preamble/frontmatter, `\include` for chapters (gives per-chapter `.aux` → `\includeonly{}` works)
- Hyphens in filenames, not underscores
- `.gitignore`: `build/` does the real work, but list the extensions too in case something is ever built outside it — `*.aux *.bbl *.bcf *.blg *.fdb_latexmk *.fls *.lof *.log *.lot *.out *.run.xml *.synctex.gz *.toc *.xdv`. Plus `*conflicted copy*`, because the repo lives in a Nextcloud folder.

## main.tex — document order

`main.tex` holds the `\documentclass`, the `\input`/`\include` list, and nothing else.

```latex
\documentclass[12pt,a4paper,oneside,openany]{book}
\input{preamble}
\begin{document}
\input{frontmatter/titlepage}
\input{frontmatter/abstract}
\input{frontmatter/abstract_german}
\tableofcontents

\include{chapters/01-abc} ...

\appendix
\include{chapters/a-sup-abc} ...

\printbibliography[heading=bibintoc]
\input{frontmatter/declaration}
\end{document}
```

- Appendices come **before** the bibliography; the declaration is the last page.
- `\chapter*` keeps a frontmatter heading unnumbered but also keeps it out of the ToC → follow every one with `\addcontentsline{toc}{chapter}{...}`.
- `heading=bibintoc` is what puts "Bibliography" in the ToC.

### Page numbering

Plain arabic, continuous from the title page (1) to the last page. **No** `\frontmatter`/`\mainmatter`/`\backmatter` — the roman-then-arabic split those give you is a convention for a 200-page bound book and just makes a thesis this length harder to navigate ("is that page 4 or page iv?").

Because those three commands are gone, `book` is now doing nothing that `report` would not; it is kept only to avoid churn. The `titlepage` environment resets the page counter to 1 *after* it ends when `oneside` is set, so `frontmatter/titlepage.tex` ends with an explicit `\setcounter{page}{2}`. Remove that and you get two page-1s and a duplicate-PDF-anchor warning.

### Screen vs print

Currently set up for **reading on screen**. Three things differ from a print setup, and all three are one-line switches:

|                  | screen (now)              | bound print copy               |
|------------------|---------------------------|--------------------------------|
| `\documentclass` | `oneside,openany`         | `twoside,openright`            |
| `geometry`       | `margin=3cm`              | `margin=3cm,bindingoffset=1cm` |
| `hypersetup`     | `linkcolor=linkblue` etc. | all three colours `black`      |

`oneside,openany` is what keeps the page count honest — `openright` pads chapters onto right-hand pages with blanks, which is right on paper and just noise in a PDF viewer. `hyperref` also gets `bookmarksnumbered`, `bookmarksopen` and `pdfstartview=FitH`, so the viewer opens with a usable sidebar outline fitted to the page width.

Both commented in place in `main.tex` and `preamble.tex`; flip them when a printed copy is actually needed.

## .latexmkrc

Repo root. Read from the **cwd where latexmk is invoked**, so always build from the root.

```perl
$pdf_mode = 1;                    # pdflatex
$out_dir = 'build';
$pdflatex = 'pdflatex -synctex=1 -interaction=nonstopmode -file-line-error %O %S';
$bibtex_use = 2;                  # run biber, treat .bbl as removable
@default_files = ('main.tex');    # bare `latexmk` builds the thesis
$clean_ext = 'synctex.gz run.xml bbl';
$max_repeat = 5;

# TeX cannot create directories; \include needs these to exist
use File::Path 'make_path';
foreach my $dir ('chapters', 'frontmatter') {
    make_path("$out_dir/$dir");
}
```

- Add every new `\include` subdirectory to that list, or → `\openout` fails → emergency stop
- `latexmk` / `latexmk -pvc` (watch) / `latexmk -c` (clean) / `latexmk -C` (clean incl. PDF)

## .vscode/settings.json

Commit it. `args: []` is the point — nothing overrides `.latexmkrc`.

```json
{
  "latex-workshop.latex.outDir": "%DIR%/build",
  "latex-workshop.latex.tools": [
    { "name": "latexmk-rc", "command": "latexmk", "args": [], "env": {} }
  ],
  "latex-workshop.latex.recipes": [
    { "name": "latexmk (rc)", "tools": ["latexmk-rc"] }
  ],
  "latex-workshop.latex.rootFile.doNotPrompt": true,
  "latex-workshop.latex.autoBuild.run": "onSave",
  "latex-workshop.view.pdf.viewer": "tab",
  "latex-workshop.latex.autoClean.run": "never"
}
```

- `outDir` does not affect the build; it tells the extension where to find PDF + synctex. Must match `$out_dir` or preview/SyncTeX silently break.
- Ctrl+Alt+B build, Ctrl+Alt+V preview, Ctrl+Alt+J source→PDF, Ctrl+click PDF→source
- First line of each chapter file: `% !TEX root = ../main.tex`

## Preamble — order matters

1. `amsmath, amssymb, mathtools, bm` **before** `newtxtext, newtxmath` (otherwise: `LaTeX Error: Command \Bbbk already defined`)
2. `csquotes` before `biblatex`
3. `hyperref` second-to-last
4. `cleveref` **after** hyperref
5. `todonotes` after hyperref too (it uses `\hypertarget` for the todo list)

Everything else is free. `\input{macros}` at the end. `==> First Aid for cleveref.sty applied!` in the log is normal, ignore.

## Citations

```latex
\usepackage[backend=biber, style=phys, autocite=inline, biblabel=brackets,
            sorting=none, giveninits=true]{biblatex}
\addbibresource{references.bib}
```

- `style=phys` defaults to **superscript** citations (APS convention). `autocite=inline` + `biblabel=brackets` → `[1]`. Set both or list and text disagree.
- Changing biblatex options invalidates the `.bbl` → `latexmk -C && latexmk`

Usage:

- `\autocite{key}` — source at end of statement
- `\textcite{key}` — authors as sentence subject → "Kufner et al. [1]"
- `\autocite{a,b,c}` → `[2–4]`; `\autocite[p.~112]{key}`; `\autocite[see][Ch.~4]{key}` (prenote, postnote — a single optional arg is the **postnote**)
- Never plain `\cite` — `\autocite` lets one preamble option reformat the whole thesis
- Keys come from Zotero BBT, autocompleted by LaTeX Workshop inside `\autocite{`

### Language

`\usepackage[english]{babel}`. The thesis is English. The Zusammenfassung is the single German page and is left as plain text — no `ngerman`, no `otherlanguage`, no extra package. English hyphenation on four sentences is not worth the machinery. (If a longer German part ever appears: `paru -S texlive-langgerman`, `[main=english,ngerman]{babel}`, wrap it in `otherlanguage`.)

### siunitx

`separate-uncertainty = true` → `\qty{4.2(3)}{\pico\second}` prints "4.2 ± 0.3 ps". Set it `false` for the compact "4.2(3) ps"; the option name reads backwards, so check the PDF rather than the option.

Build chain is pdflatex → biber → pdflatex → pdflatex, handled by latexmk. `[?]` on first build after adding a citation is normal; rebuild. If it persists → check `build/main.blg`.

`\cref` for everything that is not a citation: `\cref{fig:setup}` → "Fig. 3". Label prefixes `fig: tab: eq: sec: ch:`.

## Zotero → references.bib

Setup in [[Zotero Nextcloud Sync Setup and Usage]]. Relevant here:

- Export format **Better BibLaTeX** (not BibTeX), "Keep updated" → `references.bib` in repo root
- Prefs → BBT → Automatic export = **on change**
- Since Zotero 8 keys live in a native field and are always pinned. Changing the key format does **not** rewrite existing keys.
- Regenerating keys after citations exist breaks every `\autocite` silently → only do it early, back up `~/Zotero/zotero.sqlite` first
- Brace protected capitals in the Zotero title field: `{XPS}`, `{TiO2}`, `{DFT}`

### Slim down the export

`abstract` is ~80% of the file's bytes and `style=phys` never prints it. `file` is an absolute path into `/mnt/Data/zotero/…` that means nothing on another machine and rewrites itself on every export, churning the git diff. Drop both.

**Zotero → Settings → Better BibTeX → Export → Fields**

1. In **"Fields to omit from export"**, paste:

```
abstract,file,keywords
```

2. Set **"Export file paths"** to off.

Both are global BBT settings, not per-collection. To make them take effect on the existing file, right-click the collection → *Export Collection…* → Better BibLaTeX → overwrite `references.bib`. (Editing any item also refires the "on change" auto-export.)

Do this **before `git init`**, so the local paths never enter the history.

## Overleaf review loop (to do later)

Free plan: 1 collaborator, no git bridge, no track changes. So:

- One Overleaf project, created once, stable share link, supervisor invited once
- Refresh by dragging changed `.tex` files onto the Overleaf file tree (it prompts to overwrite)
- Tag before each round: `git tag review-2026-10-15 && git push --tags`
- Marked-up PDF for the supervisor: `latexdiff-vc --git --pdf -r review-2026-10-15 main.tex`
- Agree on **one** feedback channel. PDF annotation is safest — no conflict risk.
- If they edit in Overleaf: don't touch those files locally until pulled back and committed as a separate "supervisor edits" commit. No merge machinery here, last write wins.

Compile compatibility: avoid `minted` (needs shell-escape), use `listings`. Build heavy TikZ/pgfplots figures locally to PDF and `\includegraphics` them.

## Gotchas

|Symptom|Cause|
|---|---|
|`\openout` fails, emergency stop on `\include`|missing `build/<subdir>/`, add to `make_path` list|
|`Command \Bbbk already defined`|`amssymb` loaded after `newtx`|
|Biber never runs, "Please (re)run Biber"|pdflatex exited ≠ 0; fix the real error above it|
|`Empty bibliography` warning|no `\cite` yet, harmless|
|SyncTeX does nothing|`outDir` ≠ `$out_dir`|
|stale `main.toc` in repo root|leftover from before `$out_dir`, delete|
|frontmatter heading missing from ToC|`\chapter*` needs a matching `\addcontentsline`|

## Claude Code

`CLAUDE.md` at repo root holds the working rules — build command, log-grepping instead of dumping, one sentence per line, siunitx/mhchem conventions, and the strict no-invented-citations rule. Keep everything under git so agent diffs are reviewable.