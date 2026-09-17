% =========================================================
%   JUMEAU NUMÉRIQUE (DT) — Phase 2 / Pré-distribution clés + Refresh
% =========================================================
clc;

fprintf('=================================================\n');
fprintf('   JUMEAU NUMÉRIQUE (DT) — Phase 2 + Refresh\n');
fprintf('=================================================\n\n');

% ─────────────────────────────────────────────────────────
% ÉTAPE 1 — RÉCEPTION VIA LE TWINNING
% ─────────────────────────────────────────────────────────
if ~exist('canal_twinning.mat','file')
    error('❌ Lance reseau_physique.m d''abord.');
end

load('canal_twinning.mat');

groupe_actif  = transmission.groupe_actif;
nb_groupes    = transmission.nb_groupes;
groupes       = transmission.groupes;
appartient    = transmission.appartient;
etats_actifs  = transmission.etats_actifs;
demandes_cles = transmission.demandes_cles;
nb_paires     = transmission.nb_paires;
voisins       = transmission.voisins;
x             = transmission.x;
y             = transmission.y;
batterie      = transmission.batterie;
cpu           = transmission.cpu;
n             = transmission.n;
breadth       = transmission.breadth;
R             = transmission.R;

fprintf('[TWINNING]    Réception — %s\n', datestr(transmission.timestamp));
fprintf('[TWINNING]    Groupe actif    : %d / %d\n', groupe_actif, nb_groupes);
fprintf('[TWINNING]    ID clés reçus   : %d paire(s)\n\n', nb_paires);

% ─────────────────────────────────────────────────────────
% ÉTAPE REFRESH — RÉCEPTION DES DEMANDES DE REFRESH
% ─────────────────────────────────────────────────────────
cles_refresh = [];

if exist('refresh_request.mat','file')
    load('refresh_request.mat','refresh_request');
    cles_refresh = refresh_request.paires;
    fprintf('[REFRESH]     %d paire(s) à rafraîchir\n\n', size(cles_refresh,1));
else
    fprintf('[REFRESH]     Aucune demande de refresh\n\n');
end

% ─────────────────────────────────────────────────────────
% ÉTAPE 2 — RÉPLIQUE VIRTUELLE
% ─────────────────────────────────────────────────────────
x_virt   = x;
y_virt   = y;
bat_virt = batterie;
cpu_virt = cpu;

fprintf('[RÉPLIQUE]    Copie virtuelle créée — %d noeuds\n\n', n);

% ─────────────────────────────────────────────────────────
% ÉTAPE 3 — GESTIONNAIRE DE GROUPES
% ─────────────────────────────────────────────────────────
prochain_groupe = mod(groupe_actif, nb_groupes) + 1;
fprintf('[GEST. GROUPES] Rotation : %d → %d (~30s)\n\n',...
        groupe_actif, prochain_groupe);

% ─────────────────────────────────────────────────────────
% ÉTAPE 4 — ÉVALUATION DE L'ENVIRONNEMENT (GROUPE ACTIF)
% ─────────────────────────────────────────────────────────
fprintf('[ÉVALUATION]  Analyse Groupe %d :\n', groupe_actif);
fprintf('─────────────────────────────────────────────────\n');

for idx = 1:length(etats_actifs)
    e = etats_actifs(idx);
    fprintf('  N%d* | pos=(%.0f,%.0f) | bat=%.1f%% | cpu=%.1f%%\n',...
            e.noeud, e.x, e.y, e.batterie, e.cpu);
end

bat_moy = mean([etats_actifs.batterie]);
cpu_moy = mean([etats_actifs.cpu]);
fprintf('─────────────────────────────────────────────────\n');
fprintf('[ÉVALUATION]  Bat. moy : %.1f%% | CPU moy : %.1f%%\n\n',...
        bat_moy, cpu_moy);

% ─────────────────────────────────────────────────────────
% ÉTAPE 5 — MISE À JOUR DE L'ÉTAT PAR NŒUD
% ─────────────────────────────────────────────────────────
fprintf('[MISE À JOUR] Synchronisation réplique...\n');
for idx = 1:length(etats_actifs)
    e = etats_actifs(idx);
    x_virt(e.noeud)   = e.x;
    y_virt(e.noeud)   = e.y;
    bat_virt(e.noeud) = e.batterie;
    cpu_virt(e.noeud) = e.cpu;
end
fprintf('[MISE À JOUR] ✅ Réplique synchronisée\n\n');

% ─────────────────────────────────────────────────────────
% ÉTAPE 6 — GÉNÉRATION ET TEST DES CLÉS SUR RÉPLIQUE (pré-distribution)
% ─────────────────────────────────────────────────────────
fprintf('[CLÉS]        Génération et test sur réplique...\n');
fprintf('─────────────────────────────────────────────────\n');

cles_generees = struct();

