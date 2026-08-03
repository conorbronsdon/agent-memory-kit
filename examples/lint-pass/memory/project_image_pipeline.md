---
name: project-image-pipeline
description: The legacy image resize pipeline runs on origin; the CDN takes it over at the cutover.
metadata:
  type: project
---

Static image resizing runs in the legacy pipeline on the origin servers. The new
CDN resizes at the edge, so the pipeline is decommissioned at the cutover.

**How to apply:** while the pipeline is still live, any new image size needs a
preset added to it as well as the CDN, or the origin serves the wrong dimensions.
