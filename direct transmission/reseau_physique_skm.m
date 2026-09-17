% =========================================================
%   RÉSEAU PHYSIQUE — Modèle SKM (Secure Key Management)
%   Version légère sans DT, sans refresh, sans TTL
%   Dérivation locale des clés pairwise
% =========================================================
clc; 

fprintf('=================================================\n');
fprintf('   RÉSEAU PHYSIQUE — Modèle SKM\n');
fprintf('=================================================\n\n');

% ─────────────────────────────────────────────────────────
% CHARGEMENT DU RÉSEAU PHYSIQUE RS/DT
% ─────────────────────────────────────────────────────────
if ~exist('canal_twinning.mat','file')
    error('❌ Lance reseau_physique.m d''abord pour générer le réseau.');
end

load('canal_twinning.mat');

% Récupération des données RS
x          = transmission.x;
y          = transmission.y;
voisins    = transmission.voisins;
groupes    = transmission.groupes;
appartient = transmission.appartient;
batterie   = transmission.batterie;
cpu        = transmission.cpu;
n          = transmission.n;
breadth    = transmission.breadth;
R          = transmission.R;

fprintf('[SKM] Réseau physique chargé depuis RS/DT\n');

% ─────────────────────────────────────────────────────────
% ÉTAPE 1 — CLÉS MAÎTRESSES SKM
% ─────────────────────────────────────────────────────────
fprintf('\n[SKM] Génération des clés maîtresses...\n');

cles_maitresse = cell(1,n);
for i = 1:n
    cle = sprintf('MASTER_KEY_N%d_%d', i, randi([10000 99999]));
    cles_maitresse{i} = cle;
    fprintf('  N%d : %s\n', i, cle);
end

% ─────────────────────────────────────────────────────────
% ÉTAPE 2 — DÉRIVATION LOCALE DES CLÉS PAIRWISE
% ─────────────────────────────────────────────────────────
fprintf('\n[SKM] Dérivation des clés pairwise...\n');

cles_pairwise = {};
nb_paires = 0;

for i = 1:n
    for j = voisins{i}
        if j > i
            nb_paires = nb_paires + 1;

            cle_i = cles_maitresse{i};
            id_pair = sprintf('N%d_N%d', i, j);

            % HMAC simulé
            cle_skm = sprintf('SKM_%s_%s', cle_i, id_pair);
            hash_skm = num2str(sum(double(cle_skm).*(1:length(cle_skm))));

            cles_pairwise{nb_paires}.i = i;
            cles_pairwise{nb_paires}.j = j;
            cles_pairwise{nb_paires}.cle = cle_skm;
            cles_pairwise{nb_paires}.hash = hash_skm;

            fprintf('  Paire N%d-N%d → clé dérivée SKM\n', i, j);
        end
    end
end

fprintf('[SKM] %d clé(s) dérivée(s)\n', nb_paires);

% ─────────────────────────────────────────────────────────
% ÉTAPE 3 — CALCUL ÉNERGÉTIQUE SKM
% ─────────────────────────────────────────────────────────
fprintf('\n[ÉNERGIE SKM] Calcul du coût énergétique...\n');

E_DERIV = 2;   % dérivation HMAC simulée
E_RADIO = 6;   % transmission RS↔RS (si communication)

energie_skm = nb_paires * (E_DERIV + E_RADIO);

fprintf('[ÉNERGIE SKM] Total = %.1f unités\n', energie_skm);

% ─────────────────────────────────────────────────────────
% ÉTAPE 4 — CALCUL MÉMOIRE SKM
% ─────────────────────────────────────────────────────────
fprintf('\n[MÉMOIRE SKM] Calcul du coût mémoire...\n');

M_MASTER = 0.02;   % 16 bytes ≈ 0.02 Ko
M_PAIR   = 0.00;   % SKM ne stocke pas les clés pairwise

memoire_skm = n * M_MASTER;

fprintf('[MÉMOIRE SKM] Total = %.2f Ko\n', memoire_skm);

% ─────────────────────────────────────────────────────────
% ÉTAPE 5 — FIGURE RS SKM
% ─────────────────────────────────────────────────────────
figure('Name','RS — Modèle SKM',...
       'NumberTitle','off','Position',[50 80 700 600]);
hold on;

couleurs = lines(length(groupes));

% Liens de voisinage
for i = 1:n
    for j = voisins{i}
        if j > i
            line([x(i) x(j)], [y(i) y(j)], 'Color',[0.85 0.85 0.85],...
                 'LineWidth',0.8,'LineStyle','--');
        end
    end
end

% Liens SKM (vert)
for p = 1:nb_paires
    ni = cles_pairwise{p}.i;
    nj = cles_pairwise{p}.j;
    line([x(ni) x(nj)], [y(ni) y(nj)], 'Color',[0.05 0.65 0.35],...
         'LineWidth',3);
end

% Noeuds
for i = 1:n
    gk = appartient(i);
    c  = couleurs(gk,:);
    scatter(x(i), y(i), 160, 'o','MarkerEdgeColor',c,'MarkerFaceColor',c);
    text(x(i), y(i)+22, sprintf('N%d', i),...
         'FontSize',8,'HorizontalAlignment','center','FontWeight','bold');
end

title(sprintf('RS — SKM | %d clés dérivées', nb_paires));
grid on;

% ─────────────────────────────────────────────────────────
% SAUVEGARDE POUR COMPARAISON
% ─────────────────────────────────────────────────────────
save('skm_resultats.mat','nb_paires','energie_skm','memoire_skm',...
     'cles_pairwise','x','y','voisins','appartient','groupes');

fprintf('\n=================================================\n');
fprintf('   FIN — Modèle SKM prêt pour comparaison\n');
fprintf('=================================================\n');
