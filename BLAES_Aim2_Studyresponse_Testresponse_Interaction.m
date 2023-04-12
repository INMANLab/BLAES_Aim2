%% Create by Krista Wahlstrom 2022
%Determine BLAES Aim 2.1 behavioral responses for study images and test
%images
clear;
close all;


%% Load and pre-process Study phase BCI2000 behavioral data 
addpath(genpath(fullfile(cd,'BCI2000Tools')))

subjID         = 'BJH027';
imageset       = 'imageset3';


d = dir(fullfile(cd,'data',subjID,'Study',imageset,'*.dat'));


%Set this to true if patient is responding as you would expect during the
%presentation of the images. Set this to False, if patient did not respond
%during the presentation of the image (and instead made responses during
%the stimulation period 1501/1502 or the inter-trial ISI period 1801 or 
% during the fixation cross perdiod 1601-1786) 
respondDuringImage = false;


%Create response string for saving separate figure files and .mat files based on which analysis is run 
if respondDuringImage == true
    ResponseString = '_RespondDurStudyImage';
else
    ResponseString = '_RespondAftStudyImage';
end


%Combine all .dat files for the study phase session into one matrix
iter2 = 1;
    for file = 1:size(d,1)
        
        [~, states, parameters] = load_bcidat(fullfile(d(file).folder,d(file).name));
        pause(1);

        SEQ = parameters.Sequence.NumericValue;
        KD = states.KeyDown;
        StimCode = states.StimulusCode;
        %Includes only stimulus codes for items and scenes, no scrambled
        SEQ(SEQ < 101) = [];
        SEQ(SEQ > 472) = [];

        %Replaces the stimcode values that are not equal to a SEQ/image
        %stimulus code, with the previously shown image's stimulus code/SEQ
        %value if respondDuringImage is set to "false" so that keypresses
        %can be gathered from during the intertrial period
        if(~respondDuringImage)
            lastValidImage = -1;
            for i = 1:length(StimCode)
                if(lastValidImage ~= StimCode(i) && ismember(StimCode(i), SEQ))
                    lastValidImage = StimCode(i);
                elseif(lastValidImage ~= -1 && ~ismember(StimCode(i), SEQ))
                    StimCode(i) = lastValidImage;
                end
            end
        end

        %Create a copy of the keypresses file
        KDCopy = KD;
        KDCopy(KDCopy==0) = [];
        

        %Create keyPresses variable which lists the keypresses, the stimcode, and the stimcode index at which that key press occurred 
        cnt = 1;
        keyPresses = zeros(length(KDCopy), 3);
        for i = 1:length(KD)
            if(KD(i) ~= 0)
                keyPresses(cnt,1) = KD(i);
                keyPresses(cnt,2) = StimCode(i);
                keyPresses(cnt,3) = i;
                cnt = cnt + 1;
            end
        end
%% Add Study phase response data to the StudyTestResponseData matrix

        %Create StudyTestResponseData matrix of filename, stimulus code/image
        %code, image type (item/scene), stim or no stim, key press
        for i = 1:length(SEQ)
            StudyTestResponseData{iter2,1} = parameters.Stimuli.Value{6,SEQ(i)};
            StudyTestResponseData{iter2,2} = SEQ(i);
            StudyTestResponseData{iter2,3} = parameters.Stimuli.Value{9,SEQ(i)};
            StudyTestResponseData{iter2,4} = str2num(parameters.Stimuli.Value{8,SEQ(i)});

            idx = ismember(keyPresses(:,2), SEQ(i));
            keyPressesForSeq = keyPresses(idx, :);

            pressForImage = 0;
            for j = 1: size(keyPressesForSeq)
                if(pressForImage == 0)
                    pressForImage = keyPressesForSeq(j, 1);
                elseif(keyPressesForSeq(j, 1) == 37 || keyPressesForSeq(j, 1) == 39)
                    pressForImage = keyPressesForSeq(j, 1);
                end
    
                if(pressForImage == 37 || pressForImage == 39)
                    break;
                end
            end

            if pressForImage == 37
                StudyTestResponseData{iter2,5} = 'Dislike';
            elseif pressForImage == 39
                StudyTestResponseData{iter2,5} = 'Like';
            else
                StudyTestResponseData{iter2,5} = 'Non-Response Key';
            end

            StudyTestResponseData{iter2, 6} = pressForImage;
            iter2 = iter2 + 1;
        end

    end

%% Load Test phase BCI2000 behavioral data 

