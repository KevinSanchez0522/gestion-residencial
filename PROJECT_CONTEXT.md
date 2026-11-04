# PROJECT_CONTEXT.md — Contexto del proyecto para agentes de IA

> **Fuente de verdad.** Léelo completo antes de modificar código.
> Este documento describe la visión de negocio, el stack real detectado y las reglas
> críticas que **no deben romperse** al evolucionar la aplicación.
> Última revisión: 2026-11-03. La persistencia de negocio migró de Firebase a
> SQLite local; las referencias históricas a Firestore deben interpretarse como
> equivalentes a las consultas filtradas por `building_id` del repositorio local.

---

## 1. Visión del negocio

Aplicación profesional para **delegados de propiedad horizontal (PH) en Colombia**,
enmarcada en la **Ley 675 de 2001** (régimen de propiedad horizontal) y las normas de
convivencia que de ella se derivan.

- **Usuario principal:** delegado/administrador de PH que gestiona **hasta 24 copropiedades**
  de forma simultánea.
- **Usuarios secundarios:**
  - **Residentes / propietarios / inquilinos:** reportan novedades, consultan tareas y
    estados de cuenta, y usan el asistente de convivencia.
  - **Gerencia:** panel global de las copropiedades asignadas.
- **Naturaleza multi-tenant:** una misma app y un mismo backend sirven a **múltiples
  edificios/conjuntos**. El aislamiento de datos entre copropiedades es un requisito
  **no negociable**.
- **Objetivo funcional:** centralizar la operación de la PH (ficha técnica, certificaciones,
  apartamentos/ocupantes, tareas, PQRS, estados de cuenta y asistente de convivencia) en
  una sola herramienta móvil.

---

## 2. Stack tecnológico exacto detectado

### 2.1 Frontend — `proyecto_delegado` (Flutter)

| Área | Paquete | Versión detectada |
|---|---|---|
| Framework | Flutter / Dart SDK | Flutter 3.41.4 / Dart `^3.11.1` (Material 3) |
| Persistencia | `sqflite` | `^2.4.2+1` |
| Sesión local | `shared_preferences` | `^2.5.6` |
| Hash de contraseña | `crypto` | `^3.0.8` |
| Estado / MVVM | `provider` | `^6.1.5+1` |
| Calendario | `table_calendar` | `^3.1.2` |
| Fechas/i18n | `intl` | `^0.19.0` |
| Notificaciones | `flutter_local_notifications` | `^17.2.2` |
| Zonas horarias | `timezone` | `^0.9.4` |
| GenAI (cliente) | `google_generative_ai` | `^0.4.7` (declarada) |
| HTTP | `http` | usada en `gemini_service.dart` |

- **No hay Firebase ni Firestore en la versión actual.** La autenticación y los
  datos de negocio son locales (SQLite).
- La IA se consume a través del backend FastAPI.

### 2.2 Backend — `backend_delegado` (FastAPI)

- **Python + FastAPI**, servido con **Uvicorn** en `0.0.0.0:8000` (`reload=True` en desarrollo).
- Validación de payload con **Pydantic** (`BaseModel`).
- **Google GenAI SDK oficial**: `from google import genai`, `from google.genai import types`
  y `from google.genai import errors`.
- Modelo activo: **`gemini-3.6-flash`** (constante `PRIMARY_MODEL`).
- Endpoints actuales:
  - `GET /` → health check (`{"status": "Servidor activo y escuchando"}`).
  - `POST /api/resident-chat` → recibe `{ building_name, message }` y devuelve `{ response }`.

### 2.3 Flujo de datos de IA

```
ResidentAiChatScreen (Flutter)
        │  GeminiService.sendMessage()
        ▼
HTTP POST  ──►  FastAPI /api/resident-chat  ──►  Google GenAI (gemini-3.6-flash)
        ◄──  { "response": "..." }  ◄──
```

---

## 3. Reglas críticas de desarrollo

### 3.1 Aislamiento estricto de datos por edificio (`building_id`)

