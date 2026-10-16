# Infraestructura con Terraform – blacklist

Crea y destruye con un comando todo lo necesario para correr la API en AWS Elastic Beanstalk
con Docker y RDS PostgreSQL. Está organizada en **módulos** reutilizables y **entornos**
(`dev` y `prod`), cada uno con su propio estado.

## Estructura

```
terraform/
├── modules/                    piezas reutilizables, sin valores fijos
│   ├── network/                VPC por defecto + security groups (app y RDS, puerto 5432)
│   ├── iam/                    rol de servicio y perfil de instancia (opcional)
│   ├── rds/                    PostgreSQL privado + DATABASE_URL
│   ├── beanstalk/              bucket S3, aplicación, versión, entorno Docker,
│   │                           health check /health, estrategia de despliegue
│   └── budget/                 alerta de gasto por correo (opcional)
│
├── environments/
│   ├── dev/                    1–2 instancias, AllAtOnce
│   └── prod/                   3–6 instancias, Rolling (para las estrategias)
│       ├── main.tf             une los módulos
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf         proveedor AWS y región
│       └── terraform.tfvars.example
│
├── scripts/
│   ├── empaquetar.ps1          Windows: arma ../../blacklist.zip
│   └── empaquetar.sh           Mac/Linux
└── README.md
```

En el repositorio, `terraform/` va en la raíz, al lado de `app/`, `Dockerfile` y `application.py`.

Nombres que crea cada entorno (ejemplo `dev`):

| Recurso | Nombre |
|---|---|
| Aplicación / entorno Beanstalk | `blacklist-dev-app` / `blacklist-dev-env` |
| Base de datos | `blacklist-dev-db` (base `blacklist_db`) |
| Security groups | `blacklist-dev-app-sg`, `blacklist-dev-rds-sg` |
| Roles | `blacklist-dev-eb-service-role`, `blacklist-dev-eb-ec2-profile` |
| Bucket | `blacklist-dev-eb-versions-<cuenta>-<región>` |

## Requisitos (una sola vez)

1. **Terraform** ≥ 1.5 – https://developer.hashicorp.com/terraform/install
   (Windows: `winget install Hashicorp.Terraform`)
2. **AWS CLI** – https://aws.amazon.com/cli/
3. **Un usuario IAM con permisos de administrador** en su cuenta (no use el usuario root).
   Los pasos están en la sección siguiente.

## Usuario IAM y AWS CLI

### 1. Crear el usuario IAM (en la consola web)

1. Entre a la consola con su cuenta y vaya a **IAM → Usuarios → Crear usuario**.
2. En **Nombre** escriba, por ejemplo, `su-nombre-admin`.
3. Dé clic en **Siguiente**.
4. Seleccione **Adjuntar políticas directamente** y marque **AdministratorAccess**.
5. Dé clic en **Siguiente** y luego en **Crear usuario**.
6. Abra el usuario y vaya a la pestaña **Credenciales de seguridad → Crear clave de acceso**.
7. Elija **Interfaz de línea de comandos (CLI)**, acepte la casilla y dé clic en **Siguiente → Crear clave de acceso**.
8. Copie el **Access key ID** y el **Secret access key**. La clave secreta solo se muestra una vez; también puede descargar el `.csv`.

### 2. Configurar la AWS CLI

```
aws configure
```

Responda las preguntas:

```
AWS Access Key ID:      (el que copió)
AWS Secret Access Key:  (el secreto)
Default region name:    us-east-2
Default output format:  json
```

Verifique con:

```
aws sts get-caller-identity
```

El `Arn` debe terminar en `user/su-nombre-admin`. Si termina en `root`, está usando las claves del usuario root.

### 3. Confirmar que es administrador

```
aws iam list-attached-user-policies --user-name su-nombre-admin
```

Debe aparecer `AdministratorAccess` en la lista.

### Seguridad

- **No comparta ni suba a GitHub** esas claves. Quedan guardadas en `C:\Users\<usuario>\.aws\credentials` (Windows) o `~/.aws/credentials` (Mac/Linux), fuera del proyecto.
- Si alguna vez creó claves para el usuario **root**, bórrelas: entre como root, haga clic en su nombre arriba a la derecha y vaya a **Credenciales de seguridad → Claves de acceso → Eliminar**.
- Si `aws sts get-caller-identity` responde `ExpiredToken`, hay credenciales temporales viejas. Borre la línea `aws_session_token` del archivo de credenciales y revise que no existan las variables de entorno `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` ni `AWS_SESSION_TOKEN`.

## Roles de Elastic Beanstalk

Por defecto (`create_iam_roles = true`) **Terraform crea los dos roles** con todo lo necesario:
`blacklist-<entorno>-eb-service-role` y `blacklist-<entorno>-eb-ec2-profile`. No hay que hacer nada.

Si prefiere usar roles que ya existen en su cuenta (por ejemplo, creados a mano desde la consola),
ponga en `terraform.tfvars`:

