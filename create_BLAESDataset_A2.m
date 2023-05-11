function BLAES = create_BLAESDataset_A2
% 
% create_BLAESDataset_A2 searches INMANLab Box for all BLAES Aim 2
% recordings and returns a structured dataset.
%
% ArgOut:
%    - BLAES: database of recording sessions from study (encoding) phase, with the following fields:
%        - data: raw peri-stim (1s stim +/- 2s) sampled at 2kHz (time x chan x epoch)
%        - conditions: stim (1) vs. no-stim (0)
%        - responses: sure no (67), maybe no (86), sure yes (78), maybe yes (66)
%        - imgCodes: image code corresponding to specific stimuli
%        - imgTypes: old vs. new
%        - imgContent: item vs. scene
%        - outcomes: hit, miss, correct rejection (CR), false alarm (FA)
%        - chanLabels: raw labels used during recording
%        - parameters: structure containing parameter information
%        - pID: patient ID
%        - imageset: experimental run / images shown
%        - version: date the dataset was generated
%
% Author:    Justin Campbell1166
% Contact:   justin.campbell@hsc.utah.edu 
% Version:   05-10-2023

%% Stim Code Mapping

% Stimuli
codeKeys.isi = 1801;
codeKeys.items = [101:348];
codeKeys.scenes = [349:472];
codeKeys.scrambled = [473:720];

% Conditions
codeKeys.noStim = 1501;
codeKeys.stim = 1502;

% Responses
codeKeys.sureNo = 67;
codeKeys.maybeNo = 86;
codeKeys.sureYes = 78;
codeKeys.maybeYes = 66;

%% Set Paths

INMANLab_path = 'C:\Users\Justin\Box\INMANLab\'; % path to Inman Lab folder in box
if (~exist('load_bcidat')) || (~exist('epoch_BCI_data'))
    addpath(genpath(fullfile(INMANLab_path, 'BCI2000\BCI2000Tools'))); % path to BCI2000Tools
    addpath(genpath('G:\My Drive\Code\BLAES\BCI_data_utils')); % path to Justin's BCI data functions
end

%% Find Patients

dataPrefixes = {'UIC', 'SLC', 'BJH'};
dirNames = {dir(INMANLab_path).name};
pIDs = dirNames(contains(dirNames, dataPrefixes));

rmPts = {'UIC202201', 'UIC202212', 'UIC202213',...
         'BJH027', 'BJH028', 'BJH029', 'BJH030', 'UIC202302'}; % Sz, Sz, asleep, A1-LD, A1-LD, A1-LD, A1-LD, A1-LD
pIDs = pIDs(find(~contains(pIDs, rmPts))); % remove specific patients

nPatients = length(pIDs);
fprintf('%d patients found... \n', nPatients);

%% Prepare Dataset

tic;
BLAES = struct([]);
fCounter = 0;

