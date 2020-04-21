


esegui_a_star(Soluzione):-
    iniziale(S),
    manhattan_distance(S, Distanza),
    a_star([nodo(S,[], Distanza)],[],Soluzione).

a_star([nodo(S,AzioniPerS,_)|_],_,AzioniPerS):-
    finale(S),!.

a_star([nodo(S,AzioniPerS,F)|CodaStati],Visitati,Soluzione):-
    findall(Az,applicabile(Az,S),ListaAzioniApplicabili),
    generaStatiFigli(nodo(S,AzioniPerS, _),[S|Visitati],ListaAzioniApplicabili,StatiFigli),
    append(CodaStati,StatiFigli,NuovaCoda),
    sort(3, @=<, NuovaCoda, NuovaCodaOrdinata),
    a_star(NuovaCodaOrdinata,[S|Visitati],Soluzione).



generaStatiFigli(_,_,[],[]).

generaStatiFigli(nodo(S,AzioniPerS,_),Visitati,[Az|AltreAzioni],[nodo(SNuovo,[Az|AzioniPerS], F)|AltriFigli]):-
    trasforma(Az,S,SNuovo),
    \+member(SNuovo,Visitati),
    !,
    manhattan_distance(SNuovo, Distanza),
    length(AzioniPerS, G),
    G1 is G+1,
    F is G1 + Distanza,
    generaStatiFigli(nodo(S,AzioniPerS,_),Visitati,AltreAzioni,AltriFigli).

generaStatiFigli(nodo(S,AzioniPerS,_),Visitati,[_|AltreAzioni],AltriFigli):-
    generaStatiFigli(nodo(S,AzioniPerS,_),Visitati,AltreAzioni,AltriFigli).



