---
name: page-composition
description: Add or change a routed page or view in apps/web/src/pages — routing, data orchestration, layout, loading and error states. Use when creating a screen or changing what a route renders.
allowed-tools: Read Grep Glob Edit Write
---

# Page composition

Loads only while working in `apps/web/src/pages/`.

## What a page is

The **only** layer allowed to orchestrate: it decides which data this screen
needs, asks the data layer for it, and arranges components. It is the seam
between routing and presentation, and it should be boring.

A page contains: route params parsing, data-layer calls, layout, and the three
states. It does not contain business rules, formatting logic, or reusable
markup — those move down into components or up into the API.

## The three states, at page level

```
loading  → a skeleton with the final layout's shape, so nothing jumps
empty    → distinct from loading, and it says what the user can do next
error    → error.message from the API, plus a retry
```

A page that renders only the success path is not finished, and review treats it
that way. The empty state is the one everyone forgets and every user eventually
sees on day one.

## Rules

- Parse and **validate route params** at the top. A malformed id in the URL is
  user input, and it reaches this file first.
- Fetch at the page, pass data down. Never let a child component fetch — see the
  `data-layer` skill for why.
- No business rule here. If the page decides who may see what, the server is
  missing an authorization check and the page is only hiding the button.
- Set the document title and the page's primary heading. Both, and matching —
  it is the cheapest accessibility and SEO win available.
- Route-level code splitting by default. A page nobody visits should not be in
  the initial bundle.

## Before creating a page

Check whether this is genuinely a new route or a state of an existing one. A
"page" that differs from another by one boolean is usually a query parameter,
and splitting it duplicates the loading, empty and error handling three times.
