(in-package #:lisppi-mouse)
;;==============================================================================
;;
;; Mouse interface for raspberry pi using evdev
;;
#||
struct timeval {
	__kernel_time_t		tv_sec;		/* seconds */
	__kernel_suseconds_t	tv_usec;	/* microseconds */
};

struct input_event {
	struct timeval time;
	__u16 type;
	__u16 code;
	__s32 value;
}
(defcstruct event
  (sec :uint)
  (usec :uint)
  (type :uint16)
  (code :uint16)
  (value :uint32))

;#define EV_SYN			0x00
#define EV_KEY			0x01
#define EV_REL			0x02
#define EV_ABS			0x03
#define EV_MSC			0x04
#define EV_SW			0x05
#define EV_LED			0x11
#define EV_SND			0x12
#define EV_REP			0x14
#define EV_FF			0x15
#define EV_PWR			0x16
#define EV_FF_STATUS		0x17
#define EV_MAX			0x1f
#define EV_CNT			(EV_MAX+1)


||#
;; foreign event buffer
(defparameter *buffer* nil)
;; file handle
(defparameter *file* nil)
;;==============================================================================
;; Low-level linux file access
;;
(defcfun ("close" %close) :int
  (fd :int))

(defcfun ("read" %read) :int
  (fd :int)
  (buf :pointer)
  (size :int))

(defcfun ("open" %open) :int
  (filename :string)
  (mode :uint))
;;==============================================================================
;;
;; Accessing the event file
;;
(defun close ()
  (%close *file*)
  (foreign-free *buffer*))

(defun ev-read ()
  (%read *file* *buffer* 16))

(defun open ()
  (setf *buffer* (foreign-alloc :uint :count 4))
  (setf *file* (%open "/dev/input/event0" #x800)))

;; For now, just store results in globals.
(defparameter *mouse-x* 0)
(defparameter *mouse-y* 0)
(defparameter *mouse-wheel* 180)

(defparameter *mouse-left* 0)
(defparameter *mouse-middle* 0)
(defparameter *mouse-right* 0)

;;==============================================================================
;; A primitive to update mouse x,y and wheel, and range-check.
;; nil means don't update.
(defun mouse-update (x y wheel)
  (when x
    (incf *mouse-x* x)
    (when (< 1920 *mouse-x*)   (setf *mouse-x* 1920))
    (when (> 0 *mouse-x*)      (setf *mouse-x* 0)))
  (when y
    (decf *mouse-y* y)
    (when (< 1080 *mouse-y*)    (setf *mouse-y* 1080))
    (when (> 0 *mouse-y*)       (setf *mouse-y* 0)))
  (when wheel
    (incf *mouse-wheel* (* 2 wheel))
    (when (< 360 *mouse-wheel*)      (setf *mouse-wheel* 360))
    (when (> 0 *mouse-wheel*)        (setf *mouse-wheel* 0)))
  ;; actually move the screen mouse!
;
  )

;;(mouse-pointer-move *mouse-x* *mouse-y*);


;;==============================================================================
;; Check form mouse evdev events, and process any outstanding events.
;; Return nil if no mouse events pending or t if processed.  Results are
;; in mouse globals.
;;
(defun mouse-maybe-event ()
  (let ((result (ev-read)))       
    (if (= -1 result)
	nil
      (let ((type (mem-ref *buffer* :uint16 8))
	    (code (mem-ref *buffer* :uint16 10))
	    (value (mem-ref *buffer* :int 12)))
	;; (format t "   ~A ~A~&" code value)
	;;   (format t "ev: ~A~&" (mem-ref *q* :uint16 8))
	(case type
	  (0);;SYN
	  (1 (format t "press ~A ~A~&"code value) (force-output)
	     (case code
	       (272 (setf *mouse-left* value))	; BTN_LEFT
	       (273 (setf *mouse-right* value))
	       (274 (setf *mouse-middle* value))))
	  (2 (case code ;;rel      x      y       wheel
	       (0 (mouse-update value    nil      nil))
	       (1 (mouse-update   nil  value   nil))
	       (8 (mouse-update   nil   nil     value))
	       (t (format t "Unhandled rel ~A ~A~&" code value))))
	  (4); misc msg
					; BTN right
	  
	  
	  
	  ;;(0)
	  (t (format t "Unhandled message ~A ~A ~A~&"type code value)))
	t))))
;;==============================================================================
;; Process any outstanding events.  Call lambda with
;; x y wheel b1 b2 b3
(defun mouse-report (x y w l m r)
  (format t "~A ~A ~A ~A ~A ~A~&"x y w l m r))

(defun handle-events (fun)
  (loop
     while (mouse-maybe-event))
  (funcall fun *mouse-x* *mouse-y* *mouse-wheel*
	   *mouse-left* *mouse-middle* *mouse-right*))


;; A thread-suitable mouse task.
;; The handler passed to it will be called with up-to-date mouse info
;; x y wheel bl bm br) every timethere is a change.
;; Sleep the thread or call synced mouse draw afterwards.

(defparameter quit nil)
(defun mouse-loop (&optional (fun #'mouse-report))
  (setf quit nil)
  (open)
  (loop
     until quit
     do (handle-events fun))
  (close))


