# Docker Strapi v5

Automated Docker images for Strapi v5 with automatic version tracking and multi-platform support.

## Features

- **Automatic Version Tracking**: Daily checks for new Strapi releases
- **Multi-Variant Images**: Debian (default) and Alpine variants
- **Multi-Platform Support**: Ready for linux/amd64, linux/arm64, linux/arm/v7
- **Latest Node.js LTS**: Built on Node.js 22 LTS
- **Automated Builds**: GitHub Actions workflows for CI/CD
- **Docker Hub Integration**: Automatic README sync and image publishing

## Available Images

### Debian (Default)
```bash
docker pull <DOCKER_USERNAME>/strapi:latest
docker pull <DOCKER_USERNAME>/strapi:<version>
```

### Alpine
```bash
docker pull <DOCKER_USERNAME>/strapi:latest-alpine
docker pull <DOCKER_USERNAME>/strapi:<version>-alpine
```

## Quick Start

### Basic Usage

```bash
docker run -d \
  -p 1337:1337 \
  -v $(pwd)/app:/srv/app \
  <DOCKER_USERNAME>/strapi:latest
```

### Docker Compose

```yaml
version: '3'
services:
  strapi:
    image: <DOCKER_USERNAME>/strapi:latest
    container_name: strapi
    restart: unless-stopped
    ports:
      - "1337:1337"
    volumes:
      - ./app:/srv/app
    environment:
      DATABASE_CLIENT: sqlite
      DATABASE_FILENAME: .tmp/data.db
```

### Create New Strapi Project

```bash
docker run -it --rm \
  -v $(pwd)/my-project:/srv/app \
  <DOCKER_USERNAME>/strapi:latest \
  strapi new . --quickstart
```

## GitHub Actions Setup

### Required Secrets

Configure the following secrets in your GitHub repository (Settings → Secrets and variables → Actions):

