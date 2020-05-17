;  ---------------------------------------------
;  --- Definizione del modulo e dei template ---
;  ---------------------------------------------
(defmodule AGENT (import MAIN ?ALL) (import ENV ?ALL) (export ?ALL))

(deffacts init-agent
  (affondati sottomarini 0) ; 1 casella, max 4
  (affondati cacciatorpedinieri 0)  ; 2 caselle, max 3
  (affondati incrociatori 0)  ; 3 caselle, max 2
  (affondati corazzate 0) ; 4 caselle, max 1
)

(deffunction water-if-empty (?x ?y)
  (if (not (any-factp ((?kcell k-cell)) (and (eq ?kcell:x ?x) (eq ?kcell:y ?y)))) then
   (assert (k-cell (x ?x) (y ?y) (content water))))
)

; Se abbiamo trovato tutte le navi in una riga assegna acqua alle caselle restanti
(defrule row-full (declare (salience 50))
	(k-per-row  (num ?n) (row ?x))
  (test (eq ?n (length$ (find-all-facts ((?k k-cell)) (and (eq ?k:x ?x) (neq ?k:content water))))))
	=>
	(loop-for-count (?cnt 0 9) do
		(water-if-empty ?x ?cnt))
)

; Se abbiamo trovato tutte le navi in una colonna assegna acqua alle caselle restanti
(defrule column-full (declare (salience 50))
	(k-per-col  (num ?n) (col ?y))
  (test (eq ?n (length$ (find-all-facts ((?k k-cell)) (and (eq ?k:y ?y) (neq ?k:content water))))))
	=>
	(loop-for-count (?cnt 0 9) do
		(water-if-empty ?cnt ?y))
)

(defrule empty-around-sub (declare (salience 50))
  (k-cell (x ?x) (y ?y) (content sub))
  =>
  (assert (k-cell (x (+ ?x 1)) (y ?y) (content water)))
  (assert (k-cell (x (- ?x 1)) (y ?y) (content water)))
  (assert (k-cell (x ?x) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x ?x) (y (- ?y 1)) (content water)))
)

(defrule empty-around-left (declare (salience 50))
  (k-cell (x ?x) (y ?y) (content left))
  =>
  (assert (k-cell (x ?x) (y (- ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 1)) (y ?y) (content water)))
  (assert (k-cell (x (- ?x 1)) (y ?y) (content water)))
)

(defrule empty-around-right (declare (salience 50))
  (k-cell (x ?x) (y ?y) (content right))
  =>
  (assert (k-cell (x ?x) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 1)) (y ?y) (content water)))
  (assert (k-cell (x (- ?x 1)) (y ?y) (content water)))
)

(defrule empty-around-top (declare (salience 50))
  (k-cell (x ?x) (y ?y) (content top))
  =>
  (assert (k-cell (x ?x) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x ?x) (y (- ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y ?y) (content water)))
)

(defrule empty-around-bot (declare (salience 50))
  (k-cell (x ?x) (y ?y) (content bot))
  =>
  (assert (k-cell (x ?x) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x ?x) (y (- ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 1)) (y ?y) (content water)))
)

(defrule empty-around-middle-know-left-or-right (declare (salience 50))
  (k-cell (x ?x) (y ?y) (content middle))
  (k-cell (x ?x) (y ?yLeftOrRight) (content ~water))
  (test (or (eq ?yLeftOrRight (+ ?y 1)) (eq ?yLeftOrRight (- ?y 1))))
  =>
  (assert (k-cell (x (+ ?x 1)) (y ?y) (content water)))
  (assert (k-cell (x (- ?x 1)) (y ?y) (content water)))
)

(defrule empty-around-middle-know-up-or-down (declare (salience 50))
  (k-cell (x ?x) (y ?y) (content middle))
  (k-cell (x ?xUpOrDown) (y ?y) (content ~water))
  (test (or (eq ?xUpOrDown (+ ?x 1)) (eq ?xUpOrDown (- ?x 1))))
  =>
  (assert (k-cell (x ?x) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x ?x) (y (- ?y 1)) (content water)))
)

(defrule empty-around-middle-water-left-or-right (declare (salience 50)) ;; per il lato opposto
  (k-cell (x ?x) (y ?y) (content middle))
  (k-cell (x ?x) (y ?yLeftOrRight) (content water))
  (test (or (eq ?yLeftOrRight (+ ?y 1)) (eq ?yLeftOrRight (- ?y 1))))
  =>
  (assert (k-cell (x ?x) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x ?x) (y (- ?y 1)) (content water)))
)

(defrule empty-around-middle-water-up-or-down (declare (salience 50)) ;; per il lato opposto
  (k-cell (x ?x) (y ?y) (content middle))
  (k-cell (x ?xUpOrDown) (y ?y) (content water))
  (test (or (eq ?xUpOrDown (+ ?x 1)) (eq ?xUpOrDown (- ?x 1))))
  =>
  (assert (k-cell (x (+ ?x 1)) (y ?y) (content water)))
  (assert (k-cell (x (- ?x 1)) (y ?y) (content water)))
)

(defrule empty-around-middle-top-border (declare (salience 50))
  (k-cell (x 0) (y ?y) (content middle))
  =>
  (assert (k-cell (x 1) (y ?y) (content water)))
)

(defrule empty-around-middle-bottom-border (declare (salience 50))
  (k-cell (x 9) (y ?y) (content middle))
  =>
  (assert (k-cell (x 8) (y ?y) (content water)))
)

(defrule empty-around-middle-left-border (declare (salience 50))
  (k-cell (x ?x) (y 0) (content middle))
  =>
  (assert (k-cell (x ?x) (y 1) (content water)))
)

(defrule empty-around-middle-right-border (declare (salience 50))
  (k-cell (x ?x) (y 9) (content middle))
  =>
  (assert (k-cell (x ?x) (y 8) (content water)))
)