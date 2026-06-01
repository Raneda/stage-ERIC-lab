% =========================================================
%   JUMEAU NUMÉRIQUE (DT) — V2 (Sans flux entre nœuds)
%   Focus : communication, mise à jour états, rotation groupes
%   - Gestionnaire de groupes (A→B→C→A)
%   - Évaluation environnement
%   - Mise à jour état par noeud (position, batterie, CPU)
%   - Simulation / Test
%   - Prise de décision
%   - Stockage : états, décisions, logs
% =========================================================
clc;

fprintf('=================================================\n');
fprintf('   JUMEAU NUMÉRIQUE (DT)\n');
fprintf('=================================================\n\n');

% ─────────────────────────────────────────────────────────
% ÉTAPE 1 — RÉCEPTION VIA LE TWINNING
% ─────────────────────────────────────────────────────────
if ~exist('canal_twinning.mat','file')
    error('❌ Lance reseau_physique.m d''abord.');
end

load('canal_twinning.mat');

groupe_actif = transmission.groupe_actif;
etats_A      = transmission.etats_A;
x            = transmission.x;
y            = transmission.y;
batterie     = transmission.batterie;
cpu          = transmission.cpu;
n            = transmission.n;
breadth      = transmission.breadth;
groupes      = transmission.groupes;
push_B       = transmission.push_B;
push_C       = transmission.push_C;

fprintf('[TWINNING]    Réception — %s\n', datestr(transmission.timestamp));
fprintf('[TWINNING]    Groupe actif reçu   : %s\n', groupe_actif);
fprintf('[TWINNING]    Mémoire des états   : Groupe ID=%s | Horodatage=%s\n',...
        groupe_actif, datestr(transmission.timestamp));
fprintf('[TWINNING]    Push Groupe B       : %s | %s\n',...
        push_B.statut, datestr(push_B.timestamp));
fprintf('[TWINNING]    Push Groupe C       : %s | %s\n\n',...
        push_C.statut, datestr(push_C.timestamp));

% ─────────────────────────────────────────────────────────
% ÉTAPE 2 — COPIE VIRTUELLE IDENTIQUE
% ─────────────────────────────────────────────────────────
x_virt   = x;
y_virt   = y;
bat_virt = batterie;
cpu_virt = cpu;

fprintf('[COPIE]       Réplique virtuelle créée — %d noeuds\n\n', n);

% ─────────────────────────────────────────────────────────
% ÉTAPE 3 — GESTIONNAIRE DE GROUPES
% ─────────────────────────────────────────────────────────
fprintf('[GEST. GROUPES] Rotation : A → B → C → A (~30s)\n');

ordre_rotation = {'A','B','C'};
idx_actuel     = find(strcmp(ordre_rotation, groupe_actif));
idx_suivant    = mod(idx_actuel, length(ordre_rotation)) + 1;
prochain_groupe = ordre_rotation{idx_suivant};

fprintf('[GEST. GROUPES] Groupe actuel  : %s\n', groupe_actif);
fprintf('[GEST. GROUPES] Prochain groupe : %s (dans ~30s)\n\n', prochain_groupe);

% ─────────────────────────────────────────────────────────
% ÉTAPE 4 — ÉVALUATION DE L'ENVIRONNEMENT
% ─────────────────────────────────────────────────────────
fprintf('[ÉVALUATION]  Analyse Groupe %s :\n', groupe_actif);
fprintf('─────────────────────────────────────────────────\n');

for idx = 1:length(etats_A)
    e = etats_A(idx);
    fprintf('  N%d | pos=(%.0f,%.0f) | bat=%.1f%% | cpu=%.1f%%\n',...
            e.noeud, e.x, e.y, e.batterie, e.cpu);
end

bat_moy = mean([etats_A.batterie]);
cpu_moy = mean([etats_A.cpu]);
fprintf('─────────────────────────────────────────────────\n');
fprintf('[ÉVALUATION]  Batterie moy : %.1f%% | CPU moy : %.1f%%\n\n',...
        bat_moy, cpu_moy);

% ─────────────────────────────────────────────────────────
% ÉTAPE 5 — MISE À JOUR DE L'ÉTAT PAR NOEUD
% ─────────────────────────────────────────────────────────
fprintf('[MISE À JOUR] Synchronisation réplique...\n');

for idx = 1:length(etats_A)
    e = etats_A(idx);
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

test_resultats = true(1, length(etats_A));
for idx = 1:length(etats_A)
    e         = etats_A(idx);
    etat_ref  = sprintf('N%d|pos=(%.0f,%.0f)|bat=%.1f|cpu=%.1f',...
                         e.noeud, e.x, e.y, e.batterie, e.cpu);
    hash_ref  = num2str(sum(double(etat_ref) .* (1:length(etat_ref))));
    test_ok   = strcmp(e.hash, hash_ref);
    test_resultats(idx) = test_ok;

    if test_ok
        fprintf('  N%d : ✅ État valide\n', e.noeud);
    else
        fprintf('  N%d : ❌ État invalide !\n', e.noeud);
    end
