%% deliverable1_bandgap_comparison.m
% Bandgap energy and critical electric field of Si, GaN and SiC.
%
% Why this matters: "wide bandgap" refers to the energy gap of the
% semiconductor material. A wider gap and a higher critical field let a
% device block more voltage in a thinner layer and run hotter, which is
% why GaN and SiC suit high-voltage, high-efficiency power conversion.
%
% Values are literature values, not measurements from this project,
% taken from Table I of: M. Buffolo et al., "Review and outlook on GaN
% and SiC power devices," IEEE Trans. Electron Devices, vol. 71, no. 3,
% pp. 1344-1355, 2024 (4H-SiC polytype for silicon carbide).

clear; clc; close all;

materials = {'Si', 'GaN', 'SiC (4H)'};

% Bandgap energy, eV, room temperature [Buffolo et al., Table I]
bandgap_eV = [1.12, 3.40, 3.23];

% Critical (breakdown) electric field, MV/cm [Buffolo et al., Table I]
critical_field_MVcm = [0.3, 3.3, 2.5];

fprintf('--- Material property comparison (literature values, not measured) ---\n');
for i = 1:3
    fprintf('%-10s  Bandgap = %.2f eV   Critical field = %.1f MV/cm\n', ...
        materials{i}, bandgap_eV(i), critical_field_MVcm(i));
end

%% ---------------- Combined bar chart ----------------
figure('Color','w','Position',[100 100 900 450]);

subplot(1,2,1);
b1 = bar(bandgap_eV, 'FaceColor','flat');
b1.CData = [0.2 0.4 0.8; 0.85 0.2 0.2; 0.2 0.7 0.3];
set(gca, 'XTickLabel', materials);
ylabel('Bandgap Energy (eV)');
title('Bandgap Energy');
grid on;
for i = 1:3
    text(i, bandgap_eV(i)+0.08, sprintf('%.2f', bandgap_eV(i)), ...
        'HorizontalAlignment','center', 'FontWeight','bold');
end

subplot(1,2,2);
b2 = bar(critical_field_MVcm, 'FaceColor','flat');
b2.CData = [0.2 0.4 0.8; 0.85 0.2 0.2; 0.2 0.7 0.3];
set(gca, 'XTickLabel', materials);
ylabel('Critical Field (MV/cm)');
title('Breakdown Field Strength');
grid on;
for i = 1:3
    text(i, critical_field_MVcm(i)+0.1, sprintf('%.1f', critical_field_MVcm(i)), ...
        'HorizontalAlignment','center', 'FontWeight','bold');
end

sgtitle('Why Wide Bandgap: Material Properties Behind Si / GaN / SiC');

fprintf('\nTakeaway: GaN and SiC have roughly three times the bandgap of\n');
fprintf('silicon and about eight to eleven times its critical field. These\n');
fprintf('properties pay off in high-voltage, fast-switching power conversion.\n');
fprintf('In the low-voltage amplifier of this project they are not exercised.\n');
