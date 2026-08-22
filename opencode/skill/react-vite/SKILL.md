---
name: react-vite
description: React + Vite conventions. Use when working on React/Vite projects - functional components and hooks, react-router, named exports, data fetching with loading/error/empty states.
---

# React + Vite Conventions

## Framework
- **React 18/19** with functional components and hooks
- **Vite** as the build tool
- **TypeScript** preferred (JavaScript also accepted)
- No class components — ever

## Tooling
- `npm run dev` for development
- `npm run build` for production build
- `npm run preview` for previewing production build

## Project Structure
```
src/
├── components/     # React components
├── pages/          # Page-level components (if using react-router)
├── hooks/          # Custom hooks
├── utils/          # Utilities
├── api/            # API client code
├── types/          # TypeScript type definitions
├── App.tsx         # Root component
└── main.tsx        # Entry point
public/             # Static assets
```

## Conventions
- Use `react-router-dom` for routing (v6+)
- Use `const` for all component declarations
- Name files in PascalCase for components
- Use named exports for components, not default exports
- Keep components small and focused
- Extract reusable logic into custom hooks
- Use CSS modules, Tailwind, or inline styles — no CSS-in-JS libraries

## Data Fetching
- Use `fetch` or a lightweight wrapper
- Handle loading, error, and empty states in every data-fetching component
- Use `useEffect` for data fetching (or a library like `@tanstack/react-query`)
