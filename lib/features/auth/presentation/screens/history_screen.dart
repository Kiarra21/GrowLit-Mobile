import 'package:flutter/material.dart';
import 'package:growlit_mobile/theme/colors.dart';

class _HistoryDay {
  const _HistoryDay({
    required this.date,
    required this.day,
    required this.time,
    required this.waterLevel,
    required this.waterStatus,
    required this.lightLevel,
    required this.lightStatus,
    required this.controlNote,
  });

  final String date;
  final String day;
  final String time;
  final String waterLevel;
  final String waterStatus;
  final String lightLevel;
  final String lightStatus;
  final String controlNote;
}

const List<_HistoryDay> _kWeeklyHistory = [
  _HistoryDay(
    date: '05/05/2026',
    day: 'Senin',
    time: '23:59',
    waterLevel: '12 cm',
    waterStatus: 'Cukup',
    lightLevel: '1850 lx',
    lightStatus: 'Berlebih',
    controlNote: 'Lampu ON',
  ),
  _HistoryDay(
    date: '06/05/2026',
    day: 'Selasa',
    time: '23:59',
    waterLevel: '10 cm',
    waterStatus: 'Cukup',
    lightLevel: '1620 lx',
    lightStatus: 'Cukup',
    controlNote: 'Normal',
  ),
  _HistoryDay(
    date: '07/05/2026',
    day: 'Rabu',
    time: '23:59',
    waterLevel: '8 cm',
    waterStatus: 'Rendah',
    lightLevel: '1480 lx',
    lightStatus: 'Cukup',
    controlNote: 'Pompa ON',
  ),
  _HistoryDay(
    date: '08/05/2026',
    day: 'Kamis',
    time: '23:59',
    waterLevel: '13 cm',
    waterStatus: 'Cukup',
    lightLevel: '1750 lx',
    lightStatus: 'Cukup',
    controlNote: 'Normal',
  ),
  _HistoryDay(
    date: '09/05/2026',
    day: 'Jumat',
    time: '23:59',
    waterLevel: '7 cm',
    waterStatus: 'Rendah',
    lightLevel: '1390 lx',
    lightStatus: 'Kurang',
    controlNote: 'Pompa ON, Lampu ON',
  ),
  _HistoryDay(
    date: '10/05/2026',
    day: 'Sabtu',
    time: '23:59',
    waterLevel: '11 cm',
    waterStatus: 'Cukup',
    lightLevel: '1690 lx',
    lightStatus: 'Cukup',
    controlNote: 'Normal',
  ),
  _HistoryDay(
    date: '11/05/2026',
    day: 'Minggu',
    time: '23:59',
    waterLevel: '9 cm',
    waterStatus: 'Rendah',
    lightLevel: '1510 lx',
    lightStatus: 'Cukup',
    controlNote: 'Reset mingguan',
  ),
];

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F9F3),
              Color(0xFFEAF3BE),
              AppColors.lightGreen,
            ],
            stops: [0.0, 0.36, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'History',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            color: AppColors.darkGreen,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkGreen.withValues(alpha: 0.10),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Snapshot 23.59 / 7 Hari Terakhir',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.darkGreen,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.resedaGreen,
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                elevation: 0,
                              ),
                              child: const Text('Export'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Yang ditampilkan adalah data terakhir tiap hari pada pukul 23.59.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.darkGreen.withValues(
                                  alpha: 0.60,
                                ),
                              ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Table(
                            border: TableBorder.all(
                              color: AppColors.resedaGreen.withValues(
                                alpha: 0.18,
                              ),
                            ),
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            columnWidths: const {
                              0: FixedColumnWidth(82),
                              1: FixedColumnWidth(56),
                              2: FixedColumnWidth(56),
                              3: FixedColumnWidth(60),
                              4: FixedColumnWidth(72),
                              5: FixedColumnWidth(62),
                              6: FixedColumnWidth(82),
                              7: FixedColumnWidth(94),
                            },
                            children: [
                              const TableRow(
                                decoration: BoxDecoration(
                                  color: Color(0xFFF4F8EA),
                                ),
                                children: [
                                  _TableCell(text: 'Tanggal', isHeader: true),
                                  _TableCell(text: 'Hari', isHeader: true),
                                  _TableCell(text: 'Waktu', isHeader: true),
                                  _TableCell(text: 'Air', isHeader: true),
                                  _TableCell(
                                    text: 'Status Air',
                                    isHeader: true,
                                  ),
                                  _TableCell(text: 'Cahaya', isHeader: true),
                                  _TableCell(
                                    text: 'Status Cahaya',
                                    isHeader: true,
                                  ),
                                  _TableCell(text: 'Kontrol', isHeader: true),
                                ],
                              ),
                              ..._kWeeklyHistory.map(
                                (item) => TableRow(
                                  children: [
                                    _TableCell(text: item.date),
                                    _TableCell(text: item.day),
                                    _TableCell(text: item.time),
                                    _TableCell(text: item.waterLevel),
                                    _StatusTableCell(text: item.waterStatus),
                                    _TableCell(text: item.lightLevel),
                                    _StatusTableCell(text: item.lightStatus),
                                    _TableCell(text: item.controlNote),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({required this.text, this.isHeader = false});

  final String text;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.darkGreen,
          fontSize: isHeader ? 9.5 : 9,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _StatusTableCell extends StatelessWidget {
  const _StatusTableCell({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (text) {
      'Cukup' => const Color(0xFFE8F5D8),
      'Rendah' => const Color(0xFFFFE9C9),
      'Kurang' => const Color(0xFFFFE1E1),
      'Berlebih' => const Color(0xFFD9F0C5),
      _ => const Color(0xFFF0F0F0),
    };

    final textColor = switch (text) {
      'Cukup' => const Color(0xFF4E7A23),
      'Rendah' => const Color(0xFF9A6500),
      'Kurang' => const Color(0xFFB23B3B),
      'Berlebih' => const Color(0xFF3F6D1C),
      _ => AppColors.darkGreen,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
