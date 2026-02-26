---
created: 2026-02-25T21:30:15.797Z
title: Fix broken string quoting in restricted areas table rendering
area: ui
files:
  - index.html:1850-1852
---

## Problem

The `renderRestrictedAreas()` function at index.html:1845 builds table row HTML using string concatenation. The `onchange` and `onclick` inline handlers used unescaped single quotes inside a single-quoted JS string literal, e.g.:

```js
'...onchange="saveRestrictedAreaRow('' + r.id + '',this.closest('tr'))"...'
```

JavaScript parsed `''` as two adjacent empty strings (legal) but `this.closest('tr')` broke the outer string because `'tr'` terminated the string prematurely. This caused an `Uncaught SyntaxError: Unexpected string` at line 1850, crashing the entire `<script>` block before it could run — preventing the campaign dropdown from loading at all.

## Solution

Escape the inner quotes using `\'`:

```js
'...onchange="saveRestrictedAreaRow(\'' + r.id + '\',this.closest(\'tr\'))"...'
```

**Status: FIXED** in this session (2026-02-25). Recorded here for reference in case the pattern recurs elsewhere (e.g. in future table-building functions).
