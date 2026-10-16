# Pruebas de API con Postman – Microservicio Blacklist

Este directorio contiene la colección de Postman y los entornos para probar y validar exhaustivamente el microservicio de lista negra global de emails.

---

## Archivos en este directorio

| Archivo | Descripción |
|---------|-------------|
| `Blacklist.postman_collection.json` | Colección completa con todos los endpoints, encabezados de autorización Bearer JWT, ejemplos de respuesta y pruebas automatizadas (*assertions* en JavaScript). |
| `Blacklist-Local.postman_environment.json` | Entorno configurado para ejecución local o con Docker Compose (`http://localhost:8000`). |
| `Blacklist-AWS-Prod.postman_environment.json` | Entorno configurado para el despliegue en AWS Elastic Beanstalk (`app_url`). |

---

## Autenticación con JWT (Flask-JWT-Extended)

La API requiere autenticación mediante **JSON Web Token (JWT)** en el encabezado HTTP:

```http
Authorization: Bearer <JWT>
```

> [!IMPORTANT]
> **No confunda el token con la clave secreta:**
> - `JWT_SECRET_KEY` es la **clave del servidor** configurada en `.env` o `terraform.tfvars`.
> - `token` es el **JWT firmado** que se genera a partir de esa clave y que debe pegarse en Postman.

### Token Pregenerado para Pruebas / Evaluación Rápida

Para facilitar la revisión y calificación por parte de los profesores y monitores:
* Si levanta el proyecto usando los valores por defecto (`cp .env.example .env`), el servidor usará `JWT_SECRET_KEY="mi-clave-secreta"`.
* **El entorno `Blacklist-Local.postman_environment.json` y la colección ya vienen preconfigurados con un JWT válido firmado con esa clave.**
* ¡No es necesario generar nada para probar en local/Docker! Simplemente importe y ejecute las pruebas.

Si necesita copiar el token pregenerado manualmente, es el siguiente:

```text
eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3OTIxNTAxNzQsIm5iZiI6MTc5MjE1MDE3NCwianRpIjoiNDhkM2Y0YjQtMjY4Ny00MDIzLThlNDEtZmY3NDk3YmIxMzQ1IiwiaWRlbnRpdHkiOiJibGFja2xpc3QtY2xpZW50IiwiZnJlc2giOmZhbHNlLCJ0eXBlIjoiYWNjZXNzIn0.sJmedFxB7n6ffhcizXycfdNTs-ipDTlFvlwWo7hKDPQ
```

### Generación de un Nuevo JWT (Entornos personalizados o AWS Prod)

Si cambia la clave en el servidor o desea generar un token para su entorno desplegado en AWS (`terraform.tfvars`), ejecute el script con su clave:

**En PowerShell (Windows):**
```powershell
$env:JWT_SECRET_KEY="su-clave-secreta"; python generar_token.py
```

**En Bash (Linux / macOS):**
```bash
JWT_SECRET_KEY="su-clave-secreta" python generar_token.py
```

Copie la cadena de texto resultante y péguela en el valor de la variable `token` de su entorno en Postman.

---

## Variables de Entorno en Postman

| Variable | Tipo | Descripción | Ejemplo / Valor inicial |
|----------|------|-------------|-------------------------|
| `base_url` | default | URL base donde corre el microservicio | `http://localhost:8000` (Local) / `http://<URL_ELASTIC_BEANSTALK>` (AWS) |
| `token` | secret | Token JWT generado con `generar_token.py` | *(Pegar el JWT generado)* |
| `app_uuid` | default | UUID v4 que identifica la aplicación cliente | `123e4567-e89b-12d3-a456-426614174000` |
| `email` | default | Email de prueba utilizado en las peticiones | `prueba@correo.com` *(se actualiza dinámicamente en tests)* |

---

## Peticiones y Casos de Prueba Cubiertos

La colección está diseñada para ejecutarse secuencialmente y cubre todos los requerimientos de la Entrega 1:

