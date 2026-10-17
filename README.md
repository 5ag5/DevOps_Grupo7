# DevOps_Grupo7
Grupo 7 del equipo de DevOps

Microservicio de **lista negra global de emails** (Flask + PostgreSQL).

## Arquitectura por capas

```text
Request HTTP → api (controladores) → services (negocio) → repositories (datos) → PostgreSQL
```

| Carpeta | Responsabilidad |
|---------|-----------------|
| `app/api/` | Endpoints REST, validación de entrada (schemas) y respuestas HTTP |
| `app/services/` | Reglas de negocio (normalizar email, evitar duplicados). No conoce HTTP |
| `app/repositories/` | Único punto de acceso a la base de datos |
| `app/models/` | Entidades SQLAlchemy |
| `app/auth.py` | Configuración de Flask-JWT-Extended y respuestas 401/403 |
| `app/config.py` | Configuración leída de variables de entorno |

Cada capa solo llama a la siguiente; así el servicio puede probarse con un repositorio falso.

## Ejecución con Docker Compose (Recomendado)

Para levantar la aplicación junto con PostgreSQL en contenedores:

1. Cree su archivo `.env` a partir de `.env.example`:
   ```bash
   cp .env.example .env
   ```
   Asegúrese de definir un valor para `JWT_SECRET_KEY`.

2. Iniciar servicios en segundo plano:
   ```bash
   docker compose up -d --build
   ```

3. Comandos útiles:
   ```bash
   docker compose ps        # Ver estado de los contenedores
   docker compose logs -f   # Ver logs en tiempo real
   docker compose down      # Detener los servicios
   ```

La API estará disponible en `http://localhost:8000` y PostgreSQL en el puerto `5432`.

## Ejecución local (sin Docker)

```bash
python -m venv .venv
.venv\Scripts\activate          # Windows
source .venv/bin/activate       # Linux / macOS

pip install -r requirements.txt
```

Defina las variables de entorno (ver `.env.example`):

**PowerShell (Windows):**
```powershell
$env:DATABASE_URL="postgresql://usuario:password@localhost:5432/blacklist_db"
$env:JWT_SECRET_KEY="mi-clave-secreta"
```

**Bash (Linux / macOS):**
```bash
export DATABASE_URL="postgresql://usuario:password@localhost:5432/blacklist_db"
export JWT_SECRET_KEY="mi-clave-secreta"
```

Inicie la aplicación:
```bash
python application.py           # http://localhost:8000
```

Si no se define `DATABASE_URL`, se usa un SQLite local (`blacklist.db`) para desarrollo.

## Autorización

La autenticación usa **Flask-JWT-Extended**. Todos los endpoints de `/blacklists` exigen el encabezado:

```http
Authorization: Bearer <JWT>
```

El JWT se genera una vez con la misma `JWT_SECRET_KEY` configurada en el servidor (local, `.env` o `terraform.tfvars`):

**PowerShell (Windows):**
```powershell
$env:JWT_SECRET_KEY="mi-clave-secreta"; python generar_token.py
```

**Bash (Linux / macOS):**
```bash
JWT_SECRET_KEY="mi-clave-secreta" python generar_token.py
```

El script imprimirá el token firmado. Cópielo en la variable `token` de su entorno de Postman.

> [!NOTE]
> El token no expira. Para invalidarlo, cambie `JWT_SECRET_KEY` en el servidor y genere uno nuevo. Nunca suba tokens ni claves al repositorio.

| Caso | Código |
|------|--------|
| Sin encabezado o formato incorrecto | 401 Unauthorized |
| Token inválido (mal formado o firmado con otra clave) | 403 Forbidden |

## Pruebas y Colección de Postman

El repositorio incluye la documentación pública interactiva, una colección completa con assertions y entornos preconfigurados en la carpeta `postman/`:

- **Documentación Pública en Postman:** [https://documenter.getpostman.com/view/58829140/2sBYHSwzie](https://documenter.getpostman.com/view/58829140/2sBYHSwzie)
- **Colección:** `postman/Blacklist.postman_collection.json`
- **Entorno Local / Docker:** `postman/Blacklist-Local.postman_environment.json` (`http://localhost:8000`)
- **Entorno AWS Prod:** `postman/Blacklist-AWS-Prod.postman_environment.json` (`http://<URL_ELASTIC_BEANSTALK>`)

### Pasos rápidos para probar con Postman:
1. Importe la colección `postman/Blacklist.postman_collection.json` y el entorno deseado (o explore la [Documentación Pública en Postman](https://documenter.getpostman.com/view/58829140/2sBYHSwzie)).
2. **Pruebas locales inmediatas (Evaluadores):** Si levantó el servicio con los valores por defecto (`JWT_SECRET_KEY="mi-clave-secreta"`), el entorno `Blacklist-Local` **ya incluye un token JWT pregenerado funcional**. ¡Puede ejecutar las pruebas directamente sin pasos extra!
3. **Pruebas personalizadas o AWS:** Si cambió la clave o desplegó en AWS, genere un token con `generar_token.py` y péguelo en la variable `token`. Para AWS Prod, configure `base_url` con el valor de `terraform output app_url`.
4. Ejecute la colección mediante **Collection Runner** o individualmente (todos los tests pasarán en verde).

Para consultar la cadena del token pregenerado, detalle de assertions, ejecución vía CLI con Newman y más detalles, consulte la [Guía de Postman](postman/README.md).

## Endpoints

### POST /blacklists — Agregar un email a la lista negra

```json
{
  "email": "cliente@correo.com",
  "app_uuid": "123e4567-e89b-12d3-a456-426614174000",
  "blocked_reason": "Fraude (opcional, máx. 255 caracteres)"
}
```

La IP de origen y la fecha/hora se guardan automáticamente.

| Código | Caso |
|--------|------|
| 201 | Email agregado |
| 400 | JSON inválido, email inválido, UUID inválido o `blocked_reason` > 255 |
| 409 | El email ya está en la lista negra (sin distinguir mayúsculas) |

### GET /blacklists/{email} — Consultar un email

```json
{ "email": "cliente@correo.com", "is_blacklisted": true, "blocked_reason": "Fraude" }
```

Retorna `200` en ambos casos (`is_blacklisted: false` si el email no está registrado).

### GET /health

Chequeo de salud del servicio (sin autenticación).

