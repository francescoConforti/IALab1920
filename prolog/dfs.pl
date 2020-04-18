% depth_search(Soluzione)
depth_search(Soluzione):-
    iniziale(S),
    dfs(S,Soluzione,[S]).

% dfs(S,Soluzione)
dfs(S,[],_):-finale(S),!.
dfs(S,[Az|SequenzaAzioni],Visitati):-
    applicabile(Az,S),
    trasforma(Az,S,S_Nuovo),
    \+member(S_Nuovo,Visitati),
    dfs(S_Nuovo,SequenzaAzioni,[S_Nuovo|Visitati]).

