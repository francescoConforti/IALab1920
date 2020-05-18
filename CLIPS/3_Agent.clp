;  ---------------------------------------------
;  --- Definizione del modulo e dei template ---
;  ---------------------------------------------
(defmodule AGENT (import MAIN ?ALL) (import ENV ?ALL) (export ?ALL))

;  ---------------------------------------------
;  -------------- Fatti iniziali ---------------
;  ---------------------------------------------

(deffacts init-agent
  (affondati sottomarini 0) ; 1 casella, max 4
  (affondati cacciatorpedinieri 0)  ; 2 caselle, max 3
  (affondati incrociatori 0)  ; 3 caselle, max 2
  (affondati corazzate 0) ; 4 caselle, max 1
)

;  ---------------------------------------------
;  ------------- Funzioni ----------------------
;  ---------------------------------------------

(deffunction water-if-empty (?x ?y)
  (if (and (not (any-factp ((?kcell k-cell)) (and (eq ?kcell:x ?x) (eq ?kcell:y ?y))))
           (not (any-factp ((?ex exec)) (and (eq ?ex:action guess) (eq ?ex:x ?x) (eq ?ex:y ?y))))) then
   (assert (k-cell (x ?x) (y ?y) (content water))))
)

;  ---------------------------------------------------------
;  --- Regole per la pulizia e la gestione dell'ambiente ---
;  ------------------ Salience 70 --------------------------
;  ---------------------------------------------------------

(defrule cleanX (declare (salience 70))
  ?k <- (k-cell (x -1|10))
  =>
  (retract ?k)
)

(defrule cleanY (declare (salience 70))
  ?k <- (k-cell (y -1|10))
  =>
  (retract ?k)
)

; è fondamentale che questa regola abbia salience > reduce-k-new-cell
(defrule reduce-row (declare (salience 70))
  ?f <- (reduce-row ?x)
  ?row <- (k-per-row (num ?n) (row ?x))
  =>
  (retract ?f)
  (bind ?newnum (- ?n 1))
  (modify ?row (num ?newnum))
)

; è fondamentale che questa regola abbia salience > reduce-k-new-cell
(defrule reduce-col (declare (salience 70))
  ?f <- (reduce-col ?y)
  ?col <- (k-per-col (num ?n) (col ?y))
  =>
  (retract ?f)
  (bind ?newnum (- ?n 1))
  (modify ?col (num ?newnum))
)

;  ---------------------------------------------------------
;  --- Regole per la gestione delle caselle note -----------
;  -------- e l'inferenza delle caselle vuote --------------
;  ------------------ Salience 50 --------------------------
;  ---------------------------------------------------------

(defrule reduce-k-new-cell (declare (salience 50))
  (k-cell (x ?x) (y ?y) (content ~water))
  =>
  (assert (reduce-row ?x))
  (assert (reduce-col ?y))
)

(defrule reduce-k-guess (declare (salience 50))
  (exec (action guess) (x ?x) (y ?y))
  (not (k-cell (x ?x) (y ?y)))
  =>
  (assert (reduce-row ?x))
  (assert (reduce-col ?y))
)

; TODO: aumenta su unguess

; Se abbiamo trovato tutte le navi in una riga assegna acqua alle caselle restanti
(defrule row-empty (declare (salience 50))
	(k-per-row (num 0) (row ?x))
	=>
	(loop-for-count (?cnt 0 9) do
		(water-if-empty ?x ?cnt))
)

; Se abbiamo trovato tutte le navi in una colonna assegna acqua alle caselle restanti
(defrule column-empty (declare (salience 50))
	(k-per-col (num 0) (col ?y))
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

;  ---------------------------------------------------------
;  --- Regole per l'inferenza delle caselle occupate -------
;  -------------- usando l'azione guess --------------------
;  ------------------ Salience 30 --------------------------
;  ---------------------------------------------------------

; conosco già la cella ma la guess porta punti
(defrule guess-known-cell (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content ~water))
  (status (step ?s)(currently running))
	(not (exec  (action guess) (x ?x) (y ?y)))
=>
	(assert (exec (step ?s) (action guess) (x ?x) (y ?y)))
  (pop-focus)
)

; top si trova subito sopra il bordo, quindi è una nave da 2
(defrule guess-under-top-1-border (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content top))
  (test (> (+ ?x 2) 9))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?nextx & :(= (+ ?x 1) ?nextx)) (y ?y)))
  ?affondati <- (affondati cacciatorpedinieri ?n)
  =>
  ; tengo anche traccia dell'acqua intorno alla nave
  (assert (k-cell (x (+ ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 1)) (y (- ?y 1)) (content water)))
  (retract ?affondati)
  (assert (affondati cacciatorpedinieri (+ ?n 1)))
  (assert (exec (step ?s) (action guess) (x (+ ?x 1)) (y ?y)))
  (pop-focus)
)

; top si trova subito sopra una casella con acqua, quindi è una nave da 2
(defrule guess-under-top-1-water (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content top))
  (k-cell (x ?xwater) (y ?y) (content water))
  (test (eq (+ ?x 2) ?xwater))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?nextx & :(= (+ ?x 1) ?nextx)) (y ?y)))
  ?affondati <- (affondati cacciatorpedinieri ?n)
  =>
  ; tengo anche traccia dell'acqua intorno alla nave
  (assert (k-cell (x (+ ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 1)) (y (- ?y 1)) (content water)))
  (retract ?affondati)
  (assert (affondati cacciatorpedinieri (+ ?n 1)))
  (assert (exec (step ?s) (action guess) (x (+ ?x 1)) (y ?y)))
  (pop-focus)
)

; le navi da 3 e 4 sono già state affondate, quindi questa è da 2
(defrule guess-under-top-1-biggest-boat (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content top))
  (affondati incrociatori 2)
  (affondati corazzate 1)
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?nextx & :(= (+ ?x 1) ?nextx)) (y ?y)))
  ?affondati <- (affondati cacciatorpedinieri ?n)
  =>
  ; tengo anche traccia dell'acqua intorno alla nave
  (assert (k-cell (x (+ ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 1)) (y (- ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 2)) (y ?y) (content water)))
  (retract ?affondati)
  (assert (affondati cacciatorpedinieri (+ ?n 1)))
  (assert (exec (step ?s) (action guess) (x (+ ?x 1)) (y ?y)))
  (pop-focus)
)

; TODO caso normale: guess sotto top senza altre info