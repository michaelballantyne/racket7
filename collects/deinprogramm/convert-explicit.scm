;; I HATE DEFINE-STRUCT!
(define-struct/properties :empty-list ()
  ((prop:custom-write
    (lambda (r port write?)
      (write-string "#<empty-list>" port))))
  (make-inspector))

(define the-empty-list (make-:empty-list))

;; essentially copied from define-record-procedures.scm
(define (write-list l port write?)
  (let ((pp? (and (pretty-printing)
		  (number? (pretty-print-columns)))))

    (write-string "#<" port)
    (write-string "list" port)

    (let-values (((ref-line ref-column ref-pos)
		  (if pp?
		      (port-next-location port)
		      (values 0 -1 0)))) ; to compensate for space
      (let ((do-element
	     (if pp?
		 (lambda (element)
		   (let* ((max-column (- (pretty-print-columns) 1)) ; > terminator
			  (tentative
			   (make-tentative-pretty-print-output-port
			    port
			    max-column
			    void)))
		     (display " " tentative)
		     ((if write? write display) element tentative)
		     (let-values (((line column pos) (port-next-location tentative)))
		       (if (< column max-column)
			   (tentative-pretty-print-port-transfer tentative port)
			   (begin
			     (tentative-pretty-print-port-cancel tentative)
			     (let ((count (pretty-print-newline port max-column)))
			       (write-string (make-string (max 0 (- (+ ref-column 1) count)) #\space) 
					     port)
			       ((if write? write display) element port)))))))
		 (lambda (element)
		   (display " " port)
		   ((if write? write display) element port)))))
	(let loop ((elements (:list-elements l)))
	  (cond
	   ((pair? elements)
	    (do-element (car elements))
	    (loop (cdr elements)))
	   ((not (null? elements))
	    (write-string " ." port)
	    (do-element elements))))))
      
    (write-string ">" port)))

;; might be improper
(define-struct/properties :list (elements)
  ((prop:custom-write write-list))
  (make-inspector))

;; doesn't handle cycles
(define (convert-explicit v)
  (cond
   ((null? v) the-empty-list)
   ((pair? v)				; need to check for sharing
    (make-:list
     (let recur ((v v))
       (cond
	((null? v)
	 v)
	((not (pair? v))
	 (convert-explicit v))
	(else
	 (cons (convert-explicit (car v))
	       (recur (cdr v))))))))
   ((deinprogramm-struct? v)
    (let*-values (((ty skipped?) (struct-info v))
		  ((name-symbol
		    init-field-k auto-field-k accessor-proc mutator-proc immutable-k-list
		    super-struct-type skipped?)
		   (struct-type-info ty)))
      (apply (struct-type-make-constructor ty)
	     (map convert-explicit
		  (map (lambda (index)
			 (accessor-proc v index))
		       (iota (+ init-field-k auto-field-k)))))))
   (else
    v)))

