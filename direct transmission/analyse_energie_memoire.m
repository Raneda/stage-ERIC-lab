% =========================================================
%   ANALYSE — Énergie & Mémoire RS (modèle final)
%   Tous les graphiques dans UNE SEULE fenêtre
% =========================================================
clc; clear; close all;

% Charger les données de la simulation
load('canal_twinning.mat');
nb_paires = transmission.nb_paires;

% -----------------------------
% Coûts énergétiques (unités)
% -----------------------------
E_GEN   = 5;   % Génération de clé
E_TEST  = 3;   % Test de clé
E_HASH  = 2;   % Hachage d'état
E_RS_RS = 6;   % Transmission radio RS <-> RS
E_RS_DT = 2;   % Transmission ID RS -> DT
E_DT_RS = 3;   % Transmission clé DT -> RS

% -----------------------------
% Coûts mémoire (Ko)
% -----------------------------
M_CLE  = 0.2;   % Stockage clé AES128 + hash + ID
M_ETAT = 0.21;  % Stockage état de nœud
M_LOG  = 0.6;   % Stockage log DT

% =========================================================
%   CALCULS — RS sans DT / RS avec DT
% =========================================================

energie_RS_sans_DT = nb_paires * (E_GEN + E_TEST + E_HASH + E_RS_RS);
memoire_RS_sans_DT = nb_paires * (M_CLE + M_ETAT + M_LOG);

energie_RS_avec_DT = nb_paires * (E_RS_DT + E_DT_RS);
memoire_RS_avec_DT = nb_paires * M_CLE;

% =========================================================
%   FIGURE UNIQUE — 8 sous-graphes
% =========================================================
figure('Name','Analyse RS — Énergie & Mémoire détaillée',...
       'NumberTitle','off','Position',[200 80 1400 900]);
set(gcf,'WindowStyle','normal'); movegui('center');

% =========================================================
% 1) BARRES GLOBALES — RS sans DT vs RS avec DT
% =========================================================
subplot(3,3,1);
bar([energie_RS_sans_DT, energie_RS_avec_DT]);
set(gca,'XTickLabel',{'RS sans DT','RS avec DT'});
title('Énergie — Global');
ylabel('Unités');
grid on;

subplot(3,3,2);
bar([memoire_RS_sans_DT, memoire_RS_avec_DT]);
set(gca,'XTickLabel',{'RS sans DT','RS avec DT'});
title('Mémoire — Global');
ylabel('Ko');
grid on;

% =========================================================
% 2) COURBE — Énergie RS vs nombre de nœuds
% =========================================================
n_values = 5:5:300;
nb_paires_values = n_values;

energie_sans_DT_curve = nb_paires_values .* (E_GEN + E_TEST + E_HASH + E_RS_RS);
energie_avec_DT_curve = nb_paires_values .* (E_RS_DT + E_DT_RS);

subplot(3,3,3);
plot(n_values, energie_sans_DT_curve, '-o','LineWidth',2,'Color',[0.85 0.1 0.1]);
hold on;
plot(n_values, energie_avec_DT_curve, '-s','LineWidth',2,'Color',[0.05 0.65 0.35]);
grid on;
xlabel('Nombre de nœuds');
ylabel('Énergie (unités)');
title('Énergie RS en fonction du nombre de nœuds');
legend({'RS sans DT','RS avec DT'},'Location','northwest');

% =========================================================
% 3) COURBE — Mémoire RS vs nombre de nœuds
% =========================================================
memoire_sans_DT_curve = nb_paires_values .* (M_CLE + M_ETAT + M_LOG);
memoire_avec_DT_curve = nb_paires_values .* M_CLE;

subplot(3,3,4);
plot(n_values, memoire_sans_DT_curve, '-o','LineWidth',2,'Color',[0.85 0.1 0.1]);
hold on;
plot(n_values, memoire_avec_DT_curve, '-s','LineWidth',2,'Color',[0.05 0.65 0.35]);
grid on;
xlabel('Nombre de nœuds');
ylabel('Mémoire (Ko)');
title('Mémoire RS en fonction du nombre de nœuds');
legend({'RS sans DT','RS avec DT'},'Location','northwest');

% =========================================================
% COURBE UNIQUE — Tous les coûts énergétiques
% =========================================================
subplot(3,3,5);   % On utilise un seul emplacement
hold on;

plot(n_values, nb_paires_values * E_RS_RS, '-o','LineWidth',2,'Color',[0.1 0.2 0.9]);
plot(n_values, nb_paires_values * E_RS_DT, '-s','LineWidth',2,'Color',[0.1 0.7 0.9]);
plot(n_values, nb_paires_values * E_DT_RS, '-d','LineWidth',2,'Color',[0.9 0.4 0.1]);
plot(n_values, nb_paires_values * (E_GEN + E_TEST + E_HASH), '-^','LineWidth',2,'Color',[0.1 0.9 0.3]);

grid on;
xlabel('Nombre de nœuds');
ylabel('Énergie (unités)');
title('Coûts énergétiques — Comparaison globale');

legend({'RS↔RS','RS→DT','DT→RS','Calculs (GEN+TEST+HASH)'},...
       'Location','northwest');


% =========================================================
% 8) COURBE — Mémoire (Clés + États + Logs)
% =========================================================
subplot(3,3,9);
plot(n_values, nb_paires_values * M_CLE, '-o','LineWidth',2,'Color',[0.2 0.8 0.2]);
hold on;
plot(n_values, nb_paires_values * M_ETAT, '-s','LineWidth',2,'Color',[0.8 0.2 0.2]);
plot(n_values, nb_paires_values * M_LOG, '-d','LineWidth',2,'Color',[0.2 0.2 0.8]);
grid on;
xlabel('Nombre de nœuds');
ylabel('Mémoire (Ko)');
title('Mémoire — Clés / États / Logs');
legend({'Clés','États','Logs'},'Location','northwest');

fprintf('\n>>> Analyse détaillée générée dans une seule fenêtre.\n');

