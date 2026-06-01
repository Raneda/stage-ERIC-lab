% =========================================================
%   MAIN SIMULATION — Phase 1 / Option A
%   Orchestre RS → Twinning → DT → Rx
% =========================================================
clc; clear; close all;

fprintf('=================================================\n');
fprintf('   SIMULATION — Phase 1 / Groupes dynamiques\n');
fprintf('=================================================\n\n');

% ─────────────────────────────────────────────────────────
% ÉTAPE 1 — RÉSEAU PHYSIQUE : déploiement + voisinage + Tx
% ─────────────────────────────────────────────────────────
fprintf('>>> ÉTAPE 1 : RÉSEAU PHYSIQUE (RS) — Tx\n');
fprintf('─────────────────────────────────────────────────\n');
reseau_physique;

% ─────────────────────────────────────────────────────────
% ÉTAPE 2 — JUMEAU NUMÉRIQUE : évaluation + décision
% ─────────────────────────────────────────────────────────
fprintf('\n>>> ÉTAPE 2 : JUMEAU NUMÉRIQUE (DT)\n');
fprintf('─────────────────────────────────────────────────\n');
jumeau_numerique;

% ─────────────────────────────────────────────────────────
% ÉTAPE 3 — RÉSEAU PHYSIQUE : Rx + application locale
% ─────────────────────────────────────────────────────────
fprintf('\n>>> ÉTAPE 3 : RÉSEAU PHYSIQUE (RS) — Rx\n');
fprintf('─────────────────────────────────────────────────\n');

load('decision_jumeau.mat');

fprintf('[Rx]          Instructions reçues du DT\n');
fprintf('[Rx]          Groupe actif    : %d / %d\n',...
        reponse.groupe_actif, reponse.nb_groupes);
fprintf('[Rx]          Prochain groupe : %d\n', reponse.prochain_groupe);
fprintf('[Rx]          Décision        : %s\n', reponse.decision);
fprintf('[Rx]          Action          : %s\n', reponse.action);
fprintf('[Rx]          Simulation      : %s\n',...
        ternaire_str(reponse.sim_ok,'✅ OK','❌ Échec'));

fprintf('\n[APPLICATION] ✅ Instructions appliquées localement\n');

fprintf('\n=================================================\n');
fprintf('   SIMULATION TERMINÉE\n');
fprintf('   Prochain cycle : Groupe %d dans ~30s\n', reponse.prochain_groupe);
fprintf('=================================================\n');

function res = ternaire_str(condition, si_vrai, si_faux)
    if condition, res = si_vrai; else, res = si_faux; end
end

