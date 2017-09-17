;;;; package.lisp

(defpackage #:lisppi-mouse
  (:nicknames :mouse) 
  (:shadow :open :close)
  (:use #:cffi #:cl)


  


  (:export
   :open :close :handle-events) 
  )



