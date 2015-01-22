class Ttcp < Formula
  homepage "http://www.pcausa.com/Utilities/pcattcp.htm"
  url "http://www.pcausa.com/Utilities/pcattcp/UnixTTCP.zip"
  sha1 "a8bf785174d20517298ad85f0f5a8166525cac93"
  version "1.12"

  def install
    inreplace "makefile", "gcc", "#{ENV.cc} #{ENV.cflags}"

    system "make", "ttcp"
    bin.install "ttcp"
  end

  test do
    #
  end
end
