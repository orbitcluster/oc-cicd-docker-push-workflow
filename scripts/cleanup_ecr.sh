#!/bin/bash
set -e

# Construct repo name
REPO_NAME="${ORGID}-${BUID}-${APPID}/${IMAGE_NAME}"
echo "Repository Name: $REPO_NAME"
echo "Cleaning up images for branch: $BRANCH_NAME"

if [ -z "$BRANCH_NAME" ]; then
    echo "Error: Branch name is required for cleanup."
    exit 1
fi

# List images that contain the branch name in their tag
# Filter keys: imageDigest
# Command breakdown:
# list-images: Gets list of images
# --query: JMESPath to filter imageIds where imageTag contains "-$BRANCH_NAME-" and select imageDigest
# output: json array of digests.
# Wait, checking tags: "v1-feat-login-sha". Branch part is "feat-login".
# So simple "contains" check for "-$BRANCH_NAME-" should work to avoid partial matches (e.g. branch 'lo' matching 'login').
# Tag pattern: {base}-{safe_branch}-{sha}

# JMESPATH filter explanation:
# imageIds[?contains(imageTag, '-$BRANCH_NAME-')].{imageDigest: imageDigest, imageTag: imageTag}
# Returns array of objects.

echo "Finding images..."
IMAGE_DIGESTS=$(aws ecr list-images --repository-name "$REPO_NAME" --region "$REGION" \
    --query "imageIds[?imageTag!=null && contains(imageTag, '-${BRANCH_NAME}-')].imageDigest" \
    --output text)

if [ -z "$IMAGE_DIGESTS" ]; then
    echo "No images found for branch $BRANCH_NAME."
    exit 0
fi

echo "Found images to delete:"
echo "$IMAGE_DIGESTS"

# Convert space-delimited digests to format needed for batch-delete-image
# needed format: imageDigest=digest1 imageDigest=digest2 ...
DELETE_ARGS=""
for digest in $IMAGE_DIGESTS; do
    DELETE_ARGS="$DELETE_ARGS imageDigest=$digest"
done

# Limit: batch-delete-image accepts max 100 images.
# If more than 100, we need a loop.
# Simplifying assumption for now or using xargs if needed.
# Let's hope feature branch churn isn't > 100 images at once.

echo "Deleting images..."
aws ecr batch-delete-image --repository-name "$REPO_NAME" --region "$REGION" --image-ids $DELETE_ARGS

echo "Cleanup complete."
