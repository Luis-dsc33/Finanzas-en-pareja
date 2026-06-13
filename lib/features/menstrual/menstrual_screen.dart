import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/menstrual_models.dart';
import '../../services/firebase/menstrual_service.dart';
import '../../main.dart'; // AppColors

class MenstrualScreen extends StatefulWidget {
  const MenstrualScreen({Key? key}) : super(key: key);

  @override
  State<MenstrualScreen> createState() => _MenstrualScreenState();
}

class _MenstrualScreenState extends State<MenstrualScreen> {
  final MenstrualService _service = MenstrualService();

  MenstrualData? _data;
  bool _isLoading = true;
  StreamSubscription<MenstrualData?>? _sub;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Onboarding
  bool _showOnboarding = false;
  DateTime? _onboardDate1;
  DateTime? _onboardDate2;

  bool get _isMiri {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return email.toLowerCase() == 'miri@finanzas.com';
  }

  @override
  void initState() {
    super.initState();
    _sub = _service.watchData().listen((data) {
      if (mounted) {
        setState(() {
          _data = data ?? MenstrualData();
          _isLoading = false;
          // Si Miri y no tiene ciclos, mostrar onboarding
          if (_isMiri && _data!.cycles.isEmpty) {
            _showOnboarding = true;
          } else {
            _showOnboarding = false;
          }
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _data = MenstrualData();
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ── Colores por fase ──
  static const Color _periodColor = Color(0xFFFF8FAB);
  static const Color _predictedColor = Color(0xFFFFD6E0);
  static const Color _ovulationColor = Color(0xFFB5EAD7);
  static const Color _heartColor = Color(0xFFE0AAFF);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SafeArea(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.pink),
        ),
      );
    }

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isMiri ? 'Mi ciclo 🌸' : 'Ciclo de Miri 🌸',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isMiri
                                ? 'Lleva el control de tu ciclo'
                                : 'Vista de solo lectura',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (!_isMiri)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.skyBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility_rounded,
                                  color: AppColors.skyBlue, size: 16),
                              SizedBox(width: 4),
                              Text('Solo lectura',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.skyBlue)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Onboarding para Miri
                  if (_showOnboarding) _buildOnboarding(),

                  // Calendario
                  if (!_showOnboarding) ...[
                    _buildCalendar(),
                    const SizedBox(height: 16),

                    // Acciones de Miri para el día seleccionado
                    if (_isMiri && _selectedDay != null)
                      _buildDayActions(),
                    if (_isMiri && _selectedDay != null)
                      const SizedBox(height: 16),

                    // Tarjeta de estado actual
                    _buildPhaseCard(),
                    const SizedBox(height: 16),

                    // Info del próximo periodo
                    _buildNextPeriodCard(),
                    const SizedBox(height: 16),

                    // Leyenda
                    _buildLegend(),
                    const SizedBox(height: 16),

                    // Historial de ciclos (solo Miri)
                    if (_isMiri) _buildCycleHistory(),
                    const SizedBox(height: 100),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ONBOARDING
  // ═══════════════════════════════════════════
  Widget _buildOnboarding() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF2B5D4), Color(0xFFCBB6F0), Color(0xFFA8D8EA)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.pink.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¡Hola Miri! 🌷',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Para predecir tu ciclo con más precisión, por favor registra la fecha de inicio de tus últimos 2 periodos.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 24),

          // Fecha del periodo más antiguo
          _buildOnboardDatePicker(
            label: 'Inicio del penúltimo periodo',
            date: _onboardDate1,
            onPick: () async {
              final d = await showDatePicker(
                context: context,
                initialDate:
                    DateTime.now().subtract(const Duration(days: 56)),
                firstDate:
                    DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppColors.pink,
                        onPrimary: Colors.white,
                        surface: AppColors.background,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (d != null) setState(() => _onboardDate1 = d);
            },
          ),
          const SizedBox(height: 14),

          // Fecha del último periodo
          _buildOnboardDatePicker(
            label: 'Inicio del último periodo',
            date: _onboardDate2,
            onPick: () async {
              final d = await showDatePicker(
                context: context,
                initialDate:
                    DateTime.now().subtract(const Duration(days: 28)),
                firstDate:
                    DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppColors.pink,
                        onPrimary: Colors.white,
                        surface: AppColors.background,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (d != null) setState(() => _onboardDate2 = d);
            },
          ),
          const SizedBox(height: 24),

          // Botón guardar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_onboardDate1 != null && _onboardDate2 != null)
                  ? _saveOnboarding
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.pink,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Guardar y empezar 🌸',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardDatePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onPick,
  }) {
    const months = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                date != null
                    ? '${date.day} ${months[date.month]} ${date.year}'
                    : label,
                style: TextStyle(
                  color: date != null
                      ? Colors.white
                      : Colors.white.withOpacity(0.7),
                  fontWeight:
                      date != null ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.edit_calendar_rounded,
                color: Colors.white.withOpacity(0.7), size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _saveOnboarding() async {
    if (_onboardDate1 == null || _onboardDate2 == null) return;

    // Asegurar que date1 es antes que date2
    DateTime first, second;
    if (_onboardDate1!.isBefore(_onboardDate2!)) {
      first = _onboardDate1!;
      second = _onboardDate2!;
    } else {
      first = _onboardDate2!;
      second = _onboardDate1!;
    }

    final data = MenstrualData(
      cycles: [
        MenstrualCycle(
          id: first.millisecondsSinceEpoch.toString(),
          startDate: first,
          endDate: first.add(const Duration(days: 4)),
        ),
        MenstrualCycle(
          id: second.millisecondsSinceEpoch.toString(),
          startDate: second,
          endDate: second.add(const Duration(days: 4)),
        ),
      ],
    );

    await _service.saveData(data);
    // El stream se actualizará automáticamente
  }

  // ═══════════════════════════════════════════
  // CALENDARIO
  // ═══════════════════════════════════════════
  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime(2024, 1, 1),
        lastDay: DateTime(2028, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() => _calendarFormat = format);
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        locale: 'es_ES',
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left_rounded,
              color: AppColors.pink),
          rightChevronIcon: const Icon(Icons.chevron_right_rounded,
              color: AppColors.pink),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
          weekendStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textLight,
          ),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppColors.lavender.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.pink,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          outsideDaysVisible: false,
          defaultTextStyle: const TextStyle(
            color: AppColors.textPrimary,
          ),
          weekendTextStyle: const TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) =>
              _buildDayCell(day, false, false),
          todayBuilder: (context, day, focusedDay) =>
              _buildDayCell(day, true, false),
          selectedBuilder: (context, day, focusedDay) =>
              _buildDayCell(day, false, true),
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day, bool isToday, bool isSelected) {
    final data = _data ?? MenstrualData();
    final inPeriod = data.isDateInPeriod(day);
    final inPredicted = data.isDateInPredictedPeriod(day);
    final inOvulation = data.isDateInOvulation(day);
    final heart = data.hasHeart(day);

    Color? bgColor;
    Color textColor = AppColors.textPrimary;
    BoxBorder? border;

    if (isSelected) {
      bgColor = AppColors.pink;
      textColor = Colors.white;
    } else if (inPeriod) {
      bgColor = _periodColor;
      textColor = Colors.white;
    } else if (inPredicted) {
      bgColor = _predictedColor;
      textColor = AppColors.pink;
    } else if (inOvulation) {
      bgColor = _ovulationColor;
      textColor = const Color(0xFF2D6A4F);
    } else if (isToday) {
      bgColor = AppColors.lavender.withOpacity(0.2);
      border = Border.all(color: AppColors.lavender, width: 2);
    }

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: border,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontWeight:
                  (isToday || isSelected) ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
              color: textColor,
            ),
          ),
          if (heart)
            Positioned(
              bottom: 2,
              child: Text('💜',
                  style: TextStyle(
                      fontSize: 8,
                      shadows: [
                        Shadow(
                            blurRadius: 2,
                            color: Colors.black.withOpacity(0.3))
                      ])),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ACCIONES DEL DÍA (Solo Miri)
  // ═══════════════════════════════════════════
  Widget _buildDayActions() {
    final data = _data ?? MenstrualData();
    final day = _selectedDay!;
    final inPeriod = data.isDateInPeriod(day);
    final heart = data.hasHeart(day);

    const months = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${day.day} ${months[day.month]} ${day.year}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Botón Periodo
              Expanded(
                child: _buildActionButton(
                  emoji: '🩸',
                  label: inPeriod ? 'Quitar periodo' : 'Marcar periodo',
                  color: _periodColor,
                  isActive: inPeriod,
                  onTap: () => _togglePeriod(day),
                ),
              ),
              const SizedBox(width: 12),
              // Botón Corazón
              Expanded(
                child: _buildActionButton(
                  emoji: '💜',
                  label: heart ? 'Quitar corazón' : 'Agregar corazón',
                  color: _heartColor,
                  isActive: heart,
                  onTap: () => _service.toggleHeart(day),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String emoji,
    required String label,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.3) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? color : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePeriod(DateTime day) async {
    final data = _data ?? MenstrualData();
    final d = DateTime(day.year, day.month, day.day);

    // Verificar si el día ya está en un ciclo existente
    MenstrualCycle? existing;
    for (final cycle in data.cycles) {
      final start = DateTime(
          cycle.startDate.year, cycle.startDate.month, cycle.startDate.day);
      final end = cycle.endDate != null
          ? DateTime(cycle.endDate!.year, cycle.endDate!.month,
              cycle.endDate!.day)
          : start.add(Duration(days: data.averagePeriodLength - 1));
      if (!d.isBefore(start) && !d.isAfter(end)) {
        existing = cycle;
        break;
      }
    }

    if (existing != null) {
      // Quitar el día: si es start/end, ajustar; si es el único, eliminar ciclo
      if (existing.durationDays <= 1 ||
          (d == DateTime(existing.startDate.year, existing.startDate.month,
                  existing.startDate.day) &&
              existing.endDate == null)) {
        await _service.deleteCycle(existing.id);
      } else {
        // Si es el primer día, mover start un día
        final start = DateTime(existing.startDate.year,
            existing.startDate.month, existing.startDate.day);
        if (d == start) {
          existing.startDate = d.add(const Duration(days: 1));
          await _service.saveData(data);
        } else {
          // Si es el último día, mover end un día atrás
          final end = existing.endDate != null
              ? DateTime(existing.endDate!.year, existing.endDate!.month,
                  existing.endDate!.day)
              : start.add(Duration(days: data.averagePeriodLength - 1));
          if (d == end) {
            existing.endDate = d.subtract(const Duration(days: 1));
            await _service.saveData(data);
          } else {
            // Día intermedio: acortar endDate a día anterior
            existing.endDate = d.subtract(const Duration(days: 1));
            await _service.saveData(data);
          }
        }
      }
    } else {
      // Agregar: buscar si está adyacente a un ciclo existente
      bool extended = false;
      for (final cycle in data.cycles) {
        final end = cycle.endDate ??
            cycle.startDate.add(Duration(days: data.averagePeriodLength - 1));
        final endDay = DateTime(end.year, end.month, end.day);
        final startDay = DateTime(
            cycle.startDate.year, cycle.startDate.month, cycle.startDate.day);

        if (d == endDay.add(const Duration(days: 1))) {
          cycle.endDate = d;
          await _service.saveData(data);
          extended = true;
          break;
        } else if (d == startDay.subtract(const Duration(days: 1))) {
          cycle.startDate = d;
          await _service.saveData(data);
          extended = true;
          break;
        }
      }

      if (!extended) {
        // Crear nuevo ciclo
        await _service.addCycle(MenstrualCycle(
          id: d.millisecondsSinceEpoch.toString(),
          startDate: d,
          endDate: null,
        ));
      }
    }
  }

  // ═══════════════════════════════════════════
  // TARJETA DE FASE ACTUAL
  // ═══════════════════════════════════════════
  Widget _buildPhaseCard() {
    final data = _data ?? MenstrualData();
    final phase = data.currentPhase;
    final emoji = data.currentPhaseEmoji;
    final desc = data.currentPhaseDescription;
    final cycleDay = data.currentCycleDay;

    Color phaseColor;
    switch (phase) {
      case 'Menstruación':
        phaseColor = _periodColor;
        break;
      case 'Fase Folicular':
        phaseColor = AppColors.mint;
        break;
      case 'Ovulación':
        phaseColor = _ovulationColor;
        break;
      case 'Fase Lútea':
        phaseColor = AppColors.lavender;
        break;
      default:
        phaseColor = AppColors.textLight;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            phaseColor.withOpacity(0.3),
            phaseColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: phaseColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: phaseColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phase,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (cycleDay != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Día $cycleDay del ciclo',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: phaseColor,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // PRÓXIMO PERIODO
  // ═══════════════════════════════════════════
  Widget _buildNextPeriodCard() {
    final data = _data ?? MenstrualData();
    final daysUntil = data.daysUntilNextPeriod;
    final nextDate = data.nextPeriodDate;

    const months = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _predictedColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                daysUntil != null ? '$daysUntil' : '?',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: daysUntil != null ? 22 : 24,
                  color: AppColors.pink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Próximo periodo',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  daysUntil != null && nextDate != null
                      ? daysUntil <= 0
                          ? 'Se espera hoy o ya debió llegar'
                          : 'En $daysUntil días · ${nextDate.day} ${months[nextDate.month]}'
                      : 'Registra al menos 2 periodos para predicciones',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // LEYENDA
  // ═══════════════════════════════════════════
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Leyenda',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem(_periodColor, 'Periodo'),
              _buildLegendItem(_predictedColor, 'Predicción'),
              _buildLegendItem(_ovulationColor, 'Ovulación'),
              _buildLegendItem(_heartColor, '💜 Corazón'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // HISTORIAL DE CICLOS
  // ═══════════════════════════════════════════
  Widget _buildCycleHistory() {
    final data = _data ?? MenstrualData();
    if (data.cycles.isEmpty) return const SizedBox();

    final sorted = List<MenstrualCycle>.from(data.cycles)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    const months = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Historial de ciclos',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Ciclo promedio: ${data.averageCycleLength} días',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...sorted.map((cycle) {
            final endStr = cycle.endDate != null
                ? '${cycle.endDate!.day} ${months[cycle.endDate!.month]}'
                : 'En curso';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _periodColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('🩸', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cycle.startDate.day} ${months[cycle.startDate.month]} ${cycle.startDate.year} → $endStr',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${cycle.durationDays} días',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _service.deleteCycle(cycle.id),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.coral.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.coral, size: 16),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
