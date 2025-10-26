// lib/data/models/profile_model.dart
import 'package:equatable/equatable.dart';
import 'package:hasbni/data/models/exchange_rate_model.dart';

class Profile extends Equatable {
  final String id;
  final String shopName;
  final String? address;
  final String? phoneNumber;
  final String? city;
  final List<ExchangeRate> exchangeRates;

  const Profile({
    required this.id,
    required this.shopName,
    this.address,
    this.phoneNumber,
    this.city,
    this.exchangeRates = const [],
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    var rates = <ExchangeRate>[];
    if (json['exchange_rates'] != null) {
      rates = (json['exchange_rates'] as List)
          .map((rateJson) => ExchangeRate.fromJson(rateJson))
          .toList();
    }
    return Profile(
      id: json['id'],
      // --- CORRECTION: Provide a default value to prevent crashes ---
      shopName: json['shop_name'] ?? '',
      address: json['address'],
      phoneNumber: json['phone_number'],
      city: json['city'],
      exchangeRates: rates,
    );
  }

  @override
  List<Object?> get props => [
    id,
    shopName,
    address,
    phoneNumber,
    city,
    exchangeRates,
  ];
}
