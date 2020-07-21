# rsj-report
[![Build Status](https://travis-ci.com/jsk-report-template/rsj-report.svg?branch=master)](https://travis-ci.com/github/jsk-report-template/rsj-report)

Latex template for RSJ

### 1. Edit LaTeX files

### 2. Make pdf

```bash
make
# or
latexmk -pvc main
```

### Optional. Convert Japanese punctuations

```bash
make pub
# or
make publish
# will convert 「、」「。」 to 「，」「．」 in *.tex
# Original files are backed up as *.tex.orig
```

### Optional. cleaning

```bash
make clean
# or
make wipe
```