```hcl
create_iam_roles      = false
service_role_name     = "aws-elasticbeanstalk-service-role"
instance_profile_name = "Instance_Profile_EC2"
```

y verifique en **IAM → Roles** que existen y tienen esta configuración:

1. **aws-elasticbeanstalk-service-role** (lo usa el servicio Elastic Beanstalk)
   - Confía en: `elasticbeanstalk.amazonaws.com`
   - Políticas:
     - `AWSElasticBeanstalkEnhancedHealth`
     - `AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy`
2. **Instance_Profile_EC2** (lo usan las instancias EC2)
   - Confía en: `ec2.amazonaws.com`
   - Políticas:
     - `AWSElasticBeanstalkWebTier`
     - `AWSElasticBeanstalkWorkerTier`
     - `AWSElasticBeanstalkMulticontainerDocker`

Para revisarlos, abra cada rol: la pestaña **Relaciones de confianza** muestra en qué confía
y la pestaña **Permisos** muestra las políticas. Si se intercambian, el entorno falla con
`Unable to assume role`.

## Crear un entorno

```powershell
# 1. Empaquetar la app (desde la raíz del repositorio)
powershell -ExecutionPolicy Bypass -File terraform\scripts\empaquetar.ps1   # Mac/Linux: bash terraform/scripts/empaquetar.sh

# 2. Configurar y crear
cd terraform\environments\dev  # o prod
copy terraform.tfvars.example terraform.tfvars    # editar contraseña, clave JWT y correo
terraform init
terraform apply
```

Tarda unos 15–20 minutos (RDS es lo más lento). Al final muestra `app_url` y `health_url`.
Abra `health_url`: debe responder `"status": "ok", "database": "up"`.

Para `prod` es igual, dentro de `terraform\environments\prod`.

## Desplegar una versión nueva

1. Cambie el código (por ejemplo `APP_VERSION = "v2"` en `app/__init__.py`).
2. Empaquete y aplique en el entorno:
   ```powershell
   powershell -ExecutionPolicy Bypass -File ..\..\scripts\empaquetar.ps1
   terraform apply -var="version_label=v2"
   ```

## Estrategias de despliegue (en prod)

`prod` ya trae 3–6 instancias. Para cada estrategia:

```powershell
cd terraform\environments\prod

# 1) Cambiar la estrategia (configuración; NO es el despliegue que se mide)
terraform apply -var="deployment_policy=Immutable"

# 2) Desplegar una versión nueva con esa estrategia (este SÍ se mide)
powershell -ExecutionPolicy Bypass -File ..\..\scripts\empaquetar.ps1
terraform apply -var="deployment_policy=Immutable" -var="version_label=v3"
```

Lo más cómodo es cambiar `deployment_policy` en `terraform.tfvars` y pasar solo `version_label`.

| `deployment_policy` | Qué hace |
|---|---|
| `AllAtOnce` | Todas las instancias a la vez; hay caída breve |
| `Rolling` | Por lotes de `batch_size` instancias (por defecto 1) |
| `RollingWithAdditionalBatch` | Igual, pero lanza un lote extra para no perder capacidad |
| `Immutable` | Lanza instancias nuevas y luego borra las viejas |
| `TrafficSplitting` | Envía `traffic_split_percent`% del tráfico a la versión nueva durante `traffic_split_evaluation_minutes` minutos |

Cambie la estrategia y despliegue la versión en **dos `apply` separados**: si van juntos,
Beanstalk los aplica en una sola actualización y la estrategia no se mide bien.
Los tiempos y capturas se toman de la consola (pestaña **Eventos**).

## Destruir (al terminar cada sesión de trabajo)

```powershell
cd terraform\environments\dev     # o prod
terraform destroy
```

Borra Beanstalk, RDS, security groups, roles, bucket y alerta, en el orden correcto (10–15 min).


## Problemas comunes

| Error | Solución |
|---|---|
| `already exists` | Ya existe un recurso con ese nombre (por ejemplo, creado a mano). Bórrelo o cambie `project` en `terraform.tfvars` |
| `Invalid function argument ... filemd5` | No existe `blacklist.zip` en la raíz: ejecute el script de empaquetado |
| `Unable to assume role` | Con `create_iam_roles = false` los roles indicados no existen o están intercambiados. Use `create_iam_roles = true` |
| Entorno en *Severe* / 5xx en `/health` | Consola → Beanstalk → **Registros → Últimas 100 líneas** |
| El tipo de instancia no está disponible en una zona | Pruebe `instance_type = "t3.small"` u otra región |

## Notas para el equipo

- Cada integrante usa **su propia cuenta de AWS**, así que cada uno tiene su propio estado
  (`terraform.tfstate` dentro de cada entorno, que **no** se sube a GitHub).
- No suba `terraform.tfvars`: tiene la contraseña de la base de datos y la clave JWT.
- Si borra `terraform.tfstate` con recursos creados, Terraform ya no los conoce:
  bórrelos a mano desde la consola.
- En el `.gitignore` de la raíz del repositorio agregue `blacklist.zip`.