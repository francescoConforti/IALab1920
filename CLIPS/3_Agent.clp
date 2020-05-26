;  ---------------------------------------------
;  --- Definizione del modulo e dei template ---
;  ---------------------------------------------
(defmodule AGENT (import MAIN ?ALL) (import ENV ?ALL) (export ?ALL))

(deftemplate CONFLICT
  (slot x)
  (slot y)
  (slot reason (type STRING))
)

(deftemplate nave-verticale-affondata
  (multislot xs)
  (slot y)
  (slot hit (allowed-values 0 1)) ;0 indica che non è stata colpita, 1 il contrario
)

(deftemplate nave-orizzontale-affondata
  (slot x)
  (multislot ys)
  (slot hit (allowed-values 0 1)) ;0 indica che non è stata colpita, 1 il contrario
)

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
;  -------- Regole di rilevamento dei conflitti ------------
;  ------------------ Salience massima  --------------------
;  ---------------------------------------------------------

(defrule conflict-kcell (declare (salience 100))
  (k-cell (x ?x) (y ?y) (content ?c1))
  (k-cell (x ?x) (y ?y) (content ~?c1))
  =>
  (assert (CONFLICT (x ?x) (y ?y) (reason "la k-cell contiene due parti di nave diverse")))
)

(defrule conflict-kcell-water (declare (salience 100))
  (k-cell (x ?x) (y ?y) (content water))
  (k-cell (x ?x) (y ?y) (content ~water))
  =>
  (assert (CONFLICT (x ?x) (y ?y) (reason "la k-cell contiene sia acqua che una parte di nave")))
)

(defrule conflict-guess-fire (declare (salience 100))
  (exec (action guess) (x ?x) (y ?y))
  (exec (action fire) (x ?x) (y ?y))
  =>
  (assert (CONFLICT (x ?x) (y ?y) (reason "guess e fire sulla stessa casella")))
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
  ?affondati <- (affondati sottomarini ?n)
  =>
  (assert (k-cell (x (+ ?x 1)) (y ?y) (content water)))
  (assert (k-cell (x (- ?x 1)) (y ?y) (content water)))
  (assert (k-cell (x ?x) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x ?x) (y (- ?y 1)) (content water)))
  (retract ?affondati)
  (assert (affondati sottomarini (+ ?n 1)))
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

; le regole seguenti servono ad aggiungere info sull'acqua in situazioni che possono
; verificarsi in seguito al processo di guess / fire ma sono impossibili o
; difficili da aggiungere direttamente al momento della action

