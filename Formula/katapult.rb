class Katapult < Formula
  desc "Open any URI scheme from an https link"
  homepage "https://github.com/kelvinst/katapult"
  url "https://github.com/kelvinst/katapult/releases/download/v0.0.0/katapult-0.0.0.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  uses_from_macos "python"

  def install
    bin.install "bin/katapult"
    pkgshare.install "share/katapult/katapult-spoon.lua"
  end

  def caveats
    <<~EOS
      To open Katapult links without the page through Hammerspoon, load the
      spoon from ~/.hammerspoon/init.lua:

        package.path = package.path .. ";#{opt_pkgshare}/?.lua"
        katapult = require("katapult-spoon")

      then make Hammerspoon the default http handler:

        hs -c 'hs.urlevent.setDefaultHandler("http")'
    EOS
  end

  test do
    assert_equal "https://kelvinst.github.io/katapult/#x%3A%2F%2Fy",
      shell_output("#{bin}/katapult x://y").strip
  end
end
