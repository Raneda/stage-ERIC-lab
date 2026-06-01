% =========================================================
%   MAIN SIMULATION
%   Orchestre RS → DT → Rx
% =========================================================
clc; clear; close all;
fprintf('=================================================\n');
fprintf('   SIMULATION — RS / TWINNING / DT\n');
fprintf('=================================================\n\n');
fprintf('>>> ÉTAPE 1 : RÉSEAU PHYSIQUE (RS) — Tx\n');
fprintf('─────────────────────────────────────────────────\n');
reseau_physique;
fprintf('\n>>> ÉTAPE 2 : JUMEAU NUMÉRIQUE (DT)\n');
fprintf('─────────────────────────────────────────────────\n');
jumeau_numerique;
fprintf('\n>>> ÉTAPE 3 : RÉSEAU PHYSIQUE (RS) — Rx\n');
fprintf('─────────────────────────────────────────────────\n');
load('decision_jumeau.mat');
fprintf('[Rx]          Instructions reçues du DT\n');
fprintf('[Rx]          Groupe actif    : %s\n', reponse.groupe_actif);
fprintf('[Rx]          Prochain groupe : %s\n', reponse.prochain_groupe);
fprintf('[Rx]          Décision        : %s\n', reponse.decision);
fprintf('[Rx]          Action          : %s\n', reponse.action);
fprintf('[Rx]          Simulation      : %s\n',...
        ternaire_str(reponse.sim_ok,'✅ OK','❌ Échec'));
fprintf('\n[APPLICATION] ✅ Instructions appliquées localement\n');
fprintf('\n=================================================\n');
fprintf('   SIMULATION TERMINÉE\n');
fprintf('=================================================\n');
function res = ternaire_str(condition, si_vrai, si_faux)
    if condition, res = si_vrai; else, res = si_faux; end
end