(defrule empty-above-middle-after-middle (declare (salience 50))
  (k-cell (x ?x) (y ?y) (content middle))
  (k-cell (x ?x1 & :(= (+ ?x 1) ?x1)) (y ?y) (content middle))
  =>
  (assert (k-cell (x (- ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (- ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 2)) (y ?y) (content water)))
)

(defrule empty-under-middle-after-middle (declare (salience 50))
  (k-cell (x ?x) (y ?y) (content middle))
  (k-cell (x ?x1 & :(= (- ?x 1) ?x1)) (y ?y) (content middle))
  =>
  (assert (k-cell (x (+ ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 1)) (y (- ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 2)) (y ?y) (content water)))
)

(defrule empty-left-of-middle-after-middle (declare (salience 50))
  (k-cell (x ?x) (y ?y) (content middle))
  (k-cell (x ?x) (y ?y1 & :(= (+ ?y 1) ?y1)) (content middle))
  =>
  (assert (k-cell (x (+ ?x 1)) (y (- ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (- ?y 1)) (content water)))
  (assert (k-cell (x ?x) (y (- ?y 2)) (content water)))
)

(defrule empty-right-of-middle-after-middle (declare (salience 50))
  (k-cell (x ?x) (y ?y) (content middle))
  (k-cell (x ?x) (y ?y1 & :(= (- ?y 1) ?y1)) (content middle))
  =>
  (assert (k-cell (x (+ ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x ?x) (y (+ ?y 2)) (content water)))
)

;asserisce che una nave da 2 è affondata facendo una visita bottom up 
(defrule verifica-cacciatorpedinieri-affondati-bottom-up (declare (salience 50))
  (k-cell (x ?x1) (y ?y) (content water))
  
  (or (exec (action guess) (x ?x2&:(= ?x2 (- ?x1 1))) (y ?y))
      (k-cell (x ?x2&:(= ?x2 (- ?x1 1))) (y ?y) (content ~water)))
  
  (or (exec (action guess) (x ?x3&:(= ?x3 (- ?x1 2))) (y ?y))
      (k-cell (x ?x3&:(= ?x3 (- ?x1 2))) (y ?y) (content ~water)))
  
  (or (k-cell (x ?x4&:(= ?x4 (- ?x1 3))) (y ?y))
      (test (< (- ?x1 3) 0)))

  (not (nave-verticale-affondata (xs ?x3 ?x2) (y ?y) (hit 1)))
  
  ?affondati <- (affondati cacciatorpedinieri ?n)
  (test (< ?n 4))
  =>
  (assert (nave-verticale-affondata (xs ?x3 ?x2) (y ?y) (hit 1)))
  (retract ?affondati)
  (assert (affondati cacciatorpedinieri (+ ?n 1)))
)

;asserisce che una nave da 2 è affondata facendo una visita top down
(defrule verifica-cacciatorpedinieri-affondati-top-down (declare (salience 50))
  (k-cell (x ?x1) (y ?y) (content water))

  (or (exec (action guess) (x ?x2&:(= ?x2 (+ ?x1 1))) (y ?y))
      (k-cell (x ?x2&:(= ?x2 (+ ?x1 1))) (y ?y) (content ~water)))
  
  (or (exec (action guess) (x ?x3&:(= ?x3 (+ ?x1 2))) (y ?y))
      (k-cell (x ?x3&:(= ?x3 (+ ?x1 2))) (y ?y) (content ~water)))
  
  (or (k-cell (x ?x4&:(= ?x4 (+ ?x1 3))) (y ?y))
      (test (> (+ ?x1 3) 9)))

  (not (nave-verticale-affondata (xs ?x2 ?x3) (y ?y) (hit 1)))
  
  ?affondati <- (affondati cacciatorpedinieri ?n)
  (test (< ?n 4))
  =>
  (assert (nave-verticale-affondata (xs ?x2 ?x3) (y ?y) (hit 1)))
  (retract ?affondati)
  (assert (affondati cacciatorpedinieri (+ ?n 1)))
)

;asserisce che una nave da 2 è affondata facendo una visita left-to-right
(defrule verifica-cacciatorpedinieri-affondati-left-to-right (declare (salience 50))
  (k-cell (x ?x) (y ?y1) (content water))

  (or (exec (action guess) (x ?x) (y ?y2&:(= ?y2 (+ ?y1 1))))
      (k-cell (x ?x) (y ?y2&:(= ?y2 (+ ?y1 1))) (content ~water)))

  (or (exec (action guess) (x ?x) (y ?y3&:(= ?y3 (+ ?y1 2))))
      (k-cell (x ?x) (y ?y3&:(= ?y3 (+ ?y1 2))) (content ~water)))

  (or (k-cell (x ?x) (y ?y4&:(= ?y4 (+ ?y1 3))))
      (test (> (+ ?y1 3) 9)))

  (not (nave-orizzontale-affondata (x ?x) (ys ?y2 ?y3) (hit 1)))
  
  ?affondati <- (affondati cacciatorpedinieri ?n)
  (test (< ?n 4))
  =>
  (assert (nave-orizzontale-affondata (x ?x) (ys ?y2 ?y3) (hit 1)))
  (retract ?affondati)
  (assert (affondati cacciatorpedinieri (+ ?n 1)))
)

;asserisce che una nave da 2 è affondata facendo una visita right-to-left 
(defrule verifica-cacciatorpedinieri-affondati-right-to-left (declare (salience 50))
  (k-cell (x ?x) (y ?y1) (content water))

  (or (exec (action guess) (x ?x) (y ?y2&:(= ?y2 (- ?y1 1))))
      (k-cell (x ?x) (y ?y2&:(= ?y2 (- ?y1 1))) (content ~water)))

  (or (exec (action guess) (x ?x) (y ?y3&:(= ?y3 (- ?y1 2))))
      (k-cell (x ?x) (y ?y3&:(= ?y3 (- ?y1 2))) (content ~water)))

  (or (k-cell (x ?x) (y ?y4&:(= ?y4 (- ?y1 3))))
      (test (< (- ?y1 3) 0)))

  (not (nave-orizzontale-affondata (x ?x) (ys ?y3 ?y2) (hit 1)))
  
  ?affondati <- (affondati cacciatorpedinieri ?n)
  (test (< ?n 4))
  =>
  (assert (nave-orizzontale-affondata (x ?x) (ys ?y3 ?y2) (hit 1)))
  (retract ?affondati)
  (assert (affondati cacciatorpedinieri (+ ?n 1)))
)

;asserisce che una nave da 3 è affondata facendo una visita bottom up 
(defrule verifica-incrociatori-affondati-bottom-up (declare (salience 50))
  (k-cell (x ?x1) (y ?y) (content water))

  (or (exec (action guess) (x ?x2&:(= ?x2 (- ?x1 1))) (y ?y))
      (k-cell (x ?x2&:(= ?x2 (- ?x1 1))) (y ?y) (content ~water)))

  (or (exec (action guess) (x ?x3&:(= ?x3 (- ?x1 2))) (y ?y))
      (k-cell (x ?x3&:(= ?x3 (- ?x1 2))) (y ?y) (content ~water)))

  (or (exec (action guess) (x ?x4&:(= ?x4 (- ?x1 3))) (y ?y))
      (k-cell (x ?x4&:(= ?x4 (- ?x1 3))) (y ?y) (content ~water)))

  (or (k-cell (x ?x5&:(= ?x5 (- ?x1 4))) (y ?y))
      (test (< (- ?x1 4) 0)))

  (not (nave-verticale-affondata (xs ?x4 ?x3 ?x2) (y ?y) (hit 1)))
  
  ?affondati <- (affondati incrociatori ?n)
  (test (< ?n 3))
  =>
  (assert (nave-verticale-affondata (xs ?x4 ?x3 ?x2) (y ?y) (hit 1)))
  (retract ?affondati)
  (assert (affondati incrociatori (+ ?n 1)))
)

;asserisce che una nave da 3 è affondata facendo una visita top down 
(defrule verifica-incrociatori-affondati-top-down (declare (salience 50))
  (k-cell (x ?x1) (y ?y) (content water))

  (or (exec (action guess) (x ?x2&:(= ?x2 (+ ?x1 1))) (y ?y))
      (k-cell (x ?x2&:(= ?x2 (+ ?x1 1))) (y ?y) (content ~water)))

  (or (exec (action guess) (x ?x3&:(= ?x3 (+ ?x1 2))) (y ?y))
      (k-cell (x ?x3&:(= ?x3 (+ ?x1 2))) (y ?y) (content ~water)))

  (or (exec (action guess) (x ?x4&:(= ?x4 (+ ?x1 3))) (y ?y))
      (k-cell (x ?x4&:(= ?x4 (+ ?x1 3))) (y ?y) (content ~water)))

  (or (k-cell (x ?x5&:(= ?x5 (+ ?x1 4))) (y ?y))
      (test (< (+ ?x1 4) 0)))

  (not (nave-verticale-affondata (xs ?x2 ?x3 ?x4) (y ?y) (hit 1)))
  
  ?affondati <- (affondati incrociatori ?n)
  (test (< ?n 3))
  =>
  (assert (nave-verticale-affondata (xs ?x2 ?x3 ?x4) (y ?y) (hit 1)))
  (retract ?affondati)
  (assert (affondati incrociatori (+ ?n 1)))
)

;asserisce che una nave da 3 è affondata facendo una visita left-to-right
(defrule verifica-incrociatori-affondati-left-to-right (declare (salience 50))
  (k-cell (x ?x) (y ?y1) (content water))

  (or (exec (action guess) (x ?x) (y ?y2&:(= ?y2 (+ ?y1 1))))
      (k-cell (x ?x) (y ?y2&:(= ?y2 (+ ?y1 1))) (content ~water)))

  (or (exec (action guess) (x ?x) (y ?y3&:(= ?y3 (+ ?y1 2))))
      (k-cell (x ?x) (y ?y3&:(= ?y3 (+ ?y1 2))) (content ~water)))

  (or (exec (action guess) (x ?x) (y ?y4&:(= ?y4 (+ ?y1 3))))
      (k-cell (x ?x) (y ?y4&:(= ?y4 (+ ?y1 3))) (content ~water)))

  (or (k-cell (x ?x) (y ?y5&:(= ?y5 (+ ?y1 4))))
      (test (> (+ ?y1 4) 9)))

  (not (nave-orizzontale-affondata (x ?x) (ys ?y2 ?y3 ?y4) (hit 1)))
  
  ?affondati <- (affondati incrociatori ?n)
  (test (< ?n 3))
  =>
  (assert (nave-orizzontale-affondata (x ?x) (ys ?y2 ?y3 ?y4) (hit 1)))
  (retract ?affondati)
  (assert (affondati incrociatori (+ ?n 1)))
)

;asserisce che una nave da 3 è affondata facendo una visita right-to-left
(defrule verifica-incrociatori-affondati-right-to-left (declare (salience 50))
  (k-cell (x ?x) (y ?y1) (content water))

  (or (exec (action guess) (x ?x) (y ?y2&:(= ?y2 (- ?y1 1))))
      (k-cell (x ?x) (y ?y2&:(= ?y2 (- ?y1 1))) (content ~water)))

  (or (exec (action guess) (x ?x) (y ?y3&:(= ?y3 (- ?y1 2))))
      (k-cell (x ?x) (y ?y3&:(= ?y3 (- ?y1 2))) (content ~water)))

  (or (exec (action guess) (x ?x) (y ?y4&:(= ?y4 (- ?y1 3))))
      (k-cell (x ?x) (y ?y4&:(= ?y4 (- ?y1 3))) (content ~water)))

  (or (k-cell (x ?x) (y ?y5&:(= ?y5 (- ?y1 4))))
      (test (> (- ?y1 4) 9)))

  (not (nave-orizzontale-affondata (x ?x) (ys ?y4 ?y3 ?y2) (hit 1)))
  
  ?affondati <- (affondati incrociatori ?n)
  (test (< ?n 3))
  =>
  (assert (nave-orizzontale-affondata (x ?x) (ys ?y4 ?y3 ?y2) (hit 1)))
  (retract ?affondati)
  (assert (affondati incrociatori (+ ?n 1)))
)

;asserisce che una nave da 4 è affondata facendo una visita top-down 
(defrule verifica-corazzata-affondata-top-down (declare (salience 50))
  (k-cell (x ?x1) (y ?y) (content water))

  (or (exec (action guess) (x ?x2&:(= ?x2 (+ ?x1 1))) (y ?y))
      (k-cell (x ?x2&:(= ?x2 (+ ?x1 1))) (y ?y) (content ~water)))

  (or (exec (action guess) (x ?x3&:(= ?x3 (+ ?x1 2))) (y ?y))
      (k-cell (x ?x3&:(= ?x3 (+ ?x1 2))) (y ?y) (content ~water)))

  (or (exec (action guess) (x ?x4&:(= ?x4 (+ ?x1 3))) (y ?y))
      (k-cell (x ?x4&:(= ?x4 (+ ?x1 3))) (y ?y) (content ~water)))

  (or (exec (action guess) (x ?x5&:(= ?x5 (+ ?x1 4))) (y ?y))
      (k-cell (x ?x5&:(= ?x5 (+ ?x1 4))) (y ?y) (content ~water)))

  (or (k-cell (x ?x6&:(= ?x6 (+ ?x1 5))) (y ?y))
      (test (< (+ ?x1 5) 0)))

  (not (nave-verticale-affondata (xs ?x2 ?x3 ?x4 ?x5) (y ?y) (hit 1)))
  
  ?affondati <- (affondati corazzate 0)
  =>
  (assert (nave-verticale-affondata (xs ?x2 ?x3 ?x4 ?x5) (y ?y) (hit 1)))
  (retract ?affondati)
  (assert (affondati corazzate 1))
)

;asserisce che una nave da 4 è affondata facendo una visita bottom up
(defrule verifica-corazzata-affondata-bottom-up (declare (salience 50))
  (k-cell (x ?x1) (y ?y) (content water))

  (or (exec (action guess) (x ?x2&:(= ?x2 (- ?x1 1))) (y ?y))
      (k-cell (x ?x2&:(= ?x2 (- ?x1 1))) (y ?y) (content ~water)))

  (or (exec (action guess) (x ?x3&:(= ?x3 (- ?x1 2))) (y ?y))
      (k-cell (x ?x3&:(= ?x3 (- ?x1 2))) (y ?y) (content ~water)))

  (or (exec (action guess) (x ?x4&:(= ?x4 (- ?x1 3))) (y ?y))
      (k-cell (x ?x4&:(= ?x4 (- ?x1 3))) (y ?y) (content ~water)))

  (or (exec (action guess) (x ?x5&:(= ?x5 (- ?x1 4))) (y ?y))
      (k-cell (x ?x5&:(= ?x5 (- ?x1 4))) (y ?y) (content ~water)))

  (or (k-cell (x ?x6&:(= ?x6 (- ?x1 5))) (y ?y))
      (test (< (- ?x1 5) 0)))

  (not (nave-verticale-affondata (xs ?x5 ?x4 ?x3 ?x2) (y ?y) (hit 1)))
  
  ?affondati <- (affondati corazzate 0)
  =>
  (assert (nave-verticale-affondata (xs ?x5 ?x4 ?x3 ?x2) (y ?y) (hit 1)))
  (retract ?affondati)
  (assert (affondati corazzate 1))
)

;asserisce che una nave da 4 è affondata facendo una visita left-to-right
(defrule verifica-corazzata-affondata-left-to-right (declare (salience 50))
  (k-cell (x ?x) (y ?y1) (content water))

  (or (exec (action guess) (x ?x) (y ?y2&:(= ?y2 (+ ?y1 1))))
      (k-cell (x ?x) (y ?y2&:(= ?y2 (+ ?y1 1))) (content ~water)))

  (or (exec (action guess) (x ?x) (y ?y3&:(= ?y3 (+ ?y1 2))))
      (k-cell (x ?x) (y ?y3&:(= ?y3 (+ ?y1 2))) (content ~water)))

  (or (exec (action guess) (x ?x) (y ?y4&:(= ?y4 (+ ?y1 3))))
      (k-cell (x ?x) (y ?y4&:(= ?y4 (+ ?y1 3))) (content ~water)))

  (or (exec (action guess) (x ?x) (y ?y5&:(= ?y5 (+ ?y1 3))))
      (k-cell (x ?x) (y ?y5&:(= ?y5 (+ ?y1 3))) (content ~water)))

  (or (k-cell (x ?x) (y ?y6&:(= ?y6 (+ ?y1 4))))
      (test (> (+ ?y1 5) 9)))

  (not (nave-orizzontale-affondata (x ?x) (ys ?y2 ?y3 ?y4 ?y5) (hit 1)))
  
  ?affondati <- (affondati corazzate 0)
  =>
  (assert (nave-orizzontale-affondata (x ?x) (ys ?y2 ?y3 ?y4 ?y5) (hit 1)))
  (retract ?affondati)
  (assert (affondati corazzate 1))
)

;asserisce che una nave da 4 è affondata facendo una visita right-to-left
(defrule verifica-corazzata-affondata-right-to-left (declare (salience 50))
  (k-cell (x ?x) (y ?y1) (content water))

  (or (exec (action guess) (x ?x) (y ?y2&:(= ?y2 (- ?y1 1))))
      (k-cell (x ?x) (y ?y2&:(= ?y2 (- ?y1 1))) (content ~water)))

  (or (exec (action guess) (x ?x) (y ?y3&:(= ?y3 (- ?y1 2))))
      (k-cell (x ?x) (y ?y3&:(= ?y3 (- ?y1 2))) (content ~water)))

  (or (exec (action guess) (x ?x) (y ?y4&:(= ?y4 (- ?y1 3))))
      (k-cell (x ?x) (y ?y4&:(= ?y4 (- ?y1 3))) (content ~water)))

  (or (exec (action guess) (x ?x) (y ?y5&:(= ?y5 (- ?y1 3))))
      (k-cell (x ?x) (y ?y5&:(= ?y5 (- ?y1 3))) (content ~water)))

  (or (k-cell (x ?x) (y ?y6&:(= ?y6 (- ?y1 4))))
      (test (< (- ?y1 5) 0)))

  (not (nave-orizzontale-affondata (x ?x) (ys ?y5 ?y4 ?y3 ?y2) (hit 1)))
  
  ?affondati <- (affondati corazzate 0)
  =>
  (assert (nave-orizzontale-affondata (x ?x) (ys ?y5 ?y4 ?y3 ?y2) (hit 1)))
  (retract ?affondati)
  (assert (affondati corazzate 1))
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
	(not (exec  (action guess|fire) (x ?x) (y ?y)))
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
  =>
  ; tengo anche traccia dell'acqua intorno alla nave
  (assert (k-cell (x (+ ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 1)) (y (- ?y 1)) (content water)))
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
  =>
  ; tengo anche traccia dell'acqua intorno alla nave
  (assert (k-cell (x (+ ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 1)) (y (- ?y 1)) (content water)))
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
  =>
  ; tengo anche traccia dell'acqua intorno alla nave
  (assert (k-cell (x (+ ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 1)) (y (- ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 2)) (y ?y) (content water)))
  (assert (exec (step ?s) (action guess) (x (+ ?x 1)) (y ?y)))
  (pop-focus)
)

; caso normale: guess sotto top senza altre info
(defrule guess-under-top-1-default (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content top))
  (test (<= (+ ?x 2) 9))
  (or (not (affondati incrociatori 2))
      (not (affondati corazzate 1)))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?nextx & :(= (+ ?x 1) ?nextx)) (y ?y)))
  =>
  ; tengo anche traccia dell'acqua intorno alla nave
  (assert (k-cell (x (+ ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 1)) (y (- ?y 1)) (content water)))
  (assert (exec (step ?s) (action guess) (x (+ ?x 1)) (y ?y)))
  (pop-focus)
)