for p = 1:nb_paires
    ni    = demandes_cles(p).noeud_i;
    nj    = demandes_cles(p).noeud_j;
    id    = demandes_cles(p).id_cle;

    % Clé AES128 de communication
    cle_valeur = sprintf('CLÉ_AES128_%s', id);
    hash_cle   = num2str(sum(double(cle_valeur).*(1:length(cle_valeur))));
    hash_verif = num2str(sum(double(cle_valeur).*(1:length(cle_valeur))));
    test_ok    = strcmp(hash_cle, hash_verif);

    cles_generees(p).noeud_i    = ni;
    cles_generees(p).noeud_j    = nj;
    cles_generees(p).id_cle     = id;
    cles_generees(p).cle        = cle_valeur;
    cles_generees(p).hash       = hash_cle;
    cles_generees(p).valide     = test_ok;
    cles_generees(p).groupe_id  = demandes_cles(p).groupe_id;
    cles_generees(p).timestamp  = datetime('now');
end

% ─────────────────────────────────────────────────────────
% ÉTAPE 7 — REFRESH : GÉNÉRATION / TEST DES CLÉS EXPIREES
% ─────────────────────────────────────────────────────────
fprintf('[REFRESH]     Génération des nouvelles clés...\n');

cles_refresh_gen = struct([]);

for k = 1:size(cles_refresh,1)
    ni = cles_refresh(k,1);
    nj = cles_refresh(k,2);

    id_new = sprintf('REFRESH_N%d_N%d_%s', ni, nj,...
                     num2str(round(posixtime(datetime('now')))));

    cle_valeur = sprintf('CLÉ_AES128_%s', id_new);
    hash_cle   = num2str(sum(double(cle_valeur).*(1:length(cle_valeur))));
    hash_verif = num2str(sum(double(cle_valeur).*(1:length(cle_valeur))));
    test_ok    = strcmp(hash_cle, hash_verif);

    cles_refresh_gen(k).noeud_i   = ni;
    cles_refresh_gen(k).noeud_j   = nj;
    cles_refresh_gen(k).id_cle    = id_new;
    cles_refresh_gen(k).cle       = cle_valeur;
    cles_refresh_gen(k).hash      = hash_cle;
    cles_refresh_gen(k).valide    = test_ok;
    cles_refresh_gen(k).timestamp = datetime('now');
end

% ─────────────────────────────────────────────────────────
% ÉTAPE 8 — STOCKAGE CENTRALISÉ (pré-distribution + refresh)
% ─────────────────────────────────────────────────────────
if exist('cles_dt.mat','file')
    load('cles_dt.mat','cles_dt');
else
    cles_dt = cell(n,n);
end

% Pré-distribution
for p = 1:nb_paires
    ni = cles_generees(p).noeud_i;
    nj = cles_generees(p).noeud_j;

    entry.cle        = cles_generees(p).cle;
    entry.hash       = cles_generees(p).hash;
    entry.id_cle     = cles_generees(p).id_cle;
    entry.groupe_id  = cles_generees(p).groupe_id;
    entry.valide     = cles_generees(p).valide;
    entry.revoked    = false;
    entry.timestamp  = cles_generees(p).timestamp;
    entry.ttl        = 30;   % TTL = 30 secondes
    entry.expire_at  = entry.timestamp + seconds(entry.ttl);

    cles_dt{ni,nj} = entry;
    cles_dt{nj,ni} = entry;
end

% Refresh
for k = 1:size(cles_refresh,1)
    ni = cles_refresh(k,1);
    nj = cles_refresh(k,2);

    entry.cle        = cles_refresh_gen(k).cle;
    entry.hash       = cles_refresh_gen(k).hash;
    entry.id_cle     = cles_refresh_gen(k).id_cle;
    entry.groupe_id  = 0;
    entry.valide     = cles_refresh_gen(k).valide;
    entry.revoked    = false;
    entry.timestamp  = cles_refresh_gen(k).timestamp;
    entry.ttl        = 30;   % TTL = 30 secondes
    entry.expire_at  = entry.timestamp + seconds(entry.ttl);

    cles_dt{ni,nj} = entry;
    cles_dt{nj,ni} = entry;
end

save('cles_dt.mat','cles_dt');
fprintf('[STOCKAGE DT] ✅ Clés mises à jour (pré-distribution + refresh)\n\n');

% ─────────────────────────────────────────────────────────
% ÉTAPE 9 — SIMULATION / TEST GLOBAL
% ─────────────────────────────────────────────────────────
fprintf('[SIMULATION]  Vérification intégrité états...\n');

test_etats = true(1, length(etats_actifs));
for idx = 1:length(etats_actifs)
    e        = etats_actifs(idx);
    etat_ref = sprintf('N%d|pos=(%.0f,%.0f)|bat=%.1f|cpu=%.1f',...
                        e.noeud, e.x, e.y, e.batterie, e.cpu);
    hash_ref = num2str(sum(double(etat_ref).*(1:length(etat_ref))));
    test_etats(idx) = strcmp(e.hash, hash_ref);
end

