require 'formula'

class Vim73 < Formula
  homepage 'http://www.vim.org/'
  # Get stable versions from hg repo instead of downloading an increasing
  # number of separate patches.
  patchlevel = 1314
  url 'https://vim.googlecode.com/hg/', :tag => "v7-3-#{"%03d" % patchlevel}"
  version "7.3.#{patchlevel}"

  # We only have special support for finding depends_on :python, but not yet for
  # :ruby, :perl etc., so we use the standard environment that leaves the
  # PATH as the user has set it right now.
  env :std

  option "override-system-vi", "Override system vi"
  option "disable-nls", "Build vim without National Language Support (translated messages, keymaps)"
  option "with-client-server", "Enable client/server mode"

  LANGUAGES_OPTIONAL = %w(lua luajit mzscheme perl python3 tcl)
  LANGUAGES_DEFAULT  = %w(ruby python)

  LANGUAGES_OPTIONAL.each do |language|
    option "with-#{language}", "Build vim with #{language} support"
  end
  LANGUAGES_DEFAULT.each do |language|
    option "without-#{language}", "Build vim without #{language} support"
  end

  depends_on :python => :recommended
  depends_on 'gtk+' if build.with? 'client-server'

  def patches
    DATA if build.include? "with-luajit"
  end

  def install
    ENV['LUA_PREFIX'] = HOMEBREW_PREFIX if build.with?('lua') || build.with?('luajit')
    ENV.append_to_cflags '-mtune=native'

    opts = []
    opts += LANGUAGES_OPTIONAL.map do |language|
      "--enable-#{language}interp" if build.with?(language) && language != 'luajit'
    end
    opts += LANGUAGES_DEFAULT.map do |language|
      "--enable-#{language}interp" unless build.without? language
    end

    if build.with? 'luajit'
      opts << "--enable-luainterp" unless build.with? 'lua'
      opts << "--with-luajit"
    end

    opts << "--disable-nls" if build.include? "disable-nls"

    if python
      if python.brewed?
        # Avoid that vim always links System's Python even if configure tells us
        # it has found a brewed Python. Verify with `otool -L`.
        ENV.prepend 'LDFLAGS', "-F#{python.framework}"
      elsif python.from_osx? && !MacOS::CLT.installed?
        # Avoid `Python.h not found` on 10.8 with Xcode-only
        ENV.append 'CFLAGS', "-I#{python.incdir}", ' '
        # opts << "--with-python-config-dir=#{python.libdir}"
      end
    end

    # XXX: Please do not submit a pull request that hardcodes the path
    # to ruby: vim can be compiled against 1.8.x or 1.9.3-p385 and up.
    # If you have problems with vim because of ruby, ensure a compatible
    # version is first in your PATH when building vim.

    # We specify HOMEBREW_PREFIX as the prefix to make vim look in the
    # the right place (HOMEBREW_PREFIX/share/vim/{vimrc,vimfiles}) for
    # system vimscript files. We specify the normal installation prefix
    # when calling "make install".
    system "./configure", "--prefix=#{HOMEBREW_PREFIX}",
                          "--mandir=#{man}",
                          "--enable-gui=no",
                          "--without-x",
                          "--enable-multibyte",
                          "--with-tlib=ncurses",
                          "--enable-cscope",
                          "--with-features=huge",
                          "--with-compiledby=Homebrew",
                          *opts
    system "make"
    # If stripping the binaries is not enabled, vim will segfault with
    # statically-linked interpreters like ruby
    # http://code.google.com/p/vim/issues/detail?id=114&thanks=114&ts=1361483471
    system "make", "install", "prefix=#{prefix}", "STRIP=/usr/bin/true"
    ln_s bin+'vim', bin+'vi' if build.include? 'override-system-vi'
  end
end

__END__
--- a/src/Makefile
+++ b/src/Makefile
@@ -2552,7 +2552,7 @@
 	$(CCC) -o $@ if_xcmdsrv.c
 
 objects/if_lua.o: if_lua.c
-	$(CCC) $(LUA_CFLAGS) -o $@ if_lua.c
+	$(CC) -c -I$(srcdir) $(LUA_CFLAGS) $(ALL_CFLAGS) -o $@ if_lua.c
 
 objects/if_mzsch.o: if_mzsch.c $(MZSCHEME_EXTRA)
 	$(CCC) -o $@ $(MZSCHEME_CFLAGS_EXTRA) if_mzsch.c
