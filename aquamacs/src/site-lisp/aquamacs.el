;; Aquamacs Emacs startup file
;; these defaults attempt to turn Emacs into a nice application for 
;; operating systems with a graphical user interface.
 
;; This is the central configuration file.  
;;
;; Author: David Reitter, david.reitter@gmail.com
;; Maintainer: David Reitter
;; Keywords: aquamacs
 
;; Last change: $Id: aquamacs.el,v 1.64 2006/03/27 19:26:04 davidswelt Exp $ 

;; This file is part of Aquamacs Emacs
;; http://aquamacs.org/

;; Aquamacs Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; Aquamacs Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.
 
;; Copyright (C) 2005, David Reitter



(defvar aquamacs-version "0.9.9"
"A string with Aquamacs' version number.
The format of the string is undefined. 
For a reliable numerical representation, use `aquamacs-version-id'.")

(defvar aquamacs-version-id 099.0
"A float indicating Aquamacs' version number.
Full integers correspond to the third position of the public
version number, e.g. version 0.9.7 is represented as `97.x'.
Minor version numbers are reflected in the decimals. 
It is guaranteed that iff of two Aquamacs releases A and B,
B is newer than A, then aquamacs-version-id for B is higher 
than aquamacs-version-id for A.")

(defvar aquamacs-minor-version "a"
"Version code for minor maintenance releases.
Changes in this code are ignored during the online version check.")


(defun aquamacs-setup ()
 

  (aquamacs-mac-initialize) ;; call at runtime only
       
  (require 'aquamacs-tools)

  ;; Stop Emacs from asking for "y-e-s", when a "y" will do. 


  

  (defcustom aquamacs-quick-yes-or-no-prompt-flag t
    "If non-nil, the user does not have to type in yes or no at
yes-or-no prompts - y or n will do."
    :group 'Aquamacs
    :version "22.0"
    :type 'boolean
    )
  (defvaralias 'aquamacs-quick-yes-or-no-prompt 
    'aquamacs-quick-yes-or-no-prompt-flag)

; (yes-or-no-p "asda")
  ; (aquamacs-ask-for-confirmation "asd" t)
 
  (defun aquamacs-repl-yes-or-no-p (text)
    "Like `yes-or-no-p' - use that function instead."
    (aquamacs-ask-for-confirmation text t))
  (defun aquamacs-y-or-n-p (text)
    "Like `y-or-n-p' - use that function instead."
    (aquamacs-ask-for-confirmation text nil))

  (unless (fboundp 'old-yes-or-no-p)
    (fset 'old-yes-or-no-p (symbol-function 'yes-or-no-p)))
  (unless (fboundp 'old-y-or-n-p)
    (fset 'old-y-or-n-p (symbol-function 'y-or-n-p)))
  
  
  (fset 'y-or-n-p 'aquamacs-y-or-n-p)
  (fset 'yes-or-no-p 'aquamacs-repl-yes-or-no-p)

  (defadvice map-y-or-n-p (around raiseframe (&rest args) activate)
    (raise-frame)
    ad-do-it)    

  ;; No more annoying bells all the time

  (aquamacs-set-defaults 
   '((ring-bell-function (lambda () (message "")))
     )
   )

  ;; this can be turned off in .emacs via
  ;; (setq ring-bell-function nil)

  (defcustom aquamacs-ring-bell-on-error-flag nil
    "If non-nil, Aquamacs gives an audio signal in cases of error, regardless of ``ring-bell-function''."
    :group 'Aquamacs
    :version "22.0"
    :type 'boolean
    )
  (defvaralias  'aquamacs-ring-bell-on-error 'aquamacs-ring-bell-on-error-flag)

  ;; but please ring the bell when there is a real error
  (defadvice error (around ring-bell (&rest args) activate protect)
 
    (if aquamacs-ring-bell-on-error-flag
	(progn
	  (let ((ring-bell-function nil))
	    (ding))
					;	(message (prin1-to-string args))
	  ad-do-it)
      ;; else
      ad-do-it)) 



  ;; Find-file may open a new frame
  (if window-system
      (global-set-key [remap find-file] 'aquamacs-find-file)  
    )
 


  (add-hook 'after-init-hook 
	    (lambda () 
	      (condition-case nil (load custom-file) (error t))
	      (aquamacs-activate-features-new-in-this-version)
	      ) 'append)

  (defun font-exists-p (fontorfontset)
    (condition-case nil
	(or
	 (font-info fontorfontset)
	 (fontset-info fontorfontset)
	 )
      (error nil)
      )
    )

   

  ;; Mac OS X specific stuff 

  (when (eq window-system 'mac)
    (require 'osx_defaults)
    (aquamacs-osx-defaults-setup)
    )
  (eval-when-compile
    (require 'osx_defaults)
    (aquamacs-osx-defaults-setup)
    )
  (require 'easymenu) 


  (require 'recentf)

  (defun aquamacs-recentf-show-basenames (l &optional no-dir)
    "Filter the list of menu elements L to show filenames sans directory.
When a filename is duplicated, it is appended a sequence number if
optional argument NO-DIR is non-nil, or its directory otherwise.
Separate paths from file names with --."
    (let (filtered-names filtered-list full name counters sufx)
      (dolist (elt l (nreverse filtered-list))
	(setq full (recentf-menu-element-value elt)
	      name (file-name-nondirectory full))
	(if (not (member name filtered-names))
	    (push name filtered-names)
	  (if no-dir
	      (if (setq sufx (assoc name counters))
		  (setcdr sufx (1+ (cdr sufx)))
		(setq sufx 1)
		(push (cons name sufx) counters))
	    (setq sufx (file-name-directory full)))
	  (setq name (format "%s -- %s" name sufx)))
	(push (recentf-make-menu-element name full) filtered-list))))

  (aquamacs-set-defaults 
   '(
     ( recentf-max-menu-items 25)
     (recentf-menu-before  "Open Directory...                 ")
     (recentf-keep ( mac-is-mounted-volume-p file-remote-p file-readable-p))
     (recentf-filename-handler abbreviate-file-name)
     (recentf-menu-filter aquamacs-recentf-show-basenames)))  

  ;; define a single command to be included in the recentf menu
  (defun recentf-clearlist ()
    "Remove all files from the recent list."
    (interactive)
    (setq recentf-list ()))

  (setq recentf-menu-items-for-commands
	(list ["Clear Menu"
	       recentf-clearlist
	       :help "Remove all excluded and non-kept files from the recent list"
	       :active t]
        
	      ) 
	)



  (recentf-mode 1)  

  (global-set-key "\C-x\ \C-r" 'recentf-open-files)  


  (setq file-name-coding-system 'utf-8)

;; Page scrolling


  (require 'pager)
  ;; overwrites CUA stuff
 
  (global-set-key [remap scroll-up]	      'pager-page-down)
  (global-set-key [remap cua-scroll-up]	      'pager-page-down)
  (global-set-key [remap scroll-up-mark]      'pager-page-down-extend-region)
  (global-set-key [next] 	      'pager-page-down)
  (global-set-key [\S-next] 	      'pager-page-down-extend-region)
  (global-set-key [\M-up]	      'pager-page-up)
  (global-set-key [remap scroll-down]	      'pager-page-up) 
  (global-set-key [remap cua-scroll-down]	      'pager-page-up)
  (global-set-key [remap scroll-down-mark]      'pager-page-up-extend-region)
  (global-set-key [prior]	      'pager-page-up)
  (global-set-key [\S-prior]	      'pager-page-up-extend-region)

  ;; was here in 0.9.5, taken out
  ;;(global-set-key [C-up]        'pager-row-up)
  ;;(global-set-key [C-down]      'pager-row-down)
 



  (require 'aquamacs-menu)
  (require 'aquamacs-bug) ;; successfully send bug reports on the Mac

  


  (require 'longlines) 
  (aquamacs-set-defaults 
   `(
     (send-mail-function mailclient-send-it)
     (mail-setup-with-from nil)  
					; Colorized fonts
					; Turn on font-lock in all modes that support it
     (global-font-lock-mode t)
     (font-lock-maximum-decoration t)

					; Make Text mode the default mode for new buffers
					; turn on Auto Fill mode automatically in Text mode  
     (default-major-mode text-mode)
     (initial-major-mode text-mode)


					; scroll just one line when hitting the bottom of the window
     (scroll-step 1)
     (scroll-conservatively 10000)
     ;; Start scrolling when 2 lines from top/bottom 
     (scroll-margin 0)
     (visual-scroll-margin 2)

     (tramp-verbose 1)                  ;; don't annoy us

					; no flash instead of that annoying bell
     (visible-bell nil)

					; Display the column number of the point in the mode line
     (column-number-mode t)

;;; Do not automatically add newlines on (page) down
     (next-line-add-newlines nil)

     ;; Show directories in buffer names when needed
     (buffers-menu-show-directories t)

     ;; Do not complain when a minibuffer is still open somewhere

     (enable-recursive-minibuffers t)
 
     (longlines-wrap-follows-window-size t)

     ;; do not allow user to mess with minibuffer prompt

     (minibuffer-prompt-properties
      ,(plist-put minibuffer-prompt-properties
		  'point-entered 'minibuffer-avoid-prompt))

     )
   )


  ;; set a nntp server if there's none
  (if (getenv "NNTPSERVER") ;; (gnus-getenv-nntpserver)
      nil
    (aquamacs-set-defaults '(

			     (setq gnus-select-method 
				   '(nntp "news.readfreenews.net"))
			     )
			   )
    )

					; activate the modes now
  (global-font-lock-mode 1) 
  (column-number-mode 1)

					; ------- Frames (OSX Windows) ----------

					; format the title-bar to always include the buffer name
  (setq frame-title-format "Emacs - %b")
 
 
  (require 'view)
  ;; redefine view-buffer
  (defun view-buffer (buffer &optional exit-action)
    "View BUFFER in View mode, returning to previous buffer when done.
Emacs commands editing the buffer contents are not available; instead,
a special set of commands (mostly letters and punctuation)
are defined for moving around in the buffer.
Space scrolls forward, Delete scrolls backward.
For list of all View commands, type H or h while viewing.

This command runs the normal hook `view-mode-hook'.

Optional argument EXIT-ACTION is either nil or a function with buffer as
argument.  This function is called when finished viewing buffer.
Use this argument instead of explicitly setting `view-exit-action'."

    (interactive "bView buffer: ")
    (let ((undo-window (list (window-buffer) (window-start) (window-point)))
	  (obof one-buffer-one-frame) ;;may be buffer-local!
	  ) 
      (switch-to-buffer buffer)
      (view-mode-enter (cons (selected-window) (cons (cons nil undo-window) obof))
		       exit-action)))



  ;; Make sure it's saved to .emacs when necessary
  ;; we need to redefine this here - this is copied and modified from menu-bar.el
  ;; there is no method to mark a customize-variable to save _and_ to 
  ;; set need-save so that it will be saved to .emacs. 


					; write the aquamacs-version to end of customizations.el
					; warning: bug - this will add to the file
					; so the file will grow over time
					; because the last (setq is what actually counts,
					; this shouldn't cause any problems.
  ;; (defadvice custom-save-all  
  ;;   (after save-aquamacs-customization-version (&rest args) activate)
 
  ;;   (write-region
  ;;    (with-output-to-string
  ;;      (print `(setq aquamacs-customization-version-id
  ;;      ,aquamacs-customization-version-id))
  ;;      )
  ;;    nil ;end
  ;;    custom-file
  ;;    'append
  ;;    'quiet
  ;;    )
  ;; )
 

 
					; update the help-mode specification with a fit-frame
					; append it, so the user's choice has priority
  (defun 	make-help-mode-use-frame-fitting ()

    (unless (assq 'fit-frame 
		  (assq 'help-mode aquamacs-default-styles)
		  ) ;; unless it's already set

      (assq-set 'help-mode
		(append  
		 (cdr (assq 'help-mode aquamacs-default-styles))
		 '((fit-frame . t))
		 )
		'aquamacs-default-styles)
      )
    )


   
  (add-hook 'after-init-hook
	    'make-help-mode-use-frame-fitting
	    'append) ;; move to the end: after loading customizations
	
	
      
  (provide 'drews_init)	; migration from 0.9.1 (require in customizations)

  ;; http://www.emacswiki.org/cgi-bin/wiki/DrewsElispLibraries
  
  ;; set default fonts - after aquamacs-frame-setup has initialized things

  (if (fontset-exist-p "fontset-monaco12") 
      (assq-set 'font "fontset-monaco12" 'default-frame-alist)
    (if (fontset-exist-p "fontset-mac_roman_12") 
	(assq-set 'font "fontset-mac_roman_12" 'default-frame-alist)

      (if (fontset-exist-p "fontset-lucida14") 
	  (assq-set 'font "fontset-lucida14" 'default-frame-alist)
	)
      )
    )

  (if (fontset-exist-p "fontset-mac_roman_12") 
      (assq-set 'font "fontset-mac_roman_12" 'special-display-frame-alist)

    (if (fontset-exist-p "fontset-monaco12") 
	(assq-set 'font "fontset-monaco12" 'special-display-frame-alist))
    )

  ;; automatic positioning please  
  ;; for normal windows
  ;; for special windows, the user can set and save things
  ;; also, we don't want the initial frame to move around
  (setq default-frame-alist (assq-delete-all 'top default-frame-alist))
  (setq default-frame-alist (assq-delete-all 'left default-frame-alist)) 
  (setq default-frame-alist (assq-delete-all 'width default-frame-alist))
  (setq default-frame-alist (assq-delete-all 'height default-frame-alist))
  ;; sensible defaults for the position of the special windows
  ;; (in case user turns them off)
  (assq-set 'top 30 'special-display-frame-alist)
  (assq-set 'left '(- 0) 'special-display-frame-alist)
  (assq-set 'height 30 'special-display-frame-alist)
  (assq-set 'width 75 'special-display-frame-alist)
  (assq-set 'user-position nil 'special-display-frame-alist)

  
  ;; turn on mode-spec styles AFTER setting default-frame-alist
  ;; so everything is copied over to the 'default style as appropriate
  ;; mode-specific font settings
  (aquamacs-set-defaults '((aquamacs-styles-mode t)))
  (require 'aquamacs-styles) 
  ;; default-frame-alist should be empty now


  ;; local toolbars

  (defun tool-bar-enabled-p (&optional frame)
    "Evaluates to non-nil if the tool-bar is present
in frame FRAME. If FRAME is nil, the function applies
to the selected frame."
    (> (or (frame-parameter frame 'tool-bar-lines) 0) 0)) 

  (defun toggle-tool-bar-here ()
    (interactive)
    (modify-frame-parameters 
     nil 
     (list (cons 'tool-bar-lines 
		 (if (tool-bar-enabled-p)
		     0
		   1
		   )))))
  ;; (toggle-tool-bar-here)


					; and turn on smart frame positioning

  
  (require 'smart-frame-positioning)
  
  (fset 'winmgr-display-available-pixel-bounds
	'mac-display-available-pixel-bounds)

  (aquamacs-set-defaults 
   '((smart-frame-positioning-mode t)
     ( smart-frame-positioning-enforce t) ;; and enforce it
     )
   )

  (smart-frame-positioning-mode t) ;; and turn on!

  
  (defvar mac-pass-option-to-system 'deprecated)

  ;; make sure there are no old customizations around
  ;; N.B.: if no customization file is present, 
  ;; aquamacs-customization-version-id is 0 or nil

  (defun aquamacs-activate-features-new-in-this-version ()

    ;; aquamacs-customization-version-id contains the version id
    ;; of aquamacs when the customization file was written

    (when (and aquamacs-customization-version-id
	       (> aquamacs-customization-version-id 0))

    (if (< aquamacs-customization-version-id 092.5)

	;; make sure we fit frames
	(assq-set 'user-position nil 'default-frame-alist)

      )

    (if (< aquamacs-customization-version-id 092.8)
	;; bring the lucida font back because
	;; we have switched over to monaco as the default
	(mapc 
	 (lambda (th)
	   (unless (assq (car th) aquamacs-default-styles)
	     (assq-set (car th) 
		       (cdr th)
		       'aquamacs-default-styles)))
	 ;; list
	 (filter-fonts '(
			 (text-mode  
			  (font . "fontset-lucida14")) 
			 (change-log-mode  
			  (font . "fontset-lucida14"))
			 (tex-mode  
			  (font . "fontset-lucida14"))
			 (paragraph-indent-text-mode  
			  (font . "fontset-lucida14"))
			 ))))
    (if (< aquamacs-customization-version-id 094.1)
	(progn
	  ;; in the mode-spec styles, this is taken care of
	  ;; anyways
	  (setq default-frame-alist 
		(assq-delete-all 'scroll-bar-width default-frame-alist))
	  (setq special-display-frame-alist 
		(assq-delete-all 'scroll-bar-width special-display-frame-alist))
      
	  (mapc 
	   (lambda (th)
	     (unless (assq (car th) aquamacs-default-styles)
	       (assq-set (car th) 
			 (cdr th)
			 'aquamacs-default-styles)))
	   ;; list
	   (filter-fonts '(
			   (help-mode (tool-bar-lines . 0) (fit-frame . t)) 
			   (custom-mode (tool-bar-lines . 0) (fit-frame . t)))))))



;; todo before 0.9.9:
;; how to deal with tool-bar-mode set in user's custom-file?
;; for now, ignore it

;; Print warnings / compatibility options
    
    (if (boundp 'mac-reverse-ctrl-meta)
	(message "Warning: `mac-reverse-ctrl-meta' is not used any more from
Aquamacs 0.9.7 on. This variable had been deprecated for several versions.
Use `mac-{control|command|option|function}-modifier' instead."))
    (if (boundp 'mac-command-key-is-meta)
	(message "Warning: `mac-command-key-is-meta' is not used any more from
Aquamacs 0.9.7 on. This variable had been deprecated for several versions.
Use `mac-command-modifier' instead."))


    (when (and (boundp 'mac-pass-option-to-system)
	       (not (eq mac-pass-option-to-system 'deprecated)))
      (when mac-pass-option-to-system
	   (setq mac-option-modifier-enabled-value mac-option-modifier)
	   (setq mac-option-modifier nil))
      (if (> aquamacs-customization-version-id 096.0)
	(message "Warning: `mac-pass-option-to-system' is deprecated from
Aquamacs 0.9.7 on. `mac-option-modifier' has been set for you.")))))

  (require 'one-buffer-one-frame)
  (one-buffer-one-frame-mode 1)
  ;; necessary to ensure the value is saved with the Options
  ;; (setting the default)
  (aquamacs-set-defaults '((one-buffer-one-frame-mode t)))

;; ----------- MISC STUFF ----------------


  ;; (require 'ibuffer)

  (put 'upcase-region 'disabled nil)
 

  ;; -------- MOUSE BEHAVIOR / SELECTION -------------

  ;; we activate CUA mode again but disable the keys 
  ;; thanks to Lawrence Akka for hints on the following section
  ;; ;; not needed


  (require 'mouse-sel) ; provie functions - but don't turn on mouse-sel-mode
 

  (aquamacs-set-defaults '((cua-use-hyper-key only) ;;this avoids shift-return
			   (cua-enable-cua-keys nil)))
 
  ;; enable cua-keep-region-after-copy only for the mac like commands
  (defadvice cua-copy-region (around keep-region activate)
    (if (eq this-original-command 'clipboard-kill-ring-save)
	(let ((cua-keep-region-after-copy t))
	  ad-do-it) 
      ;; respect user's setting of cua-keep-region-after-copy for M-w etc.
      ad-do-it))

  (cua-mode 1) ;; this goes first (so we can overwrite the settings)

  (defun aquamacs-cua-warning ()
    (and (not cua-mode)
	 (message 
	  "Warning: You have turned off `cua-mode' in your customizations 
or init file. Without this mode, Aquamacs will behave in an 
un-Mac-like way when you select text and copy&paste it.")))
  (add-hook 'after-init-hook 'aquamacs-cua-warning)
  
  ;; give context menus on right click
  ;; if mac-wh is nil, we need the following
 ;;  (define-key mode-line-major-mode-keymap [mode-line down-mouse-1] 
;;     'mouse-major-mode-menu)
;;   (define-key mode-line-major-mode-keymap [mode-line mouse-2] 
;;     'mode-line-mode-menu-1)
;;   (define-key mode-line-major-mode-keymap [mode-line down-mouse-3] 
;;     'describe-mode)
;;   (define-key mode-line-minor-mode-keymap [header-line down-mouse-3] 
;;     'mode-line-minor-mode-help)
;;   (define-key mode-line-minor-mode-keymap [mode-line down-mouse-3] 
;;     'mode-line-minor-mode-help)
;;   (define-key mode-line-minor-mode-keymap [header-line mouse-2] 
;;     'mode-line-mode-menu-1)
;;   (define-key mode-line-minor-mode-keymap [mode-line mouse-2] 
;;     'mode-line-mode-menu-1)


;;   (let ((help-echo 
;; 	 "left click (mouse-1): select (drag to resize), right click (mouse-2): delete others, mouse-3: delete this"))
;;     (setq-default mode-line-modes
;; 		  (list
;; 		   (propertize "%[(" 'help-echo help-echo)
;; 		   `(:propertize ("" mode-name)
;; 				 help-echo "left click (mouse-1): major-mode-menu, mouse-3: help for current major mode"
;; 				 mouse-face mode-line-highlight
;; 				 local-map ,mode-line-major-mode-keymap)
;; 		   '("" mode-line-process)
;; 		   `(:propertize ("" minor-mode-alist)
;; 				 mouse-face mode-line-highlight
;; 				 help-echo "mouse-2 (right click): minor mode menu, mouse-3: help for minor modes"
;; 				 local-map ,mode-line-minor-mode-keymap)
;; 		   (propertize "%n" 'help-echo "right click (mouse-2): widen"
;; 			       'mouse-face 'mode-line-highlight
;; 			       'local-map (make-mode-line-mouse-map
;; 					   'mouse-2 #'mode-line-widen))
;; 		   (propertize ")%]--" 'help-echo 
;; 			       help-echo))))


  ;; do not use [ ... ] notation - pure space allocation!

  ;; enable flyspell's corrections on mouse-3
  (setq flyspell-mouse-map
	(let ((map (make-sparse-keymap)))
	  (define-key map (if (featurep 'xemacs) [button3] [down-mouse-3])
	    #'flyspell-correct-word)
	  map))

  (let ((cmdkey (or (if (boundp 'mac-command-modifier)
			mac-command-modifier nil) 'alt)))
    (global-set-key (vector '(shift down-mouse-1)) 'mouse-extend)
    (global-set-key (vector `(shift ,cmdkey down-mouse-1)) 
		    'mouse-extend-secondary)
    (global-set-key (vector `(,cmdkey mouse-1)) 'mouse-start-secondary)
    (global-set-key (vector `(,cmdkey drag-mouse-1)) 'mouse-set-secondary)
    (global-set-key (vector `(,cmdkey down-mouse-1)) 'mouse-drag-secondary))
 
  (aquamacs-set-defaults '((x-select-enable-clipboard nil) 
			   (cua-mode t)
			   (mouse-sel-leave-point-near-mouse t)))

  ;; mainly to ensure  that we overwrite a marked region
  ;; (transient-mark-mode nil)


;  (when (string= "mac" window-system)
; don't do this -  
 ;;   (put 'PRIMARY 'mac-scrap-name "org.gnu.Emacs.selection.PRIMARY")

  ;; unnecessary
;    (setq mac-services-selection 'PRIMARY)
;    )
;;;;;;;;;;;;
 
     
					; applications on OS X don't display a splash screen 
 
  (setq command-line-args  (append command-line-args (list "--no-splash")))
  (setq inhibit-startup-message t)

  (defun aquamacs-wrap-string (str width)
    (with-temp-buffer 
      (insert str)
      (let ((fill-column width))
	(fill-region (point-min) (point-max)))
      (buffer-string)))
 
;; redefine this
  (defun startup-echo-area-message ()
    (aquamacs-wrap-string
     (concat
      (if (and (eq window-system 'mac) 
	       (eq (key-binding [(alt \?)]) 'aquamacs-user-help))
	  "For an introduction to Aquamacs Emacs, type Apple-?." 
	(if window-system
	    "For an introduction to Aquamacs Emacs,\nchoose `Aquamacs Help' from the `Help' menu."
	  (substitute-command-keys
	   "For a introduction to Aquamacs Emacs, type \
\\[aquamacs-user-help].")))
      ;;The GPL stipulates that the following message is shown.

      (propertize 	(substitute-command-keys "
Copyright (C) 2006 Free Software Foundation, Inc., & D. Reitter. No Warranty. You may
redistribute Aquamacs under the GNU General Public License. Type \\[describe-copying] to view.") 'face 'blue-foreground-face)) 
     (frame-parameter nil 'width) ;; let's just hope that this is the width of the echo area
     ))

;;  (message (startup-echo-area-message))
  
  (if (string= "mac" window-system)
      (defun use-fancy-splash-screens-p () t))
  
       
;; the following causes not-so-good things to happen.
;; (defun fancy-splash-default-action () nil)

  (aquamacs-set-defaults
   '((fancy-splash-image "aquamacs-splash-screen.jpg")
     (fancy-splash-max-time 3000)))
  
;; (defadvice fancy-splash-screens (around new-frame (&rest args) activate protect)
 
;;   (let ((one-buffer-one-frame-force t))
;;     ad-do-it)
;;   (message " ")
;;   )

  ;; only the fancy splash screen is displayed more than once
  ;; this is a workaround    
 
    
  ;; scratch buffer should be empty 
  ;; the philosophy is: don't give users any text to read to get started!    

  (aquamacs-set-defaults '((  initial-scratch-message nil)
			   ))

  ;; while pc selection mode will be turned on, we don't
  ;; want it to override Emacs like key bindings. 
  ;; we need to fill the following variable with something
  ;; that is non-nil.
  (setq pc-select-default-key-bindings '(([home]      . beginning-of-buffer)
					 ([end]      . end-of-buffer)
					 ))

  (aquamacs-set-defaults 
   '( 
     (mouse-wheel-progessive-speed nil)
   ;;  (mouse-wheel-scroll-amount (1 (shift . 0.5) (control . 0.2) ))
     (mouse-wheel-scroll-amount (1 ((shift) . 0.5) ((control) . 0.2) ))
     (pc-select-meta-moves-sexps t)
     (pc-select-selection-keys-only t)
     (pc-selection-mode t)
     (show-paren-mode t)
     (blink-cursor-mode t)
     (cursor-type (bar . 2))
     ;; on modern systems, loading files doesn't take so long any more.
     (large-file-warning-threshold 20000000)
     ;; show unfinished key inputs early
     (echo-keystrokes 0.1))) 
   

  
					; activate the modes


  (pc-selection-mode 1) 
  (show-paren-mode 1) 
  (blink-cursor-mode 1)

  (set-default 'cursor-type '(bar . 2))


  ;;; for initial buffer
;;; for some reason
  (add-hook 'after-init-hook (lambda ()
			       (setq buffer-offer-save t)
			       ))
     
  ;; Define customization group
;; add items that aren't Aquamacs defcustoms
  (defgroup Aquamacs 
    '( 
      (smart-frame-positioning-enforce custom-variable)
      (smart-frame-positioning-mode custom-variable)
      (mac-option-modifier  custom-variable)
      (mac-control-modifier  custom-variable)
      (mac-function-modifier  custom-variable)
      (mac-pass-control-to-system  custom-variable)
      (mac-command-modifier  custom-variable)
      (mac-pass-command-to-system  custom-variable)
      (mac-emulate-three-button-mouse  custom-variable)
      (mac-allow-anti-aliasing  custom-variable)
      (x-select-enable-clipboard  custom-variable)
      (special-display-regexps custom-variable)
      )
    "Options specific to Aquamacs Emacs. Some of these customizations
values exist in GNU Emacs as well, but have default values different 
from those in GNU Emacs. Customize them to achieve the GNU Emacs behavior.
Note that not all customization variables with differing defaults are
listed here."
    :group 'emacs
    )
 

;; ensure that Save Options saves all of our fancy new options
;; TO DO:
;; now that variable setting has been revised
;; we should review whether this is still necessary.

  ;; this is initialized to the current version 
  ;; it'll be overwritten by whatever is in the customization file
  (defvar aquamacs-customization-version-id 0)
  ;; the following ensures that it gets saved
  ;; as customized variable.
  (customize-set-variable 'aquamacs-customization-version-id 
			  aquamacs-customization-version-id)
  
  (defvar aquamacs-menu-bar-options-to-save
    (append '(line-number-mode 
	      column-number-mode 
	      size-indication-mode
	      cua-mode show-paren-mode
	      transient-mark-mode 
	      global-font-lock-mode
	      display-time-mode 
	      display-battery-mode
	      one-buffer-one-frame-mode 
	      mac-option-modifier)
	    (mapcar (lambda (x) 
		      (emkm-name (car x))) 
		    emulate-mac-keyboard-mode-maps)
	    ))

  (defvar aquamacs-menu-bar-customize-options-to-save
    '(scroll-bar-mode
     debug-on-quit debug-on-error
     tooltip-mode menu-bar-mode	;; tool-bar-mode
     save-place uniquify-buffer-name-style fringe-mode
     indicate-empty-lines indicate-buffer-boundaries
     case-fold-search
     current-language-environment default-input-method
     ;; Saving `text-mode-hook' is somewhat questionable,
     ;; as we might get more than we bargain for, if
     ;; other code may has added hooks as well.
     ;; Nonetheless, not saving it would like be confuse
     ;; more often.
     ;; -- Per Abrahamsen <abraham@dina.kvl.dk> 2002-02-11.
     text-mode-hook

     blink-cursor-mode
     ;; added dr. 04/2005
     aquamacs-styles-mode
     aquamacs-default-styles 
     aquamacs-customization-version-id))

  (defun aquamacs-menu-bar-options-save ()
    "Save current values of Options menu items using Custom.
Return non-nil if options where saved."
    (interactive)
    (let ((need-save nil))
      (setq aquamacs-customization-version-id aquamacs-version-id)
      ;; These are set with menu-bar-make-mm-toggle, which does not
      ;; put on a customized-value property.
      (dolist (elt aquamacs-menu-bar-options-to-save)
	(and (customize-mark-to-save elt)
	     (setq need-save (cons elt need-save)))) 
      ;; 
      ;; These are set with `customize-set-variable'.
      (dolist (elt aquamacs-menu-bar-customize-options-to-save)
	(and (get elt 'customized-value) 
	     (customize-mark-to-save elt)
	     (setq need-save (cons elt need-save))))
      ;; Save if we changed anything.
      (when need-save
	(custom-save-all))
      need-save))

  (defun aquamacs-menu-bar-changed-options ()
    (let ((need-save))
      (dolist (elt aquamacs-menu-bar-options-to-save)
	(and (aquamacs-variable-customized-p elt)
	     (setq need-save (cons elt need-save))))
      (dolist (elt aquamacs-menu-bar-customize-options-to-save)
	(and (get elt 'customized-value) 
	     (aquamacs-variable-customized-p elt)
	     (setq need-save (cons elt need-save))))
      need-save))

  (defcustom aquamacs-save-options-on-quit 'ask
    "If t, always save the options (from the options menu) when quitting.
If set to `ask' (default), the user is asked in case the options
have changed."
    :group 'Aquamacs
    :type '(choice (const nil)  (const ask) (const t)))
  
  (defun aquamacs-variable-customized-p (symbol)
    "Returns t if variable SYMBOL has a different value from what was saved."
    (custom-load-symbol symbol)
    (let* ((get (or (get symbol 'custom-get) 'default-value))
	   (value (funcall get symbol))
	   (saved (get symbol 'saved-value))
	   (standard (get symbol 'standard-value))
	   (comment (get symbol 'customized-variable-comment)))

      (and (or (null standard)
	      (not (equal value (condition-case nil
				    (eval (car standard))
				  (error nil)))))
	  (eq saved (list (custom-quote value))))))
	  


  (defun aquamacs-ask-to-save-options ()
  "Checks if options need saving and allows to do that.
Returns t."
  (interactive)
  (let* ((changed (aquamacs-menu-bar-changed-options)))
    (if (and (filter-list changed
			  (list 'aquamacs-customization-version-id
				'smart-frame-prior-positions
				'transient-mark-mode))
	     ;; depends on return value of `aquamacs-menu-bar-options-save'
	     ;; NOT implemented for the standard menu-bar-options-save!
	     ;; ask user whether to accept these saved changes
	     (if (eq aquamacs-save-options-on-quit 'ask)
		 (y-or-n-p "Options have changed - save them? ")
	       aquamacs-save-options-on-quit))
	(aquamacs-menu-bar-options-save)))
  t)
  (add-hook 'kill-emacs-query-functions 'aquamacs-ask-to-save-options)


  (defun aquamacs-save-buffers-kill-emacs (&optional arg)
    "Offer to save each buffer, then kill this Emacs process.
With prefix arg, silently save all file-visiting buffers, then kill.
Like `save-buffers-kill-emacs', except that it doesn't ask again
if modified buffers exist."
    (interactive "P")
    (save-some-buffers arg t)
    (and (or (not (fboundp 'process-list))
	     ;; process-list is not defined on VMS.
	     (let ((processes (process-list))
		   active)
	       (while processes
		 (and (memq (process-status (car processes)) 
			    '(run stop open listen))
		      (process-query-on-exit-flag (car processes))
		      (setq active t))
		 (setq processes (cdr processes)))
	       (or (not active)
		   (list-processes t)
		   (yes-or-no-p 
		    "Active processes exist; kill them and exit anyway? "))))
	 ;; Query the user for other things, perhaps.
	 (run-hook-with-args-until-failure 'kill-emacs-query-functions)
	 (or (null confirm-kill-emacs)
	     (funcall confirm-kill-emacs "Really exit Emacs? "))
	 (kill-emacs)))

(global-set-key [remap save-buffers-kill-emacs] 
		'aquamacs-save-buffers-kill-emacs)

  ;; workaround for people who still call this in their .emacs
  (defun mwheel-install ()
    (message "mwheel-install ignored in Aquamacs- mouse wheel support is present by default.")
    t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; temporary stuff for releases according to admin/FOR-RELEASE

  (setq undo-ask-before-discard nil)
;; http://sourceforge.net/tracker/index.php?func=detail&aid=1295333&group_id=138078&atid=740475				      


  ;; workarounds for current bugs 
 
  ;; (tool-bar-setup) ;; when image.el is preloaded,
  ;; tool bar is created too early upon launch.
  ;; therefore, set it up again, this time after
  ;; image-load-path is defined properly

  '			      ; can't get rid of the menu bar on a Mac
  (easy-menu-remove-item global-map 
			 '("menu-bar" "options" "showhide") 'menu-bar-mode)

					;' can't show a frame on a different display
  (easy-menu-remove-item global-map 
			 '("menu-bar" "file") 'make-frame-on-display)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; this is for the About dialog

  (setq emacs-build-system 
	(concat emacs-build-system
		" - Aquamacs Distribution " 
		aquamacs-version aquamacs-minor-version))

  (require 'check-for-updates)
					; via hook so it can be turned off
  (add-hook 'after-init-hook 'aquamacs-check-for-updates-if-necessary 'append) 

(aquamacs-tool-bar-setup)

  ) ;; aquamacs-setup


;; this to overwrite the tool-bar setup function
;  
(defun aquamacs-tool-bar-setup ()
  ;; People say it's bad to have EXIT on the tool bar, since users
  ;; might inadvertently click that button.
  ;;(tool-bar-add-item-from-menu 'save-buffers-kill-emacs "exit")
  (setq tool-bar-map (make-sparse-keymap))
  (let ((face 'tool-bar)
	(spec '((t (:background "#e0e0e0" :foreground "black" 
				:box (:line-width 1 :style released-button))))))
    (face-spec-set face spec nil)
    (put face 'face-defface-spec spec))
  ;; will be overwritten by color themes

  (tool-bar-add-item-from-menu 'new-frame-with-new-scratch "new")
  (tool-bar-add-item-from-menu 'mac-key-open-file "open")
  (tool-bar-add-item-from-menu 'dired "diropen")
  (tool-bar-add-item-from-menu 
   'kill-this-buffer "close" nil
   :visible '(or (not (boundp 'one-buffer-one-frame-mode))
		(not one-buffer-one-frame-mode)))
  (tool-bar-add-item-from-menu 'save-buffer "save" nil
			       :visible '(or buffer-file-name
					     (not (eq 'special
						      (get major-mode
							   'mode-class))))) 
  (tool-bar-add-item-from-menu 'write-file "saveas" nil
			       :visible '(or buffer-file-name
					     (not (eq 'special
						      (get major-mode
							   'mode-class)))))
  (tool-bar-add-item-from-menu 'undo "undo" nil
			       :visible '(not (eq 'special (get major-mode
	  							'mode-class))))
  (tool-bar-add-item-from-menu (lookup-key menu-bar-edit-menu [cut])
			       "cut" nil
			       :visible '(not (eq 'special (get major-mode
								'mode-class))))
  (tool-bar-add-item-from-menu (lookup-key menu-bar-edit-menu [copy])
			       "copy")
  (tool-bar-add-item-from-menu (lookup-key menu-bar-edit-menu [paste])
			       "paste" nil
			       :visible '(not (eq 'special (get major-mode
								'mode-class))))
  (tool-bar-add-item-from-menu 'nonincremental-search-forward "search")
  ;;(tool-bar-add-item-from-menu 'ispell-buffer "spell")

  ;; There's no icon appropriate for News and we need a command rather
  ;; than a lambda for Read Mail.
  ;;(tool-bar-add-item-from-menu 'compose-mail "mail/compose")

  (tool-bar-add-item-from-menu 'print-buffer "print")
  (tool-bar-add-item "preferences" 'customize 'customize
		     :help "Edit preferences (customize)")

  (tool-bar-add-item "help" (lambda ()
			      (interactive)
			      (popup-menu menu-bar-help-menu))
		     'help
		     :help "Pop up the Help menu")

  ;; Toolbar button, mapped to handle-toggle-tool-bar in tool-bar.el
  ;; (Toolbar button - on systems that support it!)
  (global-set-key [toggle-frame-toolbar] 'handle-toggle-tool-bar)

  )

(provide 'aquamacs)

 