# Contributing

Thanks for looking. This is solo-maintained, so replies to issues and pull requests may take a few days.

## Ground rules

- Every step must be idempotent: running it twice leaves the server exactly as after the first run.
- Every step must support `--dry-run`: it prints what it would change and changes nothing.
- The SSH change is applied last and verified before the old settings are discarded. Do not reorder that.
- Plain bash only, no extra dependencies on the target server.

## Lint and test locally

You need `shellcheck` and `shfmt`.

```bash
shellcheck $(git ls-files '*.sh')
shfmt -d $(git ls-files '*.sh')
bash tests/test_cli.sh
```

CI runs the same checks, with the test inside an `ubuntu:24.04` container. To do that yourself:

```bash
docker run --rm -v "$PWD":/work -w /work ubuntu:24.04 bash tests/test_cli.sh
```

Optionally install the hooks in `.pre-commit-config.yaml` with `pre-commit install`.

Never run `bootstrap.sh` on a machine you care about while testing. Use a container or a throwaway VM.

## Branches and commits

- Branch from `main`: `feat/<short-name>`, `fix/<short-name>`, `docs/<short-name>` or `chore/<short-name>`.
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/).
- `main` only changes through pull requests, squash-merged after CI passes.

## Pull requests

Fill in the template: what, why, how you tested it, and whether you tested a re-run. If a change touches a step, I expect to see the second run described, not only the first.
