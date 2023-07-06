#!/bin/bash
set -e

USAGE="$(basename "$0") [-h] --tag YYYY.MM.REVISION [--ecr-region REGION, defaults to 'us-east-1'] [--ecr-endpoint PUBLIC_ECR ENDPOINT, defaults to 'public.ecr.aws/f9w8i0a8']"

print_usage() {
  echo "$USAGE" 1>&2
}

# ansamual@ - 2023-07-06 - modify these settings to point to your own public ECR repo
ECR_REPO="pcluster-ui-rmit"
ECR_REGION="us-east-1"

# Private endpoint - uncomment if pushing to private
#ECR_ENDPOINT="775780210965.dkr.ecr.us-east-2.amazonaws.com"

# Public endpoint example - uncomment if pushing to public
ECR_ENDPOINT="public.ecr.aws/f9w8i0a8"

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h)
    print_usage
    exit 1
    ;;
    --tag)
    TAG=$2
    shift
    shift
    ;;
    --ecr-endpoint)
    ECR_ENDPOINT=$2
    shift
    shift
    ;;
    --ecr-region)
    ECR_REGION=$2
    shift
    shift
    ;;
    *)
    print_usage
    exit 1
    ;;
esac
done


if [ -z $TAG ]; then
  echo 'No `--tag` parameter specified, exiting' 1>&2
  exit 1
elif ! [[ $TAG =~ [0-9]{4}\.(0[1-9]|1[0-2])\.[0-9]+ ]]; then
  echo '`--tag` parameter must be a valid year, month and revision number combo of the following format `YYYY.MM.REVISION`, exiting' 1>&2
  exit 1
fi

# Use for private repos - use with private ECR_ENDPOINT above
#aws ecr get-login-password --region "$ECR_REGION" | docker login --username AWS --password-stdin "${ECR_ENDPOINT}"

# Use for public repos - use with public ECR_ENDPOINT above
aws ecr-public get-login-password --region "$ECR_REGION" | docker login --username AWS --password-stdin "${ECR_ENDPOINT}"


pushd frontend
# if [ ! -d node_modules ]; then
#   npm install
# fi
docker build --build-arg PUBLIC_URL=/ -t frontend-awslambda .
popd
docker build -f Dockerfile.awslambda -t ${ECR_REPO} .

ECR_IMAGE_VERSION_TAGGED=${ECR_ENDPOINT}/${ECR_REPO}:${TAG}
ECR_IMAGE_LATEST_TAGGED=${ECR_ENDPOINT}/${ECR_REPO}:latest

docker tag ${ECR_REPO} ${ECR_IMAGE_VERSION_TAGGED}
docker push ${ECR_IMAGE_VERSION_TAGGED}

docker tag ${ECR_REPO} ${ECR_IMAGE_LATEST_TAGGED}
docker push ${ECR_IMAGE_LATEST_TAGGED}

echo "Uploaded: ${ECR_IMAGE_VERSION_TAGGED}, ${ECR_IMAGE_LATEST_TAGGED}"