# Repuestos Exactos

> **Integración actual:** login con RE-api, sesión Bearer, datos reales del taller en Inicio y Ajustes e historial de diagnósticos con filtros y paginación, además de búsqueda real de catálogo y compatibilidad. Guía: [Conexión con la API](docs/conexion_api.md). La captura de diagnósticos conserva su alcance de prototipo. Guía de búsqueda: [Búsqueda conectada](docs/busqueda.md).

> **"Para mecánicos de talleres automotrices que sufren de falta de información al cotizar repuestos, Repuestos Exactos interpreta el diagnóstico OBD2 y entrega una matriz comparativa instantánea basada en coste, durabilidad y riesgos, optimizando el tiempo y la decisión de compra."**

---

## 🏛️ Contexto Académico
- **Institución**: Universidad Mayor
- **Asignatura**: Arquitectura de Desarrollo Web y Móvil
- **Profesor**: Carlos Muñoz
- **Fecha**: Agosto / Septiembre 2026

## 👥 Equipo de Desarrollo
* **Javier Chandía**
* **Adrián Perugini**
* **Matías Daza**
* **Victoria Escobar**

---

## 📋 Descripción del Proyecto
Repuestos Exactos es una solución de software móvil orientada al sector automotriz, diseñada para optimizar el flujo de trabajo en talleres mecánicos. La plataforma integra diagnóstico automotriz en tiempo real mediante escáneres OBD-II y un motor de cotización multifuente. Su objetivo principal es resolver la asimetría de información en la adquisición de repuestos, traduciendo códigos de falla técnicos (DTC) en un análisis comercial estructurado y eficiente para la toma de decisiones informada.

### Público Objetivo
Mecánicos profesionales y administradores de talleres automotrices que utilizan herramientas de diagnóstico OBD-II y requieren optimizar tiempos y recursos financieros en la adquisición de componentes vehiculares.

---

## ⚙️ Características Principales

* **Integración Diagnóstica (OBD-II):** Módulo de comunicación vía Bluetooth con dispositivos de escaneo automotriz para la extracción e interpretación de códigos de falla (DTC).
* **Identificación Vehicular Automatizada:** Lectura del número de identificación vehicular (VIN) a través del protocolo OBD-II, con respaldo de ingreso manual (Marca, Modelo, Año, Motor).
* **Motor de Cotización Multifuente:** Integración mediante API RESTful con plataformas de comercio electrónico consolidadas e índices locales de precios en moneda local (CLP).
* **Matriz Comparativa de Componentes (3 Perfiles):**
    * 🔴 **Perfil Económico (Genérico):** Menor costo inicial, advirtiendo sobre posibles limitaciones de vida útil y mayor riesgo de falla prematura.
    * 🟡 **Perfil Práctico (OEM):** Relación precio-calidad óptima basada en rendimiento comprobado en el sector.
    * 🟢 **Perfil Óptimo (Genuino):** Componentes originales de fabricante para garantizar máxima durabilidad y garantía.
* **Interfaz de Usuario (UI/UX) Moderna:** Diseño de interfaz móvil con soporte de Modo Oscuro / Modo Claro, animaciones interactivas y visualización de datos comprensibles.

---

## 🏗️ Arquitectura del Sistema
El desarrollo de la plataforma se estructura utilizando principios de Clean Architecture y el modelo C4 (Niveles 1 y 2):
* **Frontend:** Aplicación móvil en Flutter con separación por capas (`core`, `features`, `data`, `presentation`).
* **Backend:** Arquitectura orientada a servicios basada en API RESTful (planificada para Hito 2).
* **Base de Datos:** Modelo relacional optimizado en carpeta `/db`.

---

