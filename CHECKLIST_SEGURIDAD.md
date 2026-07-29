# Checklist de Seguridad de la Información — Evidencia en el proyecto

Auditoría del checklist "Evaluación de Validaciones en Proyecto Integrador" contra el código real de:
- **Frontend**: este repo (Flutter) — `lib/`
- **Backend**: `../toolshare-api` (Go, arquitectura hexagonal)

Leyenda: ✅ Cumple · ⚠️ Parcial · ❌ No cumple

---

## 2. Checklist de Validación de Entradas y Sanitización

### 1. Validación del Lado del Cliente

**Validación de Formato, Longitud y Rango — ⚠️ Parcial**
- `lib/feactures/bank_account/presentation/screes/bank_account_screen.dart:203-213` — CLABE con `maxLength: 18`. **Por qué cumple**: obliga longitud exacta antes de enviar al backend, evitando peticiones inválidas.
- `lib/feactures/payment_methods/presentation/screes/add_card_screen.dart:95-143` — `LengthLimitingTextInputFormatter` en número/CVV/vencimiento. **Por qué cumple**: restringe cuántos caracteres puede teclear el usuario, previniendo overflow de datos.
- `lib/feactures/solicitante/presentation/screes/tool_detail_screen.dart:70-72` — clamp de días de renta a 1-30. **Por qué cumple**: impide rangos absurdos (0 días o 500 días) antes de calcular el precio.
- `lib/feactures/auth/register/presentation/screes/register_screen.dart:349-437` — teléfono ≥10 dígitos, password ≥8. **Por qué cumple**: aplica un mínimo antes de permitir el submit.
- Debilidad: `lib/feactures/propietario/presentation/widgets/tool_basic_info_fields.dart:104-111` — "Antigüedad (Meses)" solo valida no-vacío, sin `int.tryParse` ni rango. **Por qué NO cumple del todo**: acepta texto no numérico porque el validator nunca intenta parsear el valor.

**Validación de Contenido y Regex — ✅ Cumple (uso limitado)**
- `register_screen.dart:366` — `RegExp(r'\D')` para limpiar el teléfono. **Por qué cumple**: filtra cualquier carácter que no sea dígito antes de guardar el valor.
- `bank_account_screen.dart:211` — `RegExp(r'^\d{18}$')` para CLABE. **Por qué cumple**: valida el contenido completo (solo dígitos, longitud exacta), no solo la longitud.
- `add_card_screen.dart:129,165` — `RegExp(r'^\d{2}/\d{2}$')` para `MM/AA`. **Por qué cumple**: garantiza el formato exacto de fecha de vencimiento, rechazando formatos ambiguos.
- `login_form.dart:98` — email solo usa `.contains('@')`, sin regex. **Por qué NO cumple del todo**: acepta valores como `@` o `a@` como "válidos".

### 2. Validación del Lado del Servidor

**Autenticidad, Consistencia e Integridad de datos recibidos — ✅ Cumple**
- `internal/user/handler/auth_dto.go:11-16` — tags `binding:"required,email,min=8"`. **Por qué cumple**: Gin/validator rechaza la petición con 400 antes de que el handler ejecute lógica, si el JSON no cumple el contrato.
- `internal/rental/handler/rental_dto.go:12-19,28-30`, `internal/tool/handler/tool_dto.go:8-21`, `internal/review/handler/review_dto.go:11` — mismo patrón de `binding:"required"`. **Por qué cumple**: cada endpoint define su propio contrato de entrada, no confía en el cliente.
- Validación adicional en servicio (fechas RFC3339, rating 1-5, CLABE). **Por qué cumple**: hay una segunda capa de verificación además del binding, por si la regla no se puede expresar solo con tags.

