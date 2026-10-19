# OBS Studio, from the upstream Apple-silicon DMG: nixpkgs' obs-studio is
# `platforms = linux`. Hash comes from the Homebrew cask definition.
{
  lib,
  stdenv,
  fetchurl,
  undmg,
}:

stdenv.mkDerivation {
  pname = "obs-studio-bin";
  version = "32.2.2";

  src = fetchurl {
    url = "https://cdn-fastly.obsproject.com/downloads/obs-studio-32.2.2-macos-apple.dmg";
    hash = "sha256-kg1vJnA9LfbkCFvTwcvtMEiDJQhBNsem6eNwIfvWqvc=";
  };

  nativeBuildInputs = [ undmg ];
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -R OBS.app $out/Applications/
    runHook postInstall
  '';

  meta = {
    description = "Video recording and live streaming software";
    homepage = "https://obsproject.com";
    platforms = lib.platforms.darwin;
    mainProgram = "OBS";
  };
}
