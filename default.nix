## https://gist.github.com/telent/4a92294a767656759959006fe8440122

with import <nixpkgs> {};
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
    freetype openal sqlite mesa_noglu libGL SDL libdrm.dev
    lua51Packages.lua libusb ffmpeg libxkbcommon
    lzma vlc apr harfbuzz
  ] ;

  preConfigurePhases = ["noSuidInstall"];

  noSuidInstall = ''
    mkdir -p build
    sed -i 's/SETUID//g' src/CMakeLists.txt 
  '';

  cmakeFlags = "-DENABLE_SIMD=Off -DDRM_INCLUDE_DIR=${DRM_INCLUDE_DIR} -DVIDEO_PLATFORM=egl-dri ../src";
#  makeFlags="-C build";


  hardeningDisable = [ "all" ];
}
