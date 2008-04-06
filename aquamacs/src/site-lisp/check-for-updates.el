;; check-for-updates.el
;; Checks for updates to Aquamacs - queries a remote server every 3 days.
;; If new version found, a new check will be forced next time 
;; (to show message again!)
;; Stores file .id in a folder 

;; Author: David Reitter, david.reitter@gmail.com
;; Maintainer: David Reitter
;; Keywords: aquamacs version check
 
;; Last change: $Id: check-for-updates.el,v 1.22 2008/04/06 13:10:25 davidswelt Exp $

;; This file is part of Aquamacs Emacs
;; http://www.aquamacs.org/

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
 
;; Copyright (C) 2005, 2007 David Reitter

; the following is user-settable (to "")
(defvar aquamacs-version-check-url "http://aquamacs.org/cgi-bin/currentversion.cgi" "URL to check for updates.  ")
;; warning: the default used to be aquamacs.sourceforge.net until after 1.0a

(defun aquamacs-check-version-information ()
  (interactive) 
;(switch-to-buffer (get-buffer-create  " *Aquamacs Privacy* "))
(with-output-to-temp-buffer (help-buffer)

(print "
        Aquamacs - Version update check
 
        Aquamacs automatically checks for updates and notifies
	the user if there's something new.  Your privacy: While
	checking for a new version, Aquamacs contacts an internet
	server to get the version number - this happens once
	every 3 days. The server will receive and store the
	following anonymous connection data: an anonymous but
	user-specific ID, the number of program starts, the
	versions of Aquamacs and OS X and the processor type that
	you're using.  Just as during any access to an Internet
	server, your IP address and the time of your inquiry may
	be stored, too. This information is used to produce
	statistics; we will delete the original data after a
	period of time. The statistics help us develop the
	application further - for example, we may decide to drop
	support for a particular operating system version.

	If you like to turn this check off, add this to your file
	~/Library/Preferences/Aquamacs Emacs/Preferences.el:

	(setq aquamacs-version-check-url nil)
"))
nil  )




; the following is internal - shouldn't be set 
(setq aquamacs-id-file "~/Library/Preferences/Aquamacs Emacs/.id")
(setq aquamacs-user-likes-beta 0) ;; this is 0 or 1, not nil / t
(setq aquamacs-version-check-buffer nil) 
(setq url-show-status nil) ;;don't annoy user
(defun aquamacs-compare-version ()
  (if aquamacs-version-check-buffer ;; just for safety
      (save-excursion 
	(set-buffer aquamacs-version-check-buffer)
 
	(if (> aquamacs-user-likes-beta 0) ; user likes beta versions?
	    (re-search-forward "<beta-version>\\(.*\\)</beta-version>" (buffer-end 1) t)
	  (re-search-forward "<version>\\(.*\\)</version>" (buffer-end 1) t)
	  )
 
	(if (and (not (equal (match-string 1) aquamacs-version))
		   (not (equal (match-string 1) 
			       (concat aquamacs-version 
				       aquamacs-minor-version) )))
	    (progn
	      (write-region (concat "888\n") 
			    ;; notice that a new version is available 
		  nil
		  aquamacs-id-file
		  'append 
		  'shut-up
		  nil
		  nil)
	      (aquamacs-new-version-notify (match-string 1)))
	  (with-temp-message (format "%s is the most recent Aquamacs version available."
				     (concat aquamacs-version 
				       aquamacs-minor-version)) nil)))))
 
(defun aquamacs-new-version-notify (v)
  ;; show right away and show when idle
  (message (format "Get the new Aquamacs %s from http://aquamacs.org" v))
  (run-with-idle-timer 
   0 nil 'message
   (format "Get the new Aquamacs %s from http://aquamacs.org" v)))

(defun aquamacs-ask-donate ()
  (if (and (fboundp 'mac-dialog-y-or-n-p)
	   (mac-dialog-y-or-n-p "Welcome to the new Aquamacs."
				"The Aquamacs Project depends on your support.
Please consider to help us by donating at http://aquamacs.org. 
Only your continued support keeps the project alive.
Would you like to see the donations site now?
(This reminder won't be displayed again in this version.)"))
      (aquamacs-donate)))

(defun aquamacs-welcome-notify ()
  ;; show right away and show when idle
      (run-with-idle-timer 
       0 nil 'aquamacs-ask-donate))


(defvar aquamacs-check-update-time-period 3
  "Time to wait (in days) between online checks for update.")

(defvar aquamacs-check-update-timer nil)

(defun aquamacs-check-for-updates ()
  (interactive)
  (aquamacs-check-for-updates-if-necessary 'force)
  ;; re-run the check after three days
  (if aquamacs-check-update-timer
      (cancel-timer aquamacs-check-update-timer))
  (let ((secs (* 86400 aquamacs-check-update-time-period)))
    (setq aquamacs-check-update-timer
	  (run-with-timer secs secs 
			  'aquamacs-check-for-updates-if-necessary 'force 'nonewstart))))

(defun aquamacs-check-for-updates-if-necessary (&optional force-check no-new-start)
  "Check (periodically) if there's an update for Aquamacs available, 
and show user a message if there is."
  (let (  
	( call-number 0)
	( session-id (random t) )
	( today (date-to-day (current-time-string)))
	( last-update-check 0) 
	( previous-version 0))

    (if (file-readable-p aquamacs-id-file)
	(with-temp-buffer
	  (insert-file-contents-literally aquamacs-id-file)
	    ; (set-buffer buf)
	    ; (buffer-string)
	    (goto-char (point-min)) 
	    (setq call-number (or (number-at-point) 0) )
	    (goto-line 2)
	    (setq last-update-check (or (number-at-point) 0))
	    (goto-line 3)
	    (setq session-id (or (number-at-point) (random t)))
	    (goto-line 4)
	    (setq aquamacs-user-likes-beta (or (number-at-point) 0))
	    (goto-line 5)
	    ;; number-at-point doesn't like decimals
	    (setq previous-version (or (string-to-number 
					(thing-at-point 'line)) 0))
	    (if (eq previous-version 888) ;; upgrade compat.
		(setq previous-version 0))
	    (goto-line 6)
	    (setq force-check (or force-check (eq 888 (number-at-point)))) 
	    ;; contains 888 if new version previously found
	    )
	  
      )
  
    (if (string-match "beta"  aquamacs-version)
	     (setq aquamacs-user-likes-beta 1)
      )

    ;; show "what's new" 
    (when (and (> previous-version 0)
	       (> (- aquamacs-version-id previous-version) 0.0))
      (aquamacs-show-change-log)
      (aquamacs-welcome-notify))
 
    (if (or force-check (>= (- today last-update-check)  aquamacs-check-update-time-period))
	(progn
	  (aquamacs-check-for-updates-internal session-id call-number)
	  (setq last-update-check today)
	  )
      )
        (write-region (concat (number-to-string (+ (if no-new-start 0 1) 
						   (or call-number 0))) "\n"
			  (number-to-string (or last-update-check 0)) "\n"
			  (number-to-string (or session-id 0)) "\n"
			   (if (> aquamacs-user-likes-beta 0) "1" "0") "\n"
			   (number-to-string aquamacs-version-id) "\n"
			  )
 
		  nil
		  aquamacs-id-file
		  nil 
		  'shut-up
		  nil
		  nil)
	;; store file
    	     ))


    
;; "&afpf=" (if aquamacs-auto-frame-parameters-flag "1" "0")
;; "&sfpm=" (if smart-frame-positioning-mode "1" "0")

(defun aquamacs-check-for-updates-internal (session-id calls)
 
 
    (when aquamacs-version-check-url
      ;; do not autoload (avoid messages)
      (require 'mail-utils)
      (require 'url)
      (require 'url-parse)
      (require 'url-methods)
      (require 'url-cache)
	(condition-case nil
	   
	    (let ((url (url-generic-parse-url 
			 (concat 
			  aquamacs-version-check-url
			  "?sess=" (number-to-string (or session-id 0)) 
			  "&seq=" (number-to-string (or calls 0))
			  "&beta=" (number-to-string (or aquamacs-user-likes-beta 0)) 
			  "&ver=" (url-encode-string (concat (or aquamacs-version "unknown") (or aquamacs-minor-version "-")))
				 
			  "&os=" 
			  (url-encode-string  
			   (replace-regexp-in-string 
			    "\[\r\n\]" "" 
			    (with-temp-buffer
			      (call-process "/usr/bin/uname" nil t nil "-r") 
			      (substring (buffer-string) 0 (min (1- (point-max)) 10)))))
			  "&cpu=" 
			  (url-encode-string  
			   (replace-regexp-in-string 
			    "\[\r\n\]" ""
			    (with-temp-buffer 
			      (call-process "/usr/bin/uname" nil t nil "-p") 
			      (substring (buffer-string) 0 (min (1- (point-max)) 10)))))))))
	; HTTP-GET
	(setq aquamacs-version-check-buffer   
	      (url-http url 
			'aquamacs-compare-version  nil ))

	; now make sure that the Emacs won't ask to kill this 
	; process when quitting
	(dolist ( p (process-list))
	  (if (string-match (elt url 3) (process-name p))
	      (set-process-query-on-exit-flag p nil)
	    )
	  )
	)
	(error nil))
      )
  nil)

; (aquamacs-check-for-updates-if-necessary t)

;; menu item (Aquamacs menu)
;; needs about-emacs.patch
(put 'check-for-updates                'mac-apple-event-id "chku")
(define-key mac-apple-event-map [hi-command check-for-updates]
  'aquamacs-check-for-updates)



(provide 'check-for-updates)

; (url-http-debug "asd")

 