## 📌 Entregables del Hito 1 (Front-End y Arquitectura)
- **Prototipo Navegable**: Implementado en Flutter con 5 pantallas conectadas y simulación de flujo real.
- **Documentación Completa**: Localizada en [`/docs`](docs/guia_explicativa_h1.md) (Guía para no programadores y desglose técnico de pantallas).
- **Estructura de Arquitectura Limpia**:
  - `lib/core/`: Sistema de temas (`AppTheme`, `ThemeProvider`) y enrutador declarativo (`appRouter` con `go_router`).
  - `lib/features/`: Módulos independientes por funcionalidad (`home`, `diagnostic`, `search`, `history`, `settings`).
  - `lib/data/`: Modelos de datos y repositorios simulados para pruebas de dominio automotriz.
  - `db/`: Carpeta con esquemas para base de datos relacional.

### Pantallas del Prototipo
1. **Inicio (`/`)**: Dashboard con accesos rápidos, métricas de escaneo del día y botón directo al diagnóstico.
2. **Diagnóstico OBD2 en Vivo (`/diagnostic`)**: Radar de búsqueda Bluetooth interactivo y despliegue de matriz comparativa (Genuino vs. OEM vs. Genérico).
3. **Búsqueda Manual (`/search`)**: Formulario por VIN o Marca/Modelo/Año con catálogo interactivo.
4. **Historial de Escaneos (`/history`)**: Registro de vehículos atendidos con filtros por estado.
5. **Configuración (`/settings`)**: Selector de Modo Claro / Modo Oscuro y preferencias de taller.

---

## 🚀 Guía Paso a Paso para Integrantes del Grupo (Cómo probar la app en 3 minutos)

Para cualquier integrante del equipo que clone este repositorio y quiera probarlo en su computadora:

