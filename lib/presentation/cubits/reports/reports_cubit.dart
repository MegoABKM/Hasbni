
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
        
        startDate = DateTime(now.year, now.month, now.day).toUtc();
        
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
        
        startDate = DateTime(weekAgo.year, weekAgo.month, weekAgo.day).toUtc();
        
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
        
        startDate = DateTime(
          monthAgo.year,
          monthAgo.month,
          monthAgo.day,
        ).toUtc();
        
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
        
        startDate = DateTime(now.year, 1, 1).toUtc();
        
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
        
        startDate = state.customStartDate!.toUtc();
        final customEnd = state.customEndDate!;
        
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
      // 1. Fetch Summary
      final summary = await _repository.getFinancialSummary(
        startDate: startDate,
        endDate: endDate,
      );

      // 2. Fetch Diary Entries (NEW)
      final diary = await _repository.getDiaryEntries(
        startDate: startDate,
        endDate: endDate,
      );

      emit(state.copyWith(
        status: ReportsStatus.success, 
        summary: summary,
        diaryEntries: diary, // <--- Emit new data
      ));
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
