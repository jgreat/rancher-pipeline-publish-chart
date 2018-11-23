#!/bin/bash

set -e

if [ -z "${CHART_VERSION}" ]; then
    # Get the first semver tag
    IFS=',' read -ra TAGS <<< $(cat .tags)
    for t in "${TAGS[@]}"; do
        echo "Found tag: ${t}"
        if [[ $t =~ [v]*[0-9]+\.[0-9]+\.[0-9]+.* ]]; then
            CHART_VERSION=$t
            break
        fi
    done
fi
echo "CHART_VERSION: $CHART_VERSION"

# If master then its a "release", else its a feature branch.
# Releases are named with the git repo name
if [ -z "${CHART_NAME}" ]; then
    if [ "${CICD_GIT_BRANCH}" == "master" ]; then
        echo "Found master branch."
        CHART_NAME="${CICD_GIT_REPO_NAME}"
    else
        echo "Found feature branch."
        CHART_NAME="${CICD_GIT_BRANCH}"
    fi
fi
echo "CHART_NAME: ${CHART_NAME}"

mkdir -p .build/charts
cp -R .chart .build/${CHART_NAME}

# sed replace version and name
sed -i -e "s/%VERSION%/${CHART_VERSION}/g" .build/${CHART_NAME}/Chart.yaml
sed -i -e "s/%CHART_NAME%/${CHART_NAME}/g" .build/${CHART_NAME}/Chart.yaml

export HELM_HOME=/root/.helm

# Lint Chart
helm lint .build/${CHART_NAME}

# Package Chart
helm package -d .build/charts .build/${CHART_NAME}

# Add Remote Repo
helm repo add --username "${HELM_REPO_USERNAME}" --password "${HELM_REPO_PASSWORD}" \
${HELM_REPO_NAME} ${HELM_REPO_URL}

# Publish Chart 
helm push .build/charts/${CHART_NAME}-${CHART_VERSION}.tgz ${HELM_REPO_NAME}
