#!/bin/bash
set -e

# Construct the repository name with the image name as a suffix
# This creates a structure like: orgid-buid-appid/image-name
REPO_NAME="${ORGID}-${BUID}-${APPID}/${IMAGE_NAME}"
echo "Repository Name: $REPO_NAME"
echo "Image Type: '$IMAGE_TYPE'"

# Check if repository exists
if ! aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$REGION" > /dev/null 2>&1; then
  echo "Repository $REPO_NAME does not exist. Creating..."
  aws ecr create-repository --repository-name "$REPO_NAME" --region "$REGION"
else
  echo "Repository $REPO_NAME already exists."
fi

if [ "$IMAGE_TYPE" == "helm" ]; then
    echo "Processing Helm Chart push..."

    # Login to ECR for Helm
    aws ecr get-login-password --region "$REGION" | helm registry login --username AWS --password-stdin "$REGISTRY"

    # Chart Package Name (Standard: name-version.tgz)
    # Assuming IMAGE_NAME is the chart name
    CHART_FILE="${IMAGE_NAME}-${TAG}.tgz"

    if [ ! -f "$CHART_FILE" ]; then
        echo "Error: Chart package $CHART_FILE not found in current directory."
        exit 1
    fi

    # Push to ECR
    # We push to the "Namespace" (Org-Build-App). Helm appends the chart name.
    # So if we want: registry/org-buid-app/image-name
    # We push to: oci://registry/org-buid-app
    TARGET_OCI="oci://$REGISTRY/${ORGID}-${BUID}-${APPID}"

    echo "Pushing $CHART_FILE to $TARGET_OCI"
    helm push "$CHART_FILE" "$TARGET_OCI"

else
    # Docker Push Logic
    ECR_IMAGE="$REGISTRY/$REPO_NAME:$TAG"

    echo "Tagging image as $ECR_IMAGE"
    docker tag "$IMAGE_NAME:$TAG" "$ECR_IMAGE"

    echo "Pushing image to ECR"
    docker push "$ECR_IMAGE"
fi
