{
  lib,
  rustPlatform,
  symlinkJoin,
  src,
  libffi,
  zlib,
  libxml2,
  llvmPackages_21,
}:

let
  llvm = llvmPackages_21.llvm;
  llvmPrefix = symlinkJoin {
    name = "llvm-${llvm.version}-sys";
    paths = [
      llvm
      llvm.dev
      llvm.lib
    ];
  };
in
rustPlatform.buildRustPackage {
  pname = "hades";
  version = "unstable-2026-10-20";

  inherit src;
  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "inkwell-0.8.0" = "sha256-FHszgwvAo6DIqf6lSrFNdp05Hyp+uHvesCBETx5TEt4=";
    };
  };
  cargoBuildFlags = [
    "-p"
    "hades"
  ];

  buildInputs = [
    llvmPrefix
    llvmPackages_21.libclang
    libffi
    zlib
    libxml2
  ];
  LIBCLANG_PATH = "${llvmPackages_21.libclang.lib}/lib";
  LLVM_SYS_211_PREFIX = "${llvmPrefix}";

  doCheck = false;

  meta = {
    description = "Systems programming language with an LLVM backend";
    mainProgram = "hades";
    platforms = lib.platforms.darwin;
  };
}
