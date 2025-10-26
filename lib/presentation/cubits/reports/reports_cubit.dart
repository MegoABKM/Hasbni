// lib/presentation/cubits/reports/reports_cubit.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hasbni/data/repositories/reports_repository.dart';
import 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final ReportsRepository _repository;

  ReportsCubit() : _repository = ReportsRepository(), super(ReportsState());

  Future<void> loadSummary({
    TimePeriod? period,
    DateTimeRange? customDateRange,
  }) async {
    final newPeriod =
        period ??
        (customDateRange != null ? TimePeriod.custom : state.selectedPeriod);

    emit(
      state.copyWith(
        status: ReportsStatus.loading,
        selectedPeriod: newPeriod,
        customStartDate: customDateRange?.start,
        customEndDate: customDateRange?.end,
      ),
    );

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (newPeriod) {
      case TimePeriod.today:
        // Start of today in local time, then converted to UTC
        startDate = DateTime(now.year, now.month, now.day).toUtc();
        // End of today in local time, then converted to UTC
        endDate = DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
          59,
          999,
        ).toUtc();
        break;
      case TimePeriod.week:
        final weekAgo = now.subtract(const Duration(days: 6));
        // Start of 6 days ago in local time, then converted to UTC
        startDate = DateTime(weekAgo.year, weekAgo.month, weekAgo.day).toUtc();
        // End of today in local time, then converted to UTC
        endDate = DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
          59,
          999,
        ).toUtc();
        break;
      case TimePeriod.month:
        final monthAgo = now.subtract(const Duration(days: 29));
        // Start of 29 days ago in local time, then converted to UTC
        startDate = DateTime(
          monthAgo.year,
          monthAgo.month,
          monthAgo.day,
        ).toUtc();
        // End of today in local time, then converted to UTC
        endDate = DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
          59,
          999,
        ).toUtc();
        break;
      case TimePeriod.year:
        // Start of the year in local time, then converted to UTC
        startDate = DateTime(now.year, 1, 1).toUtc();
        // End of today in local time, then converted to UTC
        endDate = DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
          59,
          999,
        ).toUtc();
        break;
      case TimePeriod.custom:
        if (state.customStartDate == null || state.customEndDate == null)
          return;
        // Start of the selected start day, converted to UTC
        startDate = state.customStartDate!.toUtc();
        final customEnd = state.customEndDate!;
        // End of the selected end day, converted to UTC
        endDate = DateTime(
          customEnd.year,
          customEnd.month,
          customEnd.day,
          23,
          59,
          59,
          999,
        ).toUtc();
        break;
    }

    try {
      // The dates are now sent as unambiguous UTC timestamps
      final summary = await _repository.getFinancialSummary(
        startDate: startDate,
        endDate: endDate,
      );
      emit(state.copyWith(status: ReportsStatus.success, summary: summary));
    } catch (e) {
      emit(
        state.copyWith(
          status: ReportsStatus.failure,
          errorMessage: 'فشل تحميل الملخص: $e',
        ),
      );
    }
  }
}
