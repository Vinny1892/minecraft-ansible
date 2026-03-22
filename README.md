# minecraft-ansible

Automação Ansible para deploy e gerenciamento de servidor **Minecraft Java Edition** em múltiplos ambientes: Docker local, VM e AWS EC2.

---

## Requisitos

| Ferramenta | Versão |
|---|---|
| Python | 3.10+ |
| Poetry | qualquer |
| Docker | qualquer (testes locais) |
| Ansible | ^7.2.0 (instalado via Poetry) |

Para deploy em **AWS EC2**: instância com SSM Agent + role IAM `AmazonSSMManagedInstanceCore`. Não é necessário expor a porta 22.

---

## Setup

```bash
poetry install   # instala Ansible, Molecule e dependências
poetry shell     # ativa o virtualenv
```

---

## Deploy

### Docker (desenvolvimento local)

```bash
make setup   # constrói imagem e sobe container
make check   # verifica conectividade
make exec    # executa o playbook
```

### VM local

```bash
cp envs/env_vm.example.yml envs/env_vm.yml
# preencha: host, user, path_ssh_private_key, password_user_sudo

ansible-playbook -i inventories/inventory_vm.yml playbooks/minecraft.yaml
```

### AWS EC2

```bash
cp envs/env_aws.example.yml envs/env_aws.yml
# preencha: ansible_aws_ssm_bucket_name, ansible_aws_ssm_region

export AWS_PROFILE=seu-profile
make install_production
```

---

## Variáveis da Role

Definidas em `roles/minecraft/vars/main.yml`:

| Variável | Padrão | Descrição |
|---|---|---|
| `jdk_version` | `"21"` | Versão do OpenJDK a instalar |
| `minecraft_server_url_for_download` | URL Mojang 1.19.3+ | URL do JAR oficial do servidor |
| `path_map_folder` | `""` | Caminho local de um world map a importar |
| `copy_local_map_folder` | `false` | Habilita importação do world map |

Para importar um world map existente:

```bash
ansible-playbook -i inventories/docker.yaml playbooks/minecraft.yaml \
  -e copy_local_map_folder=true \
  -e path_map_folder=/caminho/para/world/
```

> O world map existente em `/opt/minecraft/world` é automaticamente copiado para `/opt/minecraft_maps/world-{timestamp}` antes de cada deploy.

---

## Testes

```bash
make test
# equivalente a: cd roles/minecraft && molecule test
```

O pipeline Molecule cria um container Ubuntu 22.04 com systemd, aplica a role e verifica que a porta `25565` está escutando.

---

## Documentação

- [`docs/onboarding.md`](docs/onboarding.md) — guia passo a passo para novos contribuidores
- [`docs/arquitetura.md`](docs/arquitetura.md) — deep-dive arquitetural com diagramas e análise de decisões de design

---

## Licença

MIT — DiegoBulhoes
