
function out = pupl_PFE_lm(EYE)
% Correct pupil foreshortening error by multivariate linear regression
% 
% Citation:
% Brisson, J., Mainville, M., Mailloux, D., Beaulieu, C., Serres, J., &
% Sirois, S. (2013). Pupil diameter measurement errors as a function of
% gaze direction in corneal reflection eyetrackers. Behavior research
% methods, 45(4), 1322-1331.
if nargin == 0
    out = [];
    fprintf('Correcting pupil foreshortening error by multivariate linear regression\n');
else
    out = sub_PFE_lm(EYE);
end

end

function EYE = sub_PFE_lm(EYE)

gx = EYE.gaze.x;
gy = EYE.gaze.y;

pupil_fields = reshape(fieldnames(EYE.pupil), 1, []);

for field = pupil_fields
    [B, Rsq, df, Yhat] = nanlm(EYE.pupil.(field{:}), gx, gy);
    fprintf('Modelling %s pupil %s as:\n', field{:}, pupl_getunits(EYE));
    fprintf('Y = %f + %f Gx + %f Gy\n', B);
    fprintf('R squared: %f on %d degrees of freedom\n', Rsq, df);
    % Put NaNs back and correct
    Pc = EYE.pupil.(field{:});
    Pc = Pc(:) - Yhat + nanmean_bc(Pc);
    EYE.pupil.(field{:}) = reshape(Pc, size(EYE.pupil.(field{:})));
end

end