| Secret Name | Description | Where to Get It |
|-------------|-------------|-----------------|
| `DOCKER_USERNAME` | Docker Hub username | Your Docker Hub account |
| `DOCKER_PASSWORD` | Docker Hub access token (recommended) or password | [Docker Hub → Account Settings → Security](https://hub.docker.com/settings/security) |
| `PAT` | GitHub Personal Access Token with `workflow` scope | [GitHub → Settings → Developer settings → Personal access tokens](https://github.com/settings/tokens) |

**Note**: `GITHUB_TOKEN` is automatically provided by GitHub Actions and requires no configuration.

### Setting Up Docker Hub Access Token (Recommended)

1. Go to [Docker Hub Account Settings](https://hub.docker.com/settings/security)
2. Click "New Access Token"
3. Give it a description (e.g., "GitHub Actions")
4. Set permissions: Read, Write, Delete
5. Copy the token and add it as `DOCKER_PASSWORD` secret in GitHub

### Setting Up GitHub PAT

1. Go to [GitHub Personal Access Tokens](https://github.com/settings/tokens)
2. Click "Generate new token" → "Generate new token (classic)"
3. Give it a descriptive name (e.g., "Strapi Docker Workflows")
4. Select scopes: `workflow`
5. Click "Generate token"
6. Copy the token and add it as `PAT` secret in GitHub

## Workflows

### 1. Auto Check New Releases
**File**: `.github/workflows/auto-check-new-releases.yml`

Automatically checks for new Strapi releases daily and triggers the build process.

- **Schedule**: Runs daily at midnight (UTC)
- **Manual Trigger**: Can be triggered manually via GitHub Actions UI
- **Action**: Fetches latest Strapi version from npm and commits to `release-versions/strapi-latest.txt`

### 2. Publish Docker Images
**File**: `.github/workflows/publish-docker-images.yml`

Builds and publishes Docker images when a new version is detected.

- **Trigger**: On changes to `release-versions/*` files
- **Builds**:
  - Debian variant (default)
  - Alpine variant
- **Tags**:
  - `latest` / `latest-alpine`
  - `<version>` / `<version>-alpine`
- **Platforms**: Configurable multi-platform support
- **Extras**:
  - Syncs README to Docker Hub
  - Creates GitHub release

### 3. Manual Release
**File**: `.github/workflows/manual-release.yml`

Manually trigger a build for a specific Strapi version.

- **Trigger**: Manual workflow dispatch
- **Input**: Strapi version number (e.g., `5.0.0`)
- **Usage**: Go to Actions → Create new release manually → Run workflow

## Directory Structure

```
.
├── .github/
│   └── workflows/
│       ├── auto-check-new-releases.yml
│       ├── manual-release.yml
│       └── publish-docker-images.yml
├── images/
│   ├── strapi-alpine/
│   │   ├── Dockerfile
│   │   ├── docker-entrypoint.sh
│   │   └── README.md
│   └── strapi-debian/
│       ├── Dockerfile
│       ├── docker-entrypoint.sh
│       └── README.md
├── release-versions/
│   └── strapi-latest.txt
└── README.md
```

## Building Locally

### Debian Image
```bash
cd images/strapi-debian
docker build \
  --build-arg STRAPI_VERSION=5.0.0 \
  --build-arg NODE_VERSION=22 \
  -t strapi:5.0.0 .
```

### Alpine Image
```bash
cd images/strapi-alpine
docker build \
  --build-arg STRAPI_VERSION=5.0.0 \
  --build-arg NODE_VERSION=22 \
  -t strapi:5.0.0-alpine .
```

## Environment Variables

The Strapi container supports all standard Strapi environment variables:

```bash
DATABASE_CLIENT=postgres
DATABASE_HOST=db
DATABASE_PORT=5432
DATABASE_NAME=strapi
DATABASE_USERNAME=strapi
DATABASE_PASSWORD=strapi
JWT_SECRET=your-secret-key
ADMIN_JWT_SECRET=your-admin-secret
APP_KEYS=key1,key2,key3,key4
API_TOKEN_SALT=your-salt
```

## Advanced Usage

### With PostgreSQL

```yaml
version: '3'
services:
  strapi:
    image: <DOCKER_USERNAME>/strapi:latest
    container_name: strapi
    restart: unless-stopped
    ports:
      - "1337:1337"
    volumes:
      - ./app:/srv/app
    environment:
      DATABASE_CLIENT: postgres
      DATABASE_HOST: db
      DATABASE_PORT: 5432
      DATABASE_NAME: strapi
      DATABASE_USERNAME: strapi
      DATABASE_PASSWORD: strapi
      DATABASE_SSL: false
    depends_on:
      - db

  db:
    image: postgres:16-alpine
    container_name: strapi-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: strapi
      POSTGRES_USER: strapi
      POSTGRES_PASSWORD: strapi
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```

### Multi-Platform Build

To enable multi-platform builds, uncomment the `platforms` line in `.github/workflows/publish-docker-images.yml`:

```yaml
platforms: linux/amd64,linux/arm64,linux/arm/v7
```

## Version Information

- **Node.js**: 22 LTS (Active until April 2027)
- **Strapi**: Automatically tracks latest v5 releases
- **Base Images**:
  - `node:22` (Debian)
  - `node:22-alpine` (Alpine)

## Maintenance

### Updating to New Node.js Version

1. Edit `images/strapi-debian/Dockerfile` and `images/strapi-alpine/Dockerfile`
2. Update `ARG NODE_VERSION=22` to the desired version
3. Update `.github/workflows/publish-docker-images.yml`
4. Update `NODE_VERSION=22` in the build-args sections

### Manual Version Override

To manually set a specific Strapi version:

1. Go to GitHub Actions
2. Select "Create new release manually"
3. Click "Run workflow"
4. Enter the desired Strapi version (e.g., `5.0.0`)
5. Click "Run workflow"

## Troubleshooting

### Container Starts But Exits Immediately

Check logs:
```bash
docker logs <container-name>
```

Ensure the volume directory has correct permissions:
```bash
chmod -R 777 ./app
```

### Database Connection Issues

Verify environment variables and ensure the database service is running:
```bash
docker-compose ps
docker-compose logs db
```

### Permission Denied Errors

The container runs as user `1000:1000`. Ensure your volume directory is writable:
```bash
sudo chown -R 1000:1000 ./app
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Update documentation if needed
5. Submit a pull request

## License

See [LICENSE](LICENSE) file for details.

## Links

- [Strapi Official Documentation](https://docs.strapi.io/)
- [Docker Hub Repository](https://hub.docker.com/r/<DOCKER_USERNAME>/strapi)
- [GitHub Repository](https://github.com/<YOUR_USERNAME>/docker-strapi-v5)
- [Strapi GitHub](https://github.com/strapi/strapi)

## Support

For issues related to:
- **This Docker setup**: Open an issue in this repository
- **Strapi itself**: Visit [Strapi Community](https://discord.strapi.io/)
- **Docker**: Visit [Docker Documentation](https://docs.docker.com/)

---

**Note**: Replace `<DOCKER_USERNAME>` and `<YOUR_USERNAME>` with your actual Docker Hub and GitHub usernames.
