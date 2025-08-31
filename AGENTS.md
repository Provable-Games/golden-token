# Repository Guidelines

## Project Structure & Module Organization

- Source: `src/` (entry in `src/lib.cairo`; modules like `encoding.cairo`, `svg.cairo`).
- Tests: `tests/` (Starknet Foundry `snforge` tests; e.g., `tests/test_*.cairo`).
- Scripts: `scripts/` (e.g., `deploy_sepolia.sh`).
- CI: `workflows/` (lint, tests, coverage). Build artifacts in `target/`.

## Build, Test, and Development Commands

- Build: `scarb build` — compiles the Cairo contracts.
- Format: `scarb fmt` or `scarb fmt --check` — formats/checks code style.
- Test: `snforge test` — runs unit/integration tests.
- Coverage: `snforge test --coverage` — generates `coverage/coverage.lcov`.
- Fuzzing example: `snforge test --features fuzzing --fuzzer-runs 500`.
- Deploy (Sepolia): `./scripts/deploy_sepolia.sh` (requires `.env` with `STARKNET_ACCOUNT`, `STARKNET_PRIVATE_KEY`).

## Coding Style & Naming Conventions

- Language: Cairo 2 (edition `2024_07`). Indent with 4 spaces; no tabs.
- Files and modules: `snake_case.cairo`; expose via `pub mod <name>;` in `src/lib.cairo`.
- Keep functions small and single-purpose; prefer explicit types.
- Always run `scarb fmt` before pushing; CI enforces formatting.

## Testing Guidelines

- Framework: Starknet Foundry (`snforge_std`); forks configured in `Scarb.toml` (`[tool.snforge]`).
- Write tests in `tests/`, name as `test_<feature>.cairo` and functions with `#[test]`.
- Use mainnet fork tests when relevant: `#[fork("mainnet")]` (Cartridge endpoint preconfigured).
- Coverage: maintain ≥ 78% line coverage (CI checks via `lcov`).

## Commit & Pull Request Guidelines

- Commits: imperative mood, concise subject (≤72 chars), e.g., `add erc721 votes`, `update airdrop logic`.
- PRs: include summary, rationale, and linked issue. Note behavior changes, gas/size impacts, and test coverage deltas.
- Requirements: green CI (format, tests, coverage), updated docs when behavior or interfaces change.

## Security & Configuration Tips

- Dependencies pinned in `Scarb.toml`; prefer OZ components (ERC721, Ownable, ERC2981, Votes, SRC5).
- Secrets: never commit keys; provide `.env` locally for deploy scripts.
- Reentrancy/external calls: prefer internal helpers; validate ownership and bounds (see `airdrop_tokens`).
