%% make_paper_figures.m
% Generates Figures 11 and 12 for the PGA wide-bandgap switch paper.
%
%   Figure 11 - Mean absolute error under four modelling assumptions
%   Figure 12 - Residual between measured and predicted output, by gain tier
%
% Both are drawn in greyscale so they remain readable when the proceedings
% are printed in monochrome. Series are separated by fill value rather than
% by colour, since hue is lost in a black and white print and green and
% orange desaturate to nearly the same grey.
%
% Outputs 300 dpi PNGs sized for a single IEEE column (3.4 in wide).
%
% Run this after demo_twin_vs_measured.m, which produces the simulated
% values this script cross-checks against.

clear; clc; close all;

%% ---------------- Source data ----------------
% Fixed circuit values, measured off the board (Individual Resistors tab)
Rf_meas = 98.35e3;      % ohm, measured feedback resistor
Rf_nom  = 100e3;        % ohm, nominal feedback resistor

% Input voltage, two candidates:
Vin_calc = 0.468;       % V, computed from the divider using nominal parts
Vin_meas = 0.485;       % V, measured at pin 3, all nine states (Node Voltages tab)

labels = {'Si Low','GaN Low','SiC Low', ...
          'Si Mid','GaN Mid','SiC Mid', ...
          'Si High','GaN High','SiC High'};

% Measured branch input resistances (Individual Resistors tab, Assembled Rin)
Rin_meas = [99210, 99140, 99240, ...
            23910, 23880, 23900, ...
            10585, 10662, 10661];      % state 8 is 9.99k + 0.672k

% Nominal branch input resistances
Rin_nom  = [100e3, 100e3, 100e3, ...
            24.2e3, 24.2e3, 24.2e3, ...
            10.68e3, 10.68e3, 10.68e3];

% Mean measured output, five trials per state (Vout Trials tab)
Vout_meas = [0.985, 0.979, 0.984, ...
             2.5032, 2.5000, 2.5030, ...
             5.0222, 4.9352, 4.9852];

% Largest per-state standard deviation across the five trials, in volts.
% This sets the noise floor drawn on Figure 12.
noise_floor_V = 0.0004;

%% ---------------- Error budget, four assumption cases ----------------
predict = @(vin, rin, rf) vin .* (1 + rf ./ rin);
meanAbsErr = @(pred) mean(abs(Vout_meas - pred) ./ Vout_meas) * 100;
worstErr   = @(pred) max(abs(Vout_meas - pred) ./ Vout_meas) * 100;

cases = { ...
  'Nominal R\newlineCalculated V_{in}',  predict(Vin_calc, Rin_nom,  Rf_nom); ...
  'Measured R\newlineCalculated V_{in}', predict(Vin_calc, Rin_meas, Rf_meas); ...
  'Nominal R\newlineMeasured V_{in}',    predict(Vin_meas, Rin_nom,  Rf_nom); ...
  'Measured R\newlineMeasured V_{in}',   predict(Vin_meas, Rin_meas, Rf_meas)};

mae = cellfun(@(pred) meanAbsErr(pred), cases(:,2));
wst = cellfun(@(pred) worstErr(pred),   cases(:,2));

fprintf('Mean absolute error under four modelling assumptions\n');
fprintf('%-34s %10s %10s\n', 'Assumption', 'Mean', 'Worst');
for k = 1:4
    fprintf('%-34s %9.2f%% %9.2f%%\n', ...
        strrep(cases{k,1}, '\newline', ' / '), mae(k), wst(k));
end
fprintf('\n');

%% ---------------- Residuals against each branch own prediction ----------
Vout_pred = predict(Vin_meas, Rin_meas, Rf_meas);
resid_pct = (Vout_meas - Vout_pred) ./ Vout_pred * 100;

tiers = {'Low','Mid','High'};
techs = {'Si','SiC','GaN'};
R = zeros(3,3);                       % rows are tiers, columns are technologies
for t = 1:3
    for d = 1:3
        idx = find(strcmp(labels, sprintf('%s %s', techs{d}, tiers{t})));
        R(t,d) = resid_pct(idx);
    end
end

fprintf('Residual, measured minus predicted, as a percentage of prediction\n');
fprintf('%-6s %9s %9s %9s\n', 'Tier', techs{:});
for t = 1:3
    fprintf('%-6s %+8.2f%% %+8.2f%% %+8.2f%%\n', tiers{t}, R(t,:));
end
fprintf('\n');

%% ================= FIGURE 11, error budget =================
f11 = figure('Color','w','Units','inches','Position',[1 1 3.4 2.4]);
ax = axes(f11); hold(ax,'on');

