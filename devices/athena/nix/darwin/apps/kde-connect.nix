# KDE Connect, from KDE's own release-service macOS build: nixpkgs'
# kdeconnect-kde is `platforms = linux` (plus freebsd).
{
  lib,
  stdenv,
  fetchurl,
  undmg,
}:

stdenv.mkDerivation {
  pname = "kdeconnect-bin";
  version = "26.08.2";

  src = fetchurl {
    url = "https://download.kde.org/stable/release-service/26.08.2/macos/kdeconnect-kde-macos-clang-arm64.dmg";
    hash = "sha256-HGMo/KNjryKbSLI4cXqxdnR7BrV3FOK7looEHDjO0VM=";
  };

  nativeBuildInputs = [ undmg ];
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -R "KDE Connect.app" $out/Applications/
    runHook postInstall
  '';

  meta = {
    description = "Multi-platform app that allows your devices to communicate";
    homepage = "https://kdeconnect.kde.org";
    platforms = lib.platforms.darwin;
  };
}
