manhattan_distance(pos(Riga, Colonna), Distanza):-
    finale(pos(RigaFinale, ColonnaFinale)),
    DistanzaRigaTemp is RigaFinale - Riga,
    DistanzaRiga is abs(DistanzaRigaTemp),
    DistanzaColonnaTemp is ColonnaFinale - Colonna,
    DistanzaColonna is abs(DistanzaColonnaTemp),
    Distanza is DistanzaRiga + DistanzaColonna.

:-dynamic(costo_cammino/1).
costo_cammino(0).



prova(Soluzione):-
    iniziale(S),
    manhattan_distance(S, Distanza),
    esegui(Soluzione, Distanza).

prova(Soluzione):-
    NuovaProfondita is Distanza,
    prova(Soluzione, NuovaDistanza), !.
    
esegui(Soluzione, Limite):-
    iniziale(S),
    iterative_deepening(S, [], Limite, Soluzione).

aiterative_deepening(S,_,_,[]):-
    finale(S),!.

iterative_deepening(S,Visitati,Limite,[Az|SequenzaAzioni]):-
    Limite>0,
    applicabile(Az,S),
    trasforma(Az,S,SNuovo),
    \+member(SNuovo,Visitati),
    costo_cammino(N),
    N1 is N+1,
    retractall(costo_cammino(_)),
    assert(costo_cammino(N1)),
    NuovoLimite is Limite-1,
    iterative_deepening(SNuovo,[S|Visitati],NuovoLimite,SequenzaAzioni).

iterative_deepening(S,Visitati,Limite,[Az|SequenzaAzioni]):-
    Limite=0,
    min_value(S, Min),
    costo_cammino(N),
    NuovoLimite is Min + N,
    iterative_deepening(SNuovo,[S|Visitati],NuovoLimite,SequenzaAzioni).

   
