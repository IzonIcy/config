---
name: rust-dev
description: Rust development conventions. Use when writing Rust - cargo build/test, clippy, rustfmt, anyhow/thiserror, serde, clap, tokio, minimize dependencies.
---

# Rust Development Conventions

## Tooling
- **cargo** for building, testing, and running
- **clippy** for linting (`cargo clippy`)
- **rustfmt** for formatting (`cargo fmt`)
- Always run `cargo check` before `cargo build`

## Testing
- `cargo test` for unit + integration tests
- Unit tests inline in source files (in `#[cfg(test)]` modules)
- Integration tests in `tests/` directory
- Use `#[should_panic]` for expected failures
- Use `assert_eq!`, `assert_ne!`, `assert!` — avoid custom macros

## Style
- Edition 2021 preferred (2024 for newer projects)
- Use `anyhow` for application-level error handling
- Use `thiserror` for library-level error types
- Prefer `clap` derive API for CLI argument parsing
- Use `serde` + `serde_json`/`toml` for serialization
- Name binaries via `[[bin]]` in Cargo.toml
- Use `crossterm` + `ratatui` for TUI applications
- Use `tokio` for async runtime

## Project Structure
```
project/
├── src/
│   ├── main.rs     # Binary entry point
│   ├── lib.rs      # Library root
│   └── ...         # Modules
├── tests/          # Integration tests
├── Cargo.toml
└── Cargo.lock
```

## Dependencies
- Minimize dependency count
- Prefer pure Rust solutions (avoid C bindings unless necessary)
- Pin major versions, allow semver-compatible minor/patch
