% =========================================================
%   RÉSEAU PHYSIQUE (RS) — Phase 1 / Option A
%   Groupes dynamiques par voisinage (rayon R)
%   - Chaque nœud + ses voisins directs = un groupe
%   - Groupe actif = groupe du nœud 1 (premier traité)
%   - Les autres groupes sont en attente
% =========================================================
clc; clear; close all;

fprintf('=================================================\n');
fprintf('   RÉSEAU PHYSIQUE (RS) — Phase 1 / Option A\n');
fprintf('=================================================\n\n');

% ─────────────────────────────────────────────────────────
% PARAMÈTRES
% ─────────────────────────────────────────────────────────
n       = 9;
breadth = 500;
R       = 200;   % rayon de communication (modifiable)

% ─────────────────────────────────────────────────────────
% ÉTAPE 1 — DÉPLOIEMENT ALÉATOIRE
% ─────────────────────────────────────────────────────────
rng('shuffle');  % aléatoire pur basé sur l'horloge
x = breadth * rand(1, n);
y = breadth * rand(1, n);

fprintf('[DÉPLOIEMENT] %d noeuds déployés | Rayon R = %dm\n\n', n, R);
for i = 1:n
    fprintf('  N%d : pos=(%.0f, %.0f)\n', i, x(i), y(i));
end

% ─────────────────────────────────────────────────────────
% ÉTAPE 2 — MATRICE DE VOISINAGE
% Deux noeuds sont voisins si distance <= R
% ─────────────────────────────────────────────────────────
fprintf('\n[VOISINAGE]   Calcul des voisins (R=%dm)...\n', R);

voisins = cell(1, n);  % voisins{i} = liste des voisins de i
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
        fprintf('  N%d : aucun voisin (isolé !)\n', i);
    else
        fprintf('  N%d : voisins = [%s]\n', i, ...
                strjoin(arrayfun(@(v) sprintf('N%d',v), voisins{i}, ...
                'UniformOutput', false), ', '));
    end
end

% ─────────────────────────────────────────────────────────
% ÉTAPE 3 — FORMATION DES GROUPES PAR VOISINAGE
% Chaque noeud i forme un groupe avec ses voisins directs
% On évite les doublons : un noeud appartient au groupe
% du noeud avec le plus petit indice parmi eux
% ─────────────────────────────────────────────────────────
fprintf('\n[GROUPES]     Formation des groupes par voisinage...\n');

appartient = zeros(1, n);  % appartient(i) = id du groupe de i
groupe_id  = 0;
groupes    = {};            % groupes{k} = liste des noeuds du groupe k

for i = 1:n
    if appartient(i) == 0
        groupe_id = groupe_id + 1;
        membres   = [i, voisins{i}];
        membres   = unique(membres);
        groupes{groupe_id} = membres;
        for m = membres
            if appartient(m) == 0
                appartient(m) = groupe_id;
            end
        end
    end
end

nb_groupes = groupe_id;
fprintf('[GROUPES]     %d groupe(s) formé(s) :\n', nb_groupes);
for k = 1:nb_groupes
    noms = strjoin(arrayfun(@(v) sprintf('N%d',v), groupes{k}, ...
                   'UniformOutput', false), ', ');
    if k == 1
        statut = 'ACTIF';
    else
        statut = 'attente';
    end
    fprintf('  Groupe %d [%s] : %s\n', k, statut, noms);
end

% ─────────────────────────────────────────────────────────
% ÉTAPE 4 — ÉTATS PAR NOEUD
% ─────────────────────────────────────────────────────────
batterie = 40 + 60 * rand(1, n);
cpu      = 20 + 60 * rand(1, n);

fprintf('\n[ÉTATS]       État initial par noeud :\n');
for i = 1:n
    fprintf('  N%d [Grp %d] pos=(%.0f,%.0f) bat=%.1f%% cpu=%.1f%%\n',...
            i, appartient(i), x(i), y(i), batterie(i), cpu(i));
end

% ─────────────────────────────────────────────────────────
% ÉTAPE 5 — MODULES DE SÉCURITÉ (Groupe actif = groupe 1)
% ─────────────────────────────────────────────────────────
fprintf('\n[MODULES SÉC] Traitement Groupe 1 (actif)...\n');

