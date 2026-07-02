% =========================================================
%   MAIN SIMULATION — Phase 2 / Pré-distribution clés
%   RS → Twinning → DT → RS
% =========================================================
clc; clear; close all;

fprintf('=================================================\n');
fprintf('   SIMULATION — Phase 2 / Pré-distribution clés\n');
fprintf('=================================================\n\n');

% =========================================================
% ÉTAPE 1 — RS : déploiement + voisinage + ID clés + Tx
% =========================================================
fprintf('>>> ÉTAPE 1 : RS — Déploiement + ID clés (TOUS GROUPES)\n');
reseau_physique;

% =========================================================
% ÉTAPE 2 — DT : génération + test + stockage clés
% =========================================================
fprintf('\n>>> ÉTAPE 2 : DT — Génération et test des clés\n');
jumeau_numerique;

% =========================================================
% ÉTAPE 3 — RS : Réception + stockage des clés
% =========================================================
fprintf('\n>>> ÉTAPE 3 : RS — Réception et stockage des clés\n');

load('decision_jumeau.mat');
load('canal_twinning.mat');

x       = transmission.x;
y       = transmission.y;
n       = transmission.n;
breadth = transmission.breadth;
voisins = transmission.voisins;
appartient = transmission.appartient;
nb_groupes = transmission.nb_groupes;

fprintf('[Rx] %d clé(s) reçue(s) du DT\n', reponse.nb_paires);

cles_locales = cell(n, 1);
for i = 1:n
    cles_locales{i} = struct('paire',{},'cle',{});
end

for p = 1:reponse.nb_paires
    cle = reponse.cles_generees(p);
    if cle.valide
        ni = cle.noeud_i;
        nj = cle.noeud_j;

        idx_i = length(cles_locales{ni}) + 1;
        cles_locales{ni}(idx_i).paire = sprintf('N%d-N%d', ni, nj);
        cles_locales{ni}(idx_i).cle   = cle.cle;

        idx_j = length(cles_locales{nj}) + 1;
        cles_locales{nj}(idx_j).paire = sprintf('N%d-N%d', ni, nj);
        cles_locales{nj}(idx_j).cle   = cle.cle;

        fprintf('[APPLICATION] N%d ↔ N%d : clé stockée\n', ni, nj);
    end
end

save('cles_locales_rs.mat','cles_locales');

% =========================================================
% FIGURE RS — Communications sécurisées (seule figure RS)
% =========================================================
figure('Name','RS — Communications sécurisées',...
       'NumberTitle','off','Position',[400 80 700 600]);
hold on;

couleurs = lines(nb_groupes);

for i = 1:n
    for j = voisins{i}
        if j > i
            line([x(i) x(j)], [y(i) y(j)], 'Color',[0.85 0.85 0.85],...
                 'LineWidth',0.8,'LineStyle','--');
        end
    end
end

for p = 1:reponse.nb_paires
    cle = reponse.cles_generees(p);
    if cle.valide
        ni = cle.noeud_i;
        nj = cle.noeud_j;
        line([x(ni) x(nj)], [y(ni) y(nj)], 'Color',[0.05 0.65 0.35],...
             'LineWidth',3);
        mx = (x(ni)+x(nj))/2;
        my = (y(ni)+y(nj))/2;
        text(mx, my+14, '🔐 sécurisé','FontSize',7,...
             'HorizontalAlignment','center');
    end
end

for i = 1:n
    gk = appartient(i);
    c  = couleurs(gk,:);
    nb_cles_i = length(cles_locales{i});
    scatter(x(i), y(i), 160, 'o','MarkerEdgeColor',c,'MarkerFaceColor',c);
    text(x(i), y(i)+22, sprintf('N%d\n%d clé(s)', i, nb_cles_i),...
         'FontSize',8,'HorizontalAlignment','center','FontWeight','bold');
end

xlim([0 breadth]); ylim([0 breadth]);
title(sprintf('RS — %d communications sécurisées', reponse.nb_paires));
grid on;

% =========================================================
% SCÉNARIO : N1 veut parler à N2 → demande de clé au DT
% =========================================================
fprintf('\n>>> SCÉNARIO : Communication N1 → N2 via DT\n');

ni = 1; nj = 2;

try
    cle_info = dt_get_key(ni, nj);
    fprintf('[COMMUNICATION] N%d ↔ N%d utilise la clé : %s\n', ...
            ni, nj, cle_info.cle);
catch ME
    fprintf('[COMMUNICATION] Erreur : %s\n', ME.message);
end

% =========================================================
% ANALYSE — Énergie & Mémoire RS (2 colonnes)
% =========================================================
fprintf('\n>>> ANALYSE : Énergie & Mémoire RS\n');

nb_paires = reponse.nb_paires;

E_GEN = 5; E_TEST = 3; E_HASH = 2; E_TX = 1; E_RX = 1;
M_CLE = 0.5; M_ETAT = 1; M_LOG = 2;

energie_RS_sans_DT = nb_paires * (E_GEN + E_TEST + E_HASH);
energie_RS_avec_DT = nb_paires * (E_TX + E_RX);

memoire_RS_sans_DT = nb_paires * (M_CLE + M_ETAT + M_LOG);
memoire_RS_avec_DT = nb_paires * M_CLE;

figure('Name','Comparaison RS','NumberTitle','off',...
       'Position',[1150 80 900 400]);

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

fprintf('Énergie RS sans DT : %.1f\n', energie_RS_sans_DT);
fprintf('Énergie RS avec DT : %.1f\n', energie_RS_avec_DT);
fprintf('Mémoire RS sans DT : %.1f Ko\n', memoire_RS_sans_DT);
fprintf('Mémoire RS avec DT : %.1f Ko\n', memoire_RS_avec_DT);

fprintf('\n=================================================\n');
fprintf('   SIMULATION TERMINÉE\n');
fprintf('=================================================\n');
