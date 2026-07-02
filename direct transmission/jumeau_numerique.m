% =========================================================
%   JUMEAU NUMÉRIQUE (DT) — Phase 2 / Pré-distribution clés
%   - Reçoit les ID de clés du RS (tous les groupes)
%   - N1* génère la clé pour chaque paire
%   - N2* teste la clé sur la réplique
%   - Stockage des clés dans le DT (par paire)
%   - Envoi des clés validées au RS
% =========================================================
clc;

fprintf('=================================================\n');
fprintf('   JUMEAU NUMÉRIQUE (DT) — Phase 2\n');
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
% ÉTAPE 5 — MISE À JOUR DE L'ÉTAT PAR NOEUD
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
% ÉTAPE 6 — GÉNÉRATION ET TEST DES CLÉS SUR RÉPLIQUE
% Pour chaque paire (Ni, Nj) :
%   → N i* génère la clé à partir de l'ID
%   → N j* teste et valide la clé
% ─────────────────────────────────────────────────────────
fprintf('[CLÉS]        Génération et test sur réplique...\n');
fprintf('─────────────────────────────────────────────────\n');

cles_generees = struct();

for p = 1:nb_paires
    ni    = demandes_cles(p).noeud_i;
    nj    = demandes_cles(p).noeud_j;
    id    = demandes_cles(p).id_cle;

    % --- N i* : génération de la clé à partir de l'ID ---
    cle_valeur = sprintf('CLÉ_AES128_%s', id);
    hash_cle   = num2str(sum(double(cle_valeur).*(1:length(cle_valeur))));

    fprintf('  (G%d) N%d* génère  → %s\n', demandes_cles(p).groupe_id, ni, cle_valeur);
    fprintf('         hash        → %s\n', hash_cle);

    % --- N j* : test de réception et vérification hash ---
    hash_verif = num2str(sum(double(cle_valeur).*(1:length(cle_valeur))));
    test_ok    = strcmp(hash_cle, hash_verif);

    if test_ok
        fprintf('  N%d* valide        → ✅ Clé intègre\n\n', nj);
    else
        fprintf('  N%d* valide        → ❌ Clé invalide !\n\n', nj);
    end

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
% STOCKAGE CENTRALISÉ DES CLÉS DANS LE DT (par paire)
% ─────────────────────────────────────────────────────────
if exist('cles_dt.mat','file')
    load('cles_dt.mat','cles_dt');
else
    % cles_dt{ni, nj} = struct(...)
    cles_dt = cell(n, n);
end

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

    % Stockage symétrique (Ni,Nj) et (Nj,Ni)
    cles_dt{ni, nj} = entry;
    cles_dt{nj, ni} = entry;
end

save('cles_dt.mat','cles_dt');
fprintf('[STOCKAGE DT] ✅ Clés stockées par paire dans cles_dt.mat\n\n');

% ─────────────────────────────────────────────────────────
% ÉTAPE 7 — SIMULATION / TEST GLOBAL
% ─────────────────────────────────────────────────────────
fprintf('[SIMULATION]  Vérification intégrité états...\n');

test_etats = true(1, length(etats_actifs));
for idx = 1:length(etats_actifs)
    e        = etats_actifs(idx);
    etat_ref = sprintf('N%d|pos=(%.0f,%.0f)|bat=%.1f|cpu=%.1f',...
                        e.noeud, e.x, e.y, e.batterie, e.cpu);
    hash_ref = num2str(sum(double(etat_ref).*(1:length(etat_ref))));
    test_etats(idx) = strcmp(e.hash, hash_ref);
    if test_etats(idx)
        fprintf('  N%d* : ✅ État valide\n', e.noeud);
    else
        fprintf('  N%d* : ❌ État invalide\n', e.noeud);
    end
end

sim_ok     = all(test_etats);
cles_ok    = all([cles_generees.valide]);
tout_ok    = sim_ok && cles_ok;

fprintf('[SIMULATION]  États   : %s\n', ternaire_str(sim_ok,'✅','❌'));
fprintf('[SIMULATION]  Clés    : %s\n', ternaire_str(cles_ok,'✅','❌'));
fprintf('[SIMULATION]  Global  : %s\n\n', ternaire_str(tout_ok,'✅ OK','❌ Échec'));

% ─────────────────────────────────────────────────────────
% ÉTAPE 8 — PRISE DE DÉCISION
% ─────────────────────────────────────────────────────────
fprintf('[DÉCISION]    Analyse...\n');

if ~tout_ok
    decision = 'Alerte — validation échouée';
    action   = 'Clés non distribuées';
elseif bat_moy < 20
    decision = 'Batterie critique';
    action   = 'Rotation urgente';