| # | Petición | Método y Ruta | Auth | Código | Assertions / Comportamiento |
|---|----------|---------------|------|--------|------------------------------|
| 1 | **Health** | `GET /health` | No | `200 OK` | Valida que el servicio esté arriba (`status: "ok"`). Utilizado por el balanceador AWS ALB. |
| 2 | **POST - Agregar email** | `POST /blacklists` | Bearer JWT | `201 Created` | En su *Pre-request Script* genera un email único (`prueba_${Date.now()}@correo.com`) para permitir ejecuciones repetidas. Valida que se registre la IP (`ip_address`) y la fecha (`created_at`). |
| 3 | **POST - Email duplicado** | `POST /blacklists` | Bearer JWT | `409 Conflict` | Intenta registrar nuevamente el email recién creado. Valida respuesta 409 ante duplicados simultáneos o secuenciales. |
| 4 | **POST - Datos inválidos** | `POST /blacklists` | Bearer JWT | `400 Bad Request` | Envía un email con formato inválido y un UUID que no cumple RFC 4122. Valida estructura de errores en respuesta. |
| 5 | **GET - Email en lista negra** | `GET /blacklists/{{email}}` | Bearer JWT | `200 OK` | Consulta el email registrado y valida `is_blacklisted: true` con su razón de bloqueo. |
| 6 | **GET - Email no registrado** | `GET /blacklists/libre@correo.com` | Bearer JWT | `200 OK` | Consulta un email inexistente y valida `is_blacklisted: false` y `blocked_reason: null`. |
| 7 | **GET - Sin token** | `GET /blacklists/{{email}}` | Sin token | `401 Unauthorized` | Verifica rechazo 401 por falta de credenciales (`Token de autorización no proporcionado`). |
| 8 | **GET - Token inválido** | `GET /blacklists/{{email}}` | Token erróneo | `403 Forbidden` | Envía un token mal formado o con firma inválida y verifica rechazo 403 (`Token de autorización inválido`). |

---

## Paso a Paso: Cómo Ejecutar en Postman

1. **Importar los archivos en Postman**:
   - Abra Postman y haga clic en **Import** (arriba a la izquierda).
   - Arrastre o seleccione `Blacklist.postman_collection.json`.
   - Arrastre o seleccione el entorno deseado:
     - `Blacklist-Local.postman_environment.json` (para pruebas locales / Docker).
     - `Blacklist-AWS-Prod.postman_environment.json` (para pruebas en AWS).

2. **Configurar las variables del entorno**:
   - Seleccione el entorno importado en el menú desplegable superior derecho de Postman.
   - Haga clic en el ícono de edición del entorno (ojo o lápiz).
   - En `base_url`:
     - Si usa **Blacklist-Local**: confirme que esté en `http://localhost:8000`.
     - Si usa **Blacklist-AWS-Prod**: reemplace `<URL_ELASTIC_BEANSTALK_PROD>` por la URL entregada por Terraform (`terraform output app_url`).
   - En `token`: pegue el JWT generado con `generar_token.py` tanto en *Initial value* como en *Current value*.
   - Guarde los cambios (**Save**).

3. **Ejecutar la suite completa con Collection Runner**:
   - Seleccione la colección **DevOps Grupo7 - Blacklist**.
   - Haga clic en **Run collection**.
   - Verifique el orden de las peticiones (deben ir del 1 al 8 como están ordenadas).
   - Haga clic en **Run DevOps Grupo7 - Blacklist**.
   - Todos los tests deben pasar en verde (**All Passed**).

---

## Ejecución Automatizada con Newman (CLI)

También es posible ejecutar las pruebas directamente desde la terminal mediante **Newman**:

```bash
# Instalar Newman globalmente si no lo tiene:
npm install -g newman

# Ejecutar suite con el entorno local pasando el token generado:
newman run postman/Blacklist.postman_collection.json \
  -e postman/Blacklist-Local.postman_environment.json \
  --env-var "token=<PEGA_AQUI_TU_JWT>"
```
