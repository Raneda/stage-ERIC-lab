% =========================================================
%   RÉSEAU PHYSIQUE (RS) — V2 (Sans flux entre nœuds)
%   Focus : communication, groupes, états
%   - 9 noeuds en 3 groupes (A, B, C)
%   - Groupe A : actif en traitement
%   - Groupe B : en attente (push 30s simulé)
%   - Groupe C : en attente
%   - Modules sécurité : chiffrement + hachage
%   - Tx : émission état chiffré + Groupe ID
%   - Rx : réception instructions validées
%   - Application locale
% =========================================================
clc; clear; close all;

fprintf('=================================================\n');
fprintf('   RÉSEAU PHYSIQUE (RS)\n');
fprintf('=================================================\n\n');

% ─────────────────────────────────────────────────────────
% PARAMÈTRES
% ─────────────────────────────────────────────────────────
n       = 9;
breadth = 500;

% ─────────────────────────────────────────────────────────
% ÉTAPE 1 — DÉPLOIEMENT ALÉATOIRE
% ─────────────────────────────────────────────────────────
x = breadth * rand(1, n);
y = breadth * rand(1, n);

fprintf('[DÉPLOIEMENT] %d noeuds déployés aléatoirement\n\n', n);

% ─────────────────────────────────────────────────────────
% ÉTAPE 2 — DÉFINITION DES GROUPES
% ─────────────────────────────────────────────────────────
groupes.A.noeuds = [1, 2, 3];
groupes.A.statut = 'actif';
groupes.B.noeuds = [4, 5, 6];
groupes.B.statut = 'attente';
groupes.C.noeuds = [7, 8, 9];
groupes.C.statut = 'attente';

fprintf('[GROUPES]     Groupe A (actif)   : N%d N%d N%d\n',...
        groupes.A.noeuds);
fprintf('[GROUPES]     Groupe B (attente) : N%d N%d N%d\n',...
        groupes.B.noeuds);
fprintf('[GROUPES]     Groupe C (attente) : N%d N%d N%d\n\n',...
        groupes.C.noeuds);

% ─────────────────────────────────────────────────────────
% ÉTAPE 3 — ÉTATS PAR NOEUD
% Position (x,y) + batterie + CPU simulés
% ─────────────────────────────────────────────────────────
batterie = 40 + 60 * rand(1, n);
cpu      = 20 + 60 * rand(1, n);

fprintf('[ÉTATS]       État initial par noeud :\n');
for i = 1:n
    if ismember(i, groupes.A.noeuds),      grp = 'A';
    elseif ismember(i, groupes.B.noeuds),  grp = 'B';
    else,                                   grp = 'C';
    end
    fprintf('  N%d [Grp %s] pos=(%.0f,%.0f) bat=%.1f%% cpu=%.1f%%\n',...
            i, grp, x(i), y(i), batterie(i), cpu(i));
end

% ─────────────────────────────────────────────────────────
% ÉTAPE 4 — MODULES DE SÉCURITÉ (Groupe A uniquement)
% Chiffrement simulé + Hachage de l'état
% ─────────────────────────────────────────────────────────
fprintf('\n[MODULES SÉC] Traitement Groupe A...\n');

etats_A = struct();
for idx = 1:length(groupes.A.noeuds)
    i            = groupes.A.noeuds(idx);
    etat_clair   = sprintf('N%d|pos=(%.0f,%.0f)|bat=%.1f|cpu=%.1f',...
                            i, x(i), y(i), batterie(i), cpu(i));
    hash_etat    = num2str(sum(double(etat_clair) .* (1:length(etat_clair))));
    etat_chiffre = sprintf('ENC[%s]', etat_clair);

    fprintf('  N%d : hash=%s\n', i, hash_etat);

    etats_A(idx).noeud        = i;
    etats_A(idx).groupe_id    = 'A';
    etats_A(idx).x            = x(i);
    etats_A(idx).y            = y(i);
    etats_A(idx).batterie     = batterie(i);
    etats_A(idx).cpu          = cpu(i);
    etats_A(idx).hash         = hash_etat;
    etats_A(idx).etat_chiffre = etat_chiffre;
    etats_A(idx).timestamp    = datetime('now');
end

% ─────────────────────────────────────────────────────────
% ÉTAPE 5 — Tx : ÉMISSION (→ Twinning)
% Groupe A : flux actif
% Groupes B,C : push périodique simulé (attente)
% ─────────────────────────────────────────────────────────
fprintf('\n[Tx]          Émission Groupe A → Twinning\n');

transmission.groupe_actif   = 'A';
transmission.etats_A        = etats_A;
transmission.x              = x;
transmission.y              = y;
transmission.batterie       = batterie;
transmission.cpu            = cpu;
transmission.n              = n;
transmission.breadth        = breadth;
transmission.groupes        = groupes;
transmission.timestamp      = datetime('now');

% Push périodique simulé pour groupes en attente
transmission.push_B.groupe    = 'B';
transmission.push_B.statut    = 'attente';
transmission.push_B.timestamp = datetime('now');
transmission.push_C.groupe    = 'C';
transmission.push_C.statut    = 'attente';
transmission.push_C.timestamp = datetime('now');

save('canal_twinning.mat', 'transmission');
fprintf('[Tx]          ✅ État Groupe A émis\n');
fprintf('[Tx]          Groupes B,C : push périodique enregistré\n');

% ─────────────────────────────────────────────────────────
% ÉTAPE 6 — AFFICHAGE RS (Flux supprimés)
% ─────────────────────────────────────────────────────────
figure('Name','RS — Réseau physique','NumberTitle','off',...
       'Position',[50 80 660 580]);
hold on;

cA = [0.05 0.65 0.35];
cB = [0.95 0.55 0.05];
cC = [0.55 0.55 0.55];

for i = 1:n
    if ismember(i, groupes.A.noeuds),     c=cA; t=160;
    elseif ismember(i, groupes.B.noeuds), c=cB; t=110;
    else,                                  c=cC; t=110;
    end
    scatter(x(i), y(i), t, 'o',...
            'MarkerEdgeColor',c,'MarkerFaceColor',c);
    text(x(i), y(i)+22,...
         sprintf('N%d\nbat:%.0f%%\ncpu:%.0f%%', i, batterie(i), cpu(i)),...
         'FontSize',7,'HorizontalAlignment','center',...
         'FontWeight','bold','Color',c);
end

% Légendes fictives adaptées à la vue par groupes (sans lignes)
hA  = scatter(nan,nan,160,'o','MarkerEdgeColor',cA,'MarkerFaceColor',cA);
hB  = scatter(nan,nan,110,'o','MarkerEdgeColor',cB,'MarkerFaceColor',cB);
hC  = scatter(nan,nan,110,'o','MarkerEdgeColor',cC,'MarkerFaceColor',cC);

xlim([0 breadth]); ylim([0 breadth]);
title('RS — Réseau physique | Groupe A actif | B,C en attente',...
      'FontWeight','bold');
xlabel('X (m)'); ylabel('Y (m)');
legend([hA hB hC],...
       'Groupe A (Actif — Traitement)',...
       'Groupe B (En attente — Push 30s)',...
       'Groupe C (En attente)',...
       'Location','northeast');
grid on;
drawnow;

fprintf('\n=================================================\n');
fprintf('   FIN RS — Lance jumeau_numerique.m\n');
fprintf('=================================================\n');