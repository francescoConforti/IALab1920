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

settimane(3).
settimana(1..S) :- settimane(S).
giorni(6).
giorno(1..G) :- giorni(G). % lunedi...sabato
ore(8).
ora(1..O) :- ore(O).
% haOre(giorno, settimana, ore)
N { haOre(5, S, 8) : settimana(S) } N :- settimane(N).  % venerdì ha 8 ore tutte le settimane
N { haOre(6, S, O) : settimana(S), O = (4;5) } N :- settimane(N).  % sabato ha 4 o 5 ore tutte le settimane
1 { haOre(6, S, O) : ora(O) } 1 :- settimana(S). 
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
% un docente non può fare due corsi nella stessa ora
:- assegna(Corso1, S, G, O), assegna(Corso2, S, G, O), insegnamento(Corso1, Docente, _), insegnamento(Corso2, Docente, _), Corso1 != Corso2.

% **************************************************************************************
%                                   VINCOLI RIGIDI
% **************************************************************************************

% a ciascun insegnamento vengono assegnate minimo 2 e massimo 4 ore nello stesso giorno
2 { assegna(Corso, S, G, O) : ora(O), haOre(G, S, OreDelGiorno), O <= OreDelGiorno } 4 :- assegna(Corso, S, G, _).

% l’insegnamento “Project Management” deve concludersi non oltre la prima settimana full-time
:- assegna(project_management, S, G, O), S>7.

%le prime due ore di lezione sono dedicate alla presentazione del corso
assegna(presentazione_del_corso, 1, 5, 1).
assegna(presentazione_del_corso, 1, 5, 2).

% propedeuticità fondamenti_di_ICT_e_paradigmi_di_programmazione -> ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web
:- assegna(fondamenti_di_ICT_e_paradigmi_di_programmazione, Settimana1, _, _), assegna(ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web, Settimana2, _, _), Settimana1 > Settimana2.
:- assegna(fondamenti_di_ICT_e_paradigmi_di_programmazione, Settimana, Giorno1, _), assegna(ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web, Settimana, Giorno2, _), Giorno1>Giorno2.
:- assegna(fondamenti_di_ICT_e_paradigmi_di_programmazione, Settimana, Giorno, Ora1), assegna(ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web, Settimana, Giorno, Ora2), Ora1>Ora2.

%propedeuticità ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web -> progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_I
:- assegna(ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web, Settimana1, _, _), assegna(progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_I, Settimana2, _, _), Settimana1 > Settimana2.
:- assegna(ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web, Settimana, Giorno1, _), assegna(progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_I, Settimana, Giorno2, _), Giorno1>Giorno2.
:- assegna(ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web, Settimana, Giorno, Ora1), assegna(progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_I, Settimana, Giorno, Ora2), Ora1>Ora2.

%propedeuticità progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_I -> progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_II
:- assegna(progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_I, Settimana1, _, _), assegna(progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_II, Settimana2, _, _), Settimana1 > Settimana2.
:- assegna(progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_I, Settimana, Giorno1, _), assegna(progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_II, Settimana, Giorno2, _), Giorno1>Giorno2.
:- assegna(progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_I, Settimana, Giorno, Ora1), assegna(progettazione_e_sviluppo_di_applicazioni_web_su_dispositivi_mobile_II, Settimana, Giorno, Ora2), Ora1>Ora2.

%propedeuticità progettazione_di_basi_di_dati -> tecnologie_server_side_per_il_web
:- assegna(progettazione_di_basi_di_dati, Settimana1, _, _), assegna(tecnologie_server_side_per_il_web, Settimana2, _, _), Settimana1 > Settimana2.
:- assegna(progettazione_di_basi_di_dati, Settimana, Giorno1, _), assegna(tecnologie_server_side_per_il_web, Settimana, Giorno2, _), Giorno1>Giorno2.
:- assegna(progettazione_di_basi_di_dati, Settimana, Giorno, Ora1), assegna(tecnologie_server_side_per_il_web, Settimana, Giorno, Ora2), Ora1>Ora2.

%propedeuticità linguaggi_di_markup -> ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web
:- assegna(linguaggi_di_markup, Settimana1, _, _), assegna(ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web, Settimana2, _, _), Settimana1 > Settimana2.
:- assegna(linguaggi_di_markup, Settimana, Giorno1, _), assegna(ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web, Settimana, Giorno2, _), Giorno1>Giorno2.
:- assegna(linguaggi_di_markup, Settimana, Giorno, Ora1), assegna(ambienti_di_sviluppo_e_linguaggi_client_side_per_il_web, Settimana, Giorno, Ora2), Ora1>Ora2.

