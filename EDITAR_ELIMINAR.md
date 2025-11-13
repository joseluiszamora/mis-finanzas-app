# 📝 Guía de Edición y Eliminación de Movimientos

## ✨ Nuevas Funcionalidades

Se han agregado capacidades completas de **editar** y **eliminar** movimientos a la aplicación.

---

## 🎯 Formas de Editar un Movimiento

### 1️⃣ Deslizar hacia la derecha (Swipe Right) 👉

```
┌────────────────────────────────────┐
│ 🔵 [Editar]  ← Desliza aquí       │
│    ┌──────────────────────────┐   │
│    │ 🔴 Compra supermercado   │   │
│    │ [Alimentación] 13/11     │   │
│    │                $1,500.50 │   │
│    └──────────────────────────┘   │
└────────────────────────────────────┘
```

**Acción:** Desliza el movimiento de **izquierda a derecha**  
**Resultado:** Abre la pantalla de edición  
**Visual:** Fondo azul con ícono de editar

### 2️⃣ Mantener presionado (Long Press) 👆

```
┌────────────────────────────────────┐
│ ┌──────────────────────────────┐   │
│ │ 🔴 Compra supermercado       │   │
│ │ [Alimentación] 13/11         │   │ ← Mantén presionado aquí
│ │                    $1,500.50 │   │
│ └──────────────────────────────┘   │
└────────────────────────────────────┘
```

**Acción:** Mantén presionado el movimiento por 1-2 segundos  
**Resultado:** Abre la pantalla de edición  
**Visual:** Feedback táctil (vibración en algunos dispositivos)

---

## 🗑️ Formas de Eliminar un Movimiento

### 1️⃣ Deslizar hacia la izquierda (Swipe Left) 👈

```
┌────────────────────────────────────┐
│       Desliza aquí → [Eliminar] 🔴│
│   ┌──────────────────────────┐    │
│   │ 🔴 Compra supermercado   │    │
│   │ [Alimentación] 13/11     │    │
│   │                $1,500.50 │    │
│   └──────────────────────────┘    │
└────────────────────────────────────┘
```

**Acción:** Desliza el movimiento de **derecha a izquierda**  
**Resultado:** Muestra confirmación antes de eliminar  
**Visual:** Fondo rojo con ícono de eliminar

### 2️⃣ Desde la pantalla de edición 🗑️

```
╔════════════════════════════════════╗
║ ← Editar Movimiento            🗑️ ║ ← Botón eliminar
╠════════════════════════════════════╣
║ [Formulario de edición]            ║
║ ...                                ║
╚════════════════════════════════════╝
```

**Acción:** Abre el movimiento para editar y presiona el ícono de basura  
**Resultado:** Muestra confirmación antes de eliminar  
**Visual:** Ícono de basura en el AppBar

---

## 📱 Pantalla de Edición

### Características:

```
╔════════════════════════════════════╗
║ ← Editar Movimiento            🗑️ ║
╠════════════════════════════════════╣
║                                    ║
║ ┌────────────────────────────┐    ║
║ │ Tipo de movimiento         │    ║
║ │ [Ingreso] [Egreso]         │    ║
║ └────────────────────────────┘    ║
║                                    ║
║ ┌────────────────────────────┐    ║
║ │ 📝 Concepto                │    ║
║ │ Compra supermercado        │    ║
║ └────────────────────────────┘    ║
║                                    ║
║ ┌────────────────────────────┐    ║
║ │ 💵 Monto                   │    ║
║ │ 1500.50                    │    ║
║ └────────────────────────────┘    ║
║                                    ║
║ ┌────────────────────────────┐    ║
║ │ 📂 Categoría ▼             │    ║
║ │ Alimentación               │    ║
║ └────────────────────────────┘    ║
║                                    ║
║ ┌────────────────────────────┐    ║
║ │ 📅 Fecha                   │    ║
║ │ 13/11/2025                 │    ║
║ └────────────────────────────┘    ║
║                                    ║
║ ┌────────────────────────────┐    ║
║ │ 👥 Grupo                   │    ║
║ │ Personal                   │    ║
║ └────────────────────────────┘    ║
║                                    ║
║ ┌────────────────────────────┐    ║
║ │   💾 Guardar Cambios       │    ║
║ └────────────────────────────┘    ║
║                                    ║
╚════════════════════════════════════╝
```

**Todos los campos son editables:**

- ✏️ Tipo (Ingreso/Egreso)
- ✏️ Concepto
- ✏️ Monto
- ✏️ Categoría (según el tipo)
- ✏️ Fecha
- ✏️ Grupo

**Acciones disponibles:**

- 💾 Guardar cambios
- 🗑️ Eliminar (botón en AppBar)
- ← Cancelar (botón atrás)

---

## ⚠️ Confirmación de Eliminación

Cuando intentas eliminar un movimiento, aparece un diálogo de confirmación:

```
╔════════════════════════════════════╗
║  Confirmar eliminación             ║
║                                    ║
║  ¿Estás seguro de que deseas       ║
║  eliminar "Compra supermercado"?   ║
║                                    ║
║  Esta acción no se puede deshacer. ║
║                                    ║
║  [Cancelar]  [Eliminar]            ║
╚════════════════════════════════════╝
```

**Opciones:**

- **Cancelar:** No elimina nada y cierra el diálogo
- **Eliminar:** Elimina permanentemente de Google Sheets

---

## 🔄 Sincronización con Google Sheets

### Editar Movimiento

```
1. Usuario edita el movimiento en la app
   ↓
2. App actualiza la fila correspondiente en Google Sheets
   ↓
3. La lista local se actualiza automáticamente
   ↓
4. Mensaje de confirmación: "Movimiento actualizado exitosamente"
```

