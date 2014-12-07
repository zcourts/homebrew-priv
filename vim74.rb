require 'formula'

class Vim74 < Formula
  homepage 'http://www.vim.org/'
  # Get stable versions from hg repo instead of downloading an increasing
  # number of separate patches.
  patchlevel = 541
  url 'https://vim.googlecode.com/hg/', :tag => "v7-4-#{"%03d" % patchlevel}"
  version "7.4.#{patchlevel}"

  # We only have special support for finding depends_on :python, but not yet for
  # :ruby, :perl etc., so we use the standard environment that leaves the
  # PATH as the user has set it right now.
  env :std

  option "override-system-vi", "Override system vi"
  option "disable-nls", "Build vim without National Language Support (translated messages, keymaps)"
  option "with-client-server", "Enable client/server mode"

  LANGUAGES_OPTIONAL = %w(lua mzscheme perl python3 tcl)
  LANGUAGES_DEFAULT  = %w(ruby python)

  LANGUAGES_OPTIONAL.each do |language|
    option "with-#{language}", "Build vim with #{language} support"
  end
  LANGUAGES_DEFAULT.each do |language|
    option "without-#{language}", "Build vim without #{language} support"
  end

  depends_on :python => :recommended
  depends_on :python3 => :optional
  depends_on 'lua' => :optional
  depends_on 'luajit' => :optional
  depends_on 'gtk+' if build.with? 'client-server'

  conflicts_with 'ex-vi',
    :because => 'vim and ex-vi both install bin/ex and bin/view'

  def patches; DATA; end

  def install
    ENV['LUA_PREFIX'] = HOMEBREW_PREFIX if build.with?('lua') || build.with?('luajit')
    ENV.append_to_cflags '-mtune=native'

    # vim doesn't require any Python package, unset PYTHONPATH.
    ENV.delete('PYTHONPATH')

    opts = []
    opts += LANGUAGES_OPTIONAL.map do |language|
      "--enable-#{language}interp" if build.with? language
    end
    opts += LANGUAGES_DEFAULT.map do |language|
      "--enable-#{language}interp" if build.with? language
    end

    if build.with? 'luajit'
      opts << "--enable-luainterp" unless build.with? 'lua'
      opts << "--with-luajit"
    end

    opts << "--disable-nls" if build.include? "disable-nls"

    if build.with? 'client-server'
      opts << '--enable-gui=gtk2'
    else
      opts << "--enable-gui=no"
      opts << "--without-x"
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
                          "--enable-multibyte",
                          "--with-tlib=ncurses",
                          "--enable-cscope",
                          "--with-features=huge",
                          "--with-compiledby=Homebrew",
                          "--enable-fail-if-missing",
                          *opts

    # Require Python's dynamic library, and needs to be built as a framework.
    if build.with? "python" and build.with? "python3"
      py_prefix = `python -c "import sys; print(sys.prefix)"`.chomp
      py3_prefix = `python3 -c "import sys; print(sys.prefix)"`.chomp
      # Help vim find Python's dynamic library as absolute path.
      inreplace "src/auto/config.mk" do |s|
        s.gsub! /-DDYNAMIC_PYTHON_DLL=\\".*\\"/, %(-DDYNAMIC_PYTHON_DLL=\'\"#{py_prefix}/Python\"\')
        s.gsub! /-DDYNAMIC_PYTHON3_DLL=\\".*\\"/, %(-DDYNAMIC_PYTHON3_DLL=\'\"#{py3_prefix}/Python\"\')
      end
    end

    system "make"
    # If stripping the binaries is not enabled, vim will segfault with
    # statically-linked interpreters like ruby
    # http://code.google.com/p/vim/issues/detail?id=114&thanks=114&ts=1361483471
    system "make", "install", "prefix=#{prefix}", "STRIP=true"
    bin.install_symlink "vim" => "vi" if build.include? "override-system-vi"
  end
end

__END__
diff --git a/src/Makefile b/src/Makefile
--- a/src/Makefile
+++ b/src/Makefile
@@ -2552,7 +2552,7 @@
 	$(CCC) -o $@ if_xcmdsrv.c
 
 objects/if_lua.o: if_lua.c
-	$(CCC) $(LUA_CFLAGS) -o $@ if_lua.c
+	$(CC) -c -I$(srcdir) $(LUA_CFLAGS) $(ALL_CFLAGS) -o $@ if_lua.c
 
 objects/if_mzsch.o: if_mzsch.c $(MZSCHEME_EXTRA)
 	$(CCC) -o $@ $(MZSCHEME_CFLAGS_EXTRA) if_mzsch.c
diff --git a/src/eval.c b/src/eval.c
--- a/src/eval.c
+++ b/src/eval.c
@@ -6929,7 +6929,9 @@ free_unref_items(copyID)
     int copyID;
 {
     dict_T	*dd;
+    dict_T	*dd_next;
     list_T	*ll;
+    list_T	*ll_next;
     int		did_free = FALSE;
 
     /*
@@ -6941,11 +6943,10 @@ free_unref_items(copyID)
 	    /* Free the Dictionary and ordinary items it contains, but don't
 	     * recurse into Lists and Dictionaries, they will be in the list
 	     * of dicts or list of lists. */
+	    dd_next = dd->dv_used_next;
 	    dict_free(dd, FALSE);
 	    did_free = TRUE;
-
-	    /* restart, next dict may also have been freed */
-	    dd = first_dict;
+	    dd = dd_next;
 	}
 	else
 	    dd = dd->dv_used_next;
@@ -6962,11 +6963,10 @@ free_unref_items(copyID)
 	    /* Free the List and ordinary items it contains, but don't recurse
 	     * into Lists and Dictionaries, they will be in the list of dicts
 	     * or list of lists. */
+	    ll_next = ll->lv_used_next;
 	    list_free(ll, FALSE);
 	    did_free = TRUE;
-
-	    /* restart, next list may also have been freed */
-	    ll = first_list;
+	    ll = ll_next;
 	}
 	else
 	    ll = ll->lv_used_next;
