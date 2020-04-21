manhattan_distance(pos(Riga, Colonna), Distanza):-
    finale(pos(RigaFinale, ColonnaFinale)),
    DistanzaRigaTemp is RigaFinale - Riga,
    DistanzaRiga is abs(DistanzaRigaTemp),
    DistanzaColonnaTemp is ColonnaFinale - Colonna,
    DistanzaColonna is abs(DistanzaColonnaTemp),
    Distanza is DistanzaRiga + DistanzaColonna.



pitagora_distance(pos(Riga, Colonna), Distanza):-
    finale(pos(RigaFinale, ColonnaFinale)),
    DistanzaRigaTemp is RigaFinale - Riga,
    DistanzaRigaTemp2 is DistanzaRigaTemp * DistanzaRigaTemp,
    DistanzaColonnaTemp is ColonnaFinale - Colonna,
    DistanzaColonnaTemp2 is DistanzaColonnaTemp * DistanzaColonnaTemp,
    DistanzaTemp is DistanzaColonnaTemp2 + DistanzaRigaTemp2,
    sqrt(DistanzaTemp, Distanza).
    

euristica(pos(Riga, Colonna), Distanza):-
    pitagora_distance(pos(Riga, Colonna), Distanza).