**Validación de Permisos y Control de Acceso — ✅ Cumple**
- `internal/shared/middleware/auth.go:21-45` (`RequireAuth`) — decodifica y valida el JWT en cada request protegida, aplicado en `router.go:82,99,138`. **Por qué cumple**: sin token válido no se llega al handler.
- `internal/tool/service/tool_service.go:165-166,217-218,286-287,345-346,367-368` — compara `tool.OwnerID != ownerID` antes de editar/borrar. **Por qué cumple**: es control de acceso a nivel de *dato* (no solo de endpoint), evita que un dueño edite herramientas de otro.
- `internal/rental/handler/rental_handler.go:152-155`, `internal/review/service/review_service.go:47-58` — solo owner/requester de la renta pueden verla o calificarla. **Por qué cumple**: mismo principio aplicado a rentas y reseñas.

### 3. Tipado de Datos y Lógica de Negocio

**Verificación estricta de Tipos — ✅ Cumple**
- `internal/rental/handler/rental_handler.go:56-64` — `time.Parse(time.RFC3339,...)` con `if err != nil → 400`. **Por qué cumple**: una fecha mal formada nunca llega a convertirse en un `time.Time` inválido dentro del dominio.
- `internal/shared/helpers.go:14-21` — `uuid.Parse` con manejo de error. **Por qué cumple**: un ID mal formado se rechaza antes de tocar la base de datos.
- `lib/feactures/payment_methods/.../add_card_screen.dart:36-37` — `int.tryParse` para mes/año (no `int.parse`, que crashea). **Por qué cumple**: falla de forma controlada (retorna `null`) en vez de lanzar una excepción no capturada.

**Cumplimiento de Reglas de Negocio — ⚠️ Parcial**
- `internal/rental/service/rental_service.go` — `ErrToolNotAvailable`, `ErrRentalNotPending`, `ErrCannotCancelDone`. **Por qué cumple**: impide transiciones de estado inválidas (ej. cancelar una renta ya finalizada).
- `internal/review/service/review_service.go:63-68` — bloquea calificar dos veces la misma renta. **Por qué cumple**: hay un chequeo explícito de "ya existe reseña" antes de insertar.
- Falta: no se valida solapamiento de fechas de renta contra otras rentas activas de la misma herramienta; la disponibilidad depende solo del flag booleano `tools.is_available` (`rental_service.go:94-95`). **Por qué NO cumple del todo**: dos solicitudes concurrentes en fechas distintas podrían generar conflicto si el flag no se sincroniza atómicamente.

### 4. Reglas Específicas de Validación

**Email — ⚠️ Parcial**
- `internal/user/handler/auth_dto.go:12,20` (`binding:"email"`) + `internal/user/service/auth_service.go:71,109` (`strings.ToLower(strings.TrimSpace(...))`). **Por qué cumple (backend)**: valida el formato Y normaliza, evitando duplicados tipo `A@x.com` vs `a@x.com`.
- `lib/feactures/auth/login/presentation/components/login_form.dart:98` — solo `.contains('@')`. **Por qué NO cumple (frontend)**: no verifica dominio ni estructura, deja pasar valores como `@`.

**Tarjetas de Crédito — ✅ Cumple (por diseño correcto, no por Luhn)**
- `auth_dto.go:57`, `mercadopago_provider.go:166`, `auth_service.go:287-325` — solo se guarda `card_token`, nunca el PAN/CVV. **Por qué cumple**: el dato sensible ni siquiera transita por tu base de datos; se delega a Mercado Pago, que ya cumple PCI-DSS. No hace falta Luhn propio porque nunca manejas el número real.

**Contraseñas Fuertes — ❌ No cumple**
- Solo se exige longitud mínima de 8 caracteres (cliente y servidor, sin regla de mayúsculas/números/símbolos). **Por qué NO cumple**: una contraseña como `"aaaaaaaa"` pasa la validación.
- `auth_service.go:81` — `bcrypt.GenerateFromPassword(pwd, 12)`. **Esto sí es correcto** pero es almacenamiento (resistencia a fuerza bruta/rainbow tables), no exige complejidad del password en sí.

### 5. Validación Cruzada y Contextual