noeuds_actifs = groupes{1};
etats_actifs  = struct();

for idx = 1:length(noeuds_actifs)
    i            = noeuds_actifs(idx);
    etat_clair   = sprintf('N%d|pos=(%.0f,%.0f)|bat=%.1f|cpu=%.1f',...
                            i, x(i), y(i), batterie(i), cpu(i));
    hash_etat    = num2str(sum(double(etat_clair) .* (1:length(etat_clair))));
    etat_chiffre = sprintf('ENC[%s]', etat_clair);

    fprintf('  N%d : hash=%s\n', i, hash_etat);

    etats_actifs(idx).noeud        = i;
    etats_actifs(idx).groupe_id    = 1;
    etats_actifs(idx).x            = x(i);
    etats_actifs(idx).y            = y(i);
    etats_actifs(idx).batterie     = batterie(i);
    etats_actifs(idx).cpu          = cpu(i);
    etats_actifs(idx).hash         = hash_etat;
    etats_actifs(idx).etat_chiffre = etat_chiffre;
    etats_actifs(idx).timestamp    = datetime('now');
end

% ─────────────────────────────────────────────────────────
% ÉTAPE 6 — Tx : ÉMISSION → Twinning
% ─────────────────────────────────────────────────────────
fprintf('\n[Tx]          Émission Groupe 1 → Twinning\n');

transmission.groupe_actif   = 1;
transmission.nb_groupes     = nb_groupes;
transmission.groupes        = groupes;
transmission.appartient     = appartient;
transmission.etats_actifs   = etats_actifs;
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
fprintf('[Tx]          ✅ État Groupe 1 émis\n');
fprintf('[Tx]          Groupes 2..%d : push périodique enregistré\n', nb_groupes);

% ─────────────────────────────────────────────────────────
% ÉTAPE 7 — AFFICHAGE RS
% ─────────────────────────────────────────────────────────
couleurs = lines(nb_groupes);  % une couleur par groupe

figure('Name','RS — Réseau physique (Groupes dynamiques)',...
       'NumberTitle','off','Position',[50 80 700 600]);
hold on;

% Liens de voisinage
for i = 1:n
    for j = voisins{i}
        if j > i  % éviter les doublons
            line([x(i) x(j)],[y(i) y(j)],...
                 'Color',[0.75 0.75 0.75],'LineWidth',1,'LineStyle','--');
        end
    end
end

% Cercle de rayon R autour de N1 (pour visualiser)
theta = linspace(0, 2*pi, 100);
plot(x(1)+R*cos(theta), y(1)+R*sin(theta),...
     'Color',[0.2 0.6 1 0.3],'LineWidth',1,'LineStyle',':');

% Noeuds
h_leg = gobjects(nb_groupes,1);
for i = 1:n
    gk = appartient(i);
    c  = couleurs(gk,:);
    if gk == 1, t = 180; else, t = 110; end
    scatter(x(i), y(i), t, 'o',...
            'MarkerEdgeColor', c,...
            'MarkerFaceColor', c);
    text(x(i), y(i)+22,...
         sprintf('N%d\nbat:%.0f%%\ncpu:%.0f%%', i, batterie(i), cpu(i)),...
         'FontSize',7,'HorizontalAlignment','center',...
         'FontWeight','bold','Color',c);
end

% Légende
for k = 1:nb_groupes
    c = couleurs(k,:);
    if k == 1
        lbl = sprintf('Groupe %d (Actif)', k);
        t   = 180;
    else
        lbl = sprintf('Groupe %d (Attente · push 30s)', k);
        t   = 110;
    end
    h_leg(k) = scatter(nan, nan, t, 'o',...
                       'MarkerEdgeColor',c,'MarkerFaceColor',c,...
                       'DisplayName', lbl);
end

xlim([0 breadth]); ylim([0 breadth]);
title(sprintf('RS — %d noeuds | %d groupes | R=%dm | Groupe 1 actif',...
      n, nb_groupes, R),'FontWeight','bold');
xlabel('X (m)'); ylabel('Y (m)');
legend(h_leg, 'Location','northeast');
grid on;
drawnow;

fprintf('\n=================================================\n');
fprintf('   FIN RS — Lance jumeau_numerique.m\n');
fprintf('=================================================\n');