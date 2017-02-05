;;; gopherize.el --- gopherize.me utility -*- lexical-binding: t; -*-

;; Copyright (C) 2017 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-gopherize
;; Version: 0.01
;; Package-Requires: ((emacs "25"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(eval-when-compile
  (defvar url-http-end-of-headers))

(require 'cl-lib)
(require 'url)
(require 'json)
(require 'map)

(defvar gopherize--categories
  (make-hash-table :test #'equal))

(defun gopherize--collect-categories ()
  (let ((url "https://gopherize.me/api/artwork"))
   (url-retrieve
    url
    (lambda (&rest _args)
      (let* ((content (buffer-substring-no-properties url-http-end-of-headers (point-max)))
             (res (json-read-from-string content)))
        (cl-loop for category across (assoc-default 'categories res)
                 for id = (assoc-default 'id category)
                 for images = (assoc-default 'images category)
                 do
                 (puthash id images gopherize--categories))))
    nil t)))

(defun gopherize--construct-parameters (opt-params)
  (cl-loop for (key . images) in (map-pairs gopherize--categories)
           when  (or (member key '("artwork/010-Body" "artwork/020-Eyes"))
                     (and opt-params (>= (cl-random 1.0) 0.8)))
           collect
           (assoc-default 'id (aref images (random (length images))))))

;;;###autoload
(defun gopherize-me (opt-params)
  (interactive
   (list (not (null current-prefix-arg))))
  (when (zerop (map-length gopherize--categories))
    (user-error "Not initialize categories yet. Please do M-x gopherize-init"))
  (let* ((params (gopherize--construct-parameters opt-params))
         (url (concat "https://gopherize.me/api/render?images="
                      (mapconcat (lambda (p) (url-hexify-string p)) params "|"))))
    (url-retrieve
     url
     (lambda (&rest _args)
       (let ((image (buffer-substring-no-properties
                     (1+ url-http-end-of-headers) (point-max))))
         (save-selected-window
           (with-current-buffer (get-buffer-create "*gopherize me*")
             (let ((buffer-file-coding-system 'binary))
               (fundamental-mode)
               (read-only-mode -1)
               (erase-buffer)
               (insert image)
               (image-mode)
               (pop-to-buffer (current-buffer)))))))
     nil t)))

(defun gopherize-init ()
  (interactive)
  (gopherize--collect-categories))

(provide 'gopherize)

;;; gopherize.el ends here
