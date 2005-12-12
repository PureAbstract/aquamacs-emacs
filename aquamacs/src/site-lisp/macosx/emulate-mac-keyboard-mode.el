
;; emulate-mac-*-keyboard-modes for Aquamacs
;; (C) 2005 by David Reitter
;; do not copy / redistribute. All rights reserved.

;; This defines multiple global minor modes, each of which
;; emulates common keys of a keyboard layout.
;;
;; The bindings are defined in `emulate-mac-keyboard-mode-maps'.
;;
;; By default, the following minor modes are defined:
;;
;; emulate-mac-german-keyboard-mode
;; emulate-mac-italian-keyboard-mode
;; emulate-mac-french-keyboard-mode

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar emulate-mac-keyboard-mode-maps nil
"List of special key translation bindings for `emulate-mac-keyboard-mode'.
Each element of this list should be a cons (LANGUAGE . BINDINGS), where
LANGUAGE is a symbol named after the language associated with the keyboard
layout to be used, and BINDINGS is a list of bindings, each consisting of
a cons cell (KEY . RESULT), where KEY is a string or other key identifier
denoting the key, and RESULT is a string giving the text to be inserted
for the key. Example:
 ((german . ((\"\\M-l\" . \"@\")
 	     (\"\\M-/\" . \"\\\\\"))))")

(setq emulate-mac-keyboard-mode-maps
 `((german . (("\M-l" . "@")
	       ("\M-/" . "\\")
	       ("\M-5" . "[")
	       ("\M-6" . "]")
	       ("\M-7" . "|")
	       ("\M-8" . "{")
	       ("\M-9" . "}")
	       ("\M-6" . "]")))
    (french . (("\M-`" . "@")
	       ("\M-$" . "\223")
	       ("\M-/" . "\\")
	       ("\M-�" . "#")
	       ("\M-(" . "{")
	       ("\M-5" . "[")
	       ("\M-)" . "}")
	       ("\M-�" . "]")))
    (italian . ( ; ("\M-�" . "@")  
		 ;; ([(meta �)]  . "@") ; wont work either
		("\M-(" . "{")
		("\M-4" . "[")
		("\M-)" . "}")
		("\M-7" . "]")  
		("\M-\:" . "|")))
    (us . (     ("\M-3" . "�")
		("\M-@" . ,(make-char 'latin-iso8859-15 164)) ;; euro symbol
		("\M-6" . "�")))
    (british . (("\M-3" . "#")
		("\M-2" . ,(make-char 'latin-iso8859-15 164)) ;; euro symbol
		("\M-6" . "�")))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun make-emulate-mac-keyboard-mode-map (language)
  (let ((emkm-ins-count 0))
  (let ((map (make-sparse-keymap)))
	  (mapcar (lambda (x)
		    (setq emkm-ins-count (1+ emkm-ins-count))
		    (define-key map  (car x)
		      (eval (list 'defun  (intern (format "emkm-%s-%d" 
					     language emkm-ins-count))
				  ()
				  (format "Insert %s characters" language)
				  '(interactive) 
				  `(insert ,(cdr x))))))
		  (reverse (cdr 
			    (assq language 
				  emulate-mac-keyboard-mode-maps))))
	  map))) 

(defun emkm-name (lang &optional suf)
  (if suf
      (intern (format "emulate-mac-%s-keyboard-mode%s" lang suf)))
  (intern (format "emulate-mac-%s-keyboard-mode" lang)))

(defun turn-off-emulate-mac-keyboard-modes (&optional except-language)
"Turn off all emulate-mac-keyboard minor modes"
  (mapcar (lambda 
	    (other-language)
	    (if (eq except-language other-language)
		t
	      (funcall (emkm-name other-language) 0)))
	  (mapcar 'car emulate-mac-keyboard-mode-maps)))

; (turn-off-emulate-mac-keyboard-modes)
 
(defun define-emulate-mac-keyboard-modes ()
"Read `emulate-mac-keyboard-mode-maps' and define a minor mode
for each entry in this alist. The minor mode will apply the
keymap specified there, and turn off all other keyboard emulation
minor modes."
  (mapc 
   (lambda (language)
     ;; define keymap first
     (let ((keymap-sym (emkm-name language "-map")))
       (set keymap-sym
	    (make-emulate-mac-keyboard-mode-map language))
       (eval `(define-minor-mode ,(emkm-name language) 
		"Binds a number of typically used Mac key combinations
to their keyboard-specific equivalents in order to use the 
Option key as Meta, while retaining access to commonly used  
such as [, ], @, etc. This mode is intended to be used with
`mac-option-modifier' set to `meta'.
Other mac keyboard emulation modes are turned off.
This mode has been defined from `emulate-mac-keyboard-mode-maps'
by the function `define-emulate-mac-keyboard-modes'."
		,nil ;; init-value
		,nil ;; lighter
		,keymap-sym ;; keymap
		:global t
		:group 'Aquamacs
		(when (eval ,(emkm-name language))
		  ;; disable competing modes
		  (turn-off-emulate-mac-keyboard-modes (quote ,language))
		  ;; Option key is Meta
		  (setq mac-option-modifier 'meta)
		  (message "Emulating important Option key combinations of %s keyboard layout." (capitalize (symbol-name (quote ,language)))))
		nil
		)))
     (set (emkm-name language) nil))
   (mapcar 'car emulate-mac-keyboard-mode-maps))
  (mapc (lambda (language)
	;; define-key-after won't work - has issues.
	(define-key menu-bar-option-key-menu (vector (list language))
	  (eval `(menu-bar-make-mm-toggle 
		  ,(emkm-name language)
		  ,(format "Emulate some %s Option key combinations" 
			   (capitalize (symbol-name language)))
		  "This mode binds commonly used Option key combinations
to their equivalents used on Mac OS X."
		  (:enable (eq mac-option-modifier 'meta))
		  ))))
(mapcar 'car emulate-mac-keyboard-mode-maps)))

;; Define entries for menu

(defvar menu-bar-option-key-menu (make-sparse-keymap "Option Key"))


(defvar mac-option-modifier-enabled-value 'meta)
(defun  toggle-mac-option-modifier (&optional interactively) 
  (interactive "p")
  (unless mac-option-modifier-enabled-value
    (setq mac-option-modifier-enabled-value 'meta))
   (setq mac-option-modifier
	 (if mac-option-modifier
	     (progn
	       (setq mac-option-modifier-enabled-value mac-option-modifier)
	       nil)
	   mac-option-modifier-enabled-value))
   (if interactively (customize-mark-as-set 'mac-option-modifier))
   (message 
    (format "Option key is %s%s" 
	    (if mac-option-modifier 
		""  "not ")
	    (upcase-initials 
	     (symbol-name (or mac-option-modifier 
			      mac-option-modifier-enabled-value))))))

(defvar menu-bar-option-key-menu (make-sparse-keymap "Modifier Keys"))



(define-emulate-mac-keyboard-modes)


(define-key menu-bar-option-key-menu [option-to-system-separator]
  '(menu-item "--"))

(define-key menu-bar-option-key-menu [option-to-system]
  `(menu-item
    ,(aq-shortcut  "Option Key for %s (not extra characters)  "
		   'toggle-mac-option-modifier 
		   (upcase-initials (symbol-name 
				     (or mac-option-modifier 
					 mac-option-modifier-enabled-value))))
    toggle-mac-option-modifier 
    :key-sequence nil
    :visible (boundp 'mac-option-modifier)
    :help "Toggle whether to let Option key behave as Emacs key, 
do not let it produce special characters (passing the key to the system)."
    :button (:toggle . mac-option-modifier)))
 


(define-key-after menu-bar-options-menu [option-key-menu]
  `(menu-item "Option Key" ,menu-bar-option-key-menu)
  'edit-options-separator)

(provide 'emulate-mac-keyboard-mode)
 