%propedeuticità project_management -> marketing_digitale
:- assegna(project_management, Settimana1, _, _), assegna(marketing_digitale, Settimana2, _, _), Settimana1 > Settimana2.
:- assegna(project_management, Settimana, Giorno1, _), assegna(marketing_digitale, Settimana, Giorno2, _), Giorno1>Giorno2.
:- assegna(project_management, Settimana, Giorno, Ora1), assegna(marketing_digitale, Settimana, Giorno, Ora2), Ora1>Ora2.

%propedeuticità marketing_digitale -> tecniche_e_strumenti_di_marketing_digitale
:- assegna(marketing_digitale, Settimana1, _, _), assegna(tecniche_e_strumenti_di_marketing_digitale, Settimana2, _, _), Settimana1 > Settimana2.
:- assegna(marketing_digitale, Settimana, Giorno1, _), assegna(tecniche_e_strumenti_di_marketing_digitale, Settimana, Giorno2, _), Giorno1>Giorno2.
:- assegna(marketing_digitale, Settimana, Giorno, Ora1), assegna(tecniche_e_strumenti_di_marketing_digitale, Settimana, Giorno, Ora2), Ora1>Ora2.

%propedeuticità project_management -> strumenti_e_metodi_di_interazione_nei_social_media
:- assegna(project_management, Settimana1, _, _), assegna(strumenti_e_metodi_di_interazione_nei_social_media, Settimana2, _, _), Settimana1 > Settimana2.
:- assegna(project_management, Settimana, Giorno1, _), assegna(strumenti_e_metodi_di_interazione_nei_social_media, Settimana, Giorno2, _), Giorno1>Giorno2.
:- assegna(project_management, Settimana, Giorno, Ora1), assegna(strumenti_e_metodi_di_interazione_nei_social_media, Settimana, Giorno, Ora2), Ora1>Ora2.

%propedeuticità project_management -> progettazione_grafica_e_design_di_interfacce
:- assegna(project_management, Settimana1, _, _), assegna(progettazione_grafica_e_design_di_interfacce, Settimana2, _, _), Settimana1 > Settimana2.
:- assegna(project_management, Settimana, Giorno1, _), assegna(progettazione_grafica_e_design_di_interfacce, Settimana, Giorno2, _), Giorno1>Giorno2.
:- assegna(project_management, Settimana, Giorno, Ora1), assegna(progettazione_grafica_e_design_di_interfacce, Settimana, Giorno, Ora2), Ora1>Ora2.

%propedeuticità acquisizione_ed_elaborazione_di_immagini_statiche_grafica -> elementi_di_fotografia_digitale
:- assegna(acquisizione_ed_elaborazione_di_immagini_statiche_grafica, Settimana1, _, _), assegna(elementi_di_fotografia_digitale, Settimana2, _, _), Settimana1 > Settimana2.
:- assegna(acquisizione_ed_elaborazione_di_immagini_statiche_grafica, Settimana, Giorno1, _), assegna(elementi_di_fotografia_digitale, Settimana, Giorno2, _), Giorno1>Giorno2.
:- assegna(acquisizione_ed_elaborazione_di_immagini_statiche_grafica, Settimana, Giorno, Ora1), assegna(elementi_di_fotografia_digitale, Settimana, Giorno, Ora2), Ora1>Ora2.

%propedeuticità elementi_di_fotografia_digitale -> acquisizione_ed_elaborazione_di_sequenze_di_immagini_digitali
:- assegna(elementi_di_fotografia_digitale, Settimana1, _, _), assegna(acquisizione_ed_elaborazione_di_sequenze_di_immagini_digitali, Settimana2, _, _), Settimana1 > Settimana2.
:- assegna(elementi_di_fotografia_digitale, Settimana, Giorno1, _), assegna(acquisizione_ed_elaborazione_di_sequenze_di_immagini_digitali, Settimana, Giorno2, _), Giorno1>Giorno2.
:- assegna(elementi_di_fotografia_digitale, Settimana, Giorno, Ora1), assegna(acquisizione_ed_elaborazione_di_sequenze_di_immagini_digitali, Settimana, Giorno, Ora2), Ora1>Ora2.

%propedeuticità acquisizione_ed_elaborazione_di_immagini_statiche_grafica -> grafica_3d
:- assegna(acquisizione_ed_elaborazione_di_immagini_statiche_grafica, Settimana1, _, _), assegna(grafica_3d, Settimana2, _, _), Settimana1 > Settimana2.
:- assegna(acquisizione_ed_elaborazione_di_immagini_statiche_grafica, Settimana, Giorno1, _), assegna(grafica_3d, Settimana, Giorno2, _), Giorno1>Giorno2.
:- assegna(acquisizione_ed_elaborazione_di_immagini_statiche_grafica, Settimana, Giorno, Ora1), assegna(grafica_3d, Settimana, Giorno, Ora2), Ora1>Ora2.


                                        

#show assegna/4.
