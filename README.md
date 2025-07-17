# 📦 Registry Docker Compose Stack

[![MIT License](https://img.shields.io/github/license/Vantasin/Registry?style=flat-square)](LICENSE)
[![Docker Registry](https://img.shields.io/badge/Docker%20Registry-Self--Hosted-blue?logo=docker&style=flat-square)](https://registry.example.com)
[![ZFS](https://img.shields.io/badge/ZFS-OpenZFS-blue?style=flat-square)](https://openzfs.org/)

🐳 Docker Registry — A self-hosted Docker image storage service for managing, storing, and distributing container images across your infrastructure. Useful for CI/CD pipelines, local development, and version-controlled container deployments.

---

## 📁 Directory Structure

```bash
tank/
├── docker/
│   ├── compose/
│   │   └── registry/             # Git repo lives here
│   │       ├── docker-compose.yml  # Main Docker Compose config
│   │       ├── .env                # Runtime environment variables and secrets (gitignored!)
│   │       ├── env.example         # Example .env file for reference
│   │       └── README.md           # This file
│   └── data/
│       └── registry/             # Volume mounts and persistent data
```

---

## 🧰 Prerequisites

* Docker Engine
* Docker Compose V2
* Git
* (Optional) ZFS on Linux for dataset management

> ⚠️ **Note:** These instructions assume your ZFS pool is named `tank`. If your pool has a different name (e.g., `rpool`, `zdata`, etc.), replace `tank` in all paths and commands with your actual pool name.

---

## ⚙️ Setup Instructions

1. **Create the stack directory and clone the repository**

   If using ZFS:
   ```bash
   sudo zfs create -p tank/docker/compose/registry
   cd /tank/docker/compose/registry
   sudo git clone https://github.com/Vantasin/Registry.git .
   ```

   If using standard directories:
   ```bash
   mkdir -p ~/docker/compose/registry
   cd ~/docker/compose/registry
   git clone https://github.com/Vantasin/Registry.git .
   ```

2. **Create the runtime data directory** (optional)

   If using ZFS:
   ```bash
   sudo zfs create -p tank/docker/data/registry
   ```

   If using standard directories:
   ```bash
   mkdir -p ~/docker/data/registry
   ```

3. **Configure environment variables**

   Copy and modify the `.env` file:

   ```bash
   sudo cp env.example .env
   sudo nano .env
   sudo chmod 600 .env
   ```

   > **Note:** Be sure to update the `REGISTRY_USERNAME` & `REGISTRY_PASSWORD`, they are your login credentials. If necessary you can also update the `REGISTRY_DATA_VOLUME` & `REGISTRY_PORT`.

   > **Note:** In order to remotely use the Docker Registry we need a trusted certificate from a certificate authority. Be sure to create the **Proxy Host** eg. `registry.example.com` using [Nginx Proxy Manager](https://github.com/Vantasin/Nginx-Proxy-Manager.git) as a reverse proxy for HTTPS certificates via Let's Encrypt.

4. **Setup basic authentication**

   Run the script:

   ```bash
   chmod +x generate_htpasswd.sh
   ./generate_htpasswd.sh
   ```

5. **Start registry**

   ```bash
   docker compose up -d
   ```

---
## Push Images to Registry

To push Docker images to your **Docker Registry**, you need to follow these steps:

---

### 🧭 Overview

* You have a local Docker registry container listening on `localhost:5000`
* It's exposed externally as `https://registry.example.com` via Nginx Proxy Manager (NPM)
* You’ve added Basic Auth using `htpasswd`
* You want to `docker push` images to it

---

### ✅ 1. 📦 Tag Your Image Correctly

You must tag the image using the **registry domain**:

```bash
docker tag my-image:latest registry.example.com/my-image:latest
```

If you're using a custom port like `registry.example.com:8443`, include it in the tag:

```bash
docker tag my-image:latest registry.example.com:8443/my-image:latest
```

---

### ✅ 2. 🔐 Authenticate to Your Registry

Docker supports HTTP Basic Auth via the `docker login` command.

Run:

```bash
docker login registry.example.com
```

You'll be prompted for the username and password from your `.env` / `htpasswd`.

> ✅ This creates an entry in your `~/.docker/config.json` so Docker can authenticate for future pulls and pushes.

---

### ✅ 3. 🚀 Push the Image

Once authenticated and tagged:

```bash
docker push registry.example.com/my-image:latest
```

---

### ✅ 4. ⚙️ Nginx Proxy Manager Configuration

Make sure your NPM proxy host is configured like this:

| Setting                   | Value                                                               |
| ------------------------- | ------------------------------------------------------------------- |
| **Domain Name**           | `registry.example.com`                                              |
| **Forward Hostname/IP**   | `localhost` (or container hostname like `registry`)                 |
| **Forward Port**          | `5000`                                                              |
| **Scheme**                | `http`                                                              |
| **Enable SSL**            | ✅ Yes (via Let's Encrypt)                                           |
| **Block Common Exploits** | ✅ Yes                                                               |
| **Websockets Support**    | ✅ Recommended                                                       |
| **Access List/Auth**      | **Disabled** (because you're using `htpasswd` inside the container) |

> ⚠️ If you add auth in NPM **and** inside the registry container, you may get **double prompts or errors.** Only use `htpasswd` **inside** the container, not NPM’s access list.

---

### ✅ 5. 🔒 DNS + HTTPS Requirements

Ensure:

* `registry.example.com` resolves to your public IP or Tailscale IP
* You have a **valid TLS certificate** via NPM (Let's Encrypt)

---

### 🐳 Example Workflow

```bash
# 1. Tag the image
docker tag alpine:latest registry.example.com/test/alpine:latest

# 2. Login to registry
docker login registry.example.com

# 3. Push the image
docker push registry.example.com/test/alpine:latest
```

---

### 🔍 Troubleshooting

| Problem                                         | Solution                             |
| ----------------------------------------------- | ------------------------------------ |
| `unauthorized: authentication required`         | Run `docker login` again             |
| `x509: certificate signed by unknown authority` | Ensure TLS cert is valid and trusted |
| Push fails with 403/404                         | Check NPM doesn’t also require auth  |
| Can't reach `registry.example.com`              | Check DNS or NPM reverse proxy setup |

---

## 🙏 Acknowledgments

- [ChatGPT](https://openai.com/chatgpt) — for assistance in generating setup scripts and templates.
- [Docker Registry](https://hub.docker.com/_/registry) — the official Docker image distribution server.
- [htpasswd (Apache HTTP Tools)](https://httpd.apache.org/docs/current/programs/htpasswd.html) — for secure Basic Auth credential management.
- [Nginx Proxy Manager](https://nginxproxymanager.com/) — a simple, powerful web UI for managing reverse proxies and SSL certificates.
- [Docker](https://www.docker.com/) — for container orchestration and runtime.
- [OpenZFS](https://openzfs.org/) — for advanced local filesystem features, dataset organization, and snapshotting.

> Special thanks to the maintainers and contributors of these projects for making secure and scalable self-hosted infrastructure possible.