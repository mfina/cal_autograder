function [out] = IsScript(mFileName)
% In order to support script files, 
%  this file allows disambiguation of .m files
%
% out returns 0 if function and 1 if script
%
% 3.20.12

try
    nargin(mFileName);
    out = 0;
catch err
    if strcmp(err.identifier, 'MATLAB:nargin:isScript')
        out = 1;
	% Below from modifying problemFunctionHandle 'script' to full path name
    elseif strcmp(err.identifier, 'MATLAB:narginout:notValidMfile') && ...
            exist([mFileName, '.m'], 'file');
        out = 1;        
    else
        rethrow(err)
    end
end
