Param(
    [Parameter(Mandatory=$true)]
    [string]$Username,

    [Parameter(Mandatory=$true)]
    [string]$RepoName,

    [Parameter(Mandatory=$true)]
    [string]$Version,

    [Parameter(Mandatory=$false)]
    [switch]$NoPush
)

# Check if Docker is available
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker is not installed or not available in PATH."
    exit 1
}

# Validate username (alphanumeric, hyphens, underscores)
if ($Username -notmatch '^[\w\-]+$') {
    Write-Error "Invalid username: '$Username'. Allowed characters: letters, numbers, hyphens, underscores."
    exit 1
}

# Validate repository name (alphanumeric, hyphens, underscores)
if ($RepoName -notmatch '^[\w\-]+$') {
    Write-Error "Invalid repository name: '$RepoName'. Allowed characters: letters, numbers, hyphens, underscores."
    exit 1
}

# Validate version string (semantic versioning style)
if ($Version -notmatch '^[0-9]+(\.[0-9]+)*(?:-[\w\.]+)?$') {
    Write-Error "Invalid version format: '$Version'."
    exit 1
}

# Build the Docker image with both tags
docker build --pull --rm `
    -t "${Username}/${RepoName}:latest" `
    -t "${Username}/${RepoName}:${Version}" `
    .

if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker build failed."
    exit $LASTEXITCODE
}

if (-not $NoPush) {
    # Push the version tag, then the latest tag
    docker image push "${Username}/${RepoName}:${Version}"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to push tag $Version."
        exit $LASTEXITCODE
    }

    docker image push "${Username}/${RepoName}:latest"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to push tag latest."
        exit $LASTEXITCODE
    }

    Write-Host "Successfully built and pushed ${Username}/${RepoName}:${Version} and latest."
} else {
    Write-Host "Successfully built ${Username}/${RepoName}:${Version} and latest. Push skipped due to -NoPush."
}
