function epochs = epoch_BCI_data(stimulus_codes, parameters, start_code, end_code, pad)
% 
% epoch_BCI_data finds the index which marks the transition between two
% stimulus codes and creates an epoch around that transition.
%
% ArgIn: 
%    - stimulus_codes: stimulus_code information generated from states var using load_BCI_dat.m [1 x 1 struct]
%    - parameters: parameter information generated from load_BCI_dat.m [1 x 1 struct]
%    - start_code: unique BCI2000 code for stimulus [int]
%    - end_code: unique BCI2000 code for stimulus [int]
%    - pad: time (in seconds) to pad around transition [2 x 1 array]
% ArgOut:
%    - epoch_start_idxs: index marking the transition from start_code to end-code [1 x n array]
%    - epochs: indices surrounding transition from start_code to end-code
%    with padding applied before/after [n x 1 cell]
%
% E.G.,:
%    [epoch_start_idxs, epochs] = epoch_BCI_data(states, 1502, 1801, [0, 5]); % find
%    the transition from stim (1502) to ISI (1801) and create an epoch
%    with 5 seconds of padding after end of stim
%
% Author:    Justin Campbell
% Contact:   justin.campbell@hsc.utah.edu 
% Version:   03-01-2022
%% 

% Find Trials
epoch_start_idxs = [];
for i = 1:length(stimulus_codes)
    if stimulus_codes(i) == end_code; % if stimulus code matches end_code
        if stimulus_codes(i - 1) == start_code; % and if previous stimulus code matches start_code
            epoch_start_idxs = [epoch_start_idxs (i-1)]; % add index of last sample to array (last instance of start_code, NOT first instance of _code)
        end
    end
end

% Create epochs w/ padding (in seconds)
epochs = cell(length(epoch_start_idxs),1);
pre_pad = pad(1) * parameters.SamplingRate.NumericValue;
post_pad = pad(2) * parameters.SamplingRate.NumericValue;
for i = 1:length(epoch_start_idxs) % loop through no_stim trials
    if (pre_pad ~= 0) && (post_pad ~= 0) % pad pre- and post-
        epochs{i} = (epoch_start_idxs(i) - pre_pad):(epoch_start_idxs(i) + post_pad);
    elseif (pre_pad == 0) && (post_pad ~= 0) % pad post- only
        epochs{i} = epoch_start_idxs(i):(epoch_start_idxs(i) + post_pad);
    elseif (pre_pad ~= 0) && (post_pad == 0) % pad pre- only
        epochs{i} = (epoch_start_idxs(i) - pre_pad):epoch_start_idxs(i);
    else % no padding specified
        error('Need to specify padding (in sec) to create epochs!')
    end
end

% Summarize output
% fprintf('Created %d epochs with %ds pre- and %ds post-padding around the transition from %d to %d\n', size(epochs,1), pad(1), pad(2), start_code, end_code);

end