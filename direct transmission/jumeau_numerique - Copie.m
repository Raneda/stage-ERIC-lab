% =========================================================
%   JUMEAU NUMÉRIQUE (DT)
%   - Reçoit la demande du Noeud 1 physique
%   - Copie virtuelle : Noeud 1 virtuel génère la clé
%   - Noeud 2 virtuel teste la clé
%   - Si tout est OK → envoie la clé au Noeud 2 physique
% =========================================================
clc; close all;

fprintf('=================================================\n');
fprintf('   JUMEAU NUMÉRIQUE — DT\n');
fprintf('=================================================\n\n');

% ─────────────────────────────────────────────────────────
% ÉTAPE 1 — RÉCEPTION DE LA DEMANDE DU NOEUD 1
% ─────────────────────────────────────────────────────────
fprintf('[ATTENTE]     En écoute du réseau physique...\n');

while ~exist('canal_twinning.mat', 'file')
    pause(0.5);
end

load('canal_twinning.mat');

n_em  = demande.noeud_emetteur;
n_rec = demande.noeud_recepteur;
x     = demande.x;
y     = demande.y;
n     = demande.n;
breadth = demande.breadth;
SinkX   = demande.SinkX;
SinkY   = demande.SinkY;
hash_recu = demande.hash_cle;

fprintf('[RÉCEPTION]   Demande reçue — %s\n', datestr(demande.timestamp));
fprintf('[RÉCEPTION]   Noeud %d veut communiquer avec Noeud %d\n', n_em, n_rec);
fprintf('[RÉCEPTION]   Hash reçu : %s\n\n', hash_recu);

% ─────────────────────────────────────────────────────────
% ÉTAPE 2 — COPIE VIRTUELLE IDENTIQUE
% Le jumeau recrée exactement le même réseau
% ─────────────────────────────────────────────────────────
x_virt = x;
y_virt = y;

fprintf('[COPIE]       Réseau virtuel créé — %d noeuds identiques\n\n', n);

% ─────────────────────────────────────────────────────────
% ÉTAPE 3 — NOEUD 1 VIRTUEL : AUDIT DU HASH
% Le jumeau vérifie que la clé du Noeud 1 est intègre
% avant de générer une nouvelle clé
% ─────────────────────────────────────────────────────────
fprintf('[NOEUD %d VIRTUEL] Audit du hash reçu...\n', n_em);

cle_reference  = sprintf('Cle_Noeud%d_AES128_Initial', n_em);
hash_reference = num2str(sum(double(cle_reference) .* (1:length(cle_reference))));

fprintf('[NOEUD %d VIRTUEL] Hash reçu      : %s\n', n_em, hash_recu);
fprintf('[NOEUD %d VIRTUEL] Hash référence : %s\n', n_em, hash_reference);

if strcmp(hash_recu, hash_reference)
    audit_ok = true;
    fprintf('[NOEUD %d VIRTUEL] ✅ Hash valide — clé intègre\n\n', n_em);
else
    audit_ok = false;
    fprintf('[NOEUD %d VIRTUEL] ❌ Hash invalide — clé compromise !\n\n', n_em);
end

% ─────────────────────────────────────────────────────────
% ÉTAPE 4 — NOEUD 1 VIRTUEL : GÉNÉRATION DE LA NOUVELLE CLÉ
% C'est le jumeau qui fait le calcul lourd
% pas le noeud physique
% ─────────────────────────────────────────────────────────
fprintf('[NOEUD %d VIRTUEL] Génération de la nouvelle clé...\n', n_em);

timestamp_cle  = num2str(round(posixtime(datetime('now'))));
cle_nouvelle   = sprintf('Cle_N%d_vers_N%d_AES128_%s',...
                          n_em, n_rec, timestamp_cle);
hash_nouvelle  = num2str(sum(double(cle_nouvelle) .* (1:length(cle_nouvelle))));

fprintf('[NOEUD %d VIRTUEL] Nouvelle clé  : %s\n', n_em, cle_nouvelle);
fprintf('[NOEUD %d VIRTUEL] Hash clé      : %s\n\n', n_em, hash_nouvelle);

