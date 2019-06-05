// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "secp256k1",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "secp256k1",
            targets: ["secp256k1"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "libsecp256k1",
            path: "./secp256k1/Classes",
            exclude: [
                "secp256k1/build-aux",
                "secp256k1/obj",
                "secp256k1/sage",
                "secp256k1/src/asm",
                "secp256k1/src/java",
                "secp256k1/src/testrand_impl.h",
                "secp256k1/src/testrand.h",
                "secp256k1/src/tests_exhaustive.c",
                "secp256k1/src/tests.c",
                "secp256k1/src/gen_context.c",
                "secp256k1/src/bench_ecdh.c",
                "secp256k1/src/bench_ecmult.c",
                "secp256k1/src/bench_internal.c",
                "secp256k1/src/bench_recover.c",
                "secp256k1/src/bench_sign.c",
                "secp256k1/src/bench_verify.c",
                "secp256k1/src/bench.h",
                "secp256k1/src/modules/ecdh/tests_impl.h",
                "secp256k1/src/modules/recovery/tests_impl.h",

                "exporter"
            ],
            sources: [
                ".",
                "secp256k1/src",
                "secp256k1/include",
                "secp256k1/contrib",
                "secp256k1/modules/ecdh",
                "secp256k1/modules/recovery"
            ],
            publicHeadersPath: "secp256k1/include"),
        .target(
            name: "secp256k1",
            dependencies: ["libsecp256k1"],
            path: "./secp256k1/Classes/exporter",
            sources: ["."])
    ]
)
