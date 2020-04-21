manhattan_distance(pos(Riga, Colonna), Distanza):-
    finale(pos(RigaFinale, ColonnaFinale)),
    DistanzaRigaTemp is RigaFinale - Riga,
    DistanzaRiga is abs(DistanzaRigaTemp),
    DistanzaColonnaTemp is ColonnaFinale - Colonna,
    DistanzaColonna is abs(DistanzaColonnaTemp),
    Distanza is DistanzaRiga + DistanzaColonna.