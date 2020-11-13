{
  description = "TODO(akavel)";

  outputs = { self, nixpkgs }: {

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.all;

    packages.x86_64-linux.all =
      # TODO(akavel): reuse code here and in default.nix
      with import nixpkgs { system = "x86_64-linux"; };
      stdenv.mkDerivation rec {
        name = "arcan";
        version="1";
        src = ./.;
        nativeBuildInputs = with pkgs; [
          cmake git
        ] ;
        CMAKE_CXX_FLAGS = "-msse4.1";
        DRM_INCLUDE_DIR = "${pkgs.libdrm.dev}/include/libdrm";
        buildInputs = with pkgs; [
          freetype openal sqlite mesa_noglu libGL SDL2 libdrm.dev
          lua51Packages.lua libusb ffmpeg libxkbcommon
          lzma vlc apr harfbuzz
        ] ;

        preConfigurePhases = ["noSuidInstall"];

        noSuidInstall = ''
          rm -rf build
          mkdir -p build
          sed -i 's/SETUID//g' src/CMakeLists.txt 
        '';

        cmakeFlags = builtins.concatStringsSep " " [
          "-DENABLE_SIMD=Off"
          "-DDRM_INCLUDE_DIR=${DRM_INCLUDE_DIR}"
          "-DVIDEO_PLATFORM=egl-dri"
          "-DHYBRID_SDL=On"  # "Produce an arcan_sdl main binary as well"
          "../src"
        ];
        #  makeFlags="-C build";


        hardeningDisable = [ "all" ];
      };

  };
}
