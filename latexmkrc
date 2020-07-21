#!/usr/bin/env perl

# compile
$pdf_mode = 3;  # use dvipdf
$latex = 'platex -kanji=utf-8 -interaction=nonstopmode -halt-on-error -shell-escape';
$bibtex = 'pbibtex';
$dvipdf = 'dvipdfmx %O -o %D %S';
$makeindex = 'mendex %O -o %D %S';

# update
# $compiling_cmd = "find . -type f -name '*.tex' -print0 | xargs -0 sed -i.orig -e 's/。/．/g; s/、/，/g'";

# preview
if ($^O eq 'darwin') {
    $pdf_previewer = 'open -a Preview.app %S';
} elsif ($^O eq 'linux') {
    $pdf_previewer = 'evince';
}
$preview_continuous_mode = 1;