- **Todo** dato de negocio debe estar ligado a un `building_id` / `buildingId`.
- Toda consulta local **debe** estar filtrada/encapsulada por edificio:
  - `tasks` → campo `building_id` + `where('building_id = ?', buildingId)`.
  - `apartments` → clave compuesta `(building_id, id)`.
  - `users` → campo `building_id` (vínculo residente ↔ copropiedad).
- **Prohibido** consultar tablas globales y filtrar en el cliente cuando eso exponga
  datos de otras copropiedades. Validar la pertenencia del usuario al `building_id` antes de
  leer o escribir.
- El aislamiento se refuerza en el repositorio (`DatabaseService`) y en las consultas
  de los ViewModels. Al tocar el backend, **nunca** mezclar información de distintos
  `building_name`/edificios en una misma respuesta.

### 3.2 Confidencialidad de estados de cuenta por unidad

- `lib/models/statement_model.dart` está **vacío (pendiente de implementar)**.
- Al implementarlo: cada estado de cuenta pertenece a **una unidad** (`apartment`/`unit`)
  dentro de **un edificio**. Solo el propietario/residente de esa unidad puede verlo.
- **Nunca** exponer saldos, deudas, pagos o movimientos de otra unidad a un residente.
- La gerencia/delegado puede ver **consolidados**, pero no debe filtrar el detalle financiero
  individual de una unidad a otros residentes.
- No registrar información financiera en logs ni cachearla en texto plano.

### 3.3 Tolerancia a fallos y reintentos ante 503

- Backend (`main.py`): `max_retries = 3`, backoff `time.sleep(1.5 * attempt)` (1.5 s, 3 s) y
  captura explícita de `errors.ServerError` (saturación / HTTP 503) devolviendo un mensaje
  amigable al usuario.
- Cliente (`gemini_service.dart`): `.timeout(Duration(seconds: 20))` y manejo de error de red
  con mensaje controlado (mismo Wi-Fi / backend encendido).
- **Mantener este patrón** al agregar nuevas llamadas a IA o servicios externos.
- No convertir un fallo transitorio en una excepción no controlada que rompa la UI.

### 3.4 Configuración dinámica de la IP del backend

- Hoy está **hardcodeada** en `lib/services/gemini_service.dart`:
  ```dart
  static const String _serverIp = '192.168.1.13';
  static const String _endpoint = 'http://$_serverIp:8000/api/resident-chat';
  ```
- Debe evolucionar a **configuración dinámica** sin recompilar ni editar código por red:
  - `--dart-define=API_BASE_URL=...` en tiempo de build, **o**
  - pantalla de ajustes que persista la IP/host, **o**
  - descubrimiento en la LAN.
- **No** hardcodear credenciales ni API keys en el cliente.

### 3.5 Seguridad — deuda técnica detectada

- `GEMINI_API_KEY` está **hardcodeada** en `backend_delegado/main.py` → mover a variable de
  entorno (`os.environ`) y rotar la clave expuesta.
- Las contraseñas locales usan SHA-256 con sal. Para producción, migrar a un KDF lento
  (Argon2, bcrypt o PBKDF2).
- `lib/services/ai_service.dart` está **vacío** (código muerto a limpiar o completar).

---

## 4. Estructura de carpetas actual

### 4.1 Frontend — `proyecto_delegado/`

