;;; aquamacs-faces.el --- Lisp faces for Aquamacs

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;; Copyright (C) 1995-2004, Drew Adams, all rights reserved.
;; Copyright (C) 2005, 2008, David Reitter, all rights reserved.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Standard Aquamacs Faces
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defface autoface-default
  '((((type ns))
     :inherit default :height 120 :weight normal :width normal :slant normal
     :underline nil :strike-through nil :stipple nil :family "Monaco"))
  "Default face for all buffers for `aquamacs-autoface-mode'"
  :group 'Aquamacs)

(defface text-mode-default
  '((((type ns))
     :inherit autoface-default :height 130 :weight normal :width normal
     :slant normal :underline nil :strike-through nil :stipple nil
     :family "Lucida Grande"))
  "Default face for text in `aquamacs-autoface-mode'"
  :group 'Aquamacs)

(defface latex-mode-default
  '((((type ns))
     :inherit autoface-default :height 130 :weight normal :width normal
     :slant normal :underline nil :strike-through nil :stipple nil
     :family "Lucida Grande"))
  "Default face for LaTeX in `aquamacs-autoface-mode'"
  :group 'Aquamacs)

(defface org-mode-default
  '((((type ns))
     :inherit autoface-default :height 120 :weight normal :width normal
     :slant normal :underline nil :strike-through nil :stipple nil
     :family "Monaco"))
  "Default face for Org-Mode in `aquamacs-autoface-mode'"
  :group 'Aquamacs)
