function [solutionFunctionHandle] = LoadSolutionFunction(homePath, solutionPath, solutionName)

cd(solutionPath);
solutionFunctionHandle = str2func(solutionName);
cd(homePath);

end