end

sim_ok = all(test_resultats);
if sim_ok
    fprintf('[SIMULATION]  ✅ Tous les états validés sur réplique\n');
else
    fprintf('[SIMULATION]  ❌ Anomalie détectée\n');
end

% ─────────────────────────────────────────────────────────
% ÉTAPE 7 — PRISE DE DÉCISION
% ─────────────────────────────────────────────────────────
fprintf('\n[DÉCISION]    Analyse et décision...\n');

if ~sim_ok
    decision = 'Alerte — état invalide détecté';
    action   = 'Blocage groupe';
elseif bat_moy < 20
    decision = 'Batterie critique';
    action   = 'Rotation urgente vers groupe suivant';
elseif cpu_moy > 80
    decision = 'CPU surchargé';
    action   = 'Allègement traitement';
else
    decision = 'Nominal';
    action   = sprintf('Rotation prévue → Groupe %s dans ~30s', prochain_groupe);
end

fprintf('[DÉCISION]    État  : %s\n', decision);
fprintf('[DÉCISION]    Action: %s\n', action);

% ─────────────────────────────────────────────────────────
% ÉTAPE 8 — STOCKAGE : états, décisions, logs
% ─────────────────────────────────────────────────────────
log_entry.timestamp      = datetime('now');
log_entry.groupe_actif   = groupe_actif;
log_entry.prochain       = prochain_groupe;
log_entry.etats          = etats_A;
log_entry.bat_moy        = bat_moy;
log_entry.cpu_moy        = cpu_moy;
log_entry.sim_ok         = sim_ok;
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
reponse.decision        = decision;
reponse.action          = action;
reponse.sim_ok          = sim_ok;
reponse.timestamp       = datetime('now');

save('decision_jumeau.mat','reponse');
fprintf('[SUBSCRIBE]   ✅ Décision envoyée → Rx physique\n');

% ─────────────────────────────────────────────────────────
% ÉTAPE 10 — AFFICHAGE DT (Flux supprimés)
% ─────────────────────────────────────────────────────────
figure('Name','DT — Jumeau numérique','NumberTitle','off',...
       'Position',[740 80 660 580]);
hold on;

cA = [0.05 0.65 0.35];
cB = [0.95 0.55 0.05];
cC = [0.55 0.55 0.55];

for i = 1:n
    if ismember(i, groupes.A.noeuds),     c=cA; t=160;
    elseif ismember(i, groupes.B.noeuds), c=cB; t=110;
    else,                                  c=cC; t=110;
    end
    scatter(x_virt(i), y_virt(i), t, 'o',...
            'MarkerEdgeColor',c,'MarkerFaceColor',c);
    text(x_virt(i), y_virt(i)+22,...
         sprintf('N%d*\nbat:%.0f%%\ncpu:%.0f%%',...
                 i, bat_virt(i), cpu_virt(i)),...
         'FontSize',7,'HorizontalAlignment','center',...
         'FontWeight','bold','Color',c);
end

% Légende simplifiée sans lignes de flux pour correspondre exactement au schéma
hA = scatter(nan,nan,160,'o','MarkerEdgeColor',cA,'MarkerFaceColor',cA);
hB = scatter(nan,nan,110,'o','MarkerEdgeColor',cB,'MarkerFaceColor',cB);
hC = scatter(nan,nan,110,'o','MarkerEdgeColor',cC,'MarkerFaceColor',cC);

xlim([0 breadth]); ylim([0 breadth]);
title(sprintf('DT — Jumeau numérique | Groupe actif : %s → %s | %s',...
      groupe_actif, prochain_groupe, decision),'FontWeight','bold');
xlabel('X (m)'); ylabel('Y (m)');
legend([hA hB hC],...
       'Réplique Groupe A (Actif)',...
       'Réplique Groupe B (Attente)',...
       'Réplique Groupe C (Attente)',...
       'Location','northeast');
grid on;
drawnow;

fprintf('\n=================================================\n');
fprintf('   RÉSUMÉ DT\n');
fprintf('─────────────────────────────────────────────────\n');
fprintf('  Groupe actif   : %s\n', groupe_actif);
fprintf('  Prochain groupe : %s\n', prochain_groupe);
fprintf('  Batterie moy   : %.1f%%\n', bat_moy);
fprintf('  CPU moy        : %.1f%%\n', cpu_moy);
fprintf('  Simulation     : %s\n', ternaire_str(sim_ok,'✅ OK','❌ Échec'));
fprintf('  Décision       : %s\n', decision);
fprintf('  Action         : %s\n', action);
fprintf('=================================================\n');

function res = ternaire_str(condition, si_vrai, si_faux)
    if condition, res = si_vrai; else, res = si_faux; end
end