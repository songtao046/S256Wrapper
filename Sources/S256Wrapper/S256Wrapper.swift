import Foundation
import secp256k1

public struct S256Wrapper {
  private static let context: OpaquePointer = {
    guard let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY)) else {
      fatalError("Failed to create secp256k1 context")
    }
    return ctx
  }()
  
  public struct KeyPair {
    public let privateKey: [UInt8]
    public let publicKey: [UInt8]
  }
  
  public static func generateKeyPair() -> KeyPair? {
    var privateKey = [UInt8](repeating: 0, count: 32)
    var publicKey = secp256k1_pubkey()

    // Generate random private key
    guard SecRandomCopyBytes(kSecRandomDefault, privateKey.count, &privateKey) == errSecSuccess else {
      return nil
    }
    
    // Validate private key
    guard secp256k1_ec_seckey_verify(context, privateKey) == 1 else {
      return nil // Invalid private key
    }
    
    // Generate public key
    guard secp256k1_ec_pubkey_create(context, &publicKey, privateKey) == 1 else {
      return nil
    }
    
    // Serialize public key
    let uncompressedPublicKeyLength = 65
    var serializedPublicKey = [UInt8](repeating: 0, count: uncompressedPublicKeyLength)
    var outputLength = uncompressedPublicKeyLength
    secp256k1_ec_pubkey_serialize(context, &serializedPublicKey, &outputLength, &publicKey, UInt32(SECP256K1_EC_COMPRESSED))
    
    // Securely clear private key memory
    defer {
      privateKey.replaceSubrange(0..<privateKey.count, with: repeatElement(0, count: privateKey.count))
    }
    
    return KeyPair(privateKey: privateKey, publicKey: serializedPublicKey)
  }
  
  /// Sign a message using the private key
  public static func signRaw(privateKey: [UInt8], message: [UInt8]) -> [UInt8]? {
    var signature = secp256k1_ecdsa_signature()
    
    // Sign the message
    guard secp256k1_ecdsa_sign(context, &signature, message, privateKey, nil, nil) == 1 else {
      return nil
    }
    
    // Serialize signature in compact (raw) format
    var rawSignature = [UInt8](repeating: 0, count: 64)
    secp256k1_ecdsa_signature_serialize_compact(context, &rawSignature, &signature)
    
    return rawSignature
  }
  
  
  public static func signDER(privateKey: [UInt8], message: [UInt8]) -> [UInt8]? {
    var signature = secp256k1_ecdsa_signature()
    
    // Sign the message
    guard secp256k1_ecdsa_sign(context, &signature, message, privateKey, nil, nil) == 1 else {
      return nil
    }
    
    // Serialize signature in DER format
    var derSignature = [UInt8](repeating: 0, count: 72) // Maximum DER signature size
    var outputLength = derSignature.count
    guard secp256k1_ecdsa_signature_serialize_der(context, &derSignature, &outputLength, &signature) == 1 else {
      return nil
    }
    
    // Trim DER signature to actual size
    return Array(derSignature.prefix(outputLength))
  }
  
  
  /// Verify a signature
  public static func verifySignature(publicKey: [UInt8], message: [UInt8], signature: [UInt8]) -> Bool {
    var pubkey = secp256k1_pubkey()
    var sig = secp256k1_ecdsa_signature()
    
    // Parse the public key
    guard secp256k1_ec_pubkey_parse(context, &pubkey, publicKey, publicKey.count) == 1 else {
      return false
    }
    
    // Parse the signature
    guard secp256k1_ecdsa_signature_parse_compact(context, &sig, signature) == 1 else {
      return false
    }
    
    // Verify the signature
    return secp256k1_ecdsa_verify(context, &sig, message, &pubkey) == 1
  }
  
  /// 验证私钥
  public static func isValidPrivateKey(_ privateKey: [UInt8]) -> Bool {
    return secp256k1_ec_seckey_verify(context, privateKey) == 1
  }
  
  /// 验证公钥
  public static func isValidPublicKey(_ publicKey: [UInt8]) -> Bool {
    var pubkey = secp256k1_pubkey()
    return secp256k1_ec_pubkey_parse(context, &pubkey, publicKey, publicKey.count) == 1
  }
  
  /// 将私钥转换为公钥
  public static func privateKeyToPublicKey(_ privateKey: [UInt8]) -> [UInt8]? {
    guard isValidPrivateKey(privateKey) else { return nil }
    
    var pubkey = secp256k1_pubkey()
    guard secp256k1_ec_pubkey_create(context, &pubkey, privateKey) == 1 else { return nil }
    
    // 默认生成压缩格式公钥
    let compressedPublicKeyLength = 33
    var publicKey = [UInt8](repeating: 0, count: compressedPublicKeyLength)
    var outputLength = compressedPublicKeyLength
    secp256k1_ec_pubkey_serialize(context, &publicKey, &outputLength, &pubkey, UInt32(SECP256K1_EC_COMPRESSED))
    
    return publicKey
  }
  
  /// 转换公钥为压缩/非压缩格式
  public static func convertPublicKeyFormat(_ publicKey: [UInt8], toCompressed: Bool) -> [UInt8]? {
    guard isValidPublicKey(publicKey) else { return nil }
    
    var pubkey = secp256k1_pubkey()
    guard secp256k1_ec_pubkey_parse(context, &pubkey, publicKey, publicKey.count) == 1 else { return nil }
    
    var outputLength = toCompressed ? 33 : 65
    var formattedPublicKey = [UInt8](repeating: 0, count: outputLength)
    secp256k1_ec_pubkey_serialize(context, &formattedPublicKey, &outputLength, &pubkey, toCompressed ? UInt32(SECP256K1_EC_COMPRESSED) : UInt32(SECP256K1_EC_UNCOMPRESSED))
    
    return formattedPublicKey
  }
}