% Two assumption groups distinguished by fill value, not by colour:
% white bars assume the input voltage, dark bars use the measured value.
faceVals = [1 1 1; 1 1 1; 0.35 0.35 0.35; 0.35 0.35 0.35];
for k = 1:4
    bar(ax, k, mae(k), 0.62, 'FaceColor', faceVals(k,:), ...
        'EdgeColor','k', 'LineWidth', 0.9);
    text(ax, k, mae(k)+0.12, sprintf('%.2f%%', mae(k)), ...
        'HorizontalAlignment','center', 'FontSize', 8, ...
        'FontWeight','bold', 'FontName','Times New Roman');
end

% Annotate the improvement from measuring the input voltage
yA = max(mae) + 1.0;
plot(ax, [1 3], [yA yA], 'k-', 'LineWidth', 0.9);
plot(ax, [1 1], [yA-0.12 yA+0.12], 'k-', 'LineWidth', 0.9);
plot(ax, [3 3], [yA-0.12 yA+0.12], 'k-', 'LineWidth', 0.9);
text(ax, 2, yA+0.22, 'measuring one voltage: 4x better', ...
    'HorizontalAlignment','center', 'FontSize', 7.5, ...
    'FontWeight','bold', 'FontName','Times New Roman');

set(ax, 'XTick', 1:4, 'XTickLabel', cases(:,1), ...
    'FontName','Times New Roman', 'FontSize', 7, ...
    'XLim', [0.4 4.6], 'YLim', [0 yA+0.9], 'Box','on', 'LineWidth', 0.8);
ylabel(ax, 'Mean absolute error vs measurement (%)', ...
    'FontName','Times New Roman', 'FontSize', 8);
grid(ax,'on'); ax.GridLineStyle = ':'; ax.YGrid = 'on'; ax.XGrid = 'off';
ax.Layer = 'top';

exportgraphics(f11, 'fig11_error_budget.png', 'Resolution', 300);

%% ================= FIGURE 12, residuals by tier =================
f12 = figure('Color','w','Units','inches','Position',[1 1 3.4 2.3]);
ax2 = axes(f12); hold(ax2,'on');

b = bar(ax2, R, 'grouped', 'EdgeColor','k', 'LineWidth', 0.7);
% Three distinct fill values so the series survive a monochrome print
b(1).FaceColor = [0.25 0.25 0.25];   % Si,  solid dark
b(2).FaceColor = [0.62 0.62 0.62];   % SiC, mid grey
b(3).FaceColor = [1.00 1.00 1.00];   % GaN, white with black edge

% Noise floor band, expressed as a percentage of the smallest output
nf_pct = noise_floor_V / min(Vout_meas) * 100;
xl = [0.4 3.6];
patch(ax2, [xl fliplr(xl)], [-nf_pct -nf_pct nf_pct nf_pct], ...
    [0.75 0.75 0.75], 'EdgeColor','none', 'FaceAlpha', 0.65);
uistack(findobj(ax2,'Type','patch'), 'bottom');
text(ax2, 3.55, nf_pct+0.06, 'noise floor', 'HorizontalAlignment','right', ...
    'FontSize', 6.5, 'FontAngle','italic', 'FontName','Times New Roman');

% Value labels above and below each bar
for d = 1:3
    for t = 1:3
        xpos = b(d).XEndPoints(t);
        v = R(t,d);
        if v >= 0, off = 0.07; va = 'bottom'; else, off = -0.07; va = 'top'; end
        text(ax2, xpos, v+off, sprintf('%+.2f', v), ...
            'HorizontalAlignment','center', 'VerticalAlignment', va, ...
            'FontSize', 6, 'FontName','Times New Roman');
    end
end

yline(ax2, 0, 'k-', 'LineWidth', 0.8);
set(ax2, 'XTick', 1:3, 'XTickLabel', tiers, 'XLim', xl, ...
    'FontName','Times New Roman', 'FontSize', 8, 'Box','on', 'LineWidth', 0.8);
xlabel(ax2, 'Gain tier', 'FontName','Times New Roman', 'FontSize', 8);
ylabel(ax2, '(Measured - Predicted) / Predicted  (%)', ...
    'FontName','Times New Roman', 'FontSize', 8);
legend(ax2, b, techs, 'Location','northeast', 'Orientation','horizontal', ...
    'Box','off', 'FontSize', 7.5, 'FontName','Times New Roman');
ylim(ax2, [min(R(:))-0.5, max(R(:))+0.7]);
grid(ax2,'on'); ax2.GridLineStyle = ':'; ax2.YGrid = 'on'; ax2.XGrid = 'off';
ax2.Layer = 'top';

exportgraphics(f12, 'fig12_residuals.png', 'Resolution', 300);

fprintf('Written: fig11_error_budget.png and fig12_residuals.png (300 dpi)\n');
fprintf('Noise floor drawn at %.3f %% of the smallest measured output.\n', nf_pct);
