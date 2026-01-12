import 'package:equatable/equatable.dart';
import 'package:hasbni/data/models/exchange_rate_model.dart';

class Profile extends Equatable {
  final int id; // <--- CHANGED: String -> int
  final String shopName;
  final String? address;
  final String? phoneNumber;
  final String? city;
  final List<ExchangeRate> exchangeRates;
  final bool hasManagerPassword; // Added to match API response

  const Profile({
    required this.id,
    required this.shopName,
    this.address,
    this.phoneNumber,
    this.city,
    this.exchangeRates = const [],
    this.hasManagerPassword = false,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    var rates = <ExchangeRate>[];
    if (json['exchange_rates'] != null) {
      rates = (json['exchange_rates'] as List)
          .map((rateJson) => ExchangeRate.fromJson(rateJson))
          .toList();
    }
    return Profile(
      id: json['id'], // Now correctly accepts the int (e.g., 4) from Laravel
      shopName: json['shop_name'] ?? '',
      address: json['address'],
      phoneNumber: json['phone_number'],
      city: json['city'],
      exchangeRates: rates,
      // Laravel boolean field might come as 1/0 or true/false
      hasManagerPassword: json['has_manager_password'] == true || json['has_manager_password'] == 1,
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
    hasManagerPassword,
  ];
}