require 'formula'

class Ttcp < Formula
  url 'http://www.pcausa.com/Utilities/pcattcp/UnixTTCP.zip'
  homepage 'http://www.pcausa.com/Utilities/pcattcp.htm'
  md5 '4061bf263cdd6bbccacedcca9b6370aa'
  version '1.12'

  def install
    inreplace "makefile", "gcc", "#{ENV.cc} #{ENV.cflags}"

    system "make ttcp"
    bin.install "ttcp"
  end
end
