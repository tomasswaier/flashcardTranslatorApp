{
  description = "Flutter";
  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";
		android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs";
    };
  };
  outputs = { self, nixpkgs-unstable, flake-utils,android-nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs-unstable {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };
        buildToolsVersion = "33.0.2";
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          buildToolsVersions = [ buildToolsVersion ];
          platformVersions = [ "33" ];
          abiVersions = [ "arm64-v8a" ];
        };
        androidSdk = androidComposition.androidsdk;
				androidCustomPackage = android-nixpkgs.sdk.${system} (
          sdkPkgs: with sdkPkgs; [
            cmdline-tools-latest
            build-tools-34-0-0
            platform-tools
            emulator
            platforms-android-34
          ]
        );

				pinnedJDK = pkgs.jdk17;
      in
      {
        devShell =
          with pkgs; mkShell rec {
            ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
            buildInputs = [
              flutter
              androidSdk
              jdk17
							dart
							android-studio
							sqlite
            ]++[
							pinnedJDK
							androidCustomPackage
						];
						JAVA_HOME=pinnedJDK;
						shellHook = ''
					    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${lib.makeLibraryPath [ sqlite ]}"
					  '';


          };
      });
}
