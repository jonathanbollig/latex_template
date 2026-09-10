# written by Claude @07.09.26

# Engine: 1 = pdflatex
$pdf_mode = 1;

# Keep the repo clean
$out_dir = 'build';

# -synctex=1 enables source <-> PDF jumping in VS Code
# -interaction=nonstopmode stops it hanging on an error waiting for input
# -file-line-error gives "file.tex:42: message" instead of just "l.42"
$pdflatex = 'pdflatex -synctex=1 -interaction=nonstopmode -file-line-error %O %S';

# Bibliography: latexmk detects biber vs bibtex from the .bcf file itself.
# 2 = run it, and treat .bbl as a removable build artifact.
$bibtex_use = 2;

# main.tex's \draftbuildtrue also skips the bibliography, so skip biber too
# in that mode -- citations just render as "undefined" until draft mode ends.
open(my $main_tex_fh, '<', 'main.tex') or die "can't read main.tex: $!";
my $draftbuild = grep { /^\s*\\draftbuildtrue/ } <$main_tex_fh>;
close $main_tex_fh;
if ($draftbuild) {
    # Write a stub %B.blg too -- latexmk parses it for a "Data source" line and
    # errors out if the biber log it expects is missing or doesn't have one.
    $biber = 'echo "[draft mode: skipping biber]" && printf "> INFO - Reading \'references.bib\'\n" > %B.blg && touch %B.bbl';
}

# So that a bare `latexmk` builds the thesis regardless of which file is open
@default_files = ('main.tex');

# latexmk -c removes these too
$clean_ext = 'synctex.gz run.xml bbl';

# Guard against a runaway rerun loop from an unstable cross-reference
$max_repeat = 5;

# TeX cannot create directories; \include needs these to exist
use File::Path 'make_path';
foreach my $dir ('chapters', 'frontmatter') {
    make_path("$out_dir/$dir");
}