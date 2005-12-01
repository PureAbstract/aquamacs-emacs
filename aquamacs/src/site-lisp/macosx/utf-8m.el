;;; -*- coding: iso-2022-7bit -*-
;;; utf-8m.el --- modified UTF-8 encoding for Mac OS X hfs plus volume format

;; Copyright (C) 2004-2005  Seiji Zenitani <zenitani@mac.com>

;; Author: Seiji Zenitani <zenitani@mac.com>
;; Version: v20051124
;; Keywords: mac, multilingual, Unicode, UTF-8
;; Created: 2004-02-20
;; Compatibility: Mac OS X (Carbon Emacs)
;; URL(jp): http://home.att.ne.jp/alpha/z123/emacs-mac-j.html
;; URL(en): http://home.att.ne.jp/alpha/z123/emacs-mac-e.html

;; Contributed by Eiji Honjoh

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; This package provides a modified utf-8 encoding (utf-8m) for Mac OSX
;; hfs plus volume format. By setting utf-8m as the file-name-coding-system,
;; emacs can read the following characters in filenames.
;; 
;;  * Japanese Kana characters with Dakuten/Han-Dakuten signs
;;  * Korean Hangul characters
;;  * Latin characters with diacritical marks (accents, umlauts, tilde, etc.)
;;
;; Note that utf-8m does not restore the above characters when
;; it exports the filenames. Fortunately, it seems that the filesystem
;; knows how to deal with such invalid filenames.
;;
;; In order to use, add the below line to your .emacs file.
;; 
;;   (set-file-name-coding-system 'utf-8m)
;;

;;; utf-8m $B$K$D$$$F(B

;; Mac OS X $B$N(B HFS+ $B%U%!%$%k%7%9%F%`$N%U%!%$%kL>$rFI$`$?$a$N(B
;; $B=$@5(B UTF8 $B%(%s%3!<%G%#%s%0(B (utf-8m) $B$rDs6!$7$^$9!#(B
;; $B%U%!%$%kL>$rFI$_9~$`:]$K@55,2=J}<0$rJQ99$9$k$N$G(B
;; $BF|K\8l$NByE@!&H>ByE@J8;z$H%O%s%0%kJ8;z!"%"%/%;%s%HIU$-$N%i%F%sJ8;z$,(B
;; $BJ8;z2=$1$7$J$$$h$&$K$J$j$^$9!#%U%!%$%kL>$r=q$-=P$9:]$NJQ49$O(B
;; $B9MN8$7$F$$$^$;$s$,!"%U%!%$%k%7%9%F%`B&$,$&$^$/=hM}$7$F$/$l$k$h$&$G$9!#(B
;; utf-8m $B$r;HMQ$9$k$?$a$K$O!"$3$N%U%!%$%k$rFI$_9~$s$@$N$A!"(B
;;
;;   (set-file-name-coding-system 'utf-8m)
;;
;; $B$H$7$F2<$5$$!#(B


;;; Code:

;; convert utf-8 (NFD) to utf-8 (NFC) by calling `mac-code-convert-string'.
;; ref. http://lists.gnu.org/archive/html/emacs-devel/2005-07/msg01067.html
(defun utf-8m-post-read-conversion (length)
  "Document forthcoming..."
  (save-excursion ;; the original converter
    (setq length (utf-8-post-read-conversion length)))
  (save-excursion ;; additional conversion (NFD -> NFC)
    (save-restriction
      (narrow-to-region (point) (+ (point) length))
      (let ((str (buffer-string)))
        (delete-region (point-min) (point-max))
        (insert-string
         (decode-coding-string
          (mac-code-convert-string
           (encode-coding-string str 'utf-8) 'utf-8 'utf-8 'NFC)
          'utf-8))
        (- (point-max) (point-min))
        ))))

;; define a coding system (utf-8m)
(make-coding-system
 'utf-8m 4 ?u
 "modified UTF-8 encoding for Mac OS X hfs plus volume format."
 '(ccl-decode-mule-utf-8 . ccl-encode-mule-utf-8)
 `((safe-charsets
    ascii
    eight-bit-control
    eight-bit-graphic
    latin-iso8859-1
    mule-unicode-0100-24ff
    mule-unicode-2500-33ff
    mule-unicode-e000-ffff
    ,@(if utf-translate-cjk-mode
          utf-translate-cjk-charsets))
   (mime-charset . nil)
   (coding-category . coding-category-utf-8)
   (valid-codes (0 . 255))
   (pre-write-conversion . utf-8-pre-write-conversion)
;   (pre-write-conversion . utf-8m-pre-write-conversion)
;   (post-read-conversion . utf-8-post-read-conversion)
   (post-read-conversion . utf-8m-post-read-conversion)
   (translation-table-for-encode . utf-translation-table-for-encode)
   (dependency unify-8859-on-encoding-mode
               unify-8859-on-decoding-mode
               utf-fragment-on-decoding
               utf-translate-cjk-mode)))


(provide 'utf-8m)

;; utf-8m.el ends here.
