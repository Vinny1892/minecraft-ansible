---
title: "Onboarding — minecraft-ansible"
description: "Guia Zero-to-Hero para subir o ambiente local e fazer o primeiro deploy em menos de 15 minutos"
---

# Onboarding — minecraft-ansible

Guia prático para novos contribuidores. Ao final deste documento você terá:
- Ambiente local configurado
- Servidor Minecraft rodando em Docker
- Entendimento do ciclo de desenvolvimento e teste

---

## Pré-requisitos

| Ferramenta | Versão mínima | Verificação |
|---|---|---|
| Python | 3.10+ | `python --version` |
| Poetry | qualquer | `poetry --version` |
| Docker | qualquer | `docker info` |
| jq | qualquer | `jq --version` |

---

## 1. Configurar o Ambiente

```bash
# Clone e entre no projeto
cd minecraft-ansible

# Instala Ansible, Molecule e ferramentas de dev
poetry install

# Ativa o virtualenv
poetry shell
```

**O que foi instalado** (`pyproject.toml:9-16`):
- `ansible ^7.2.0` — motor de automação
- `molecule[docker] ^4.0.4` — framework de testes para roles
- `black`, `isort` — formatadores Python

---

## 2. Estrutura do Projeto (Anotada)

```
minecraft-ansible/
│
├── ansible.cfg               ← Habilita plugins aws_ec2 e yaml; desativa host_key_checking
├── pyproject.toml            ← Gerenciador de dependências (Poetry)
├── Makefile                  ← Atalhos para todas as operações comuns
│
├── docker/
│   └── Dockerfile            ← Imagem para testes locais (ubuntu + sshd + usuário ansible)
│
├── envs/
│   ├── env_vm.example.yml    ← Template de credenciais para VM
│   └── env_aws.example.yml   ← Template de variáveis AWS SSM
│
├── inventories/
│   ├── docker.yaml           ← Descobre containers Docker locais via socket
│   ├── inventory.aws_ec2.yaml← EC2 filtrado por tag Project=minecraft, conecta via SSM
│   └── inventory_vm.yml      ← VM estático; lê credenciais de envs/env_vm.yml
│
├── playbooks/
│   └── minecraft.yaml        ← Ponto de entrada único: aplica a role minecraft em todos os hosts
│
└── roles/minecraft/
    ├── defaults/main.yml     ← minecraft_version (declarativo, não usado nas tasks)
    ├── vars/main.yml         ← jdk_version, URL do JAR, opções de world map
    ├── tasks/main.yml        ← Lógica completa de instalação (94 linhas)
    ├── handlers/main.yml     ← Handler único: systemctl start minecraft
    ├── templates/
    │   └── minecraft.service.j2  ← Unidade systemd (heap 1GB, User=root)
    └── molecule/             ← Testes automatizados da role
        ├── default/
        │   ├── molecule.yml  ← Configuração: ubuntu:22.04 privileged + cgroup
        │   └── converge.yml  ← Aplica a role no container de teste
        ├── verify.yml        ← Verificação pós-converge (stub — só assert: true)
        └── tests/
            └── test_default.py ← pytest: verifica porta 25565 escutando
```

---

## 3. Primeiro Deploy — Docker Local

Este é o fluxo recomendado para desenvolvimento. Não requer AWS nem VM.

### Passo 1: Subir o container de teste

```bash
make setup
```

O que acontece internamente (`Makefile:11-14`):
```makefile
docker rm -f minecraft            # Remove container anterior se existir
docker build -t minecraft ./docker # Constrói imagem com sshd
docker run -d --name minecraft -p 2222:22 minecraft  # Sobe em background
```

A imagem resultante (`docker/Dockerfile`) tem:
- Usuário `ansible` com senha `ansible`
- sudo sem senha para o grupo `admin`
- SSH habilitado na porta 2222 (mapeada para :22 do container)

### Passo 2: Verificar conectividade

```bash
make check
```

Saída esperada:
```
minecraft | CHANGED | rc=0 >>
Mon Mar 22 12:00:00 UTC 2026
```

Se falhar com `UNREACHABLE`, verifique se o container está rodando: `docker ps`.

### Passo 3: Executar o playbook

```bash
make exec
```

Este comando executa (`Makefile:26`):
```bash
ansible-playbook -i inventories/docker.yaml playbooks/minecraft.yaml
```

O playbook aplica `roles/minecraft` com `become: true` (playbooks/minecraft.yaml:3-6).

### Passo 4: Verificar resultado

```bash
make show_ip        # IP do container (ex: 172.17.0.2)
docker exec minecraft systemctl status minecraft
```

Saída esperada do systemctl:
```
● minecraft.service - Minecraft server
   Loaded: loaded (/etc/systemd/system/minecraft.service; enabled)
   Active: active (running)
```

---

## 4. Ciclo de Desenvolvimento de Tasks

Ao modificar `roles/minecraft/tasks/main.yml`, use o ciclo Molecule para iterar rapidamente sem fazer deploy real.

```bash
# Ciclo completo (cria container → aplica role → verifica → destrói)
make test

# Apenas reaplicar a role sem recriar o container (mais rápido)
cd roles/minecraft && molecule converge

# Inspecionar o container após converge
cd roles/minecraft && molecule login

# Derrubar o container de teste
cd roles/minecraft && molecule destroy
```

**Por que o container Molecule é diferente do Docker de dev?**

O container de teste (`molecule/default/molecule.yml:8-14`) usa `privileged: true` e monta `/sys/fs/cgroup` para permitir que o **systemd funcione dentro do container**. Isso é necessário porque a role usa o módulo `systemd` para parar e iniciar serviços. O container de dev (`docker/Dockerfile`) não precisa disso — é usado apenas para testar conectividade SSH e execução do playbook, não para testar o serviço systemd em isolamento.

---

## 5. Deploy em VM Local

Se você tem uma VM acessível via SSH:

```bash
# Copie e preencha o arquivo de credenciais
cp envs/env_vm.example.yml envs/env_vm.yml
# Edite env_vm.yml com: host, user, path_ssh_private_key, password_user_sudo

# Execute o playbook apontando para o inventário de VM
ansible-playbook -i inventories/inventory_vm.yml playbooks/minecraft.yaml
```

---

## 6. Deploy em AWS EC2

Pré-requisitos:
- Instância EC2 com tag `Project=minecraft`
- SSM Agent instalado e role IAM `AmazonSSMManagedInstanceCore` associada
- AWS CLI configurado com profile adequado

```bash
# Copie e preencha variáveis AWS
cp envs/env_aws.example.yml envs/env_aws.yml

# Configure o profile AWS
export AWS_PROFILE=seu-profile

# Teste descoberta de inventário
ansible-inventory -i inventories/inventory.aws_ec2.yaml --graph

# Execute o playbook
make install_production
```

---

## 7. Importar um World Map Existente

Para restaurar um backup ou importar um novo mapa:

```bash
ansible-playbook -i inventories/docker.yaml playbooks/minecraft.yaml \
  -e copy_local_map_folder=true \
  -e path_map_folder=/caminho/local/para/world/
```

**Como funciona** (`roles/minecraft/tasks/main.yml:65-72`): a task `Copy map to server` só executa quando `copy_local_map_folder == true` **e** o world já existia no servidor (`map_folder_exists.stat.exists`). O mapa é copiado para `/opt/minecraft/world` antes do servidor iniciar.

---

## Glossário

| Termo | Significado no projeto |
|---|---|
| **world map** | Diretório `/opt/minecraft/world` — save do mundo Minecraft |
| **ISO 8601 timestamp** | Formato de data usado nos backups: `2026-03-22T12:00:00Z` |
| **SSM** | AWS Systems Manager Session Manager — acesso a EC2 sem SSH exposto |
| **become** | Escalada de privilégios Ansible (equivalente a `sudo`) |
| **handler** | Task Ansible que só executa quando notificada por outra task |
| **converge** | Fase do Molecule que aplica a role no container de teste |
| **inventory plugin** | Componente Ansible que gera inventário dinamicamente (ex: `aws_ec2`, `docker_containers`) |

---

## Caminhos de Leitura por Perfil

**Novo contribuidor (primeira feature):**
→ `roles/minecraft/tasks/main.yml` → `roles/minecraft/vars/main.yml` → `roles/minecraft/templates/minecraft.service.j2`

**Debugging de deploy:**
→ `inventories/` (qual inventário está sendo usado?) → `ansible.cfg` → `envs/` (credenciais corretas?)

**Entender testes:**
→ `roles/minecraft/molecule/default/molecule.yml` → `roles/minecraft/molecule/default/converge.yml` → `roles/minecraft/molecule/tests/test_default.py`
