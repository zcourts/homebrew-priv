require 'formula'

class Asciinema < Formula
  homepage 'http://asciinema.org'
  url 'https://github.com/asciinema/asciinema-cli/archive/v0.9.8.tar.gz'
  sha1 'd374ffebe81cc43bf9d07380836302981d249b73'

  depends_on :python

  def install
    system 'make', 'install', "PREFIX=#{prefix}"
  end
end
