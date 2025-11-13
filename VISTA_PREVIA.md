# 📱 Vista Previa de la Aplicación

## Pantalla Principal (Home Screen)

```
╔════════════════════════════════════════════╗
║  Mis Finanzas                         🔄   ║
╠════════════════════════════════════════════╣
║                                            ║
║  ┌────────────────────────────────────┐   ║
║  │   🟢 INGRESOS    🔴 EGRESOS        │   ║
║  │   ↑              ↓                 │   ║
║  │   $5,000.00      $2,500.50        │   ║
║  │                                    │   ║
║  │   ─────────────────────────────    │   ║
║  │                                    │   ║
║  │         Balance: $2,499.50        │   ║
║  └────────────────────────────────────┘   ║
║                                            ║
║  ┌────────────────────────────────────┐   ║
║  │ 🔴 Compra supermercado             │   ║
║  │    [Alimentación]  13/11/2025      │   ║
║  │                         $1,500.50  │   ║
║  └────────────────────────────────────┘   ║
║                                            ║
║  ┌────────────────────────────────────┐   ║
║  │ 🟢 Pago quincenal                  │   ║
║  │    [Salario]  13/11/2025           │   ║
║  │                         $5,000.00  │   ║
║  └────────────────────────────────────┘   ║
║                                            ║
║  ┌────────────────────────────────────┐   ║
║  │ 🔴 Recarga de transporte           │   ║
║  │    [Transporte]  12/11/2025        │   ║
║  │                           $500.00  │   ║
║  └────────────────────────────────────┘   ║
║                                            ║
║  ┌────────────────────────────────────┐   ║
║  │ 🔴 Netflix                         │   ║
║  │    [Entretenimiento]  10/11/2025   │   ║
║  │                           $199.00  │   ║
║  └────────────────────────────────────┘   ║
║                                            ║
║                                            ║
║                                  [➕ Nuevo]║
╚════════════════════════════════════════════╝
```

### Características de la Pantalla Principal:

1. **AppBar (Barra Superior):**

   - Título: "Mis Finanzas"
   - Botón de actualizar (🔄)
   - Color: Teal

2. **Tarjeta de Resumen:**

   - Ingresos totales (verde)
   - Egresos totales (rojo)
   - Balance (diferencia)
   - Fondo degradado teal
   - Sombras y elevación

3. **Lista de Movimientos:**

   - Tarjetas individuales
   - Icono según tipo (↑ ingreso, ↓ egreso)
   - Concepto destacado
   - Categoría en tag
   - Fecha
   - Monto con formato de moneda
   - Al tocar: Modal con detalles completos

4. **Botón Flotante:**
   - Texto: "Nuevo"
   - Icono: ➕
   - Color: Teal
   - Al presionar: Navega a formulario

---

## Pantalla Agregar Movimiento

```
╔════════════════════════════════════════════╗
║  ← Nuevo Movimiento                        ║
╠════════════════════════════════════════════╣
║                                            ║
║  ┌────────────────────────────────────┐   ║
║  │  Tipo de movimiento                │   ║
║  │                                    │   ║
║  │  ┌──────────┐    ┌──────────┐    │   ║
║  │  │ ↑        │    │ ↓        │    │   ║
║  │  │ Ingreso  │    │ Egreso   │    │   ║
║  │  └──────────┘    └──────────┘    │   ║
║  │     (verde)        (rojo)         │   ║
║  └────────────────────────────────────┘   ║
║                                            ║
║  ┌────────────────────────────────────┐   ║
║  │  📝 Concepto                       │   ║
║  │  ┌──────────────────────────────┐ │   ║
║  │  │ Compra en supermercado       │ │   ║
║  │  └──────────────────────────────┘ │   ║
║  └────────────────────────────────────┘   ║
║                                            ║
║  ┌────────────────────────────────────┐   ║
║  │  💵 Monto                          │   ║
║  │  ┌──────────────────────────────┐ │   ║
║  │  │ 1500.50                      │ │   ║
║  │  └──────────────────────────────┘ │   ║
║  └────────────────────────────────────┘   ║
║                                            ║
║  ┌────────────────────────────────────┐   ║
║  │  📂 Categoría                      │   ║
║  │  ┌──────────────────────────────┐ │   ║
║  │  │ Alimentación            ▼    │ │   ║
║  │  └──────────────────────────────┘ │   ║
║  └────────────────────────────────────┘   ║
║                                            ║
║  ┌────────────────────────────────────┐   ║
║  │  📅 Fecha                          │   ║
║  │  13/11/2025                        │   ║
║  └────────────────────────────────────┘   ║
║                                            ║
║  ┌────────────────────────────────────┐   ║
║  │  👥 Grupo (opcional)               │   ║
║  │  ┌──────────────────────────────┐ │   ║
║  │  │ Personal                     │ │   ║
║  │  └──────────────────────────────┘ │   ║
║  └────────────────────────────────────┘   ║
║                                            ║
║  ┌────────────────────────────────────┐   ║
║  │      💾 Guardar Movimiento         │   ║
║  └────────────────────────────────────┘   ║
║                                            ║
╚════════════════════════════════════════════╝
```

### Características del Formulario:

