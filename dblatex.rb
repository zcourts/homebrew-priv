require 'formula'

class Dblatex < Formula
  env :userpaths
  url 'http://downloads.sourceforge.net/project/dblatex/dblatex/dblatex-0.3.5/dblatex-0.3.5.tar.bz2'
  homepage 'http://dblatex.sourceforge.net'
  md5 '9a80f7c23e1a41e5404669c48deefd00'

  def install
    system "python", "setup.py", "install", "--prefix=#{prefix}", "--install-scripts=#{bin}"
  end

  def patches
    #Fixes attr error install_layout
    DATA
  end
end

__END__
diff --git a/setup.py b/setup.py
index 2fa793f..a842cc0 100644
--- a/setup.py
+++ b/setup.py
@@ -368,10 +368,7 @@ class Install(install):
             raise OSError("not found: %s" % ", ".join(mis_stys))
 
     def run(self):
-        if self.install_layout == "deb":
-            db = DebianInstaller(self)
-        else:
-            db = None
+        db = None
 
         if not(db) and not(self.nodeps):
             try:
