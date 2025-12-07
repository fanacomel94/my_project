import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart' as dart_crypto;

/// CryptoManager: secure key management and crypto primitives using the
/// `cryptography` package.
///
/// - X25519 for ECDH key agreement
/// - Ed25519 for signatures
/// - HKDF-SHA256 for key derivation
/// - AES-GCM for authenticated encryption
class CryptoManager {
  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  // Storage keys
  static const _x25519PrivateKeyKey = 'wa_shield_x25519_private_key';
  static const _x25519PublicKeyKey = 'wa_shield_x25519_public_key';
  static const _ed25519PrivateKeyKey = 'wa_shield_ed25519_private_key';
  static const _ed25519PublicKeyKey = 'wa_shield_ed25519_public_key';

  // Algorithms
  static final X25519 _x25519 = X25519();
  static final Ed25519 _ed25519 = Ed25519();
  static final AesGcm _aesGcm = AesGcm.with256bits();

  // Simple HKDF-SHA256 implementation (extract-and-expand) using package:crypto
  static Uint8List _hkdfSha256(
    Uint8List ikm,
    List<int> info,
    int length, [
    List<int>? salt,
  ]) {
    final saltBytes = salt ?? List<int>.filled(32, 0);
    final prk = dart_crypto.Hmac(
      dart_crypto.sha256,
      saltBytes,
    ).convert(ikm).bytes;
    // Expand: info || 0x01
    final hmac = dart_crypto.Hmac(dart_crypto.sha256, prk);
    final t = hmac.convert([...info, 0x01]).bytes;
    if (length <= t.length) {
      return Uint8List.fromList(t.sublist(0, length));
    }
    // For simplicity we only support output up to hash length (32 bytes)
    throw Exception('Requested HKDF length too large');
  }

  /// Generate a new X25519 (agreement) and Ed25519 (signing) key pair,
  /// persist them into secure storage and return the public keys in Base64.
  static Future<Map<String, String>> generateAndStoreKeyPairs() async {
    // X25519 key pair
    final xKeyPair = await _x25519.newKeyPair();
    final xPairData = await xKeyPair.extract();
    final xPrivate = xPairData.bytes; // private key seed/bytes
    final xPublic = xPairData.publicKey.bytes;

    // Ed25519 key pair (for signing)
    final edKeyPair = await _ed25519.newKeyPair();
    final edPairData = await edKeyPair.extract();
    final edPrivate = edPairData.bytes;
    final edPublic = edPairData.publicKey.bytes;

    // Store keys (private keys only in secure storage)
    await _secureStorage.write(
      key: _x25519PrivateKeyKey,
      value: base64Encode(xPrivate),
    );
    await _secureStorage.write(
      key: _x25519PublicKeyKey,
      value: base64Encode(xPublic),
    );
    await _secureStorage.write(
      key: _ed25519PrivateKeyKey,
      value: base64Encode(edPrivate),
    );
    await _secureStorage.write(
      key: _ed25519PublicKeyKey,
      value: base64Encode(edPublic),
    );

    return {
      'x25519_public': base64Encode(xPublic),
      'ed25519_public': base64Encode(edPublic),
    };
  }

  /// Load stored X25519 private key bytes (if present)
  static Future<Uint8List?> _loadX25519PrivateKeyBytes() async {
    final s = await _secureStorage.read(key: _x25519PrivateKeyKey);
    if (s == null) return null;
    return Uint8List.fromList(base64Decode(s));
  }