1. **Selector de Tipo:**

   - Botones grandes e intuitivos
   - Visual feedback al seleccionar
   - Cambia las categorías disponibles

2. **Campo Concepto:**

   - TextInput con placeholder
   - Validación requerida
   - Icono descriptivo

3. **Campo Monto:**

   - Teclado numérico
   - Formato decimal
   - Validación de número válido

4. **Dropdown Categoría:**

   - Lista desplegable
   - Categorías según el tipo
   - Validación requerida

5. **Selector de Fecha:**

   - DatePicker nativo
   - Muestra fecha formateada
   - Por defecto: hoy

6. **Campo Grupo:**

   - Opcional
   - Para organizar movimientos

7. **Botón Guardar:**
   - Valida todos los campos
   - Muestra loading durante el guardado
   - SnackBar de confirmación

---

## Modal de Detalles

```
╔════════════════════════════════════════════╗
║  Detalles del Movimiento              ✕   ║
║  ────────────────────────────────────      ║
║                                            ║
║  Concepto:      Compra en supermercado    ║
║                                            ║
║  Monto:         $1,500.50                 ║
║                                            ║
║  Tipo:          Egreso                    ║
║                                            ║
║  Categoría:     Alimentación              ║
║                                            ║
║  Fecha:         13/11/2025                ║
║                                            ║
║  Mes:           noviembre                 ║
║                                            ║
║  Grupo:         Personal                  ║
║                                            ║
╚════════════════════════════════════════════╝
```

---

## Estados de la Aplicación

### Estado de Carga

```
╔════════════════════════════════════════════╗
║  Mis Finanzas                              ║
╠════════════════════════════════════════════╣
║                                            ║
║                    ⚙️                      ║
║                                            ║
║       Conectando con Google Sheets...     ║
║                                            ║
╚════════════════════════════════════════════╝
```

### Estado Sin Datos

```
╔════════════════════════════════════════════╗
║  Mis Finanzas                              ║
╠════════════════════════════════════════════╣
║                                            ║
║                    💰                      ║
║                                            ║
║     No hay movimientos registrados        ║
║        Agrega tu primer movimiento        ║
║                                            ║
║                                  [➕ Nuevo]║
╚════════════════════════════════════════════╝
```

### Estado de Error

```
╔════════════════════════════════════════════╗
║  Mis Finanzas                              ║
╠════════════════════════════════════════════╣
║                                            ║
║                    ⚠️                      ║
║                   Error                    ║
║                                            ║
║  No se pudo conectar con Google Sheets.   ║
║     Verifica las credenciales.            ║
║                                            ║
║          [🔄 Reintentar]                  ║
║                                            ║
╚════════════════════════════════════════════╝
```

---

## Flujo de Usuario

### Flujo 1: Ver Movimientos

```
1. Abrir App
   ↓
2. Ver pantalla de carga
   ↓
3. Conexión a Google Sheets
   ↓
4. Mostrar lista de movimientos
   ↓
5. Ver resumen de finanzas
   ↓
6. (Opcional) Tocar un movimiento
   ↓
7. Ver detalles completos
```

### Flujo 2: Agregar Movimiento

```
1. En pantalla principal
   ↓
2. Presionar botón [➕ Nuevo]
   ↓
3. Seleccionar tipo (Ingreso/Egreso)
   ↓
4. Llenar formulario
   ↓
5. Presionar [💾 Guardar]
   ↓
6. Ver confirmación
   ↓
7. Volver a pantalla principal
   ↓
8. Ver nuevo movimiento en la lista
```

### Flujo 3: Actualizar Datos

```
1. En pantalla principal
   ↓
2. Presionar botón [🔄]
   ↓
3. Pull to refresh
   ↓
4. Recargar datos de Google Sheets
   ↓
5. Actualizar lista y resumen
```

---

## Paleta de Colores

```
┌─────────────────────────────────────────────┐
│ Principal                                   │
│ ████ Teal (#009688)                        │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ Ingresos                                    │
│ ████ Green (#4CAF50)                       │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ Egresos                                     │
│ ████ Red (#F44336)                         │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ Fondo                                       │
│ ░░░░ Grey 100 (#F5F5F5)                    │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ Cards                                       │
│ ████ White (#FFFFFF)                       │
└─────────────────────────────────────────────┘
```

---

## Iconografía

- 💰 Wallet: Finanzas/Sin datos
- ↑ Arrow Up: Ingresos
- ↓ Arrow Down: Egresos
- ➕ Plus: Agregar nuevo
- 🔄 Refresh: Actualizar
- 📝 Description: Concepto
- 💵 Money: Monto
- 📂 Category: Categoría
- 📅 Calendar: Fecha
- 👥 Group: Grupo
- 💾 Save: Guardar
- ✕ Close: Cerrar
- ⚠️ Error: Estado de error
- ⚙️ Settings: Cargando

---

## Responsive Breakpoints

```
📱 Móvil (< 600px)
  - Una columna
  - Stack vertical
  - Padding: 16px

📱 Tablet (600-900px)
  - Una columna amplia
  - Más espaciado
  - Padding: 24px

💻 Desktop (> 900px)
  - Centro de la pantalla
  - Max width: 600px
  - Padding: 32px
```
