% =========================================================
%   RÉSEAU PHYSIQUE (RS) — Phase 2 / Pré-distribution clés
%   - Groupes dynamiques par voisinage (Option A)
%   - Chaque paire de voisins génère un ID de clé
%   - Envoi des ID au Twinning → DT
%   - Réception et stockage des clés générées par le DT
% =========================================================
clc; clear; close all;

fprintf('=================================================\n');
fprintf('   RÉSEAU PHYSIQUE (RS) — Phase 2\n');
fprintf('=================================================\n\n');

% ─────────────────────────────────────────────────────────
% PARAMÈTRES
% ─────────────────────────────────────────────────────────
n       = 9;
breadth = 500;
R       = 200;

% ─────────────────────────────────────────────────────────
% ÉTAPE 1 — DÉPLOIEMENT ALÉATOIRE
% ─────────────────────────────────────────────────────────
rng('shuffle');
x = breadth * rand(1, n);
y = breadth * rand(1, n);

fprintf('[DÉPLOIEMENT] %d noeuds | Rayon R=%dm\n\n', n, R);

% ─────────────────────────────────────────────────────────
% ÉTAPE 2 — MATRICE DE VOISINAGE
% ─────────────────────────────────────────────────────────
fprintf('[VOISINAGE]   Calcul des voisins...\n');

voisins = cell(1, n);
for i = 1:n
    for j = 1:n
        if i ~= j
            dist = sqrt((x(i)-x(j))^2 + (y(i)-y(j))^2);
            if dist <= R
                voisins{i}(end+1) = j;
            end
        end
    end
end

for i = 1:n
    if isempty(voisins{i})
        fprintf('  N%d : isolé !\n', i);
    else
        fprintf('  N%d : voisins = [%s]\n', i, ...
                strjoin(arrayfun(@(v) sprintf('N%d',v), voisins{i}, ...
                'UniformOutput',false), ', '));
    end
end

% ─────────────────────────────────────────────────────────
% ÉTAPE 3 — FORMATION DES GROUPES
% ─────────────────────────────────────────────────────────
fprintf('\n[GROUPES]     Formation des groupes...\n');

appartient = zeros(1, n);
groupe_id  = 0;
groupes    = {};

for i = 1:n
    if appartient(i) == 0
        groupe_id = groupe_id + 1;
        membres   = unique([i, voisins{i}]);
        groupes{groupe_id} = membres;
        for m = membres
            if appartient(m) == 0
                appartient(m) = groupe_id;
            end
        end
    end
end

nb_groupes = groupe_id;
fprintf('[GROUPES]     %d groupe(s) formé(s)\n', nb_groupes);
for k = 1:nb_groupes
    noms = strjoin(arrayfun(@(v) sprintf('N%d',v), groupes{k},...
                   'UniformOutput',false), ', ');
    fprintf('  Groupe %d : %s\n', k, noms);
end

% ─────────────────────────────────────────────────────────
% ÉTAPE 4 — ÉTATS PAR NOEUD
% ─────────────────────────────────────────────────────────
batterie = 40 + 60 * rand(1, n);
cpu      = 20 + 60 * rand(1, n);

% Stockage clés local (vide au départ)
cles_locales = struct();
for i = 1:n
    cles_locales(i).noeud  = i;
    cles_locales(i).paires = {};   % liste des paires
    cles_locales(i).cles   = {};   % clé correspondante
end

% ─────────────────────────────────────────────────────────
% ÉTAPE 5 — GÉNÉRATION DES ID DE CLÉS POUR TOUS LES GROUPES
% ─────────────────────────────────────────────────────────
fprintf('\n[ID CLÉS]     Génération des ID pour TOUS les groupes...\n');

demandes_cles = struct([]);
nb_paires     = 0;
timestamp_str = num2str(round(posixtime(datetime('now'))));

for g = 1:nb_groupes
    noeuds_actifs = groupes{g};
    fprintf('  Groupe %d : noeuds = [%s]\n', g, ...
        strjoin(arrayfun(@(v) sprintf('N%d',v), noeuds_actifs, 'UniformOutput',false), ', '));

    for a = 1:length(noeuds_actifs)
        i = noeuds_actifs(a);
        for b = a+1:length(noeuds_actifs)
            j = noeuds_actifs(b);

            % Vérifier que i et j sont bien voisins directs
            if ismember(j, voisins{i})
                nb_paires = nb_paires + 1;
                id_cle    = sprintf('ID_N%d_N%d_G%d_%s', i, j, g, timestamp_str);

                demandes_cles(nb_paires).noeud_i   = i;
                demandes_cles(nb_paires).noeud_j   = j;
                demandes_cles(nb_paires).id_cle    = id_cle;
                demandes_cles(nb_paires).groupe_id = g;
                demandes_cles(nb_paires).timestamp = datetime('now');

                fprintf('    Paire (N%d, N%d) [G%d] → ID = %s\n', i, j, g, id_cle);
            end
        end
    end
end

fprintf('[ID CLÉS]     %d paire(s) identifiée(s) sur tous les groupes\n', nb_paires);

