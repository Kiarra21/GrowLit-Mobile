import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:growlit_mobile/theme/colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatValue(dynamic value) {
    if (value == null) return '-';
    if (value is bool) return value ? 'ON' : 'OFF';
    if (value is num) {
      if (value is int) return value.toString();
      return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
    }
    return value.toString();
  }

  Future<void> _exportHistoryToExcel(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final query = await FirebaseFirestore.instance
          .collection('history')
          .orderBy('recordedAt', descending: false)
          .get();

      if (query.docs.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Belum ada data history untuk diexport.'),
          ),
        );
        return;
      }

      final excel = Excel.createExcel();
      final sheet = excel[excel.tables.keys.first];
      sheet.appendRow([
        TextCellValue('Tanggal'),
        TextCellValue('Waktu'),
        TextCellValue('LDR'),
        TextCellValue('Jarak'),
        TextCellValue('Lampu'),
        TextCellValue('Pompa'),
      ]);

      for (final doc in query.docs) {
        final data = doc.data();
        final recordedAtRaw = data['recordedAt'];
        final recordedAt = recordedAtRaw is Timestamp
            ? recordedAtRaw.toDate()
            : DateTime.now();

        sheet.appendRow([
          TextCellValue(
            '${_twoDigits(recordedAt.day)}/${_twoDigits(recordedAt.month)}/${recordedAt.year}',
          ),
          TextCellValue(
            '${_twoDigits(recordedAt.hour)}:${_twoDigits(recordedAt.minute)}',
          ),
          TextCellValue(_formatValue(data['ldr'])),
          TextCellValue(_formatValue(data['jarak'])),
          TextCellValue(_formatValue(data['lampu'])),
          TextCellValue(_formatValue(data['pompa'])),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) {
        throw StateError('Gagal membuat file Excel.');
      }

      final directory = await getTemporaryDirectory();
      final fileName =
          'growlit_history_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${directory.path}${Platform.pathSeparator}$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Export history GrowLit'),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal export Excel: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyStream = FirebaseFirestore.instance
        .collection('history')
        .orderBy('recordedAt', descending: true)
        .snapshots();

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'History Time Series',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.darkGreen,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Container(
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
                              'History Time Series',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.darkGreen,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            ElevatedButton(
                              onPressed: () => _exportHistoryToExcel(context),
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
                              child: const Text('Export Excel'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(height: 12),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: historyStream,
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Gagal memuat history: ${snapshot.error}',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.redAccent),
                                  ),
                                );
                              }

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final docs = snapshot.data?.docs ?? [];
                              if (docs.isEmpty) {
                                return Center(
                                  child: Text(
                                    'Belum ada data history.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppColors.darkGreen),
                                  ),
                                );
                              }

                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  child: Table(
                                    border: TableBorder.all(
                                      color: AppColors.resedaGreen.withValues(
                                        alpha: 0.18,
                                      ),
                                    ),
                                    defaultVerticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                    columnWidths: const {
                                      0: FixedColumnWidth(108),
                                      1: FixedColumnWidth(92),
                                      2: FixedColumnWidth(76),
                                      3: FixedColumnWidth(76),
                                      4: FixedColumnWidth(76),
                                      5: FixedColumnWidth(76),
                                    },
                                    children: [
                                      const TableRow(
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF4F8EA),
                                        ),
                                        children: [
                                          _TableCell(
                                            text: 'Tanggal',
                                            isHeader: true,
                                          ),
                                          _TableCell(
                                            text: 'Waktu',
                                            isHeader: true,
                                          ),
                                          _TableCell(
                                            text: 'LDR',
                                            isHeader: true,
                                          ),
                                          _TableCell(
                                            text: 'Jarak',
                                            isHeader: true,
                                          ),
                                          _TableCell(
                                            text: 'Lampu',
                                            isHeader: true,
                                          ),
                                          _TableCell(
                                            text: 'Pompa',
                                            isHeader: true,
                                          ),
                                        ],
                                      ),
                                      ...docs.map((doc) {
                                        final data = doc.data();
                                        final recordedAtRaw =
                                            data['recordedAt'];
                                        final recordedAt =
                                            recordedAtRaw is Timestamp
                                            ? recordedAtRaw.toDate()
                                            : DateTime.now();
                                        return TableRow(
                                          children: [
                                            _TableCell(
                                              text:
                                                  '${_twoDigits(recordedAt.day)}/${_twoDigits(recordedAt.month)}/${recordedAt.year}',
                                            ),
                                            _TableCell(
                                              text:
                                                  '${_twoDigits(recordedAt.hour)}:${_twoDigits(recordedAt.minute)}',
                                            ),
                                            _TableCell(
                                              text: _formatValue(data['ldr']),
                                            ),
                                            _TableCell(
                                              text: _formatValue(data['jarak']),
                                            ),
                                            _StatusTableCell(
                                              text: _formatValue(data['lampu']),
                                            ),
                                            _StatusTableCell(
                                              text: _formatValue(data['pompa']),
                                            ),
                                          ],
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
    final isOn = text.toUpperCase() == 'ON' || text == 'true';
    final backgroundColor = isOn
        ? const Color(0xFFD9F0C5)
        : const Color(0xFFF0F0F0);
    final textColor = isOn ? const Color(0xFF3F6D1C) : AppColors.darkGreen;

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
