import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Local, on-device accounts (the same model as Atlas's lock screen): the password never
/// leaves the device and is stored only as a salted PBKDF2-HMAC-SHA256 hash.
class Account {
  const Account({required this.name, required this.email, required this.salt, required this.hash});

  final String name;
  final String email;
  final String salt;
  final String hash;

  Account copyWith({String? name}) => Account(name: name ?? this.name, email: email, salt: salt, hash: hash);

  Map<String, dynamic> toJson() => {'name': name, 'email': email, 'salt': salt, 'hash': hash};

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        name: j['name'] as String,
        email: j['email'] as String,
        salt: j['salt'] as String,
        hash: j['hash'] as String,
      );
}

const _iterations = 20000;

String newSalt() {
  final r = Random.secure();
  return base64Encode(List<int>.generate(16, (_) => r.nextInt(256)));
}

/// Single-block PBKDF2 (32-byte key), enough for a SHA-256 sized hash.
String hashPassword(String password, String salt) {
  final hmac = Hmac(sha256, utf8.encode(password));
  final block = Uint8List.fromList([...base64Decode(salt), 0, 0, 0, 1]);
  var u = hmac.convert(block).bytes;
  final out = Uint8List.fromList(u);
  for (var i = 1; i < _iterations; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < out.length; j++) {
      out[j] ^= u[j];
    }
  }
  return base64Encode(out);
}

bool verifyPassword(Account a, String password) {
  final h = hashPassword(password, a.salt);
  // Constant-time compare.
  if (h.length != a.hash.length) return false;
  var diff = 0;
  for (var i = 0; i < h.length; i++) {
    diff |= h.codeUnitAt(i) ^ a.hash.codeUnitAt(i);
  }
  return diff == 0;
}

String normaliseEmail(String email) => email.trim().toLowerCase();

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
bool isValidEmail(String email) => _emailRe.hasMatch(email.trim());
