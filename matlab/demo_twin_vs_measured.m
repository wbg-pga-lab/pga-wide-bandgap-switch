%% Physical circuit vs. Simulink model, direct comparison
% PGA switch technology comparison (Quint R. Cabral, Shubaan Meyyappan)
%
% A nine-state programmable gain amplifier was built on the bench, and
% a Simulink model of the same circuit uses datasheet values for each
% switch (Si, GaN, SiC). This script runs the model for all nine states
% and lines its output up against what the board measured, state by state.
%
% Requires PGA_twin.slx open or in the same folder (the Simulink model
% built directly from the schematic).

clear; clc; close all;
modelName = 'PGA_twin';
if ~bdIsLoaded(modelName)
    open_system([modelName '.slx']);
end

% --- Fixed circuit-wide values, measured off the real board ---
Rf_val  = 98.35e3;   % ohms, measured
Vin_val = 0.485;     % V, measured (Node Voltages tab)

% --- Per-state device parameters, straight from each part's real datasheet ---
% Si:  IRLU024NPBF   -> on-state resistance 0.080 ohm @ 5V drive,  Vth 1.5V
% GaN: TP65H150G4PS  -> on-state resistance 0.150 ohm @ 10V drive, Vth 4.0V
% SiC: MSC750SMA170B -> on-state resistance 0.797 ohm @ ~19V drive, Vth 3.0V
states = struct( ...
    'name',   {'Si Low','GaN Low','SiC Low', ...
               'Si Mid','GaN Mid','SiC Mid', ...
               'Si High','GaN High','SiC High'}, ...
    'Rin',    {99210, 99140, 99240, ...
               23910, 23880, 23900, ...
               10585, 10662, 10661}, ...   % state 8 corrected 10782 -> 10662
    ...                                     % workbook Individual Resistors:
    ...                                     % 9.99k + 0.672k = 10.662k
    'Ron',    {0.080, 0.150, 0.797, ...
               0.080, 0.150, 0.797, ...
               0.080, 0.150, 0.797}, ...
    'Vth',    {1.5, 4.0, 3.0, ...
               1.5, 4.0, 3.0, ...
               1.5, 4.0, 3.0} ...
);

% Measured on the physical board (Vout Trials tab, mean of 5 trials/state)
measured_Vout = [0.985, 0.979, 0.984, 2.5032, 2.5, 2.503, 5.0222, 4.9352, 4.9852];

fprintf('Device parameters used in the Simulink model (from datasheets):\n');
fprintf('%-10s  %10s  %14s  %10s\n', 'State', 'Rin (ohm)', 'On-resist. (ohm)', 'Vth (V)');
for i = 1:9
    fprintf('%-10s  %10d  %14.3f  %10.1f\n', states(i).name, states(i).Rin, states(i).Ron, states(i).Vth);
end

% --- Run the model across all 9 states ---
sim_Vout = nan(1,9);

set_param([modelName '/Vin DC Voltage Source'], 'v0', num2str(Vin_val));
set_param([modelName '/Rf'], 'R', num2str(Rf_val));          % Rf, fixed
set_param([modelName '/Gate_Drive'], 'Value', '5');           % gate drive, fixed high

for i = 1:9
    set_param([modelName '/Rin'], 'R', num2str(states(i).Rin));
    set_param([modelName '/Switch_Under_Test'], ...
        'Rds', num2str(states(i).Ron), ...
        'Vth', num2str(states(i).Vth));

    simOut = sim(modelName);
    sim_Vout(i) = simOut.Vout_sim.Data(end);
end

% --- Compare ---
pct_diff = 100 * (sim_Vout - measured_Vout) ./ measured_Vout;

fprintf('\nSimulink model vs. physical board:\n');
fprintf('%-10s  %12s  %12s  %10s\n', 'State', 'Model (V)', 'Measured (V)', 'Diff (%)');
for i = 1:9
    fprintf('%-10s  %12.4f  %12.4f  %9.2f%%\n', ...
        states(i).name, sim_Vout(i), measured_Vout(i), pct_diff(i));
end
fprintf('\nMean absolute difference: %.2f%%\n', mean(abs(pct_diff)));

% --- Theoretical Vout, from the same measured Rf/Rin used above ---
theory_Vout = Vin_val * (1 + Rf_val ./ [states.Rin]);

% --- Export theory/sim/measured comparison for the paper ---
T = table({states.name}', theory_Vout', sim_Vout', measured_Vout', ...
    'VariableNames', {'State','Vout_theory','Vout_sim','Vout_measured'});
writetable(T, 'deliverable4_comparison.csv');

% --- One plot: model vs measured, grouped by state ---
figure('Color','w','Position',[100 100 900 450]);
names = {states.name};
bar_data = [sim_Vout; measured_Vout]';
b = bar(bar_data, 'grouped');
b(1).FaceColor = [0.2 0.4 0.8];   % Simulink model
b(2).FaceColor = [0.85 0.55 0.1]; % Measured (physical board)
set(gca, 'XTickLabel', names, 'XTickLabelRotation', 40);
ylabel('Vout (V)');
legend({'Simulink model','Physical board (measured)'}, 'Location','northwest');
title('Simulink Model vs. Physical Circuit, All 9 States');
grid on;
