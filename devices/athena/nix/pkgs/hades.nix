# ~/Projects/hades, built from the workspace's own Cargo.lock. The `hades`
# binary lives in crates/hades, so only that member is built.
#
# Two things make this heavier than a normal crate: `inkwell` comes from git
# (so it needs an outputHash) and it binds LLVM 21 through llvm-sys 211, which
# wants a single prefix holding bin/llvm-config *and* lib/libLLVM — nixpkgs
# splits those across the dev/lib outputs, hence the symlinkJoin.
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

  # exactly what libLLVM-21 records as its own dependencies
  buildInputs = [
    llvmPrefix
    llvmPackages_21.libclang
    libffi
    zlib
    libxml2
  ];
  LIBCLANG_PATH = "${llvmPackages_21.libclang.lib}/lib";
  LLVM_SYS_211_PREFIX = "${llvmPrefix}";

  # the workspace's tests need services the sandbox has no time for
  doCheck = false;

  meta = {
    description = "Systems programming language with an LLVM backend";
    mainProgram = "hades";
    platforms = lib.platforms.darwin;
  };
}