for i = 1:nPatients % loop through patient IDs
    dataPath = fullfile(INMANLab_path, pIDs{i}, 'Data', 'BLAES_study');
    dataDirs = dir(dataPath);
    dataDirs = dataDirs(~ismember({dataDirs.name},{'.','..'}));

    try
        for ii = 1:size(dataDirs,1) % loop through imagesets/sessions
            dataFiles = dir(fullfile(dataPath, dataDirs(ii).name, '*.dat'));
            dataFiles = dataFiles(~cellfun(@isempty, regexpi({dataFiles.name}, '\d\d.dat', 'end'))); % isolate RAW .dat files
            signals = cell(length(dataFiles),1);
            states = cell(length(dataFiles),1);
            parameters = cell(length(dataFiles),1);
            fCounter = fCounter + 1; % track number of recording sessions
    
           for iii = 1:size(dataFiles,1) % loop through dataFiles
               fprintf('Loading %s %s file %d... \n', pIDs{i}, dataDirs(ii).name, iii);
               [signals{iii}, states{iii}, parameters{iii}] = load_bcidat(fullfile(dataFiles(iii).folder, dataFiles(iii).name));
           end % file loop
    
           % concatenate data split across .dat files
           signals = cell2mat(signals(:,1));
           stimCodes = [];
           for s = 1:length(states)
               stimCodes = [stimCodes; states{s}.StimulusCode];
           end
           parameters = parameters{1}; % only 1 necessary (consistent across blocks)

           % get channel labels
           chanLabels = parameters.ChannelNames.Value;
           macroChanLabels = chanLabels;

           % create peri-stim epochs (1s stim +/- 2s)
           stimImgCodes = [];
           stimEpochs = epoch_BCI_data(stimCodes, parameters, codeKeys.stim, codeKeys.isi, [3, 2]);
           stimData =  cell(length(stimEpochs),1);
           for se = 1:length(stimEpochs) % loop through epochs
               stimData{se} = signals(stimEpochs{se},:);
               stimImg = unique(stimCodes(stimEpochs{se})); % find image code
               stimImgCodes = [stimImgCodes, stimImg(stimImg < min(codeKeys.scrambled))];
           end
           stimData = cell2mat(reshape(stimData,1,1,[]));

           % create peri-no-stim epochs (1s stim +/- 2s)
           noStimImgCodes = [];
           noStimEpochs = epoch_BCI_data(stimCodes, parameters, codeKeys.noStim, codeKeys.isi, [3, 2]);
           noStimData =  cell(length(noStimEpochs),1);
           keeps = []; % klugey solution for getting rid of scrambled images not present during test phase
           keepCounter = 1;
           for nse = 1:length(noStimEpochs) % loop through epochs
               noStimData{nse} = signals(noStimEpochs{nse},:);
               noStimImg = unique(stimCodes(noStimEpochs{nse})); % find image code
               if noStimImg(1) < min(codeKeys.scrambled)
                   keeps = [keeps, keepCounter]; % indices of non-scrambled images
               end
               noStimImgCodes = [noStimImgCodes, noStimImg(noStimImg < min(codeKeys.scrambled))];
               keepCounter = keepCounter + 1;
           end
           noStimData = noStimData(keeps); % remove epochs w/ scrambled images
           noStimData = cell2mat(reshape(noStimData,1,1,[]));

           % map codes to outcomes
           testDirs = dir(fullfile(INMANLab_path, pIDs{i}, 'Data', 'BLAES_test'));
           TDfile = dir(fullfile(INMANLab_path, pIDs{i}, 'Data', 'BLAES_test', dataDirs(ii).name, '*Test_Data*.mat'));
           outcomeTable = load(fullfile(TDfile.folder, TDfile.name)).collectData;

           responses = {};
           imgType = {};
           imgContent = {};
           outcomes = {};
           conditions = {};

           imgCodes = [stimImgCodes, noStimImgCodes];
           for img = 1:length(imgCodes)
               tableIdx = find([outcomeTable{:,6}] == imgCodes(img));
               responses{img} = outcomeTable{tableIdx,5};
               imgType{img} = outcomeTable{tableIdx,4};
               conditions{img} = outcomeTable{tableIdx,3};
               imgContent{img} = outcomeTable{tableIdx,2};

               if (responses{img} == codeKeys.sureYes) || (responses{img} == codeKeys.maybeYes) % Yes
                   if strcmp(imgType{img}, 'old')
                       outcomes{img} = 'Hit';
                   elseif strcmp(imgType{img}, 'new')
                       outcomes{img} = 'FA';
                   end
               elseif (responses{img} == codeKeys.sureNo) || (responses{img} == codeKeys.maybeNo) % No
                   if strcmp(imgType{img}, 'old')
                       outcomes{img} = 'Miss';
                   elseif strcmp(imgType{img}, 'new')
                       outcomes{img} = 'CR';
                   end
               end
           end

           % save information in structure
           BLAES(fCounter).data = cat(3,stimData, noStimData);
           BLAES(fCounter).conditions = conditions;
           BLAES(fCounter).responses = responses;
           BLAES(fCounter).imgCodes = imgCodes;
           BLAES(fCounter).imgType = imgType;
           BLAES(fCounter).imgContent = imgContent;
           BLAES(fCounter).outcomes = outcomes;
           BLAES(fCounter).chanLabels = macroChanLabels;
           BLAES(fCounter).parameters = parameters;
           BLAES(fCounter).pID = pIDs{i};
           BLAES(fCounter).imageset = dataDirs(ii).name;
    
        end % session loop

    catch 
        fprintf('Error preparing data for %s \n', pIDs{i});

    end % try-catch

end % pID loop

%% Export

version = datetime;
clearvars -except BLAES version

% Save separate .mat files
for i = 1:length(BLAES)
    rowNum = i;
    sample = BLAES(rowNum);
    sample.version = version;
    saveStr = strcat('D:\BLAES_A2\', sample.pID, '_', sample.imageset, '_study.mat');
    save(saveStr, '-struct', 'sample');
end

% Recreate master dataset from solo files
% matFiles = dir('D:\BLAES_A2\');
% matFiles = matFiles(~ismember({matFiles.name},{'.','..'}));
% BLAES = [];
% for i = 1:length(matFiles)
%     x = load(matFiles(i).name);
%     BLAES = [BLAES;x.sample];
% end

toc;
