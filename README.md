# CICD Docker Push Workflow

This GitHub Action builds and pushes a Docker image to AWS ECR. It automatically creates the ECR repository if it doesn't exist.

## Description

This composite action performs the following steps:

1.  Configures AWS credentials.
2.  Logs in to Amazon ECR.
3.  Checks if the ECR repository exists (based on `orgid-buid-appid`).
4.  Creates the repository if it doesn't exist.
5.  Tags the local Docker image with the ECR URI.
6.  Pushes the image to ECR.

## Inputs

| Input            | Description                          | Required | Default     |
| ---------------- | ------------------------------------ | -------- | ----------- |
| `image_type`     | Image type                           | `false`  | `docker`    |
| `image-name`     | Local image name to push             | `true`   |             |
| `tag`            | Image tag                            | `true`   |             |
| `appid`          | Application ID (used for repo name)  | `true`   |             |
| `orgid`          | Organization ID (used for repo name) | `true`   |             |
| `buid`           | Build ID (used for repo name)        | `true`   |             |
| `role-to-assume` | AWS IAM Role to assume               | `true`   |             |
| `region`         | AWS Region                           | `false`  | `us-east-1` |

## Usage

```yaml
steps:
  - uses: actions/checkout@v3

  # ... build your docker image ...

  - name: Push to ECR
    uses: ./path/to/oc-cicd-docker-push-workflow
    with:
      image-name: my-app-image
      tag: ${{ github.sha }}
      orgid: myorg
      buid: myunit
      appid: myapp
      role-to-assume: arn:aws:iam::123456789012:role/my-role
      region: us-east-1
```

## Repository Naming Convention

The ECR repository name is automatically generated using the following format:
`{orgid}-{buid}-{appid}/{image-name}`
