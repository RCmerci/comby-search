;;; comby-search.el --- search codes using comby     -*- lexical-binding: t; -*-

;; Copyright (C) 2020  rcmerci

;; Author: rcmerci <rcmerci@gmail.com>
;; Keywords: matching

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

(defcustom comby-search-comby-bin (executable-find "comby")
  "comby binary path")

(defvar comby-search-lang-match-param '((go . "-matcher .go")
					(ocaml . "-matcher .ml")))

;;;###autoload
(defun comby-search (&optional lang template)
  (interactive (list
		(completing-read "select language: "
				 comby-search-lang-match-param)
		(completing-read
		 "select searching template: "
		 '("interface {:[_]MethodName(:[_]):[_]}"))))
  (unless comby-search-comby-bin
    (error "'comby' not found"))
  (when (get-buffer "*comby-search*")
    (kill-buffer "*comby-search*"))

  (let* ((input (read-from-minibuffer ">> " template))
	 (proc
	  (start-process-shell-command "*comby-search*"
				       (get-buffer-create "*comby-search*")
				       (format "%s -o %s -exclude-dir 'vendor,bin,.' %s '%s' ''"
					       comby-search-comby-bin
					       (cdr (assoc (intern lang) comby-search-lang-match-param))
					       (if (projectile-project-root) (format "-directory %s" (projectile-project-root)) "")
					       input))))
    (set-process-filter proc (lambda (proc str)
			       (with-current-buffer (process-buffer proc)
				 (insert str))))
    (set-process-sentinel proc (lambda (proc _s)
				 (when (eq (process-status proc) 'exit)
				   (with-current-buffer (process-buffer proc)
				     (goto-char (point-min))
				     (while (search-forward "\\n" nil t)
				       (replace-match "\n" "FIXEDCASE" "LITERAL"))
				     (compilation-mode)
				     (pop-to-buffer (current-buffer))))))))


(provide 'comby-search)
;;; comby-search.el ends here
