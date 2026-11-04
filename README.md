# PMFinances

**PMFinances** es una aplicación moderna y nativa para iOS y macOS de finanzas personales y control de gastos, desarrollada en SwiftUI puro con arquitectura MVVM. Diseñada con una estética limpia, contrastada, soporte nativo de temas Claro/Oscuro/Sistema y una arquitectura centrada en la privacidad, ofrece una visión integral y en tiempo real de tu salud financiera sin depender de servidores de terceros ni requerir cuentas de usuario.

---

## Características Principales

### 1. Tres Pantallas Principales (Selector en Barra Superior)
- **Registros**:
  - Listado cronológico de movimientos con tarjetas elegantes y contrastadas.
  - **Deslizar para borrar optimizado**: El gesto de borrado rápido se activa únicamente al deslizar desde el lado derecho de la fila (zona del importe), garantizando un desplazamiento vertical (*scroll*) suave y fluido a 60/120 fps sin interferencias en el resto de la fila.
  - Menú contextual al mantener pulsado para editar o eliminar.
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

### 2. Atajo Completo Autónomo y Siri (Apple Shortcuts & App Intents)

PMFinances incluye un **atajo nativo 100% completo y listo para usar** mediante el framework moderno **App Intents**. No es necesario diseñar flujos ni conectar bloques manualmente en la app Atajos; el atajo ya viene creado y preconfigurado en el sistema operativo.

#### Idioma Dinámico del Dispositivo
El atajo detecta automáticamente el idioma de tu iPhone:
- **En iPhones en Español**: El atajo se llama **"Nuevo Registro"** y las frases por voz, diálogos de pregunta y confirmación se ejecutan íntegramente en español.
- **En iPhones en Inglés u otros idiomas**: El atajo se registra como **"New Record"** y toda la interacción por voz/pantalla se realiza en inglés.

#### ¿Qué tiene que hacer el usuario al descargarse la app para usarlo?
**Absolutamente nada técnico ni manual.** Al instalar PMFinances, iOS registra automáticamente el atajo en el sistema. Cualquier usuario puede utilizarlo al instante de 3 formas:
1. **Con la voz mediante Siri (sin tocar nada)**:
   - En español: *“Oye Siri, nuevo registro en PMFinances”* (o *“Oye Siri, añade un gasto en PMFinances”*).
   - En inglés: *“Hey Siri, new record in PMFinances”* (o *“Hey Siri, add financial record in PMFinances”*).
   - Siri preguntará interactivamente por voz o tarjeta en pantalla los datos requeridos y guardará el registro.
2. **Desde la App Atajos de Apple**:
   - Abrir la app nativa **Atajos**; en la sección de PMFinances aparecerá el atajo listo para pulsar.
3. **Desde los Ajustes de la App**:
   - En *Ajustes > Atajos de Siri*, pulsar directamente en **"Ejecutar Atajo"**.

#### Flujo Interactivo Completo (5 Datos Requeridos):
Al ejecutarse, el atajo solicita de forma guiada y autónoma:
1. **Importe / Cantidad (€)**: Solicita el valor numérico (ej. *45,50 €*).
2. **Concepto o Comercio**: Pregunta el nombre o descripción del gasto/ingreso (ej. *Mercadona, Amazon, Nómina*).
3. **Categoría Dinámica**: Muestra un selector interactivo alimentado **en tiempo real** con las categorías de `categories.json`.
4. **Tipo de Movimiento**: Selector interactivo entre *Gasto Único*, *Gasto Recurrente* o *Ingreso*.
5. **Fecha del Momento de Creación**: Asigna automáticamente la fecha y hora exacta en la que se ejecuta el atajo.

Al finalizar, escribe la transacción directamente en el archivo `finanzas.json` (almacenamiento local o iCloud Drive) y emite un diálogo de confirmación con el resumen.

