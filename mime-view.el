;;; mime-view.el --- interactive MIME viewer for GNU Emacs

;; Copyright (C) 1995,1996,1997,1998 Free Software Foundation, Inc.

;; Author: MORIOKA Tomohiko <morioka@jaist.ac.jp>
;; Created: 1994/7/13
;;	Renamed: 1994/8/31 from tm-body.el
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
(require 'mime-text)


;;; @ version
;;;

(defconst mime-view-version-string
  `,(concat "SEMI MIME-View "
	    (mapconcat #'number-to-string (cdr semi-version) ".")
	    " (" (car semi-version) ")"))


;;; @ variables
;;;

(defvar mime-acting-condition
  '(((type . text)(subtype . plain)
     (method "tm-plain" nil 'file "" 'encoding 'mode 'name)
     (mode "play" "print")
     )
    ((type . text)(subtype . html)
     (method "tm-html" nil 'file "" 'encoding 'mode 'name)
     (mode . "play")
     )
    ((type . text)(subtype . x-rot13-47)
     (method . mime-method-to-display-caesar)
     (mode . "play")
     )
    ((type . text)(subtype . x-rot13-47-48)
     (method . mime-method-to-display-caesar)
     (mode . "play")
     )

    ((type . audio)(subtype . basic)
     (method "tm-au"    nil 'file "" 'encoding 'mode 'name)
     (mode . "play")
     )
    
    ((type . image)
     (method "tm-image" nil 'file "" 'encoding 'mode 'name)
     (mode "play" "print")
     )
    
    ((type . video)(subtype . mpeg)
     (method "tm-mpeg"  nil 'file "" 'encoding 'mode 'name)
     (mode . "play")
     )
    
    ((type . application)(subtype . postscript)
     (method "tm-ps" nil 'file "" 'encoding 'mode 'name)
     (mode "play" "print")
     )
    ((type . application)(subtype . octet-stream)
     (method . mime-method-to-save)(mode "play" "print")
     )

    ((type . message)(subtype . external-body)
     ("access-type" . "anon-ftp")
     (method . mime-method-to-display-message/external-ftp)
     )
    ((type . message)(subtype . rfc822)
     (method . mime-method-to-display-message/rfc822)
     (mode . "play")
     )
    ((type . message)(subtype . partial)
     (method . mime-method-to-store-message/partial)
     (mode . "play")
     )
    
    ((method "metamail" t "-m" "tm" "-x" "-d" "-z" "-e" 'file)
     (mode . "play")
     )
    ((method . mime-method-to-save)(mode . "extract"))
    ))

(defvar mime-view-childrens-header-showing-Content-Type-list
  '("message/rfc822" "message/news"))

(defvar mime-view-visible-media-type-list
  '("text/plain" nil "text/richtext" "text/enriched"
    "text/rfc822-headers"
    "text/x-latex" "application/x-latex"
    "message/delivery-status"
    "application/pgp" "text/x-pgp"
    "application/octet-stream"
    "application/x-selection" "application/x-comment")
  "*List of media-types to be able to display in MIME-View buffer.
Each elements are string of TYPE/SUBTYPE, e.g. \"text/plain\".")

(defvar mime-view-content-button-visible-ctype-list
  '("application/pgp"))

(defvar mime-view-uuencode-encoding-name-list '("x-uue" "x-uuencode"))

(defvar mime-view-ignored-field-list
  '(".*Received" ".*Path" ".*Id" "References"
    "Replied" "Errors-To"
    "Lines" "Sender" ".*Host" "Xref"
    "Content-Type" "Precedence"
    "Status" "X-VM-.*")
  "All fields that match this list will be hidden in MIME preview buffer.
Each elements are regexp of field-name. [mime-view.el]")

(defvar mime-view-ignored-field-regexp
  (concat "^"
	  (apply (function regexp-or) mime-view-ignored-field-list)
	  ":"))

(defvar mime-view-visible-field-list '("Dnas.*" "Message-Id")
  "All fields that match this list will be displayed in MIME preview buffer.
Each elements are regexp of field-name.")

(defvar mime-view-redisplay nil)

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


;;; @@ entity button
;;;

(defun mime-view-insert-entity-button (rcnum cinfo
					     media-type media-subtype params
					     subj encoding)
  "Insert entity-button."
  (mime-insert-button
   (let ((access-type (assoc "access-type" params))
	 (num (or (cdr (assoc "x-part-number" params))
		  (if (consp rcnum)
		      (mapconcat (function
				  (lambda (num)
				    (format "%s" (1+ num))
				    ))
				 (reverse rcnum) ".")
		    "0"))
	      ))
     (cond (access-type
	    (let ((server (assoc "server" params)))
	      (setq access-type (cdr access-type))
	      (if server
		  (format "%s %s ([%s] %s)"
			  num subj access-type (cdr server))
		(let ((site (cdr (assoc "site" params)))
		      (dir (cdr (assoc "directory" params)))
		      )
		  (format "%s %s ([%s] %s:%s)"
			  num subj access-type site dir)
		  )))
	    )
	   (t
	    (let ((charset (cdr (assoc "charset" params))))
	      (concat
	       num " " subj
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
   (function mime-view-play-current-entity))
  )

(defun mime-view-entity-button-function (rcnum cinfo
					       media-type media-subtype
					       params subj encoding)
  "Insert entity button conditionally.
Please redefine this function if you want to change default setting."
  (or (null rcnum)
      (and (eq media-type 'application)
	   (or (eq media-subtype 'x-selection)
	       (and (eq media-subtype 'octet-stream)
		    (let ((entity-info
			   (mime-article/rcnum-to-cinfo (cdr rcnum) cinfo)))
		      (and (eq (mime-entity-info-media-type entity-info)
			       'multipart)
			   (eq (mime-entity-info-media-subtype entity-info)
			       'encrypted)
			   )))))
      (mime-view-insert-entity-button
       rcnum cinfo media-type media-subtype params subj encoding)
      ))


;;; @@ content header filter
;;;

(defun mime-view-cut-header ()
  (goto-char (point-min))
  (while (re-search-forward mime-view-ignored-field-regexp nil t)
    (let* ((beg (match-beginning 0))
	   (end (match-end 0))
	   (name (buffer-substring beg end))
	   )
      (catch 'visible
	(let ((rest mime-view-visible-field-list))
	  (while rest
	    (if (string-match (car rest) name)
		(throw 'visible nil)
	      )
	    (setq rest (cdr rest))))
	(delete-region beg
		       (save-excursion
			 (if (re-search-forward "^\\([^ \t]\\|$\\)" nil t)
			     (match-beginning 0)
			   (point-max))))
	))))

(defun mime-view-default-content-header-filter ()
  (mime-view-cut-header)
  (eword-decode-header)
  )

(defvar mime-view-content-header-filter-alist nil)


;;; @@ content filter
;;;

(defvar mime-view-content-filter-alist
  '(("text/enriched" . mime-view-filter-for-text/enriched)
    ("text/richtext" . mime-view-filter-for-text/richtext)
    (t . mime-view-filter-for-text/plain)
    )
  "Alist of media-types vs. corresponding MIME-View filter functions.
Each element looks like (TYPE/SUBTYPE . FUNCTION) or (t . FUNCTION).
TYPE/SUBTYPE is a string of media-type and FUNCTION is a filter
function.  t means default media-type.")


;;; @@ entity separator
;;;

(defun mime-view-entity-separator-function (rcnum cinfo
						  media-type media-subtype
						  params subj)
  "Insert entity separator conditionally.
Please redefine this function if you want to change default setting."
  (or (mime-view-header-visible-p rcnum cinfo)
      (mime-view-body-visible-p rcnum cinfo media-type media-subtype)
      (progn
	(goto-char (point-max))
	(insert "\n")
	)))


;;; @@ buffer local variables
;;;

;;; @@@ in raw buffer
;;;

(defvar mime-raw-content-info
  "Information about structure of message.
Please use reference function `mime::content-info/SLOT-NAME' to
reference slot of content-info.  Their argument is only content-info.

Following is a list of slots of the structure:

rcnum		reversed content-number (list)
point-min	beginning point of region in raw-buffer
point-max	end point of region in raw-buffer
type		media-type/subtype (string or nil)
parameters	parameter of Content-Type field (association list)
encoding	Content-Transfer-Encoding (string or nil)
children	entities included in this entity (list of content-infos)

If a entity includes other entities in its body, such as multipart or
message/rfc822, content-infos of other entities are included in
`children', so content-info become a tree.")
(make-variable-buffer-local 'mime-raw-content-info)

(defvar mime-view-buffer nil
  "MIME View buffer corresponding with the (raw) buffer.")
(make-variable-buffer-local 'mime-view-buffer)


;;; @@@ in view buffer
;;;

(defvar mime-mother-buffer nil
  "Mother buffer corresponding with the (MIME-View) buffer.
If current MIME-View buffer is generated by other buffer, such as
message/partial, it is called `mother-buffer'.")
(make-variable-buffer-local 'mime-mother-buffer)

(defvar mime-raw-buffer nil
  "Raw buffer corresponding with the (MIME-View) buffer.")
(make-variable-buffer-local 'mime-raw-buffer)

(defvar mime-view-original-major-mode nil
  "Major-mode in mime-raw-buffer.")
(make-variable-buffer-local 'mime-view-original-major-mode)

(make-variable-buffer-local 'mime::preview/original-window-configuration)


;;; @@ quitting method
;;;

(defvar mime-view-quitting-method-alist
  '((mime-show-message-mode
     . mime-view-quitting-method-for-mime-show-message-mode))
  "Alist of major-mode vs. quitting-method of mime-view.")

(defvar mime-view-over-to-previous-method-alist nil)
(defvar mime-view-over-to-next-method-alist nil)

(defvar mime-view-show-summary-method nil
  "Alist of major-mode vs. show-summary-method.")


;;; @@ following method
;;;

(defvar mime-view-following-method-alist nil
  "Alist of major-mode vs. following-method of mime-view.")

(defvar mime-view-following-required-fields-list
  '("From"))


;;; @@ X-Face
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

(defun mime-view-setup-buffers (&optional ctl encoding ibuf obuf)
  (if ibuf
      (progn
	(get-buffer ibuf)
	(set-buffer ibuf)
	))
  (or mime-view-redisplay
      (setq mime-raw-content-info (mime-parse-message ctl encoding))
      )
  (let* ((cinfo mime-raw-content-info)
	 (pcl (mime/flatten-content-info cinfo))
	 (the-buf (current-buffer))
	 (mode major-mode)
	 )
    (or obuf
	(setq obuf (concat "*Preview-" (buffer-name the-buf) "*")))
    (set-buffer (get-buffer-create obuf))
    (let ((inhibit-read-only t))
      ;;(setq buffer-read-only nil)
      (widen)
      (erase-buffer)
      (setq mime-raw-buffer the-buf)
      (setq mime-view-original-major-mode mode)
      (setq major-mode 'mime-view-mode)
      (setq mode-name "MIME-View")
      (while pcl
	(mime-view-display-entity (car pcl) cinfo the-buf obuf)
	(setq pcl (cdr pcl))
	)
      (set-buffer-modified-p nil)
      )
    (setq buffer-read-only t)
    (set-buffer the-buf)
    )
  (setq mime-view-buffer obuf)
  )

(defun mime-view-display-entity (content cinfo ibuf obuf)
  "Display entity from content-info CONTENT."
  (let* ((beg (mime-entity-info-point-min content))
	 (end (mime-entity-info-point-max content))
	 (media-type (mime-entity-info-media-type content))
	 (media-subtype (mime-entity-info-media-subtype content))
	 (ctype (if media-type
		    (if media-subtype
			(format "%s/%s" media-type media-subtype)
		      (symbol-name media-type)
		      )))
	 (params (mime-entity-info-parameters content))
	 (encoding (mime-entity-info-encoding content))
	 (rcnum (mime-entity-info-rnum content))
	 he e nb ne subj)
    (set-buffer ibuf)
    (goto-char beg)
    (setq he (if (re-search-forward "^$" nil t)
		 (1+ (match-end 0))
	       end))
    (if (> he end)
	(setq he end)
      )
    (save-restriction
      (narrow-to-region beg end)
      (setq subj
	    (eword-decode-string
	     (mime-article/get-subject params encoding)))
      )
    (set-buffer obuf)
    (setq nb (point))
    (narrow-to-region nb nb)
    (mime-view-entity-button-function
     rcnum cinfo media-type media-subtype params subj encoding)
    (if (mime-view-header-visible-p rcnum cinfo)
	(mime-view-display-header beg he)
      )
    (if (and (null rcnum)
	     (member
	      ctype mime-view-content-button-visible-ctype-list))
	(save-excursion
	  (goto-char (point-max))
	  (mime-view-insert-entity-button
	   rcnum cinfo media-type media-subtype params subj encoding)
	  ))
    (cond ((mime-view-body-visible-p rcnum cinfo media-type media-subtype)
	   (mime-view-display-body he end
				      rcnum cinfo ctype params subj encoding)
	   )
	  ((and (eq media-type 'message)(eq media-subtype 'partial))
	   (mime-view-insert-message/partial-button)
	   )
	  ((and (null rcnum)
		(null (mime-entity-info-children cinfo))
		)
	   (goto-char (point-max))
	   (mime-view-insert-entity-button
	    rcnum cinfo media-type media-subtype params subj encoding)
	   ))
    (mime-view-entity-separator-function
     rcnum cinfo media-type media-subtype params subj)
    (setq ne (point-max))
    (widen)
    (put-text-property nb ne 'mime-view-raw-buffer ibuf)
    (put-text-property nb ne 'mime-view-cinfo content)
    (goto-char ne)
    ))

(defun mime-view-display-header (beg end)
  (save-restriction
    (narrow-to-region (point)(point))
    (insert-buffer-substring mime-raw-buffer beg end)
    (let ((f (cdr (assq mime-view-original-major-mode
			mime-view-content-header-filter-alist))))
      (if (functionp f)
	  (funcall f)
	(mime-view-default-content-header-filter)
	))
    (run-hooks 'mime-view-content-header-filter-hook)
    ))

(defun mime-view-display-body (beg end rcnum cinfo ctype params subj encoding)
  (save-restriction
    (narrow-to-region (point-max)(point-max))
    (insert-buffer-substring mime-raw-buffer beg end)
    (let ((f (cdr (or (assoc ctype mime-view-content-filter-alist)
		      (assq t mime-view-content-filter-alist)))))
      (and (functionp f)
	   (funcall f ctype params encoding)
	   )
      )))

(defun mime-view-insert-message/partial-button ()
  (save-restriction
    (goto-char (point-max))
    (if (not (search-backward "\n\n" nil t))
	(insert "\n")
      )
    (goto-char (point-max))
    (narrow-to-region (point-max)(point-max))
    (insert mime-view-announcement-for-message/partial)
    (mime-add-button (point-min)(point-max)
		     (function mime-view-play-current-entity))
    ))

(defun mime-article/get-uu-filename (param &optional encoding)
  (if (member (or encoding
		  (cdr (assq 'encoding param))
		  )
	      mime-view-uuencode-encoding-name-list)
      (save-excursion
	(or (if (re-search-forward "^begin [0-9]+ " nil t)
		(if (looking-at ".+$")
		    (buffer-substring (match-beginning 0)(match-end 0))
		  ))
	    ""))
    ))

(defun mime-article/get-subject (param &optional encoding)
  (or (std11-find-field-body '("Content-Description" "Subject"))
      (let (ret)
	(if (or (and (setq ret (mime/Content-Disposition))
		     (setq ret (assoc "filename" (cdr ret)))
		     )
		(setq ret (assoc "name" param))
		(setq ret (assoc "x-name" param))
		)
	    (std11-strip-quoted-string (cdr ret))
	  ))
      (mime-article/get-uu-filename param encoding)
      ""))


;;; @ entity information
;;;

(defun mime-article/point-content-number (p &optional cinfo)
  (or cinfo
      (setq cinfo mime-raw-content-info)
      )
  (let ((b (mime-entity-info-point-min cinfo))
	(e (mime-entity-info-point-max cinfo))
	(c (mime-entity-info-children cinfo))
	)
    (if (and (<= b p)(<= p e))
	(or (let (co ret (sn 0))
	      (catch 'tag
		(while c
		  (setq co (car c))
		  (setq ret (mime-article/point-content-number p co))
		  (cond ((eq ret t) (throw 'tag (list sn)))
			(ret (throw 'tag (cons sn ret)))
			)
		  (setq c (cdr c))
		  (setq sn (1+ sn))
		  )))
	    t))))

(defsubst mime-article/rcnum-to-cinfo (rnum &optional cinfo)
  (mime-article/cnum-to-cinfo (reverse rnum) cinfo)
  )

(defun mime-article/cnum-to-cinfo (cn &optional cinfo)
  (or cinfo
      (setq cinfo mime-raw-content-info)
      )
  (if (eq cn t)
      cinfo
    (let ((sn (car cn)))
      (if (null sn)
	  cinfo
	(let ((rc (nth sn (mime-entity-info-children cinfo))))
	  (if rc
	      (mime-article/cnum-to-cinfo (cdr cn) rc)
	    ))
	))))

(defun mime/flatten-content-info (&optional cinfo)
  (or cinfo
      (setq cinfo mime-raw-content-info)
      )
  (let ((dest (list cinfo))
	(rcl (mime-entity-info-children cinfo))
	)
    (while rcl
      (setq dest (nconc dest (mime/flatten-content-info (car rcl))))
      (setq rcl (cdr rcl))
      )
    dest))


;;; @@ predicate functions
;;;

(defun mime-view-header-visible-p (rcnum cinfo)
  "Return non-nil if header of current entity is visible."
  (or (null rcnum)
      (member (mime-entity-info-type/subtype
	       (mime-article/rcnum-to-cinfo (cdr rcnum) cinfo))
	      mime-view-childrens-header-showing-Content-Type-list)
      ))

(defun mime-view-body-visible-p (rcnum cinfo media-type media-subtype)
  (let ((ctype (if media-type
		   (if media-subtype
		       (format "%s/%s" media-type media-subtype)
		     (symbol-name media-type)
		     ))))
    (and (member ctype mime-view-visible-media-type-list)
	 (if (and (eq media-type 'application)
		  (eq media-subtype 'octet-stream))
	     (let ((ccinfo (mime-article/rcnum-to-cinfo rcnum cinfo)))
	       (member (mime-entity-info-encoding ccinfo)
		       '(nil "7bit" "8bit"))
	       )
	   t))
    ))


;;; @ MIME viewer mode
;;;

(defconst mime-view-menu-title "MIME-View")
(defconst mime-view-menu-list
  '((up		 "Move to upper content"      mime-view-move-to-upper)
    (previous	 "Move to previous content"   mime-view-move-to-previous)
    (next	 "Move to next content"	      mime-view-move-to-next)
    (scroll-down "Scroll to previous content" mime-view-scroll-down-entity)
    (scroll-up	 "Scroll to next content"     mime-view-scroll-up-entity)
    (play	 "Play Content"               mime-view-play-current-entity)
    (extract	 "Extract Content"            mime-view-extract-current-entity)
    (print	 "Print"                      mime-view-print-current-entity)
    (x-face	 "Show X Face"                mime-view-display-x-face)
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
      "u"        (function mime-view-move-to-upper))
    (define-key mime-view-mode-map
      "p"        (function mime-view-move-to-previous))
    (define-key mime-view-mode-map
      "n"        (function mime-view-move-to-next))
    (define-key mime-view-mode-map
      "\e\t"     (function mime-view-move-to-previous))
    (define-key mime-view-mode-map
      "\t"       (function mime-view-move-to-next))
    (define-key mime-view-mode-map
      " "        (function mime-view-scroll-up-entity))
    (define-key mime-view-mode-map
      "\M- "     (function mime-view-scroll-down-entity))
    (define-key mime-view-mode-map
      "\177"     (function mime-view-scroll-down-entity))
    (define-key mime-view-mode-map
      "\C-m"     (function mime-view-next-line-content))
    (define-key mime-view-mode-map
      "\C-\M-m"  (function mime-view-previous-line-content))
    (define-key mime-view-mode-map
      "v"        (function mime-view-play-current-entity))
    (define-key mime-view-mode-map
      "e"        (function mime-view-extract-current-entity))
    (define-key mime-view-mode-map
      "\C-c\C-p" (function mime-view-print-current-entity))
    (define-key mime-view-mode-map
      "a"        (function mime-view-follow-current-entity))
    (define-key mime-view-mode-map
      "q"        (function mime-view-quit))
    (define-key mime-view-mode-map
      "h"        (function mime-view-show-summary))
    (define-key mime-view-mode-map
      "\C-c\C-x" (function mime-view-kill-buffer))
    ;; (define-key mime-view-mode-map
    ;;   "<"        (function beginning-of-buffer))
    ;; (define-key mime-view-mode-map
    ;;   ">"        (function end-of-buffer))
    (define-key mime-view-mode-map
      "?"        (function describe-mode))
    (define-key mime-view-mode-map
      [tab] (function mime-view-move-to-next))
    (define-key mime-view-mode-map
      [delete] (function mime-view-scroll-down-entity))
    (define-key mime-view-mode-map
      [backspace] (function mime-view-scroll-down-entity))
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

(defun mime-view-mode (&optional mother ctl encoding ibuf obuf
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
x		Display X-Face
q		Quit
button-2	Move to point under the mouse cursor
        	and decode current content as `play mode'
"
  (interactive)
  (mime-maybe-hide-echo-buffer)
  (let ((ret (mime-view-setup-buffers ctl encoding ibuf obuf))
	(win-conf (current-window-configuration))
	)
    (prog1
	(switch-to-buffer ret)
      (setq mime::preview/original-window-configuration win-conf)
      (if mother
	  (progn
	    (setq mime-mother-buffer mother)
	    ))
      (mime-view-define-keymap default-keymap-or-function)
      (let ((point (next-single-property-change (point-min) 'mime-view-cinfo)))
	(if point
	    (goto-char point)
	  (goto-char (point-min))
	  (search-forward "\n\n" nil t)
	  ))
      (run-hooks 'mime-view-mode-hook)
      )))


;;; @@ playing
;;;

(autoload 'mime-view-play-current-entity "mime-play" "Play current entity." t)

(defun mime-view-extract-current-entity ()
  "Extract current entity into file (maybe).
It decodes current entity to call internal or external method as
\"extract\" mode.  The method is selected from variable
`mime-acting-condition'."
  (interactive)
  (mime-view-play-current-entity "extract")
  )

(defun mime-view-print-current-entity ()
  "Print current entity (maybe).
It decodes current entity to call internal or external method as
\"print\" mode.  The method is selected from variable
`mime-acting-condition'."
  (interactive)
  (mime-view-play-current-entity "print")
  )


;;; @@ following
;;;

(defun mime-view-get-original-major-mode ()
  "Return major-mode of original buffer.
If a current buffer has mime-mother-buffer, return original major-mode
of the mother-buffer."
  (if mime-mother-buffer
      (save-excursion
	(set-buffer mime-mother-buffer)
	(mime-view-get-original-major-mode)
	)
    mime-view-original-major-mode))

(defun mime-view-follow-current-entity ()
  "Write follow message to current entity.
It calls following-method selected from variable
`mime-view-following-method-alist'."
  (interactive)
  (let ((root-cinfo (get-text-property (point-min) 'mime-view-cinfo))
	cinfo)
    (while (null (setq cinfo (get-text-property (point) 'mime-view-cinfo)))
      (backward-char)
      )
    (let* ((p-beg (previous-single-property-change (point) 'mime-view-cinfo))
	   p-end
	   (rcnum (mime-entity-info-rnum cinfo))
	   (len (length rcnum))
	   )
      (cond ((null p-beg)
	     (setq p-beg
		   (if (eq (next-single-property-change (point-min)
							'mime-view-cinfo)
			   (point))
		       (point)
		     (point-min)))
	     )
	    ((eq (next-single-property-change p-beg 'mime-view-cinfo)
		 (point))
	     (setq p-beg (point))
	     ))
      (setq p-end (next-single-property-change p-beg 'mime-view-cinfo))
      (cond ((null p-end)
	     (setq p-end (point-max))
	     )
	    ((null rcnum)
	     (setq p-end (point-max))
	     )
	    (t
	     (save-excursion
	       (goto-char p-end)
	       (catch 'tag
		 (let (e)
		   (while (setq e
				(next-single-property-change
				 (point) 'mime-view-cinfo))
		     (goto-char e)
		     (let ((rc (mime-entity-info-rnum
				(get-text-property (point)
						   'mime-view-cinfo))))
		       (or (equal rcnum (nthcdr (- (length rc) len) rc))
			   (throw 'tag nil)
			   ))
		     (setq p-end e)
		     ))
		 (setq p-end (point-max))
		 ))
	     ))
      (let* ((mode (mime-view-get-original-major-mode))
	     (new-name (format "%s-%s" (buffer-name) (reverse rcnum)))
	     new-buf
	     (the-buf (current-buffer))
	     (a-buf mime-raw-buffer)
	     fields)
	(save-excursion
	  (set-buffer (setq new-buf (get-buffer-create new-name)))
	  (erase-buffer)
	  (insert-buffer-substring the-buf p-beg p-end)
	  (goto-char (point-min))
	  (if (mime-view-header-visible-p rcnum root-cinfo)
	      (delete-region (goto-char (point-min))
			     (if (re-search-forward "^$" nil t)
				 (match-end 0)
			       (point-min)))
	    )
	  (goto-char (point-min))
	  (insert "\n")
	  (goto-char (point-min))
	  (let ((rcnum (mime-entity-info-rnum cinfo)) ci str)
	    (while (progn
		     (setq str
			   (save-excursion
			     (set-buffer a-buf)
			     (setq ci (mime-article/rcnum-to-cinfo rcnum))
			     (save-restriction
			       (narrow-to-region
				(mime-entity-info-point-min ci)
				(mime-entity-info-point-max ci)
				)
			       (std11-header-string-except
				(concat "^"
					(apply (function regexp-or) fields)
					":") ""))))
		     (if (and
			  (eq (mime-entity-info-media-type ci) 'message)
			  (eq (mime-entity-info-media-subtype ci) 'rfc822))
			 nil
		       (if str
			   (insert str)
			 )
		       rcnum))
	      (setq fields (std11-collect-field-names)
		    rcnum (cdr rcnum))
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

(defun mime-view-display-x-face ()
  (interactive)
  (save-window-excursion
    (set-buffer mime-raw-buffer)
    (mime-view-x-face-function)
    ))


;;; @@ moving
;;;

(defun mime-view-move-to-upper ()
  "Move to upper entity.
If there is no upper entity, call function `mime-view-quit'."
  (interactive)
  (let (cinfo)
    (while (null (setq cinfo (get-text-property (point) 'mime-view-cinfo)))
      (backward-char)
      )
    (let ((r (mime-article/rcnum-to-cinfo
	      (cdr (mime-entity-info-rnum cinfo))
	      (get-text-property 1 'mime-view-cinfo)))
	  point)
      (catch 'tag
	(while (setq point (previous-single-property-change
			    (point) 'mime-view-cinfo))
	  (goto-char point)
	  (if (eq r (get-text-property (point) 'mime-view-cinfo))
	      (throw 'tag t)
	    )
	  )
	(mime-view-quit)
	))))

(defun mime-view-move-to-previous ()
  "Move to previous entity.
If there is no previous entity, it calls function registered in
variable `mime-view-over-to-previous-method-alist'."
  (interactive)
  (while (null (get-text-property (point) 'mime-view-cinfo))
    (backward-char)
    )
  (let ((point (previous-single-property-change (point) 'mime-view-cinfo)))
    (if point
	(goto-char point)
      (let ((f (assq mime-view-original-major-mode
		     mime-view-over-to-previous-method-alist)))
	(if f
	    (funcall (cdr f))
	  ))
      )))

(defun mime-view-move-to-next ()
  "Move to next entity.
If there is no previous entity, it calls function registered in
variable `mime-view-over-to-next-method-alist'."
  (interactive)
  (let ((point (next-single-property-change (point) 'mime-view-cinfo)))
    (if point
	(goto-char point)
      (let ((f (assq mime-view-original-major-mode
		     mime-view-over-to-next-method-alist)))
	(if f
	    (funcall (cdr f))
	  ))
      )))

(defun mime-view-scroll-up-entity (&optional h)
  "Scroll up current entity.
If reached to (point-max), it calls function registered in variable
`mime-view-over-to-next-method-alist'."
  (interactive)
  (or h
      (setq h (1- (window-height)))
      )
  (if (= (point) (point-max))
      (let ((f (assq mime-view-original-major-mode
                     mime-view-over-to-next-method-alist)))
        (if f
            (funcall (cdr f))
          ))
    (let ((point
	   (or (next-single-property-change (point) 'mime-view-cinfo)
	       (point-max))))
      (forward-line h)
      (if (> (point) point)
          (goto-char point)
        )
      )))

(defun mime-view-scroll-down-entity (&optional h)
  "Scroll down current entity.
If reached to (point-min), it calls function registered in variable
`mime-view-over-to-previous-method-alist'."
  (interactive)
  (or h
      (setq h (1- (window-height)))
      )
  (if (= (point) (point-min))
      (let ((f (assq mime-view-original-major-mode
                     mime-view-over-to-previous-method-alist)))
        (if f
            (funcall (cdr f))
          ))
    (let (point)
      (save-excursion
	(catch 'tag
	  (while (> (point) 1)
	    (if (setq point
		      (previous-single-property-change (point)
						       'mime-view-cinfo))
		(throw 'tag t)
	      )
	    (backward-char)
	    )
	  (setq point (point-min))
	  ))
      (forward-line (- h))
      (if (< (point) point)
          (goto-char point)
        ))))

(defun mime-view-next-line-content ()
  (interactive)
  (mime-view-scroll-up-entity 1)
  )

(defun mime-view-previous-line-content ()
  (interactive)
  (mime-view-scroll-down-entity 1)
  )


;;; @@ quitting
;;;

(defun mime-view-quit ()
  "Quit from MIME-View buffer.
It calls function registered in variable
`mime-view-quitting-method-alist'."
  (interactive)
  (let ((r (assq mime-view-original-major-mode
		 mime-view-quitting-method-alist)))
    (if r
	(funcall (cdr r))
      )))

(defun mime-view-show-summary ()
  "Show summary.
It calls function registered in variable
`mime-view-show-summary-method'."
  (interactive)
  (let ((r (assq mime-view-original-major-mode
		 mime-view-show-summary-method)))
    (if r
	(funcall (cdr r))
      )))

(defun mime-view-kill-buffer ()
  (interactive)
  (kill-buffer (current-buffer))
  )


;;; @ end
;;;

(provide 'mime-view)

(run-hooks 'mime-view-load-hook)

;;; mime-view.el ends here