```
proyecto_delegado/
├── android/
├── ios/
├── linux/
├── macos/
├── web/
├── windows/
├── test/
├── lib/
│   ├── data/
│   │   └── app_database.dart         # Esquema y conexión SQLite
│   ├── models/
│   │   ├── apartment_model.dart      # Apartamento + ocupantes
│   │   ├── building_model.dart       # Ficha técnica de la copropiedad
│   │   ├── statement_model.dart      # (VACÍO - pendiente: estados de cuenta)
│   │   ├── task_model.dart           # Tareas y solicitudes (buildingId)
│   │   └── user_model.dart           # Roles: gerente/delegado/residente
│   ├── screens/
│   │   ├── auth/
│   │   │   └── login_screen.dart
│   │   ├── delegate/
│   │   │   ├── apartment_detail_screen.dart
│   │   │   ├── building_detail_screen.dart
│   │   │   ├── building_tasks_screen.dart
│   │   │   ├── create_building_screen.dart
│   │   │   ├── delegate_home_screen.dart
│   │   │   └── edit_building_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── manager/                  # (VACÍO - panel de gerencia pendiente)
│   │   └── resident/
│   │       ├── resident_ai_chat_screen.dart
│   │       ├── resident_building_tasks_screen.dart
│   │       └── resident_home_screen.dart
│   ├── services/
│   │   ├── ai_service.dart           # (VACÍO)
│   │   ├── auth_service.dart         # Auth local, hash y sesión
│   │   ├── database_service.dart     # Repositorio SQLite y streams
│   │   ├── gemini_service.dart       # Cliente HTTP hacia el backend
│   │   └── notification_service.dart
│   ├── viewmodels/
│   │   ├── auth_viewmodel.dart
│   │   ├── building_detail_viewmodel.dart
│   │   ├── building_form_viewmodel.dart
│   │   ├── buildings_viewmodel.dart
│   │   └── tasks_viewmodel.dart
│   └── main.dart
├── analysis_options.yaml
├── DOCUMENTO_TECNICO.md
├── pubspec.yaml
├── pubspec.lock
├── README.md
└── test_harness.bat                  # Harness de validación (ver §7)
```

### 4.2 Backend — `backend_delegado/`

```
backend_delegado/
├── __pycache__/
└── main.py                           # FastAPI + Google GenAI (gemini-3.6-flash)
```

---

## 5. Convenciones de trabajo

- Idioma de UI, comentarios y documentación: **español**.
- No romper el aislamiento multi-tenant ni la confidencialidad financiera (§3.1 y §3.2).
- Antes de dar una tarea por terminada, ejecutar el harness de validación
  `test_harness.bat` (está en la raíz de `proyecto_delegado/` y detecta solo las carpetas
  de ambos proyectos):

  ```bat
  REM Modo normal: los lints "info" no son fatales (recomendado en desarrollo)
  test_harness.bat
  ```

  ```bat
  REM Modo estricto: cualquier aviso (incluidos los "info") hace fallar la validación
  set HARNESS_STRICT=1
  test_harness.bat
  ```

  - Código `0` = sintaxis Python correcta + `flutter analyze` sin errores/warnings.
  - Código `1` = error de sintaxis en `main.py` o problemas en `flutter analyze`.
  - Código `2` = falta Python, Flutter o alguna carpeta del proyecto.

  > Estado (2026-10-08): `flutter analyze` reporta **No issues found!**, por lo que el
  > harness pasa limpio también con `HARNESS_STRICT=1`.

---

## 6. Estado actual y pendientes

- [x] Persistencia local con SQLite (`users`, `buildings`, `apartments`, `tasks`).
- [x] Autenticación local con hash SHA-256 + sal y sesión en `shared_preferences`.
- [x] Migración de la UI principal a ViewModels con `provider`/`ChangeNotifier`.
- [x] CRUD de edificios, apartamentos y tareas con confirmaciones y feedback.
- [x] Actualización reactiva de listas y detalle sin reiniciar la app.
- [x] Favoritos, compartir y borrado en cascada de edificios.
- [ ] Implementar `statement_model.dart` (estados de cuenta por unidad, confidenciales).
- [ ] Implementar o eliminar `ai_service.dart` (archivo vacío).
- [ ] Implementar el panel de gerencia (`lib/screens/manager/` vacío).
- [ ] Externalizar `GEMINI_API_KEY` a variable de entorno.
- [ ] Hacer configurable la IP/URL del backend (quitar `192.168.1.13` hardcodeada).
- [x] Declarar `http` en `pubspec.yaml` (`^1.6.0`).
- [ ] Migrar el hash de contraseñas a un KDF lento para producción.