#### Configuraciones Opcionales para Máxima Comodidad:
- **Botón de Acción (iPhone 15 Pro, iPhone 16)**:
  - En *Ajustes de iOS > Botón de Acción > Atajo > Nuevo Registro / New Record*. Permite registrar un gasto en 2 segundos manteniendo pulsado el botón lateral.
- **Widgets de Pantalla de Bloqueo o Inicio**:
  - Añade un widget de la app Atajos apuntando al atajo para tener un acceso directo permanente.
- **Automatización Inmediata con Apple Pay**:
  1. En la app **Atajos**, ve a la pestaña **Automatización**.
  2. Pulsa en **+** y selecciona **Transacción** (Apple Pay).
  3. Elige tus tarjetas bancarias y marca *Ejecutar inmediatamente*.
  4. Vincula la acción *Añadir Registro Financiero* usando el importe y comercio de la transacción detectada.

---

### 3. Ajustes Reorganizados en Submenús
El menú de configuración se organiza en apartados temáticos estructurados:
1. **Idioma**: Selección dinámica entre **Español** e **Inglés**, con aplicación inmediata sin reiniciar.
2. **Aspecto**: Selector entre modo **Claro**, **Oscuro** o **Sincronizar con el sistema** con propagación reactiva en tiempo real.
3. **Categorías**:
   - Creación, edición de nombre y borrado de categorías con paleta de colores personalizable.
   - **Auto-sincronización no destructiva**: Si un registro contiene una categoría nueva, se incorpora automáticamente a `categories.json` sin alterar el movimiento original.
   - **Protección contra borrado**: Si una categoría tiene transacciones registradas, la app impide su borrado accidental hasta que se reasignen o eliminen dichos movimientos.
4. **Atajos de Siri**:
   - Guía interactiva de uso, visualización de categorías dinámicas activas y acceso directo para abrir o ejecutar el atajo nativo.
5. **Almacenamiento de Datos**:
   - Selección de carpeta personalizada mediante el selector nativo de archivos.
   - Detección automática y soporte completo para **iCloud Drive** (sincronización multi-dispositivo vía *Security-Scoped Bookmarks*).
   - Recarga de datos y carga de datos de demostración con un toque.
6. **Control de Versión**:
   - Muestra en la parte inferior de los ajustes la versión activa y el número de compilación (ej. `PMFinances Versión 1.0 (1)`) para seguimiento e informe de errores.

---

### 4. Filtros Avanzados y Búsqueda
- **Rango Temporal**: *Este mes, Mes pasado, Últimos 3 meses, Últimos 6 meses, Últimos 12 meses, Año actual, Todo el histórico* o *Personalizado* con calendario *Desde / Hasta*.
- **Multiselección de Categorías**: Filtra por una o múltiples categorías a la vez.
- **Tipo de Movimiento**: *Todos, Gastos únicos, Gastos recurrentes, Ingresos*.
- **Rango de Importe**: Menor a 50 €, 50 € - 200 €, 200 € - 500 €, Más de 500 €, o valores exactos.
- **Buscador de Texto en Tiempo Real**: Filtrado instantáneo por nombre o categoría.

---

## Rendimiento y Optimización
PMFinances 1.0 incorpora una arquitectura optimizada para un consumo mínimo de batería y una tasa de refresco fluida de 60/120 Hz:
- **Caché de formateadores con exclusión mutua**: Reutilización segura (`NSLock`) de formateadores de moneda y fecha, evitando instanciaciones redundantes por celda durante el scroll.
- **Memoización reactiva en ViewModel**: El filtrado y cálculo estadístico se computa de forma memoizada e incremental, invalidándose únicamente ante mutaciones de datos o filtros.
- **Decodificación JSON bajo demanda**: Inspección de metadatos de almacenamiento sin deserialización síncrona repetitiva de disco.

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

- **`categories.json`** *(con migración transparente desde el antiguo `categorias.json`)*:
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
- **Compatibilidad**: iOS 17.0+ y macOS 14.0+ (Universal).
- **Diseño**: Compatibilidad total con modo claro y oscuro, con paletas semánticas y contrastes optimizados para pantallas OLED.