### Eliminar Movimiento

```
1. Usuario confirma la eliminación
   ↓
2. App elimina la fila completa en Google Sheets
   ↓
3. El movimiento se elimina de la lista local
   ↓
4. Mensaje de confirmación: "Movimiento eliminado exitosamente"
```

---

## 💡 Tips de Uso

### Para Editar:

✅ **Desliza hacia la derecha** - Más rápido  
✅ **Mantén presionado** - Más preciso  
✅ **Edita cualquier campo** - Todos son modificables  
✅ **Cambia el tipo** - De Ingreso a Egreso o viceversa

### Para Eliminar:

⚠️ **Siempre hay confirmación** - No se elimina accidentalmente  
⚠️ **Es permanente** - No hay "deshacer"  
⚠️ **Desliza completamente** - Debe llegar al final  
⚠️ **Desde la pantalla de edición** - También puedes eliminar

---

## 🎨 Feedback Visual

### Estados de la App:

**Editando:**

```
┌────────────────────────────────┐
│ ⚙️  Guardando cambios...       │
└────────────────────────────────┘
```

**Éxito:**

```
┌────────────────────────────────┐
│ ✅ Movimiento actualizado      │
└────────────────────────────────┘
```

**Eliminando:**

```
┌────────────────────────────────┐
│ ⚙️  Eliminando...              │
└────────────────────────────────┘
```

**Eliminado:**

```
┌────────────────────────────────┐
│ ✅ Movimiento eliminado        │
└────────────────────────────────┘
```

**Error:**

```
┌────────────────────────────────┐
│ ❌ Error al actualizar         │
└────────────────────────────────┘
```

---

## 🔧 Características Técnicas

### Edición:

- **Identificación:** Por índice en la lista
- **Actualización:** Fila por fila en Google Sheets
- **Validación:** Misma que al crear
- **Rollback:** No automático (se recarga desde Sheets)

### Eliminación:

- **Confirmación:** Diálogo obligatorio
- **Método:** `Worksheet.deleteRow(rowNumber)`
- **Cascada:** Elimina completamente de Google Sheets
- **Recuperación:** Solo desde historial de Google Sheets

---

## 🚨 Consideraciones Importantes

### ⚠️ ADVERTENCIAS:

1. **La eliminación es permanente** en la app

   - Puedes recuperar desde el historial de Google Sheets
   - Ve a: Archivo → Ver historial de versiones

2. **Los índices cambian** después de eliminar

   - La app se recarga automáticamente
   - No edites múltiples movimientos sin recargar

3. **Requiere conexión a Internet**

   - Sin conexión, las operaciones fallarán
   - Los cambios no se guardan localmente

4. **Validaciones activas**
   - No puedes guardar campos vacíos
   - El monto debe ser un número válido
   - La categoría debe estar en la lista

---

## 📊 Flujos de Usuario

### Flujo de Edición:

```
1. Ver lista de movimientos
   ↓
2. Deslizar derecha O mantener presionado
   ↓
3. Pantalla de edición se abre
   ↓
4. Modificar campos deseados
   ↓
5. Presionar "Guardar Cambios"
   ↓
6. Confirmación visual (✅)
   ↓
7. Volver a pantalla principal
   ↓
8. Ver movimiento actualizado
```

### Flujo de Eliminación (Swipe):

```
1. Ver lista de movimientos
   ↓
2. Deslizar completamente a la izquierda
   ↓
3. Diálogo de confirmación
   ↓
4. Presionar "Eliminar"
   ↓
5. Confirmación visual (✅)
   ↓
6. Movimiento desaparece de la lista
```

### Flujo de Eliminación (Desde Edición):

```
1. Abrir movimiento para editar
   ↓
2. Presionar ícono 🗑️ en AppBar
   ↓
3. Diálogo de confirmación
   ↓
4. Presionar "Eliminar"
   ↓
5. Confirmación visual (✅)
   ↓
6. Volver a pantalla principal
   ↓
7. Movimiento eliminado
```

---

## 🎓 Mejoras Futuras Sugeridas

### Para Considerar:

1. **Modo offline:**

   - Cola de cambios pendientes
   - Sincronización cuando haya conexión

2. **Historial de cambios:**

   - Log de modificaciones
   - Quién editó qué y cuándo

3. **Deshacer:**

   - Caché temporal de eliminados
   - Restaurar en X segundos

4. **Edición en lote:**

   - Selección múltiple
   - Cambiar categoría de varios a la vez

5. **Búsqueda antes de editar:**
   - Filtro en la lista
   - Encontrar el movimiento específico

---

## 🔐 Seguridad

### Permisos Necesarios:

✅ **Google Sheets API:** Escritura y eliminación  
✅ **Service Account:** Permisos de "Editor" en la hoja

### Precauciones:

⚠️ Las eliminaciones son **irreversibles** desde la app  
⚠️ Usa el historial de Google Sheets para recuperar  
⚠️ No compartas tu hoja con personas no autorizadas

---

## 📝 Notas de Desarrollo

### Archivos Modificados:

1. **`google_sheets_service.dart`**

   - `editarMovimiento()`
   - `eliminarMovimiento()`
   - `buscarIndiceMovimiento()`

2. **`movimientos_provider.dart`**

   - `editarMovimiento()`
   - `eliminarMovimiento()`

3. **`home_screen.dart`**

   - Integración de `Dismissible` widget
   - `_editarMovimiento()`
   - `_confirmarEliminar()`
   - Long press handler

4. **`editar_movimiento_screen.dart`** (NUEVO)
   - Pantalla completa de edición
   - Botón de eliminar en AppBar
   - Pre-llenado de campos

---

¡Ahora tienes control total sobre tus movimientos financieros! 🎉💰
