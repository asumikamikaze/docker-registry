# :whale: ak | DOCKER REGISTRY

Configuración de una `registry` privada para `desarrollo`.

## Index

* **[Registry](#rotating_light-importante-rotating_light)**
    * **[Instalación](#instalación)**
    * **[Repositorio](#repositorio)**
    * **[Estructura](#estructura)**
        * [Compose File](#compose-file)
        * [Env (environment) File](#env-environment-file)
        * [Config File](#config-file)
    * **[Usuarios](#usuarios)**
        * [Creación](#creación-de-un-usuario)
        * [Eliminación](#eliminación-de-un-usuario)
        * [Listado](#lista-de-usuarios)
* **[Troubleshooting...](#wrench-troubleshooting)**

## :rotating_light: Importante :rotating_light:

Todas las ejecuciones sobre el `shell` se definen de la siguiente manera:

```bash
> [command] ...
```

El signo `mayor` (`>`) **NO** se debe incluir, éste indica que la línea debe ser ejecutada dentro del contexto de un `shell`.

# :coffee: REGISTRY

## Instalación

> :warning: **ADVERTENCIA**
>
> Al ejecutar el instalador, éste eliminará todo el contenido del directorio `/data/registry/master`.
>
> La ejecución del mismo será resonsabilidad de quién lo haga.

Puedes iniciar la instalación vía línea de comando mendiante el uso de `curl` o `wget`.

**Vía `curl`:**

```bash
> sh -c "$(curl -fsSL https://raw.githubusercontent.com/asumikamikaze/docker-registry/master/installer.sh)"
```

**Vía `wget`:**

```bash
> sh -c "$(wget https://raw.githubusercontent.com/asumikamikaze/docker-registry/master/installer.sh -O -)"
```

> :white_check_mark: **ESPECIFICACIONES:**
>
> **Host**
> * **Virtualization:** vmware
> * **Operating System:** CentOS Linux 7 (Core)
> * **Kernel:** Linux `3.10.0-862.3.2.el7.x86_64`
> * **Architecture:** `x86-64`
>
> **Software**
> * **Docker:** `18.09.6`, build `481bc77156` (`18.09.1` Server Version) o superior
> * **Docker Compose**: `1.23.2`, build `1110ad01` o superior
> * **Git:** `1.8.3.1` o superior
> * **Curl:** `7.29.0` o superior
>
> Se asume que los requerimientos básicos ya se encuentran instalados.

> :information_source: **REQUERIMIENTO:** `curl` o `wget`
>
> Instalación `yum install [curl|wget]`.

## Repositorio

El proyecto se gestiona a partir de repositorio de tipo `git`, que se ecuentra en la siguiente `url`:

https://github.com/asumikamikaze/docker-registry

Para realizar el despliegue **clonamos** el repositorio dentro del servidor que posea `docker`:

```bash
> git clone -b master --single-branch https://github.com/asumikamikaze/docker-registry.git
```

## Estructura

El directorio de trabajo será establecido en la siguiente ruta: `/data/registry`

```bash
> tree -a --dirsfirst /data/registry

  /data/registry
  ├── /master
  │   ├── /auth
  │   │   └── htpasswd
  │   ├── /cache
  │   ├── /certs
  │   ├── /data
  │   ├── .env
  │   ├── config.yml
  │   ├── docker-compose.yml
  │   └── prune.sh

```

* **master**: configuración de la `registry`
    * **auth**: configuración de la `autenticación`, el archivo `htpasswd` contiene todos los usuarios y contraseñas permitidos en la `registry`.
    * **cache**: persistencia del `cache` mediante `redis`.
    * **certs**: certificados para la configuración del `ssl`.
    * **data**: persistencia de los `repositorios`.
    * **.env**: configuración de las `variables de entorno` a desplegar.
    * **config.yml**: configuración base.
    * **docker-compose.yml**: configuración de los `servicios` a desplegar.
    * **prune.sh**: utilida para el purgado de la `registry`.

### Compose File

Definición de los servicios a desplegar mediante la utilidad `docker-compose`, para mayor información visitar la documentación oficial: https://docs.docker.com/registry/deploying/

El archivo define básicamente 3 servicios:

* **master** (`registry`) definición de la `registry`.
    * https://hub.docker.com/_/registry
* **master_cache** (`redis`) implementación de un `cache` mediante el uso de `redis`.
    * https://hub.docker.com/_/redis
* **master_web** (`registry-browser`) interfaz web para la exploración del contenido de la `registry`.
    * https://hub.docker.com/r/klausmeyer/docker-registry-browser/

Respecto a la configuración de red se emplea el modo `externo`, lo que significa que debe ser [creada](#creación-de-la-red) antes de desplegar los servicios. Para mayor información visitar la documentación oficial: https://docs.docker.com/compose/compose-file/#external-1

> `external`
>
> If set to true, specifies that this network has been created outside of Compose. docker-compose up does not attempt to create it, and raises an error if it doesn’t exist... [read more](https://docs.docker.com/compose/compose-file/#external-1)

```yaml
version: '3.4'

x-restart: &restart
  restart: unless-stopped

services:
  master:
    <<: *restart
    image: registry:latest
    ports:
      - ${PORT}:5000
    ...

  master_cache:
    <<: *restart
    image: redis:latest
    ...

  master_web:
    <<: *restart
    image: registry-browser:latest
    ports:
      - ${PORT_UI}:8080
    ...

networks:
  registry:
    external:
      name: registry
```

> Archivo [:page_facing_up: docker-compose.yml](/docker-compose.yml)

### Env (environment) File

Definición de los valores globales de la configuración del archivo `docker-compose.yml`.

```bash
# WARNING! no editar.
COMPOSE_PROJECT_NAME=registry
COMPOSE_FILE=docker-compose.yml

# .env
HOST=hostname.local
PORT=5000
PORT_UI=5002
MASTER_LOCAL=master.local
MASTER_CACHE_LOCAL=master-cache.local
MASTER_WEB_LOCAL=master-web.local
BASEPATH=/data/registry/master
REDIS_PASSWORD=***
```

> Archivo [:page_facing_up: .env](/.env)

### Config File

La definicón de este archivo apunta a establecer una configuración base para el despliegue de la `registry`, para mayor información visitar la documentación oficial: https://docs.docker.com/registry/configuration/

```yaml
version: 0.1

log:
  accesslog:
    disabled: false
  level: debug
  ...

storage:
  cache:
    blobdescriptor: redis
  filesystem:
    rootdirectory: /var/lib/registry
    maxthreads: 100
  delete:
    enabled: true

auth:
  htpasswd:
    ...

http:
  addr: :5000
  ...

redis:
  ...
```

> Archivo [:page_facing_up: master/config.yml](/master/config.yml)

## Usuarios

La gestión de las crendenciales se realiza mediante la utilidad de apache `htpasswd`, para mayor información visitar la documentación oficial: https://httpd.apache.org/docs/current/programs/htpasswd.html

> En el apartado de `troubleshooting` se explica brevemente como [instalar htpasswd](#instalar-htpasswd)

### Creación de un usuario

```bash
> htpasswd -B /data/registry/master/auth/htpasswd <username>

New password:
Re-type new password:
Adding password for user <username>
```

Utilizando `docker-compose`:

```bash
> docker-compose exec master htpasswd -Bbn <username> <password> >> /data/registry/master/auth/htpasswd
```

### Eliminación de un usuario

```bash
> htpasswd -D /data/registry/master/auth/htpasswd <username>

Deleting password for user <username>
```

### Lista de usuarios

| **username** | **password** |
| --- | --- |
| **admin** | `admin` |

Verificación de los usuarios habilitados:

```bash
> grep -Po '^\w+' /data/registry/master/auth/htpasswd | awk '{print " - " $1}'

 - admin
 - ...
```

# :wrench: TROUBLESHOOTING

## Creación de la red

La red es creada por el instalador, en caso de no utilizar este la misma puede ser creada de la siguiente manera.

```bash
> docker network create --subnet=172.100.0.0/24 --driver=bridge registry
```

## Iniciar los servicios

```bash
> cd /data/registry/master
> docker-compose --compatibility up -d
```

> Modo [--compatibility](#docker-compose-modo-compatibilidad)

## Detener los servicios

```bash
> cd /data/registry/master
> docker-compose down
```

## Visualizar los servicios

```bash
> cd /data/registry/master
> docker-compose ps
```

## Actualizar el repositorio

```bash
> git checkout -f . && git pull --rebase --stat origin master
```

## Docker compose modo compatibilidad

Se requiere la verisón `1.20.0+`, para mayor información visitar la documentación oficial: https://docs.docker.com/compose/compose-file/compose-versioning/#compatibility-mode

> `docker-compose` 1.20.0 introduces a new `--compatibility` flag designed to help developers transition to version 3 more easily. ...

```bash
# verificamos la versión
> docker-compose --version

# descargamos el binario
> wget https://github.com/docker/compose/releases/download/1.24.1/docker-compose-Linux-x86_64

# lo movemos a su destino
> mv -f docker-compose-Linux-x86_64 /usr/bin/docker-compose

# le asignamos privilegios de ejecución
> chmod a+x /usr/bin/docker-compose
```

## Registry

### Purgar

```bash
> cd /data/registry/master
> docker-compose exec master sh -c "/bin/registry garbage-collect --dry-run /etc/docker/registry/config.yml"
```

> **Leer:**
> * https://docs.docker.com/registry/garbage-collection/
> * https://gbougeard.github.io/blog.english/2017/05/20/How-to-clean-a-docker-registry-v2.html

### Ver la configuración

```bash
> cd /data/registry/master
> docker-compose exec master sh -c "cat /etc/docker/registry/config.yml"
```

## Configurar la registry en modo inseguro

```bash
> nano /etc/docker/daemon.json
```

Agregar la siguiente línea, asuimiendo que `hostname.local` es nuestro **Hostname** y `192.168.1.100` la **IP** a la que apunta:

```json
{
  "...": "...",
  "insecure-registries": ["hostname.local:5000","192.168.1.100:5000"]
}
```

Reiniciar el servicio:

```bash
> systemctl daemon-reload && systemctl restart docker
```

Verificar el cambio:

```bash
> docker info

...
Server Version: 18.09.1
...
Name: HOSTNAME
...
Insecure Registries:
 hostname.local:5000
 192.168.1.100:5000
 127.0.0.0/8
Live Restore Enabled: false
...
```

## Instalar htpasswd

```bash
> yum provides \*bin/htpasswd

Loaded plugins: fastestmirror
Repodata is over 2 weeks old. Install yum-cron? Or run: yum makecache fast
Loading mirror speeds from cached hostfile
...

httpd-tools-2.4.6-80.el7.centos.x86_64 : Tools for use with the Apache HTTP Server
Repo        : centos
Matched from:
Filename    : /usr/bin/htpasswd
...

> yum install httpd-tools
...
```

# TODO

* Implementar autenticación por **token**.
* Desplegar con `swarm` también.

--

> (c) 2020 ak | asumikamikaze.com
