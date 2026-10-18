# Búsqueda conectada con RE-api

La pantalla Búsqueda consulta datos reales mediante el mismo ApiClient/Dio y el token del usuario. No mantiene los selectores vacíos del prototipo.

## Uso

1. Escribir un DTC como P0300 o un prefijo como P03 y pulsar la lupa. Elegir una coincidencia; cuando solo hay una queda seleccionada automáticamente.
2. Opcionalmente elegir marca, modelo y año. Si se elige un modelo, el año es obligatorio para filtrar compatibilidad con claridad.
3. Administración y mecánica también pueden identificar un VIN ya registrado en el taller para completar modelo y año. Auditoría utiliza la selección manual del catálogo.
4. Pulsar Buscar repuestos. Se muestran componente, marca, referencia, perfil, precio de referencia con margen, durabilidad estimada y riesgo del catálogo.
5. Usar Cargar más cuando exista otra página. Cambiar el DTC o el vehículo limpia los resultados anteriores y descarta respuestas pendientes.

Sin modelo y año se muestra catálogo general asociado al DTC y se indica que la compatibilidad aún no está filtrada. El VIN no se decodifica mediante servicios externos ni crea vehículos nuevos. No se guarda una cotización en este flujo.

Los errores de códigos, marcas/modelos, VIN y repuestos tienen mensajes propios. Una falla al cargar una página adicional conserva los resultados previos y permite reintentar. El controlador vive únicamente durante la ruta; se descartan respuestas tardías al salir.

## Separación de responsabilidades

- domain: entidades tipadas y contrato SearchRepository, sin Flutter/Dio.
- data/models/CatalogDto: validación de JSON, UUID, enums y precios.
- data/repositories/ApiSearchRepository: consumo de rutas protegidas mediante el cliente compartido.
- presentation/controllers/CatalogSearchController: selección, carga, errores y coordinación de consultas.
- presentation/views y widgets: formulario, filtros y tarjetas; sin HTTP ni SQL.
- main.dart y app_router.dart: inyección y ciclo de vida por ruta.

Los importes se reciben como texto decimal y se convierten a BigInt para evitar pérdida de precisión en web, incluso por encima del límite de enteros exactos de JavaScript. El formato mostrado agrega separadores de miles sin convertir a double.

## Pruebas

flutter test cubre DTO, importes exactos, cambios de filtro con respuestas tardías, VIN cancelado, permisos del controlador, carga de páginas, reintentos y pantalla estrecha.
Con TEST_API_URL y TEST_DEMO_PASSWORD en el entorno, search_api_integration_test.dart verifica Dio contra RE-api/PostgreSQL y los dos talleres del seed. No guardar contraseñas en argumentos o archivos versionados.

La captura real del diagnóstico y la comunicación Bluetooth/OBD siguen siendo el siguiente módulo pendiente.
