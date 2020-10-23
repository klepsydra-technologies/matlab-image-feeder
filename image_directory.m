function image_directory(block)
%MSFUNTMPL_BASIC A Template for a Level-2 MATLAB S-Function
%   The MATLAB S-function is written as a MATLAB function with the
%   same name as the S-function. Replace 'image_directory' with the
%   name of your S-function.

%   Copyright 2003-2018 The MathWorks, Inc.

%%
%% The setup method is used to set up the basic attributes of the
%% S-function such as ports, parameters, etc. Do not add any other
%% calls to the main body of the function.
%%
setup(block);

%endfunction

%% Function: setup ===================================================
%% Abstract:
%%   Set up the basic characteristics of the S-function block such as:
%%   - Input ports
%%   - Output ports
%%   - Dialog parameters
%%   - Options
%%
%%   Required         : Yes
%%   C MEX counterpart: mdlInitializeSizes
%%
function setup(block)

% Register number of ports
block.NumInputPorts  = 1;
block.NumOutputPorts = 3;
block.AllowSignalsWithMoreThan2D = 1;

% Setup port properties to be inherited or dynamic
%block.SetPreCompInpPortInfoToDynamic;
%block.SetPreCompOutPortInfoToDynamic;

% Override input port properties
block.InputPort(1).Dimensions        = 1;
block.InputPort(1).DatatypeID  = 0;  % double
block.InputPort(1).Complexity  = 'Real';
block.InputPort(1).DirectFeedthrough = true;

% Override output port properties
block.OutputPort(1).Dimensions     = [1024 1024 3];
block.OutputPort(1).DimensionsMode = 'Variable';
block.OutputPort(1).Complexity  = 'Real';
block.OutputPort(1).SamplingMode = 'sample';
block.OutputPort(1).DatatypeID  = 3; % uint8

block.OutputPort(2).Dimensions     = [1 11];
block.OutputPort(2).DimensionsMode = 'Variable';
block.OutputPort(2).Complexity  = 'Real';
block.OutputPort(2).SamplingMode = 'sample';
block.OutputPort(2).DatatypeID  = 0; % uint8

block.OutputPort(3).Dimensions     = [1];
block.OutputPort(3).DimensionsMode = 'Variable';
block.OutputPort(3).Complexity  = 'Real';
block.OutputPort(3).SamplingMode = 'sample';
block.OutputPort(3).DatatypeID  = 0; % uint8

% Register parameters
block.NumDialogPrms     = 1;

% Register sample times
%  [0 offset]            : Continuous sample time
%  [positive_num offset] : Discrete sample time
%
%  [-1, 0]               : Inherited sample time
%  [-2, 0]               : Variable sample time
block.SampleTimes = [-1 0];

% Specify the block simStateCompliance. The allowed values are:
%    'UnknownSimState', < The default setting; warn and assume DefaultSimState
%    'DefaultSimState', < Same sim state as a built-in block
%    'HasNoSimState',   < No sim state
%    'CustomSimState',  < Has GetSimState and SetSimState methods
%    'DisallowSimState' < Error out when saving or restoring the model sim state
block.SimStateCompliance = 'DefaultSimState';
block.RegBlockMethod('SetInputPortSamplingMode', @SetInpPortFrameData);

%
% SetInputPortSamplingMode:
%   Functionality    : Check and set input and output port 
%                      attributes and specify whether the port is operating 
%                      in sample-based or frame-based mode
%   C MEX counterpart: mdlSetInputPortFrameData.
%   (The DSP System Toolbox is required to set a port as frame-based)
%
function SetInpPortFrameData(block, idx, fd)
block.InputPort(idx).SamplingMode = fd;
block.OutputPort(1).SamplingMode  = fd;
block.OutputPort(2).SamplingMode  = fd;
block.OutputPort(3).SamplingMode  = fd;

%% -----------------------------------------------------------------
%% The MATLAB S-function uses an internal registry for all
%% block methods. You should register all relevant methods
%% (optional and required) as illustrated below. You may choose
%% any suitable name for the methods and implement these methods
%% as local functions within the same file. See comments
%% provided for each function for more information.
%% -----------------------------------------------------------------