### Paso 1: Prerrequisitos
- Tener instalado **Flutter** en el sistema ([flutter.dev](https://docs.flutter.dev/get-started/install)).
- Navegador web (Microsoft Edge, Google Chrome, etc.).

### Paso 2: Descargar dependencias
Abre una terminal en la carpeta del proyecto y ejecuta:
```bash
flutter pub get
```

### Paso 3: Iniciar el servidor local
```bash
flutter run -d web-server --web-port 8080 --web-hostname localhost
```

### Paso 4: Abrir en el navegador
Abre tu navegador y entra a:
👉 **`http://localhost:8080`**

### Paso 5: Vista de Celular Móvil 📲
1. Presiona **`F12`** en la ventana del navegador.
2. Presiona **`Ctrl` + `Shift` + `M`** (Modo Dispositivo).
3. Selecciona **iPhone 14 Pro Max** o **Pixel 7** en la parte superior y pon el zoom al **100%**.

## Referencias de Mercado Libre

En Búsqueda, selecciona una falla y el componente a revisar. «Buscar en Mercado Libre» consulta el proveedor; «Guardar alternativa» registra una referencia con nota. Se consultan desde Historial → Alternativas guardadas. Los resultados de catálogo técnico se identifican sin precio ni disponibilidad confirmada. El catálogo local conserva su funcionamiento.

[Contrato, configuración y límites del incremento](../Backend_Repuestos_Exactos/docs/integracion_mercadolibre.md).

## Captura OBD2 por Bluetooth clásico (incremento V015)

El módulo Diagnóstico reemplaza su simulación por Web Serial. Este primer transporte está dirigido a Windows + Chrome de escritorio (117 o posterior) + Vgate vLinker MC Bluetooth 3.0 SPP. Requiere localhost o HTTPS. Android/iOS nativos, BLE y Wi-Fi no están implementados en este incremento. Las descripciones del Hito 1 anteriores documentan el prototipo original; el resumen diario 3/12 todavía es de prototipo.

Recorrido de uso:

1. Conectar el adaptador al vehículo y emparejarlo en Windows siguiendo las instrucciones del fabricante. Cerrar otras aplicaciones que usen su puerto.
2. Ingresar como propietario o mecánico. En Diagnóstico elegir el vehículo; «Registrar vehículo» permite dar de alta modelo, año, patente y motor cuando el taller está vacío.
3. El propietario registra una vez el adaptador en el inventario del taller. Es un registro lógico: el navegador no expone su MAC y no se inventa una.
4. Elegir el adaptador, declarar kilometraje y pulsar Conectar. Chrome solicita elegir el puerto SPP real. Pulsar Leer fallas con el vehículo en las condiciones indicadas por el fabricante.
5. Revisar códigos almacenados, pendientes y permanentes, ECU y estado de cada servicio. Guardar diagnóstico conserva todas las observaciones, incluidas las no catalogadas; reintentar un guardado no duplica la sesión.
6. Historial → Ver diagnóstico → Buscar repuestos para un código catalogado. La búsqueda externa y las alternativas guardadas conservan la sesión y el vehículo de origen. Guardar una alternativa no compra, no crea una cotización ni cambia el estado de la sesión.

Separación: widgets/controladores → contratos de dominio → repositorio HTTP o motor ELM327 → transporte Web Serial. El motor admite sólo comandos de identificación/configuración y lectura; el comando 04 de borrado no está permitido. Los dobles de protocolo están únicamente en test/support; producción no devuelve fallas simuladas si falta hardware.

Validación: flutter analyze, flutter test y flutter build web --release. El test optativo test/obd_backend_flow_test.dart requiere RUN_OBD_HTTP_TESTS=true, TEST_API_URL, DEMO_PASSWORD y una DB_NAME con prefijo re_api_preflight_. Usar exclusivamente una copia desechable de PostgreSQL y una API QA apuntando a ella: esta prueba registra vehículos, sesiones y alternativas. La evidencia de este incremento usa respuestas seriales controladas y un proveedor externo controlado, con HTTP/PostgreSQL reales.

**Pendiente de aceptación física:** no se contó con el adaptador ni el vehículo durante la implementación. Emparejamiento, selector de puerto, firmware, protocolo del auto y lecturas reales deben comprobarse con el vLinker MC. Este alcance cubre OBD genérico, no garantiza diagnóstico ABS/airbag ni servicios propios de cada marca.

[Traza del incremento](../Backend_Repuestos_Exactos/docs/evidencia/traza_bluetooth_obd2.json) · [Evidencia y límites](../Backend_Repuestos_Exactos/docs/evidencia/bluetooth_validacion.json).

### VIN automático

Al leer las fallas se consulta también el VIN mediante modo 09 PID 02 (0902). Se reensamblan respuestas CAN de 11/29 bits y segmentos heredados por ECU; el valor debe contener 17 caracteres válidos y coincidir entre las ECU que lo entreguen. NO DATA, falta de soporte, respuesta inválida o timeout de VIN no descartan DTC ya leídos. La identificación se consulta al final y nunca borra fallas.

Ya no hace falta elegir vehículo ni kilometraje para conectar y leer. Si el VIN existe entre los vehículos visibles del taller, se selecciona automáticamente. Si no existe, se conserva la lectura y se permite seleccionar o registrar el vehículo después. El formulario recibe el VIN leído; marca, modelo, año, patente y motor requieren confirmación manual. No hay un servicio externo de decodificación de VIN ni se deduce automáticamente «Peugeot 3008 2017» de un VIN nuevo.

Al guardar, la API contrasta el VIN: completa el campo existente del vehículo únicamente si estaba vacío y rechaza un VIN distinto. La asociación y la creación de sesión/fallas son una misma transacción. Un conflicto permite corregir el vehículo conservando la lectura; un fallo de red mantiene la clave y los datos para reintentar sin duplicar. El detalle del historial muestra el VIN registrado, sujeto a las reglas existentes de acceso y anonimización.

V016 añade Peugeot / 3008 al catálogo para la prueba prevista con un auto de 2017. No crea el auto ni una identidad ficticia. La compatibilidad y lectura real de ese vehículo siguen pendientes de prueba con el adaptador.

Referencia de protocolo: [ELM327, respuestas multilínea y VIN](https://www.elmelectronics.com/wp-content/uploads/2016/07/ELM327DSH.pdf#page=42).
