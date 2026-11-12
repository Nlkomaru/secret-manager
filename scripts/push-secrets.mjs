import { execFileSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";

const args = process.argv.slice(2);
const isSharedMode = args.includes("--shared");

function getArgValue(flag) {
  const idx = args.indexOf(flag);
  return idx !== -1 && args[idx + 1] ? args[idx + 1] : null;
}

const envFilePath = getArgValue("--file") || resolve(process.cwd(), ".env");
if (!existsSync(envFilePath)) {
  console.error(`Error: .env file not found at ${envFilePath}`);
  console.error(
    "Usage: node push-secrets.mjs [--shared] [--project <name>] [--env <production|preview>] [--file <path>]"
  );
  process.exit(1);
}

const owner = process.env.GITHUB_OWNER || getArgValue("--owner") || "nlkomaru";
const project = process.env.PROJECT_NAME || getArgValue("--project") || "omoide";
const environment = process.env.TARGET_ENV || getArgValue("--env") || "production";
const region = process.env.AWS_REGION || getArgValue("--region") || "ap-northeast-1";

const envContent = readFileSync(envFilePath, "utf-8");
const lines = envContent.split("\n");

console.log(`Pushing secrets from: ${envFilePath}`);
console.log(
  `Target: ${isSharedMode ? `/github/${owner}/shared/*` : `/github/${owner}/${project}/${environment}/*`}`
);
console.log(`Region: ${region}\n`);

for (const line of lines) {
  const trimmed = line.trim();
  if (!trimmed || trimmed.startsWith("#")) continue;

  const equalIndex = trimmed.indexOf("=");
  if (equalIndex === -1) continue;

  const key = trimmed.slice(0, equalIndex).trim();
  let value = trimmed.slice(equalIndex + 1).trim();

  // Remove quotes
  if (
    (value.startsWith('"') && value.endsWith('"')) ||
    (value.startsWith("'") && value.endsWith("'"))
  ) {
    value = value.slice(1, -1);
  }

  if (!value) {
    console.log(`Skipping empty key: ${key}`);
    continue;
  }

  const path = isSharedMode
    ? `/github/${owner}/shared/${key}`
    : `/github/${owner}/${project}/${environment}/${key}`;

  try {
    execFileSync(
      "aws",
      [
        "ssm",
        "put-parameter",
        "--region",
        region,
        "--name",
        path,
        "--value",
        value,
        "--type",
        "SecureString",
        "--overwrite",
      ],
      { stdio: "ignore" }
    );
    console.log(`✓ [SecureString] ${path}`);
  } catch (err) {
    console.error(`✗ Failed to put parameter: ${path}`, err.message);
  }
}

console.log("\nDone syncing to AWS SSM Parameter Store!");
