#!/bin/bash
set -e

REPO_NAME="${ORGID}-${BUID}-${APPID}"
echo "Repository Name: $REPO_NAME"

# Check if repository exists
if ! aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$REGION" > /dev/null 2>&1; then
  echo "Repository $REPO_NAME does not exist. Creating..."
  aws ecr create-repository --repository-name "$REPO_NAME" --region "$REGION"
else
  echo "Repository $REPO_NAME already exists."
fi

ECR_IMAGE="$REGISTRY/$REPO_NAME:$TAG"

echo "Tagging image as $ECR_IMAGE"
docker tag "$IMAGE_NAME:$TAG" "$ECR_IMAGE"

echo "Pushing image to ECR"
docker push "$ECR_IMAGE"
