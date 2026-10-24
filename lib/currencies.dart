import 'dart:ui';

class CurrencyInfo {
  const CurrencyInfo(this.code, this.name);
  final String code;
  final String name;
}

/// ISO 4217 codes people actually spend in, most common first-ish, then alphabetical.
const allCurrencies = [
  CurrencyInfo('INR', 'Indian Rupee'),
  CurrencyInfo('USD', 'US Dollar'),
  CurrencyInfo('EUR', 'Euro'),
  CurrencyInfo('GBP', 'British Pound'),
  CurrencyInfo('AED', 'UAE Dirham'),
  CurrencyInfo('ARS', 'Argentine Peso'),
  CurrencyInfo('AUD', 'Australian Dollar'),
  CurrencyInfo('BDT', 'Bangladeshi Taka'),
  CurrencyInfo('BRL', 'Brazilian Real'),
  CurrencyInfo('CAD', 'Canadian Dollar'),
  CurrencyInfo('CHF', 'Swiss Franc'),
  CurrencyInfo('CLP', 'Chilean Peso'),
  CurrencyInfo('CNY', 'Chinese Yuan'),
  CurrencyInfo('COP', 'Colombian Peso'),
  CurrencyInfo('CZK', 'Czech Koruna'),
  CurrencyInfo('DKK', 'Danish Krone'),
  CurrencyInfo('EGP', 'Egyptian Pound'),
  CurrencyInfo('HKD', 'Hong Kong Dollar'),
  CurrencyInfo('HUF', 'Hungarian Forint'),
  CurrencyInfo('IDR', 'Indonesian Rupiah'),
  CurrencyInfo('ILS', 'Israeli Shekel'),
  CurrencyInfo('JPY', 'Japanese Yen'),
  CurrencyInfo('KES', 'Kenyan Shilling'),
  CurrencyInfo('KRW', 'South Korean Won'),
  CurrencyInfo('KWD', 'Kuwaiti Dinar'),
  CurrencyInfo('LKR', 'Sri Lankan Rupee'),
  CurrencyInfo('MXN', 'Mexican Peso'),
  CurrencyInfo('MYR', 'Malaysian Ringgit'),
  CurrencyInfo('NGN', 'Nigerian Naira'),
  CurrencyInfo('NOK', 'Norwegian Krone'),
  CurrencyInfo('NPR', 'Nepalese Rupee'),
  CurrencyInfo('NZD', 'New Zealand Dollar'),
  CurrencyInfo('PHP', 'Philippine Peso'),
  CurrencyInfo('PKR', 'Pakistani Rupee'),
  CurrencyInfo('PLN', 'Polish Zloty'),
  CurrencyInfo('QAR', 'Qatari Riyal'),
  CurrencyInfo('RUB', 'Russian Ruble'),
  CurrencyInfo('SAR', 'Saudi Riyal'),
  CurrencyInfo('SEK', 'Swedish Krona'),
  CurrencyInfo('SGD', 'Singapore Dollar'),
  CurrencyInfo('THB', 'Thai Baht'),
  CurrencyInfo('TRY', 'Turkish Lira'),
  CurrencyInfo('TWD', 'New Taiwan Dollar'),
  CurrencyInfo('UAH', 'Ukrainian Hryvnia'),
  CurrencyInfo('VND', 'Vietnamese Dong'),
  CurrencyInfo('ZAR', 'South African Rand'),
];

/// Currencies whose amounts are conventionally shown without decimals.
const zeroDecimal = {'JPY', 'KRW', 'VND', 'CLP', 'IDR', 'HUF', 'COP'};

const _byRegion = {
  'IN': 'INR', 'US': 'USD', 'GB': 'GBP', 'AE': 'AED', 'AU': 'AUD', 'CA': 'CAD', 'JP': 'JPY',
  'SG': 'SGD', 'BD': 'BDT', 'PK': 'PKR', 'LK': 'LKR', 'NP': 'NPR', 'BR': 'BRL', 'MX': 'MXN',
  'ZA': 'ZAR', 'NG': 'NGN', 'KE': 'KES', 'CN': 'CNY', 'KR': 'KRW', 'SA': 'SAR', 'CH': 'CHF',
  'DE': 'EUR', 'FR': 'EUR', 'ES': 'EUR', 'IT': 'EUR', 'NL': 'EUR', 'IE': 'EUR', 'PT': 'EUR',
};

/// A sensible first suggestion from the device's region (en-IN → INR).
String suggestedCurrency() =>
    _byRegion[PlatformDispatcher.instance.locale.countryCode?.toUpperCase()] ?? 'USD';

CurrencyInfo currencyInfo(String code) =>
    allCurrencies.firstWhere((c) => c.code == code, orElse: () => CurrencyInfo(code, code));
