# rancher-pipeline-publish-chart
Publish helm chart with rancher pipeline.

This script renders a Helm chart from the `.chart` directory in the root for the repo and uses the [helm push plugin](https://github.com/chartmuseum/helm-push) to publish the chart to a [Chartmuseum](https://github.com/helm/chartmuseum) instance.

## Template Replacement

This script will do a simple `sed` replace of `%VERSION%` with `$CHART_VERSION`) and `%CHART_NAME%` with `$CHART_NAME` in the Chart.yaml when rendering the Helm chart.

### Example .chart/Chart.yaml

```yaml
apiVersion: v1
appVersion: %VERSION%
description: Microservices vote demo.
name: %CHART_NAME%
version: %VERSION%
icon: https://rancher.com/img/brand-guidelines/assets/logos/svg/cow/rancher-logo-cow-blue.svg
```

## Environment Vars

### Required

| VAR | Description |
| --- | --- |
| `HELM_REPO_URL` | Url for Helm Repo (base path for index.yaml). |
| `HELM_REPO_USERNAME` | Username for publishing charts. Use k8s secret and `envFrom` syntax with Rancher Pipelines. |
| `HELM_REPO_PASSWORD` | Password for publishing charts. Use k8s secret and `envFrom` syntax with Rancher Pipelines. |

### Option overrides

| VAR | Default | Description |
| --- | --- | --- |
| `CHART_NAME` | Value of `CICD_GIT_BRANCH` | Will use the `git` branch name or override with variable. |
| `CHART_VERSION` | Use first SemVer value from `.tags` file. | Use `.tags` file or set manually with the Env Var. |

## .tags file

This will read a comma separated list of tags in a `.tags` file located in the root of the repo. It will use the first SemVer-like value (`[v]*[0-9]+\.[0-9]+\.[0-9]+.*`) it finds.

This `.tags` file can be dynamically generated in a previous build step with a tool like: [drone-build-tag](https://github.com/jgreat/drone-build-tag)

## Example `.rancher-pipeline.yml`

`rancher-pipeline-publish-chart` is used in the "Render and Publish Helm Charts" stage.

```yaml
stages:
- name: Create Build Tag
  steps:
  - runScriptConfig:
      image: jgreat/drone-build-tag:0.1.0
      shellScript: build-tags.sh --include-feature-tag
- name: Build and Publish Image
  steps:
  - publishImageConfig:
      dockerfilePath: ./Dockerfile
      buildContext: .
      tag: jgreat/vote-demo-web:use-tags-file
      pushRemote: true
      registry: index.docker.io
- name: Render and Publish Helm Charts
  steps:
  - runScriptConfig:
      image: jgreat/rancher-pipeline-publish-chart:0.0.2
      shellScript: publish-chart.sh
    env:
      HELM_REPO_URL: https://vote-demo-charts.eng.rancher.space/vote-demo-web/
    envFrom:
    - sourceName: chart-creds
      sourceKey: BASIC_AUTH_PASS
      targetKey: HELM_REPO_PASSWORD
    - sourceName: chart-creds
      sourceKey: BASIC_AUTH_USER
      targetKey: HELM_REPO_USERNAME
- name: Upgrade Catalog Apps
  steps:
  - runScriptConfig:
      image: jgreat/rancher-pipeline-deploy:0.0.2
      shellScript: rancher-pipeline-deploy
    env:
      RANCHER_URL: https://jgreat-vote-rancher.eng.rancher.space
      RANCHER_CATALOG_NAME: vote-demo-web
    envFrom:
    - sourceName: chart-creds
      sourceKey: RANCHER_API_TOKEN
      targetKey: RANCHER_API_TOKEN
timeout: 10
```