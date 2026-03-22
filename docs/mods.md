---
title: "Gerenciamento de Mods"
description: "Como instalar mods no servidor Forge via Modrinth ou pasta local"
---

# Gerenciamento de Mods

O servidor usa **Forge** e suporta dois métodos de instalação de mods: download automático via **API do Modrinth** ou cópia de uma **pasta local**. Os dois métodos podem ser usados juntos.

---

## Método 1 — Modrinth (recomendado)

Define uma lista de slugs do Modrinth na variável `modrinth_mods`. O Ansible consulta a API automaticamente e baixa a versão mais recente de cada mod compatível com a versão do Minecraft e do Forge configurados.

### Como encontrar o slug de um mod

O slug é o identificador do mod na URL do Modrinth:

```
https://modrinth.com/mod/jei        → slug: jei
https://modrinth.com/mod/create     → slug: create
https://modrinth.com/mod/waystones  → slug: waystones
```

### Exemplos de uso

**Via linha de comando:**
```bash
ansible-playbook -i inventories/docker.yaml playbooks/minecraft.yaml \
  -e '{"modrinth_mods": ["jei", "create", "waystones"]}'
```

**Via variável no inventário ou group_vars:**
```yaml
# inventories/group_vars/all.yml
modrinth_mods:
  - jei
  - create
  - waystones
  - sophisticated-backpacks
  - farmers-delight
```

**Padrão** (sem mods): `modrinth_mods: []` — as tasks são puladas.

### Como funciona internamente

Para cada slug, o Ansible chama:
```
GET https://api.modrinth.com/v2/project/{slug}/version
    ?loaders=["forge"]
    &game_versions=["{minecraft_version}"]
```

A API retorna versões ordenadas por data (mais recente primeiro). O Ansible seleciona o arquivo com `primary: true` e baixa o JAR para `/opt/minecraft/mods/`.

> Não é necessário API key — a API do Modrinth é pública para leitura.

### Compatibilidade

O filtro de versão usa as variáveis `minecraft_version` e o loader `forge` definidos em `roles/minecraft/defaults/main.yml`. Se um mod não tiver versão compatível, a task falha com erro da API.

Para verificar compatibilidade antes do deploy:
```bash
curl "https://api.modrinth.com/v2/project/create/version?loaders=[\"forge\"]&game_versions=[\"1.21.1\"]" | jq '.[0].name'
```

---

## Método 2 — Pasta local

Útil para mods que não estão no Modrinth, mods pagos ou modpacks pré-configurados.

```bash
ansible-playbook -i inventories/docker.yaml playbooks/minecraft.yaml \
  -e copy_local_mods=true \
  -e path_mods_folder=/caminho/local/para/mods/
```

O conteúdo do diretório informado é copiado para `/opt/minecraft/mods/` no servidor.

---

## Usando os dois métodos juntos

```bash
ansible-playbook -i inventories/docker.yaml playbooks/minecraft.yaml \
  -e '{"modrinth_mods": ["jei", "create"]}' \
  -e copy_local_mods=true \
  -e path_mods_folder=/mods/extras/
```

Os mods locais são copiados primeiro, depois os do Modrinth são baixados — ambos vão para `/opt/minecraft/mods/`.

---

## Referência de variáveis

| Variável | Padrão | Descrição |
|---|---|---|
| `modrinth_mods` | `[]` | Lista de slugs do Modrinth para download automático |
| `copy_local_mods` | `false` | Habilita cópia de mods de pasta local |
| `path_mods_folder` | `""` | Caminho local da pasta de mods |
| `minecraft_version` | `"1.21.1"` | Versão usada no filtro da API do Modrinth |

Todas definidas em `roles/minecraft/defaults/main.yml` e podem ser sobrescritas por inventário ou `-e`.
