;;; pgg.el --- glue for the various PGP implementations.

;; Copyright (C) 1999 Daiki Ueno

;; Author: Daiki Ueno <ueno@ueda.info.waseda.ac.jp>
;; Created: 1999/10/28
;; Keywords: PGP

;; This file is part of SEMI (Secure Emacs MIME Interface).

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Code:

(require 'calist)

(eval-and-compile (require 'luna))

(require 'pgg-def)
(require 'pgg-parse)

(eval-when-compile
  (ignore-errors 
    (require 'w3)
    (require 'url)))

(in-calist-package 'pgg)

(defun pgg-field-match-method-with-containment
  (calist field-type field-value)
  (let ((s-field (assq field-type calist)))
    (cond ((null s-field)
	   (cons (cons field-type field-value) calist)
	   )
	  ((memq (cdr s-field) field-value)
	   calist))))

(define-calist-field-match-method 'signature-version
  #'pgg-field-match-method-with-containment)

(define-calist-field-match-method 'symmetric-key-algorithm
  #'pgg-field-match-method-with-containment)

(define-calist-field-match-method 'public-key-algorithm
  #'pgg-field-match-method-with-containment)

(define-calist-field-match-method 'hash-algorithm
  #'pgg-field-match-method-with-containment)

(defvar pgg-verify-condition nil
  "Condition-tree about which PGP implementation is used for verifying.")

(defvar pgg-decrypt-condition nil
  "Condition-tree about which PGP implementation is used for decrypting.")

(ctree-set-calist-strictly
 'pgg-verify-condition
 '((signature-version 3)(public-key-algorithm RSA)(hash-algorithm MD5)
   (scheme . pgp)))

(ctree-set-calist-strictly
 'pgg-decrypt-condition
 '((public-key-algorithm RSA)(symmetric-key-algorithm IDEA)
   (scheme . pgp)))

(ctree-set-calist-strictly
 'pgg-verify-condition
 '((signature-version 3 4)
   (public-key-algorithm RSA ELG DSA)
   (hash-algorithm MD5 SHA1 RIPEMD160)
   (scheme . pgp5)))

(ctree-set-calist-strictly
 'pgg-decrypt-condition
 '((public-key-algorithm RSA ELG DSA)
   (symmetric-key-algorithm 3DES CAST5 IDEA)
   (scheme . pgp5)))

(ctree-set-calist-strictly
 'pgg-verify-condition
 '((signature-version 3 4)
   (public-key-algorithm ELG-E DSA ELG)
   (hash-algorithm MD5 SHA1 RIPEMD160)
   (scheme . gpg)))

(ctree-set-calist-strictly
 'pgg-decrypt-condition
 '((public-key-algorithm ELG-E DSA ELG)
   (symmetric-key-algorithm 3DES CAST5 BLOWFISH TWOFISH)
   (scheme . gpg)))

;;; @ definition of the implementation scheme
;;;

(eval-and-compile
  (luna-define-class pgg-scheme ())

  (luna-define-internal-accessors 'pgg-scheme)
  )

(luna-define-generic lookup-key-string (scheme string &optional type)
  "Search keys associated with STRING")

(luna-define-generic encrypt-region (scheme start end recipients)
  "Encrypt the current region between START and END.")

(luna-define-generic decrypt-region (scheme start end)
  "Decrypt the current region between START and END.")

(luna-define-generic sign-region (scheme start end)
  "Make detached signature from text between START and END.")

(luna-define-generic verify-region (scheme start end &optional signature)
  "Verify region between START and END 
as the detached signature SIGNATURE.")

(luna-define-generic insert-key (scheme)
  "Insert public key at point.")

(luna-define-generic snarf-keys-region (scheme start end)
  "Add all public keys in region between START 
and END to the keyring.")

;;; @ interface functions
;;;

(defmacro pgg-make-scheme (scheme)
  `(progn
     (require (intern (format "pgg-%s" ,scheme)))
     (funcall (intern (format "pgg-make-scheme-%s" 
			      ,scheme)))))

(defun pgg-encrypt-region (start end rcpts)
  (interactive
   (list (region-beginning)(region-end)
	 (split-string (read-string "Recipients: ") "[ \t,]+")))
  (let ((entity (pgg-make-scheme pgg-default-scheme)))
    (luna-send entity 'encrypt-region entity start end rcpts)))

(defun pgg-decrypt-region (start end)
  (interactive "r")
  (let* ((packet (cdr (assq 1 (pgg-parse-armor-region start end))))
	 (scheme
	  (or pgg-scheme
	      (cdr (assq 'scheme
			 (progn
			   (in-calist-package 'pgg)
			   (ctree-match-calist pgg-decrypt-condition
					       packet))))
	      pgg-default-scheme))
	 (entity (pgg-make-scheme scheme)))
    (luna-send entity 'decrypt-region entity start end)))

(defun pgg-sign-region (start end)
  (interactive "r")
  (let ((entity (pgg-make-scheme pgg-default-scheme)))
    (luna-send entity 'sign-region entity start end)))

(defun pgg-verify-region (start end &optional signature fetch)
  (interactive "r")
  (let* ((packet
	  (with-temp-buffer
	    (buffer-disable-undo)
	    (set-buffer-multibyte nil)
	    (insert-file-contents signature)
	    (cdr (assq 2 (pgg-decode-armor-region (point-min)(point-max))))
	    ))
	 (scheme
	  (or pgg-scheme
	      (cdr (assq 'scheme
			 (progn
			   (in-calist-package 'pgg)
			   (ctree-match-calist pgg-verify-condition
					       packet))))
	      pgg-default-scheme))
	 (entity (pgg-make-scheme scheme))
	 (key (cdr (assq 'key-identifier packet)))
	 keyserver)
    (and (stringp key)
	 (setq key (concat "0x" (pgg-truncate-key-identifier key)))
	 (null (pgg-lookup-key-string key))
	 fetch
	 (y-or-n-p (format "Key %s not found; attempt to fetch? " key))
	 (setq keyserver 
	       (or (cdr (assq 'preferred-key-server packet))
		   pgg-default-keyserver-address))
	 (ignore-errors (require 'url))
	 (pgg-fetch-key
	  (if (url-type (url-generic-parse-url keyserver))
	      keyserver
	    (format "http://%s:11371/pks/lookup?op=get&search=%s"
		    keyserver key))))
    (luna-send entity 'verify-region entity start end signature)))

(defun pgg-insert-key ()
  (let ((entity (pgg-make-scheme (or pgg-scheme pgg-default-scheme))))
    (luna-send entity 'insert-key entity)))

(defun pgg-snarf-keys-region (start end)
  (let ((entity (pgg-make-scheme (or pgg-scheme pgg-default-scheme))))
    (luna-send entity 'snarf-keys-region entity start end)))

(defun pgg-lookup-key-string (string &optional type)
  (let ((entity (pgg-make-scheme (or pgg-scheme pgg-default-scheme))))
    (luna-send entity 'lookup-key-string entity string type)))

(defun pgg-fetch-key (url)
  "Attempt to fetch a key for addition to PGP or GnuPG keyring.

Return t if we think we were successful; nil otherwise.  Note that nil
is not necessarily an error, since we may have merely fired off an Email
request for the key."
  (require 'w3)
  (require 'url)
  (with-current-buffer (get-buffer-create pgg-output-buffer)
    (buffer-disable-undo)
    (erase-buffer)
    (let ((proto (url-type (url-generic-parse-url url)))
	  buffer-file-name)
      (unless (memq (intern proto) '(http finger))
	(insert (format "Protocol %s is not supported.\n" proto)))
      (url-insert-file-contents url)
      (if (re-search-forward "^-+BEGIN" nil 'last)
	  (progn
	    (delete-region (point-min) (match-beginning 0))
	    (when (re-search-forward "^-+END" nil t)
	      (delete-region (progn (end-of-line) (point))
			     (point-max)))
	    (insert "\n")
	    (with-temp-buffer
	      (insert-buffer-substring pgg-output-buffer)
	      (pgg-snarf-keys-region (point-min)(point-max))))
	(erase-buffer)
	(insert "Cannot retrieve public key from URL (" url ")\n")))
    ))


;;; @ utility functions
;;;

(defvar pgg-passphrase-cache-expiry 16)
(defvar pgg-passphrase-cache (make-vector 7 0))

(defvar pgg-read-passphrase nil)
(defun pgg-read-passphrase (prompt &optional key)
  (if (not pgg-read-passphrase)
      (if (functionp 'read-passwd)
	  (setq pgg-read-passphrase 'read-passwd)
	(if (load "passwd" t)
	    (setq pgg-read-passphrase 'read-passwd)
	  (autoload 'ange-ftp-read-passwd "ange-ftp")
	  (setq pgg-read-passphrase 'ange-ftp-read-passwd))))
  (or (and key (setq key (pgg-truncate-key-identifier key))
	   (symbol-value (intern-soft key pgg-passphrase-cache)))
      (funcall pgg-read-passphrase prompt)))

(defun pgg-add-passphrase-cache (key passphrase)
  (setq key (pgg-truncate-key-identifier key))
  (set (intern key pgg-passphrase-cache)
       passphrase)
  (run-at-time pgg-passphrase-cache-expiry nil
	       #'pgg-remove-passphrase-cache
	       key))

(defun pgg-remove-passphrase-cache (key)
  (unintern key pgg-passphrase-cache))

(provide 'pgg)

;;; pgg.el ends here