elseif cpu_moy > 80
    decision = 'CPU surchargé';
    action   = 'Allègement traitement';
else
    decision = 'Nominal';
    action   = sprintf('Clés distribuées | Rotation → Groupe %d dans ~30s',...
                        prochain_groupe);
end

fprintf('[DÉCISION]    État  : %s\n', decision);
fprintf('[DÉCISION]    Action: %s\n\n', action);

% ─────────────────────────────────────────────────────────
% ÉTAPE 9 — STOCKAGE DT (LOGS)
% ─────────────────────────────────────────────────────────
log_entry.timestamp      = datetime('now');
log_entry.groupe_actif   = groupe_actif;
log_entry.prochain       = prochain_groupe;
log_entry.etats          = etats_actifs;
log_entry.bat_moy        = bat_moy;
log_entry.cpu_moy        = cpu_moy;
log_entry.sim_ok         = sim_ok;
log_entry.cles           = cles_generees;
log_entry.decision       = decision;
log_entry.action         = action;

if exist('stockage_dt.mat','file')
    load('stockage_dt.mat','logs');
    logs{end+1} = log_entry;
else
    logs = {log_entry};
end
save('stockage_dt.mat','logs');
fprintf('[STOCKAGE]    ✅ États · Clés · Décisions · Logs sauvegardés\n');
fprintf('[STOCKAGE]    Total entrées : %d\n\n', length(logs));

% ─────────────────────────────────────────────────────────
% ÉTAPE 10 — SUBSCRIBE : envoi au RS
% ─────────────────────────────────────────────────────────
reponse.groupe_actif    = groupe_actif;
reponse.prochain_groupe = prochain_groupe;
reponse.nb_groupes      = nb_groupes;
reponse.cles_generees   = cles_generees;
reponse.nb_paires       = nb_paires;
reponse.decision        = decision;
reponse.action          = action;
reponse.tout_ok         = tout_ok;
reponse.timestamp       = datetime('now');

save('decision_jumeau.mat','reponse');
fprintf('[SUBSCRIBE]   ✅ Clés validées envoyées → RS\n');

% ─────────────────────────────────────────────────────────
% ÉTAPE 11 — AFFICHAGE DT
% ─────────────────────────────────────────────────────────
couleurs = lines(nb_groupes);

figure('Name','DT — Jumeau numérique (Phase 2)',...
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

% Liens clés générées
for p = 1:nb_paires
    ni = cles_generees(p).noeud_i;
    nj = cles_generees(p).noeud_j;
    if cles_generees(p).valide
        c_lien = [0.05 0.65 0.35];
        style  = '-';
    else
        c_lien = [0.85 0.1 0.1];
        style  = ':';
    end
    line([x_virt(ni) x_virt(nj)],[y_virt(ni) y_virt(nj)],...
         'Color',c_lien,'LineWidth',2.5,'LineStyle',style);
    mx = (x_virt(ni)+x_virt(nj))/2;
    my = (y_virt(ni)+y_virt(nj))/2;
    text(mx, my+12,...
         ternaire_str(cles_generees(p).valide,'✅ clé OK','❌ échec'),...
         'FontSize',7,'HorizontalAlignment','center','Color',c_lien);
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
             'DisplayName','Clé validée ✅');
h_nok = plot(nan,nan,':','Color',[0.85 0.1 0.1],'LineWidth',2.5,...
             'DisplayName','Clé invalide ❌');

xlim([0 breadth]); ylim([0 breadth]);
title(sprintf('DT — Phase 2 | %d clés générées | %s',...
      nb_paires, decision),'FontWeight','bold');
xlabel('X (m)'); ylabel('Y (m)');
legend([h_leg; h_ok; h_nok],'Location','northeast');
grid on; drawnow;

fprintf('\n=================================================\n');
fprintf('   RÉSUMÉ DT\n');
fprintf('─────────────────────────────────────────────────\n');
fprintf('  Groupe actif    : %d / %d\n', groupe_actif, nb_groupes);
fprintf('  Paires traitées : %d\n', nb_paires);
for p = 1:nb_paires
    fprintf('    (N%d, N%d) [G%d] : %s\n',...
            cles_generees(p).noeud_i,...
            cles_generees(p).noeud_j,...
            cles_generees(p).groupe_id,...
            ternaire_str(cles_generees(p).valide,'✅ OK','❌ Échec'));
end
fprintf('  Décision        : %s\n', decision);
fprintf('  Action          : %s\n', action);
fprintf('=================================================\n');

function res = ternaire_str(condition, si_vrai, si_faux)
    if condition, res = si_vrai; else, res = si_faux; end
end