%This next section requires that you've already run the
%BLAES_BehavioralAnalysis script that creates the collectData matrix of the
%Test phase behavioral responses

if exist(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Test_Data_',imageset,'.mat')))
    load(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Test_Data_',imageset,'.mat')))
end
    
%% Add Test phase response data to the StudyTestResponseData matrix  

imageStimCodeTestPhasePressMap = containers.Map(collectData(:, 6), collectData(:, 5));
for i = 1:size(StudyTestResponseData,1)
    imageStimCode = cell2mat(StudyTestResponseData(i,2));
    if isKey(imageStimCodeTestPhasePressMap, imageStimCode)
        StudyTestResponseData(i,7) = num2cell(imageStimCodeTestPhasePressMap(imageStimCode));
    else
        StudyTestResponseData(i,7) = cellstr('Not Found');
    end
end

save(fullfile(cd,'data',subjID, strcat(subjID,imageset,'_StudyTestResponseInteraction_Data', ResponseString,'.mat')),'StudyTestResponseData')

%% Behavioral Analysis
%Create a copy of StudyTestResponseData so the original data is preserved.


%Within this replicate matrix, change item-scrambledA and item-scrambledB
%to "item" and %scene to "scene" (this %scene only exists in some of the first
%patient data sets.
StudyTestResp_Revised = StudyTestResponseData;
for k = 1:size(StudyTestResp_Revised,1)
    if contains(StudyTestResp_Revised{k,3},'item-')
        StudyTestResp_Revised{k,3} = 'item';
    elseif contains(StudyTestResp_Revised{k,3},'% scene')
        StudyTestResp_Revised{k,3} = 'scene';
    end
end


%Change column 4 of StudyTestResp_Revised to stim/nostim
for k = 1:size(StudyTestResp_Revised,1)
    if StudyTestResp_Revised{k,4} == 0
        StudyTestResp_Revised{k,4} = 'No-Stim';
    elseif StudyTestResp_Revised{k,4} == 1
        StudyTestResp_Revised{k,4} = 'Stimulated';
    end
end


%Change column 7 of StudyTestResp_Revised from key press to text
for k = 1:size(StudyTestResp_Revised,1)
    if StudyTestResp_Revised{k,7} == 78
        StudyTestResp_Revised{k,7} = 'Sure Yes';
    elseif StudyTestResp_Revised{k,7} == 66
        StudyTestResp_Revised{k,7} = 'Maybe Yes';
    elseif StudyTestResp_Revised{k,7} == 86
        StudyTestResp_Revised{k,7} = 'Maybe No';
    elseif StudyTestResp_Revised{k,7} == 67
        StudyTestResp_Revised{k,7} = 'Sure No';
    end
end



%Change the StudyTestResp_Revised matrix into a table
ResponseTable = cell2table(StudyTestResp_Revised);


%Add all possible study behavioral response options (Dislike, Like, and Non-Response Key
% to column 5 of ResponseTable, and all possible test behavioral responses to column 7 of ResponseTable
% so that in the case where a patient doesn't use one of those responses, they're still added as options to 
% the RespCounts table below to be analyzed. Also (arbitrarily) add 'scene' to column 3 of ResponseTable table, 
% and 'Stim' to column 4, because MatLab won't accept empty values properly and won't analyze them correctly in the RespCounts table.
ResponseTable(size(ResponseTable,1)+1,3) = {'scene'};
ResponseTable(size(ResponseTable,1),4) = {'Stimulated'};
ResponseTable(size(ResponseTable,1),5) = {'Like'};
ResponseTable(size(ResponseTable,1),7) = {'Sure Yes'};

ResponseTable(size(ResponseTable,1)+1,3) = {'scene'};
ResponseTable(size(ResponseTable,1),4) = {'Stimulated'};
ResponseTable(size(ResponseTable,1),5) = {'Dislike'};
ResponseTable(size(ResponseTable,1),7) = {'Maybe Yes'};

ResponseTable(size(ResponseTable,1)+1,3) = {'scene'};
ResponseTable(size(ResponseTable,1),4) = {'Stimulated'};
ResponseTable(size(ResponseTable,1),5) = {'Non-Response Key'};
ResponseTable(size(ResponseTable,1),7) = {'Maybe No'};

ResponseTable(size(ResponseTable,1)+1,3) = {'scene'};
ResponseTable(size(ResponseTable,1),4) = {'Stimulated'};
ResponseTable(size(ResponseTable,1),5) = {'Like'};
ResponseTable(size(ResponseTable,1),7) = {'Sure No'};


%Get the group counts for Study behavioral response/Test behavioral
%response/Stim-NoStim/Item-Scene
%IncludeEmptyGroups will also display values in the table that are zero
RespCounts = groupcounts(ResponseTable,{'StudyTestResp_Revised3','StudyTestResp_Revised4', 'StudyTestResp_Revised5','StudyTestResp_Revised7'}, 'IncludeEmptyGroups', true);

%Subtract 1 from each of the groupcounts in the RespCounts table that's
%associated with the four artificially added rows in the ResponseTable
for l = 1:size(RespCounts,1)
    if contains(RespCounts{l,1}, 'scene') && contains(RespCounts{l,2}, 'Stimulated') && contains(RespCounts{l,3}, 'Like') && contains(RespCounts{l,4}, 'Sure Yes')
        RespCounts{l,5} = RespCounts{l,5}-1;
    elseif contains(RespCounts{l,1}, 'scene') && contains(RespCounts{l,2}, 'Stimulated') && contains(RespCounts{l,3}, 'Dislike') && contains(RespCounts{l,4}, 'Maybe Yes')
        RespCounts{l,5} = RespCounts{l,5}-1;
    elseif contains(RespCounts{l,1}, 'scene') && contains(RespCounts{l,2}, 'Stimulated') && contains(RespCounts{l,3}, 'Non-Response Key') && contains(RespCounts{l,4}, 'Maybe No')
        RespCounts{l,5} = RespCounts{l,5}-1;
    elseif contains(RespCounts{l,1}, 'scene') && contains(RespCounts{l,2}, 'Stimulated') && contains(RespCounts{l,3}, 'Like') && contains(RespCounts{l,4}, 'Sure No')
        RespCounts{l,5} = RespCounts{l,5}-1;
    end
end

%Sort RespCounts alphabetically
RespCounts = sortrows(RespCounts,2);
RespCounts = sortrows(RespCounts,1);

%Remove the percent column from RespCounts because it's not needed for
%analysis
RespCounts.Percent = [];

%% Plotting

%Create text for the upper corner of each bar plot that lists each
%condition and the number of responses for each

%Items
plottext_Items_SureYes = {strcat('Item-NoStim-Like-SureYes: ',num2str(RespCounts{8,5})),strcat('Item-Stim-Like-SureYes: ',num2str(RespCounts{20,5})),...
    strcat('Item-NoStim-Dislike-SureYes: ',num2str(RespCounts{4,5})),strcat('Item-Stim-Dislike-SureYes: ',num2str(RespCounts{16,5}))};


plottext_Items_MaybeYes = {strcat('Item-NoStim-Like-MaybeYes: ',num2str(RespCounts{6,5})),strcat('Item-Stim-Like-MaybeYes: ',num2str(RespCounts{18,5})),...
    strcat('Item-NoStim-Dislike-MaybeYes: ',num2str(RespCounts{2,5})),strcat('Item-Stim-Dislike-MaybeYes: ',num2str(RespCounts{14,5}))};


plottext_Items_SureNo = {strcat('Item-NoStim-Like-SureNo: ',num2str(RespCounts{7,5})),strcat('Item-Stim-Like-SureNo: ',num2str(RespCounts{19,5})),...
    strcat('Item-NoStim-Dislike-SureNo: ',num2str(RespCounts{3,5})),strcat('Item-Stim-Dislike-SureNo: ',num2str(RespCounts{15,5}))};


plottext_Items_MaybeNo = {strcat('Item-NoStim-Like-MaybeNo: ',num2str(RespCounts{5,5})),strcat('Item-Stim-Like-MaybeNo: ',num2str(RespCounts{17,5})),...
    strcat('Item-NoStim-Dislike-MaybeNo: ',num2str(RespCounts{1,5})),strcat('Item-Stim-Dislike-MaybeNo: ',num2str(RespCounts{13,5}))};



%Scenes
plottext_Scenes_SureYes = {strcat('Scene-NoStim-Like-SureYes: ',num2str(RespCounts{32,5})),strcat('Scene-Stim-Like-SureYes: ',num2str(RespCounts{44,5})),...
    strcat('Scene-NoStim-Dislike-SureYes: ',num2str(RespCounts{28,5})),strcat('Scene-Stim-Dislike-SureYes: ',num2str(RespCounts{40,5}))};


plottext_Scenes_MaybeYes = {strcat('Scene-NoStim-Like-MaybeYes: ',num2str(RespCounts{30,5})),strcat('Scene-Stim-Like-MaybeYes: ',num2str(RespCounts{42,5})),...
    strcat('Scene-NoStim-Dislike-MaybeYes: ',num2str(RespCounts{26,5})),strcat('Scene-Stim-Dislike-MaybeYes: ',num2str(RespCounts{38,5}))};


plottext_Scenes_SureNo = {strcat('Scene-NoStim-Like-SureNo: ',num2str(RespCounts{31,5})),strcat('Scene-Stim-Like-SureNo: ',num2str(RespCounts{43,5})),...
    strcat('Scene-NoStim-Dislike-SureNo: ',num2str(RespCounts{27,5})),strcat('Scene-Stim-Dislike-SureNo: ',num2str(RespCounts{39,5}))};


plottext_Scenes_MaybeNo = {strcat('Scene-NoStim-Like-MaybeNo: ',num2str(RespCounts{29,5})),strcat('Scene-Stim-Like-MaybeNo: ',num2str(RespCounts{41,5})),...
    strcat('Scene-NoStim-Dislike-MaybeNo: ',num2str(RespCounts{25,5})),strcat('Scene-Stim-Dislike-MaybeNo: ',num2str(RespCounts{37,5}))};



%Plot each response combination as a count

%Items_SureYes
b = bar([(RespCounts{8,5});(RespCounts{20,5});(RespCounts{4,5});(RespCounts{16,5})]);

xlim([0 8])
ylim([0 50])

b.FaceColor = 'flat';
%Set bar colors
b.CData(1,:) = [1 0 0];
b.CData(2,:) = [1 0 0];
b.CData(3,:) = [1 0 0];
b.CData(4,:) = [1 0 0];


%Set the plottext labels to be positioned above bar 13 on the xaxis, and the
%yaxis position to be at 95% of the max number of behavioral responses that
%occur
text(4.5,max(RespCounts{:,5})*0.95, plottext_Items_SureYes)
title([subjID, ' ', imageset, ' ', 'Items-SureYes'],'fontweight','bold','fontsize',14)
xticklabels({'Item-NoStim-Like-SureYes', 'Item-Stim-Like-SureYes','Item-NoStim-Dislike-SureYes','Item-Stim-Dislike-SureYes'})
xlabel('Study-Test Behavioral Response','fontweight','bold','fontsize',12)
ylabel('Counts','fontweight','bold','fontsize',12)

%get current figure "gcf" for saving purposes
f = gcf;

%Save bar graph
savefile = fullfile(cd, 'figures', subjID, imageset, strcat(subjID, '_', imageset, ResponseString, '_ItemSureYes_StudyTestResponseInteraction.png'));
saveas(f, savefile);




%Items_MaybeYes
b = bar([(RespCounts{6,5});(RespCounts{18,5});(RespCounts{2,5});(RespCounts{14,5})]);

xlim([0 8])
ylim([0 50])

b.FaceColor = 'flat';
%Set bar colors
b.CData(1,:) = [1 0.55 0.55];
b.CData(2,:) = [1 0.55 0.55];
b.CData(3,:) = [1 0.55 0.55];
b.CData(4,:) = [1 0.55 0.55];


%Set the plottext labels to be positioned above bar 13 on the xaxis, and the
%yaxis position to be at 95% of the max number of behavioral responses that
%occur
text(4.5,max(RespCounts{:,5})*0.95, plottext_Items_MaybeYes)
title([subjID, ' ', imageset, ' ', 'Items-MaybeYes'],'fontweight','bold','fontsize',14)
xticklabels({'Item-NoStim-Like-MaybeYes', 'Item-Stim-Like-MaybeYes','Item-NoStim-Dislike-MaybeYes','Item-Stim-Dislike-MaybeYes'})
xlabel('Study-Test Behavioral Response','fontweight','bold','fontsize',12)
ylabel('Counts','fontweight','bold','fontsize',12)

%get current figure "gcf" for saving purposes
f = gcf;

%Save bar graph
savefile = fullfile(cd, 'figures', subjID, imageset, strcat(subjID, '_', imageset, ResponseString, '_ItemMaybeYes_StudyTestResponseInteraction.png'));
saveas(f, savefile);




%Items_SureNo
b = bar([(RespCounts{7,5});(RespCounts{19,5});(RespCounts{3,5});(RespCounts{15,5})]);

xlim([0 8])
ylim([0 50])

b.FaceColor = 'flat';
%Set bar colors
b.CData(1,:) = [0 0 1];
b.CData(2,:) = [0 0 1];
b.CData(3,:) = [0 0 1];
b.CData(4,:) = [0 0 1];


%Set the plottext labels to be positioned above bar 13 on the xaxis, and the
%yaxis position to be at 95% of the max number of behavioral responses that
%occur
text(4.5,max(RespCounts{:,5})*0.95, plottext_Items_SureNo)
title([subjID, ' ', imageset, ' ', 'Items-SureNo'],'fontweight','bold','fontsize',14)
xticklabels({'Item-NoStim-Like-SureNo', 'Item-Stim-Like-SureNo','Item-NoStim-Dislike-SureNo','Item-Stim-Dislike-SureNo'})
xlabel('Study-Test Behavioral Response','fontweight','bold','fontsize',12)
ylabel('Counts','fontweight','bold','fontsize',12)


%get current figure "gcf" for saving purposes
f = gcf;

%Save bar graph
savefile = fullfile(cd, 'figures', subjID, imageset, strcat(subjID, '_', imageset, ResponseString, '_ItemSureNo_StudyTestResponseInteraction.png'));
saveas(f, savefile);




%Items_MaybeNo
b = bar([(RespCounts{5,5});(RespCounts{17,5});(RespCounts{1,5});(RespCounts{13,5})]);

xlim([0 8])
ylim([0 50])

b.FaceColor = 'flat';
%Set bar colors
b.CData(1,:) = [0.49 0.53 0.85];
b.CData(2,:) = [0.49 0.53 0.85];
b.CData(3,:) = [0.49 0.53 0.85];
b.CData(4,:) = [0.49 0.53 0.85];


%Set the plottext labels to be positioned above bar 13 on the xaxis, and the
%yaxis position to be at 95% of the max number of behavioral responses that
%occur
text(4.5,max(RespCounts{:,5})*0.95, plottext_Items_MaybeNo)
title([subjID, ' ', imageset, ' ', 'Items-MaybeNo'],'fontweight','bold','fontsize',14)
xticklabels({'Item-NoStim-Like-MaybeNo', 'Item-Stim-Like-MaybeNo','Item-NoStim-Dislike-MaybeNo','Item-Stim-Dislike-MaybeNo'})
xlabel('Study-Test Behavioral Response','fontweight','bold','fontsize',12)
ylabel('Counts','fontweight','bold','fontsize',12)


%get current figure "gcf" for saving purposes
f = gcf;

%Save bar graph
savefile = fullfile(cd, 'figures', subjID, imageset, strcat(subjID, '_', imageset, ResponseString, '_ItemMaybeNo_StudyTestResponseInteraction.png'));
saveas(f, savefile);





%Scenes_SureYes
b = bar([(RespCounts{32,5});(RespCounts{44,5});(RespCounts{28,5});(RespCounts{40,5})]);

xlim([0 8])
ylim([0 50])

b.FaceColor = 'flat';
%Set bar colors
b.CData(1,:) = [1 0.7 0.2];
b.CData(2,:) = [1 0.7 0.2];
b.CData(3,:) = [1 0.7 0.2];
b.CData(4,:) = [1 0.7 0.2];


%Set the plottext labels to be positioned above bar 13 on the xaxis, and the
%yaxis position to be at 95% of the max number of behavioral responses that
%occur
text(4.5,max(RespCounts{:,5})*0.95, plottext_Scenes_SureYes)
title([subjID, ' ', imageset, ' ', 'Scenes-SureYes'],'fontweight','bold','fontsize',14)
xticklabels({'Scene-NoStim-Like-SureYes', 'Scene-Stim-Like-SureYes','Scene-NoStim-Dislike-SureYes','Scene-Stim-Dislike-SureYes'})
xlabel('Study-Test Behavioral Response','fontweight','bold','fontsize',12)
ylabel('Counts','fontweight','bold','fontsize',12)


%get current figure "gcf" for saving purposes
f = gcf;

%Save bar graph
savefile = fullfile(cd, 'figures', subjID, imageset, strcat(subjID, '_', imageset, ResponseString, '_SceneSureYes_StudyTestResponseInteraction.png'));
saveas(f, savefile);




%Scenes_MaybeYes
b = bar([(RespCounts{30,5});(RespCounts{42,5});(RespCounts{26,5});(RespCounts{38,5})]);

xlim([0 8])
ylim([0 50])

b.FaceColor = 'flat';
%Set bar colors
b.CData(1,:) = [1 1 0.1];
b.CData(2,:) = [1 1 0.1];
b.CData(3,:) = [1 1 0.1];
b.CData(4,:) = [1 1 0.1];


%Set the plottext labels to be positioned above bar 13 on the xaxis, and the
%yaxis position to be at 95% of the max number of behavioral responses that
%occur
text(4.5,max(RespCounts{:,5})*0.95, plottext_Scenes_MaybeYes)
title([subjID, ' ', imageset, ' ', 'Scenes-MaybeYes'],'fontweight','bold','fontsize',14)
xticklabels({'Scene-NoStim-Like-MaybeYes', 'Scene-Stim-Like-MaybeYes','Scene-NoStim-Dislike-MaybeYes','Scene-Stim-Dislike-MaybeYes'})
xlabel('Study-Test Behavioral Response','fontweight','bold','fontsize',12)
ylabel('Counts','fontweight','bold','fontsize',12)

%get current figure "gcf" for saving purposes
f = gcf;

%Save bar graph
savefile = fullfile(cd, 'figures', subjID, imageset, strcat(subjID, '_', imageset, ResponseString, '_SceneMaybeYes_StudyTestResponseInteraction.png'));
saveas(f, savefile);





%Scenes_SureNo
b = bar([(RespCounts{31,5});(RespCounts{43,5});(RespCounts{27,5});(RespCounts{39,5})]);

xlim([0 8])
ylim([0 50])

b.FaceColor = 'flat';
%Set bar colors
b.CData(1,:) = [0.05 0.42 0.12];
b.CData(2,:) = [0.05 0.42 0.12];
b.CData(3,:) = [0.05 0.42 0.12];
b.CData(4,:) = [0.05 0.42 0.12];


%Set the plottext labels to be positioned above bar 13 on the xaxis, and the
%yaxis position to be at 95% of the max number of behavioral responses that
%occur
text(4.5,max(RespCounts{:,5})*0.95, plottext_Scenes_SureNo)
title([subjID, ' ', imageset, ' ', 'Scenes-SureNo'],'fontweight','bold','fontsize',14)
xticklabels({'Scene-NoStim-Like-SureNo', 'Scene-Stim-Like-SureNo','Scene-NoStim-Dislike-SureNo','Scene-Stim-Dislike-SureNo'})
xlabel('Study-Test Behavioral Response','fontweight','bold','fontsize',12)
ylabel('Counts','fontweight','bold','fontsize',12)


%get current figure "gcf" for saving purposes
f = gcf;

%Save bar graph
savefile = fullfile(cd, 'figures', subjID, imageset, strcat(subjID, '_', imageset, ResponseString, '_SceneSureNo_StudyTestResponseInteraction.png'));
saveas(f, savefile);




%Scenes_MaybeNo
b = bar([(RespCounts{29,5});(RespCounts{41,5});(RespCounts{25,5});(RespCounts{37,5})]);

xlim([0 8])
ylim([0 50])

b.FaceColor = 'flat';
%Set bar colors
b.CData(1,:) = [0.40 0.80 0.40];
b.CData(2,:) = [0.40 0.80 0.40];
b.CData(3,:) = [0.40 0.80 0.40];
b.CData(4,:) = [0.40 0.80 0.40];


%Set the plottext labels to be positioned above bar 13 on the xaxis, and the
%yaxis position to be at 95% of the max number of behavioral responses that
%occur
text(4.5,max(RespCounts{:,5})*0.95, plottext_Scenes_MaybeNo)
title([subjID, ' ', imageset, ' ', 'Scenes-MaybeNo'],'fontweight','bold','fontsize',14)
xticklabels({'Scene-NoStim-Like-MaybeNo', 'Scene-Stim-Like-MaybeNo','Scene-NoStim-Dislike-MaybeNo','Scene-Stim-Dislike-MaybeNo'})
xlabel('Study-Test Behavioral Response','fontweight','bold','fontsize',12)
ylabel('Counts','fontweight','bold','fontsize',12)



%get current figure "gcf" for saving purposes
f = gcf;

%Save bar graph
savefile = fullfile(cd, 'figures', subjID, imageset, strcat(subjID, '_', imageset, ResponseString, '_SceneMaybeNo_StudyTestResponseInteraction.png'));
saveas(f, savefile);
