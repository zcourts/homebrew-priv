require 'formula'

class Asciinema < Formula
  homepage 'http://asciinema.org'
  url 'https://github.com/asciinema/asciinema-cli/archive/v0.9.8.tar.gz'
  sha1 '9db87a077ff831adb4c993a01838aca750dbb41e'

  depends_on :python

  def install
    system 'make', 'install', "PREFIX=#{prefix}"
  end
end