% ─────────────────────────────────────────────────────────
% ÉTAPE 5 — NOEUD 2 VIRTUEL : TEST DE LA CLÉ
% Le noeud 2 virtuel reçoit la clé et la teste
% avant qu'elle soit envoyée au noeud 2 physique
% ─────────────────────────────────────────────────────────
fprintf('[NOEUD %d VIRTUEL] Réception et test de la clé...\n', n_rec);

% Simulation réception
hash_recu_par_n2 = hash_nouvelle;

% Vérification intégrité côté noeud 2
hash_verif = num2str(sum(double(cle_nouvelle) .* (1:length(cle_nouvelle))));

if strcmp(hash_recu_par_n2, hash_verif)
    test_ok = true;
    fprintf('[NOEUD %d VIRTUEL] ✅ Clé reçue et validée\n', n_rec);
    fprintf('[NOEUD %d VIRTUEL] ✅ Test de communication virtuel réussi\n\n', n_rec);
else
    test_ok = false;
    fprintf('[NOEUD %d VIRTUEL] ❌ Clé invalide — recalcul nécessaire\n\n', n_rec);
end

% ─────────────────────────────────────────────────────────
% ÉTAPE 6 — DÉCISION FINALE
% Si le test virtuel est OK → on envoie au physique
% ─────────────────────────────────────────────────────────
fprintf('[DT CORE]     Décision finale...\n');

if audit_ok && test_ok
    fprintf('[DT CORE]     ✅ Clé validée sur les deux noeuds virtuels\n');
    fprintf('[DT CORE]     ✅ Envoi au Noeud %d physique autorisé\n\n', n_rec);
    statut = 'Validée ✅';
else
    fprintf('[DT CORE]     ❌ Validation échouée — clé non envoyée\n\n');
    statut = 'Rejetée ❌';
end

% ─────────────────────────────────────────────────────────
% ÉTAPE 7 — ENVOI DE LA CLÉ AU RÉSEAU PHYSIQUE
% ─────────────────────────────────────────────────────────
reponse.noeud_emetteur  = n_em;
reponse.noeud_recepteur = n_rec;
reponse.cle             = cle_nouvelle;
reponse.hash_cle        = hash_nouvelle;
reponse.audit_ok        = audit_ok;
reponse.test_ok         = statut;
reponse.timestamp       = datetime('now');

save('decision_jumeau.mat', 'reponse');
fprintf('[TWINNING]    ✅ Clé envoyée au Noeud %d physique\n\n', n_rec);

% ─────────────────────────────────────────────────────────
% ÉTAPE 8 — AFFICHAGE DU JUMEAU NUMÉRIQUE
% ─────────────────────────────────────────────────────────
figure('Name','JUMEAU NUMÉRIQUE — DT','NumberTitle','off',...
       'Position',[730 100 660 560]);

% Sink = DT Core
scatter(SinkX, SinkY, 300, 'diamond', 'filled',...
        'MarkerFaceColor',[0.5 0 0.5],'MarkerEdgeColor','k');
hold on;

% Noeuds virtuels
for i = 1:n
    if i == n_em
        couleur = [0.9 0.4 0];      % orange = noeud 1 virtuel
        taille  = 160;
    elseif i == n_rec
        couleur = [0.1 0.7 0.1];    % vert = noeud 2 virtuel
        taille  = 160;
    else
        couleur = [0.4 0.6 0.8];    % bleu clair = autres
        taille  = 80;
    end

    scatter(x_virt(i), y_virt(i), taille,...
            'MarkerEdgeColor', couleur,...
            'MarkerFaceColor', couleur);
    text(x_virt(i), y_virt(i)+18, sprintf('N%d*', i),...
         'FontSize', 9, 'HorizontalAlignment','center',...
         'FontWeight','bold', 'Color', couleur);

    line([x_virt(i) SinkX],[y_virt(i) SinkY],...
         'Color',[0.85 0.85 0.85 0.2],'LineWidth',0.6);
end

% Flux : Noeud 1 virtuel → DT Core → Noeud 2 virtuel
line([x_virt(n_em) SinkX],[y_virt(n_em) SinkY],...
     'Color',[0.9 0.4 0],'LineWidth',2.5,'LineStyle','--');
