#!/usr/bin/env python3
"""POST a signed failure payload to a Hermes webhook."""

import hashlib
import hmac
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request


def commit_message():
    try:
        return subprocess.check_output(
            ["git", "log", "-1", "--format=%s"],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
    except (OSError, subprocess.CalledProcessError):
        return ""


def pipeline_url():
    organization = os.environ.get("SEMAPHORE_ORGANIZATION_URL", "").rstrip("/")
    workflow_id = os.environ.get("SEMAPHORE_WORKFLOW_ID", "")
    pipeline_id = os.environ.get("SEMAPHORE_PIPELINE_ID", "")
    if not organization or not workflow_id:
        return ""

    url = f"{organization}/workflows/{workflow_id}"
    if pipeline_id:
        url = f"{url}?pipeline_id={pipeline_id}"
    return url


def payload():
    branch = os.environ.get("SEMAPHORE_GIT_WORKING_BRANCH") or os.environ.get("SEMAPHORE_GIT_BRANCH", "")
    return {
        "pipeline": {
            "id": os.environ.get("SEMAPHORE_PIPELINE_ID", ""),
            "name": os.environ.get("SEMAPHORE_PIPELINE_NAME", ""),
            "result": os.environ.get("SEMAPHORE_PIPELINE_RESULT", ""),
            "result_reason": os.environ.get("SEMAPHORE_PIPELINE_RESULT_REASON", ""),
            "url": pipeline_url(),
        },
        "project": {
            "name": os.environ.get("SEMAPHORE_PROJECT_NAME", ""),
        },
        "repository": {
            "slug": os.environ.get("SEMAPHORE_GIT_REPO_SLUG", ""),
            "url": os.environ.get("SEMAPHORE_GIT_URL", ""),
        },
        "revision": {
            "branch": {"name": branch},
            "commit_sha": os.environ.get("SEMAPHORE_GIT_SHA", ""),
            "commit_message": commit_message(),
            "reference": os.environ.get("SEMAPHORE_GIT_REF", ""),
        },
        "workflow": {
            "id": os.environ.get("SEMAPHORE_WORKFLOW_ID", ""),
            "number": os.environ.get("SEMAPHORE_WORKFLOW_NUMBER", ""),
        },
    }


def main():
    if os.environ.get("SEMAPHORE_PIPELINE_RESULT") != "failed":
        print("Pipeline did not fail; skipping Hermes notification")
        return 0

    url = os.environ.get("HERMES_WEBHOOK_URL", "").strip()
    secret = os.environ.get("HERMES_WEBHOOK_SECRET", "").strip()
    if url in ("", "disabled") or not secret:
        print(
            "Hermes webhook is not configured. Set HERMES_WEBHOOK_URL and "
            "HERMES_WEBHOOK_SECRET on the hermes-webhook secret.",
            file=sys.stderr,
        )
        return 1

    body = json.dumps(payload(), separators=(",", ":")).encode()
    signature = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
    request = urllib.request.Request(
        url,
        data=body,
        method="POST",
        headers={
            "Content-Type": "application/json",
            "User-Agent": "Semaphore-Hermes",
            "X-Webhook-Signature": signature,
            "X-Request-ID": os.environ.get("SEMAPHORE_PIPELINE_ID", ""),
        },
    )

    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            status = response.status
            raw = response.read().decode()
    except urllib.error.HTTPError as error:
        status = error.code
        raw = error.read().decode()
    except urllib.error.URLError as error:
        print(f"Hermes webhook request failed: {error.reason}", file=sys.stderr)
        return 1

    print(f"Hermes webhook responded {status}: {raw}")
    return 0 if status in (200, 202) else 1


if __name__ == "__main__":
    sys.exit(main())
