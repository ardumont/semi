;;; mime-view.el --- interactive MIME viewer for GNU Emacs

;; Copyright (C) 1995,1996,1997,1998 Free Software Foundation, Inc.

;; Author: MORIOKA Tomohiko <morioka@jaist.ac.jp>
;; Created: 1994/07/13
;;	Renamed: 1994/08/31 from tm-body.el
;;	Renamed: 1997/02/19 from tm-view.el
;; Keywords: MIME, multimedia, mail, news

;; This file is part of SEMI (Sophisticated Emacs MIME Interfaces).

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

(require 'std11)
(require 'mel)
(require 'eword-decode)
(require 'mime-parse)
(require 'semi-def)
(require 'calist)
(require 'alist)
(require 'mailcap)


;;; @ version
;;;

(defconst mime-view-version-string
  `,(concat (car mime-module-version) " MIME-View "
	    (mapconcat #'number-to-string (cddr mime-module-version) ".")
	    " (" (cadr mime-module-version) ")"))


;;; @ variables
;;;

(defgroup mime-view nil
  "MIME view mode"
  :group 'mime)

(defcustom mime-view-find-every-acting-situation t
  "*Find every available acting-situation if non-nil."
  :group 'mime-view
  :type 'boolean)

(defcustom mime-acting-situation-examples-file "~/.mime-example"
  "*File name of example about acting-situation demonstrated by user."
  :group 'mime-view
  :type 'file)


;;; @ in raw-buffer (representation space)
;;;

(defvar mime-raw-message-info nil
  "Information about structure of message.
Please use reference function `mime-entity-SLOT' to get value of SLOT.

Following is a list of slots of the structure:

buffer			buffer includes this entity (buffer).
node-id			node-id (list of integers)
header-start		minimum point of header in raw-buffer
header-end		maximum point of header in raw-buffer
body-start		minimum point of body in raw-buffer
body-end		maximum point of body in raw-buffer
content-type		content-type (content-type)
content-disposition	content-disposition (content-disposition)
encoding		Content-Transfer-Encoding (string or nil)
children		entities included in this entity (list of entity)

If an entity includes other entities in its body, such as multipart or
message/rfc822, `mime-entity' structures of them are included in
`children', so the `mime-entity' structure become a tree.")
(make-variable-buffer-local 'mime-raw-message-info)


(defvar mime-preview-buffer nil
  "MIME-preview buffer corresponding with the (raw) buffer.")
(make-variable-buffer-local 'mime-preview-buffer)


(defvar mime-raw-representation-type nil
  "Representation-type of mime-raw-buffer.
It must be nil, `binary' or `cooked'.
If it is nil, `mime-raw-representation-type-alist' is used as default
value.
Notice that this variable is usually used as buffer local variable in
raw-buffer.")

(make-variable-buffer-local 'mime-raw-representation-type)

(defvar mime-raw-representation-type-alist
  '((mime-show-message-mode     . binary)
    (mime-temp-message-mode     . binary)
    (t                          . cooked)
    )
  "Alist of major-mode vs. representation-type of mime-raw-buffer.
Each element looks like (SYMBOL . REPRESENTATION-TYPE).  SYMBOL is
major-mode or t.  t means default.  REPRESENTATION-TYPE must be
`binary' or `cooked'.
This value is overridden by buffer local variable
`mime-raw-representation-type' if it is not nil.")


(defsubst mime-raw-find-entity-from-node-id (entity-node-id
					     &optional message-info)
  "Return entity from ENTITY-NODE-ID in mime-raw-buffer.
If optional argument MESSAGE-INFO is not specified,
`mime-raw-message-info' is used."
  (mime-raw-find-entity-from-number (reverse entity-node-id) message-info))

(defun mime-raw-find-entity-from-number (entity-number &optional message-info)
  "Return entity from ENTITY-NUMBER in mime-raw-buffer.
If optional argument MESSAGE-INFO is not specified,
`mime-raw-message-info' is used."
  (or message-info
      (setq message-info mime-raw-message-info))
  (if (eq entity-number t)
      message-info
    (let ((sn (car entity-number)))
      (if (null sn)
	  message-info
	(let ((rc (nth sn (mime-entity-children message-info))))
	  (if rc
	      (mime-raw-find-entity-from-number (cdr entity-number) rc)
	    ))
	))))

(defun mime-raw-find-entity-from-point (point &optional message-info)
  "Return entity from POINT in mime-raw-buffer.
If optional argument MESSAGE-INFO is not specified,
`mime-raw-message-info' is used."
  (or message-info
      (setq message-info mime-raw-message-info))
  (if (and (<= (mime-entity-point-min message-info) point)
	   (<= point (mime-entity-point-max message-info)))
      (let ((children (mime-entity-children message-info)))
	(catch 'tag
	  (while children
	    (let ((ret
		   (mime-raw-find-entity-from-point point (car children))))
	      (if ret
		  (throw 'tag ret)
		))
	    (setq children (cdr children)))
	  message-info))))


;;; @ in preview-buffer (presentation space)
;;;

(defvar mime-mother-buffer nil
  "Mother buffer corresponding with the (MIME-preview) buffer.
If current MIME-preview buffer is generated by other buffer, such as
message/partial, it is called `mother-buffer'.")
(make-variable-buffer-local 'mime-mother-buffer)

(defvar mime-raw-buffer nil
  "Raw buffer corresponding with the (MIME-preview) buffer.")
(make-variable-buffer-local 'mime-raw-buffer)

(defvar mime-preview-original-window-configuration nil
  "Window-configuration before mime-view-mode is called.")
(make-variable-buffer-local 'mime-preview-original-window-configuration)

(defun mime-preview-original-major-mode (&optional recursive)
  "Return major-mode of original buffer.
If optional argument RECURSIVE is non-nil and current buffer has
mime-mother-buffer, it returns original major-mode of the
mother-buffer."
  (if (and recursive mime-mother-buffer)
      (save-excursion
	(set-buffer mime-mother-buffer)
	(mime-preview-original-major-mode recursive)
	)
    (save-excursion
      (set-buffer
       (mime-entity-buffer
	(get-text-property (point-min) 'mime-view-entity)))
      major-mode)))


;;; @ entity information
;;;

(defsubst mime-entity-parent (entity &optional message-info)
  "Return mother entity of ENTITY.
If optional argument MESSAGE-INFO is not specified,
`mime-raw-message-info' in buffer of ENTITY is used."
  (mime-raw-find-entity-from-node-id
   (cdr (mime-entity-node-id entity))
   (or message-info
       (save-excursion
	 (set-buffer (mime-entity-buffer entity))
	 mime-raw-message-info))))

(defun mime-entity-situation (entity)
  "Return situation of ENTITY."
  (append (or (mime-entity-content-type entity)
	      (make-mime-content-type 'text 'plain))
	  (let ((d (mime-entity-content-disposition entity)))
	    (cons (cons 'disposition-type
			(mime-content-disposition-type d))
		  (mapcar (function
			   (lambda (param)
			     (let ((name (car param)))
			       (cons (cond ((string= name "filename")
					    'filename)
					   ((string= name "creation-date")
					    'creation-date)
					   ((string= name "modification-date")
					    'modification-date)
					   ((string= name "read-date")
					    'read-date)
					   ((string= name "size")
					    'size)
					   (t (cons 'disposition (car param))))
				     (cdr param)))))
			  (mime-content-disposition-parameters d))
		  ))
	  (list (cons 'encoding (mime-entity-encoding entity))
		(cons 'major-mode
		      (save-excursion
			(set-buffer (mime-entity-buffer entity))
			major-mode)))
	  ))


(defvar mime-view-uuencode-encoding-name-list '("x-uue" "x-uuencode"))

(defun mime-raw-get-uu-filename ()
  (save-excursion
    (if (re-search-forward "^begin [0-9]+ " nil t)
	(if (looking-at ".+$")
	    (buffer-substring (match-beginning 0)(match-end 0))
	  ))))

(defun mime-raw-get-subject (entity)
  (or (std11-find-field-body '("Content-Description" "Subject"))
      (let ((ret (mime-entity-content-disposition entity)))
	(and ret
	     (setq ret (mime-content-disposition-filename ret))
	     (std11-strip-quoted-string ret)
	     ))
      (let ((ret (mime-entity-content-type entity)))
	(and ret
	     (setq ret
		   (cdr
		    (let ((param (mime-content-type-parameters ret)))
		      (or (assoc "name" param)
			  (assoc "x-name" param))
		      )))
	     (std11-strip-quoted-string ret)
	     ))
      (if (member (mime-entity-encoding entity)
		  mime-view-uuencode-encoding-name-list)
	  (mime-raw-get-uu-filename))
      ""))


(defsubst mime-raw-point-to-entity-node-id (point &optional message-info)
  "Return entity-node-id from POINT in mime-raw-buffer.
If optional argument MESSAGE-INFO is not specified,
`mime-raw-message-info' is used."
  (mime-entity-node-id (mime-raw-find-entity-from-point point message-info)))

(defsubst mime-raw-point-to-entity-number (point &optional message-info)
  "Return entity-number from POINT in mime-raw-buffer.
If optional argument MESSAGE-INFO is not specified,
`mime-raw-message-info' is used."
  (mime-entity-number (mime-raw-find-entity-from-point point message-info)))

(defun mime-raw-flatten-message-info (&optional message-info)
  "Return list of entity in mime-raw-buffer.
If optional argument MESSAGE-INFO is not specified,
`mime-raw-message-info' is used."
  (or message-info
      (setq message-info mime-raw-message-info))
  (let ((dest (list message-info))
	(rcl (mime-entity-children message-info)))
    (while rcl
      (setq dest (nconc dest (mime-raw-flatten-message-info (car rcl))))
      (setq rcl (cdr rcl)))
    dest))


;;; @ presentation of preview
;;;

;;; @@ entity-button
;;;

;;; @@@ predicate function
;;;

(defun mime-view-entity-button-visible-p (entity)
  "Return non-nil if header of ENTITY is visible.
Please redefine this function if you want to change default setting."
  (let ((media-type (mime-entity-media-type entity))
	(media-subtype (mime-entity-media-subtype entity)))
    (or (not (eq media-type 'application))
	(and (not (eq media-subtype 'x-selection))
	     (or (not (eq media-subtype 'octet-stream))
		 (let ((mother-entity (mime-entity-parent entity)))
		   (or (not (eq (mime-entity-media-type mother-entity)
				'multipart))
		       (not (eq (mime-entity-media-subtype mother-entity)
				'encrypted)))
		   )
		 )))))

;;; @@@ entity button generator
;;;

(defun mime-view-insert-entity-button (entity subject)
  "Insert entity-button of ENTITY."
  (let ((entity-node-id (mime-entity-node-id entity))
	(params (mime-entity-parameters entity)))
    (mime-insert-button
     (let ((access-type (assoc "access-type" params))
	   (num (or (cdr (assoc "x-part-number" params))
		    (if (consp entity-node-id)
			(mapconcat (function
				    (lambda (num)
				      (format "%s" (1+ num))
				      ))
				   (reverse entity-node-id) ".")
		      "0"))
		))
       (cond (access-type
	      (let ((server (assoc "server" params)))
		(setq access-type (cdr access-type))
		(if server
		    (format "%s %s ([%s] %s)"
			    num subject access-type (cdr server))
		(let ((site (cdr (assoc "site" params)))
		      (dir (cdr (assoc "directory" params)))
		      )
		  (format "%s %s ([%s] %s:%s)"
			  num subject access-type site dir)
		  )))
	    )
	   (t
	    (let ((media-type (mime-entity-media-type entity))
		  (media-subtype (mime-entity-media-subtype entity))
		  (charset (cdr (assoc "charset" params)))
		  (encoding (mime-entity-encoding entity)))
	      (concat
	       num " " subject
	       (let ((rest
		      (format " <%s/%s%s%s>"
			      media-type media-subtype
			      (if charset
				  (concat "; " charset)
				"")
			      (if encoding
				  (concat " (" encoding ")")
				""))))
		 (if (>= (+ (current-column)(length rest))(window-width))
		     "\n\t")
		 rest)))
	    )))
     (function mime-preview-play-current-entity))
    ))


;;; @@ entity-header
;;;

(defvar mime-header-presentation-method-alist nil
  "Alist of major mode vs. corresponding header-presentation-method functions.
Each element looks like (SYMBOL . FUNCTION).
SYMBOL must be major mode in raw-buffer or t.  t means default.
Interface of FUNCTION must be (ENTITY SITUATION).")

(defvar mime-view-ignored-field-list
  '(".*Received" ".*Path" ".*Id" "References"
    "Replied" "Errors-To"
    "Lines" "Sender" ".*Host" "Xref"
    "Content-Type" "Precedence"
    "Status" "X-VM-.*")
  "All fields that match this list will be hidden in MIME preview buffer.
Each elements are regexp of field-name.")

(defvar mime-view-visible-field-list '("Dnas.*" "Message-Id")
  "All fields that match this list will be displayed in MIME preview buffer.
Each elements are regexp of field-name.")


;;; @@ entity-body
;;;

;;; @@@ predicate function
;;;

(defun mime-calist::field-match-method-as-default-rule (calist
							field-type field-value)
  (let ((s-field (assq field-type calist)))
    (cond ((null s-field)
	   (cons (cons field-type field-value) calist)
	   )
	  (t calist))))

(define-calist-field-match-method
  'header #'mime-calist::field-match-method-as-default-rule)

(define-calist-field-match-method
  'body #'mime-calist::field-match-method-as-default-rule)


(defvar mime-preview-condition nil
  "Condition-tree about how to display entity.")

(ctree-set-calist-strictly
 'mime-preview-condition '((type . application)(subtype . octet-stream)
			   (encoding . nil)
			   (body . visible)))
(ctree-set-calist-strictly
 'mime-preview-condition '((type . application)(subtype . octet-stream)
			   (encoding . "7bit")
			   (body . visible)))
(ctree-set-calist-strictly
 'mime-preview-condition '((type . application)(subtype . octet-stream)
			   (encoding . "8bit")
			   (body . visible)))

(ctree-set-calist-strictly
 'mime-preview-condition '((type . application)(subtype . pgp)
			   (body . visible)))

(ctree-set-calist-strictly
 'mime-preview-condition '((type . application)(subtype . x-latex)
			   (body . visible)))

(ctree-set-calist-strictly
 'mime-preview-condition '((type . application)(subtype . x-selection)
			   (body . visible)))

(ctree-set-calist-strictly
 'mime-preview-condition '((type . application)(subtype . x-comment)
			   (body . visible)))

(ctree-set-calist-strictly
 'mime-preview-condition '((type . message)(subtype . delivery-status)
			   (body . visible)))

(ctree-set-calist-strictly
 'mime-preview-condition
 '((body . visible)
   (body-presentation-method . mime-preview-text/plain)))

(ctree-set-calist-strictly
 'mime-preview-condition
 '((type . nil)
   (body . visible)
   (body-presentation-method . mime-preview-text/plain)))

(ctree-set-calist-strictly
 'mime-preview-condition
 '((type . text)(subtype . enriched)
   (body . visible)
   (body-presentation-method . mime-preview-text/enriched)))

(ctree-set-calist-strictly
 'mime-preview-condition
 '((type . text)(subtype . richtext)
   (body . visible)
   (body-presentation-method . mime-preview-text/richtext)))

(ctree-set-calist-strictly
 'mime-preview-condition
 '((type . text)(subtype . t)
   (body . visible)
   (body-presentation-method . mime-preview-text/plain)))

(ctree-set-calist-strictly
 'mime-preview-condition
 '((type . multipart)(subtype . alternative)
   (body . visible)
   (body-presentation-method . mime-preview-multipart/alternative)))

(ctree-set-calist-strictly
 'mime-preview-condition '((type . message)(subtype . partial)
			   (body-presentation-method
			    . mime-preview-message/partial-button)))

(ctree-set-calist-strictly
 'mime-preview-condition '((type . message)(subtype . rfc822)
			   (body-presentation-method . nil)
			   (childrens-situation (header . visible)
						(entity-button . invisible))))

(ctree-set-calist-strictly
 'mime-preview-condition '((type . message)(subtype . news)
			   (body-presentation-method . nil)
			   (childrens-situation (header . visible)
						(entity-button . invisible))))


;;; @@@ entity presentation
;;;

(autoload 'mime-preview-text/plain "mime-text")
(autoload 'mime-preview-text/enriched "mime-text")
(autoload 'mime-preview-text/richtext "mime-text")

(defvar mime-view-announcement-for-message/partial
  (if (and (>= emacs-major-version 19) window-system)
      "\
\[[ This is message/partial style split message. ]]
\[[ Please press `v' key in this buffer          ]]
\[[ or click here by mouse button-2.             ]]"
    "\
\[[ This is message/partial style split message. ]]
\[[ Please press `v' key in this buffer.         ]]"
    ))

(defun mime-preview-message/partial-button (&optional entity situation)
  (save-restriction
    (goto-char (point-max))
    (if (not (search-backward "\n\n" nil t))
	(insert "\n")
      )
    (goto-char (point-max))
    (narrow-to-region (point-max)(point-max))
    (insert mime-view-announcement-for-message/partial)
    (mime-add-button (point-min)(point-max)
		     #'mime-preview-play-current-entity)
    ))

(defun mime-preview-multipart/mixed (entity situation)
  (let ((children (mime-entity-children entity))
	(default-situation
	  (cdr (assq 'childrens-situation situation))))
    (while children
      (mime-view-display-entity (car children)
				(save-excursion
				  (set-buffer (mime-entity-buffer entity))
				  mime-raw-message-info)
				(current-buffer)
				default-situation)
      (setq children (cdr children))
      )))

(defcustom mime-view-type-subtype-score-alist
  '(((text . enriched) . 3)
    ((text . richtext) . 2)
    ((text . plain)    . 1)
    (t . 0))
  "Alist MEDIA-TYPE vs corresponding score.
MEDIA-TYPE must be (TYPE . SUBTYPE), TYPE or t.  t means default."
  :group 'mime-view
  :type '(repeat (cons (choice :tag "Media-Type"
			       (item :tag "Type/Subtype"
				     (cons symbol symbol))
			       (item :tag "Type" symbol)
			       (item :tag "Default" t))
		       integer)))

(defun mime-preview-multipart/alternative (entity situation)
  (let* ((children (mime-entity-children entity))
	 (default-situation
	   (cdr (assq 'childrens-situation situation)))
	 (i 0)
	 (p 0)
	 (max-score 0)
	 (situations
	  (mapcar (function
		   (lambda (child)
		     (let ((situation
			    (or (ctree-match-calist
				 mime-preview-condition
				 (append (mime-entity-situation child)
					 default-situation))
				default-situation)))
		       (if (cdr (assq 'body-presentation-method situation))
			   (let ((score
				  (cdr
				   (or (assoc
					(cons
					 (cdr (assq 'type situation))
					 (cdr (assq 'subtype situation)))
					mime-view-type-subtype-score-alist)
				       (assq
					(cdr (assq 'type situation))
					mime-view-type-subtype-score-alist)
				       (assq
					t
					mime-view-type-subtype-score-alist)
				       ))))
			     (if (> score max-score)
				 (setq p i
				       max-score score)
			       )))
		       (setq i (1+ i))
		       situation)
		     ))
		  children)))
    (setq i 0)
    (while children
      (let ((child (car children))
	    (situation (car situations)))
	(mime-view-display-entity child
				  (save-excursion
				    (set-buffer (mime-entity-buffer child))
				    mime-raw-message-info)
				  (current-buffer)
				  default-situation
				  (if (= i p)
				      situation
				    (del-alist 'body-presentation-method
					       (copy-alist situation))))
	)
      (setq children (cdr children)
	    situations (cdr situations)
	    i (1+ i))
      )))


;;; @ acting-condition
;;;

(defvar mime-acting-condition nil
  "Condition-tree about how to process entity.")

(if (file-readable-p mailcap-file)
    (let ((entries (mailcap-parse-file)))
      (while entries
	(let ((entry (car entries))
	      view print shared)
	  (while entry
	    (let* ((field (car entry))
		   (field-type (car field)))
	      (cond ((eq field-type 'view)  (setq view field))
		    ((eq field-type 'print) (setq print field))
		    ((memq field-type '(compose composetyped edit)))
		    (t (setq shared (cons field shared))))
	      )
	    (setq entry (cdr entry))
	    )
	  (setq shared (nreverse shared))
	  (ctree-set-calist-with-default
	   'mime-acting-condition
	   (append shared (list '(mode . "play")(cons 'method (cdr view)))))
	  (if print
	      (ctree-set-calist-with-default
	       'mime-acting-condition
	       (append shared
		       (list '(mode . "print")(cons 'method (cdr view))))
	       ))
	  )
	(setq entries (cdr entries))
	)))

(ctree-set-calist-strictly
 'mime-acting-condition
 '((type . application)(subtype . octet-stream)
   (mode . "play")
   (method . mime-method-to-detect)
   ))

(ctree-set-calist-with-default
 'mime-acting-condition
 '((mode . "extract")
   (method . mime-method-to-save)))

(ctree-set-calist-strictly
 'mime-acting-condition
 '((type . text)(subtype . x-rot13-47)(mode . "play")
   (method . mime-method-to-display-caesar)
   ))
(ctree-set-calist-strictly
 'mime-acting-condition
 '((type . text)(subtype . x-rot13-47-48)(mode . "play")
   (method . mime-method-to-display-caesar)
   ))

(ctree-set-calist-strictly
 'mime-acting-condition
 '((type . message)(subtype . rfc822)(mode . "play")
   (method . mime-method-to-display-message/rfc822)
   ))
(ctree-set-calist-strictly
 'mime-acting-condition
 '((type . message)(subtype . partial)(mode . "play")
   (method . mime-method-to-store-message/partial)
   ))

(ctree-set-calist-strictly
 'mime-acting-condition
 '((type . message)(subtype . external-body)
   ("access-type" . "anon-ftp")
   (method . mime-method-to-display-message/external-ftp)
   ))

(ctree-set-calist-strictly
 'mime-acting-condition
 '((type . application)(subtype . octet-stream)
   (method . mime-method-to-save)
   ))


;;; @ quitting method
;;;

(defvar mime-preview-quitting-method-alist
  '((mime-show-message-mode
     . mime-preview-quitting-method-for-mime-show-message-mode))
  "Alist of major-mode vs. quitting-method of mime-view.")

(defvar mime-preview-over-to-previous-method-alist nil
  "Alist of major-mode vs. over-to-previous-method of mime-view.")

(defvar mime-preview-over-to-next-method-alist nil
  "Alist of major-mode vs. over-to-next-method of mime-view.")


;;; @ following method
;;;

(defvar mime-view-following-method-alist nil
  "Alist of major-mode vs. following-method of mime-view.")

(defvar mime-view-following-required-fields-list
  '("From"))


;;; @ X-Face
;;;

;; hack from Gnus 5.0.4.

(defvar mime-view-x-face-to-pbm-command
  "{ echo '/* Width=48, Height=48 */'; uncompface; } | icontopbm")

(defvar mime-view-x-face-command
  (concat mime-view-x-face-to-pbm-command
	  " | xv -quit -")
  "String to be executed to display an X-Face field.
The command will be executed in a sub-shell asynchronously.
The compressed face will be piped to this command.")

(defun mime-view-x-face-function ()
  "Function to display X-Face field. You can redefine to customize."
  ;; 1995/10/12 (c.f. tm-eng:130)
  ;;	fixed by Eric Ding <ericding@San-Jose.ate.slb.com>
  (save-restriction
    (narrow-to-region (point-min) (re-search-forward "^$" nil t))
    ;; end
    (goto-char (point-min))
    (if (re-search-forward "^X-Face:[ \t]*" nil t)
	(let ((beg (match-end 0))
	      (end (std11-field-end))
	      )
	  (call-process-region beg end "sh" nil 0 nil
			       "-c" mime-view-x-face-command)
	  ))))


;;; @ buffer setup
;;;

(defun mime-view-display-entity (entity message-info obuf
					default-situation
					&optional situation)
  (let* ((raw-buffer (mime-entity-buffer entity))
	 (start (mime-entity-point-min entity))
	 (end (mime-entity-point-max entity))
	 end-of-header e nb ne subj)
    (set-buffer raw-buffer)
    (goto-char start)
    (setq end-of-header (if (re-search-forward "^$" nil t)
			    (1+ (match-end 0))
			  end))
    (if (> end-of-header end)
	(setq end-of-header end)
      )
    (save-restriction
      (narrow-to-region start end)
      (setq subj (eword-decode-string (mime-raw-get-subject entity)))
      )
    (or situation
	(setq situation
	      (or (ctree-match-calist mime-preview-condition
				      (append (mime-entity-situation entity)
					      default-situation))
		  default-situation)))
    (let ((button-is-invisible
	   (eq (cdr (assq 'entity-button situation)) 'invisible))
	  (header-is-visible
	   (eq (cdr (assq 'header situation)) 'visible))
	  (header-presentation-method
	   (or (cdr (assq 'header-presentation-method situation))
	       (cdr (assq major-mode mime-header-presentation-method-alist))))
	  (body-presentation-method
	   (cdr (assq 'body-presentation-method situation)))
	  (children (mime-entity-children entity)))
      (set-buffer obuf)
      (setq nb (point))
      (narrow-to-region nb nb)
      (or button-is-invisible
	  (if (mime-view-entity-button-visible-p entity)
	      (mime-view-insert-entity-button entity subj)
	    ))
      (when header-is-visible
	(if header-presentation-method
	    (funcall header-presentation-method entity situation)
	  (mime-insert-decoded-header
	   entity
	   mime-view-ignored-field-list mime-view-visible-field-list
	   (save-excursion
	     (set-buffer raw-buffer)
	     (if (eq (cdr (assq major-mode mime-raw-representation-type))
		     'binary)
		 default-mime-charset)
	     )))
	(insert "\n")
	)
      (cond ((eq body-presentation-method 'with-filter)
	     (let ((body-filter (cdr (assq 'body-filter situation))))
	       (save-restriction
		 (narrow-to-region (point-max)(point-max))
		 (insert-buffer-substring raw-buffer end-of-header end)
		 (funcall body-filter situation)
		 )))
	    (children)
	    ((functionp body-presentation-method)
	     (funcall body-presentation-method entity situation)
	     )
	    (t
	     (when button-is-invisible
	       (goto-char (point-max))
	       (mime-view-insert-entity-button entity subj)
	       )
	     (or header-is-visible
		 (progn
		   (goto-char (point-max))
		   (insert "\n")
		   ))
	     ))
      (setq ne (point-max))
      (widen)
      (put-text-property nb ne 'mime-view-entity entity)
      (goto-char ne)
      (if children
	  (if (functionp body-presentation-method)
	      (funcall body-presentation-method entity situation)
	    (mime-preview-multipart/mixed entity situation)
	    ))
      )))


;;; @ MIME viewer mode
;;;

(defconst mime-view-menu-title "MIME-View")
(defconst mime-view-menu-list
  '((up		 "Move to upper entity"    mime-preview-move-to-upper)
    (previous	 "Move to previous entity" mime-preview-move-to-previous)
    (next	 "Move to next entity"	   mime-preview-move-to-next)
    (scroll-down "Scroll-down"             mime-preview-scroll-down-entity)
    (scroll-up	 "Scroll-up"               mime-preview-scroll-up-entity)
    (play	 "Play current entity"     mime-preview-play-current-entity)
    (extract	 "Extract current entity"  mime-preview-extract-current-entity)
    (print	 "Print current entity"    mime-preview-print-current-entity)
    (x-face	 "Show X Face"             mime-preview-display-x-face)
    )
  "Menu for MIME Viewer")

(cond (running-xemacs
       (defvar mime-view-xemacs-popup-menu
	 (cons mime-view-menu-title
	       (mapcar (function
			(lambda (item)
			  (vector (nth 1 item)(nth 2 item) t)
			  ))
		       mime-view-menu-list)))
       (defun mime-view-xemacs-popup-menu (event)
	 "Popup the menu in the MIME Viewer buffer"
	 (interactive "e")
	 (select-window (event-window event))
	 (set-buffer (event-buffer event))
	 (popup-menu 'mime-view-xemacs-popup-menu))
       (defvar mouse-button-2 'button2)
       )
      (t
       (defvar mouse-button-2 [mouse-2])
       ))

(defun mime-view-define-keymap (&optional default)
  (let ((mime-view-mode-map (if (keymapp default)
				(copy-keymap default)
			      (make-sparse-keymap)
			      )))
    (define-key mime-view-mode-map
      "u"        (function mime-preview-move-to-upper))
    (define-key mime-view-mode-map
      "p"        (function mime-preview-move-to-previous))
    (define-key mime-view-mode-map
      "n"        (function mime-preview-move-to-next))
    (define-key mime-view-mode-map
      "\e\t"     (function mime-preview-move-to-previous))
    (define-key mime-view-mode-map
      "\t"       (function mime-preview-move-to-next))
    (define-key mime-view-mode-map
      " "        (function mime-preview-scroll-up-entity))
    (define-key mime-view-mode-map
      "\M- "     (function mime-preview-scroll-down-entity))
    (define-key mime-view-mode-map
      "\177"     (function mime-preview-scroll-down-entity))
    (define-key mime-view-mode-map
      "\C-m"     (function mime-preview-next-line-entity))
    (define-key mime-view-mode-map
      "\C-\M-m"  (function mime-preview-previous-line-entity))
    (define-key mime-view-mode-map
      "v"        (function mime-preview-play-current-entity))
    (define-key mime-view-mode-map
      "e"        (function mime-preview-extract-current-entity))
    (define-key mime-view-mode-map
      "\C-c\C-p" (function mime-preview-print-current-entity))
    (define-key mime-view-mode-map
      "a"        (function mime-preview-follow-current-entity))
    (define-key mime-view-mode-map
      "q"        (function mime-preview-quit))
    (define-key mime-view-mode-map
      "\C-c\C-x" (function mime-preview-kill-buffer))
    ;; (define-key mime-view-mode-map
    ;;   "<"        (function beginning-of-buffer))
    ;; (define-key mime-view-mode-map
    ;;   ">"        (function end-of-buffer))
    (define-key mime-view-mode-map
      "?"        (function describe-mode))
    (define-key mime-view-mode-map
      [tab] (function mime-preview-move-to-next))
    (define-key mime-view-mode-map
      [delete] (function mime-preview-scroll-down-entity))
    (define-key mime-view-mode-map
      [backspace] (function mime-preview-scroll-down-entity))
    (if (functionp default)
	(cond (running-xemacs
	       (set-keymap-default-binding mime-view-mode-map default)
	       )
	      (t
	       (setq mime-view-mode-map
		     (append mime-view-mode-map (list (cons t default))))
	       )))
    (if mouse-button-2
	(define-key mime-view-mode-map
	  mouse-button-2 (function mime-button-dispatcher))
      )
    (cond (running-xemacs
	   (define-key mime-view-mode-map
	     mouse-button-3 (function mime-view-xemacs-popup-menu))
	   )
	  ((>= emacs-major-version 19)
	   (define-key mime-view-mode-map [menu-bar mime-view]
	     (cons mime-view-menu-title
		   (make-sparse-keymap mime-view-menu-title)))
	   (mapcar (function
		    (lambda (item)
		      (define-key mime-view-mode-map
			(vector 'menu-bar 'mime-view (car item))
			(cons (nth 1 item)(nth 2 item))
			)
		      ))
		   (reverse mime-view-menu-list)
		   )
	   ))
    (use-local-map mime-view-mode-map)
    (run-hooks 'mime-view-define-keymap-hook)
    ))

(defsubst mime-maybe-hide-echo-buffer ()
  "Clear mime-echo buffer and delete window for it."
  (let ((buf (get-buffer mime-echo-buffer-name)))
    (if buf
	(save-excursion
	  (set-buffer buf)
	  (erase-buffer)
	  (let ((win (get-buffer-window buf)))
	    (if win
		(delete-window win)
	      ))
	  (bury-buffer buf)
	  ))))

(defvar mime-view-redisplay nil)

(defun mime-view-display-message (message &optional preview-buffer
					  mother default-keymap-or-function)
  (mime-maybe-hide-echo-buffer)
  (let ((win-conf (current-window-configuration))
	(raw-buffer (mime-entity-buffer message)))
    (or preview-buffer
	(setq preview-buffer
	      (concat "*Preview-" (buffer-name raw-buffer) "*")))
    (set-buffer raw-buffer)
    (setq mime-raw-message-info (mime-parse-message))
    (setq mime-preview-buffer preview-buffer)
    (let ((inhibit-read-only t))
      (switch-to-buffer preview-buffer)
      (widen)
      (erase-buffer)
      (setq mime-raw-buffer raw-buffer)
      (if mother
	  (setq mime-mother-buffer mother)
	)
      (setq mime-preview-original-window-configuration win-conf)
      (setq major-mode 'mime-view-mode)
      (setq mode-name "MIME-View")
      (mime-view-display-entity message message
				preview-buffer
				'((entity-button . invisible)
				  (header . visible)
				  ))
      (mime-view-define-keymap default-keymap-or-function)
      (let ((point
	     (next-single-property-change (point-min) 'mime-view-entity)))
	(if point
	    (goto-char point)
	  (goto-char (point-min))
	  (search-forward "\n\n" nil t)
	  ))
      (run-hooks 'mime-view-mode-hook)
      ))
  (set-buffer-modified-p nil)
  (setq buffer-read-only t)
  )

(defun mime-view-buffer (&optional raw-buffer preview-buffer mother
				   default-keymap-or-function)
  (interactive)
  (mime-view-display-message
   (save-excursion
     (if raw-buffer (set-buffer raw-buffer))
     (mime-parse-message)
     )
   preview-buffer mother default-keymap-or-function))

(defun mime-view-mode (&optional mother ctl encoding
				 raw-buffer preview-buffer
				 default-keymap-or-function)
  "Major mode for viewing MIME message.

Here is a list of the standard keys for mime-view-mode.

key		feature
---		-------

u		Move to upper content
p or M-TAB	Move to previous content
n or TAB	Move to next content
SPC		Scroll up or move to next content
M-SPC or DEL	Scroll down or move to previous content
RET		Move to next line
M-RET		Move to previous line
v		Decode current content as `play mode'
e		Decode current content as `extract mode'
C-c C-p		Decode current content as `print mode'
a		Followup to current content.
q		Quit
button-2	Move to point under the mouse cursor
        	and decode current content as `play mode'
"
  (interactive)
  (mime-view-display-message
   (save-excursion
     (if raw-buffer (set-buffer raw-buffer))
     (or mime-view-redisplay
	 (mime-parse-message ctl encoding))
     )
   preview-buffer mother default-keymap-or-function))


;;; @@ playing
;;;

(autoload 'mime-preview-play-current-entity "mime-play"
  "Play current entity." t)

(defun mime-preview-extract-current-entity ()
  "Extract current entity into file (maybe).
It decodes current entity to call internal or external method as
\"extract\" mode.  The method is selected from variable
`mime-acting-condition'."
  (interactive)
  (mime-preview-play-current-entity "extract")
  )

(defun mime-preview-print-current-entity ()
  "Print current entity (maybe).
It decodes current entity to call internal or external method as
\"print\" mode.  The method is selected from variable
`mime-acting-condition'."
  (interactive)
  (mime-preview-play-current-entity "print")
  )


;;; @@ following
;;;

(defun mime-preview-follow-current-entity ()
  "Write follow message to current entity.
It calls following-method selected from variable
`mime-view-following-method-alist'."
  (interactive)
  (let (entity)
    (while (null (setq entity
		       (get-text-property (point) 'mime-view-entity)))
      (backward-char)
      )
    (let* ((p-beg
	    (previous-single-property-change (point) 'mime-view-entity))
	   p-end
	   (entity-node-id (mime-entity-node-id entity))
	   (len (length entity-node-id))
	   )
      (cond ((null p-beg)
	     (setq p-beg
		   (if (eq (next-single-property-change (point-min)
							'mime-view-entity)
			   (point))
		       (point)
		     (point-min)))
	     )
	    ((eq (next-single-property-change p-beg 'mime-view-entity)
		 (point))
	     (setq p-beg (point))
	     ))
      (setq p-end (next-single-property-change p-beg 'mime-view-entity))
      (cond ((null p-end)
	     (setq p-end (point-max))
	     )
	    ((null entity-node-id)
	     (setq p-end (point-max))
	     )
	    (t
	     (save-excursion
	       (goto-char p-end)
	       (catch 'tag
		 (let (e)
		   (while (setq e
				(next-single-property-change
				 (point) 'mime-view-entity))
		     (goto-char e)
		     (let ((rc (mime-entity-node-id
				(get-text-property (point)
						   'mime-view-entity))))
		       (or (equal entity-node-id
				  (nthcdr (- (length rc) len) rc))
			   (throw 'tag nil)
			   ))
		     (setq p-end e)
		     ))
		 (setq p-end (point-max))
		 ))
	     ))
      (let* ((mode (mime-preview-original-major-mode 'recursive))
	     (new-name
	      (format "%s-%s" (buffer-name) (reverse entity-node-id)))
	     new-buf
	     (the-buf (current-buffer))
	     (a-buf mime-raw-buffer)
	     fields)
	(save-excursion
	  (set-buffer (setq new-buf (get-buffer-create new-name)))
	  (erase-buffer)
	  (insert-buffer-substring the-buf p-beg p-end)
	  (goto-char (point-min))
          (let ((entity-node-id (mime-entity-node-id entity)) ci str)
	    (while (progn
		     (setq
		      str
		      (save-excursion
			(set-buffer a-buf)
			(setq
			 ci
			 (mime-raw-find-entity-from-node-id entity-node-id))
			(save-restriction
			  (narrow-to-region
			   (mime-entity-point-min ci)
			   (mime-entity-point-max ci)
			   )
			  (std11-header-string-except
			   (concat "^"
				   (apply (function regexp-or) fields)
				   ":") ""))))
		     (if (and
			  (eq (mime-entity-media-type ci) 'message)
			  (eq (mime-entity-media-subtype ci) 'rfc822))
			 nil
		       (if str
			   (insert str)
			 )
		       entity-node-id))
	      (setq fields (std11-collect-field-names)
		    entity-node-id (cdr entity-node-id))
	      )
	    )
	  (let ((rest mime-view-following-required-fields-list))
	    (while rest
	      (let ((field-name (car rest)))
		(or (std11-field-body field-name)
		    (insert
		     (format
		      (concat field-name
			      ": "
			      (save-excursion
				(set-buffer the-buf)
				(set-buffer mime-mother-buffer)
				(set-buffer mime-raw-buffer)
				(std11-field-body field-name)
				)
			      "\n")))
		    ))
	      (setq rest (cdr rest))
	      ))
	  (eword-decode-header)
	  )
	(let ((f (cdr (assq mode mime-view-following-method-alist))))
	  (if (functionp f)
	      (funcall f new-buf)
	    (message
	     (format
	      "Sorry, following method for %s is not implemented yet."
	      mode))
	    ))
	))))


;;; @@ X-Face
;;;

(defun mime-preview-display-x-face ()
  (interactive)
  (save-window-excursion
    (set-buffer mime-raw-buffer)
    (mime-view-x-face-function)
    ))


;;; @@ moving
;;;

(defun mime-preview-move-to-upper ()
  "Move to upper entity.
If there is no upper entity, call function `mime-preview-quit'."
  (interactive)
  (let (cinfo)
    (while (null (setq cinfo
		       (get-text-property (point) 'mime-view-entity)))
      (backward-char)
      )
    (let ((r (mime-raw-find-entity-from-node-id
	      (cdr (mime-entity-node-id cinfo))
	      (get-text-property 1 'mime-view-entity)))
	  point)
      (catch 'tag
	(while (setq point (previous-single-property-change
			    (point) 'mime-view-entity))
	  (goto-char point)
	  (if (eq r (get-text-property (point) 'mime-view-entity))
	      (throw 'tag t)
	    )
	  )
	(mime-preview-quit)
	))))

(defun mime-preview-move-to-previous ()
  "Move to previous entity.
If there is no previous entity, it calls function registered in
variable `mime-preview-over-to-previous-method-alist'."
  (interactive)
  (while (null (get-text-property (point) 'mime-view-entity))
    (backward-char)
    )
  (let ((point (previous-single-property-change (point) 'mime-view-entity)))
    (if point
	(if (get-text-property (1- point) 'mime-view-entity)
	    (goto-char point)
	  (goto-char (1- point))
	  (mime-preview-move-to-previous)
	  )
      (let ((f (assq (mime-preview-original-major-mode)
		     mime-preview-over-to-previous-method-alist)))
	(if f
	    (funcall (cdr f))
	  ))
      )))

(defun mime-preview-move-to-next ()
  "Move to next entity.
If there is no previous entity, it calls function registered in
variable `mime-preview-over-to-next-method-alist'."
  (interactive)
  (while (null (get-text-property (point) 'mime-view-entity))
    (forward-char)
    )
  (let ((point (next-single-property-change (point) 'mime-view-entity)))
    (if point
	(progn
	  (goto-char point)
	  (if (null (get-text-property point 'mime-view-entity))
	      (mime-preview-move-to-next)
	    ))
      (let ((f (assq (mime-preview-original-major-mode)
		     mime-preview-over-to-next-method-alist)))
	(if f
	    (funcall (cdr f))
	  ))
      )))

(defun mime-preview-scroll-up-entity (&optional h)
  "Scroll up current entity.
If reached to (point-max), it calls function registered in variable
`mime-preview-over-to-next-method-alist'."
  (interactive)
  (or h
      (setq h (1- (window-height)))
      )
  (if (= (point) (point-max))
      (let ((f (assq (mime-preview-original-major-mode)
                     mime-preview-over-to-next-method-alist)))
        (if f
            (funcall (cdr f))
          ))
    (let ((point
	   (or (next-single-property-change (point) 'mime-view-entity)
	       (point-max))))
      (forward-line h)
      (if (> (point) point)
          (goto-char point)
        )
      )))

(defun mime-preview-scroll-down-entity (&optional h)
  "Scroll down current entity.
If reached to (point-min), it calls function registered in variable
`mime-preview-over-to-previous-method-alist'."
  (interactive)
  (or h
      (setq h (1- (window-height)))
      )
  (if (= (point) (point-min))
      (let ((f (assq (mime-preview-original-major-mode)
		     mime-preview-over-to-previous-method-alist)))
        (if f
            (funcall (cdr f))
          ))
    (let ((point
	   (or (previous-single-property-change (point) 'mime-view-entity)
	       (point-min))))
      (forward-line (- h))
      (if (< (point) point)
          (goto-char point)
        ))))

(defun mime-preview-next-line-entity ()
  (interactive)
  (mime-preview-scroll-up-entity 1)
  )

(defun mime-preview-previous-line-entity ()
  (interactive)
  (mime-preview-scroll-down-entity 1)
  )


;;; @@ quitting
;;;

(defun mime-preview-quit ()
  "Quit from MIME-preview buffer.
It calls function registered in variable
`mime-preview-quitting-method-alist'."
  (interactive)
  (let ((r (assq (mime-preview-original-major-mode)
		 mime-preview-quitting-method-alist)))
    (if r
	(funcall (cdr r))
      )))

(defun mime-preview-kill-buffer ()
  (interactive)
  (kill-buffer (current-buffer))
  )


;;; @ end
;;;

(provide 'mime-view)

(run-hooks 'mime-view-load-hook)

;;; mime-view.el ends here