; bot si trova subito sopra il bordo, quindi è una nave da 2
(defrule guess-over-bot-1-border (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content bot))
  (test (< (- ?x 2) 0))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?nextx & :(= (- ?x 1) ?nextx)) (y ?y)))
  =>
  ; tengo anche traccia dell'acqua intorno alla nave
  (assert (k-cell (x (- ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (- ?y 1)) (content water)))
  (assert (exec (step ?s) (action guess) (x (- ?x 1)) (y ?y)))
  (pop-focus)
)

; bot si trova subito sotto una casella con acqua, quindi è una nave da 2
(defrule guess-over-bot-1-water (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content bot))
  (k-cell (x ?xwater) (y ?y) (content water))
  (test (eq (- ?x 2) ?xwater))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?nextx & :(= (- ?x 1) ?nextx)) (y ?y)))
  =>
  ; tengo anche traccia dell'acqua intorno alla nave
  (assert (k-cell (x (- ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (- ?y 1)) (content water)))
  (assert (exec (step ?s) (action guess) (x (- ?x 1)) (y ?y)))
  (pop-focus)
)

; le navi da 3 e 4 sono già state affondate, quindi questa è da 2
(defrule guess-over-bot-1-biggest-boat (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content bot))
  (affondati incrociatori 2)
  (affondati corazzate 1)
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?nextx & :(= (- ?x 1) ?nextx)) (y ?y)))
  =>
  ; tengo anche traccia dell'acqua intorno alla nave
  (assert (k-cell (x (- ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (- ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 2)) (y ?y) (content water)))
  (assert (exec (step ?s) (action guess) (x (- ?x 1)) (y ?y)))
  (pop-focus)
)

