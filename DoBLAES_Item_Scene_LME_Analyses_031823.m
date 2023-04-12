%Script to illustrate using linear mixed effects models to analyze BLAES Item vs Scene data
%JRM 3/16/23
%updated 3/18/23 to use a random effect model that nested sessions by patients.

%Load the data, which Joe put into three "long format" (in LME terminology) tables:
%One with Item data only
%One with Scene data only
%One with both Item and Scene data

%The the #5 version of the three models below (item only, scene only, and item and scene) 
% is the most appropriate way to model the random effects of patients and sessions  

%% Load dprime data tables

% All responses
load BLAES_ItemSceneDprimes_031623.mat

%Sure only
load BLAES_ItemSceneDprimes_Sure_032723.mat


%% ITEM ONLY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                               ITEM ONLY FIRST TO ILLUSTRATE SOME THINGS                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Model with random intercept for each patient but no random effect for session  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Run a linear mixed effect model with stimulation (0 or 1 = no or yes) as fixed effect
% and a random intercept for each patient.


%This approach essentially (but not technically) subtracts out each patient's grand mean
% over sessions and across stim and no stim conditions.  However, it will not acount for
% any within-patient differences between sessions.
%This approach would be reasonable if each patient were tested once, OR
% if there were no reason to think that there might be much session-to-
% session variability within a patient.
mylme_Item_1 = fitlme(ItemDprimeTable, 'Dprime ~ 1 + Stim + (1|Patient)');

%Print out info
mylme_Item_1.disp
%--> There are 2 fixed effects coefficients, one for the intercept
%    and one for the difference between stim vs no stim
%--> There are 9 random effects coefficients, one for each patient
%--> The AIC (Akaike Information Criterion) is 59.6. AIC is an index of
%    goodness of fit in which lower is better. AIC accounts for numbers
%    of parameters in a model, which is good since more parameters in
%    general leads to better fits (but potential overfitting).

%Print out just the ANOVA-style table
mylme_Item_1.anova
%p value for stim fixed effect is 0.12


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%          Model with random intercept for each patient and each session          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Run a linear mixed effect model with stimulation (0 or 1 = no or yes) as fixed effect
% and a random intercept for each patient and a random intercept for each session.

%This approach essentially (but not technically) subtracts out each patient's grand mean
% AND the grand mean for each session (grand mean of session 1; grand mean of session 2;
% grand mean of session 3).

%This approach would be reasonable if we thought there was something universally important
% about the first session across all participants, and the second session across all participants
% etc. For example, if we always stimulated high, medium, and low currents acorss the three sessions.
%But we didn't do it that way, of course.

mylme_Item_2 = fitlme(ItemDprimeTable, 'Dprime ~ 1 + Stim + (1|Patient) + (1|Session)');

%Print out info
mylme_Item_2.disp
%--> There are still 2 fixed effects coefficients, one for the intercept
%    and one for the difference between stim vs no stim
%--> There are now 12 random effects coefficients, one for each patient
%    and one for each of three possible sessions.
%--> The AIC (Akaike Information Criterion) is 61.6. AIC is an index of
%    goodness of fit in which lower is better. 61.6 is worse than 59.6.

%Print out just the ANOVA-style table
mylme_Item_2.anova
%p value for stim fixed effect is still 0.12


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        Model with random linear effect for each session nested by patient       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Run a linear mixed effect model with stimulation (0 or 1 = no or yes) as fixed effect
% and a random intercept for each patient and a random effect/slope effect of session.

%This approach essentially (but not technically) subtracts out each patient's grand mean
% AND regresses out the trend from sessions 1-3 for each patient.
%This approach would be resonable if we thought there was a linear effect of session.


mylme_Item_3 = fitlme(ItemDprimeTable, 'Dprime ~ 1 + Stim + (Session|Patient)');


%Print out info
mylme_Item_3.disp
%--> There are still 2 fixed effects coefficients, one for the intercept
%    and one for the difference between stim vs no stim
%--> There are now 18 random effects coefficients, one for the random intercept of patient
%    for the 9 patients and one for the random effect of session for each of 9 patients.
%    Note that this model treats session 1, 2, 3 as ordinal variables.
%
%--> The AIC (Akaike Information Criterion) is 22.5. AIC is an index of
%    goodness of fit in which lower is better. 22.5 is way better than 59.6.

%Print out just the ANOVA-style table
mylme_Item_3.anova
%p value for stim fixed effect is now 0.00017



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%          Model with random intercept for each session nested by patient         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Run a linear mixed effect model with stimulation (0 or 1 = no or yes) as fixed effect
% and a random intercept for each session for each patient.

%This approach essentially (but not technically) subtracts out the grand mean
% for each session for each participant.
%This approach is resonable if we think that "session 1" and "session 2" are no
% more related to one another vs "session 1" and "session 3".  In other words,
% we would treat it not as 1, 2, 3 on a scalar axis but as something like
% orange, purple, and green categories with no fixed order.  It's the same model
% as #3, but we will tell Matlab to treat the session numbers as categorical vars.

