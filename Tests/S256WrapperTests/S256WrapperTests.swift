import XCTest
@testable import S256Wrapper

final class S256WrapperTests: XCTestCase {
  func test() {
    if let (privateKey, publicKey) = S256Wrapper.generateKeyPair() {
      XCTAssertGreaterThan(privateKey.count, 0)
      XCTAssertGreaterThan(publicKey.count, 0)
      print("Private Key: \(privateKey.map { String(format: "%02x", $0) }.joined())")
      print("Public Key: \(publicKey.map { String(format: "%02x", $0) }.joined())")
    } else {
      XCTFail("Failed to generate key pair.")
      print()
    }
  }
  func testExample() throws {
    // XCTest Documentation
    // https://developer.apple.com/documentation/xctest
    
    // Defining Test Cases and Test Methods
    // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
  }
}