; caso normale: guess sopra bot senza altre info
(defrule guess-over-bot-1-default (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content bot))
  (test (>= (- ?x 2) 0))
  (or (not (affondati incrociatori 2))
      (not (affondati corazzate 1)))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?nextx & :(= (- ?x 1) ?nextx)) (y ?y)))
  =>
  ; tengo anche traccia dell'acqua intorno alla nave
  (assert (k-cell (x (- ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (- ?y 1)) (content water)))
  (assert (exec (step ?s) (action guess) (x (- ?x 1)) (y ?y)))
  (pop-focus)
)

; left si trova subito affianco al bordo, quindi è una nave da 2
(defrule guess-next-to-left-1-border (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content left))
  (test (> (+ ?y 2) 9))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x) (y ?nexty & :(= (+ ?y 1) ?nexty))))
  =>
  ; tengo anche traccia dell'acqua intorno alla nave
  (assert (k-cell (x (+ ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (exec (step ?s) (action guess) (x ?x) (y (+ ?y 1))))
  (pop-focus)
)

; left si trova subito a fainco di una casella con acqua, quindi è una nave da 2
(defrule guess-next-to-left-1-water (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content left))
  (k-cell (x ?x) (y ?ywater) (content water))
  (test (eq (+ ?y 2) ?ywater))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x) (y ?nexty & :(= (+ ?y 1) ?nexty))))
  =>
  ; tengo anche traccia dell'acqua intorno alla nave
  (assert (k-cell (x (+ ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (exec (step ?s) (action guess) (x ?x) (y (+ ?y 1))))
  (pop-focus)
)

; le navi da 3 e 4 sono già state affondate, quindi questa è da 2
(defrule guess-next-to-left-1-biggest-boat (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content left))
  (affondati incrociatori 2)
  (affondati corazzate 1)
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x) (y ?nexty & :(= (+ ?y 1) ?nexty))))
  =>
  ; tengo anche traccia dell'acqua intorno alla nave
  (assert (k-cell (x (+ ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x ?x) (y (+ ?y 2)) (content water)))
  (assert (exec (step ?s) (action guess) (x ?x) (y (+ ?y 1))))
  (pop-focus)
)

