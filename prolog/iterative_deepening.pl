iterative_deepening(Soluzione, Profondita) :-
  iterative_deepening_aux(Soluzione, 1),
  length(Soluzione, Profondita).

iterative_deepening_aux(Soluzione, SogliaIniziale) :-
  depth_limit_search(Soluzione,SogliaIniziale).

iterative_deepening_aux(Soluzione, SogliaIniziale) :-
  NuovaSoglia is SogliaIniziale+1,
  num_righe(R),
  num_colonne(C),
  SogliaLimite is R*C,
  NuovaSoglia < SogliaLimite,
  iterative_deepening_aux(Soluzione, NuovaSoglia),!.

depth_limit_search(Soluzione, Soglia) :-
  iniziale(S),
  dfs_aux(S, Soluzione, [S], Soglia).

dfs_aux(S, [], _, _) :- finale(S).
dfs_aux(S, [Azione|AzioniTail], Visitati, Soglia) :-
  Soglia>0,
  applicabile(Azione, S),
  trasforma(Azione, S, SNuovo),
  \+member(SNuovo, Visitati),
  NuovaSoglia is Soglia-1,
  dfs_aux(SNuovo, AzioniTail, [SNuovo|Visitati], NuovaSoglia).