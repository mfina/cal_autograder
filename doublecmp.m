function [out] = doublecmp(A,B,absTol)
% compares doubles A and B together within tolerance, tol
% allow transposes

% MF - uses both absTol and relTol features; uses fall through structure

% absTol feature can be used with problems where known issues may arise 
%   from differences in choosing constants

% relTol doesn't require user setting of absTol for every run


% doublecmp - evaluation from absolute tolerance

% handle empty absTol
if nargin < 3 || isempty(absTol) 
    absTol = 1e-5; 
end

% original doublecmp code
if ndims(A)==ndims(B) && all(size(A)==size(B))
    
    %Handle Inf, NaN
    A(isnan(A)) = [1000];
    B(isnan(B)) = [1000];
    A(isinf(A)) = [2000];
    B(isinf(B)) = [2000];
    
    if all(abs(A-B)<=absTol)
        out = 1;
        return;
    else
        out = 0;
    end
elseif ndims(A)==ndims(B) && all(size(A)==size(B'))
    B = B';
    
    %Handle Inf, NaN
    A(isnan(A)) = [1000];
    B(isnan(B)) = [1000];
    A(isinf(A)) = [2000];
    B(isinf(B)) = [2000];
    
    if all(abs(A-B)<=absTol)
        out = 1;
        return;
    else
        out = 0;
    end
else                                    %incorrect dimension - no points (return)
    out = 0;
    return;
end
% if out=1 return, no need to evaluate relTol
% if out=0 change to get points from relTol below


% doublecmp - evaluation from relative tolerance
%   modify to norm2-based relative tolerance
relTol = 0.0001;
normA = max(norm(A),1e-6);              %choose GSI solution for comparison
norm_A_B = norm(A-B);                   %student difference from GSI, ok since B=B' above
% ---------------------------------------------

% adds points for passing relTol criterion
if ((norm_A_B / normA) <= relTol)
    out = 1;
end


end