function [A] = MakeRowVector(A)
% Transposes Nx1 double arrays to get nicer output in Matlab

if size(A,1) > 1 
    A = transpose(A);
end

end