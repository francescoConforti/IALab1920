;  ---------------------------------------------
;  --- Definizione del modulo e dei template ---
;  ---------------------------------------------
(defmodule AGENT (import MAIN ?ALL) (import ENV ?ALL) (export ?ALL))

;assegna alle righe in cui non sono presenti navi, il contenuto water
(defrule row-empty 
	(k-per-row (row ?x) (num 0))
	(cell (x ?x) (y ?y))
	=>
	(assert(k-cell (x ?x) (y ?y) (content water))) 
)

;assegna alle colonne in cui non sono presenti navi, il contenuto water
(defrule column-empty 
	(k-per-col (col ?y) (num 0))
	(cell (x ?x) (y ?y))
	=>
	(assert(k-cell (x ?x) (y ?y) (content water)))
)
