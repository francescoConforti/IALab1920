% *******************************************
%                   DOCENTI
% *******************************************
docente(muzzetto).
docente(pozzato).
docente(gena).
docente(tomatis).
docente(micalizio).
docente(terranova).
docente(mazzei).
docente(giordani).
docente(zanchetta).
docente(vargiu).
docente(boniolo).
docente(damiano).
docente(suppini).
docente(valle).
docente(ghidelli).
docente(gabardi).
docente(santangelo).
docente(taddeo).
docente(gribaudo).
docente(schifanella).
docente(lombardo).
docente(travostino).

% *********************************************
%           INSEGNAMENTI
% *********************************************

insegnamento(project_management, muzzetto, 14).
insegnamento(fondamenti_di_ICT_e_paradigmi_di_programmazione, pozzato, 14).
insegnamento(linguaggi_di_markup, gena, 20).
insegnamento(la_gestione_della_qualita, tomatis, 10).
insegnamento(ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web, micalizio, 20).
insegnamento(progettazione_grafica_e_design_di_interfacce, terranova, 10).
insegnamento(progettazione_di_basi_di_dati, mazzei, 20).
insegnamento(strumenti_e_metodi_di_interazione_nei_social_media, giordani, 14).
insegnamento(acquisizione_ed_elaborazione_di_immagini_statiche_grafica, zanchetta, 14).
insegnamento(accessibilita_e_usabilita_nella_progettazione_multimediale, gena, 14).
insegnamento(marketing_digitale, muzzetto, 10).
insegnamento(elementi_di_fotografia_digitale, vargiu, 10).
insegnamento(risorse_digitali_per_il_progetto_collaborazione_e_documentazione, boniolo, 10).
insegnamento(tecnologie_server_side_per_il_web, damiano, 20).
insegnamento(tecniche_e_strumenti_di_marketing_digitale, zanchetta, 10).
insegnamento(introduzione_al_social_media_management, suppini, 14).
insegnamento(acquisizione_ed_elaborazione_del_suono, valle, 10).
insegnamento(acquisizione_ed_elaborazione_di_sequenze_di_immagini_digitali, ghidelli, 20).
insegnamento(comunicazione_pubblicitaria_e_comunicazione_pubblica, gabardi, 14).
insegnamento(semiologia_e_multimedialita, santangelo, 10).
insegnamento(crossmedia_articolazione_delle_scritture_multimediali, taddeo, 20).
insegnamento(grafica_3d, gribaudo, 20).
insegnamento(progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_I, pozzato, 10).
insegnamento(progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_II, schifanella, 10).
insegnamento(la_gestione_delle_risorse_umane, lombardo, 10).
insegnamento(i_vincoli_giuridici_del_progetto_diritto_dei_media, travostino, 10).

corso(C) :- insegnamento(C, _, _).

% ***********************************************************************************
%                                   SETTIMANE
% ***********************************************************************************

settimane(24).
settimana(1..S) :- settimane(S).
giorni(6).
giorno(1..G) :- giorni(G). % lunedi...sabato
ore(8).
ora(1..O) :- ore(O).
% haOre(giorno, settimana, ore)
1 { haOre(5, S, 8) } 1 :- settimana(S).  % venerdì ha 8 ore tutte le settimane
1 { haOre(6, S, O) : O = (4;5) } 1 :- settimana(S).  % sabato ha 4 o 5 ore tutte le settimane
1 { haOre(G, 7, 8) } 1 :- G = 1..4. % settimana 7 tutti i giorni da lunedì a giovedì hanno 8 ore
1 { haOre(G, 16, 8) } 1 :- G = 1..4.  % settimana 16 tutti i giorni da lunedì a giovedì hanno 8 ore

% **************************************************************************************
%                                   ASSEGNAMENTI
% **************************************************************************************

% assegna(Corso, Settimana, Giorno, Ora)
% assegno a ogni corso il numero di ore che gli spetta
OreMax { assegna(Corso, S, G, O) : haOre(G, S, OreDelGiorno), ora(O), O <= OreDelGiorno } OreMax :- insegnamento(Corso, _, OreMax).
% due corsi non possono essere la stessa ora
:- assegna(Corso1, S, G, O), assegna(Corso2, S, G, O), Corso1 != Corso2.
% un docente non può fare due corsi nella stessa ora  [inutile perchè c'è un'aula sola]
% :- assegna(Corso1, S, G, O), assegna(Corso2, S, G, O), insegnamento(Corso1, Docente, _), insegnamento(Corso2, Docente, _), Corso1 != Corso2.

% **************************************************************************************
%                                   VINCOLI RIGIDI
% **************************************************************************************

% lo stesso docente non può svolgere più di 4 ore di lezione in un giorno
:- not { assegna(Corso, S, G, O) : insegnamento(Corso, D, _), ora(O), O <= OreDelGiorno} 4, haOre(G, S, OreDelGiorno), docente(D).

% a ciascun insegnamento vengono assegnate minimo 2 e massimo 4 ore nello stesso giorno
:- not 2 { assegna(Corso, S, G, O) : ora(O), haOre(G, S, OreDelGiorno), O <= OreDelGiorno } 4, assegna(Corso, S, G, _).