; caso normale: guess affianco left senza altre info
(defrule guess-next-to-left-1-default (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content left))
  (test (<= (+ ?y 2) 9))
  (or (not (affondati incrociatori 2))
      (not (affondati corazzate 1)))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x) (y ?nexty & :(= (+ ?y 1) ?nexty))))
  =>
  ; tengo anche traccia dell'acqua intorno alla nave
  (assert (k-cell (x (+ ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (exec (step ?s) (action guess) (x ?x) (y (+ ?y 1))))
  (pop-focus)
)

; right si trova subito affianco al bordo, quindi è una nave da 2
(defrule guess-next-to-right-1-border (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content right))
  (test (< (- ?y 2) 0))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x) (y ?nexty & :(= (- ?y 1) ?nexty))))
  =>
  ; tengo anche traccia dell'acqua intorno alla nave
  (assert (k-cell (x (+ ?x 1)) (y (- ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (- ?y 1)) (content water)))
  (assert (exec (step ?s) (action guess) (x ?x) (y (- ?y 1))))
  (pop-focus)
)

; right si trova subito a fainco di una casella con acqua, quindi è una nave da 2
(defrule guess-next-to-right-1-water (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content right))
  (k-cell (x ?x) (y ?ywater) (content water))
  (test (eq (- ?y 2) ?ywater))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x) (y ?nexty & :(= (- ?y 1) ?nexty))))
  =>
  ; tengo anche traccia dell'acqua intorno alla nave
  (assert (k-cell (x (+ ?x 1)) (y (- ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (- ?y 1)) (content water)))
  (assert (exec (step ?s) (action guess) (x ?x) (y (- ?y 1))))
  (pop-focus)
)

; le navi da 3 e 4 sono già state affondate, quindi questa è da 2
(defrule guess-next-to-right-1-biggest-boat (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content right))
  (affondati incrociatori 2)
  (affondati corazzate 1)
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x) (y ?nexty & :(= (- ?y 1) ?nexty))))
  =>
  ; tengo anche traccia dell'acqua intorno alla nave
  (assert (k-cell (x (+ ?x 1)) (y (- ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (- ?y 1)) (content water)))
  (assert (k-cell (x ?x) (y (- ?y 2)) (content water)))
  (assert (exec (step ?s) (action guess) (x ?x) (y (- ?y 1))))
  (pop-focus)
)

; caso normale: guess affianco right senza altre info
(defrule guess-next-to-right-1-default (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content right))
  (test (>= (- ?y 2) 0))
  (or (not (affondati incrociatori 2))
      (not (affondati corazzate 1)))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x) (y ?nexty & :(= (- ?y 1) ?nexty))))
  =>
  ; tengo anche traccia dell'acqua intorno alla nave
  (assert (k-cell (x (+ ?x 1)) (y (- ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (- ?y 1)) (content water)))
  (assert (exec (step ?s) (action guess) (x ?x) (y (- ?y 1))))
  (pop-focus)
)

(defrule guess-under-top-2-border (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content top))
  (or (k-cell (x ?nx & :(= (+ ?x 1) ?nx)) (y ?y) (content middle)) 
      (exec (action guess) (x ?nx) (y ?y)))
  (affondati cacciatorpedinieri 3)
  (test (> (+ ?x 3) 9))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?nnx & :(= (+ ?x 2) ?nnx)) (y ?y)))
  =>
  (assert (k-cell (x (+ ?x 2)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 2)) (y (- ?y 1)) (content water)))
  (assert (exec (step ?s) (action guess) (x (+ ?x 2)) (y ?y)))
  (pop-focus)
)

(defrule guess-under-top-2-water (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content top))
  (or (k-cell (x ?nx & :(= (+ ?x 1) ?nx)) (y ?y) (content middle)) 
      (exec (action guess) (x ?nx) (y ?y)))
  (affondati cacciatorpedinieri 3)
  (k-cell (x ?xwater & :(= (+ ?x 3) ?xwater)) (y ?y) (content water))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?nnx & :(= (+ ?x 2) ?nnx)) (y ?y)))
  =>
  (assert (k-cell (x (+ ?x 2)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 2)) (y (- ?y 1)) (content water)))
  (assert (exec (step ?s) (action guess) (x (+ ?x 2)) (y ?y)))
  (pop-focus)
)

(defrule guess-under-top-2-biggest-boat (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content top))
  (or (k-cell (x ?nx & :(= (+ ?x 1) ?nx)) (y ?y) (content middle)) 
      (exec (action guess) (x ?nx) (y ?y)))
  (affondati cacciatorpedinieri 3)
  (affondati corazzate 1)
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?nnx & :(= (+ ?x 2) ?nnx)) (y ?y)))
  =>
  (assert (k-cell (x (+ ?x 2)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 2)) (y (- ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 3)) (y ?y) (content water)))
  (assert (exec (step ?s) (action guess) (x (+ ?x 2)) (y ?y)))
  (pop-focus)
)