block.RegBlockMethod('PostPropagationSetup',    @DoPostPropSetup);
block.RegBlockMethod('InitializeConditions', @InitializeConditions);
block.RegBlockMethod('Start', @Start);
block.RegBlockMethod('Outputs', @Outputs);     % Required
block.RegBlockMethod('Update', @Update);
block.RegBlockMethod('Derivatives', @Derivatives);
block.RegBlockMethod('Terminate', @Terminate); % Required

%end setup

%%
%% PostPropagationSetup:
%%   Functionality    : Setup work areas and state variables. Can
%%                      also register run-time methods here
%%   Required         : No
%%   C MEX counterpart: mdlSetWorkWidths
%%
function DoPostPropSetup(block)
block.NumDworks = 1;

global image_list
global data_folder
global image_list_size
global data_labels
global image_data

data_folder = block.DialogPrm(1).Data;
image_list = dir(data_folder + '/images')
temp_size = size(image_list);
image_list_size = temp_size(1);
data_labels = readtable(data_folder + '/labels.csv');
image_data = readtable(data_folder + '/data.csv');

block.Dwork(1).Name            = 'x1';
block.Dwork(1).Dimensions      = 1;
block.Dwork(1).DatatypeID      = 0;      % double
block.Dwork(1).Complexity      = 'Real'; % real
block.Dwork(1).UsedAsDiscState = true;


%%
%% InitializeConditions:
%%   Functionality    : Called at the start of simulation and if it is
%%                      present in an enabled subsystem configured to reset
%%                      states, it will be called when the enabled subsystem
%%                      restarts execution to reset the states.
%%   Required         : No
%%   C MEX counterpart: mdlInitializeConditions
%%
function InitializeConditions(block)

%end InitializeConditions


%%
%% Start:
%%   Functionality    : Called once at start of model execution. If you
%%                      have states that should be initialized once, this
%%                      is the place to do it.
%%   Required         : No
%%   C MEX counterpart: mdlStart
%%
function Start(block)

block.Dwork(1).Data = 3;

%end Start

%%
%% Outputs:
%%   Functionality    : Called to generate block outputs in
%%                      simulation step
%%   Required         : Yes
%%   C MEX counterpart: mdlOutputs
%%
function Outputs(block)

global image_list
global data_folder
global data_labels
global image_data

f = image_list(block.Dwork(1).Data);
img = imread(fullfile(data_folder + '/images/', f.name));
block.OutputPort(1).CurrentDimensions = size(img);
block.OutputPort(1).Data = permute(img, [2, 1, 3]);

image_name = extractBetween(f.name, 1, length(f.name) - 4);
[~,index] = ismember(image_name, image_data{:,1});
image_data_array = table2array(image_data(index, 2:11));
block.OutputPort(2).CurrentDimensions = size(image_data_array);
block.OutputPort(2).Data = image_data_array;

[~,index] = ismember(image_name, data_labels{:,1});
datal_label_array = table2array(data_labels(index, 2));
block.OutputPort(3).CurrentDimensions = [1];
block.OutputPort(3).Data = datal_label_array;

%end Outputs

%%
%% Update:
%%   Functionality    : Called to update discrete states
%%                      during simulation step
%%   Required         : No
%%   C MEX counterpart: mdlUpdate
%%
function Update(block)

global image_list_size

block.Dwork(1).Data = block.Dwork(1).Data + 1;
if block.Dwork(1).Data > image_list_size
    block.Dwork(1).Data = 3
end

%end Update

%%
%% Derivatives:
%%   Functionality    : Called to update derivatives of
%%                      continuous states during simulation step
%%   Required         : No
%%   C MEX counterpart: mdlDerivatives
%%
function Derivatives(block)

%end Derivatives

%%
%% Terminate:
%%   Functionality    : Called at the end of simulation for cleanup
%%   Required         : Yes
%%   C MEX counterpart: mdlTerminate
%%
function Terminate(block)

%end Terminate

