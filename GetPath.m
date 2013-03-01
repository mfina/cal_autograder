function [pathName] = GetPath(fullFileName)
% Return the path (directory) of any full file path, fullFileName

% % In post-R2011a(inclusive), matlab use '~' to ignore output
% [pathName,~,~,~] = fileparts(fullFileName);
[pathName,name,ext,versn] = fileparts(fullFileName);

end