**Coherencia entre múltiples campos — ⚠️ Parcial**
- `internal/rental/handler/rental_handler.go:66-69` — chequea `end_date.After(start_date)`. **Por qué cumple**: rechaza rangos de fecha imposibles antes de crear la renta.
- `internal/rental/handler/webhook_handler.go:133-146` — valida que `external_reference` del pago pertenezca al usuario/renta que lo originó. **Por qué cumple**: evita que un webhook falsificado confirme el pago de la renta de otro usuario.
- Falta la validación de solapamiento de fechas (ver punto 3) y no hay campo "confirmar contraseña" en el registro del frontend. **Por qué NO cumple del todo**: nada compara password vs. su confirmación.

**Validez en contexto específico de uso — ✅ Cumple**
- `internal/review/service/review_service.go` — rating limitado a 1-5, solo owner/requester de una renta pueden calificarla o verla. **Por qué cumple**: el valor y quién puede enviarlo están acotados al contexto real de negocio (una reseña solo tiene sentido para quien participó en la renta).

### 6. Sanitización de Entrada (Seguridad y Hardening)

**Escapado de Caracteres (SQL/HTML/JS) — ✅ Cumple (SQL) / ❌ No aplica (HTML/JS)**
- `internal/tool/postgres/tool_repository.go` (y el resto de `*/postgres/`) — todas las queries usan `pgx` con placeholders `$1,$2...`. **Por qué cumple**: el valor nunca se concatena al string SQL; el driver lo envía como parámetro separado, lo que hace imposible la inyección SQL clásica.
- No hay escapado de HTML/JS. **Por qué no aplica**: el frontend es Flutter nativo (widgets, no WebView renderizando HTML de usuario), así que no hay superficie de XSS clásica.

**Filtrado de Entradas (Whitelisting) — ✅ Cumple**
- DTOs (`*_dto.go` en cada `handler/`) limitan los campos aceptados por endpoint. **Por qué cumple**: aunque el modelo de dominio tenga más campos, el `ShouldBindJSON` solo llena los que el DTO declara, evitando "mass assignment" (que el cliente inyecte campos como `role` o `id` que no debería poder setear).

**Limpieza y Codificación (Trim, Normalize, Base64, URL Encoding) — ⚠️ Parcial**
- Trim/normalize en email/CLABE/bancarios (`auth_service.go:71,109`) y ~64 usos de `.trim()` en el frontend (ej. `register_screen.dart:252-257`). **Por qué cumple donde se aplica**: evita que espacios/mayúsculas generen duplicados o fallos de comparación.
- Falta en `name`, `description`, `comment` de reseñas. **Por qué NO cumple ahí**: esos campos se guardan tal cual los escribe el usuario, con espacios extra incluidos.

**Uso de Funciones y Librerías Seguras — ✅ Cumple**
- `go.mod`: `golang-jwt/jwt/v5`, `golang.org/x/crypto/bcrypt`, `pgx/v5`, `gin` + `go-playground/validator`. **Por qué cumple**: son librerías mantenidas y auditadas por la comunidad, no implementaciones caseras de crypto/parsing (que suelen tener bugs sutiles).

**Canonicalización y Escape de Salida Contextual (Path/Case Normalization) — ❌ No cumple**
- Hallazgo de riesgo: el nombre de archivo subido (`multipart.FileHeader.Filename`) se usa crudo para construir la ruta de guardado sin `filepath.Base()`:
  `internal/tool/service/tool_service.go:378` → `internal/shared/storage/local_storage.go:22,42` (`filepath.Join`)
  Un nombre de archivo malicioso (ej. `../../etc/algo`) podría escribir fuera del directorio de uploads.

### 7. Gestión, Frameworks y Auditoría

**Frameworks/Librerías de validación actualizadas — ✅ Cumple**
- `go.mod`: gin v1.10.0, jwt/v5 v5.2.1, pgx/v5 v5.6.0, validator v10.20.0. **Por qué cumple**: son versiones recientes sin CVEs conocidos activos al momento de la auditoría.

