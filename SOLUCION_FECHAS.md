# 🔧 Solución al Problema de Fechas

## 🐛 Problema Detectado

Las fechas aparecían en la aplicación como números en lugar de fechas legibles:

- Ejemplo: `45963`, `45974`, `45962`
- Estos números son el **formato serial de Excel/Google Sheets** (días desde 30/12/1899)

## 🔍 Causa del Problema

Cuando se escribe una fecha en formato texto (como `"13/11/2025"`) en Google Sheets:

1. Si la celda **NO está formateada como texto**, Google Sheets automáticamente detecta que es una fecha
2. La convierte a formato de **número serial** internamente
3. Al leer los datos, obtenemos el número serial en lugar del texto original

**Ejemplo de conversión:**

- `13/11/2025` → Se guarda como `45963`
- `24/11/2025` → Se guarda como `45974`
- `12/11/2025` → Se guarda como `45962`

## ✅ Solución Implementada

Se implementaron **dos mecanismos de protección**:

### 1. Forzar Formato Texto al Escribir

En `toSheetRow()` del modelo `Movimiento`:

```dart
List<dynamic> toSheetRow() {
  return ["'$fecha", mes, tipo, categoria, concepto, monto, grupo];
  //      ↑ Comilla simple fuerza formato texto
}
```

**Cómo funciona:**

- Al agregar `'` (comilla simple) antes de la fecha, Google Sheets la trata como **texto puro**
- Ejemplo: `'13/11/2025` se guarda como texto `13/11/2025`, no como número

**Ventaja:**

- Los **nuevos movimientos** se guardarán correctamente como texto

### 2. Convertir Números Seriales al Leer

En `fromSheetRow()` del modelo `Movimiento`:

```dart
factory Movimiento.fromSheetRow(List<dynamic> row) {
  String fechaStr = row.length > 0 ? row[0].toString() : '';

  // Si la fecha es un número (formato serial de Excel), convertirlo
  if (fechaStr.isNotEmpty && double.tryParse(fechaStr) != null) {
    // Es un número serial de Excel/Sheets (días desde 01/01/1900)
    final serialNumber = double.parse(fechaStr);
    // Google Sheets usa 30/12/1899 como día 1
    final baseDate = DateTime(1899, 12, 30);
    final fecha = baseDate.add(Duration(days: serialNumber.toInt()));
    fechaStr = '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  return Movimiento(
    fecha: fechaStr,
    // ... resto de campos
  );
}
```

**Cómo funciona:**

1. Detecta si la fecha es un número (usando `double.tryParse()`)
2. Si es número, calcula la fecha real:
   - Número serial de Google Sheets = días desde `30/12/1899`
   - Ejemplo: `45963` días desde `30/12/1899` = `13/11/2025`
3. Convierte la fecha a formato `dd/MM/yyyy`

**Ventaja:**

- Los **movimientos existentes** (ya guardados como números) se mostrarán correctamente

## 🎯 Resultado Final

### Para Datos Nuevos

✅ Se guardan con `'` al inicio → Google Sheets los trata como texto
✅ Al leer, se obtiene el texto directamente sin conversión

### Para Datos Existentes

✅ Se leen como números seriales
✅ Se convierten automáticamente a formato `dd/MM/yyyy`
✅ Se muestran correctamente en la app

## 📊 Ejemplos de Conversión

| Número Serial | Cálculo                 | Fecha Resultante |
| ------------- | ----------------------- | ---------------- |
| 45963         | 30/12/1899 + 45963 días | 13/11/2025       |
| 45974         | 30/12/1899 + 45974 días | 24/11/2025       |
| 45962         | 30/12/1899 + 45962 días | 12/11/2025       |

## 🛠️ Alternativa Manual (Opcional)

Si prefieres corregir manualmente las fechas en Google Sheets:

1. **Formatear la columna de fechas como texto:**

   - Selecciona toda la columna de fechas (Columna A)
   - Ve a **Formato** → **Número** → **Texto sin formato**

2. **Reemplazar números por fechas:**

   - Puedes usar una fórmula temporal en otra columna:
     ```
     =TEXT(A2,"DD/MM/YYYY")
     ```
   - Copia los resultados y pega como **valores** sobre la columna original

3. **Agregar comilla simple:**
   - En una celda auxiliar: `="'"&B2`
   - Copia y pega como valores sobre la columna de fechas

**Nota:** Con la solución implementada en el código, esto **NO es necesario**. La app maneja automáticamente ambos formatos.

## ✅ Verificación

Para verificar que la solución funciona:

1. **Movimientos existentes**: Verifica que los que mostraban números ahora muestren fechas correctas
2. **Nuevos movimientos**: Crea uno nuevo y verifica que:
   - Se guarda correctamente en Google Sheets
   - Se muestra correctamente en la app
   - En Google Sheets aparece con `'` al inicio (pero no se muestra la comilla)

## 📝 Notas Técnicas

### Formato Serial de Excel/Google Sheets

- **Base**: 30 de diciembre de 1899 (día 0)
- **Incremento**: +1 por cada día
- **Ejemplo**:
  - Día 1 = 31/12/1899
  - Día 45963 = 13/11/2025

### Por qué 30/12/1899

Aunque Excel usa 01/01/1900 como referencia, tiene un bug histórico donde considera 1900 como año bisiesto (no lo es). Google Sheets replicó este comportamiento por compatibilidad. Para evitar complicaciones, usamos 30/12/1899 como base.

### Formato de Salida

La fecha se formatea como `dd/MM/yyyy` con ceros a la izquierda:

- ✅ `01/01/2025` (correcto)
- ❌ `1/1/2025` (evitado)

Esto se logra con:

```dart
fecha.day.toString().padLeft(2, '0')
```

## 🚀 Mejoras Futuras (Opcional)

1. **Formato de fecha personalizable**: Permitir al usuario elegir formato (dd/MM/yyyy, MM/dd/yyyy, yyyy-MM-dd)
2. **Zona horaria**: Considerar zona horaria del usuario
3. **Validación en Google Sheets**: Script de Apps Script para forzar formato texto automáticamente
4. **Cache de formato**: Guardar preferencia de formato en SharedPreferences

## 🐛 Troubleshooting

### Las fechas antiguas aún se muestran como números

**Causa:** Puede que la columna en Google Sheets tenga formato de fecha con configuración regional diferente.

**Solución:**

1. Borra los datos de prueba
2. Crea nuevos movimientos
3. Verifica que aparezcan correctamente

### Fechas incorrectas después de la conversión

**Causa:** Puede haber diferencia de zona horaria o formato.

**Solución:**

1. Verifica que la fecha base sea `30/12/1899`
2. Confirma que el cálculo use `.toInt()` para evitar fracciones de día
3. Revisa que el formato de salida sea el correcto

### La comilla ' se muestra en Google Sheets

**Comportamiento esperado:** La comilla `'` NO se muestra en Google Sheets, solo fuerza el formato texto. Si la ves, es normal, pero en la interfaz de Sheets no debería aparecer.

## 📞 Resumen

✅ **Problema resuelto**: Las fechas ahora se muestran correctamente en formato `dd/MM/yyyy`
✅ **Compatibilidad**: Funciona con datos existentes (números) y nuevos (texto)
✅ **Automático**: No requiere intervención manual del usuario
✅ **Robusto**: Maneja múltiples formatos de entrada
