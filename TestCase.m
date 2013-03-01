classdef TestCase %< handle
    properties
        testCaseName = 'UNDEFINED';
        testCaseInput = {};
        testCaseTolerance = 0;
        testCasePoints = [];
        testCaseFlagOutputConfig = false;
        testCaseOutputConfig = {};        
        testCaseFlagRunInput = false;           %option to evaluate testCaseInput
        testCaseMessage = '';
    end

    methods
        % % Suggested UPDATE BELOW:
        % % Consider rewriting as varargin - options
        % function obj = TestCase(testCaseName, testCaseInput, testCaseTolerance, ...
        %                   testCasePoints, testCaseMessage, varargin)
        %   if nargin > 5           % accept varargin options
        %     if ~mod(length(varargin),2)   %even number correct
        %       pairs = reshape(varargin(:), [], 2);
        %       options = pairs(:,1);
        %       values = pairs(:,2);
        %       for ind = 1:length(options)
        %         switch options{ind}
        %         case 'formatOutput'
        %           testCase.testCaseFlagOutputConfig = true;
        %           testCase.testCaseOutputConfig = values{ind,2};
        %         case 'runInput'
        %           testCase.testCaseFlagRunInput = values{ind,2};
        %         case ...
        %         otherwise
        %         end
        %     else                          %odd number, error
        %       error('Must be even number of inputs');
        %     end
        
        function obj = TestCase(testCaseName, testCaseInput, testCaseTolerance, ...
                testCasePoints, testCaseMessage, testCaseOutputConfig, testCaseFlagRunInput)
            if nargin > 5 && ~isempty(testCaseOutputConfig)
                % define OutputConfig parameters
                %   OutputConfig is of form {outArg, fcnHan, index}
                %   E.g., {1, @(x) class(x), {'()',{1},'.',{'ID'}}
                obj.testCaseFlagOutputConfig = true;
                if ~mod( length(testCaseOutputConfig) , 3)
                    obj.testCaseOutputConfig = testCaseOutputConfig;    % assumes correct formatting
                    if 3*length(testCasePoints) ~= length(testCaseOutputConfig)
                        error(['\nWhen using output configure, the length of testCasePoints\n\t', ...
                            'Must match the number of testCaseOutputConfig sets']);
                    end
                else
                    error(['\nOutput configure not specified properly\n\t', ...
                        'each evaluation must have 3 cells']);
                end
            end
            if nargin > 6 && testCaseFlagRunInput
                % allows for getting input from evaluation - e.g. load 'fName.mat'
                obj.testCaseFlagRunInput = true;
            end
                
            obj.testCaseName = testCaseName;
            obj.testCaseInput = testCaseInput;          %For "script", this is outputVars
            obj.testCaseTolerance = testCaseTolerance;
            obj.testCasePoints = testCasePoints;
            obj.testCaseMessage = testCaseMessage;
        end
        
        function [totalPoints] = getTotalPoints(obj)
            totalPoints = sum(obj.testCasePoints);
        end
    end
end