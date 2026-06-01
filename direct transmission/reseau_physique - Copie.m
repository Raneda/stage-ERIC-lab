% =========================================================
%   RÉSEAU PHYSIQUE (CPS)
%   - 10 noeuds déployés aléatoirement
%   - Noeud 1 veut communiquer avec Noeud 2
%   - Envoie le hash de sa clé au jumeau
%   - La réception de la clé se fait après le jumeau
% =========================================================
clc; clear; close all;

fprintf('=================================================\n');
fprintf('   RÉSEAU PHYSIQUE — CPS\n');
fprintf('=================================================\n\n');

% ─────────────────────────────────────────────────────────
% PARAMÈTRES — modifiables
% ─────────────────────────────────────────────────────────
n       = 10;
breadth = 500;
SinkX   = 250;
SinkY   = 250;

noeud_emetteur  = 1;
noeud_recepteur = 2;

% ─────────────────────────────────────────────────────────
% ÉTAPE 1 — DÉPLOIEMENT ALÉATOIRE
% ─────────────────────────────────────────────────────────
x = breadth * rand(1, n);
y = breadth * rand(1, n);

fprintf('[DÉPLOIEMENT] %d noeuds déployés aléatoirement\n', n);
for i = 1:n
    fprintf('  Noeud %2d : (%.0f, %.0f)\n', i, x(i), y(i));
end

% ─────────────────────────────────────────────────────────
% ÉTAPE 2 — CLÉ ACTUELLE DU NOEUD 1
% ─────────────────────────────────────────────────────────
fprintf('\n[NOEUD %d]     Préparation de la communication...\n', noeud_emetteur);

cle_noeud1  = sprintf('Cle_Noeud%d_AES128_Initial', noeud_emetteur);
hash_noeud1 = num2str(sum(double(cle_noeud1) .* (1:length(cle_noeud1))));

fprintf('[NOEUD %d]     Clé actuelle : %s\n', noeud_emetteur, cle_noeud1);
fprintf('[NOEUD %d]     Hash calculé : %s\n', noeud_emetteur, hash_noeud1);
fprintf('[NOEUD %d]     → Veut communiquer avec Noeud %d\n',...
        noeud_emetteur, noeud_recepteur);

% ─────────────────────────────────────────────────────────
% ÉTAPE 3 — ENVOI AU JUMEAU (canal Twinning)
% ─────────────────────────────────────────────────────────
demande.noeud_emetteur  = noeud_emetteur;
demande.noeud_recepteur = noeud_recepteur;
demande.hash_cle        = hash_noeud1;
demande.x               = x;
demande.y               = y;
demande.n               = n;
demande.breadth         = breadth;
demande.SinkX           = SinkX;
demande.SinkY           = SinkY;
demande.timestamp       = datetime('now');

save('canal_twinning.mat', 'demande');
fprintf('\n[TWINNING]    ✅ Hash envoyé au jumeau numérique.\n');
fprintf('[TWINNING]    En attente de la réponse...\n');

% ─────────────────────────────────────────────────────────
% ÉTAPE 4 — AFFICHAGE RÉSEAU (avant réception clé)
% ─────────────────────────────────────────────────────────
figure('Name','RÉSEAU PHYSIQUE — CPS','NumberTitle','off',...
       'Position',[50 100 660 560]);

scatter(SinkX, SinkY, 300, 'diamond', 'filled',...
        'MarkerFaceColor',[0.1 0.1 0.8],'MarkerEdgeColor','k');
hold on;

for i = 1:n
    if i == noeud_emetteur
        couleur = [0.9 0.4 0];
        taille  = 160;
    elseif i == noeud_recepteur
        couleur = [0.1 0.7 0.1];
        taille  = 160;
    else
        couleur = [0 0.6 0.7];
        taille  = 80;
    end
    scatter(x(i), y(i), taille,...
            'MarkerEdgeColor', couleur,...
            'MarkerFaceColor', couleur);
    text(x(i), y(i)+18, sprintf('N%d', i),...
         'FontSize', 9, 'HorizontalAlignment','center',...
         'FontWeight','bold','Color', couleur);
    line([x(i) SinkX],[y(i) SinkY],...
         'Color',[0.85 0.85 0.85 0.2],'LineWidth',0.6);
end

% Lien emetteur → recepteur (en attente)
line([x(noeud_emetteur) x(noeud_recepteur)],...
     [y(noeud_emetteur) y(noeud_recepteur)],...
     'Color',[0.9 0.3 0],'LineWidth',2,'LineStyle',':');

xlim([0 breadth]); ylim([0 breadth]);
title(sprintf('RÉSEAU PHYSIQUE — Noeud %d → Noeud %d | En attente du jumeau...',...
      noeud_emetteur, noeud_recepteur),'FontWeight','bold');
xlabel('X (m)'); ylabel('Y (m)');
legend('Sink (Jumeau)',...
       sprintf('Noeud %d (émetteur)', noeud_emetteur),...
       sprintf('Noeud %d (récepteur)', noeud_recepteur),...
       'Autres noeuds','Location','northeast');
grid on;
drawnow;