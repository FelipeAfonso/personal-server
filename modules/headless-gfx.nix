# No compositor lives here. Agents validate graphical work through:
#   web:   headless chromium (screenshots built in, no display server needed)
#   games: xvfb-run <cmd>, captured with imagemagick `import` or ffmpeg
# A human can paint a GUI onto their own screen with `ssh -X rlyeh chromium`.
{ pkgs, ... }:

{
  # Real GPU acceleration for headless GL (EGL surfaceless / DRM render
  # nodes) — also what a future Sunshine/Moonlight setup would build on.
  hardware.graphics.enable = true;

  # X11 forwarding for the human escape hatch; no X server runs locally.
  services.openssh.settings.X11Forwarding = true;

  environment.systemPackages = with pkgs; [
    chromium
    xvfb-run
    xauth # required for ssh -X
    imagemagick
    ffmpeg
  ];

  # Browsers and games render text server-side; without fonts screenshots
  # come out as tofu.
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    jetbrains-mono
  ];
}