% ─────────────────────────────────────────────────────────
% ÉTAPE 6 — MODULES DE SÉCURITÉ + Tx → Twinning
% ─────────────────────────────────────────────────────────
fprintf('\n[MODULES SÉC] Hachage des états Groupe 1...\n');

% Pour l'instant, on garde le groupe 1 comme groupe actif pour l'état
noeuds_actifs = groupes{1};
etats_actifs = struct();
for idx = 1:length(noeuds_actifs)
    i            = noeuds_actifs(idx);
    etat_clair   = sprintf('N%d|pos=(%.0f,%.0f)|bat=%.1f|cpu=%.1f',...
                            i, x(i), y(i), batterie(i), cpu(i));
    hash_etat    = num2str(sum(double(etat_clair).*(1:length(etat_clair))));
    etat_chiffre = sprintf('ENC[%s]', etat_clair);

    etats_actifs(idx).noeud        = i;
    etats_actifs(idx).groupe_id    = 1;
    etats_actifs(idx).x            = x(i);
    etats_actifs(idx).y            = y(i);
    etats_actifs(idx).batterie     = batterie(i);
    etats_actifs(idx).cpu          = cpu(i);
    etats_actifs(idx).hash         = hash_etat;
    etats_actifs(idx).etat_chiffre = etat_chiffre;
    etats_actifs(idx).timestamp    = datetime('now');

    fprintf('  N%d : hash=%s\n', i, hash_etat);
end

fprintf('\n[Tx]          Émission TOUS GROUPES + ID clés → Twinning\n');

transmission.groupe_actif   = 1;
transmission.nb_groupes     = nb_groupes;
transmission.groupes        = groupes;
transmission.appartient     = appartient;
transmission.etats_actifs   = etats_actifs;
transmission.demandes_cles  = demandes_cles;
transmission.nb_paires      = nb_paires;
transmission.voisins        = voisins;
transmission.x              = x;
transmission.y              = y;
transmission.batterie       = batterie;
transmission.cpu            = cpu;
transmission.n              = n;
transmission.breadth        = breadth;
transmission.R              = R;
transmission.timestamp      = datetime('now');

save('canal_twinning.mat', 'transmission');
fprintf('[Tx]          ✅ États + %d ID de clés émis\n', nb_paires);

% ─────────────────────────────────────────────────────────
% ÉTAPE 7 — AFFICHAGE RS
% ─────────────────────────────────────────────────────────
couleurs = lines(nb_groupes);

figure('Name','RS — Réseau physique (Phase 2)',...
       'NumberTitle','off','Position',[50 80 700 600]);
hold on;

% Liens de voisinage
for i = 1:n
    for j = voisins{i}
        if j > i
            line([x(i) x(j)],[y(i) y(j)],...
                 'Color',[0.75 0.75 0.75],...
                 'LineWidth',1,'LineStyle','--');
        end
    end
end

% Liens paires de clés (toutes les paires demandées, en vert)
for p = 1:nb_paires
    ni = demandes_cles(p).noeud_i;
    nj = demandes_cles(p).noeud_j;
    line([x(ni) x(nj)],[y(ni) y(nj)],...
         'Color',[0.05 0.65 0.35],...
         'LineWidth',2.5,'LineStyle','-');
    mx = (x(ni)+x(nj))/2;
    my = (y(ni)+y(nj))/2;
    text(mx, my+12, 'ID clé','FontSize',7,...
         'HorizontalAlignment','center','Color',[0.05 0.65 0.35]);
end

% Noeuds
h_leg = gobjects(nb_groupes,1);
for i = 1:n
    gk = appartient(i);
    c  = couleurs(gk,:);
    t  = 160;
    scatter(x(i), y(i), t, 'o',...
            'MarkerEdgeColor',c,'MarkerFaceColor',c);
    text(x(i), y(i)+22,...
         sprintf('N%d\nbat:%.0f%%', i, batterie(i)),...
         'FontSize',8,'HorizontalAlignment','center',...
         'FontWeight','bold','Color',c);
end

for k = 1:nb_groupes
    c   = couleurs(k,:);
    lbl = sprintf('Groupe %d%s', k, ternaire_str(k==1,' (Actif)',''));
    h_leg(k) = scatter(nan,nan,160,'o',...
                       'MarkerEdgeColor',c,'MarkerFaceColor',c,...
                       'DisplayName',lbl);
end

h_id = plot(nan,nan,'-','Color',[0.05 0.65 0.35],...
            'LineWidth',2.5,'DisplayName','Paires ID clés');

xlim([0 breadth]); ylim([0 breadth]);
title(sprintf('RS — Phase 2 | %d paire(s) de clés demandées', nb_paires),...
      'FontWeight','bold');
xlabel('X (m)'); ylabel('Y (m)');
legend([h_leg; h_id],'Location','northeast');
grid on; drawnow;

fprintf('\n=================================================\n');
fprintf('   FIN RS — Lance jumeau_numerique.m\n');
fprintf('=================================================\n');

function res = ternaire_str(condition, si_vrai, si_faux)
    if condition, res = si_vrai; else, res = si_faux; end
end
