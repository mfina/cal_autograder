function [shortName] = GetShortName(fullFileName)
% Return the path (directory) of any file

% % In post-R2011a(inclusive), matlab use '~' to ignore output
% [pathName,~,~,~] = fileparts(fullFileName);
[pathName,name,ext,versn] = fileparts(fullFileName);

shortName = [name, ext];

end