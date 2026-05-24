---
name: devops-pipelines
description: "CI/CD pipeline templates and best practices for GitHub Actions and Azure DevOps. Use when creating pipelines, configuring build automation, setting up deployment workflows, adding quality gates, or troubleshooting pipeline failures. Also trigger when the user mentions GitHub Actions, Azure DevOps, YAML pipelines, deployment stages, or build automation."
---

# DevOps Pipelines

Templates and references for CI/CD pipelines on GitHub Actions and Azure DevOps.

## When to Use

- Creating a new CI/CD pipeline
- Adding stages (build, test, deploy) to existing pipelines
- Configuring caching, artifacts, or matrix builds
- Setting up deployment approvals and environments
- Troubleshooting pipeline failures

## GitHub Actions

### .NET Build + Test

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '8.0.x'

      - name: Restore
        run: dotnet restore

      - name: Build
        run: dotnet build --no-restore --configuration Release

      - name: Test
        run: dotnet test --no-build --configuration Release --verbosity normal
```

### Node.js Build + Test

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - run: npm ci
      - run: npm run build
      - run: npm test
```

### Caching

```yaml
- name: Cache NuGet
  uses: actions/cache@v4
  with:
    path: ~/.nuget/packages
    key: ${{ runner.os }}-nuget-${{ hashFiles('**/*.csproj') }}
    restore-keys: ${{ runner.os }}-nuget-
```

### Deployment with Environments

```yaml
deploy-staging:
  needs: build
  runs-on: ubuntu-latest
  environment: staging
  steps:
    - name: Deploy to staging
      run: echo "Deploying to staging"

deploy-production:
  needs: deploy-staging
  runs-on: ubuntu-latest
  environment:
    name: production
    url: https://app.example.com
  steps:
    - name: Deploy to production
      run: echo "Deploying to production"
```

## Azure DevOps

### Multi-Stage Pipeline

```yaml
trigger:
  branches:
    include:
      - main

pool:
  vmImage: 'ubuntu-latest'

stages:
  - stage: Build
    jobs:
      - job: BuildJob
        steps:
          - task: DotNetCoreCLI@2
            displayName: 'Restore'
            inputs:
              command: restore

          - task: DotNetCoreCLI@2
            displayName: 'Build'
            inputs:
              command: build
              arguments: '--configuration Release --no-restore'

          - task: DotNetCoreCLI@2
            displayName: 'Test'
            inputs:
              command: test
              arguments: '--configuration Release --no-build'

  - stage: DeployStaging
    dependsOn: Build
    condition: succeeded()
    jobs:
      - deployment: DeployToStaging
        environment: staging
        strategy:
          runOnce:
            deploy:
              steps:
                - script: echo "Deploy to staging"

  - stage: DeployProduction
    dependsOn: DeployStaging
    condition: succeeded()
    jobs:
      - deployment: DeployToProduction
        environment: production
        strategy:
          runOnce:
            deploy:
              steps:
                - script: echo "Deploy to production"
```

## Dockerfile Templates

### .NET API

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY *.csproj .
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app .
USER $APP_UID
EXPOSE 8080
HEALTHCHECK CMD curl -f http://localhost:8080/health || exit 1
ENTRYPOINT ["dotnet", "MyApp.dll"]
```

### Node.js App

```dockerfile
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine AS runtime
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/package*.json ./
RUN npm ci --omit=dev
USER node
EXPOSE 3000
HEALTHCHECK CMD wget -q --spider http://localhost:3000/health || exit 1
CMD ["node", "dist/index.js"]
```

## Best Practices

- **Pin versions**: Use exact versions for actions/tasks, not `latest` or `@main`
- **Cache dependencies**: Restoring from cache is 10-50x faster than downloading
- **Fail fast**: Put linting and unit tests before slow integration tests
- **Secrets management**: Use pipeline variables or vault integrations, never hardcode
- **Artifacts**: Upload build artifacts between stages, don't rebuild
- **Branch protection**: Require CI pass before merge
- **Deployment approvals**: Require manual approval for production deployments
