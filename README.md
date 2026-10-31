# PMFinances

**PMFinances** es una aplicación moderna y nativa para iOS de finanzas personales y control de gastos, desarrollada en SwiftUI puro con arquitectura MVVM. Diseñada con una estética oscura y limpia, acentos en color verde/púrpura y una arquitectura centrada en la privacidad, ofrece una visión integral y en tiempo real de tu salud financiera sin depender de servidores de terceros ni requerir cuentas de usuario.

---

## Características Principales

### 1. Tres Pantallas Principales (Selector en Barra Superior)
- **Registros**:
  - Listado cronológico de movimientos con tarjetas elegantes y contrastadas.
  - Acciones gestuales de deslizar (*swipe actions*) para editar o eliminar transacciones al instante.
  - Desglose superior de categorías con selección interactiva.
  - Botón flotante para registrar nuevos movimientos rápidamente.
- **Estadísticas**:
  - **Tarjetas KPI**: Balance Neto, Total Ingresos, Total Gastos, Desglose de Gastos Recurrentes vs Únicos y Tasa de Ahorro.
  - **Gráfico de Evolución Mensual**: Barras de ingresos y gastos mes a mes con Swift Charts.
  - **Gráfico de Tarta de Categorías**: Distribución sectorial del gasto por categorías con leyenda clara e integrada.
- **Comparativa entre Dos Intervalos**:
  - Selecciona dos intervalos de tiempo independientes (ej. *Este mes vs Mes pasado*, *Últimos 3 meses vs 6 meses*, *Año actual vs Histórico*, o fechas personalizadas *Desde/Hasta*).
  - **Filtros comunes compartidos**: Los filtros de categorías (multiselección), tipo de transacción, rango de importe y búsqueda por texto se aplican simultáneamente a ambos periodos.
  - **Tarjetas KPI Comparativas**: Muestra los valores de ambos intervalos y la variación (+/- € y +/- %) en Balance Neto, Ingresos, Gastos, Tasa de Ahorro y Número de Movimientos.
  - **Gráfico Comparativo Lado a Lado**: Visualización gráfica de ingresos, gastos y balance de cada intervalo frente a frente.
  - **Desglose Detallado por Categoría**: Comparación directa del gasto categoría por categoría con barras proporcionales dobles e indicadores de diferencia.

---

### 2. Integración con Atajos de Apple y Siri (App Intents)

PMFinances incluye compatibilidad nativa con **Apple Shortcuts** a través del framework moderno **App Intents**, permitiendo registrar gastos en `finanzas.json` en segundo plano sin necesidad de abrir la aplicación.

#### Acciones disponibles en la App Atajos:
1. **Añadir Registro Financiero (`AddFinancialRecordIntent`)**:
   - **Parámetros**:
     - **Concepto / Descripción**: Nombre del movimiento (ej. *"Supermercado"*, *"Cena con amigos"*, *"Amazon"*).
     - **Importe (€)**: Cantidad numérica.
     - **Categoría**: Menú desplegable alimentado **en tiempo real** con tus categorías de `categorias.json`.
     - **Tipo**: *Gasto Único*, *Gasto Recurrente* o *Ingreso* (por defecto *Gasto Único*).
     - **Fecha**: Fecha y hora del movimiento (por defecto la actual).
   - Escribe directamente en el archivo JSON activo (local o iCloud Drive) y devuelve un resumen de confirmación.
2. **Obtener Categorías de PMFinances (`GetCategoriesIntent`)**:
   - Devuelve la lista actual de categorías configuradas en la app para usarlas en flujos de trabajo personalizados.

#### Formas de Uso:
- **Comandos de Voz con Siri**:
  - *"Oye Siri, añade un gasto en PMFinances"*
  - *"Oye Siri, nuevo registro en PMFinances"*
- **Automatizaciones de iOS (ej. con Apple Pay)**:
  1. En la app **Atajos**, ve a la pestaña **Automatización**.
  2. Pulsa en **+** y selecciona **Transacción** (Apple Pay).
  3. Elige tus tarjetas bancarias y marca *Ejecutar inmediatamente*.
  4. Añade la acción *Añadir Registro Financiero* de PMFinances vinculando el comercio y el importe de la transacción. ¡Tus compras se guardarán solas al pagar con el iPhone o Apple Watch!
- **Botón de Acción y Pantalla de Inicio**:
  - Asigna el atajo al Botón de Acción en *Ajustes > Botón de acción > Atajo* (iPhone 15 Pro, 16, etc.).
  - Añade un widget de Atajos a tu pantalla de inicio o pantalla de bloqueo para registrar gastos con un solo toque.

---

### 3. Ajustes Reorganizados en Submenús
El menú de configuración se organiza en apartados temáticos estructurados:
1. **Idioma**: Selección dinámica entre **Español** e **Inglés**, con aplicación inmediata sin reiniciar.
2. **Categorías**:
   - Creación, edición de nombre y borrado de categorías.
   - Selector de colores personalizado (paleta predefinida o rueda cromática del sistema).
   - Almacenamiento independiente en `categorias.json` y sincronización en cascada.
3. **Atajos de Siri**:
   - Guía interactiva de uso, visualización de categorías dinámicas activas y acceso directo para abrir la app Atajos de Apple.
4. **Almacenamiento de Datos**:
   - Selección de carpeta personalizada mediante el selector nativo de archivos.
   - Detección automática y soporte completo para **iCloud Drive** (sincronización multi-dispositivo vía *Security-Scoped Bookmarks*).
   - Recarga de datos y carga de datos de demostración con un toque.

---

### 4. Filtros Avanzados y Búsqueda
- **Rango Temporal**: *Este mes, Mes pasado, Últimos 3 meses, Últimos 6 meses, Últimos 12 meses, Año actual, Todo el histórico* o *Personalizado* con calendario *Desde / Hasta*.
- **Multiselección de Categorías**: Filtra por una o múltiples categorías a la vez.
- **Tipo de Movimiento**: *Todos, Gastos únicos, Gastos recurrentes, Ingresos*.
- **Rango de Importe**: Menor a 50 €, 50 € - 200 €, 200 € - 500 €, Más de 500 €, o valores exactos.
- **Buscador de Texto en Tiempo Real**: Filtrado instantáneo por nombre o categoría.

---

## Estructura de Datos (JSON)

La app no requiere bases de datos propietarias. Toda la información reside en archivos JSON legibles por humanos:

- **`finanzas.json`**:
```json
[
  {
    "id": "1E2D3C4B-5A6F-7890-ABCD-EF1234567890",
    "name": "Compra supermercado",
    "cantidad": 64.50,
    "categoria": "Alimentación",
    "fecha": "2026-10-31T10:30:00Z",
    "tipo": "Gasto único"
  }
]
```

- **`categorias.json`**:
```json
[
  {
    "name": "Alimentación",
    "hexColor": "#FF9500"
  },
  {
    "name": "Amazon",
    "hexColor": "#FFCC00"
  }
]
```

---

## Tecnologías y Arquitectura

- **Lenguaje y UI**: Swift 5.0+ / Swift 6, SwiftUI puro, Swift Charts, AppIntents.
- **Arquitectura**: MVVM con clara separación entre modelo (`FinancialRecord`), persistencia (`LocalStorageService`), estado y lógica de negocio (`FinancialViewModel`) y vistas modulares.
- **Compatibilidad**: iOS 17.0+ (Universal iPhone y iPad).
- **Diseño**: Modo oscuro nativo de alto contraste optimizado para pantallas OLED.
