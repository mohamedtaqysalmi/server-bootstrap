# Contributing

Thanks for looking. This is solo-maintained, so replies to issues and pull requests may take a few days.

## Ground rules

- Every step must be idempotent: running it twice leaves the server exactly as after the first run.
- Every step must support `--dry-run`: it prints what it would change and changes nothing.
- The SSH change is applied last and verified before you rely on it. Do not reorder that.
- Plain bash only, no extra dependencies on the target server.

## Lint and test locally

You need `shellcheck` and `shfmt`.

```bash
shellcheck $(git ls-files '*.sh')
shfmt -d $(git ls-files '*.sh')
bash tests/test_cli.sh
docker run --rm -e BOOTSTRAP_TEST_IN_CONTAINER=1 -v "$PWD":/src:ro -w /src \
  ubuntu:24.04 bash tests/test_steps.sh
```

Never run `bootstrap.sh` on a machine you care about while testing. Use a container or a throwaway VM.

## Branches and commits

- Branch from `main`: `feat/<short-name>`, `fix/<short-name>`, `docs/<short-name>` or `chore/<short-name>`.
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/).
- `main` only changes through pull requests, squash-merged after CI passes.

## Pull requests

Fill in the template: what, why, how you tested it, and whether you tested a re-run. If a change touches a step, I expect to see the second run described, not only the first.
