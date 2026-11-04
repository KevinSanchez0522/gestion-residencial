# Gestión Residencial - Proyecto Delegado

Aplicación móvil para la administración de copropiedades (edificios y conjuntos
residenciales). Permite a **delegados** gestionar edificios, apartamentos,
tareas y recordatorios; a los **residentes** reportar novedades y consultar las
tareas de su edificio; y a la **gerencia** disponer de un panel de entrada.

La versión actual funciona **100 % en local**, sin Firebase ni conexión a
internet: usuarios, edificios, apartamentos y tareas se almacenan en SQLite
dentro del dispositivo.

## Tecnologías

| Área | Tecnología |
|---|---|
| Framework | Flutter 3.41.4 / Dart 3.11.1 (Material 3) |
| Persistencia | SQLite con `sqflite` |
| Sesión local | `shared_preferences` |
| Seguridad de contraseña | SHA-256 con sal (`crypto`) |
| Estado / MVVM | `provider` + `ChangeNotifier` |
| Notificaciones | `flutter_local_notifications` |
| Calendario | `table_calendar` |
| Fechas | `intl` |
| Compartir información | `share_plus` |

## Estructura del proyecto

```
lib/
├── data/
│   └── app_database.dart          # Conexión y esquema SQLite
├── models/                        # User, Building, Apartment, Task
├── services/
│   ├── auth_service.dart          # Registro, login, hash y sesión local
│   ├── database_service.dart      # Repositorio local y streams reactivos
│   └── notification_service.dart  # Recordatorios locales
├── viewmodels/                    # MVVM: Auth, Buildings, Detail, Form, Tasks
├── screens/
│   ├── auth/                      # Login y registro
│   ├── delegate/                  # Lista, detalle, formularios y tareas
│   └── resident/                  # Panel, tareas y asistente
└── main.dart                      # Arranque, AuthGate y rutas por rol
```

## Requisitos previos

- Flutter 3.41.4 o compatible (Dart 3.11.1).
- Android Studio con SDK de Android instalado, o VS Code con la extensión Flutter.
- Un emulador Android o dispositivo físico.

No se necesita cuenta de Firebase ni backend para las funciones principales.

## Instalación y ejecución

```bash
flutter pub get
flutter run
```

Para generar el APK de depuración:

```bash
flutter build apk --debug
```

El APK se genera en
`build/app/outputs/flutter-apk/app-debug.apk`.

## Base de datos local

- Archivo: `delegado_local.db` en el directorio de bases de datos de la app.
- Se crea automáticamente en el primer arranque.
- Tablas: `users`, `buildings`, `apartments`, `tasks`.
- Borrado en cascada: al eliminar un edificio se eliminan sus apartamentos y
  tareas.
- Persistencia: los datos y la sesión sobreviven al cierre de la aplicación.
- Para reiniciar la demo: borrar los datos de la app desde
  **Ajustes de Android → Aplicaciones → Gestión Residencial → Almacenamiento →
  Borrar datos**, o desinstalarla y volver a instalarla.

## Usuarios y flujo de prueba

Los usuarios se crean desde la pantalla de **Registro**. No hay usuarios
precargados.

| Rol | Descripción | Acceso principal |
|---|---|---|
| **Residente** | Propietario, residente o inquilino | Panel del edificio, tareas y reporte de novedades |
| **Delegado** | Administrador de copropiedades | Lista de edificios, CRUD de apartamentos y tareas |
| **Gerente** | Gerencia de operaciones | Panel de entrada |

### Orden recomendado para la demostración

1. **Registrar un delegado** con correo y contraseña de mínimo 6 caracteres.
2. En la lista de edificios, pulsar **Nuevo Edificio**, ingresar el código
   **`GERENCIA2026`**, y crear una copropiedad con nombre, NIT y dirección.
3. Abrir el edificio para ver su ficha, editar sus datos, marcar favoritos,
   compartir la información, agregar apartamentos y gestionar tareas.
4. **Cerrar sesión** y **registrar un residente**. El residente debe indicar el
   nombre o código del edificio creado y su apartamento. El sistema valida que
   el edificio exista antes de permitir el registro.
5. Iniciar sesión como residente, abrir **Solicitudes / Tareas** y reportar una
   novedad. La solicitud aparecerá en la vista del delegado.
6. Volver a iniciar sesión como delegado para ver el edificio, la solicitud y
   el estado de las tareas. La lista y el detalle se actualizan sin reiniciar
   la aplicación.

## Funcionalidades

- **Registro e inicio de sesión local** con roles y sesión persistente.
- **Contraseñas protegidas** con sal aleatoria y hash SHA-256.
- **CRUD completo de edificios**: crear, listar, consultar, editar y eliminar.
- **Edificio → Apartamentos**: crear, renombrar, consultar, agregar ocupantes
  y eliminar.
- **Tareas y solicitudes**: crear, listar por edificio, cambiar estado,
  eliminar y programar recordatorios locales.
- **Actualización reactiva**: las listas y el detalle se refrescan tras cada
  escritura, sin reiniciar la app.
- **Acciones contextuales**: favoritos, compartir, editar y eliminar desde la
  lista y el detalle.
- **Validaciones y feedback**: correo válido, contraseña mínima, confirmación
  de contraseña, campos obligatorios, cantidades no negativas, confirmaciones
  de borrado y mensajes de éxito/error.
- **Navegación con back stack** mediante `Navigator.push` y retorno con
  resultados.
- **Accesibilidad básica**: etiquetas de campos, tooltips en iconos, botones de
  al menos 48 dp y textos con contraste sobre fondos claros.

## Validaciones principales

- Correo con formato válido y no repetido.
- Contraseña de mínimo 6 caracteres y confirmación coincidente.
- Nombre de usuario de mínimo 3 caracteres.
- Edificio y apartamento obligatorios para el rol residente.
- Edificio existente al registrar un residente.
- Nombre, NIT y dirección obligatorios al crear/editar un edificio.
- Cantidad de apartamentos y ascensores como enteros no negativos.
- Confirmación antes de eliminar edificios, apartamentos y tareas.

## Pruebas y análisis

```bash
flutter analyze --no-fatal-infos
flutter test
```

Estado verificado del proyecto:

- `flutter analyze --no-fatal-infos`: **No issues found!**
- `flutter test`: **All tests passed!**
- `flutter build apk --debug`: **APK generado correctamente.**

## Documentación técnica

El diseño detallado, el esquema de base de datos, la arquitectura MVVM, los
flujos y la matriz de cumplimiento están en
[`DOCUMENTO_TECNICO.md`](DOCUMENTO_TECNICO.md).

También se incluye una versión imprimible en PDF:
[`DOCUMENTO_TECNICO.pdf`](DOCUMENTO_TECNICO.pdf) (si el archivo está presente
en la entrega).

## Limitaciones y notas académicas

- La aplicación está desarrollada en **Flutter/Dart**, no en Java/Kotlin nativo
  de Android Studio. Usa SQLite mediante `sqflite`, que es el equivalente
  multiplataforma de `SQLiteOpenHelper`/Room. Si la asignatura exige
  estrictamente un proyecto nativo, esta implementación debe presentarse como
  una equivalencia tecnológica y no como un proyecto Java/Kotlin.
- La autenticación es local al dispositivo; no hay sincronización entre
  teléfonos ni recuperación de contraseña por correo.
- El asistente de IA requiere el backend FastAPI configurado y conexión de red;
  las funciones de gestión no dependen de él.
- No se incluye el video demostrativo dentro de este repositorio.

## Licencia

Proyecto de uso académico y demostrativo.
