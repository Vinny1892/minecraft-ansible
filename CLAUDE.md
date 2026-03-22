# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ansible project for deploying and managing a Minecraft Java server across multiple infrastructure targets (Docker, AWS EC2, local VMs). Uses Poetry for Python/Ansible dependency management and Molecule for role testing.

## Common Commands

### Setup & Dependencies
```bash
poetry install          # Install all dependencies (Ansible, Molecule, etc.)
poetry shell            # Activate virtual environment
```

### Local Testing with Docker
```bash
make setup              # Build and start Docker test container
make check              # Test Ansible connectivity (ping all nodes)
make graph              # Show inventory host graph
make exec               # Run playbook against Docker container
make down               # Stop Docker container
make sh                 # Interactive shell into container
```

### Molecule Tests (role-level)
```bash
make test               # Run full molecule test suite
# Or directly:
cd roles/minecraft && molecule test          # Full test lifecycle
cd roles/minecraft && molecule converge     # Apply role only
cd roles/minecraft && molecule verify       # Run verification
cd roles/minecraft && molecule destroy      # Tear down test container
```

### Production Deploy
```bash
make install_production  # Deploy to AWS EC2 (uses inventory.aws_ec2.yaml)
```

### YAML Linting
```bash
ansible-lint            # Lint playbooks and roles
yamllint .              # Lint YAML syntax (uses roles/minecraft/.yamllint config)
```

## Architecture

### Inventory Targets
- **docker.yaml** — Local Docker container (community.docker.docker_containers plugin, grouped by container name)
- **inventory.aws_ec2.yaml** — AWS EC2 dynamic inventory (filtered by `Project=minecraft` tag, connects via AWS SSM — no SSH needed)
- **inventory_vm.yml** — Static VM inventory using vars from `envs/env_vm.yml`

### Environment Variables
Environment-specific credentials live in `envs/` (excluded from git):
- `envs/env_vm.yml` — VM host, SSH key path, sudo password
- `envs/env_aws.yml` — SSM bucket name and region

Copy from `*.example.yml` files to create these.

### Role: `roles/minecraft`
Single role that handles the full server lifecycle:
1. Installs OpenJDK (default: version 21)
2. Backs up existing world map to `/opt/minecraft-backup/` with timestamp
3. Tears down existing installation
4. Deploys server JAR from `minecraft_server_url_for_download`
5. Writes EULA acceptance
6. Installs systemd service (1GB heap, restarts on failure)

**Key variables** (`roles/minecraft/vars/main.yml`):
- `jdk_version`: JDK version to install (default: `"21"`)
- `minecraft_server_url_for_download`: Download URL for the server JAR
- `path_map_folder`: Local path to a world map to copy in (optional)
- `copy_local_map_folder`: Set `true` to enable world map copy

**Defaults** (`roles/minecraft/defaults/main.yml`):
- `minecraft_version`: `"1.19.3"`

### Molecule Testing
Molecule uses a privileged Ubuntu 22.04 Docker container with systemd enabled. Test files:
- `roles/minecraft/molecule/default/converge.yml` — Applies the role
- `roles/minecraft/molecule/verify.yml` — Verification plays
- `roles/minecraft/molecule/tests/test_default.py` — pytest asserting port 25565 is listening

### ansible.cfg
Enables `aws_ec2` and `yaml` inventory plugins. Disables host key checking. Default inventory points to `inventory.aws_ec2.yml` (override with `-i` flag for other targets).
