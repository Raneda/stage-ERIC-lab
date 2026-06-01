% =========================================================
%   JUMEAU NUMÉRIQUE (DT) — Phase 1 / Option A
%   Groupes dynamiques par voisinage
%   - Gestionnaire de groupes (1→2→...→N→1)
%   - Évaluation environnement
%   - Mise à jour état par noeud
%   - Simulation / Test sur réplique
%   - Prise de décision
%   - Stockage : états, décisions, logs
% =========================================================
clc;

fprintf('=================================================\n');
fprintf('   JUMEAU NUMÉRIQUE (DT) — Phase 1 / Option A\n');
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
voisins       = transmission.voisins;
x             = transmission.x;
y             = transmission.y;
batterie      = transmission.batterie;
cpu           = transmission.cpu;
n             = transmission.n;
breadth       = transmission.breadth;
R             = transmission.R;

fprintf('[TWINNING]    Réception — %s\n', datestr(transmission.timestamp));
fprintf('[TWINNING]    Groupe actif      : %d / %d\n', groupe_actif, nb_groupes);
fprintf('[TWINNING]    Noeuds du groupe  : %s\n',...
        strjoin(arrayfun(@(v) sprintf('N%d',v), groupes{groupe_actif},...
        'UniformOutput',false), ', '));
fprintf('[TWINNING]    Mémoire des états : Groupe ID=%d | %s\n\n',...
        groupe_actif, datestr(transmission.timestamp));

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
fprintf('[GEST. GROUPES] Rotation : 1 → 2 → ... → %d → 1 (~30s)\n', nb_groupes);

prochain_groupe = mod(groupe_actif, nb_groupes) + 1;

fprintf('[GEST. GROUPES] Groupe actuel   : %d\n', groupe_actif);
fprintf('[GEST. GROUPES] Prochain groupe : %d (dans ~30s)\n\n', prochain_groupe);

% ─────────────────────────────────────────────────────────
% ÉTAPE 4 — ÉVALUATION DE L'ENVIRONNEMENT
% ─────────────────────────────────────────────────────────
fprintf('[ÉVALUATION]  Analyse Groupe %d :\n', groupe_actif);
fprintf('─────────────────────────────────────────────────\n');

for idx = 1:length(etats_actifs)
    e = etats_actifs(idx);
    nb_vois = length(voisins{e.noeud});
    fprintf('  N%d | pos=(%.0f,%.0f) | bat=%.1f%% | cpu=%.1f%% | %d voisin(s)\n',...
            e.noeud, e.x, e.y, e.batterie, e.cpu, nb_vois);
end

bat_moy = mean([etats_actifs.batterie]);
cpu_moy = mean([etats_actifs.cpu]);
fprintf('─────────────────────────────────────────────────\n');
fprintf('[ÉVALUATION]  Batterie moy : %.1f%% | CPU moy : %.1f%%\n\n',...
        bat_moy, cpu_moy);

% Détecter noeuds isolés dans le groupe
noeuds_isoles = [];
for idx = 1:length(etats_actifs)
    if isempty(voisins{etats_actifs(idx).noeud})
        noeuds_isoles(end+1) = etats_actifs(idx).noeud;
    end
end
if ~isempty(noeuds_isoles)
    fprintf('[ÉVALUATION]  ⚠️  Noeuds isolés détectés : %s\n',...
            strjoin(arrayfun(@(v) sprintf('N%d',v), noeuds_isoles,...
            'UniformOutput',false), ', '));
end

% ─────────────────────────────────────────────────────────
% ÉTAPE 5 — MISE À JOUR DE L'ÉTAT PAR NOEUD
% ─────────────────────────────────────────────────────────
fprintf('\n[MISE À JOUR] Synchronisation réplique...\n');

for idx = 1:length(etats_actifs)
    e = etats_actifs(idx);
    x_virt(e.noeud)   = e.x;
    y_virt(e.noeud)   = e.y;
    bat_virt(e.noeud) = e.batterie;
    cpu_virt(e.noeud) = e.cpu;
    fprintf('  N%d : pos=(%.0f,%.0f) bat=%.1f%% cpu=%.1f%%\n',...
            e.noeud, e.x, e.y, e.batterie, e.cpu);
end

% ─────────────────────────────────────────────────────────
% ÉTAPE 6 — SIMULATION / TEST SUR RÉPLIQUE
% ─────────────────────────────────────────────────────────
fprintf('\n[SIMULATION]  Test intégrité sur réplique virtuelle...\n');

test_resultats = true(1, length(etats_actifs));
for idx = 1:length(etats_actifs)
    e        = etats_actifs(idx);
    etat_ref = sprintf('N%d|pos=(%.0f,%.0f)|bat=%.1f|cpu=%.1f',...
                        e.noeud, e.x, e.y, e.batterie, e.cpu);
    hash_ref = num2str(sum(double(etat_ref) .* (1:length(etat_ref))));
    test_ok  = strcmp(e.hash, hash_ref);
    test_resultats(idx) = test_ok;

    if test_ok
        fprintf('  N%d : ✅ État valide\n', e.noeud);
    else
        fprintf('  N%d : ❌ État invalide !\n', e.noeud);
    end
end

sim_ok = all(test_resultats);
if sim_ok
    fprintf('[SIMULATION]  ✅ Tous les états validés\n');
else
    fprintf('[SIMULATION]  ❌ Anomalie détectée\n');
end