% l’insegnamento “Project Management” deve concludersi non oltre la prima settimana full-time
:- assegna(project_management, S, G, O), S>7.

%le prime due ore di lezione sono dedicate alla presentazione del corso
assegna(presentazione_del_corso, 1, 5, 1).
assegna(presentazione_del_corso, 1, 5, 2).

% il calendario deve prevedere almeno 2 blocchi liberi di 2 ore ciascuno per eventuali recuperi di lezioni annullate o rinviate
2 {recupero(S, G, O) : haOre(G, S, OreDelGiorno), ora(O), O < OreDelGiorno }.
:- recupero(S, G, O), recupero(S, G, O+1).
assegna(recupero, S, G, O) :- recupero(S, G, O).
assegna(recupero, S, G, O+1) :- recupero(S, G, O).

% propedeuticità
% propedeutico(InsegnamentoPrecedente, InsegnamentoSuccessivo)
propedeutico(fondamenti_di_ICT_e_paradigmi_di_programmazione, ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web).
propedeutico(ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web, progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_I).
propedeutico(progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_I, progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_II).
propedeutico(progettazione_di_basi_di_dati, tecnologie_server_side_per_il_web).
propedeutico(linguaggi_di_markup, ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web).
propedeutico(project_management, marketing_digitale).
propedeutico(marketing_digitale, tecniche_e_strumenti_di_marketing_digitale).
propedeutico(project_management, strumenti_e_metodi_di_interazione_nei_social_media).
propedeutico(project_management, progettazione_grafica_e_design_di_interfacce).
propedeutico(acquisizione_ed_elaborazione_di_immagini_statiche_grafica, elementi_di_fotografia_digitale).
propedeutico(elementi_di_fotografia_digitale, acquisizione_ed_elaborazione_di_sequenze_di_immagini_digitali).
propedeutico(acquisizione_ed_elaborazione_di_immagini_statiche_grafica, grafica_3d).

%vincolo di propedeuticità
:- assegna(Corso1, Settimana1, _, _), assegna(Corso2, Settimana2, _, _), propedeutico(Corso1, Corso2), Settimana1 > Settimana2.
:- assegna(Corso1, Settimana, Giorno1, _), assegna(Corso2, Settimana, Giorno2, _), propedeutico(Corso1, Corso2), Giorno1>Giorno2.
:- assegna(Corso1, Settimana, Giorno, Ora1), assegna(Corso2, Settimana, Giorno, Ora2), propedeutico(Corso1, Corso2), Ora1>Ora2.

%la prima lezione di accessibilita_e_usabilita_nella_progettazione_multimediale deve essere collocata prima dell'ultima lezione di linguaggi_di_markup
:- assegna(accessibilita_e_usabilita_nella_progettazione_multimediale, S, G, O), assegna(linguaggi_di_markup, S1, G1, O1), S1>=S, G1>=G, O1>O.

% ******************************************************************************
%                         VINCOLI AUSPICABILI
% ******************************************************************************

% le lezioni dei vari insegnamenti devono rispettare le seguenti propedeuticità, in particolare la prima lezione dell’insegnamento 
% della colonna di destra deve essere successiva alle prime 4 ore di lezione del corrispondente insegnamento della colonna di sinistra
% propedeutico2(fondamenti_di_ICT_e_paradigmi_di_programmazione, progettazione_di_basi_di_dati).
% propedeutico2(tecniche_e_strumenti_di_marketing_digitale, introduzione_al_social_media_management).
% propedeutico2(comunicazione_pubblicitaria_e_comunicazione_pubblica, la_gestione_delle_risorse_umane).
% propedeutico2(tecnologie_server_side_per_il_web, progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_I).

% la distanza fra l’ultima lezione di “Progettazione e sviluppo di applicazioni web su dispositivi mobile I” e
% la prima di “Progettazione e sviluppo di applicazioni web su dispositivi mobile II” non deve superare le due settimane
vincoloProgrammazioneMobile :- assegna(progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_I, S1, _, _),
                               assegna(progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_II, S2, _, _),
                               S2 < S1 +2.

vincoloProgrammazioneMobile :- assegna(progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_I, S1, G1, _),
                               assegna(progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_II, S2, G2, _),
                               S2 <= S1 +2, G2 <= G1.

:- not vincoloProgrammazioneMobile.

% la distanza tra la prima e l’ultima lezione di ciascun insegnamento non deve superare le 6 settimane
:-assegna(Corso, S, G, O), assegna(Corso, S1, G1, O1), |S1-S|>6 .

% la prima lezione degli insegnamenti “Crossmedia: articolazione delle scritture multimediali” deve essere collocata nella seconda settimana full-time
:- assegna(crossmedia_articolazione_delle_scritture_multimediali, S, G, O), S<16.
vincolo_1:- assegna(crossmedia_articolazione_delle_scritture_multimediali, S, G, O), S==16.
:- not vincolo_1.

% la prima lezione degli insegnamenti “Introduzione al social media management” deve essere collocata nella seconda settimana full-time
:- assegna(introduzione_al_social_media_management, S, G, O), S<16.
vincolo_2:- assegna(introduzione_al_social_media_management, S, G, O), S==16.
:- not vincolo_2.

#show assegna/4.