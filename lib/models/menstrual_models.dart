/// Modelos de datos para el calendario menstrual.

// ─────────────────────────────────────────────
// CICLO MENSTRUAL REGISTRADO
// ─────────────────────────────────────────────
class MenstrualCycle {
  String id;
  DateTime startDate;
  DateTime? endDate;

  MenstrualCycle({
    required this.id,
    required this.startDate,
    this.endDate,
  });

  int get durationDays {
    if (endDate == null) {
      // Si no ha terminado, calcular hasta el día de hoy
      final now = DateTime.now();
      final diff = DateTime(now.year, now.month, now.day).difference(startDate).inDays + 1;
      return diff > 0 ? diff : 1;
    }
    return endDate!.difference(startDate).inDays + 1;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      };

  factory MenstrualCycle.fromMap(Map<String, dynamic> map) => MenstrualCycle(
        id: map['id'] ?? '',
        startDate: DateTime.parse(map['startDate']),
        endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      );
}

// ─────────────────────────────────────────────
// REGISTRO DIARIO (CORAZONES, SÍNTOMAS)
// ─────────────────────────────────────────────
class DailyLog {
  String dateKey; // "YYYY-MM-DD"
  bool hasHeart;
  List<String> symptoms;

  DailyLog({
    required this.dateKey,
    this.hasHeart = false,
    List<String>? symptoms,
  }) : symptoms = symptoms ?? [];

  Map<String, dynamic> toMap() => {
        'dateKey': dateKey,
        'hasHeart': hasHeart,
        'symptoms': symptoms,
      };

  factory DailyLog.fromMap(Map<String, dynamic> map) => DailyLog(
        dateKey: map['dateKey'] ?? '',
        hasHeart: map['hasHeart'] ?? false,
        symptoms: List<String>.from(map['symptoms'] ?? []),
      );
}

// ─────────────────────────────────────────────
// DATOS COMPLETOS DEL CALENDARIO MENSTRUAL
// ─────────────────────────────────────────────
class MenstrualData {
  List<MenstrualCycle> cycles;
  List<DailyLog> logs;

  MenstrualData({
    List<MenstrualCycle>? cycles,
    List<DailyLog>? logs,
  })  : cycles = cycles ?? [],
        logs = logs ?? [];

