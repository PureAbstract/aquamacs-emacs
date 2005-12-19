;;; plfonts.el - Setup AUC TeX for editing Polish text with plfonts.sty

;; $Id: plfonts.el,v 1.2 2005/12/19 13:01:35 davidswelt Exp $

;;; Commentary:
;;
;; `plfonts.sty' use `"' to make next character Polish.
;; `plfonts.sty' <C> L. Holenderski, IIUW, lhol@mimuw.edu.pl

;;; Code:

(defvar LaTeX-plfonts-mode-syntax-table
  (copy-syntax-table LaTeX-mode-syntax-table)
  "Syntax table used in LaTeX mode when using `plfonts.sty'.")

(modify-syntax-entry ?\"  "w"  LaTeX-plfonts-mode-syntax-table)

(TeX-add-style-hook "plfonts"
 (function (lambda ()
   (set-syntax-table LaTeX-plfonts-mode-syntax-table)
   (make-local-variable 'TeX-open-quote)
   (make-local-variable 'TeX-close-quote)
   (make-local-variable 'TeX-quote-after-quote)
   (make-local-variable 'TeX-command-default)
   (setq TeX-open-quote "\"<")
   (setq TeX-close-quote "\">")
   (setq TeX-quote-after-quote t)
   (setq TeX-command-default "plLaTeX")
   (run-hooks 'TeX-language-pl-hook))))

;;; plfonts.el ends here
