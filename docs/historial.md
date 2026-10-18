# Historial conectado

La pantalla /history consume GET /sessions de RE-api con el ApiClient compartido y el token de la sesión actual. Ya no utiliza las filas simuladas de Toyota Hilux, Ford Ranger y Chevrolet Spark.

## Separación

- domain/entities: HistoryEntry, HistoryStatus y HistoryPage, sin dependencias de Flutter ni Dio.
- domain/repositories: contrato HistoryRepository.
- data/models: HistoryPageDto valida UUID, fechas UTC, enums, tipos, nulos y paginación.
- data/repositories: ApiHistoryRepository compone filtros y llama a ApiClient.
- presentation/controllers: HistoryController coordina carga, filtros, continuación y errores; ignora respuestas obsoletas.
- presentation/views y widgets: presentación, sin solicitudes HTTP.
- main.dart y app_router.dart: inyección del repositorio y ciclo de vida del controlador por ruta.

## Uso

1. Iniciar RE-api en el puerto 8081 y Flutter web en 8080, según conexion_api.md.
2. Iniciar sesión con una cuenta existente de RE-db.
3. Abrir Historial: se consultan hasta 20 registros por página.
4. Seleccionar un estado para reiniciar el listado con ese filtro.
5. Usar Cargar más, Actualizar o deslizar hacia abajo para volver a consultar.

La pantalla muestra la fecha en la zona horaria del dispositivo y usa “Vehículo no disponible” cuando la API conserva una sesión pero oculta su vehículo. No muestra códigos DTC inventados: el listado actual recibe un conteo de fallas.
Los errores de una página adicional conservan los resultados cargados y permiten reintentar. Los datos no se guardan en caché persistente; salir de la ruta destruye su controlador.

## Validación

flutter test cubre validación del contrato, filtros con respuestas tardías, paginación, reintentos, cierre del controlador y una pantalla estrecha.
La prueba opcional api_integration_test.dart usa TEST_API_URL y TEST_DEMO_PASSWORD del proceso para verificar Dio contra la API y dos talleres reales del seed; nunca guardar esa contraseña en archivos versionados.

## Pendiente

Crear diagnósticos reales y detalle de una sesión. La búsqueda de repuestos ya está conectada: [busqueda.md](busqueda.md). Conectar el listado no implementa la comunicación Bluetooth/OBD ni convierte la pantalla de diagnóstico en una captura real.
