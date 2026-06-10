---
name: reference-deploy
description: How to deploy to staging and where the logs land.
metadata:
  type: reference
---

Ship to staging with `make deploy-staging` from the repo root. It builds, pushes the image, and rolls the staging cluster.

Logs land in the `app-staging` log group; tail them with `make logs-staging`. A deploy is healthy when the rollout prints `ready: 3/3` and the health check returns 200 within two minutes.
