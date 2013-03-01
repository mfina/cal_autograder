function [fFullFunction] = ConvertToMFile(fFullScript, outVarNames)
% Provides AutoGrader support for script files
%   through converting script file to function
%   using read / write operations
%
% Date: 3.29.12

% Remedy long path name
indSlash = find(fFullScript=='\',1,'last');
fPath = fFullScript(1:indSlash-1);
fScript = fFullScript(indSlash+1:end-2);                    %strip .m

% CREATE TEMP FILE
fFunction = [fScript, '1'];                                 %strip '.m', append '1.m'
fidWrt = fopen([fPath, '\', fFunction, '.m'], 'wt');                    %open fid for writing

% CREATE, WRITE HEADER
fcnHeader = ['function [output] = ', fFunction, '()'];
fprintf(fidWrt, [fcnHeader,'\n\n']);

% INSERT SCRIPT TO TEMP
fidRd = fopen([fPath, '\', fScript, '.m'],'r');
fprintf(fidWrt, '%%COPYING script file\n');
while ~feof(fidRd)
  lineTemp = fgetl(fidRd);
  fprintf(fidWrt, [lineTemp,'\n']);
  clear lineTemp
end
fclose(fidRd);

% CONSTRUCT OUTPUT
fprintf(fidWrt, '\n\n%%CONSTRUCTING output');
output_call = {};                           % for usage with evalc ...
evalOut = '\noutput = {';
for ind = 1:length(outVarNames)
  if strcmp(outVarNames{ind}, 'gcf')
    output_call = [output_call, {'\nset(gcf, ''visible'', ''off'');\nhFig = get(gcf);'}];
    evalOut = [evalOut, 'hFig'];
  elseif strcmp(outVarNames{ind}, 'gca')
    output_call = [output_call, {'\nset(gcf, ''visible'', ''off'');\nhAx = get(gca);'}];
    evalOut = [evalOut, 'hAx'];
  else                                              % may produce error, tested later
    evalOut = [evalOut, outVarNames{ind}];
  end

  if ind < length(outVarNames)
    evalOut = [evalOut, ', '];
  else                  %can block out this line for issues with 
    evalOut = [evalOut, '}'];   % nOutputs <= 0 gives error, intentional??? 
  end
end
evalOut = [evalOut, ';'];  

% FOOTER including setting up output variables
if ~isempty(output_call), fprintf(fidWrt, output_call{:}); end
fprintf(fidWrt, evalOut);
fprintf(fidWrt, '\n\nend');
fclose(fidWrt);

% RETURN FULL FILENAME PATH
fFullFunction = [fFullScript(1:end-2), '1.m'];

end