  /// Promedio inteligente de días del ciclo (aprende de las tendencias)
  int get averageCycleLength {
    if (cycles.length < 2) return 28;
    final sorted = List<MenstrualCycle>.from(cycles)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    
    double totalWeight = 0;
    double weightedSum = 0;
    
    // Damos más peso a los ciclos recientes para que aprenda mejor las tendencias actuales
    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].startDate.difference(sorted[i - 1].startDate).inDays;
      // Solo tomamos en cuenta ciclos con una duración realista (15 a 60 días)
      if (diff >= 15 && diff <= 60) {
        // Peso creciente: el ciclo más antiguo pesa 1, el siguiente 2, etc.
        double weight = i.toDouble(); 
        weightedSum += diff * weight;
        totalWeight += weight;
      }
    }
    return totalWeight > 0 ? (weightedSum / totalWeight).round() : 28;
  }

  /// Duración promedio de la menstruación
  int get averagePeriodLength {
    if (cycles.isEmpty) return 5;
    // Solo usamos periodos que hayan sido cerrados explícitamente para calcular el promedio
    final withEnd = cycles.where((c) => c.endDate != null).toList();
    if (withEnd.isEmpty) return 5;
    
    int validCount = 0;
    int totalDays = 0;
    for (var c in withEnd) {
      final days = c.durationDays;
      // Ignoramos registros anómalos (olvidos de cerrar el periodo)
      if (days >= 2 && days <= 12) {
        totalDays += days;
        validCount++;
      }
    }
    if (validCount == 0) return 5;
    return (totalDays / validCount).round().clamp(3, 10);
  }

  /// Último ciclo registrado
  MenstrualCycle? get lastCycle {
    if (cycles.isEmpty) return null;
    final sorted = List<MenstrualCycle>.from(cycles)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    return sorted.first;
  }

  /// Fecha predicha del próximo periodo
  DateTime? get nextPeriodDate {
    if (lastCycle == null) return null;
    return lastCycle!.startDate.add(Duration(days: averageCycleLength));
  }

  /// Días que faltan para el próximo periodo
  int? get daysUntilNextPeriod {
    if (nextPeriodDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return nextPeriodDate!.difference(today).inDays;
  }

  /// Día actual del ciclo (1-indexed)
  int? get currentCycleDay {
    if (lastCycle == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(lastCycle!.startDate.year, lastCycle!.startDate.month, lastCycle!.startDate.day);
    final diff = today.difference(start).inDays + 1;
    if (diff < 1 || diff > averageCycleLength + 10) return null;
    return diff;
  }

  /// Fase actual del ciclo
  String get currentPhase {
    final day = currentCycleDay;
    if (day == null) return 'Sin datos';
    final periodLen = averagePeriodLength;
    final cycleLen = averageCycleLength;
    final ovulationDay = cycleLen - 14;

    if (day <= periodLen) {
      return 'Menstruación';
    } else if (day < ovulationDay - 2) {
      return 'Fase Folicular';
    } else if (day <= ovulationDay + 2) {
      return 'Ovulación';
    } else {
      return 'Fase Lútea';
    }
  }

  /// Emoji de la fase actual
  String get currentPhaseEmoji {
    switch (currentPhase) {
      case 'Menstruación':
        return '🩸';
      case 'Fase Folicular':
        return '🌱';
      case 'Ovulación':
        return '🌸';
      case 'Fase Lútea':
        return '🌙';
      default:
        return '❓';
    }
  }

  /// Descripción de la fase actual
  String get currentPhaseDescription {
    switch (currentPhase) {
      case 'Menstruación':
        return 'Período activo. Cuídate y descansa 💕';
      case 'Fase Folicular':
        return 'Tu cuerpo se prepara. Energía en aumento ✨';
      case 'Ovulación':
        return 'Ventana fértil. Máxima energía 🌟';
      case 'Fase Lútea':
        return 'Preparándose para el próximo ciclo 🌙';
      default:
        return 'Registra tu ciclo para obtener predicciones';
    }
  }

  /// Verifica si una fecha está en periodo de menstruación
  bool isDateInPeriod(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    for (final cycle in cycles) {
      final start = DateTime(cycle.startDate.year, cycle.startDate.month, cycle.startDate.day);
      if (cycle.endDate != null) {
        final end = DateTime(cycle.endDate!.year, cycle.endDate!.month, cycle.endDate!.day);
        if (!d.isBefore(start) && !d.isAfter(end)) return true;
      } else {
        // El periodo sigue abierto. Marcar en rojo desde el inicio hasta el día actual.
        // No marcamos días en el futuro (si d es mañana, no es rojo hasta que llegue el día).
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (!d.isBefore(start) && !d.isAfter(today)) return true;
      }
    }
    return false;
  }

  /// Verifica si una fecha está en la predicción del próximo periodo
  bool isDateInPredictedPeriod(DateTime date) {
    if (nextPeriodDate == null) return false;
    final d = DateTime(date.year, date.month, date.day);
    final start = DateTime(nextPeriodDate!.year, nextPeriodDate!.month, nextPeriodDate!.day);
    final end = start.add(Duration(days: averagePeriodLength - 1));
    return !d.isBefore(start) && !d.isAfter(end);
  }

  /// Verifica si una fecha está en la ventana de ovulación
  bool isDateInOvulation(DateTime date) {
    if (lastCycle == null) return false;
    final d = DateTime(date.year, date.month, date.day);
    final cycleLen = averageCycleLength;
    final ovulationDay = cycleLen - 14;
    final ovDate = DateTime(
      lastCycle!.startDate.year,
      lastCycle!.startDate.month,
      lastCycle!.startDate.day,
    ).add(Duration(days: ovulationDay));
    final start = ovDate.subtract(const Duration(days: 2));
    final end = ovDate.add(const Duration(days: 2));
    return !d.isBefore(start) && !d.isAfter(end);
  }

  /// Obtiene el log de un día específico
  DailyLog? getLog(DateTime date) {
    final key = _dateToKey(date);
    try {
      return logs.firstWhere((l) => l.dateKey == key);
    } catch (_) {
      return null;
    }
  }

  /// Verifica si un día tiene corazón
  bool hasHeart(DateTime date) {
    return getLog(date)?.hasHeart ?? false;
  }

  static String _dateToKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Serialización ──

  Map<String, dynamic> toMap() => {
        'cycles': cycles.map((c) => c.toMap()).toList(),
        'logs': logs.map((l) => l.toMap()).toList(),
      };

  factory MenstrualData.fromMap(Map<String, dynamic> map) => MenstrualData(
        cycles: (map['cycles'] as List<dynamic>?)
                ?.map((c) => MenstrualCycle.fromMap(c as Map<String, dynamic>))
                .toList() ??
            [],
        logs: (map['logs'] as List<dynamic>?)
                ?.map((l) => DailyLog.fromMap(l as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
