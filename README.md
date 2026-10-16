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

```bash
# Iniciar servicios en segundo plano
docker compose up -d --build

# Ver estado de los contenedores
docker compose ps

# Ver logs
docker compose logs -f

# Detener los servicios
docker compose down
```

La API estará disponible en `http://localhost:8000` y PostgreSQL en el puerto `5432`.

## Ejecución local (sin Docker)

```bash
python -m venv .venv
.venv\Scripts\activate          # Windows  (Linux/Mac: source .venv/bin/activate)
pip install -r requirements.txt

# Variables de entorno (ver .env.example). PowerShell:
$env:DATABASE_URL="postgresql://usuario:password@localhost:5432/blacklist_db"
$env:JWT_SECRET_KEY="mi-clave-secreta"

python application.py           # http://localhost:8000
```

Si no se define `DATABASE_URL`, se usa un SQLite local (`blacklist.db`) para desarrollo.

## Autorización

La autenticación usa **Flask-JWT-Extended**. Todos los endpoints de `/blacklists` exigen el encabezado:

```
Authorization: Bearer <JWT>
```

El JWT se genera una vez con la misma `JWT_SECRET_KEY` configurada en el servidor
(local, `.env` o `terraform.tfvars`):

```powershell
$env:JWT_SECRET_KEY="mi-clave-secreta"
python generar_token.py          # imprime el token; cópielo en la variable `token` de Postman
```

El token no expira. Para invalidarlo, cambie `JWT_SECRET_KEY` en el servidor y genere uno nuevo.

| Caso | Código |
|------|--------|
| Sin encabezado o formato incorrecto | 401 |
| Token inválido (mal formado o firmado con otra clave) | 403 |

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
