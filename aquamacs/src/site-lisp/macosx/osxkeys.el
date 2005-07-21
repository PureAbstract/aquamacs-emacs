;; osxkeys.el
;; Mac Style Keyboard Shortcuts 
;; provides osx-key-mode


;; Author: David Reitter, david.reitter@gmail.com
;; Maintainer: David Reitter
;; Keywords: aquamacs
 
;; Last change: $Id: osxkeys.el,v 1.11 2005/07/21 09:42:09 davidswelt Exp $

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

 
;; Copyright (C) 2005, David Reitter


;; Unit test  / check requirements
(require 'aquamacs-tools)
(aquamacs-require  '(boundp 'mac-command-modifier))
(aquamacs-require  '(boundp 'mac-control-modifier))
(aquamacs-require  '(boundp 'mac-pass-option-to-system))


;; To do: this should only happen when the mode is switched on

(setq mac-option-modifier 'meta) 
(setq mac-control-modifier 'ctrl)
(setq mac-command-modifier 'hyper)
(setq mac-pass-option-to-system t) ;; let system do stuff with option
(setq mac-pass-command-to-system t) ;; let system handle Apple-H and the like
;; (this is default anyways)

;; mac-command-is-meta won't work any more at this point!
;; it's deprecated

;;; MacOS X specific stuff

(defvar osxkeys-command-key mac-command-modifier)

;; Define the return key to avoid problems on MacOS X
(define-key function-key-map [return] [13])

;; Option (alt) will act like in other Mac programs
;; if it is used without a standard modifier, it is interpreted as 'Meta'
;; use Esc instead of Option (alt) if you need Meta for a reserved combination.
  
;; allow selection of secondary buffer
  
(defun aquamacs-yes-or-no-p (text)

(let ((f (window-frame (minibuffer-window))))

  (raise-frame f) ; make sure frame is visible
  (let ((y (- (display-pixel-height) (frame-total-pixel-height f) 30 ))) ; extra 30 pix for typical Dock
    (if (< y (frame-parameter f 'top))
	(modify-frame-parameters f (list (cons 'top y)))
    )
    )
   (yes-or-no-p text)
)
)

 

 
(require 'aquamacs-tools)


 

(require 'filladapt)

(require 'mac-extra-functions)

(defun switch-to-next-frame ()
  (interactive)
  (select-frame-set-input-focus (next-frame))
)
(require 'redo)
  
;; remove existing bindings that don't exist on the mac
(global-unset-key [cut])
(global-unset-key [copy])
(global-unset-key [paste])
(global-unset-key [f20])
(global-unset-key [f16])
(global-unset-key [f18])
   
  
(defun clipboard-kill-ring-save-secondary ()
  "Copy secondary selection to kill ring, and save in the X clipboard."
(interactive)
  (if mouse-secondary-overlay
  (let ((x-select-enable-clipboard t))
    (clipboard-kill-ring-save 
     (overlay-start mouse-secondary-overlay) 
     (overlay-end mouse-secondary-overlay) )
    (message "Secondary selection saved to clipboard and kill-ring.")
    )
  ; else
  (message "The secondary selection is not set.")
  )
)

(defun clipboard-kill-secondary ()
  "Kill the secondary selection, and save it in the X clipboard."
   (interactive)
   (if mouse-secondary-overlay
       (let ((x-select-enable-clipboard t))
	 (clipboard-kill-region 
	  (overlay-start mouse-secondary-overlay)
	  (overlay-end mouse-secondary-overlay))
	 (message "Secondary selection saved to clipboard and kill-ring, then killed.")    
	 )
					; else
     (message "The secondary selection is not set.")
     )
)

(defun make-osx-key-mode-map (&optional command-key)
"Create a mode map for OSX key mode. COMMAND-KEY specifies
which key is mapped to command. mac-command-modifier is the
default."
(if command-key
    (setq osxkeys-command-key command-key)
  (if mac-command-modifier
      (setq osxkeys-command-key mac-command-modifier)
    )
)
(let ((map (make-sparse-keymap)))
    (define-key map `[(,osxkeys-command-key \?)] 'aquamacs-user-help)
    (define-key map `[(,osxkeys-command-key shift \?)] 'aquamacs-emacs-manual)

    (define-key map `[(,osxkeys-command-key n)] 'new-frame-with-new-scratch) ;open new frame empty
    (define-key map `[(,osxkeys-command-key o)] 'mac-key-open-file) ;open new frame with a file

    (define-key map `[(,osxkeys-command-key shift s)] 'write-file)
    (define-key map `[(,osxkeys-command-key shift o)] 'find-file-other-frame) ;open new frame with a file
    (define-key map `[(,osxkeys-command-key a)] 'mark-whole-buffer)
    (define-key map `[(,osxkeys-command-key v)] 'clipboard-yank) 
    (define-key map `[(,osxkeys-command-key c)] 'clipboard-kill-ring-save)
    (define-key map `[(shift ,osxkeys-command-key c)] 'clipboard-kill-ring-save-secondary)
    ; this because the combination control-space usually activates Spotlight
    (define-key map `[(control ,osxkeys-command-key space)] 'set-mark)
    (define-key map `[(,osxkeys-command-key x)] 'clipboard-kill-region)
    (define-key map `[(shift ,osxkeys-command-key x)] 'clipboard-kill-secondary)
    (define-key map `[(,osxkeys-command-key s)] 'save-buffer)
    (define-key map `[(,osxkeys-command-key l)] 'goto-line)
    (define-key map `[(,osxkeys-command-key f)] 'isearch-forward)
    (define-key map `[(,osxkeys-command-key g)] 'isearch-repeat-forward)
    (define-key map `[(,osxkeys-command-key w)] 'close-current-window-asktosave)
    (define-key map `[(,osxkeys-command-key m)] 'iconify-or-deiconify-frame) 
    (define-key map `[(,osxkeys-command-key .)] 'keyboard-quit)
    (define-key map `[(,osxkeys-command-key \e)] 'keyboard-escape-quit)
    (define-key map `[(,osxkeys-command-key up)] 'beginning-of-buffer)
    (define-key map `[(,osxkeys-command-key down)] 'end-of-buffer)
    (define-key map `[(,osxkeys-command-key left)] 'beginning-of-line)
    (define-key map `[(,osxkeys-command-key right)] 'end-of-line)
    (define-key map `[(,osxkeys-command-key backspace)] 'kill-whole-line)
    (define-key map `[(meta up)] 'cua-scroll-down)
    (define-key map `[(meta down)] 'cua-scroll-up)

    (define-key map [(home)] 'beginning-of-buffer)
    (define-key map [(end)] 'end-of-buffer)

    (define-key map `[(control ,osxkeys-command-key q)] 'kill-emacs)
    (define-key map `[(,osxkeys-command-key q)] 'save-buffers-kill-emacs)
;    (define-key map `[(,osxkeys-command-key ",")] 'customize)

    (define-key map `[(,osxkeys-command-key z)] 'undo)
    (define-key map `[(,osxkeys-command-key shift z)] 'redo)
    (define-key map `[(,osxkeys-command-key \`)] 'switch-to-next-frame)
    map)
)


(defvar osx-key-mode-map
  (make-osx-key-mode-map)
  "Keymap for `osx-key-mode'.")

(define-minor-mode osx-key-mode
  "Toggle Mac Key mode.
With arg, turn Mac Key mode on iff arg is positive.
When Mac Key mode is enabled, mac-style key bindings are provided."
  :global t
  :group 'osx-key-mode 
  :keymap 'osx-key-mode-map  ;; probably not needed

  ; create up-to-date keymap
  (setq osx-key-mode-map  (make-osx-key-mode-map))
) 
; unfortunately, it doesn't pick up changes in the keymap,
; so users can't change mac-command-modifier and then redefine
; the keymap at this point. 

;; Change encoding so you can use alt-e and alt-u accents (and others) 
(set-terminal-coding-system 'iso-8859-1) 
(set-keyboard-coding-system				  'mac-roman) ;; keyboard
(set-selection-coding-system			  'mac-roman) ;; copy'n'paste
 

(provide 'osxkeys)