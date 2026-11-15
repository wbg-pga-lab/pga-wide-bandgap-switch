%% deliverable2_monte_carlo.m
% Monte Carlo resistor-tolerance simulation. Purpose: isolate how much of
% the measured Vout variance across the 9 states is explained by resistor
% tolerance alone. Only the feedback and input resistors are varied;
% the input voltage is held at its measured value, so the spread in the
% output comes from resistor tolerance and nothing else.
%
% Pure MATLAB, no Simulink required.
%
% Resistor tolerance is set to 1 percent (metal film parts). If you use a
% different tolerance grade (for example 5 percent carbon film), change
% RESISTOR_TOL_PCT; this one number drives the whole simulation.
%
% Distribution assumption: resistors are modeled as uniformly distributed
% within +/- tolerance of nominal, not normally distributed. This matches
% how manufacturers actually bin resistors (parts within tolerance of a
% batch are sold as that tolerance grade, not clustered at the nominal
% value) and is the standard conservative choice for this kind of sim.

clear; clc;

RESISTOR_TOL_PCT = 1.0;   % percent
N = 20000;                % Monte Carlo iterations per state
Vin_val = 0.485;          % V, measured at the amplifier input

% Nominal branch values (Rin) and fixed Rf
Rf_nom = 100e3;    % nominal, not measured - tolerance modeling starts
                    % from nominal since that's what the manufacturer's
                    % tolerance spec is relative to
states = struct( ...
    'name', {'1 Si Low','2 GaN Low','3 SiC Low', ...
              '4 Si Mid','5 GaN Mid','6 SiC Mid', ...
              '7 Si High','8 GaN High','9 SiC High'}, ...
    'Rin_nom', {100e3, 100e3, 100e3, ...            % Low: single 100k
                24.2e3, 24.2e3, 24.2e3, ...          % Mid: 22k+2.2k
                10.68e3, 10.68e3, 10.68e3} ...       % High: 10k+680
);

fprintf('Resistor tolerance assumed: +/- %.1f%%\n', RESISTOR_TOL_PCT);
fprintf('%-10s %10s %10s %10s\n','State','Mean Vout','Std Vout','Range(95%%)');

results = struct('name',{},'mean',{},'std',{},'samples',{});

for i = 1:9
    tol = RESISTOR_TOL_PCT/100;
    Rf_samples  = Rf_nom  .* (1 + (2*rand(N,1)-1)*tol);
    Rin_samples = states(i).Rin_nom .* (1 + (2*rand(N,1)-1)*tol);

    Vout_samples = Vin_val .* (1 + Rf_samples ./ Rin_samples);

    results(i).name = states(i).name;
    results(i).mean = mean(Vout_samples);
    results(i).std  = std(Vout_samples);
    results(i).samples = Vout_samples;

    ci = prctile(Vout_samples, [2.5 97.5]);
    fprintf('%-10s %10.4f %10.4f  [%.4f, %.4f]\n', ...
        states(i).name, results(i).mean, results(i).std, ci(1), ci(2));
end

% --- Plot: 9-panel histogram grid ---
figure('Position',[100 50 1000 800]);
for i = 1:9
    subplot(3,3,i);
    histogram(results(i).samples, 60, 'Normalization','probability');
    title(results(i).name, 'Interpreter','none');
    xlabel('V_{out} (V)'); ylabel('P');
    xline(results(i).mean, 'r-', 'LineWidth',1.5);
end
sgtitle(sprintf('Monte Carlo Vout Distribution, Resistor Tolerance = %.1f%%, N=%d', ...
    RESISTOR_TOL_PCT, N));

% --- Summary comparison across states ---
figure('Position',[150 100 850 500]);
means = [results.mean];
stds  = [results.std];
errorbar(1:9, means, stds, 'o', 'LineWidth',1.5, 'MarkerSize',6, 'MarkerFaceColor','b');
xticks(1:9); xticklabels({results.name}); xtickangle(45);
ylabel('V_{out} (V)');
title('Monte Carlo Mean \pm 1\sigma per State (resistor tolerance only)');
grid on;

fprintf('\nTo compare against real measurement spread once you have multi-trial\n');
fprintf('data: overlay your Vout Trials tab''s per-state Std dev column against\n');
fprintf('the "Std Vout" column above. If measured std is much larger than this,\n');
fprintf('resistor tolerance is NOT the dominant noise source - something else is\n');
fprintf('(Vin instability, ADC/measurement noise, thermal drift, etc).\n');