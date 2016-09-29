(define-module (compan)
  #:use-module (ice-9 regex)
  #:use-module (srfi srfi-1)
  #:export (load-modules clone-repository repository-cloned?))

(define (unix-environment-value name)
  (cond ((find (lambda (name=value)
		 (string-prefix? name name=value))
	       (environ))
	 => (lambda (name=value)
	      (substring name=value (+ (string-length name)
				       (string-length "=")))))
	(else #f)))

(define HOME-DIRECTORY (unix-environment-value "HOME"))

(define-syntax-rule (with-directory directory actions ...)
  (let ((original-directory (getcwd)))
    (dynamic-wind
      (lambda () (chdir #;to directory))
      (lambda () actions ...)
      (lambda () (chdir #;to original-directory)))))

(define (exec . command+args)
  (system (apply string-append command+args)))

(define (path-join . args)
  (string-join args file-name-separator-string))

(define COMPAN-DIRECTORY (path-join HOME-DIRECTORY ".guile.d" "compan"))

(define (load-path url . subdirectory*)
  ;; TODO: on windows platforms we'd need to convert slashes
  ;; to file-name-separator-string. On the other hand, we'd need
  ;; a windows platform to test 
  (cond ((string-match "^[^:]*://*(.*)$" url)
	 => (lambda (ms)
	      (let* ((directory (match:substring ms 1))
		     (full-path (apply path-join COMPAN-DIRECTORY
				       directory subdirectory*)))
		(cond ((string-match "^(.*)\\.git$" full-path)
		       => (lambda (ms) (match:substring ms 1)))
		      (else
		       full-path)))))
	(else
	 (throw 'invalid-url url))))

(define (repository-cloned? url)
  (file-exists? (load-path url)))

(define (clone-repository url)
  (let ((path (load-path url)))
    (exec "mkdir -p "path)
    (with-directory path
     (chdir "..")
     (exec "hg clone "url))))

(define-syntax import-modules
  (syntax-rules ()
    ((_ (url directory branch) modules ...)
     (begin
       (unless (repository-cloned? url)
	 (clone-repository url))

       (with-directory (load-path url)
	(exec "hg update "branch))

       (add-to-load-path (load-path url directory))
       (use-modules modules ...)))

    ((_ (url directory) modules ...)
     (begin
       (unless (repository-cloned? url)
	 (clone-repository url))
       (add-to-load-path (load-path url directory))
       (use-modules modules ...)))

    ((_ (url) modules ...)
     (import-modules (url ".") modules ...))

    ((_ url modules ...)
     (import-modules (url) modules ...))))

(define-syntax update-repository
  (syntax-rules ()
    ((_ (url . _))
     (with-directory (load-path url)
      (exec "hg pull -u")))
    
    ((_ url)
     (update-repository (url)))))

(define-syntax-rule (load-modules (url+directory?+branch? modules ...) ...)
  (begin
    (import-modules url+directory?+branch? modules ...)
    ...
    (call-with-new-thread
     (lambda ()
       (begin (update-repository url+directory?+branch?) ...)))
    ))