(defrule guess-under-top-2-default (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content top))
  (or (k-cell (x ?nx & :(= (+ ?x 1) ?nx)) (y ?y) (content middle)) 
      (exec (action guess) (x ?nx) (y ?y)))
  (test (<= (+ ?x 3) 9))
  (affondati cacciatorpedinieri 3)
  (not (affondati corazzate 1))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?nnx & :(= (+ ?x 2) ?nnx)) (y ?y)))
  =>
  (assert (k-cell (x (+ ?x 2)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 2)) (y (- ?y 1)) (content water)))
  (assert (exec (step ?s) (action guess) (x (+ ?x 2)) (y ?y)))
  (pop-focus)
)

(defrule guess-over-bot-2-border (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content bot))
  (or (k-cell (x ?nx & :(= (- ?x 1) ?nx)) (y ?y) (content middle)) 
      (exec (action guess) (x ?nx) (y ?y)))
  (affondati cacciatorpedinieri 3)
  (test (< (- ?x 3) 0))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?nnx & :(= (- ?x 2) ?nnx)) (y ?y)))
  =>
  (assert (k-cell (x (- ?x 2)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 2)) (y (- ?y 1)) (content water)))
  (assert (exec (step ?s) (action guess) (x (- ?x 2)) (y ?y)))
  (pop-focus)
)

(defrule guess-over-bot-2-water (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content bot))
  (or (k-cell (x ?nx & :(= (- ?x 1) ?nx)) (y ?y) (content middle)) 
      (exec (action guess) (x ?nx) (y ?y)))
  (affondati cacciatorpedinieri 3)
  (k-cell (x ?xwater & :(= (- ?x 3) ?xwater)) (y ?y) (content water))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?nnx & :(= (- ?x 2) ?nnx)) (y ?y)))
  =>
  (assert (k-cell (x (- ?x 2)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 2)) (y (- ?y 1)) (content water)))
  (assert (exec (step ?s) (action guess) (x (- ?x 2)) (y ?y)))
  (pop-focus)
)

(defrule guess-over-bot-2-biggest-boat (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content bot))
  (or (k-cell (x ?nx & :(= (- ?x 1) ?nx)) (y ?y) (content middle)) 
      (exec (action guess) (x ?nx) (y ?y)))
  (affondati cacciatorpedinieri 3)
  (affondati corazzate 1)
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?nnx & :(= (- ?x 2) ?nnx)) (y ?y)))
  =>
  (assert (k-cell (x (- ?x 2)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 2)) (y (- ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 3)) (y ?y) (content water)))
  (assert (exec (step ?s) (action guess) (x (- ?x 2)) (y ?y)))
  (pop-focus)
)

(defrule guess-over-bot-2-default (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content bot))
  (or (k-cell (x ?nx & :(= (- ?x 1) ?nx)) (y ?y) (content middle)) 
      (exec (action guess) (x ?nx) (y ?y)))
  (test (>= (- ?x 3) 0))
  (affondati cacciatorpedinieri 3)
  (not (affondati corazzate 1))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?nnx & :(= (- ?x 2) ?nnx)) (y ?y)))
  =>
  (assert (k-cell (x (- ?x 2)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 2)) (y (- ?y 1)) (content water)))
  (assert (exec (step ?s) (action guess) (x (- ?x 2)) (y ?y)))
  (pop-focus)
)

(defrule guess-next-to-left-2-border (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content left))
  (or (k-cell (x ?x) (y ?ny & :(= (+ ?y 1) ?ny)) (content middle)) 
      (exec (action guess) (x ?x) (y ?ny)))
  (affondati cacciatorpedinieri 3)
  (test (> (+ ?y 3) 9))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x) (y ?nny & :(= (+ ?y 2) ?nny))))
  =>
  (assert (k-cell (x (+ ?x 1)) (y (+ ?y 2)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (+ ?y 2)) (content water)))
  (assert (exec (step ?s) (action guess) (x ?x) (y (+ ?y 2))))
  (pop-focus)
)

(defrule guess-next-to-left-2-water (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content left))
  (or (k-cell (x ?x) (y ?ny & :(= (+ ?y 1) ?ny)) (content middle)) 
      (exec (action guess) (x ?x) (y ?ny)))
  (affondati cacciatorpedinieri 3)
  (k-cell (x ?x) (y ?ywater & :(= (+ ?y 3) ?ywater)) (content water))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x) (y ?nny & :(= (+ ?y 2) ?nny))))
  =>
  (assert (k-cell (x (+ ?x 1)) (y (+ ?y 2)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (+ ?y 2)) (content water)))
  (assert (exec (step ?s) (action guess) (x ?x) (y (+ ?y 2))))
  (pop-focus)
)

(defrule guess-next-to-left-2-biggest-boat (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content left))
  (or (k-cell (x ?x) (y ?ny & :(= (+ ?y 1) ?ny)) (content middle)) 
      (exec (action guess) (x ?x) (y ?ny)))
  (affondati cacciatorpedinieri 3)
  (affondati corazzate 1)
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x) (y ?nny & :(= (+ ?y 2) ?nny))))
  =>
  (assert (k-cell (x (+ ?x 1)) (y (+ ?y 2)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (+ ?y 2)) (content water)))
  (assert (k-cell (x ?x) (y (+ ?y 3)) (content water)))
  (assert (exec (step ?s) (action guess) (x ?x) (y (+ ?y 2))))
  (pop-focus)
)

(defrule guess-next-to-left-2-default (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content left))
  (or (k-cell (x ?x) (y ?ny & :(= (+ ?y 1) ?ny)) (content middle)) 
      (exec (action guess) (x ?x) (y ?ny)))
  (affondati cacciatorpedinieri 3)
  (test (<= (+ ?y 3) 9))
  (not (affondati corazzate 1))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x) (y ?nny & :(= (+ ?y 2) ?nny))))
  =>
  (assert (k-cell (x (+ ?x 1)) (y (+ ?y 2)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (+ ?y 2)) (content water)))
  (assert (exec (step ?s) (action guess) (x ?x) (y (+ ?y 2))))
  (pop-focus)
)

(defrule guess-next-to-right-2-border (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content right))
  (or (k-cell (x ?x) (y ?ny & :(= (- ?y 1) ?ny)) (content middle)) 
      (exec (action guess) (x ?x) (y ?ny)))
  (affondati cacciatorpedinieri 3)
  (test (< (- ?y 3) 0))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x) (y ?nny & :(= (- ?y 2) ?nny))))
  =>
  (assert (k-cell (x (+ ?x 1)) (y (- ?y 2)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (- ?y 2)) (content water)))
  (assert (exec (step ?s) (action guess) (x ?x) (y (- ?y 2))))
  (pop-focus)
)

