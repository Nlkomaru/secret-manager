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
