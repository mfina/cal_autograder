function [unhidden_file_list] = dir_nonhidden(path)
%dir_nonhidden Lists all nonhidden files/queries

% Do a normal dir
file_list = dir(path);
unhidden_file_list = [];

% Loop to identify hidden files
for I = 1:length(file_list)
    % In OS X and Ubuntu, hidden files start with a dot, who knows what
    % windows does.
    if ~file_list(I).isdir && ~strcmp(file_list(I).name(1), '.')
        unhidden_file_list = [unhidden_file_list file_list(I)];
    end
end
    
end