;; Site startup file
;; loads osx_defaults and auctex defaults 

;; Author: David Reitter, david.reitter@gmail.com
;; Maintainer: David Reitter
;; Keywords: aquamacs
 
;; Last change: $Id: site-start.el,v 1.15 2006/04/06 18:49:46 davidswelt Exp $

;; This file is part of Aquamacs Emacs
;; http://www.aquamacs.org/


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
 
;; Copyright (C) 2006, David Reitter
 

;; LAST-MINUTE FIXES
;; overwriting precompiled things

; NONE




(when ;; do not load this twice 
    (not (memq 'aquamacs-site-start features))
 
  (provide 'aquamacs-site-start)

  (require 'load-emacs-pre-plugins)

  ;; aquamacs-reload-preloaded-files should be set by a
  ;; plugin (preloaded) --> for Aquamacs developer(s) only.
  (when (and (boundp 'aquamacs-reload-preloaded-files)
	   aquamacs-reload-preloaded-files
	   (boundp 'aq-preloaded))
      (message "Ignoring preloaded files.")
      (mapc (lambda (p)
	      (setq features (delete p features)))
	    aq-preloaded))

  (require 'aquamacs)
  (aquamacs-setup)




  (require 'aquamacs-mode-defaults)
 
  (require 'load-emacs-plugins)


  )
