# Reglas Permanentes del Proyecto

Este archivo define los principios innegociables que el asistente debe aplicar **EN TODO MOMENTO** al trabajar en este proyecto.

---

## 0. Alineación con el Hito 1 (INGT1003 - Arquitectura de Desarrollo)
- **Objetivo central del Hito 1**: Integrar tecnologías Front-End (RDA 1) para una propuesta sólida, vendible y navegable.
- **Entregables obligatorios de H1**:
  1. **Prototipo navegable (Front-End)**: Mínimo 3 pantallas encadenadas interactivas con datos verosímiles de dominio real (no pantallas sueltas ni imágenes estáticas).
  2. **Estructura del repositorio**: Carpeta `docs/` (documento de propuesta, láminas, mapa del producto, diagrama de arquitectura), carpeta `db/`, y `README.md` en la raíz con la propuesta en una frase.
  3. **Pitch de 5 minutos**: La propuesta de valor debe entenderse en los primeros 90 segundos (A quién le duele, qué problema resuelve y qué promete).
  4. **Arquitectura de información**: Mapa del producto visible con secciones, jerarquía y rutas claras.

---

## 1. Experto en Dart, Flutter y Desarrollo Móvil / Front-End
- Aplica siempre las mejores prácticas del ecosistema Dart y Flutter: tipado fuerte, null-safety riguroso, uso de `const` y widgets eficientes.
- En integraciones de **APIs (REST/WebSockets)**: maneja excepciones explícitamente (`SocketException`, timeouts), centraliza clientes de red y deserializa con validación.
- En **Bluetooth / BLE**: gestiona siempre el ciclo de vida del adaptador, solicitud previa de permisos nativos (Android/iOS), timeouts en escaneos, reconexión elegante y limpieza de streams en `dispose()`.

---

## 2. Experiencia Visual y Estética (Simple, Bonita y Funcional)
- Toda pantalla o componente creado o modificado debe verse moderno, atractivo y con alta calidad visual.
- **Paleta de Colores**: Prohibido usar colores planos genéricos estridentes (rojos/azules puros por defecto). Utiliza esquemas armónicos con jerarquía clara (Primario de marca, Secundario de soporte, Neutros refinados para fondos/tarjetas, y Semánticos suaves para éxito/alerta/error).
- **Usabilidad**: La estética nunca debe sacrificar la claridad. La interfaz debe ser intuitiva, con espacios equilibrados (padding consistente), micro-feedback interactivo (estados de hover, press, loading) y tipografía legible.

---

## 3. Estructura de Carpetas y Arquitectura Limpia
- **Separación estricta de responsabilidades**:
  - `presentation/` (o `ui/`): Solo widgets, pantallas y controladores de vista. Prohibido código de base de datos directa, llamadas HTTP crudas o sockets dentro de widgets.
  - `domain/`: Entidades de negocio y contratos/interfaces puras.
  - `data/`: Modelos DTOs, serialización, implementación de repositorios, bases de datos locales (SQLite/Hive/Prefs) y clientes externos (APIs, Bluetooth).
- Cada clase o widget debe residir en su propio archivo con nombres descriptivos y estructurados. Simple, directo y fácil de mantener.
