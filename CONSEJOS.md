# 💡 Consejos y Mejores Prácticas

## 🎯 Uso Óptimo de la App

### 1. Registro Diario

- ✅ **Registra tus movimientos diariamente** para no olvidar ningún gasto o ingreso
- ✅ Hazlo justo después de realizar una compra o recibir un pago
- ✅ Usa el campo "Grupo" para organizar por proyectos o personas

### 2. Categorías

- 📂 **Sé consistente con las categorías** - usa siempre las mismas
- 📂 Si necesitas nuevas categorías, agrégalas en el código
- 📂 No uses "Otro" a menos que sea realmente necesario

### 3. Conceptos Descriptivos

- 📝 **Sé específico**: En lugar de "Comida", escribe "Almuerzo en Restaurante X"
- 📝 **Incluye detalles relevantes**: "Netflix - Plan Premium" vs solo "Netflix"
- 📝 **Usa nombres consistentes** para gastos recurrentes

### 4. Grupos

- 👥 **Personal**: Gastos individuales
- 👥 **Familia**: Gastos compartidos del hogar
- 👥 **Trabajo**: Gastos relacionados con el trabajo
- 👥 **Proyecto X**: Para gastos de proyectos específicos

---

## 📊 Análisis de tus Finanzas

### En Google Sheets

Una vez que tus datos están en Google Sheets, puedes crear análisis adicionales:

#### 1. Gráficas Automáticas

```
Selecciona tus datos → Insertar → Gráfico
```

**Gráficas recomendadas:**

- Gráfico circular: Distribución de gastos por categoría
- Gráfico de líneas: Tendencia de gastos/ingresos por mes
- Gráfico de barras: Comparación mensual

#### 2. Tablas Dinámicas

```
Datos → Tabla dinámica
```

**Análisis útiles:**

- Total por categoría y mes
- Promedio de gastos por categoría
- Comparación año con año

#### 3. Fórmulas Útiles

**Total de ingresos del mes actual:**

```excel
=SUMIFS(F:F, C:C, "Ingreso", B:B, "noviembre")
```

**Total de egresos del mes actual:**

```excel
=SUMIFS(F:F, C:C, "Egreso", B:B, "noviembre")
```

**Balance del mes:**

```excel
=SUMIFS(F:F, C:C, "Ingreso", B:B, "noviembre") - SUMIFS(F:F, C:C, "Egreso", B:B, "noviembre")
```

**Gasto promedio por categoría:**

```excel
=AVERAGEIFS(F:F, D:D, "Alimentación", C:C, "Egreso")
```

**Ranking de categorías con más gastos:**

```excel
=QUERY(A:G, "SELECT D, SUM(F) WHERE C='Egreso' GROUP BY D ORDER BY SUM(F) DESC")
```

---

## 🔐 Seguridad y Privacidad

### Protección de Credenciales

1. **Nunca compartas tu archivo de credenciales JSON**
2. **No subas las credenciales a repositorios públicos** (Git, GitHub, etc.)
3. **Usa .gitignore** para excluir archivos sensibles
4. **Rota las credenciales periódicamente** (cada 6 meses)

### Backup de Datos

1. **Google Sheets hace backup automático**
   - Ve a: Archivo → Ver historial de versiones
2. **Exporta tu hoja periódicamente:**

   - Archivo → Descargar → Excel (.xlsx)
   - Guárdalo en un lugar seguro

3. **Configura copia de seguridad automática:**
   - Usa Google Drive Backup
   - O configura un script de Apps Script

---

## 🚀 Mejoras Futuras que Puedes Implementar

### 1. Filtros Avanzados

**En la pantalla principal, agrega:**

- Filtro por mes
- Filtro por categoría
- Filtro por rango de fechas
- Búsqueda por concepto

### 2. Modo Offline

**Implementa caché local:**

```dart
// Usa Hive o SQLite
import 'package:hive/hive.dart';

// Guarda datos localmente
await box.put('movimientos', movimientosList);

// Lee datos offline
var cachedMovimientos = box.get('movimientos');
```

### 3. Notificaciones

**Recuerda registrar gastos:**

```dart
// Usa flutter_local_notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Notificación diaria a las 8 PM
await flutterLocalNotificationsPlugin.zonedSchedule(
  0,
  'Registra tus gastos',
  '¿Olvidaste registrar algún gasto hoy?',
  scheduledDate,
  notificationDetails,
);
```

### 4. Presupuestos

**Agrega límites por categoría:**

```dart
class Presupuesto {
  String categoria;
  double limite;
  double gastado;

  double get disponible => limite - gastado;
  bool get excedido => gastado > limite;
}
```

### 5. Exportar Reportes

**PDF mensual:**

```dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> generarReportePDF() async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (context) => pw.Column(
        children: [
          pw.Text('Reporte de Finanzas - Noviembre 2025'),
          pw.Text('Ingresos: \$5,000.00'),
          pw.Text('Egresos: \$2,500.50'),
          pw.Text('Balance: \$2,499.50'),
        ],
      ),
    ),
  );

  final file = File('reporte.pdf');
  await file.writeAsBytes(await pdf.save());
}
```

### 6. Gráficas en la App

**Visualización de datos:**

```dart
import 'package:fl_chart/fl_chart.dart';

// Gráfico de pastel
PieChart(
  PieChartData(
    sections: [
      PieChartSectionData(
        value: alimentacion,
        title: 'Alimentación',
        color: Colors.blue,
      ),
      // ... más categorías
    ],
  ),
);
```

### 7. Multi-usuario

**Compartir finanzas familiares:**

```dart
// Agrega campo de usuario en Google Sheets
// Implementa Firebase Auth
// Filtra por usuario actual
```

### 8. Recordatorios de Gastos Recurrentes

**Para suscripciones:**

```dart
class GastoRecurrente {
  String concepto;
  double monto;
  DateTime proximoPago;
  Frecuencia frecuencia; // Mensual, Anual, etc.
}
```

---

## 🐛 Debugging y Logs

### Ver logs en Flutter

```bash
# Logs detallados
flutter run -v

# Solo logs de la app
flutter run | grep -E "print|flutter"
```

### Agregar logs en el código

```dart
// En GoogleSheetsService
print('🔵 Conectando a Google Sheets...');
print('🟢 Conexión exitosa!');
print('🔴 Error: $e');

// En MovimientosProvider
print('📊 Movimientos cargados: ${_movimientos.length}');
print('💰 Balance actual: $balance');
```

### Debugging en VS Code

1. Presiona F5 para iniciar debug
2. Coloca breakpoints (clic en el número de línea)
3. Inspecciona variables
4. Usa el panel de Debug Console

---

## 📝 Convenciones de Código

### Nombres de Variables

```dart
// ✅ Bueno
final String userName;
final double totalAmount;
final List<Movimiento> movimientosList;

// ❌ Malo
final String n;
final double amt;
final List<Movimiento> list;
```

### Comentarios

```dart
// ✅ Bueno - Explica el "por qué"
// Ordenamos por fecha más reciente primero para mejor UX
movimientos.sort((a, b) => b.fecha.compareTo(a.fecha));

// ❌ Malo - Explica el "qué" (obvio)
// Ordena los movimientos
movimientos.sort((a, b) => b.fecha.compareTo(a.fecha));
```

### Manejo de Errores

```dart
// ✅ Bueno
try {
  await _sheetsService.agregarMovimiento(movimiento);
  _showSuccessMessage();
} catch (e) {
  _showErrorMessage('Error al guardar: $e');
  _logError(e);
}

// ❌ Malo
try {
  await _sheetsService.agregarMovimiento(movimiento);
} catch (e) {
  // Silenciosamente falla
}
```

---

## 🎓 Recursos de Aprendizaje

### Flutter

- [Documentación Oficial](https://docs.flutter.dev/)
- [Flutter Codelabs](https://docs.flutter.dev/codelabs)
- [Flutter Widget Catalog](https://docs.flutter.dev/ui/widgets)

### Google Sheets API

- [Sheets API Documentation](https://developers.google.com/sheets/api)
- [gsheets Package](https://pub.dev/packages/gsheets)

### Provider Pattern

- [Provider Package](https://pub.dev/packages/provider)
- [State Management Guide](https://docs.flutter.dev/data-and-backend/state-mgmt)

### Dart

- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

---

## 🤝 Contribuciones

Si quieres mejorar esta app:

1. **Fork el proyecto**
2. **Crea una rama para tu feature:** `git checkout -b feature/nueva-funcionalidad`
3. **Commit tus cambios:** `git commit -am 'Agrega nueva funcionalidad'`
4. **Push a la rama:** `git push origin feature/nueva-funcionalidad`
5. **Crea un Pull Request**

---

## 📞 Soporte

Si tienes problemas o preguntas:

1. **Revisa la documentación:** README.md, CONFIGURACION.md
2. **Busca en los Issues** de GitHub
3. **Crea un nuevo Issue** con:
   - Descripción del problema
   - Pasos para reproducirlo
   - Screenshots si aplica
   - Logs relevantes

---

## ✨ Tips Finales

1. **Empieza simple** - No agregues todas las features de una vez
2. **Sé consistente** - Usa las mismas categorías y nombres
3. **Revisa semanalmente** - Analiza tus gastos cada semana
4. **Ajusta tu presupuesto** - Aprende de tus patrones de gasto
5. **Haz backup** - Exporta tu sheet mensualmente
6. **Actualiza la app** - Descarga actualizaciones regularmente
7. **Comparte experiencias** - Ayuda a otros usuarios

---

**¡Recuerda: El primer paso para controlar tus finanzas es conocerlas! 💰**
