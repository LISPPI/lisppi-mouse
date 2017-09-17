;;
;;
(asdf:defsystem #:lisppi-mouse
  :description "set me!"
  :author "StackSmith <fpgasm@apple2.x10.mx>"
  :license "BSD 3-clause license"
  :serial t
  :depends-on (:cffi)
  :components ((:file "package")
	       (:file "lisppi-mouse")))

