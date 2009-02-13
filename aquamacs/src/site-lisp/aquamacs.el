;; Aquamacs Emacs startup file
;; these defaults attempt to turn Emacs into a nice application for 
;; operating systems with a graphical user interface.
 
;; This is the central configuration file.  
;;
;; Author: David Reitter, david.reitter@gmail.com
;; Maintainer: David Reitter
;; Keywords: aquamacs
 
;; Last change: $Id: aquamacs.el,v 1.266 2009/02/13 17:44:23 davidswelt Exp $ 

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
 
;; Copyright (C) 2005,2006, 2007, 2008, 2009: David Reitter


(require 'aquamacs-tools)
 
(require 'aquamacs-macros)

(defvar aq-starttime 0)

(defun ats (txt) nil)

;; (defun ats (txt) 
;;   (message "ATS %s:  %s" (time-since aq-starttime) txt))



(setq aq-starttime (current-time))
(ats "started")



;; various functions


;; New documents
(defun new-empty-buffer-other-frame (&optional mode)
  "Opens a new frame containing an empty buffer."
  (interactive)
  (new-empty-buffer t mode))

(defun new-empty-buffer  (&optional other-frame mode)
  "Visits an empty buffer."
  (interactive)			
  (let ((buf (generate-new-buffer (mac-new-buffer-name "untitled"))))
    ;; setting mode is done before showing the new frame
    ;; because otherwise, we get a nasty animation effect
    (save-excursion
      (set-buffer buf)
      (if (or mode initial-major-mode)
	  (funcall  (or mode initial-major-mode)))
      (setq buffer-offer-save t)
      (put 'buffer-offer-save 'permanent-local t)
      (set-buffer-modified-p nil))
    (if other-frame
	(switch-to-buffer-other-frame buf)
      (let ((one-buffer-one-frame-force one-buffer-one-frame-mode))
	;; force new frame
	(switch-to-buffer buf)))))

(defalias  'new-frame-with-new-scratch 'new-empty-buffer)

(defun aquamacs-find-file (&optional filename)
  "Find an existing file or create a new buffer for it.  
If `one-buffer-one-frame' is non-nil, a new frame is created to
contain the new buffer."
  (interactive)
  (if (or (not one-buffer-one-frame)
	  filename
	  (< (buffer-size (window-buffer (frame-first-window))) 2))
      (if filename
	  (aquamacs-find-file-2 filename)
	(call-interactively 'aquamacs-find-file-2))
    ;; open new frame with empty buffer
    (let ((default-major-mode 'fundamental-mode))
      (new-empty-buffer nil)) ;;  'fundamental-mode
    (let ((buf (current-buffer)))
      (unwind-protect 
	  (progn 
	    ;; the following will open the file in the given
	    ;; frame, because the buffer shown is empty.
	    (call-interactively 'aquamacs-find-file-2)
	    (unless (eq (current-buffer) buf) ; get rid of old buffer
	      (kill-buffer buf)))
	    ;;(setq one-buffer-one-frame t))	
	(progn 
	   (when (eq major-mode 'dired-mode)
	     ;; do not obof variable itself buffer-local
	     ;; other packaes will bind it temporarily with let
	     ;; and then change the current buffer (e.g., by
	     ;; creating a tab).
	     ;; the behavior in that case is undefined.
	     (set (make-local-variable 'one-buffer-one-frame-inhibit) t))
	(when (and (buffer-live-p buf)
		 (< (buffer-size) 2))		; for safety
	    (kill-buffer buf)))))))


(defun aquamacs-find-file-2 (filename &optional wildcards)
  "Edit file FILENAME.
Switch to a buffer visiting file FILENAME, creating one if none
already exists.  Interactively, the default if you just type RET
is the current directory, but the visited file name is available
through the minibuffer history: type M-n to pull it into the
minibuffer.

If the buffer is shown somewhere in tabbar-mode, select that
window.

You can visit files on remote machines by specifying something
like /ssh:SOME_REMOTE_MACHINE:FILE for the file name.  You can
also visit local files as a different user by specifying
/sudo::FILE for the file name.  See the Info
node `(tramp)Filename Syntax' in the Tramp Info manual, for more
about this.

Interactively, or if WILDCARDS is non-nil in a call from Lisp,
expand wildcards (if any) and visit multiple files.  You can
suppress wildcard expansion by setting `find-file-wildcards' to nil.

To visit a file without any kind of conversion and without
automatically choosing a major mode, use \\[find-file-literally]."

  (interactive (find-file-read-args "Find file: " nil))

  (let ((value (find-file-noselect filename nil nil wildcards)))

    (if tabbar-mode
	(if (listp value)
	    (mapcar 'switch-to-buffer-in-tab (nreverse value))
	  (switch-to-buffer-in-tab value))
      (if (listp value)
	  (mapcar 'switch-to-buffer (nreverse value)))
      (switch-to-buffer value))))


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

  ;; define a single command to be included in the recentf menu
  (defun recentf-clearlist ()
    "Remove all files from the recent list."
    (interactive)
    (setq recentf-list ())
    (setq file-name-history ()))


  ;; make sure there are no old customizations around
  ;; N.B.: if no customization file is present, 
  ;; aquamacs-customization-version-id is 0 or nil
  ;; activated by aquamacs-load-preferences

  (defun aquamacs-activate-features-new-in-this-version ()

    ;; aquamacs-customization-version-id contains the version id
    ;; of aquamacs when the customization file was written

    (when (and (not (equal init-file-user nil)) ;; no .emacs was read (-q option)
	       aquamacs-customization-version-id
	       (> aquamacs-customization-version-id 0))

    (if (< aquamacs-customization-version-id 092.5)

	;; make sure we fit frames
	(assq-set 'user-position nil 'default-frame-alist)

      )

    (if (and (boundp 'aquamacs-default-styles)
	     (< aquamacs-customization-version-id 092.8))
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
	  ;; change the customizations.el file to not contain the setq statement any more
	  ;; old versions of Aquamacs (unclear which ones) wrote it to custom-file this way.
	  (if (file-exists-p custom-file)
	      (with-temp-file custom-file
		(insert-file-contents custom-file)
		(replace-regexp "(setq aquamacs-customization-version-id [0-9\\.]+)"
				"" nil (point-min) (point-max))))
	  ;; in the mode-spec styles, this is taken care of
	  ;; anyways
	  (setq default-frame-alist 
		(assq-delete-all 'scroll-bar-width default-frame-alist))
	  (setq special-display-frame-alist 
		(assq-delete-all 'scroll-bar-width special-display-frame-alist))
      
	  (if (boundp 'aquamacs-default-styles)
	  (mapc 
	   (lambda (th)
	     (unless (assq (car th) aquamacs-default-styles)
	       (assq-set (car th) 
			 (cdr th)
			 'aquamacs-default-styles)))
	   ;; list
	   (filter-fonts '(
			   (help-mode (tool-bar-lines . 0) (fit-frame . t)) 
			   (custom-mode (tool-bar-lines . 0) (fit-frame . t))))))))
    (if (and (boundp 'aquamacs-default-styles)
	     (< aquamacs-customization-version-id 99.1))
	(mapc (lambda (formode)
		(assq-delete-all 'tool-bar  
				 (cdr-safe (cdr-safe (car-safe 
						      (cdr-safe formode))))))
	      aquamacs-default-styles))
    (when (< aquamacs-customization-version-id 131)
      ;; turn on tool bar only once to show the nice new tool bar
      (add-hook 'after-init-functions 
		(lambda () 
		  (mapc (lambda (frame)
			  (modify-frame-parameters frame (list (cons 'tool-bar-lines 1))))
			(frame-list)))))
    (when (< aquamacs-customization-version-id 140)
      (condition-case nil
	  (unless (boundp 'aquamacs-140-custom-file-upgraded)
	    (with-temp-buffer 
	      (princ "
;; for compatibility with older Aquamacs versions
 (defvar aquamacs-140-custom-file-upgraded t)
 (unless (fboundp 'auto-detect-longlines) (defun auto-detect-longlines () t))"
		     (current-buffer))
	      (append-to-file (point-min) (point-max) custom-file)))
	(error nil)))
    
    (when (< aquamacs-customization-version-id 146)
      (condition-case nil
	  (aq-replace-in-list text-mode-hook 'turn-on-longlines 'turn-on-word-wrap)
	(error nil)))

    (when (< aquamacs-customization-version-id 160)
      ;; did the user not explicitly set obof or tabbar?
      (when (eq tabbar-mode 'default)
	(custom-set-variables '(tabbar-mode nil)))
      (when (eq one-buffer-one-frame-mode 'default)
	(custom-set-variables '(one-buffer-one-frame-mode t))))
    
    (when (and (boundp 'aquamacs-default-styles)
	       (< aquamacs-customization-version-id 161))
      ;; some tidying up from previous versions
      (let ((default-frame-parms (assq 'default aquamacs-default-styles)))
	(when default-frame-parms
	  (setq aquamacs-default-styles
		(cons (cons 'style-default (cdr-safe default-frame-parms))
		      (assq-delete-all
		       'default  
		       aquamacs-default-styles))))))
    (when (< aquamacs-customization-version-id 162)
      (aquamacs-import-frame-parameters-to-auto-faces)) 
    ;; Print warnings / compatibility options
    


  ;; create fontsets where needed
    (mapc
     (lambda (font-string)
       (when (and font-string (string-match "^fontset-\\([a-z]+\\)\\([0-9]+\\)$" font-string))
	 (let ((font (intern (match-string 1 font-string)))
	       (size (list (string-to-number (match-string 2 font-string)))))
	   
	   (let ((font-alist  '((monaco "apple" "monaco*" "medium" "r" "normal")
				(lucida  "apple" "lucida grande*" "medium" "r" "normal")
				(lucida_typewriter "apple" "lucida sans typewrite*" "medium" "r" "normal")
				(lucida_console  "apple" "lucida console*" "medium" "r") 
				(courier "courier*" "medium" "r" nil)
				(vera_mono "bitstream vera sans mono" "medium" "r" "normal"))))
	     (require 'aquamacs-mac-fontsets)
	     (apply #'create-aquamacs-fontset (append (cdr (assq font font-alist)) (list size) (list (symbol-name font))))))))
     (list (cdr-safe (assq 'font default-frame-alist)) (cdr-safe (assq 'font special-display-frame-alist))))


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

(defun aquamacs-cua-warning ()
    (and (not cua-mode)
	 (message 
	  "Warning: You have turned off `cua-mode' in your customizations 
or init file. Without this mode, Aquamacs will behave in an 
un-Mac-like way when you select text and copy&paste it.")))


(defun aquamacs-notice-user-settings ()
  "React to various user settings."

  (protect

   (unless noninteractive
     (unless (equal init-file-user nil) ;; no .emacs was read (-q option)
       (aquamacs-load-scratch-file))
     (aquamacs-cua-warning)
     (and (fboundp 'osx-key-mode-command-key-warning) (osx-key-mode-command-key-warning)))

   ;;   (if global-smart-spacing-mode
   ;;       (global-smart-spacing-mode 1))
   ;; turn on smart spacing in all text mode buffers
   (toggle-text-mode-smart-spacing 
    (if (memq 'smart-spacing-mode text-mode-hook) 1 0))

   (if global-hl-line-mode
       (global-hl-line-mode 1))

   (if global-show-newlines-mode
       (global-show-newlines-mode 1))

   (if (eq tabbar-mode 'default)
       (customize-set-variable 'tabbar-mode t))
   (if (eq one-buffer-one-frame-mode 'default)
       (customize-set-variable 'one-buffer-one-frame-mode nil))

   ;; have fringe-mode reflect user settings
   (setq fringe-mode
	 (cons (cdr-safe (assq 'left-fringe default-frame-alist))
	       (cdr-safe (assq 'right-fringe default-frame-alist))))
   (if (eq fringe-mode '(nil)) (setq fringe-mode))

   ;; run this after the frames have been established
   ;; via default-frame-alist
   (run-with-idle-timer 
    0.1 nil
    (lambda ()
      (mapc
       (lambda (frame) 
	 (let ((fs (frame-parameter frame 'fullscreen)))
	   (when (memq fs '(fullboth fullheight fullwidth))	    
	     (modify-frame-parameters 
	      frame (list (cons 'fullscreen nil)))
	     (modify-frame-parameters 
	      frame (list (cons 'fullscreen fs)))
	     (message
	      (substitute-command-keys 
	       "Press \\[aquamacs-toggle-full-frame] to exit full screen editing.")))))
       (frame-list))))))

; (aquamacs-notice-user-settings)

;; redefine this
;; can be redefined at dump time
  (defun startup-echo-area-message ()
    (concat
     (propertize 
       "Aquamacs is based on GNU Emacs 22, a part of the GNU/Linux system."
       'face (list :family "Lucida Grande" :height 140))
     ;;The GPL stipulates that the following message is shown.
     (propertize 	
      (substitute-command-keys " It is Free Software: you can improve and redistribute it under the GNU General Public License, version 3 or later. Copyright (C) 2008 Free Software Foundation, Inc. (C) 2008 D. Reitter. No Warranty.") 
      'face (list :family "Lucida Grande" :height 110))))

;; (progn (message "%s" (startup-echo-area-message)) (sit-for 4))
;; 
(defvar aquamacs-faces-changed)
(defun aquamacs-menu-bar-options-save (&optional maybe-save)
    "Save current values of Options menu items using Custom.
Return non-nil if options where saved.
MAYBE-SAVE t means: only save if needed"
    (interactive)
    (setq aquamacs-customization-version-id aquamacs-version-id)
    (let ((need-save nil))
      ;; These are set with menu-bar-make-mm-toggle, which does not
      ;; put on a customized-value property.
      (dolist (elt aquamacs-menu-bar-options-to-save)
	(and (customize-mark-to-save elt)
	     (setq need-save (cons elt need-save)))) 
      ;; These are set with `customize-set-variable'.
      (dolist (elt aquamacs-menu-bar-customize-options-to-save)
	(and (get elt 'customized-value) 
	     (customize-mark-to-save elt)
	     (setq need-save (cons elt need-save))))
      ;; Save if we changed anything.
      (if (or aquamacs-faces-changed need-save (not maybe-save))
	  (progn (custom-save-all)
		 (setq aquamacs-faces-changed nil)
		 (message "Options saved."))
	(message "There's no need to save your options."))
      need-save))
;; (aquamacs-menu-bar-changed-options) 
;; aquamacs-customization-version-id
  (defun aquamacs-menu-bar-changed-options ()
    (let ((need-save nil))
      (dolist (elt aquamacs-menu-bar-options-to-save)
	(and (not (eq elt 'default-frame-alist)) ;; work around a bug: saved-value of this is incorrect for tool-bar-lines
	     (aquamacs-variable-customized-p elt)
	     (setq need-save (cons elt need-save))))
      (dolist (elt aquamacs-menu-bar-customize-options-to-save)
	(and (get elt 'customized-value) 
	     (aquamacs-variable-customized-p elt)
	     (setq need-save (cons elt need-save))))
      need-save))

;; make sure the old variant isn't called, overwriting the
;; Aquamacs settings
(fset 'menu-bar-options-save 'aquamacs-menu-bar-options-save)

  (defcustom aquamacs-save-options-on-quit 'ask
    "If t, always save the options (from the options menu) when quitting.
If set to `ask' (default), the user is asked in case the options
have changed."
    :group 'Aquamacs
    :type '(choice (const nil)  (const ask) (const t)))

;; (aquamacs-variable-customized-p 'aquamacs-styles-mode)    
;; (aquamacs-variable-customized-p 'case-fold-search)
;; (aquamacs-variable-customized-p 'mac-option-modifier)
;; (aquamacs-variable-customized-p 'default-frame-alist)
;; (print (get 'default-frame-alist 'saved-value))
;; (aquamacs-variable-customized-p 'global-smart-spacing-mode)
;; (print (get 'global-smart-spacing-mode 'saved-value))


(defun aquamacs-variable-customized-p (symbol)
    "Returns t if variable SYMBOL has a different value from what was saved."
    (custom-load-symbol symbol)
    (let* ((get (or (get symbol 'custom-get) 'default-value))
	   (value (funcall get symbol))
	   (customized-value  (car-safe (get symbol 'customized-value)))
	   (saved (get symbol 'saved-value))
	   (standard (get symbol 'standard-value))
	   (comment (get symbol 'customized-variable-comment)))

      (if (or (eq customized-value value) ;; otherwise it's rogue
	      (and (eq customized-value nil) value)
	      (eq (condition-case nil (eval customized-value) (error nil)) value))
	  (let ((cmp (or saved
			 (condition-case nil
			     (eval (car standard))
			   (error nil)))))
	    (not (or (equal cmp (list (custom-quote value)))
		     ;; not quite clear why this is doubled
		    (equal (custom-quote cmp) (custom-quote value))
		    (and (listp value) (string-match "-alist$" (symbol-name symbol)) ;; heuristic...
			 (condition-case nil
			     (equal (sort (copy-alist (eval (car cmp))) (lambda (x y) (string< (car x) (car y))))
				    (sort (copy-alist value) (lambda (x y) (string< (car x) (car y)))))
			   (error nil)))))))))

;;  (filter-list (aquamacs-menu-bar-changed-options)
;; 			  (list 'aquamacs-customization-version-id
;; 				'smart-frame-prior-positions
;; 				'aquamacs-additional-fontsets
;; 				'initial-frame-alist
;; 				'transient-mark-mode))
  (defun aquamacs-ask-to-save-options ()
  "Checks if options need saving and allows to do that.
Returns t."
  (interactive)
  (let* ((changed (aquamacs-menu-bar-changed-options)))
    (if (and (or aquamacs-faces-changed
		 (filter-list changed
			  (list 'aquamacs-customization-version-id
				'smart-frame-prior-positions
				'aquamacs-additional-fontsets
				'initial-frame-alist
				'transient-mark-mode)))
	     ;; depends on return value of `aquamacs-menu-bar-options-save'
	     ;; NOT implemented for the standard menu-bar-options-save!
	     ;; ask user whether to accept these saved changes
	     (if (eq aquamacs-save-options-on-quit 'ask)
		 (progn 
		   ;;		   (print changed)
		   (y-or-n-p "Options have changed - save them? "))
	       aquamacs-save-options-on-quit))
	(aquamacs-menu-bar-options-save)))
  t)
(defun aquamacs-save-buffers-kill-emacs (&optional arg)
    "Offer to save each buffer, then kill this Emacs process.
With prefix arg, silently save all file-visiting buffers, then kill.
Like `save-buffers-kill-emacs', except that it doesn't ask again
if modified buffers exist."
    (interactive "P")
    (aquamacs-create-preferences-dirs)
    (let ((saved-timer-idle-list timer-idle-list))
      (unwind-protect 
	  (progn
	    ;; deactivate all idle timers so that
	    ;; our prompt is not being overwritten by obnoxious 
	    ;; echo area messages
	    ;; Caveat: this may impede useful functionality in "view"
	    ;; when reviewing stuff.
	    (setq timer-idle-list)
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
		   (funcall confirm-kill-emacs "Really exit Aquamacs? "))
	       (kill-emacs)))
	(setq timer-idle-list saved-timer-idle-list))))
;; (defun aquamacs-mac-ae-quit-application (event)
;;   "Quit the application Emacs with the Apple event EVENT."
;;   (interactive "e")
;; ;;  (aquamacs-save-buffers-kill-emacs)
;;   (let ((ae (mac-event-ae event)))
;;     (unwind-protect ; IT APPEARS THAT THIS CAN'T BE COMPILED.
;; 	(aquamacs-save-buffers-kill-emacs)
;;       ;; Reaches here if the user has canceled the quit.
;;       (message "Quit application: canceled.")
;;       (mac-resume-apple-event ae -128))))

;; unwind-protect form is non-functional for some reason
;; potentially because of byte-compiling this file.
;; using `eval' doesn't work...
 (defun aquamacs-mac-ae-quit-application (event)
   "Quit the application Emacs with the Apple event EVENT."
   (interactive "e")
   (aquamacs-save-buffers-kill-emacs)
   (mac-resume-apple-event ae -128))


;; workaround for people who still call this in their .emacs
  (defun mwheel-install ()
    (message "mwheel-install ignored in Aquamacs- mouse wheel support is present by default.")
    t)

;; restore *scratch*

(defcustom aquamacs-scratch-file 
  "~/Library/Application Support/Aquamacs Emacs/scratch buffer"
  "File name to save the scratch file. Set to nil to not save it."
  :group 'Aquamacs
  :version "22.0")

;; read scratch file
;; (aquamacs-load-scratch-file)

;; this will prevent Aquamacs from automatically saving the buffer in
;; case the user saves it elsewhere (under a different name)
;; this method is not perfect: it is not called if the buffer is
;; manually associated with a different file.
(defun aquamacs-do-not-save-without-query-if-saved-elsewhere ()
  (unless (equal aquamacs-scratch-file buffer-file-name)
    (setq buffer-save-without-query nil)))

(defun aquamacs-load-scratch-file ()
  "Load the scratch buffer.
The *scratch* buffer is loaded from `aquamacs-scratch-file'.
No errors are signaled."
  (when (and aquamacs-scratch-file (get-buffer "*scratch*"))
    (aquamacs-set-defaults 
     '((desktop-buffers-not-to-save
	"\\(^nn\\.a[0-9]+\\|\\.log\\|\\*scratch\\*\\)$")))
    (with-current-buffer "*scratch*"
      (condition-case nil
	  (progn
	    (let ((coding-system-for-read 'utf-8)
		  (buffer-undo-list t))
	      (if (file-exists-p aquamacs-scratch-file)
		  ;; if file unreadable, this will trip the condition-case
		  (insert-file-contents aquamacs-scratch-file 
					nil nil nil 'replace))
	      (set-buffer-modified-p nil))
	    (setq buffer-undo-list nil)
	    (setq buffer-file-name aquamacs-scratch-file)
	    (setq buffer-offer-save nil)	
	    ;; Buffer auto save caused severe problems on occasion:
	    ;; Aquamacs would ask about the file being changed upon exit,
	    ;; answering "no" would cancel exiting emacs,
	    ;; answer "yes" would delete the file!
	    (aquamacs-set-defaults 
	     `((recentf-exclude ,(append (list 
					  (expand-file-name aquamacs-scratch-file)) recentf-exclude))))
	    (setq buffer-save-without-query t)
	    (put 'buffer-save-without-query 'permanent-local t)
	    (setq buffer-file-coding-system 'utf-8)
	    (add-hook 'before-save-hook 
		      'aquamacs-do-not-save-without-query-if-saved-elsewhere
		      nil 'local))
      ;; we aso need to avoid asking whether to save this
      ;; do this here so that we never save the scratch file
      ;; if it hasn't been successfully loaded initially
      ;; (or if the file simply doesn't exist yet)
	(error (insert (format "Scratch file %s could not be read.\nThis buffer will not be saved automatically." aquamacs-scratch-file)) nil)))))


(defun toggle-text-mode-smart-spacing (&optional on)
  "Toggle `smart-spacing-mode' in `text-mode-hook'"
  (interactive)
  (let ((enable (cond ((eq on 1) t)
		      ((eq on 0) nil)
		      (t (not (memq 'smart-spacing-mode text-mode-hook))))))
   (if enable
	(add-hook 'text-mode-hook 'smart-spacing-mode)
      (remove-hook 'text-mode-hook 'smart-spacing-mode))
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
	(if (or (derived-mode-p 'text-mode) text-mode-variant)
	    (smart-spacing-mode (if enable 1 0)))))))


(defun aquamacs-setup ()
 

  (aquamacs-mac-initialize) ;; call at runtime only
  (defvar aquamacs-mac-application-bundle-directory
    "This is actually defined in mac-extra-functions.el")

  (ats "aquamacs-mac-initialize done")


  (require 'aquamacs-tools)
  (ats "aquamacs-tools done")
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
    "Like `old-yes-or-no-p' - use that function instead."
    (aquamacs-ask-for-confirmation text t))
  (defun aquamacs-y-or-n-p (text)
    "Like `old-y-or-n-p' - use that function instead."
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

  (defun aquamacs-bell ()
    (let ((ring-bell-function nil))
      (ding)))

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
	  (aquamacs-bell)
	  ad-do-it)
      ;; else
      ad-do-it))
    


  ;; Find-file may open a new frame
  (if window-system
      (global-set-key [remap find-file] 'aquamacs-find-file))
  
  
  (defun font-exists-p (fontorfontset)
    (condition-case nil
	(or
	 (font-info fontorfontset)
	 (fontset-info fontorfontset)
	 )
      (error nil)
      )
    )

  ;; Mode-Line Faces
  ;; face (defined and) applied using pretty-modeline.patch

  (defface aquamacs-variable-width '((t
		    :family "Lucida Grande"
		    :height 120)) ;; do use the frame-wide setting: it's very font dependent
  "Aquamcas default face (variable width).
Used by the modeline faces `mode-line' and `mode-line-inactive'."
  :group 'Aquamacs)

  (defun aquamacs-set-modeline-faces (&optional theme)
    (set-face-attribute 'mode-line nil
			:inherit 'aquamacs-variable-width
			:weight 'normal
			:width 'normal
			:slant 'normal
			:underline nil
			:strike-through nil)
    (set-face-attribute 'mode-line-inactive nil
			:inherit 'aquamacs-variable-width
			:weight 'normal
			:width 'normal
			:slant 'normal
			:underline nil
			:strike-through nil)
    (set-face-attribute 'mode-line-flags nil
			:family "Monaco"))
  (defvar color-theme-install-hook nil)
  ;; some themes override mode-line faces;
  ;; while they should be able to set colors, they should not remove :family or :inherit attribues
  (add-hook 'color-theme-install-hook 'aquamacs-set-modeline-faces)
  (aquamacs-set-modeline-faces)
  

  ;; tabbar needs to be defined before osxkeys
  (if (running-on-a-mac-p)
      (require 'aquamacs-tabbar) 
    ;; aquamacs-tabbar doesn't work without windows
    ;; do this before osx_defaults so that the load-path is not user-infested at this time
    ;; (to force loading of our own tabbar)
    (require 'tabbar))

  (aquamacs-set-defaults `((tabbar-mode ,(if (running-on-a-mac-p) t nil))))
  (setq tabbar-mode 'default) ;; will be set later on

  ;; Mac OS X specific stuff 

  (ats "osx_defaults ...")

  (ats "load..")
  (require 'osx_defaults) ;; always load this to define various things

  (if (running-on-a-mac-p)
      (progn
	(ats "setup...")
	(aquamacs-osx-defaults-setup))
    (eval-when-compile
      (aquamacs-osx-defaults-setup)))

  (ats "osx_defaults done")


;; POST-LOAD-PATH adjustment
;; from here on, the load path has been altered to include the user's 
;; own libraries (before our own).  Users may replace libraries
;; that we load using "require" and "load".

;; Page scrolling


  (ats "aquamacs-editing")
  (require 'aquamacs-editing)

  ;; overwrites CUA stuff
  (global-set-key [remap scroll-up]	      'aquamacs-page-down)
  (global-set-key [remap cua-scroll-up]	      'aquamacs-page-down)
  (global-set-key [remap scroll-up-mark]      'aquamacs-page-down-extend-region)
  (global-set-key [next] 	      'aquamacs-page-down)
  (global-set-key [\S-next] 	      'aquamacs-page-down-extend-region)
  (global-set-key [\M-up]	      'aquamacs-page-up)
  (global-set-key [remap scroll-down]	      'aquamacs-page-up) 
  (global-set-key [remap cua-scroll-down]	      'aquamacs-page-up)
  (global-set-key [remap scroll-down-mark]      'aquamacs-page-up-extend-region)
  (global-set-key [prior]	      'aquamacs-page-up)
  (global-set-key [\S-prior]	      'aquamacs-page-up-extend-region)

  ;; was here in 0.9.5, taken out
  ;;(global-set-key [C-up]        'pager-row-up)
  ;;(global-set-key [C-down]      'pager-row-down)
 

;; so here's a SLOW workaround


;; set ispell-program-name to correct name, or to nil
;; if neither aspell nor ispell are available.
;; original definition in Emacs always uses "ispell",
;; even if it isn't installed.

;; (aquamacs-set-defaults 
;;  `((ispell-program-name
;;     ,(or (if (locate-file "aspell" exec-path exec-suffixes 'file-executable-p) 
;; 	     "aspell")
;; 	 (if (locate-file "ispell" exec-path exec-suffixes 'file-executable-p)
;; 	     "ispell")))))
 
;; ;; find cocoAspell's directories automatically
;; (defun aquamacs--configure-aspell ()
;;   "Configure Aspell automatically if it hasn't been configured already."
;;   (remove-hook 'ispell-kill-ispell-hook 'aquamacs--configure-aspell) 
;;   ;; only once please
;;   (when (and (equal ispell-program-name "aspell")
;; 	     ;;	     (not ispell-dictionary-alist) ;; nothing found yet
;; 	     (not (getenv "ASPELL_CONF")))
;;     ;; don't do this - would assume default dirs 	
;;     ;;(ispell-maybe-find-aspell-dictionaries) ;; try to find dictionaries
;;     ;; (setq ispell-have-aspell-dictionaries nil)
;;     ;; to find out if it's already configured
;;     ;;(unless ispell-dictionary-alist
;;       (condition-case nil
;; 	  (if (with-temp-buffer
;; 	      ;; is there a stored cocoaSpell configuration? 
;; 		(ispell-call-process ispell-program-name nil t nil "dicts")
;; 		(eq (point-min) (point-max))) ;; no output?
;; 	      ;; OK, aspell has not been configured by user on Unix level
;; 	      ;; or in Emacs
;; 	      (setenv 
;; 	       "ASPELL_CONF"
;; 	       (let ((config-dir (expand-file-name 
;; 				  "~/Library/Preferences/cocoAspell"))
;; 		     (dict-dir 
;; 		      (car ;; use the first subdir in that path
;; 		       (file-expand-wildcards 
;; 			"/Library/Application Support/cocoAspell/aspell*"))))
;; 		 ;; check if the directories are readable
;; 		 (if (file-readable-p config-dir) 
;; 		     (setq config-dir (concat "conf-dir " config-dir))
;; 		   (setq config-dir nil))
;; 		 (if (file-readable-p dict-dir) 
;; 		     (setq dict-dir (concat ";dict-dir " dict-dir))
;; 		   (setq dict-dir nil))
;; 		 (concat config-dir dict-dir))))
;; 	(error nil))))

;; (add-hook 'ispell-kill-ispell-hook 'aquamacs--configure-aspell)
;; unit test:
; (setenv "ASPELL_CONF" nil)
; (aquamacs--configure-aspell) 
; (getenv "ASPELL_CONF")

(ats "aquamacs-menu ...")
  (require 'aquamacs-menu)
(ats "aquamacs-menu done")
  (require 'aquamacs-bug) ;; successfully send bug reports on the Mac
(ats "aquamacs-bug done")
  


;; visual line navigation
(require 'visual-line)


(require 'saveplace)
;;  (require 'longlines) 
(global-visual-line-mode 1)
  (aquamacs-set-defaults 
   `((global-visual-line-mode t)
     (text-mode-hook (smart-spacing-mode auto-detect-wrap)) 
     (save-place t)
     (save-place-limit 500) ;; speed on quit
     (save-place-forget-unreadable-files nil) ;; too slow
     (mail-setup-with-from nil)  
					; Colorized fonts
					; Turn on font-lock in all modes that support it
     (global-font-lock-mode t)

     (font-lock-maximum-decoration t)

					; Make Text mode the default mode for new buffers
					; turn on Auto Fill mode automatically in Text mode  
     (initial-major-mode text-mode)


					; scroll just one line when hitting the bottom of the window
     (scroll-step 1)
     (scroll-conservatively 10000)
     ;; Start scrolling when 2 lines from top/bottom 
     (scroll-margin 0)
     (visual-scroll-margin 2)

     (tramp-verbose 4)                  ;; don't annoy us

     ;; workaround for a bug in viper cursor color saving mechanism
     (viper-replace-overlay-cursor-color "red4")			       

     ;; no flash instead of that annoying bell
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
		  'point-entered 'minibuffer-avoid-prompt))))

;; on by default
(if (and (fboundp 'mac-inline-input-method-mode) 
	 (not (boundp 'mac-inline-input-method-missing)) 
	 (running-on-a-mac-p))
    (progn
      (aquamacs-set-defaults '((mac-inline-input-method-mode t))))
  ;; otherwise, redefine the mode function
  ;; so that it won't be called when loading custom-file.
  (defvar mac-inline-input-method-missing t)
  (defvar mac-inline-input-method-mode nil)
  (defun mac-inline-input-method-mode ( &optional onoff)
      (interactive)
      (message 
       "mac-input-method-mode not available without window system.")))


  ;; set a nntp server if there's none
  (if (getenv "NNTPSERVER") ;; (gnus-getenv-nntpserver)
      nil
    (aquamacs-set-defaults '((setq gnus-select-method 
				   '(nntp "news.readfreenews.net")))))

					; activate the modes now
  (global-font-lock-mode 1) 
  (column-number-mode 1)

					; ------- Frames (OSX Windows) ----------

  (ats "before view")
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


(require 'color-theme-autoloads)
(require 'aquamacs-autoface-mode)
(autoload 'aquamacs-styles-mode "aquamacs-styles.el" "Automatically set frame style according to major mode" 'interactive nil)

 (ats "styles done")

;; follow mouse autoload
(autoload 'turn-on-follow-mouse "follow-mouse.el"   "Moving the mouse will automatically select the window under it" 'interactive nil)
(autoload 'turn-off-follow-mouse "follow-mouse.el"   "Moving the mouse will not automatically select the window under it" 'interactive nil)
(autoload 'toggle-follow-mouse "follow-mouse.el"   "Toggle whether moving the mouse automatically selects the window under it" 'interactive nil)


  (provide 'drews_init)	; migration from 0.9.1 (require in customizations)
 (ats "drew done")

  ;; http://www.emacswiki.org/cgi-bin/wiki/DrewsElispLibraries
  
  ;; set default fonts - after aquamacs-frame-setup has initialized things


;; with the demise of aquamacs-styles, we don't need to create
;; fontsets any longer.
;; this will speed up the startup.

;; (when (fboundp 'create-aquamacs-fontset)
;;   (create-aquamacs-fontset "apple" "lucida grande*" "medium" "r" "normal" '(12) "lucida")
;;   (create-aquamacs-fontset "apple" "monaco*" "medium" "r" "normal"  '(12) "monaco"))

;; (if (fontset-exist-p "fontset-monaco12") 
;;       (assq-set 'font "fontset-monaco12" 'default-frame-alist)
;;     (if (fontset-exist-p "fontset-mac_roman_12") 
;; 	(assq-set 'font "fontset-mac_roman_12" 'default-frame-alist)

;;       (if (fontset-exist-p "fontset-lucida14") 
;; 	  (assq-set 'font "fontset-lucida14" 'default-frame-alist)
;; 	)
;;       )
;;     )

  ;; (if (fontset-exist-p "fontset-mac_roman_12") 
;;       (assq-set 'font "fontset-mac_roman_12" 'special-display-frame-alist)

;;     (if (fontset-exist-p "fontset-monaco12") 
;; 	(assq-set 'font "fontset-monaco12" 'special-display-frame-alist))
;;     )

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

;; set some defaults which will be set by other functions anyways
;; just so we save them to standard-value
  (assq-set 'menu-bar-lines 1 'default-frame-alist)
  (assq-set 'tool-bar-lines 1 'default-frame-alist)

(aquamacs-set-defaults `((default-frame-alist ,default-frame-alist)
			   (special-display-frame-alist ,special-display-frame-alist)))

   (ats "fontsets done")

  ;; here would be the place to turn on mode-spec styles AFTER setting default-frame-alist
  ;; so everything is copied over to the 'default style as appropriate
  ;; mode-specific font settings
  ;;  if turned on, default-frame-alist should be empty now
  (aquamacs-set-defaults '((aquamacs-styles-mode nil)))
  ;; (require 'aquamacs-styles)   ; deprecated

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

  (when window-system

  (require 'smart-frame-positioning)
   (ats "sfp loaded")

  (aquamacs-set-defaults 
   '((smart-frame-positioning-mode t)
     ( smart-frame-positioning-enforce t) ;; and enforce it
     )
   )

  (smart-frame-positioning-mode t) ;; and turn on!
  (ats "smart-frame-positioning-mode done")
  )

  (defvar mac-pass-option-to-system 'deprecated)

   (ats "loading obof")
  (require 'one-buffer-one-frame)
  ;; necessary to ensure the value is saved with the Options
  ;; (setting the default)
  (aquamacs-set-defaults '((one-buffer-one-frame-mode nil)))
  ;; so we can detect changes to the variable by the user.
  (setq one-buffer-one-frame-mode 'default) 
  ;; will be set later on

   (ats "obof done.")

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

  
  (add-hook 'after-init-hook 'aquamacs-notice-user-settings)
  
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
 
  (aquamacs-set-defaults '((inhibit-startup-message t)))

  
 




;;'blue-foreground-face)) 
;;(- (frame-parameter nil 'width) 5) 
;; let's just hope that this is the width of the echo area

;; (progn  (message (startup-echo-area-message)) (sleep-for 5))
;; buffer-file-name

(if (running-on-a-mac-p)
      (defun use-fancy-splash-screens-p () t))

        
;; the following causes not-so-good things to happen.
;; (defun fancy-splash-default-action () nil)

  (require 'savehist) ;; because we configure and activate it

  (aquamacs-set-defaults
   '((fancy-splash-image "aquamacs-splash-screen.jpg")
     (fancy-splash-max-time 3000)))
    
  ;; while pc selection mode will be turned on, we don't
  ;; want it to override Emacs like key bindings. 
  ;; we need to fill the following variable with something
  ;; that is non-nil.
  (setq pc-select-default-key-bindings '(([home]      . beginning-of-buffer)
					 ([end]      . end-of-buffer)
					 ))

  (aquamacs-set-defaults 
   '(
     ;; scratch buffer should be empty 
     ;; the philosophy is: don't give users any text to read to get started!    
     (initial-scratch-message nil)
     (focus-follows-mouse nil) ;; do not mess with user's mouse!
     (resize-mini-windows t)
     (mouse-wheel-progressive-speed t)
   ;;  (mouse-wheel-scroll-amount (1 (shift . 0.5) (control . 0.2) ))
     (mouse-wheel-scroll-amount (1 ((shift) . 0.5) ((control) . 0.2) ))
   ;;  (pc-select-meta-moves-sexps t) ;; leave nil so we can otherwise assign M-left/right
     (pc-select-selection-keys-only t)
     (pc-selection-mode t)
     (show-paren-mode t)
     (blink-cursor-mode t)
     (cursor-type (bar . 2))
     ;; on modern systems, loading files doesn't take so long any more.
     (large-file-warning-threshold 20000000)
     ;; show unfinished key inputs early
     (echo-keystrokes 0.1)
     ;; save minibuffer history
     (savehist-mode 1)
     ;; do not create backups
     (make-backup-files nil)
     ;; higher undo limit
     (undo-outer-limit 12000000)
     (undo-limit 80000)
     )) 
   

  
					; activate the modes

   (ats "enabling pc-sel")
  (pc-selection-mode 1) 
  (show-paren-mode 1) 
  (blink-cursor-mode 1)
  (savehist-mode 1)

  ;; should not be needed - done by a-s-d above
  ;; (set-default 'cursor-type '(bar . 2))


  ;;; for initial buffer
;;; for some reason
  (defun aquamacs-turn-on-buffer-offer-save-in-scratch ()
    (protect
     (if (get-buffer "*scratch*")
	 (with-current-buffer "*scratch*"
	   (setq buffer-offer-save t)))))
    
(add-hook 'after-init-hook 'aquamacs-turn-on-buffer-offer-save-in-scratch)

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
	      global-hl-line-mode
	      global-show-newlines-mode
	      show-paren-mode
	      transient-mark-mode 
	      global-font-lock-mode
	      display-time-mode 
	      display-battery-mode
	      mac-inline-input-method-mode
	      one-buffer-one-frame-mode 
	      aquamacs-styles-mode
	      aquamacs-autoface-mode
	      default-frame-alist ;; does this not prevent users from setting these?
;;;	     do not save initial-frame-alist - it is stored by smart-frame-positions
;;;  to do: frame-notice-user-settings should use default-frame-alist in addition to
;;; initial-frame-alist, so "adopt frame parameters as default" should work.
	      mac-option-modifier)
	    (and (boundp 'aquamacs-additional-fontsets)
		   '(aquamacs-additional-fontsets))
		   ;; retain for backwards compatibility
	    (mapcar (lambda (x) 
		      (emkm-name (car x))) 
		    (and (boundp 'emulate-mac-keyboard-mode-maps)
			 emulate-mac-keyboard-mode-maps))))

  (defvar aquamacs-menu-bar-customize-options-to-save
    '(scroll-bar-mode
     debug-on-quit debug-on-error
     tooltip-mode  
     uniquify-buffer-name-style 
     ;; fringe-mode and tool-bar-mode saved in default-frame-alist
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
     aquamacs-customization-version-id
     mac-print-monochrome-mode
     make-backup-files
     tabbar-mode
     ))

  
  (add-hook 'kill-emacs-query-functions 'aquamacs-ask-to-save-options)


  

(global-set-key [remap save-buffers-kill-emacs] 
		'aquamacs-save-buffers-kill-emacs)



(if (and (boundp 'mac-apple-event-map) mac-apple-event-map)
    (define-key mac-apple-event-map [core-event quit-application]
      'aquamacs-mac-ae-quit-application))

; (define-key mac-apple-event-map [core-event quit-application]      'mac-ae-quit-application)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Temporary stuff for releases according to admin/FOR-RELEASE

  (setq undo-ask-before-discard nil)
;; http://sourceforge.net/tracker/index.php?func=detail&aid=1295333&group_id=138078&atid=740475				      


  ;; workarounds for current bugs  
  '			      ; can't get rid of the menu bar on a Mac
  (easy-menu-remove-item global-map 
			 '("menu-bar" "options" "showhide") 'menu-bar-mode)

					;' can't show a frame on a different display
  (easy-menu-remove-item global-map 
			 '("menu-bar" "file") 'make-frame-on-display)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; this is for the About dialog
;; when all frames are hidden, 
;; the original fancy-splash-frame just returns nil
;; as a bugfix, we're redefining this
;; in order to create a new frame if all frames are invisible

(defun fancy-splash-frame ()
  (make-frame 
   '((name . "About Aquamacs Emacs") 
     (font . "-apple-lucida grande-medium-r-normal--0-0-0-0-m-0-mac-roman")
     (width . 75) (height . 40) (minibuffer . t)
     (background-color . "White") 
     (foreground-color . "Black") (tool-bar-lines . 0)
     (vertical-scroll-bars . auto) 
     (horizontal-scroll-bars . nil) 
     (left-fringe . 5) (right-fringe . 0)
     (internal-border-width . 0) (unsplittable . t))))

(defun fancy-splash-head ()
  "Insert the head part of the splash screen into the current buffer.
This is modified in Aquamacs compared to GNU Emacs, because most
information given would otherwise be irrelevant to Aquamacs users.
"
  (and (boundp 'longlines-mode) (longlines-mode -1))
  (let* ((image-file (cond ((stringp fancy-splash-image)
			    fancy-splash-image)
			   ((and (display-color-p)
				 (image-type-available-p 'xpm))
			    (if (and (fboundp 'x-display-planes)
				     (= (funcall 'x-display-planes) 8))
				"splash8.xpm"
			      "splash.xpm"))
			   (t "splash.pbm")))
	 (img (create-image image-file))
	 (image-width (and img (car (image-size img))))
	 (window-width (window-width (selected-window))))
    (when img
      (when (> window-width image-width)
	;; Center the image in the window.
;; 	(insert (propertize " " 'display
;; 			    `(space :align-to (+ center (-0.5 . ,img)))))

	;; Change the color of the XPM version of the splash image
	;; so that it is visible with a dark frame background.
	(when (and (memq 'xpm img)
		   (eq (frame-parameter nil 'background-mode) 'dark))
	  (setq img (append img '(:color-symbols (("#000000" . "gray30"))))))

	;; Insert the image with a help-echo and a keymap.
	(let ((map (make-sparse-keymap))
	      (help-echo "mouse-1: browse http://aquamacs.org/"))
	  (define-key map [mouse-1]
	    (lambda ()
	      (interactive)
	      (browse-url "http://aquamacs.org/")))
	  (define-key map [down-mouse-1] 'ignore)
	  (define-key map [up-mouse-1] 'ignore)
	  (insert-image img (propertize "xxx" 'help-echo help-echo
					'keymap map)))
	(insert "\n"))))
  (insert "\n")
  (fancy-splash-insert
   :face 'variable-pitch
   "Aquamacs is a distribution of GNU Emacs that is adapted for Mac users.\n\n")
  (insert "\n"))
(setq fancy-splash-text
      '((:face (variable-pitch :weight bold)
           :face variable-pitch "Aquamacs Emacs comes with "
	   :face (variable-pitch :slant oblique)
	   "ABSOLUTELY NO WARRANTY\n"
	   )
	(:face variable-pitch
	 "Use the Help menu to view manuals or go to helpful websites.\n"
	 
	 "To quit a partially entered command, type "
	 :face default
	 "Control-g"
	 :face variable-pitch
	 ".\n"
	 )))
 

(setq emacs-build-system 
      (concat 
       emacs-build-system
       " - Aquamacs Distribution " 
       (if (boundp 'aquamacs-version) aquamacs-version "?") 
       (if (boundp 'aquamacs-minor-version) aquamacs-minor-version "?")))

(require 'check-for-updates)
;; via hook so it can be turned off
(add-hook 'after-init-hook 'aquamacs-check-for-updates-if-necessary 'append) 
 

(ats "aquamacs-tool-bar-setup ...")
(when (eq window-system 'mac) ;; not yet for Cocoa
  (require 'aquamacs-tool-bar)
  (aquamacs-tool-bar-setup))
(ats "aquamacs-tool-bar-setup done")

;; finish reading environment vars

(when (running-on-a-mac-p)
  (unless (mac-read-environment-vars-from-shell-2)    
    (message "Warning - environment variable reading delayed.")
					; wait one second
    ;; we should not delay this via run-with-timer, because
    ;; some code may depend on the PATH (exec-path!) being set correctly,
    ;; for example the (autoloaded!) ispell package.
    (sit-for 1)
    (mac-read-environment-vars-from-shell-2)))

) ;; aquamacs-setup
 

			 
(provide 'aquamacs)

 