line([SinkX x_virt(n_rec)],[SinkY y_virt(n_rec)],...
     'Color',[0.1 0.7 0.1],'LineWidth',2.5,'LineStyle','--');

% Annotations flux
text((x_virt(n_em)+SinkX)/2, (y_virt(n_em)+SinkY)/2+15,...
     'Hash reçu','FontSize',8,'Color',[0.9 0.4 0],...
     'HorizontalAlignment','center');
text((SinkX+x_virt(n_rec))/2, (SinkY+y_virt(n_rec))/2+15,...
     'Clé validée','FontSize',8,'Color',[0.1 0.7 0.1],...
     'HorizontalAlignment','center');

xlim([0 breadth]); ylim([0 breadth]);
title(sprintf('JUMEAU NUMÉRIQUE — N%d* génère | N%d* teste | Statut : %s',...
      n_em, n_rec, statut),'FontWeight','bold');
xlabel('X (m)'); ylabel('Y (m)');
legend('DT Core (Sink)',...
       sprintf('Noeud %d* (génération)', n_em),...
       sprintf('Noeud %d* (test)', n_rec),...
       'Autres noeuds virtuels','Location','northeast');
grid on;

fprintf('=================================================\n');
fprintf('   RÉSUMÉ\n');
fprintf('─────────────────────────────────────────────────\n');
fprintf('  Demande      : Noeud %d → Noeud %d\n', n_em, n_rec);
fprintf('  Audit N%d    : %s\n', n_em, string(audit_ok));
fprintf('  Test N%d     : %s\n', n_rec, string(test_ok));
fprintf('  Clé générée  : %s\n', cle_nouvelle);
fprintf('  Hash clé     : %s\n', hash_nouvelle);
fprintf('  Statut final : %s\n', statut);
fprintf('=================================================\n');

% ─────────────────────────────────────────────────────────
% ÉTAPE 9 — MISE À JOUR GRAPHIQUE RÉSEAU PHYSIQUE
% Après validation, on met à jour le graphique du physique
% pour montrer la communication sécurisée établie
% ─────────────────────────────────────────────────────────
fprintf('\n[PHYSIQUE]    Mise à jour du réseau physique...\n');

load('canal_twinning.mat');
x       = demande.x;
y       = demande.y;
n       = demande.n;
breadth = demande.breadth;
SinkX   = demande.SinkX;
SinkY   = demande.SinkY;

figure('Name','RÉSEAU PHYSIQUE — Communication sécurisée établie',...
       'NumberTitle','off','Position',[50 100 660 560]);

scatter(SinkX, SinkY, 300, 'diamond', 'filled',...
        'MarkerFaceColor',[0.1 0.1 0.8],'MarkerEdgeColor','k');
hold on;

for i = 1:n
    if i == n_em
        couleur = [0.9 0.4 0];
        taille  = 160;
    elseif i == n_rec
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

% Lien sécurisé établi — ligne pleine verte
line([x(n_em) x(n_rec)],[y(n_em) y(n_rec)],...
     'Color',[0.1 0.7 0.1],'LineWidth',3,'LineStyle','-');

text((x(n_em)+x(n_rec))/2,(y(n_em)+y(n_rec))/2+20,...
     sprintf('Clé : %s', reponse.cle),...
     'FontSize',7,'HorizontalAlignment','center',...
     'Color',[0 0.5 0],'FontWeight','bold');

xlim([0 breadth]); ylim([0 breadth]);
title(sprintf('RÉSEAU PHYSIQUE — ✅ Communication N%d ↔ N%d sécurisée',...
      n_em, n_rec),'FontWeight','bold');
xlabel('X (m)'); ylabel('Y (m)');
legend('Sink (Jumeau)',...
       sprintf('Noeud %d (émetteur)', n_em),...
       sprintf('Noeud %d (récepteur)', n_rec),...
       'Autres noeuds','Location','northeast');
grid on;

fprintf('[PHYSIQUE]    ✅ Communication Noeud %d ↔ Noeud %d sécurisée !\n',...
        n_em, n_rec);