(defrule guess-next-to-right-2-water (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content right))
  (or (k-cell (x ?x) (y ?ny & :(= (- ?y 1) ?ny)) (content middle)) 
      (exec (action guess) (x ?x) (y ?ny)))
  (affondati cacciatorpedinieri 3)
  (k-cell (x ?x) (y ?ywater & :(= (- ?y 3) ?ywater)) (content water))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x) (y ?nny & :(= (- ?y 2) ?nny))))
  =>
  (assert (k-cell (x (+ ?x 1)) (y (- ?y 2)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (- ?y 2)) (content water)))
  (assert (exec (step ?s) (action guess) (x ?x) (y (- ?y 2))))
  (pop-focus)
)

(defrule guess-next-to-right-2-biggest-boat (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content right))
  (or (k-cell (x ?x) (y ?ny & :(= (- ?y 1) ?ny)) (content middle)) 
      (exec (action guess) (x ?x) (y ?ny)))
  (affondati cacciatorpedinieri 3)
  (affondati corazzate 1)
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x) (y ?nny & :(= (- ?y 2) ?nny))))
  =>
  (assert (k-cell (x (+ ?x 1)) (y (- ?y 2)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (- ?y 2)) (content water)))
  (assert (k-cell (x ?x) (y (- ?y 3)) (content water)))
  (assert (exec (step ?s) (action guess) (x ?x) (y (- ?y 2))))
  (pop-focus)
)

(defrule guess-next-to-right-2-default (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content right))
  (or (k-cell (x ?x) (y ?ny & :(= (- ?y 1) ?ny)) (content middle)) 
      (exec (action guess) (x ?x) (y ?ny)))
  (affondati cacciatorpedinieri 3)
  (test (>= (- ?y 3) 0))
  (not (affondati corazzate 1))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x) (y ?nny & :(= (- ?y 2) ?nny))))
  =>
  (assert (k-cell (x (+ ?x 1)) (y (- ?y 2)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (- ?y 2)) (content water)))
  (assert (exec (step ?s) (action guess) (x ?x) (y (- ?y 2))))
  (pop-focus)
)

(defrule guess-above-middle-ver-border-or-water-biggest-boat (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content middle))
  (or (k-cell (x ?x) (y ?y1 & :(= (+ ?y 1) ?y1)) (content water))
      (k-cell (x ?x) (y ?y1 & :(= (- ?y 1) ?y1)) (content water))
      (test (> (+ ?y 1) 9))
      (test (< (- ?y 1) 0)))
  (affondati corazzate 1)
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x1 & :(= (- ?x 1) ?x1)) (y ?y)))
  =>
  (assert (k-cell (x (- ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (- ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 2)) (y ?y) (content water)))
  (assert (exec (step ?s) (action guess) (x (- ?x 1)) (y ?y)))
  (pop-focus)
)

(defrule guess-under-middle-ver-border-or-water-biggest-boat (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content middle))
  (or (k-cell (x ?x) (y ?y1 & :(= (+ ?y 1) ?y1)) (content water))
      (k-cell (x ?x) (y ?y1 & :(= (- ?y 1) ?y1)) (content water))
      (test (> (+ ?y 1) 9))
      (test (< (- ?y 1) 0)))
  (affondati corazzate 1)
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x1 & :(= (+ ?x 1) ?x1)) (y ?y)))
  =>
  (assert (k-cell (x (+ ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 1)) (y (- ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 2)) (y ?y) (content water)))
  (assert (exec (step ?s) (action guess) (x (+ ?x 1)) (y ?y)))
  (pop-focus)
)

(defrule guess-above-middle-ver-border-or-water-default (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content middle))
  (or (k-cell (x ?x) (y ?y1 & :(= (+ ?y 1) ?y1)) (content water))
      (k-cell (x ?x) (y ?y1 & :(= (- ?y 1) ?y1)) (content water))
      (test (> (+ ?y 1) 9))
      (test (< (- ?y 1) 0)))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x1 & :(= (- ?x 1) ?x1)) (y ?y)))
  =>
  (assert (k-cell (x (- ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (- ?x 1)) (y (- ?y 1)) (content water)))
  (assert (exec (step ?s) (action guess) (x (- ?x 1)) (y ?y)))
  (pop-focus)
)

(defrule guess-under-middle-ver-border-or-water-default (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content middle))
  (or (k-cell (x ?x) (y ?y1 & :(= (+ ?y 1) ?y1)) (content water))
      (k-cell (x ?x) (y ?y1 & :(= (- ?y 1) ?y1)) (content water))
      (test (> (+ ?y 1) 9))
      (test (< (- ?y 1) 0)))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x1 & :(= (+ ?x 1) ?x1)) (y ?y)))
  =>
  (assert (k-cell (x (+ ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 1)) (y (- ?y 1)) (content water)))
  (assert (exec (step ?s) (action guess) (x (+ ?x 1)) (y ?y)))
  (pop-focus)
)

(defrule guess-right-of-middle-hor-border-or-water-biggest-boat (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content middle))
  (or (k-cell (x ?x1 & :(= (+ ?x 1) ?x1)) (y ?y) (content water))
      (k-cell (x ?x1 & :(= (- ?x 1) ?x1)) (y ?y) (content water))
      (test (> (+ ?x 1) 9))
      (test (< (- ?x 1) 0)))
  (affondati corazzate 1)
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x) (y ?y1 & :(= (+ ?y 1) ?y1))))
  =>
  (assert (k-cell (x (- ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x ?x) (y (+ ?y 2)) (content water)))
  (assert (exec (step ?s) (action guess) (x ?x) (y (+ ?y 1))))
  (pop-focus)
)

(defrule guess-left-of-middle-hor-border-or-water-biggest-boat (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content middle))
  (or (k-cell (x ?x1 & :(= (+ ?x 1) ?x1)) (y ?y) (content water))
      (k-cell (x ?x1 & :(= (- ?x 1) ?x1)) (y ?y) (content water))
      (test (> (+ ?y 1) 9))
      (test (< (- ?y 1) 0)))
  (affondati corazzate 1)
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x) (y ?y1 & :(= (- ?y 1) ?y1))))
  =>
  (assert (k-cell (x (- ?x 1)) (y (- ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 1)) (y (- ?y 1)) (content water)))
  (assert (k-cell (x ?x) (y (- ?y 2)) (content water)))
  (assert (exec (step ?s) (action guess) (x ?x) (y (- ?y 1))))
  (pop-focus)
)

