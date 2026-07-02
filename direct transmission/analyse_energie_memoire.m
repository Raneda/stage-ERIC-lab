% =========================================================
%   ANALYSE — Énergie & Mémoire RS (modèle final)
% =========================================================
clc; clear; close all;

load('canal_twinning.mat');
nb_paires = transmission.nb_paires;

% -----------------------------
% Coûts énergétiques (unités)
% -----------------------------
E_GEN = 5;      % Génération de clé (DT dans le modèle sans DT)
E_TEST = 3;     % Test de clé
E_HASH = 2;     % Hachage d'état
E_RS_RS = 6;    % Transmission radio RS <-> RS
E_RS_DT = 2;    % Transmission ID RS -> DT
E_DT_RS = 3;    % Transmission clé DT -> RS

% -----------------------------
% Coûts mémoire (Ko)
% -----------------------------
M_CLE  = 0.2;   % Stockage clé AES128 + hash + ID
M_ETAT = 0.21;  % Stockage état de nœud
M_LOG  = 0.6;   % Stockage log DT

% =========================================================
%   CALCULS
% =========================================================

% RS SANS DT : tout est fait dans le RS
energie_RS_sans_DT = nb_paires * (E_GEN + E_TEST + E_HASH + E_RS_RS);
memoire_RS_sans_DT = nb_paires * (M_CLE + M_ETAT + M_LOG);

% RS AVEC DT : le RS ne fait que transmettre ID et recevoir clé
energie_RS_avec_DT = nb_paires * (E_RS_DT + E_DT_RS);
memoire_RS_avec_DT = nb_paires * M_CLE;

% =========================================================
%   FIGURES
% =========================================================
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

fprintf('\n>>> ANALYSE ÉNERGIE/MÉMOIRE\n');
fprintf('    Énergie RS sans DT : %.2f unités\n', energie_RS_sans_DT);
fprintf('    Énergie RS avec DT : %.2f unités\n', energie_RS_avec_DT);
fprintf('    Mémoire RS sans DT : %.2f Ko\n', memoire_RS_sans_DT);
fprintf('    Mémoire RS avec DT : %.2f Ko\n', memoire_RS_avec_DT);
