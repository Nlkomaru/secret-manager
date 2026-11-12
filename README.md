# secret-manager

Zero-config secret loader and centralized management for `nlkomaru` projects.

## Architecture

- **AWS SSM Parameter Store** for zero-config secret storage with hierarchical fallback:
  1. `/github/nlkomaru/shared/*` (All repositories shared)
  2. `/github/nlkomaru/shared/<env>/*` (Shared per environment)
  3. `/github/nlkomaru/<project>/*` (Project shared)
  4. `/github/nlkomaru/<project>/<env>/*` (Project environment-specific)
- **All secrets are stored as `SecureString`** (KMS encrypted).
- **GitHub Actions OIDC** via IAM Role `arn:aws:iam::161381425016:role/github-actions-ssm-role`
- **Zero GitHub Secrets**: Repositories simply call this action with `permissions: id-token: write`.

### Naming Convention (Scope-Based Naming)

Following *The Art of Readable Code* rule that **larger scopes require longer, more descriptive names**:

- Parameters placed in `/github/nlkomaru/shared/*` are injected into **every repository** via `GITHUB_ENV`. Give them an explicit prefix and descriptive name so they never collide with generic tool variables or project-local secrets (e.g., use `NIKO_CI_AWS_ACCESS_KEY_ID`, `NIKO_CI_BUCKET_NAME`, `NIKO_CI_S3_URL` instead of `AWS_ACCESS_KEY_ID`, `BUCKET_NAME`, `S3_URL`).
- Project-specific parameters under `/github/nlkomaru/<project>/*` have a narrow scope and can use concise, standard names expected by the application or CLI.

---

## How to Use in GitHub Actions

In any repository under `nlkomaru/*`:

```yaml
permissions:
  contents: read
  id-token: write # Required for AWS OIDC

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Load secrets directly via secret-manager
      - name: Load Secrets
        uses: nlkomaru/secret-manager@main
        with:
          env: production
          export-json: ${{ runner.temp }}/worker-secrets.json
          # Optional: only write these keys to the JSON file (fails if any is missing)
          export-json-keys: |
            BETTER_AUTH_SECRET
            R2_BUCKET_NAME
```

---

## Secret Management CLI

Push `.env` variables to AWS SSM Parameter Store:

```bash
# Push to project environment (default: omoide/production)
pnpm push --project omoide --env production

# Push to shared parameters (/github/nlkomaru/shared/*)
pnpm push:shared
```
