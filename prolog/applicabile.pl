applicabile(est, pos(Riga, Colonna)) :-
    num_colonne(NC),
    Colonna < NC,
    ColonnaAccanto is Colonna+1,
    \+occupata(pos(Riga, ColonnaAccanto)).

applicabile(ovest, pos(Riga, Colonna)) :-
    Colonna > 1,
    ColonnaAccanto is Colonna-1,
    \+occupata(pos(Riga, ColonnaAccanto)).

applicabile(nord, pos(Riga, Colonna)) :- 
    Riga > 1,
    RigaSopra is Riga-1,
    \+occupata(pos(RigaSopra, Colonna)).

applicabile(sud, pos(Riga, Colonna)) :-
    num_righe(NR),
    Riga < NR,
    RigaSotto is Riga+1,
    \+occupata(pos(RigaSotto, Colonna)).

trasforma(est, pos(Riga, Colonna), pos(Riga, ColonnaAccanto)) :-
    ColonnaAccanto is Colonna+1.

trasforma(ovest, pos(Riga, Colonna), pos(Riga, ColonnaAccanto)) :-
    ColonnaAccanto is Colonna-1.

trasforma(nord, pos(Riga, Colonna), pos(RigaAccanto, Colonna)) :-
    RigaAccanto is Riga-1.

trasforma(sud, pos(Riga, Colonna), pos(RigaAccanto, Colonna)) :-
    RigaAccanto is Riga+1.