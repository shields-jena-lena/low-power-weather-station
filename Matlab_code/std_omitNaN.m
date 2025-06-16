%% Function that omits missing values from the standard deviation function
% Author: Jena Shields
% Last updated: 6/16/25
% Matlab version: MATLAB R2023b
% Used in script: field_analysis.m


function std_noNaN = std_omitNaN(A)
    std_noNaN = std(A,"omitmissing");
end