---
name: nextjs-ts
description: Next.js 16 + TypeScript conventions. Use when working on Next.js App Router projects - server components by default, route handlers, Tailwind 4, shadcn/ui, next/link and next/image.
---

# Next.js + TypeScript Conventions

## Framework
- **Next.js 16** (App Router, not Pages Router)
- **React 19** with server components by default
- **TypeScript** throughout
- **Tailwind CSS 4** for styling (using `@tailwindcss/postcss`)

## Project Structure
```
app/
├── (routes)/       # Route groups / layout organization
├── api/            # API routes (route handlers)
├── layout.tsx      # Root layout
├── page.tsx        # Home page
└── globals.css     # Global styles
components/
├── ui/             # Reusable UI primitives (Radix, shadcn-style)
├── shared/         # Shared components
└── features/       # Feature-specific components
lib/                # Utilities, API clients, helpers
public/             # Static assets
```

## Conventions
- Use `'use client'` only when necessary (interactivity, hooks, browser APIs)
- Keep server components as the default
- Fetch data in server components where possible
- Use `Route Handlers` (not API routes in `/pages/api`) for API endpoints
- Use `next/link` for navigation, not `<a>` tags
- Use `next/image` for images with explicit width/height
- Use `shadcn/ui` / `Radix UI` primitives for accessible components
- Use `lucide-react` for icons
- Use `clsx` + `tailwind-merge` for conditional class merging

## State & Data
- Prefer server-side data fetching
- Use `URL search params` for filter/sort state
- Use React context sparingly — prefer component composition
- Use `server actions` for form mutations

## ESLint
- Use the built-in `eslint-config-next` config
- Run `npm run lint` before commits