(defrule guess-right-of-middle-hor-border-or-water-default (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content middle))
  (or (k-cell (x ?x1 & :(= (+ ?x 1) ?x1)) (y ?y) (content water))
      (k-cell (x ?x1 & :(= (- ?x 1) ?x1)) (y ?y) (content water))
      (test (> (+ ?x 1) 9))
      (test (< (- ?x 1) 0)))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x) (y ?y1 & :(= (+ ?y 1) ?y1))))
  =>
  (assert (k-cell (x (- ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 1)) (y (+ ?y 1)) (content water)))
  (assert (exec (step ?s) (action guess) (x ?x) (y (+ ?y 1))))
  (pop-focus)
)

(defrule guess-left-of-middle-hor-border-or-water-default (declare (salience 30))
  (k-cell (x ?x) (y ?y) (content middle))
  (or (k-cell (x ?x1 & :(= (+ ?x 1) ?x1)) (y ?y) (content water))
      (k-cell (x ?x1 & :(= (- ?x 1) ?x1)) (y ?y) (content water))
      (test (> (+ ?y 1) 9))
      (test (< (- ?y 1) 0)))
  (status (step ?s)(currently running))
	(not (exec (action guess) (x ?x) (y ?y1 & :(= (- ?y 1) ?y1))))
  =>
  (assert (k-cell (x (- ?x 1)) (y (- ?y 1)) (content water)))
  (assert (k-cell (x (+ ?x 1)) (y (- ?y 1)) (content water)))
  (assert (exec (step ?s) (action guess) (x ?x) (y (- ?y 1))))
  (pop-focus)
)

; ---------------------------------------------------------------------
; --- Regole per la fire per completare le informazioni su una nave ---
; ---------------------- Salience 20 ----------------------------------
; ---------------------------------------------------------------------

; se viene trovato un top in (x, y), si fa una fire di (x+2, y) 
(defrule fire-top-k-cell (declare (salience 20))
  (k-cell (x ?x) (y ?y) (content top))
  (test (< ?x 8))

  (k-per-col (col ?y) (num ?n))
  (test (> ?n 0))

  (not (k-cell (x ?newx&:(= ?newx (+ ?x 2))) (y ?y)))
  (not (k-cell (x ?newx3&:(= ?newx3 (+ ?x 1))) (y ?y) (content bot)))
  (not (exec (action fire) (x ?newx2&:(= ?newx2 (+ ?x 2))) (y ?y)))

  ;se fossero state già trovate entrambe le navi da 3 e da 4 caselle, non avrebbe senso fare una fire sulla casella
  (not (affondati incrociatori 2))
  (not (affondati corazzate 1))

  (status (step ?s)(currently running))
	(moves (fires ?nf&:(> ?nf 0))) 
  
  =>

  (assert (exec (step ?s) (action fire) (x (+ ?x 2)) (y ?y))) 
  (pop-focus)
)

; se viene trovato un top in (x, y), si fa una fire di (x-2, y) 
(defrule fire-bot-k-cell (declare (salience 20))
  (k-cell (x ?x) (y ?y) (content bot))
  (test (> ?x 1))

  (k-per-col (col ?y) (num ?n))
  (test (> ?n 0))

  (not (k-cell (x ?newx&:(= ?newx (- ?x 2))) (y ?y))) 
  (not (k-cell (x ?newx3&:(= ?newx3 (- ?x 1))) (y ?y) (content top)))
  (not (exec (action fire) (x ?newx2&:(= ?newx2 (- ?x 2))) (y ?y)))

  ;se fossero state già trovate entrambe le navi, non avrebbe senso fare una fire sulla casella
  (not (affondati incrociatori 2))
  (not (affondati corazzate 1))

  (status (step ?s)(currently running))
	(moves (fires ?nf&:(> ?nf 0))) 
  
  =>

  (assert (exec (step ?s) (action fire) (x (- ?x 2)) (y ?y))) 
  (pop-focus)
)

; se viene trovato un top in (x, y), si fa una fire di (x, y+2) 
(defrule fire-left-k-cell (declare (salience 20))
  (k-cell (x ?x) (y ?y) (content left))
  (test (< ?y 8))

  (k-per-row (row ?x) (num ?n))
  (test (> ?n 0))

  (not (k-cell (x ?x) (y ?newy&:(= ?newy (+ ?y 2))) )) 
  (not (k-cell (x ?x) (y ?newy3&:(= ?newy3 (+ ?y 1)))  (content right)))
  (not (exec (action fire) (x ?x) (y ?newy2&:(= ?newy2 (+ ?y 2)))))

  ;se fossero state già trovate entrambe le navi, non avrebbe senso fare una fire sulla casella
  (not (affondati incrociatori 2))
  (not (affondati corazzate 1))

  (status (step ?s)(currently running))
	(moves (fires ?nf&:(> ?nf 0))) 
  
  =>

  (assert (exec (step ?s) (action fire) (x ?x) (y (+ ?y 2)))) 
  (pop-focus)
)

; se viene trovato un top in (x, y), si fa una fire di (x, y-2) 
(defrule fire-right-k-cell (declare (salience 20))
  (k-cell (x ?x) (y ?y) (content right))
  (test (> ?y 1))

  (k-per-row (row ?x) (num ?n))
  (test (> ?n 0))

  (not (k-cell (x ?x) (y ?newy&:(= ?newy (- ?y 2))) )) 
  (not (k-cell (x ?x) (y ?newy3&:(= ?newy3 (- ?y 1)))  (content left))) 
  (not (exec (action fire) (x ?x) (y ?newy2&:(= ?newy2 (- ?y 2)))))

  ;se fossero state già trovate entrambe le navi, non avrebbe senso fare una fire sulla casella
  (not (affondati incrociatori 2))
  (not (affondati corazzate 1))
  
  (status (step ?s)(currently running))
	(moves (fires ?nf&:(> ?nf 0))) 
  
  =>

  (assert (exec (step ?s) (action fire) (x ?x) (y (- ?y 2)))) 
  (pop-focus)
)
