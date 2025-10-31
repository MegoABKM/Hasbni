
import 'package:equatable/equatable.dart';
import 'package:hasbni/data/models/financial_summary_model.dart';

enum ReportsStatus { initial, loading, success, failure }

enum TimePeriod { today, week, month, year, custom }

class ReportsState extends Equatable {
  final ReportsStatus status;
  final FinancialSummary summary; 
  final TimePeriod selectedPeriod;
  final String? errorMessage;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  
  ReportsState({
    this.status = ReportsStatus.initial,
    FinancialSummary? summary, 
    this.selectedPeriod = TimePeriod.month,
    this.errorMessage,
    this.customStartDate,
    this.customEndDate,
    
  }) : summary = summary ?? FinancialSummary.empty();

  ReportsState copyWith({
    ReportsStatus? status,
    FinancialSummary? summary,
    TimePeriod? selectedPeriod,
    String? errorMessage,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    return ReportsState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      errorMessage: errorMessage,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
    );
  }

  @override
  List<Object?> get props => [
    status,
    summary,
    selectedPeriod,
    errorMessage,
    customStartDate,
    customEndDate,
  ];
}