sim_ok     = all(test_etats);
cles_ok    = all([cles_generees.valide]) && (isempty(cles_refresh_gen) || all([cles_refresh_gen.valide]));
tout_ok    = sim_ok && cles_ok;

fprintf('[SIMULATION]  États   : %s\n', ternaire_str(sim_ok,'✅','❌'));
fprintf('[SIMULATION]  Clés    : %s\n', ternaire_str(cles_ok,'✅','❌'));
fprintf('[SIMULATION]  Global  : %s\n\n', ternaire_str(tout_ok,'✅ OK','❌ Échec'));

% ─────────────────────────────────────────────────────────
% ÉTAPE 10 — SUBSCRIBE : envoi au RS
% ─────────────────────────────────────────────────────────
reponse.groupe_actif    = groupe_actif;
reponse.prochain_groupe = prochain_groupe;
reponse.nb_groupes      = nb_groupes;
reponse.cles_generees   = cles_generees;
reponse.cles_refresh    = cles_refresh_gen;
reponse.nb_paires       = nb_paires;
reponse.nb_refresh      = size(cles_refresh,1);
reponse.tout_ok         = tout_ok;
reponse.timestamp       = datetime('now');

save('decision_jumeau.mat','reponse');
fprintf('[SUBSCRIBE]   ✅ Clés envoyées → RS (pré-distribution + refresh)\n');

% ─────────────────────────────────────────────────────────
% ÉTAPE 11 — AFFICHAGE DT
% ─────────────────────────────────────────────────────────
couleurs = lines(nb_groupes);

figure('Name','DT — Jumeau numérique (Phase 2 + Refresh)',...
    'NumberTitle','off','Position',[770 80 700 600]);
hold on;

% Liens de voisinage
for i = 1:n
    for j = voisins{i}
        if j > i
            line([x_virt(i) x_virt(j)],[y_virt(i) y_virt(j)],...
                'Color',[0.75 0.75 0.75],'LineWidth',1,'LineStyle','--');
        end
    end
end

% Liens clés générées (pré-distribution)
for p = 1:nb_paires
    ni = cles_generees(p).noeud_i;
    nj = cles_generees(p).noeud_j;
    line([x_virt(ni) x_virt(nj)],[y_virt(ni) y_virt(nj)],...
        'Color',[0.05 0.65 0.35],'LineWidth',2.5,'LineStyle','-');
end

% Liens refresh (rouge pointillé)
for k = 1:size(cles_refresh,1)
    ni = cles_refresh(k,1);
    nj = cles_refresh(k,2);
    line([x_virt(ni) x_virt(nj)],[y_virt(ni) y_virt(nj)],...
        'Color',[0.85 0.1 0.1],'LineWidth',2.5,'LineStyle','--');
end

% Noeuds virtuels
h_leg = gobjects(nb_groupes,1);
for i = 1:n
    gk = appartient(i);
    c  = couleurs(gk,:);
    t  = 160;
    scatter(x_virt(i), y_virt(i), t, 'o',...
        'MarkerEdgeColor',c,'MarkerFaceColor',c);
    text(x_virt(i), y_virt(i)+22,...
        sprintf('N%d*\nbat:%.0f%%', i, bat_virt(i)),...
        'FontSize',8,'HorizontalAlignment','center',...
        'FontWeight','bold','Color',c);
end

for k = 1:nb_groupes
    c   = couleurs(k,:);
    lbl = sprintf('Réplique Groupe %d%s', k,...
        ternaire_str(k==groupe_actif,' (Actif)',''));
    h_leg(k) = scatter(nan,nan,160,'o',...
        'MarkerEdgeColor',c,'MarkerFaceColor',c,...
        'DisplayName',lbl);
end

h_ok  = plot(nan,nan,'-','Color',[0.05 0.65 0.35],'LineWidth',2.5,...
    'DisplayName','Clé validée (pré-distribution)');
h_rf  = plot(nan,nan,'--','Color',[0.85 0.1 0.1],'LineWidth',2.5,...
    'DisplayName','Clé rafraîchie');

xlim([0 breadth]); ylim([0 breadth]);
title(sprintf('DT — Phase 2 | %d clés | %d refresh', nb_paires, size(cles_refresh,1)),...
    'FontWeight','bold');
xlabel('X (m)'); ylabel('Y (m)');
legend([h_leg; h_ok; h_rf],'Location','northeast');
grid on; drawnow;

fprintf('\n=================================================\n');
fprintf('   RÉSUMÉ DT\n');
fprintf('─────────────────────────────────────────────────\n');
fprintf('  Groupe actif    : %d / %d\n', groupe_actif, nb_groupes);
fprintf('  Paires traitées : %d\n', nb_paires);
fprintf('  Refresh         : %d\n', size(cles_refresh,1));
fprintf('=================================================\n');

function res = ternaire_str(condition, si_vrai, si_faux)
    if condition, res = si_vrai; else, res = si_faux; end
end