% ─────────────────────────────────────────────────────────
% ÉTAPE 7 — PRISE DE DÉCISION
% ─────────────────────────────────────────────────────────
fprintf('\n[DÉCISION]    Analyse...\n');

if ~isempty(noeuds_isoles)
    decision = 'Noeuds isolés détectés';
    action   = sprintf('Augmenter R ou redéployer les noeuds isolés');
elseif ~sim_ok
    decision = 'Alerte — état invalide';
    action   = 'Blocage groupe';
elseif bat_moy < 20
    decision = 'Batterie critique';
    action   = 'Rotation urgente';
elseif cpu_moy > 80
    decision = 'CPU surchargé';
    action   = 'Allègement traitement';
else
    decision = 'Nominal';
    action   = sprintf('Rotation → Groupe %d dans ~30s', prochain_groupe);
end

fprintf('[DÉCISION]    État  : %s\n', decision);
fprintf('[DÉCISION]    Action: %s\n', action);

% ─────────────────────────────────────────────────────────
% ÉTAPE 8 — STOCKAGE
% ─────────────────────────────────────────────────────────
log_entry.timestamp      = datetime('now');
log_entry.groupe_actif   = groupe_actif;
log_entry.prochain       = prochain_groupe;
log_entry.nb_groupes     = nb_groupes;
log_entry.etats          = etats_actifs;
log_entry.bat_moy        = bat_moy;
log_entry.cpu_moy        = cpu_moy;
log_entry.sim_ok         = sim_ok;
log_entry.noeuds_isoles  = noeuds_isoles;
log_entry.decision       = decision;
log_entry.action         = action;

if exist('stockage_dt.mat','file')
    load('stockage_dt.mat','logs');
    logs{end+1} = log_entry;
else
    logs = {log_entry};
end
save('stockage_dt.mat','logs');
fprintf('\n[STOCKAGE]    ✅ États · Décisions · Logs sauvegardés\n');
fprintf('[STOCKAGE]    Total entrées : %d\n', length(logs));

% ─────────────────────────────────────────────────────────
% ÉTAPE 9 — SUBSCRIBE : envoi décision → Rx physique
% ─────────────────────────────────────────────────────────
reponse.groupe_actif    = groupe_actif;
reponse.prochain_groupe = prochain_groupe;
reponse.nb_groupes      = nb_groupes;
reponse.decision        = decision;
reponse.action          = action;
reponse.sim_ok          = sim_ok;
reponse.timestamp       = datetime('now');

save('decision_jumeau.mat','reponse');
fprintf('[SUBSCRIBE]   ✅ Décision envoyée → Rx physique\n');

% ─────────────────────────────────────────────────────────
% ÉTAPE 10 — AFFICHAGE DT
% ─────────────────────────────────────────────────────────
couleurs = lines(nb_groupes);

figure('Name','DT — Jumeau numérique (Groupes dynamiques)',...
       'NumberTitle','off','Position',[770 80 700 600]);
hold on;

% Liens de voisinage sur réplique
for i = 1:n
    for j = voisins{i}
        if j > i
            line([x_virt(i) x_virt(j)],[y_virt(i) y_virt(j)],...
                 'Color',[0.75 0.75 0.75],'LineWidth',1,'LineStyle','--');
        end
    end
end

% Noeuds virtuels
h_leg = gobjects(nb_groupes,1);
for i = 1:n
    gk = appartient(i);
    c  = couleurs(gk,:);
    if gk == groupe_actif, t = 180; else, t = 110; end
    scatter(x_virt(i), y_virt(i), t, 'o',...
            'MarkerEdgeColor',c,'MarkerFaceColor',c);
    text(x_virt(i), y_virt(i)+22,...
         sprintf('N%d*\nbat:%.0f%%\ncpu:%.0f%%',...
                 i, bat_virt(i), cpu_virt(i)),...
         'FontSize',7,'HorizontalAlignment','center',...
         'FontWeight','bold','Color',c);
end

% Légende
for k = 1:nb_groupes
    c = couleurs(k,:);
    if k == groupe_actif
        lbl = sprintf('Réplique Groupe %d (Actif)', k);
        t   = 180;
    else
        lbl = sprintf('Réplique Groupe %d (Attente)', k);
        t   = 110;
    end
    h_leg(k) = scatter(nan,nan,t,'o',...
                       'MarkerEdgeColor',c,'MarkerFaceColor',c,...
                       'DisplayName',lbl);
end

xlim([0 breadth]); ylim([0 breadth]);
title(sprintf('DT — Groupe actif : %d → %d | %s',...
      groupe_actif, prochain_groupe, decision),'FontWeight','bold');
xlabel('X (m)'); ylabel('Y (m)');
legend(h_leg,'Location','northeast');
grid on;
drawnow;

fprintf('\n=================================================\n');
fprintf('   RÉSUMÉ DT\n');
fprintf('─────────────────────────────────────────────────\n');
fprintf('  Groupe actif    : %d / %d\n', groupe_actif, nb_groupes);
fprintf('  Prochain groupe : %d\n', prochain_groupe);
fprintf('  Batterie moy    : %.1f%%\n', bat_moy);
fprintf('  CPU moy         : %.1f%%\n', cpu_moy);
fprintf('  Simulation      : %s\n', ternaire_str(sim_ok,'✅ OK','❌ Échec'));
fprintf('  Décision        : %s\n', decision);
fprintf('  Action          : %s\n', action);
fprintf('=================================================\n');

function res = ternaire_str(condition, si_vrai, si_faux)
    if condition, res = si_vrai; else, res = si_faux; end
end