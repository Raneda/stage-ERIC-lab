% =========================================================
%   ANALYSE — Énergie & Mémoire RS
% =========================================================
clc; clear; close all;

load('canal_twinning.mat');
nb_paires = transmission.nb_paires;

E_GEN = 5; E_TEST = 3; E_HASH = 2; E_TX = 1; E_RX = 1;
M_CLE = 0.5; M_ETAT = 1; M_LOG = 2;

energie_RS_sans_DT = nb_paires * (E_GEN + E_TEST + E_HASH);
energie_RS_avec_DT = nb_paires * (E_TX + E_RX);

memoire_RS_sans_DT = nb_paires * (M_CLE + M_ETAT + M_LOG);
memoire_RS_avec_DT = nb_paires * M_CLE;

figure('Name','Comparaison RS','NumberTitle','off',...
       'Position',[300 200 900 400]);

subplot(1,2,1);
bar([energie_RS_sans_DT, energie_RS_avec_DT]);
set(gca,'XTickLabel',{'RS sans DT','RS avec DT'});
title('Énergie consommée');
ylabel('Unités');
grid on;

subplot(1,2,2);
bar([memoire_RS_sans_DT, memoire_RS_avec_DT]);
set(gca,'XTickLabel',{'RS sans DT','RS avec DT'});
title('Mémoire utilisée');
ylabel('Ko');
grid on;