**Manejo de Errores Seguro (evita fuga de info sensible / stack traces) — ❌ No cumple (backend) / ✅ Cumple (frontend)**
- `internal/shared/helpers.go:39-40` (`HandleServiceErr`, rama default) — `c.JSON(500, gin.H{"error": err.Error()})`. **Por qué NO cumple**: para cualquier error no clasificado expone el mensaje interno crudo (posibles detalles de driver de BD) directo al cliente.
- `lib/core/error/app_error.dart` — traduce códigos HTTP a mensajes genéricos en español. **Por qué cumple**: el usuario nunca ve un stack trace ni el texto crudo de la excepción de Dart, sin importar qué falle internamente.

**Demostración práctica de Pentesting/Análisis Estático — ⚠️ Parcial (evidencia contradictoria)**
- Hay evidencia de un pentest previo: comentarios "Corrige el hallazgo H-01/H-02/H-04/H-09" en `internal/shared/middleware/security.go` (CORS whitelist, rate limit, recovery sin stack trace, headers de seguridad HTTP)
- **Pero ese middleware corregido NO está conectado al servidor**: `internal/shared/router/router.go:27` sigue usando `gin.Recovery()` y una función `corsMiddleware()` local (línea 154-168) con `Access-Control-Allow-Origin: *` + `Access-Control-Allow-Credentials: true` — el mismo patrón inválido que H-01 dice haber corregido. Las mitigaciones existen como código muerto, no aplicado en `cmd/server/main.go` / `router.go`.
- No hay CI (`.github/workflows`), ni `.golangci.yml`, ni `gosec`, ni tests de seguridad automatizados.

---

## Resumen ejecutivo por sección del formulario

| # | Criterio | Veredicto |
|---|----------|-----------|
| 1.1 | Validación de Formato, Longitud y Rango | ⚠️ Parcial |
| 1.2 | Validación de Contenido y Regex | ✅ Sí |
| 2.1 | Autenticidad/Integridad (servidor) | ✅ Sí |
| 2.2 | Permisos y Control de Acceso | ✅ Sí |
| 3.1 | Tipado estricto de datos | ✅ Sí |
| 3.2 | Reglas de negocio | ⚠️ Parcial (falta solapamiento de fechas) |
| 4 | Email/Tarjetas/Contraseñas fuertes | ⚠️ Parcial (falta complejidad de password) |
| 5.1 | Coherencia entre campos | ⚠️ Parcial (falta confirmar password, solapamiento) |
| 5.2 | Validez contextual | ✅ Sí |
| 6.1 | Escapado de caracteres (SQL) | ✅ Sí |
| 6.2 | Filtrado whitelisting | ✅ Sí |
| 6.3 | Trim/Normalize/Encoding | ⚠️ Parcial |
| 6.4 | Librerías seguras | ✅ Sí |
| 6.5 | Canonicalización de rutas (uploads) | ❌ No |
| 7.1 | Frameworks actualizados | ✅ Sí |
| 7.2 | Manejo de errores seguro | ❌ No (backend expone `err.Error()` crudo) |
| 7.3 | Evidencia de pentest/SAST | ⚠️ Parcial (mitigaciones escritas pero no conectadas) |

## Antes de la evaluación, prioridad de arreglo (rápidos y con alto impacto)

1. **`router.go:154-168`**: reemplazar `corsMiddleware()` local por `sharedmiddleware.CORS()` + `SecurityHeaders()` que ya existen en `internal/shared/middleware/security.go` pero no se usan.
2. **`internal/shared/helpers.go:39-40`**: no devolver `err.Error()` crudo en el 500 default; usar un mensaje genérico y solo loguear el detalle (el `log.Printf` de la línea 38 ya está bien).
3. **`internal/tool/service/tool_service.go:378`**: aplicar `filepath.Base()` al `Filename` del upload antes de construir la ruta.
4. Contraseñas: agregar regla de complejidad (mayúsculas + número, por ejemplo) en `auth_dto.go` y en `register_screen.dart`.
5. Reservas: validar solapamiento de fechas contra rentas activas de la misma herramienta (no solo el flag `is_available`).
