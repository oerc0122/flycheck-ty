;;; flycheck-ty.el --- Support ty in flycheck

;; Copyright (C) 2025 Jacob Wilkins <jacob.wilkins@stfc.ac.uk>
;;
;; Author: Jacob Wilkins <jacob.wilkins@stfc.ac.uk>
;; Created: 17 May 2025
;; Version: 1.1
;; Package-Requires: ((flycheck "0.18"))
;; Modified from https://github.com/flycheck/flycheck/issues/1974#issuecomment-1343495202

;;; Commentary:

;; This package adds support for ty to flycheck.  To use it, add
;; to your init.el:

;; (require 'flycheck-ty)
;; (add-hook 'python-mode-hook 'flycheck-mode)

;;; License:

;; This file is not part of GNU Emacs.
;; However, it is distributed under the same license.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:
(require 'flycheck)

(flycheck-def-config-file-var flycheck-python-ty-config python-ty
                              '("ty.toml" ".ty.toml"))

(flycheck-def-option-var flycheck-ty-custom-python "" (python-ty)
  "Location of custom Python for e.g. pyenv."
  :type '(radio (const :tag "Default" nil)
                 (const :tag "Local UV" "uv")
                 (string :tag "Custom location"))
  )

(defun flycheck-ty-find-env (source cust)
  "Return current environment if using uv.

   SOURCE is the current python source.
   CUST is the variable containing the configured value."
  (cond
   ((not cust) "")
   ((string-equal cust "uv") (let ((default-directory (replace-regexp-in-string "/[^/]+$" "/" source)))
                               (replace-regexp-in-string "\n$" "" (shell-command-to-string "uv python find")))
    )
   (t cust)
   )
  )


(flycheck-define-checker python-ty
  "A Python syntax and style checker using the ty utility.
To override the path to the ty executable, set
`flycheck-python-ty-executable'.
See URL `http://pypi.python.org/pypi/ty'."
  :command ("ty"
            "check"
            (config-file "--config" flycheck-python-ty-config)
            "--output-format" "concise"
            (eval
             (let ((name (flycheck-ty-find-env (buffer-file-name) flycheck-ty-custom-python)))
               (if (not (string-empty-p name)) (list "--python" name) "")
               )
             )
            source)
  :error-filter (lambda (errors)
                  (let ((errors (flycheck-sanitize-errors errors)))
                    (seq-map #'flycheck-flake8-fix-error-level errors)))
  :error-patterns
  (
   (error line-start
          (file-name) ":" line ":" (optional column ":") " "
          "error[" (id (one-or-more (any alpha "-"))) "] "
          (message (one-or-more not-newline))
          line-end)
   (warning line-start
            (file-name) ":" line ":" (optional column ":") " "
            "warning[" (id (one-or-more (any alpha "-"))) "] "
            (message (one-or-more not-newline))
            line-end)
   (info line-start
         (file-name) ":" line ":" (optional column ":") " "
         "info[" (id (one-or-more (any alpha "-"))) "] "
         (message (one-or-more not-newline))
         line-end)
   )
  :predicate (lambda () (buffer-file-name))

  :modes (python-mode python-ts-mode)

  :error-explainer
  (lambda (err)
    (let ((error-code (flycheck-error-id err))
          (url "https://github.com/astral-sh/ty/blob/main/docs/reference/rules.md#"))
      (and error-code `(url . ,(concat url error-code)))))
  :next-checkers (python-ruff)
  )

(add-to-list 'flycheck-checkers 'python-ty)
(provide 'flycheck-ty)
;;; flycheck-ty.el ends here
