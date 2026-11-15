%% deliverable4.m
% Theory, Simulink model, and measured hardware Vout across all
% 9 states. Uses real measured Rf/Rin (Individual Resistors tab), the
% Vin=0.485V currently locked in, sim_Vout from run_nine_states.m, and
% measured_Vout from the Vout Trials tab (Mean Vout column).
%
% NOTE: Vin=0.485V is still an open issue (see project notes - it may
% predate the R3 divider change). If/when a remeasured Vin is confirmed,
% only Vin_val below needs to change; theory_Vout recalculates from it.

clear; clc;

Rf_val  = 98.35e3;
Vin_val = 0.485;

Rin = [99210, 99140, 99240, ...   % Low:  Si, GaN, SiC
       23910, 23880, 23900, ...   % Mid:  Si, GaN, SiC
       10585, 10662, 10661];      % High: Si, GaN, SiC
                                  % state 8 corrected 10782 -> 10662 to match
                                  % workbook Individual Resistors (9.99k+0.672k)

theory_gain = 1 + Rf_val ./ Rin;
theory_Vout = Vin_val .* theory_gain;

% From demo_twin_vs_measured.m output (run 19 Aug 2026, after the state 8
% Rin correction). State 8 was 4.9088 when Rin was wrongly set to 10782.
% State 7 (Si High) re-run with the op-amp output limit set to 5.125 V
% (25 mV below the measured 5.15 V logic-high level): 4.991 V.
sim_Vout = [0.9658, 0.9661, 0.9656, 2.4799, 2.4824, 2.4807, 4.991, 4.9586, 4.9588];

% From Vout Trials tab, Mean Vout column
measured_Vout = [0.985, 0.979, 0.984, 2.5032, 2.5, 2.503, 5.0222, 4.9352, 4.9852];

states = 1:9;
labels = {'Si-Low','GaN-Low','SiC-Low','Si-Mid','GaN-Mid','SiC-Mid','Si-High','GaN-High','SiC-High'};

figure('Position',[100 100 850 550]);
plot(states, theory_Vout, '-ko', 'LineWidth',1.5, 'DisplayName','Theory'); hold on;
plot(states, sim_Vout,    '-b^', 'LineWidth',1.5, 'DisplayName','Simulink model');
plot(states, measured_Vout,'-rs','LineWidth',1.5, 'DisplayName','Measured');
xlabel('State'); ylabel('V_{out} (V)');
title('Theory, Simulation, and Measurement, All 9 States');
legend('Location','best'); grid on;
xticks(1:9); xticklabels(labels); xtickangle(45);

fprintf('%-10s %10s %10s %10s %12s %12s\n','State','Theory','Sim','Measured','Sim-Theory%','Meas-Sim%');
for i = 1:9
    sim_err  = (sim_Vout(i)-theory_Vout(i))/theory_Vout(i)*100;
    meas_err = (measured_Vout(i)-sim_Vout(i))/sim_Vout(i)*100;
    fprintf('%-10s %10.4f %10.4f %10.4f %12.2f %12.2f\n', ...
        labels{i}, theory_Vout(i), sim_Vout(i), measured_Vout(i), sim_err, meas_err);
end