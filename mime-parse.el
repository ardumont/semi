;;; mime-parse.el --- MIME message parser

;; Copyright (C) 1994,1995,1996,1997,1998 Free Software Foundation, Inc.

;; Author: MORIOKA Tomohiko <morioka@jaist.ac.jp>
;; Keywords: parse, MIME, multimedia, mail, news

;; This file is part of SEMI (Spadework for Emacs MIME Interfaces).

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

(require 'emu)
(require 'std11)
(require 'mime-def)


;;; @ field parser
;;;

(defconst mime/content-parameter-value-regexp
  (concat "\\("
	  std11-quoted-string-regexp
	  "\\|[^; \t\n]*\\)"))

(defconst mime::parameter-regexp
  (concat "^[ \t]*\;[ \t]*\\(" mime-token-regexp "\\)"
	  "[ \t]*=[ \t]*\\(" mime/content-parameter-value-regexp "\\)"))

(defun mime-parse-parameter (str)
  (if (string-match mime::parameter-regexp str)
      (let ((e (match-end 2)))
	(cons
	 (cons (downcase (substring str (match-beginning 1) (match-end 1)))
	       (std11-strip-quoted-string
		(substring str (match-beginning 2) e))
	       )
	 (substring str e)
	 ))))


;;; @ Content-Type
;;;

(defsubst make-mime-content-type (type subtype &optional parameters)
  (list* (cons 'type type)
	 (cons 'subtype subtype)
	 (nreverse parameters))
  )

(defun mime-parse-Content-Type (string)
  "Parse STRING as field-body of Content-Type field.
Return value is
    (PRIMARY-TYPE SUBTYPE (NAME1 . VALUE1)(NAME2 . VALUE2) ...)
or nil.  PRIMARY-TYPE and SUBTYPE are symbol and NAME_n and VALUE_n
are string."
  (setq string (std11-unfold-string string))
  (if (string-match `,(concat "^\\(" mime-token-regexp
			      "\\)/\\(" mime-token-regexp "\\)") string)
      (let* ((type (downcase
		    (substring string (match-beginning 1) (match-end 1))))
	     (subtype (downcase
		       (substring string (match-beginning 2) (match-end 2))))
	     ret dest)
	(setq string (substring string (match-end 0)))
	(while (setq ret (mime-parse-parameter string))
	  (setq dest (cons (car ret) dest)
		string (cdr ret))
	  )
	(make-mime-content-type (intern type)(intern subtype)
				(nreverse dest))
	)))

(defun mime-read-Content-Type ()
  "Read field-body of Content-Type field from current-buffer,
and return parsed it.  Format of return value is as same as
`mime-parse-Content-Type'."
  (let ((str (std11-field-body "Content-Type")))
    (if str
	(mime-parse-Content-Type str)
      )))

(defsubst mime-content-type-primary-type (content-type)
  "Return primary-type of CONTENT-TYPE."
  (cdr (car content-type)))

(defsubst mime-content-type-subtype (content-type)
  "Return primary-type of CONTENT-TYPE."
  (cdr (cadr content-type)))

(defsubst mime-content-type-parameters (content-type)
  "Return primary-type of CONTENT-TYPE."
  (cddr content-type))

(defsubst mime-content-type-parameter (content-type parameter)
  "Return PARAMETER value of CONTENT-TYPE."
  (cdr (assoc parameter (mime-content-type-parameters content-type))))


;;; @ Content-Disposition
;;;

(defconst mime-disposition-type-regexp mime-token-regexp)

(defun mime-parse-Content-Disposition (string)
  "Parse STRING as field-body of Content-Disposition field."
  (setq string (std11-unfold-string string))
  (if (string-match `,(concat "^" mime-disposition-type-regexp) string)
      (let* ((e (match-end 0))
	     (type (downcase (substring string 0 e)))
	     ret dest)
	(setq string (substring string e))
	(while (setq ret (mime-parse-parameter string))
	  (setq dest (cons (car ret) dest)
		string (cdr ret))
	  )
	(cons (cons 'type (intern type))
	      (nreverse dest))
	)))

(defun mime-read-Content-Disposition ()
  "Read field-body of Content-Disposition field from current-buffer,
and return parsed it."
  (let ((str (std11-field-body "Content-Disposition")))
    (if str
	(mime-parse-Content-Disposition str)
      )))

(defsubst mime-content-disposition-type (content-disposition)
  "Return disposition-type of CONTENT-DISPOSITION."
  (cdr (car content-disposition)))

(defsubst mime-content-disposition-parameters (content-disposition)
  "Return disposition-parameters of CONTENT-DISPOSITION."
  (cdr content-disposition))

(defsubst mime-content-disposition-parameter (content-disposition parameter)
  "Return PARAMETER value of CONTENT-DISPOSITION."
  (cdr (assoc parameter (cdr content-disposition))))

(defsubst mime-content-disposition-filename (content-disposition)
  "Return filename of CONTENT-DISPOSITION."
  (mime-content-disposition-parameter content-disposition "filename"))


;;; @ Content-Transfer-Encoding
;;;

(defun mime-parse-Content-Transfer-Encoding (string)
  "Parse STRING as field-body of Content-Transfer-Encoding field."
  (if (string-match "[ \t\n\r]+$" string)
      (setq string (match-string 0 string))
    )
  (downcase string))

(defun mime-read-Content-Transfer-Encoding (&optional default-encoding)
  "Read field-body of Content-Transfer-Encoding field from
current-buffer, and return it.
If is is not found, return DEFAULT-ENCODING."
  (let ((str (std11-field-body "Content-Transfer-Encoding")))
    (if str
	(mime-parse-Content-Transfer-Encoding str)
      default-encoding)))


;;; @ message parser
;;;

(defalias 'mime-entity-point-min 'mime-entity-header-start)
(defalias 'mime-entity-point-max 'mime-entity-body-end)

(defsubst mime-entity-media-type (entity)
  (mime-content-type-primary-type (mime-entity-content-type entity)))
(defsubst mime-entity-media-subtype (entity)
  (mime-content-type-subtype (mime-entity-content-type entity)))
(defsubst mime-entity-parameters (entity)
  (mime-content-type-parameters (mime-entity-content-type entity)))

(defsubst mime-entity-type/subtype (entity-info)
  (mime-type/subtype-string (mime-entity-media-type entity-info)
			    (mime-entity-media-subtype entity-info)))

(defun mime-parse-multipart (header-start header-end body-start body-end
					  content-type content-disposition
					  encoding node-id)
  (goto-char (point-min))
  (let* ((dash-boundary
	  (concat "--"
		  (std11-strip-quoted-string
		   (mime-content-type-parameter content-type "boundary"))))
	 (delimiter       (concat "\n" (regexp-quote dash-boundary)))
	 (close-delimiter (concat delimiter "--[ \t]*$"))
	 (rsep (concat delimiter "[ \t]*\n"))
	 (dc-ctl
	  (if (eq (mime-content-type-subtype content-type) 'digest)
	      (make-mime-content-type 'message 'rfc822)
	    (make-mime-content-type 'text 'plain)
	    ))
	 cb ce ret ncb children (i 0))
    (save-restriction
      (goto-char body-end)
      (narrow-to-region header-end
			(if (re-search-backward close-delimiter nil t)
			    (match-beginning 0)
			  body-end))
      (goto-char header-start)
      (re-search-forward rsep nil t)
      (setq cb (match-end 0))
      (while (re-search-forward rsep nil t)
	(setq ce (match-beginning 0))
	(setq ncb (match-end 0))
	(save-restriction
	  (narrow-to-region cb ce)
	  (setq ret (mime-parse-message dc-ctl "7bit" (cons i node-id)))
	  )
	(setq children (cons ret children))
	(goto-char (mime-entity-point-max ret))
	(goto-char (setq cb ncb))
	(setq i (1+ i))
	)
      (setq ce (point-max))
      (save-restriction
	(narrow-to-region cb ce)
	(setq ret (mime-parse-message dc-ctl "7bit" (cons i node-id)))
	)
      (setq children (cons ret children))
      )
    (make-mime-entity (current-buffer)
		      header-start header-end body-start body-end
		      node-id content-type content-disposition encoding
		      (nreverse children))
    ))

(defun mime-parse-message (&optional default-ctl default-encoding node-id)
  "Parse current-buffer as a MIME message.
DEFAULT-CTL is used when an entity does not have valid Content-Type
field.  Its format must be as same as return value of
mime-{parse|read}-Content-Type."
  (let ((header-start (point-min))
	header-end
	body-start
	(body-end (point-max))
	content-type content-disposition encoding
	primary-type)
    (goto-char header-start)
    (if (re-search-forward "^$" nil t)
	(setq header-end (match-end 0)
	      body-start (1+ header-end))
      (setq header-end (point-min)
	    body-start (point-min))
      )
    (save-restriction
      (narrow-to-region header-start header-end)
      (setq content-type (or (let ((str (std11-fetch-field "Content-Type")))
			       (if str
				   (mime-parse-Content-Type str)
				 ))
			     default-ctl)
	    content-disposition (let ((str (std11-fetch-field
					    "Content-Disposition")))
				  (if str
				      (mime-parse-Content-Disposition str)
				    ))
	    encoding (let ((str (std11-fetch-field
				 "Content-Transfer-Encoding")))
		       (if str
			   (mime-parse-Content-Transfer-Encoding str)
			 default-encoding))
	    primary-type (mime-content-type-primary-type content-type))
      )
    (cond ((eq primary-type 'multipart)
	   (mime-parse-multipart header-start header-end
				 body-start body-end
				 content-type content-disposition encoding
				 node-id)
	   )
	  ((and (eq primary-type 'message)
		(memq (mime-content-type-subtype content-type)
		      '(rfc822 news)
		      ))
           (make-mime-entity (current-buffer)
			     header-start header-end body-start body-end
			     node-id
			     content-type content-disposition encoding
			     (save-restriction
			       (narrow-to-region body-start body-end)
			       (list (mime-parse-message
				      nil nil (cons 0 node-id)))
			       ))
	   )
	  (t 
           (make-mime-entity (current-buffer)
			     header-start header-end body-start body-end
			     node-id
			     content-type content-disposition encoding nil)
	   ))
    ))


;;; @ utilities
;;;

(defsubst mime-root-entity-p (entity)
  "Return t if ENTITY is root-entity (message)."
  (null (mime-entity-node-id entity)))


;;; @ end
;;;

(provide 'mime-parse)

;;; mime-parse.el ends here
