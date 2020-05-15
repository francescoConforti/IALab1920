;  ---------------------------------------------
;  --- Definizione del modulo e dei template ---
;  ---------------------------------------------
(defmodule AGENT (import MAIN ?ALL) (import ENV ?ALL) (export ?ALL))

;assegna alle righe in cui non sono presenti navi, il contenuto water
(defrule row-empty (declare salience 50)
	(k-per-row  (num 0) (row ?x))
	=>
	(loop-for-count (?cnt1 0 10) do
		(assert (k-cell (x ?x) (y ?cnt1) (content water))))
)

;assegna alle colonne in cui non sono presenti navi, il contenuto water
(defrule column-empty (declare salience 50)
	(k-per-col (col ?y) (num 0))
	=>
	(loop-for-count (?cnt1 0 10) do
		(assert (k-cell (x ?cnt1) (y ?y) (content water))))
)

(defrule empty-around-sub (declare (salience 50))
  (k-cell (x ?x) (y ?y) (content sub))
  =>
  (assert (k-cell (x (+ ?x 1)) (y ?y) (content water)))
  (assert (k-cell (x (- ?x 1)) (y ?y) (content water)))
  (assert (k-cell (x ?x) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x ?x) (y (- ?y 1)) (content water)))
)

(defrule empty-around-top (declare (salience 50))
  (k-cell (x ?x) (y ?y) (content top))
  =>
  (assert (k-cell (x ?x) (y (- ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 1)) (y ?y) (content water)))
  (assert (k-cell (x (- ?x 1)) (y ?y) (content water)))
)

(defrule empty-around-bot (declare (salience 50))
  (k-cell (x ?x) (y ?y) (content bot))
  =>
  (assert (k-cell (x ?x) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 1)) (y ?y) (content water)))
  (assert (k-cell (x (- ?x 1)) (y ?y) (content water)))
)

(defrule empty-around-left (declare (salience 50))
  (k-cell (x ?x) (y ?y) (content left))
  =>
  (assert (k-cell (x ?x) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x ?x) (y (- ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y ?y) (content water)))
)

(defrule empty-around-right (declare (salience 50))
  (k-cell (x ?x) (y ?y) (content right))
  =>
  (assert (k-cell (x ?x) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x ?x) (y (- ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 1)) (y ?y) (content water)))
)

(defrule empty-around-middle-know-up-or-down (declare (salience 50))
  (k-cell (x ?x) (y ?y) (content middle))
  (k-cell (x ?x) (y ?yUpOrDown) (content ~water))
  (test (or (eq ?yUpOrDown (+ ?y 1)) (eq ?yUpOrDown (- ?y 1))))
  =>
  (assert (k-cell (x (+ ?x 1)) (y ?y) (content water)))
  (assert (k-cell (x (- ?x 1)) (y ?y) (content water)))
)

(defrule empty-around-middle-know-left-or-right (declare (salience 50))
  (k-cell (x ?x) (y ?y) (content middle))
  (k-cell (x ?xLeftOrRight) (y ?y) (content ~water))
  (test (or (eq ?xLeftOrRight (+ ?x 1)) (eq ?xLeftOrRight (- ?x 1))))
  =>
  (assert (k-cell (x ?x) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x ?x) (y (- ?y 1)) (content water)))
)

(defrule empty-around-middle-water-up-or-down (declare (salience 50)) ;; per il lato opposto
  (k-cell (x ?x) (y ?y) (content middle))
  (k-cell (x ?x) (y ?yUpOrDown) (content water))
  (test (or (eq ?yUpOrDown (+ ?y 1)) (eq ?yUpOrDown (- ?y 1))))
  =>
  (assert (k-cell (x ?x) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x ?x) (y (- ?y 1)) (content water)))
)

(defrule empty-around-middle-water-left-or-right (declare (salience 50)) ;; per il lato opposto
  (k-cell (x ?x) (y ?y) (content middle))
  (k-cell (x ?xLeftOrRight) (y ?y) (content water))
  (test (or (eq ?xLeftOrRight (+ ?x 1)) (eq ?xLeftOrRight (- ?x 1))))
  =>
  (assert (k-cell (x (+ ?x 1)) (y ?y) (content water)))
  (assert (k-cell (x (- ?x 1)) (y ?y) (content water)))
)

(defrule empty-around-middle-left-border (declare (salience 50))
  (k-cell (x 1) (y ?y) (content middle))
  =>
  (assert (k-cell (x 2) (y ?y) (content water)))
)

(defrule empty-around-middle-right-border (declare (salience 50))
  (k-cell (x 10) (y ?y) (content middle))
  =>
  (assert (k-cell (x 9) (y ?y) (content water)))
)

(defrule empty-around-middle-top-border (declare (salience 50))
  (k-cell (x ?x) (y 1) (content middle))
  =>
  (assert (k-cell (x ?x) (y 2) (content water)))
)

(defrule empty-around-middle-bottom-border (declare (salience 50))
  (k-cell (x ?x) (y 10) (content middle))
  =>
  (assert (k-cell (x ?x) (y 9) (content water)))
)