ItemDprimeTable.Session = categorical(ItemDprimeTable.Session);

mylme_Item_4 = fitlme(ItemDprimeTable, 'Dprime ~ 1 + Stim + (Session|Patient)');


%Print out info
mylme_Item_4.disp
%--> There are still 2 fixed effects coefficients, one for the intercept
%    and one for the difference between stim vs no stim
%--> There are now 27 random effects coefficients, 9 patients by 3 sessions,
%    even though not all participants had three sessions.
%--> The AIC (Akaike Information Criterion) is 23.5, which is about the
%    same as #3 but way better than #1 (59.6.).

%Print out just the ANOVA-style table
mylme_Item_4.anova
%p value for stim fixed effect is now 0.000025


%------> Take home from #1-#4 above: #3 and #4 fit WAY better than #1 and #2 and
%         make more sense.  The AIC fit for #4 is similar to #3, but #4 has more
%         face validity to me.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   UPDATE 3/18/23 BASED ON READING R LME4 MANUAL       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%After reading the manual for the LME4 package in R (the package
% that most statisticians use for linear mixed effects models), I
% realized that there is a better way to specify the nesting of the
% sessions within patients. The main difference between this one (#5)
% and the above one is that this one will fit a random intercept for
% each patient AND a random intecept for each of 17 sessions.

ItemDprimeTable.Session = categorical(ItemDprimeTable.Session);

%this is how the LME4 R package manual said to do nested random effects
mylme_Item_5 = fitlme(ItemDprimeTable, 'Dprime ~ 1 + Stim + (1|Patient)  + (1|Patient:Session)');
mylme_Item_5.disp
mylme_Item_5.anova
%p value for stim fixed effect is now 0.000055
% F value in Matlab is 21.616

%%%%%%%%%%%%%%%%%
% Matlab fitlme %
%%%%%%%%%%%%%%%%%
%
% Linear mixed-effects model fit by ML
%
% Model information:
%     Number of observations              34
%     Fixed effects coefficients           2
%     Random effects coefficients         26
%     Covariance parameters                3
%
% Formula:
%     Dprime ~ 1 + Stim + (1 | Patient) + (1 | Patient:Session)
%
% Model fit statistics:
%     AIC                 BIC                 LogLikelihood        Deviance
%     33.5596438214529    41.1914464445337    -11.7798219107265    23.5596438214529
%
% Fixed effects coefficients (95% CIs):
%     Name                   Estimate             SE                    tStat               DF
%     {'(Intercept)'}         1.51874961781893     0.208722805030291    7.27639520558631    32
%     {'Stim'       }        0.211823529411765    0.0455603508557123    4.64929539464261    32
%
%
%     pValue                  Lower                Upper
%     2.86631569018364e-08     1.09359517671221     1.94390405892565
%      5.4909590516847e-05    0.119020131614023    0.304626927209506
%
% Random effects covariance parameters (95% CIs):
% Group: Patient (9 Levels)
%     Name1                  Name2                  Type           Estimate            Lower
%     {'(Intercept)'}        {'(Intercept)'}        {'std'}        0.51419997011682    0.270422320000333
%
%
%     Upper
%     0.977735895719749
%
% Group: Patient:Session (17 Levels)
%     Name1                  Name2                  Type           Estimate
%     {'(Intercept)'}        {'(Intercept)'}        {'std'}        0.445317107963215
%
%
%     Lower                Upper
%     0.276183645022586    0.71802704547731
%
% Group: Error
%     Name               Estimate             Lower                 Upper
%     {'Res Std'}        0.132830107075966    0.0949110247805369    0.185898712890421
%
%     ANOVA marginal tests: DFMethod = 'Residual'
%
%     Term                   FStat               DF1    DF2    pValue
%     {'(Intercept)'}        52.9459271878794    1      32     2.86631569018364e-08
%     {'Stim'       }        21.6159476666449    1      32      5.4909590516847e-05





%I ran the same model in R and got the same answer.
% Matlab defaults to ML rather then REML as a fit method, so I told R to use ML and not REML.

%%%%%%%%%%%%%%%%%
%    R LME4     %
%%%%%%%%%%%%%%%%%

% > mylmer5 = lmer(Dprime ~ 1 + Stim + (1|Patient)  + (1|Patient:Session), BLAES_Aim2_1_Dprime_031523, REML=0)
% > summary(mylmer5)
% Formula: Dprime ~ 1 + Stim + (1 | Patient) + (1 | Patient:Session)
%    Data: BLAES_Aim2_1_Dprime_031523
%
%      AIC      BIC   logLik deviance df.resid
%     33.6     41.2    -11.8     23.6       29
%
% Scaled residuals:
%      Min       1Q   Median       3Q      Max
% -1.55896 -0.54065  0.08325  0.48065  1.46613
%
% Random effects:
%  Groups          Name        Variance Std.Dev.
%  Patient:Session (Intercept) 0.19831  0.4453
%  Patient         (Intercept) 0.26440  0.5142
%  Residual                    0.01764  0.1328
% Number of obs: 34, groups:  Patient:Session, 17; Patient, 9
%
% Fixed effects:
%             Estimate Std. Error t value
% (Intercept)  1.51875    0.20872   7.276
% Stim         0.21182    0.04556   4.649
%
% > anova(mylmer5)
% Analysis of Variance Table
%      npar  Sum Sq Mean Sq F value
% Stim    1 0.38139 0.38139  21.616

%% SCENE ONLY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                              SCENE ONLY SECOND FOR PARALLELISM WITH ABOVE                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%parallel model to mylme_Item_3
mylme_Scene_3 = fitlme(SceneDprimeTable, 'Dprime ~ 1 + Stim + (Session|Patient)');
%Print out info
mylme_Scene_3.disp
%Print out just the ANOVA-style table
mylme_Scene_3.anova
%-->slightly negative effect (stim = worse than no stim) and p val = 0.364979263130839

%parallel model to mylme_Item_4
SceneDprimeTable.Session = categorical(SceneDprimeTable.Session);
mylme_Scene_4 = fitlme(SceneDprimeTable, 'Dprime ~ 1 + Stim + (Session|Patient)');
%Print out info
mylme_Scene_4.disp
%Print out just the ANOVA-style table
mylme_Scene_4.anova
%-->similar slightly negative effect (stim = worse than no stim) and p val = 0.320684045756843


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   UPDATE 3/18/23 BASED ON READING R LME4 MANUAL       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SceneDprimeTable.Session = categorical(SceneDprimeTable.Session);

mylme_Scene_5 = fitlme(SceneDprimeTable, 'Dprime ~ 1 + Stim + (1|Patient)  + (1|Patient:Session)');
mylme_Scene_5.disp
%Print out just the ANOVA-style table
mylme_Scene_5.anova
%-->Stim effect for Scene data still not significant; p =  0.344768543003311

%% ITEM AND SCENE IN ONE MODEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                              ITEM AND SCENE DATA IN ONE MODEL                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%parallel to models 3 above
%Item vs Scene as categorical; shouldn't make a difference with only two levels
ItemSceneDprimeTable.ItemScene = categorical(ItemSceneDprimeTable.ItemScene);
mylme_ItemScene_3 = fitlme(ItemSceneDprimeTable, 'Dprime ~ 1 + Stim*ItemScene + (Session|Patient)');
mylme_ItemScene_3.disp
mylme_ItemScene_3.anova
%      Term                      FStat               DF1    DF2    pValue
%     {'(Intercept)'   }        100.155139997854    1      64     1.02317319574359e-14
%     {'Stim'          }        2.54802667346697    1      64        0.115358589588817
%     {'ItemScene'     }         14.015827518875    1      64     0.000390556253563591
%     {'Stim:ItemScene'}         2.2405118321716    1      64        0.139352166277161
%-->no significant interaction

%parallel to models 4 above
%session as categorical
ItemSceneDprimeTable.Session = categorical(ItemSceneDprimeTable.Session);
mylme_ItemScene_4 = fitlme(ItemSceneDprimeTable, 'Dprime ~ 1 + Stim*ItemScene + (Session|Patient)');
mylme_ItemScene_4.disp
mylme_ItemScene_4.anova
%     Term                      FStat               DF1    DF2    pValue
%     {'(Intercept)'   }        103.981889224778    1      64     4.86075555557795e-15
%     {'Stim'          }        2.63756138467034    1      64        0.109279141413546
%     {'ItemScene'     }        14.5083274923825    1      64     0.000315414393488009
%     {'Stim:ItemScene'}        2.31924082740942    1      64        0.132708541559328
%-->no significant interaction



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   UPDATE 3/18/23 BASED ON READING R LME4 MANUAL       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ItemSceneDprimeTable.Session = categorical(ItemSceneDprimeTable.Session);
mylme_ItemScene_5 = fitlme(ItemSceneDprimeTable, 'Dprime ~ 1 + Stim*ItemScene + (1|Patient)  + (1|Patient:Session)');

mylme_ItemScene_5.disp
mylme_ItemScene_5.anova

%     ANOVA marginal tests: DFMethod = 'Residual'
% 
%     Term                      FStat               DF1    DF2    pValue              
%     {'(Intercept)'   }        58.4974495701865    1      64     1.34403659878353e-10
%     {'Stim'          }        2.74567195712512    1      64        0.102412871347829
%     {'ItemScene'     }        13.9561250851883    1      64     0.000400852655712006
%     {'Stim:ItemScene'}        2.23096804969391    1      64        0.140183108799038
%-->no significant interaction

