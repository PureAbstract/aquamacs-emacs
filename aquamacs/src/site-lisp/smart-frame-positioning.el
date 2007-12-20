;;; Smart-frame-positioning.el 
;; Emacs Version: 22.0 
;; Author: David Reitter, david.reitter@gmail.com
;; Maintainer: David Reitter
;; Keywords: aquamacs frames
 
;; Last change: $Id: smart-frame-positioning.el,v 1.40 2007/12/20 02:10:30 davidswelt Exp $
 
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
 
;; Copyright (C) 2005, 2006 David Reitter

;; Smart Frame Positioning Mode: In environments where many frames are
;;  opened, this mode shows them in useful positions on the screen so
;;  they don't overlap. The mode also associates positions with buffer
;;  names, so that frames displaying the same buffer (and file name)
;;  are always opened in the same position.

;; To activate:
;; (require 'smart-frame-positioning)
;; (smart-frame-positioning-mode t)
;;
;; To Do:
;; Multiple screens are currently handled in a simplified fashion.
;; This should be well-behaved in dual-screen setups, with the exception
;; that all screens are assumed to be of the same size.
;; May produce undesirable results on certain triple-screen setups or
;; when screens with very different resolutions are used.
;;  
;; In the Carbon port, the function
;; `winmgr-get-available-screen-bounds' returns the available screen
;; coordinates for the main screen, and the position of the current
;; window in relation to that one is only guessed.  Via GetDeviceList
;; and GetNextDevice (Quickdraw), all screens can be retrieved.  A
;; better implementation could be done once the Cocoa port is
;; available, so we're not going to invest much time in the Carbon
;; portion here.
;;
;; `winmgr-get-available-screen-bounds' could be implemented for different
;; platforms. It should return a list of four ordinates (x y w h), giving the
;; available screen real estate for the main screen.
;; An optional parameter (currently not used) could identify the screen.

(defcustom save-frame-position-file 
  (convert-standard-filename
   "~/Library/Preferences/Aquamacs Emacs/frame-positions.el")
  "Name of the file that records `smart-frame-prior-positions' value."
 :type 'file)
 
(defcustom smart-frame-positioning-hook nil
  "Functions to be run before frame creation.
These functions are run in `smart-frame-positioning-mode after
a frame is created and before it is made visible. 
The functions should take one argument, that is, the new frame.
The functions may alter the frame parameters. 
After return from these functions, the above mode will adapt
the frame position of the frame. Height and width, if set 
by any of the hook functions, will normally be preserved." 
  :type 'hook
  :require 'smart-frame-positioning
  :version 22.0
  :group 'frames)


(unless (fboundp 'winmgr-display-available-pixel-bounds)
  (if (fboundp 'mac-display-available-pixel-bounds)
      (fset 'winmgr-display-available-pixel-bounds 
	    'mac-display-available-pixel-bounds))
  (if (fboundp 'x-display-usable-bounds)
      (fset 'winmgr-display-available-pixel-bounds 
	    'x-display-usable-bounds)))
 




(defun smart-position-and-create-frame (&optional parameters) 
 "Create a frame in a useful screen position.
May be used in `frame-creation-function' or 
`frame-creation-function-alist'. `smart-frame-positioning-mode' 
should be used as the interface to this function."
  (let* ((newpos)
	 
	 (oldframe (selected-frame))
	 (newparms (append (list '(visibility . nil)) 
			   parameters))
	 ;; create the frame
	 (f (funcall smart-frame-positioning-old-frame-creation-function
		     newparms)))
    ;; the frame creation function doesn't set all parameters
    ;; set the remaining ones manually
    ;; bug reported to pretest bug list 13/Jan/2006

    (mapc (lambda (x)
	    (assq-delete-all (car x) newparms))
		 (frame-parameters f))
    ;; set remaining parameters
    (modify-frame-parameters f newparms)
  

    (run-hook-with-args 'smart-frame-positioning-hook f)
      
	   
    (setq newpos (find-good-frame-position oldframe f))  
    (when (frame-parameter f 'fit-frame)
	;; delete height and width - these parameters
	;; are preserved and will stay untouched
	;; in case the hook changed them.
	;; (unless exceeding screen dimensions)
	(setq newpos 
		(assq-delete-all 
		 'height 
		 (assq-delete-all 'width newpos))))
    ; make sure we don't make it visible prematurely
    (setq newpos (assq-delete-all 'visibility newpos))
    (modify-frame-parameters f newpos)
    ;; stay within the available screen
    (smart-move-frame-inside-screen f)
    (when window-configuration-change-hook
      ;; this is so that longlines-mode recognizes the new window width
      (save-excursion
	(select-window (frame-first-window f))
	(set-buffer (window-buffer (selected-window)))
	(setq fill-column 50)
	(run-hooks 'window-configuration-change-hook)))
    (unless  (and (assq 'visibility parameters)
		  (eq (cdr (assq 'visibility parameters)) nil))
      (make-frame-visible f))
    f))	; return the frame

 
(defcustom smart-frame-positioning-enforce nil
  "If true and if in smart-frame-positioning-mode, ignore any user-supplied
position in ``default-frame-alist''." 
  :type 'boolean
  :require 'smart-frame-positioning
  :version 22.0
  :group 'frames)

(defcustom smart-frame-positioning-margin 20
  "In smart-frame-positioning-mode, place the frames this many
pixels apart if possible." 
  :type 'integer
  :require 'smart-frame-positioning
  :version 22.0
  :group 'frames)

(defvar smart-fp--frame-title-bar-height 22) ;; how to determine this?


(defun frame-total-pixel-height (f) ;;(frame-pixel-height f))
;; this should use the correct faces for minibuffer/modeline
;; and check for presence of those elements etc etc.
;; it's just an approximation right now.
  (+ smart-fp--frame-title-bar-height ;; this is for the title bar of the window
   (smart-fp--char-to-pixel-height
     (eval (frame-parameter f 'height)) f
   )))
 ; (frame-total-pixel-height (selected-frame))
; (frame-pixel-height)

(defun smart-fp--char-to-pixel-width (chars frame)
       (* chars (frame-char-width frame)))
(defun smart-fp--char-to-pixel-height (chars frame)
        (* chars (frame-char-height frame)))
(defun smart-fp--pixel-to-char-width (pixels frame &optional round-to-lower)
       (round (- (/ pixels (frame-char-width frame)) 
		 (if round-to-lower 0 .5))))
(defun smart-fp--pixel-to-char-height (pixels frame &optional round-to-lower)
       (round (- (/ pixels (frame-char-height frame)) 
		 (if round-to-lower 0 .5))))

(defun smart-fp--get-frame-creation-function ()
  (if (boundp 'frame-creation-function)
      frame-creation-function
    (if (boundp 'frame-creation-function-alist)
	(assq window-system frame-creation-function-alist))
    nil))
(require 'aquamacs-tools)
(defun smart-fp--set-frame-creation-function (fun)
  (if (boundp 'frame-creation-function)
      (setq frame-creation-function fun)
    (if (boundp 'frame-creation-function-alist)
	(assq-set window-system fun 'frame-creation-function-alist))
    nil))

 
(defun find-good-frame-position ( old-frame new-frame )
  "Finds a good frame position for a new frame based on the old one's position."
 
  (let ((new-frame-parameters))
    (if (and (not smart-frame-positioning-enforce) 
	     (cdr (assq 'user-position (frame-parameters new-frame))))
	nil ;; just leave the parameters unmodified, if user has set a position
      
      (let* (
	     ;; on some systems, we can retrieve the available pixel width.
	     (rect (if (fboundp 'winmgr-display-available-pixel-bounds)
		       (winmgr-display-available-pixel-bounds)
		     (list 0 0 
			   (display-pixel-width) (display-pixel-height))))
	     (min-x (+ 5 (nth 0 rect)))
	     (min-y (+ 5 (nth 1 rect)))
	     (max-x (nth 2 rect))
	     (max-y (nth 3 rect))
	     (preassigned 
	      (smart-fp--get-frame-position-assigned-to-buffer-name)))
	
	(or preassigned	;; if preassigned, return that.
	    (let* ( ;; eval is necessary, because left can be (+ -1000)
		  ;; which is not an integer!
		  ( y (eval (frame-parameter old-frame 'top)) )
		  ( x (eval (frame-parameter old-frame 'left)) )
		  ( w (frame-pixel-width old-frame) )
		  ( h (frame-total-pixel-height old-frame) )
        
		  (next-w w ) ;;(frame-pixel-width new-frame) )
		  (next-h h ) ;; (frame-total-pixel-height new-frame) )
		  (margin smart-frame-positioning-margin))

	      ;; in case the frame is obviously created
	      ;; on another screen
	      ;; these ought to use the full screen dimensions, not
	      ;; the available ones. However, since we don't know the dimensions
	      ;; of the other screen (we only know the main ones), these aren't
	      ;; quite clear
	      (when (< (+ x w) min-x)	; to the left
		(let ((new-max-x min-x))
		  (setq min-x (- min-x max-x))
		  (setq max-x new-max-x)))
	      (when (> x max-x)	;; to the right
		;; there seems to be a screen right to the Dock screen
		;; try to guess the size
		(setq min-x max-x) 
		(setq max-x (* 2 max-x))) ;; crude assumption - 
					; screen size unknown
	      (when (< (+ y h) min-y)	  ; above
		(let ((new-max-y min-y))
		  (setq min-y (- min-y max-y))
		  (setq max-y new-max-y)))
	      (when (> y max-y)	;; below
		(setq min-y max-y)
		(setq max-y (* 2 max-y)))
	      ;; return:
	      (unless (frame-visible-p old-frame)
		;; if we're given an invisible frame (probably no
		;; frame visible then!), assume a sensible standard
		(setq x (+ min-x margin)  y (+ min-y margin) w 0 h 0))
	      (let (
		    (next-x 
		     (if (> (- x margin next-w) min-x)
			 (- x margin next-w)
					; if it doesn't fit to the left
		       (if (> max-x  (+ x w margin next-w))
			   (+ x w margin)
			 ;; if it doesn't fit to the right
			 ;; then position on the "other side" 
			 ;; (where current frame is not)
			 (if (or (equal w 0) (equal h 0) ; invisible?
				 (> (+ x (/ w 2)) (/ max-x 2)))
			     min-x ;; left edge
			   ;; or on the right edge 
			   (- max-x next-w)))))
		    ;; now determine y position	
		    (next-y nil))
		;; we'll try to position the frame somewhere near the
		;; original one
		(mapc  
		 (lambda (ny)
		   (if next-y
		       nil ;; no operation if next-y already found
		     (let ((samerow t))
		       (mapc  
			(lambda (f)  
			  (if (or (> (abs (- (eval 
					      (frame-parameter f 'top)) 
					     ny)) 10) 
				  ;; different height
				  (or (> next-x (+ (eval 
						    (frame-parameter f 'left)) 
						   (frame-parameter f 'width))) 
					;or no overlap
				      (< (+ next-x next-w) 
					 (eval (frame-parameter f 'left)))))
			      nil	; fine
			    (setq samerow nil)))  
			;; list:
			(visible-frame-list))
		       (if samerow
			   (setq next-y ny)))))
		 ;; list:
		 (list y (+ y margin) (+ y (* 3 margin)) (+ y (* 5 margin)) 
		       (+ y (* 6 margin)) (+ y (* 4 margin))  
		       (+ y (* 2 margin)) 
		       (- y margin) (- y (* 3 margin)) (- y (* 5 margin)) 
		       (- y (* 6 margin)) (- y (* 4 margin)) 
		       (+ y (* 2 margin))))
		(setq next-x (max next-x min-x ))
		(if next-y
		    ;; make sure it's not too low
		    ;; the 20 seem to be necessary because of a bug 
		    ;; that hasn't been fixed yet.
		    (setq next-y (max min-y 
				      (min next-y (- max-y next-h 25))))
		  (setq next-y min-y)) ;; if all else fails
		;; do we need to change the height as well?
		(when (and next-y (> (+ 25 next-y next-h) max-y))
		  (setq next-h (- max-y next-y 25)))
	      
		(assq-set 'left next-x 'new-frame-parameters)
		(assq-set 'top next-y 'new-frame-parameters)
		;;  (assq-set 'width next-w 'new-frame-parameters)
	     
		;; why this? (why? enabled)
		(assq-set 'height (smart-fp--pixel-to-char-height
				   next-h new-frame) 'new-frame-parameters)
		;; return this 
		(smart-fp--convert-negative-ordinates 
		 new-frame-parameters))))))))

(defvar smart-frame-positioning-old-frame-creation-function 
	(smart-fp--get-frame-creation-function))

(define-minor-mode smart-frame-positioning-mode
  "If enabled, new frames are opened in a convenient position. 
The algorithm tries to avoid overlapping of frames on the display,
and it tries to position them so that they don't leave the screen.
Nota bene: This is not an exact science.

When frames are deleted, their position (associated with the name of
the buffer shown in their first window) is stored. Frames will be 
re-created at that position later on.

`smart-frame-positioning-enforce', `smart-frame-positioning-margin',
`smart-frame-positioning-hook' and `save-frame-position-file' 
can be customized to configure this mode."

  :init-value nil
  :global t
  :version "22.0"
  :group 'frames
  
  (if smart-frame-positioning-mode
      ;; turn on
    (progn 
 
      (unless (eq (smart-fp--get-frame-creation-function)
		  'smart-position-and-create-frame)
	(setq smart-frame-positioning-old-frame-creation-function 
	      (smart-fp--get-frame-creation-function)))

      (smart-fp--set-frame-creation-function
       'smart-position-and-create-frame)

      (add-hook 'delete-frame-functions
		'smart-fp--store-frame-position-for-buffer)

      ;; the first frame should be in a good position

      (let* ((rect (if (fboundp 'winmgr-display-available-pixel-bounds)
		       (winmgr-display-available-pixel-bounds)
		     (list 0 0 
			   (display-pixel-width) (display-pixel-height))))
	     (min-x (+ 5 (nth 0 rect)))
	     (min-y (+ 5 (nth 1 rect))))
	(setq initial-frame-alist
	      (append
	       `((top . ,(+ smart-frame-positioning-margin min-y))
		 (left . ,(+ smart-frame-positioning-margin min-x)))
	       initial-frame-alist))))
   
    ;; else (turning off)
    (smart-fp--set-frame-creation-function
     smart-frame-positioning-old-frame-creation-function)
    (remove-hook 'delete-frame-functions
		 'smart-fp--store-frame-position-for-buffer))
  smart-frame-positioning-mode)
        
(defvar smart-frame-prior-positions '()
  "Association list with buffer names and frame positions / sizes, so these
can be remembered. This is part of Aquamacs Emacs.")
 
(defun smart-fp--store-frame-position-for-buffer (f)
  "Store position of frame F associated with current buffer for
later retrieval."
  ;; (setq smart-frame-prior-positions nil)
  ;; don't store too many entries here
  (when (or buffer-file-number 
	    (not (string-match "untitled" (buffer-name))))
    ;; don't save position if 'untitled'
    ;; but do save buffers like *Messages* and *Help*
    (if (> (length smart-frame-prior-positions) 50)
	(setcdr (nthcdr 49 smart-frame-prior-positions) nil))
    (assq-set-equal (buffer-name) 
		    ( list 
		      (cons 'left (eval (frame-parameter f 'left)))
		      (cons 'top (eval (frame-parameter f 'top)))
		      (cons 'width (frame-parameter f 'width))
		      (cons 'height (frame-parameter f 'height))) 
		    'smart-frame-prior-positions)))

;; modelled after `save-place-alist-to-file'
;; but we're saving a (setq ...) so we can just load the file
;; (smart-fp--save-frame-positions-to-file)
(defun smart-fp--load-frame-positions-from-file ()
  (load (expand-file-name save-frame-position-file)
	'noerror nil 'nosuffix ))
(defun smart-fp--save-frame-positions-to-file ()
  "Save `smart-frame-prior-positions' to a file.
The file is specified in `smart-frame-position-file'."
  (let ((file (expand-file-name save-frame-position-file)))
    (save-excursion
      (set-buffer (get-buffer-create " *Saved Positions*"))
      (setq buffer-file-coding-system 'utf-8) ;; avoid asking questions
      (delete-region (point-min) (point-max))
      (let ((print-length nil)
            (print-level nil))
        (print `(setq smart-frame-prior-positions
		      ',smart-frame-prior-positions)
	       (current-buffer)))
      (condition-case nil
	  ;; Don't use write-file; we don't want this buffer to visit it.
	  (write-region (point-min) (point-max) file)
	(file-error (message "Saving frame positions: Can't write %s" file)))
      (kill-buffer (current-buffer))
      )))

;; load this after the custom-file
(add-hook 'after-init-hook 'smart-fp--load-frame-positions-from-file 'append)

(add-hook 'kill-emacs-hook 'smart-fp--save-frame-positions-to-file)

;; could assoc be used instead?
(defun assq-string-equal (key alist)
  (catch 'break
    (mapc 
     (lambda (element)
       (if (string-equal (car-safe element) key)
	   (throw 'break element)))
     alist)
    nil ;; not found
    ))

(defun smart-fp--get-frame-position-assigned-to-buffer-name ()
      (cdr (assq-string-equal (buffer-name) smart-frame-prior-positions)))


(defun smart-move-frame-inside-screen (&optional frame)
  "Move a frame inside the available screen boundaries. 
The frame specified in FRAME is moved so it is entirely visible on
the screen. The function tries to avoid leaving frames on screen
boundaries.
The function will fail to do its job when the Dock is not displayed
on the main screen, i.e. where the menu is."
  (interactive)
  (let* ((frame (or frame (selected-frame)))
	 ;; on some systems, we can retrieve the available pixel width with
	 ;; non-standard methods.
	 ;; on OS X, e.g. mac-display-available-pixel-bounds (patch!!) returns
	 ;; available screen region, excluding the Dock.
	 (rect (if (fboundp 'mac-display-available-pixel-bounds)
		   (mac-display-available-pixel-bounds)
		 (list 0 0 
		       (display-pixel-width) (display-pixel-height))))
	 (min-x (nth 0 rect))
	 (min-y (nth 1 rect))
	 (max-x (nth 2 rect))
	 (max-y (nth 3 rect))
	 (next-x (eval (frame-parameter frame 'left)))
	 (next-y (eval (frame-parameter frame 'top)))
	 (next-wc (eval (frame-parameter frame 'width)))
	 (next-hc (eval (frame-parameter frame 'height)))
	 (next-w (frame-pixel-width frame)
		 ;(smart-fp--char-to-pixel-width next-wc frame)
		  )
	 (next-h (frame-pixel-height frame))

	 (w-offset (- next-w (smart-fp--char-to-pixel-width next-wc frame)))
	 (h-offset (- next-h (smart-fp--char-to-pixel-height next-hc frame)))

	 (next-x2 (+ next-x next-w))
	 (next-y2 (+ next-y next-h)))
    (when (< (+ next-x next-w) min-x) ; to the left
      (let ((new-max-x min-x))
	(setq min-x (- min-x max-x))
	(setq max-x new-max-x)))
    (when (> next-x max-x)
      ;; there seems to be a screen right to the Dock screen
      ;; try to guess the size
      (setq min-x max-x) 
      (setq max-x (* 2 max-x))) ;; crude assumption - screen size unknown
    (when (< (+ next-y next-h) min-y) ; above
      (let ((new-max-y min-y))
	(setq min-y (- min-y max-y))
	(setq max-y new-max-y)))
    (when (> next-y max-y) ; below
      (setq min-y max-y)
      (setq max-y (* 2 max-y)))
 
    (modify-frame-parameters 
     frame
     (let* ((next-x (max min-x 
			 (min
			  (- max-x next-w )
			  next-x)))
	    (next-y (max min-y 
			 (min 
			   (- max-y next-h smart-fp--frame-title-bar-height)  ;; why subtract smart-fp--frame-title-bar-height ???
			  next-y)))
	    (next-wc  (if (<= next-w (- max-x next-x))
			  next-wc
			(smart-fp--pixel-to-char-width (- max-x next-x) 
						       frame 'round-lower)))
	    (next-hc (if (<= next-h (- max-y next-y ))
			 next-hc
		       (smart-fp--pixel-to-char-height (- max-y next-y)
						       frame 'round-lower))))
       `((left .
	       ,next-x)
	 (top .
	      ,next-y)
	 (width .
		,next-wc)   
	 (height .
		 ,next-hc)))))) 

	 
    
(defun smart-fp--convert-negative-ordinates (parms)
  "Converts screen ordinates of the form -x to a list (+ -x)."
  (mapcar (lambda (o)
	    (if (and (integerp (cdr-safe o))
		     (< (cdr o) 0))
		`(,(car o) . (+ ,(cdr o)))
		; else
		o))
	  parms))


(require 'fit-frame)
(defun scatter-frames ()
  (interactive)
  (let ((frames (visible-frame-list)))
    
;;     (dolist (frame frames)
;;       (hide-frame frame t))

  (dolist (frame frames)
    (let ((smart-frame-positioning-enforce t)
	  (smart-frame-prior-positions) (newpos)
	  (fit-frame-max-width-percent (if (> (length frames) 1) 45 90)))
      (fit-frame frame )
      (setq newpos (find-good-frame-position (selected-frame) frame))  
      (when (frame-parameter frame 'fit-frame)
	;; delete height and width - these parameters
	;; are preserved and will stay untouched
	;; in case the hook changed them.
	;; (unless exceeding screen dimensions)
	(setq newpos 
		(assq-delete-all 
		 'height 
		 (assq-delete-all 'width newpos))))
      (modify-frame-parameters frame newpos)
      (smart-move-frame-inside-screen frame))
;    (make-frame-visible frame)
    (select-frame frame))))

(provide 'smart-frame-positioning) 