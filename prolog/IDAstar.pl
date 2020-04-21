:-dynamic(minF/1).

idaStar(Soluzione, Profondita) :-
  iniziale(S),
  euristica(S, SogliaIniziale),
  num_righe(R),
  num_colonne(C),
  SogliaLimite is R*C,
  SogliaIniziale < SogliaLimite,
  retractall(minF(_)),
  assert(minF(SogliaLimite)),
  idaStar_aux(Soluzione, SogliaIniziale),
  length(Soluzione, Profondita).

idaStar_aux(Soluzione, SogliaIniziale) :-
  depth_limit_search(Soluzione,SogliaIniziale).

idaStar_aux(Soluzione, _) :-
  minF(NuovaSoglia),
  num_righe(R),
  num_colonne(C),
  SogliaLimite is R*C,
  NuovaSoglia < SogliaLimite,
  retractall(minF(_)),
  assert(minF(SogliaLimite)),
  idaStar_aux(Soluzione, NuovaSoglia),!.

depth_limit_search(Soluzione, Soglia) :-
  iniziale(S),
  dfs_aux(S, Soluzione, [S], Soglia).

dfs_aux(S, [], _, _) :- finale(S).
dfs_aux(S, [Azione|AzioniTail], Visitati, Soglia) :-
  length(Visitati, LenVisitati),
  G is LenVisitati - 1,
  euristica(S, H),
  F is G + H,
  F =< Soglia, !,
  applicabile(Azione, S),
  trasforma(Azione, S, SNuovo),
  \+member(SNuovo, Visitati),
  dfs_aux(SNuovo, AzioniTail, [SNuovo|Visitati], Soglia).
dfs_aux(S, _, Visitati, _):-
  length(Visitati, LenVisitati),
  G is LenVisitati - 1,
  euristica(S, H),
  F is G + H,
  minF(Min),
  F < Min,
  retractall(minF(_)),
  assert(minF(F)),
  !, fail.