  /// Validate public key Base64 (length and format). Returns true if valid.
  static bool validatePublicKey(String publicKeyBase64) {
    try {
      final bytes = base64Decode(publicKeyBase64);
      // X25519 and Ed25519 public keys are 32 bytes
      if (bytes.length != 32) return false;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Rotate keys: generate new pairs and replace stored keys.
  /// Returns the new public keys so that contacts may be notified out-of-band.
  static Future<Map<String, String>> rotateKeys() async {
    // Generate and store new pairs
    final newPubs = await generateAndStoreKeyPairs();
    // TODO: Notify contacts via your app logic (out-of-band)
    return newPubs;
  }

  /// Compute shared secret with our stored X25519 private key and the
  /// provided peer public key (Base64). Returns the derived AES-256 key
  /// (Base64) derived via HKDF-SHA256.
  static Future<String> computeSharedSecretAesKeyBase64(
    String theirPublicKeyBase64,
  ) async {
    final myPrivateBytes = await _loadX25519PrivateKeyBytes();
    if (myPrivateBytes == null) {
      throw Exception(
        'Local X25519 private key not found. Generate keys first.',
      );
    }

    final theirPublicBytes = base64Decode(theirPublicKeyBase64);
    if (theirPublicBytes.length != 32) {
      throw Exception('Invalid peer public key length');
    }

    final myPublicBase64 = await _secureStorage.read(key: _x25519PublicKeyKey);
    if (myPublicBase64 == null) {
      throw Exception('Local X25519 public key not found');
    }
    final myPublicBytes = base64Decode(myPublicBase64);
    final myKeyPair = SimpleKeyPairData(
      myPrivateBytes,
      publicKey: SimplePublicKey(myPublicBytes, type: KeyPairType.x25519),
      type: KeyPairType.x25519,
    );
    final theirPublic = SimplePublicKey(
      theirPublicBytes,
      type: KeyPairType.x25519,
    );

    // ECDH shared secret
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: myKeyPair,
      remotePublicKey: theirPublic,
    );

    // Extract shared secret bytes
    final sharedBytes = await sharedSecret.extractBytes();
    final derivedBytes = _hkdfSha256(
      Uint8List.fromList(sharedBytes),
      utf8.encode('WA-Shield AES-256-GCM key'),
      32,
    );
    return base64Encode(derivedBytes);
  }

  /// Derive a confirmation key (different context) from a shared secret
  /// (sharedSecret is Base64 raw secret bytes or base64 of HKDF input). This
  /// uses HKDF with a different info string so it produces a distinct key.
  static Future<String> deriveConfirmationKey(String sharedSecretBase64) async {
    final secretBytes = base64Decode(sharedSecretBase64);
    final derivedBytes = _hkdfSha256(
      Uint8List.fromList(secretBytes),
      utf8.encode('WA-Shield confirmation key'),
      32,
    );
    return base64Encode(derivedBytes);
  }

  /// Encrypt a message using AES-256-GCM. `aesKeyBase64` must be 32-byte key.
  /// Returns payload formatted as base64(JSON) with fields: iv, ciphertext, tag.
  static Future<String> encryptAES256GCM(
    String message,
    String aesKeyBase64,
  ) async {
    final keyBytes = base64Decode(aesKeyBase64);
    if (keyBytes.length != 32) throw Exception('AES key must be 32 bytes');

    final secretKey = SecretKey(keyBytes);
    final nonce = _aesGcm.newNonce();
    final messageBytes = utf8.encode(message);
    final secretBox = await _aesGcm.encrypt(
      messageBytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    // secretBox contains ciphertext and MAC (tag) internally; we serialize
    final payload = jsonEncode({
      'iv': base64Encode(nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'tag': base64Encode(secretBox.mac.bytes),
    });
    return base64Encode(utf8.encode(payload));
  }

  /// Decrypt a payload produced by `encryptAES256GCM`.
  static Future<String> decryptAES256GCM(
    String payloadBase64,
    String aesKeyBase64,
  ) async {
    try {
      final keyBytes = base64Decode(aesKeyBase64);
      if (keyBytes.length != 32) throw Exception('AES key must be 32 bytes');

      final secretKey = SecretKey(keyBytes);
      final payloadJson = utf8.decode(base64Decode(payloadBase64));
      final Map<String, dynamic> parsed = jsonDecode(payloadJson);

      final iv = base64Decode(parsed['iv'] as String);
      final ciphertext = base64Decode(parsed['ciphertext'] as String);
      final tag = base64Decode(parsed['tag'] as String);

      // Reconstruct SecretBox accepted by AesGcm
      final secretBox = SecretBox(ciphertext, nonce: iv, mac: Mac(tag));

      final clear = await _aesGcm.decrypt(secretBox, secretKey: secretKey);
      return utf8.decode(clear);
    } catch (e) {
      return 'Error: Decryption failed';
    }
  }

  /// Sign a message using stored Ed25519 private key. Returns signature Base64.
  static Future<String> signMessage(String message) async {
    final stored = await _secureStorage.read(key: _ed25519PrivateKeyKey);
    if (stored == null) throw Exception('Ed25519 private key not found');
    final privateBytes = base64Decode(stored);
    final edPublicBase64 = await _secureStorage.read(key: _ed25519PublicKeyKey);
    if (edPublicBase64 == null) throw Exception('Ed25519 public key not found');
    final edPublicBytes = base64Decode(edPublicBase64);
    final keyPair = SimpleKeyPairData(
      privateBytes,
      publicKey: SimplePublicKey(edPublicBytes, type: KeyPairType.ed25519),
      type: KeyPairType.ed25519,
    );
    final signature = await _ed25519.sign(
      utf8.encode(message),
      keyPair: keyPair,
    );
    return base64Encode(signature.bytes);
  }

  /// Verify an Ed25519 signature. `signatureBase64` is base64 of the signature.
  static Future<bool> verifySignature(
    String message,
    String signatureBase64,
    String publicKeyBase64,
  ) async {
    try {
      final signatureBytes = base64Decode(signatureBase64);
      final publicBytes = base64Decode(publicKeyBase64);
      final publicKey = SimplePublicKey(publicBytes, type: KeyPairType.ed25519);
      final sig = Signature(signatureBytes, publicKey: publicKey);
      return await _ed25519.verify(utf8.encode(message), signature: sig);
    } catch (e) {
      return false;
    }
  }

  /// Helper API: read stored public keys
  static Future<Map<String, String?>> getStoredPublicKeys() async {
    final x = await _secureStorage.read(key: _x25519PublicKeyKey);
    final ed = await _secureStorage.read(key: _ed25519PublicKeyKey);
    return {'x25519_public': x, 'ed25519_public': ed};
  }

  /// Ensure keys exist (generate if missing)
  static Future<void> ensureKeysExist() async {
    final pubs = await getStoredPublicKeys();
    if (pubs['x25519_public'] == null || pubs['ed25519_public'] == null) {
      await generateAndStoreKeyPairs();
    }
  }
}
