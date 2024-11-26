// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "S256Wrapper",
    platforms: [
        .iOS(.v13), .macOS(.v12) // 根据需求设置最低版本
    ],
    products: [
        .library(
            name: "S256Wrapper",
            targets: ["S256Wrapper"]
        )
    ],
    targets: [
        .target(
            name: "S256Wrapper",
            dependencies: ["secp256k1"]
        ),
        .testTarget(
            name: "S256WrapperTests",
            dependencies: ["S256Wrapper"]
        ),
        .target(
          name: "secp256k1",
          path: "Sources/secp256k1",
          publicHeadersPath: "include",
          cSettings: [
              .headerSearchPath("include"),
          ],
          linkerSettings: [
              .linkedLibrary("secp256k1"),
              .unsafeFlags(["-L../Sources", "-lsecp256k1"], .when(platforms: [.macOS, .iOS]))
          ]
        )
    ]
)

