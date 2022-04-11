%{

%}

classdef track < handle
        
    properties (Access = private)
        originalCopy;   % A backup copy of the track, stays unaltered
        actualTrack;    % The sample array itself
        delayMatrix;    % A matrix of the repeats
        monoTrack;      % Gets used to build the delay
        speed;          % scalar - playback speed
        delayTime;      % time between repeats
        numRepeats;     % number of rows in delayMatrix
        delayVol;       % array - how loud the repeats are
        hiPassFreq;     % Scalar
        loPassFreq;     % Scalar
        filterType;     % 1 is low pass, 2 is high pass, 3 is band pass
        reverseStatus;  % Logical - is the "reverse" effect on?
        delayStatus;    % Logical - is delay on?
        filterStatus;   % Logical - is filter on?
        analogSim;      % Logical - is this on?
        removeStatus;   % Logical - is the voice remover on?
        size            % Scalar
        startTime       % in samples. Used in chopper
        endTime         % in samples, used in chopper
        sampleFreq;     % Scalar used for playback, public for chopper
    end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods
        
%%%%%%%%%%%%%% Contents %%%%%%%%%%%%%%%%%%%
    %%%%% Important stuff %%%%%
        % Constructor function
        % Reinitialize (Wave generator)
        % initialize
        % Play
        % Stop
    %%%%% Chopper GUI %%%%%
        % Set start time
        % Set end time
        % Get start time
        % Get end time
        % Get aray
    %%%%% Effects Toggling %%%%%
        % Reverse on
        % Reverse off
        % Filter on
        % Filter off
        % Revert (to original speed)
        % Delay on
        % Delay off
        % Analog sim on
        % Analog sim off
        % Remove center
        % Un-remove center
    %%%%% Addtl Effects Controls %%%%%
        %%% Delay
            %Set number of repeats
            %Set volume
            %Set time
        %%% Filter
            %Set Hi-pass frequency
            %Set lo-pass frequency
            % Set filter type
            % Set filter
        %%% Speed
            % Speed up
            % Slow down
            % Set speed
    %%%%% Extras %%%%%
        % Show properties
        % Get speed
        % Get size
        % Get sample frequency
    %%%%% In-house operations/coversions (static) %%%%%
        % normalize frequency
        % Milliseconds-to-samples conversion
        % Calculate Total Length
        % Mix to mono

%%%%%%%%%% Important stuff %%%%%%%%%%%%%%%
        
        %Constructor
        function obj = track(sample, sampleFreq)
            %Assumes sample is an array, sampleFreq is an int
            obj.initialize(sample, sampleFreq);
        end
        
        % This is a copy of the constructor function. It is used by the 
        % Wave Generator GUI when the user creates a custom sample.
        function reInitialize(obj,sample, sampleFreq)
            obj.initialize(sample, sampleFreq);
        end
        
        %Called by both constructor and reinitialize
        function initialize(obj, sample, sampleFreq)
            obj.size = size(sample);
            %Forces the inputted array to be a column array
            if obj.size(1) <= 2
                obj.originalCopy = sample';
                obj.actualTrack = sample';
                obj.size = obj.size(end:-1:1);
            else
                obj.originalCopy = sample;
                obj.actualTrack = sample;
            end
            obj.delayMatrix = [];
            obj.monoTrack = []; 
            %min sample frequency is 1000
            if sampleFreq < 1000
                errordlg('Min sample frequency is 1000.','bad');
                obj.sampleFreq = 1000;
            else
                obj.sampleFreq = sampleFreq;
            end
            obj.speed = 1.0;
            obj.delayTime = 10;
            obj.numRepeats = 1;
            obj.delayVol = 0.5;
            obj.loPassFreq = obj.normalizeFreq(sampleFreq, 0.5*sampleFreq);
            obj.hiPassFreq = obj.normalizeFreq(sampleFreq, 0);
            obj.filterType = 1;
            obj.reverseStatus = false;
            obj.delayStatus = false;
            obj.filterStatus = false;
            obj.analogSim = false;
            obj.removeStatus = false;
            obj.startTime = 1;
            obj.endTime = obj.size(1);
        end
        
        % When the play button is pushed in any GUI
        function play(obj)
            dummyTrack = obj.actualTrack(obj.startTime:obj.endTime);
            sound(dummyTrack,obj.sampleFreq.*obj.speed);
            %Set up delay
            if obj.delayStatus == true
%These next two statements do the same thing. 
%For each iteration, they play the sample stored in the ith row of the
%delayedTrack matrix. This is multiplied by the ith value of the volume
%vector, which gets smaller, causing a trailing off effect.
%If analog sim is on, with each repeat the delayedTrack will play fewer
%samples, but at a lower frequency. So the tracks still take the same time
%to complete, but the quality gets worse with each repeat.
                obj.setNumRepeats(obj.numRepeats);
                if obj.analogSim
                    for i = 1:obj.numRepeats
                        sound(obj.delayVol(i).*obj.delayMatrix(i,1:i:end),...
                            floor(obj.sampleFreq*(1/i)*obj.speed));
                    end
                else
                    for i=1:obj.numRepeats
                        sound(obj.delayVol(i).*obj.delayMatrix(i,:),...
                            obj.sampleFreq*obj.speed);
                    end
                end
            end
        end
        
        % When 'stop' button is pressed in any GUI
        function stop(obj)
            clear sound;
        end

        
%%%%%%%%%%%%%% CHOPPING %%%%%%%%%%%%%%%%%%%%%%%%

        %
        function setStartTime(obj, cutTime)
            obj.startTime = cast(cutTime,'uint64');
        end
        
        %
        function setEndTime(obj, cutTime)
            obj.endTime = cast(cutTime,'uint64');
        end 
        
        %
        function sTime = getStartTime(obj)
            sTime = obj.startTime;
        end
        
        %
        function eTime = getEndTime(obj)
            eTime = obj.endTime;
        end
        
        % Get the array out so you can plot in the chopper GUI
        function outArray = getArray(obj)
            obj.startTime = cast(obj.startTime, 'uint64');
            obj.endTime = cast(obj.endTime, 'uint64');
            outArray = obj.actualTrack(obj.startTime: obj.endTime);
        end
        
%%%%%%%%%%% EFFECTS TOGGLING %%%%%%%%%%%
        
        %Just rewrite the array backwards
        function reverseOn(obj)
            obj.reverseStatus = true;
            if obj.removeStatus || obj.size(2) == 1
                obj.actualTrack = obj.actualTrack(end:-1:1);
                %Separate cases for mono and stereo
            elseif obj.size(2) == 2
                obj.actualTrack(:,1) = obj.actualTrack(end:-1:1,1);
                obj.actualTrack(:,2) = obj.actualTrack(end:-1:1,2);
            else
                errordlg('Unexpected error: see reverseOn fxn','bad');
            end
        end
        
        %Do it again
        function reverseOff(obj)
            obj.reverseStatus = false;
            if obj.removeStatus || obj.size(2) == 1
                obj.actualTrack = obj.actualTrack(end:-1:1);
            elseif obj.size(2) == 2
                obj.actualTrack(:,1) = obj.actualTrack(end:-1:1,1);
                obj.actualTrack(:,2) = obj.actualTrack(end:-1:1,2);
            else
                errordlg('Unexpected error: see reverseOff fxn','bad');
            end
        end
        
        %
        function filterOn(obj)
            obj.setLoPass(obj.loPassFreq);
            obj.setHiPass(obj.hiPassFreq);
            obj.filterStatus = true;
        end
        
        %
        function filterOff(obj)
            obj.filterStatus = false;
            %Rewrites the track with the unaltered original copy, necessary
            %because its hard to un-lowpass a signal
            obj.actualTrack = obj.originalCopy;
            %Needs to be re-reversed and re-removed if those effects are on
            if obj.removeStatus
                obj.removeCenter();
            end
            if obj.reverseStatus
                obj.reverseOn();
            end
        end
        
        % After altering speed, this sets it back to original
        function revert(obj)
            obj.speed = 1.0;
        end
        
        %Turning delay on/off resets parameters. Not sure why I set it up
        %this way. Consider changing this in future revision
        function delayOn(obj)
            obj.setVolume(0.5);
            obj.setNumRepeats(1);
            obj.setTime(10);
            obj.delayStatus = true;
        end
        
        %
        function delayOff(obj)
            obj.delayMatrix = [];
            obj.delayStatus = false;
        end
        
        %Analog sim is an extra feature on the delay effect
        function analogOn(obj)
            obj.analogSim = true;
        end
        
        %
        function analogOff(obj)
            obj.analogSim = false;
        end
        
        %
        function removeCenter(obj)
            if obj.size(2) == 1
                errordlg(...
                'Feature only for stereo inputs. Current sample is mono'...
                    , 'Error');
            elseif obj.size(2) == 2
                obj.actualTrack = obj.actualTrack(:,1)-...
                    obj.actualTrack(:,2);
                obj.removeStatus = true;
                obj.size(2) = 1; %because its now a mono track
            else
                errordlg('Unexpected error: see fxn removeCenter','bad');
            end
        end
        
        %
        function unremoveCenter(obj)
            obj.actualTrack = obj.originalCopy;
            obj.size(2) = 2; % because we're converting back to stereo.
            obj.removeStatus = false;
            if obj.reverseStatus
                obj.reverseOn();
            end
        end
            
        
%%%%%%%%%% Additional Effects Controls %%%%%%%%

        %%% DELAY %%%%
        
        %
        function setNumRepeats(obj,numRepeats)
            %Assumes numRepeats is an integer scalar
            obj.numRepeats = numRepeats;
            %The other parameters are dependent on numRepeats,
            %they now need to be adjusted as well
            obj.setVolume(obj.delayVol(1));
            obj.setTime(obj.delayTime);
        end
        
        %Volume is a 1 x numRepeats vector. Each value of the vector
        %is smaller than the last, which causes a trailing off effect.
        function setVolume(obj,value)
            %Assumes value is a scalar between 0 and 1
            obj.delayVol = ones(1,obj.numRepeats);
            for i = 1:obj.numRepeats
                obj.delayVol(end+1-i) = value*i/obj.numRepeats;
            end
        end
        
        %Where the bulk of the delay work is done:
        function setTime(obj, timeMS)
            %Assumes time is a scalar
            obj.delayTime = timeMS;
            numSamples = obj.msToSamplesConverter(timeMS,obj.sampleFreq);
            %The total length of each row of the matrix is equal to the
            %length of the sample, plus an amount of 'dead space' based on
            %time and numRepeats
            dummyTrack = obj.actualTrack(obj.startTime:obj.endTime);
            dummySize = size(dummyTrack);
            [dummySize,d] = max(dummySize);
            if d == 1
                dummyTrack = dummyTrack';
            end
            totalLength = obj.calculateTotalLength(dummySize,...
                numSamples, obj.numRepeats);
            totalLength = int64(totalLength);
            numSamples = int64(numSamples);
            %Initialize matrix
            obj.delayMatrix = zeros(obj.numRepeats,totalLength);
            %Delay must be in mono for this to work.
            obj.monoTrack = obj.mixToMono(obj.actualTrack);
            for i = 1:obj.numRepeats
                %First, set up the amount of front dead space, which gets
                %longer with each iteration to allow the sounds to occur at
                %different times. Same for back deadspace, but it gets
                %shorter.
                frontDeadSpace = i*numSamples;
                backDeadSpace = totalLength-frontDeadSpace-dummySize(1);
                %Construct each row of the matrix. If stereo, use
                %monoTrack, otherwise use actualTrack
                obj.delayMatrix(i,:) = [zeros(1,frontDeadSpace),...
                    dummyTrack, zeros(1, backDeadSpace)];
            end
        end
        
        %%% Filter %%%%
        
        %
        function setHiPass(obj,value)
            obj.hiPassFreq = obj.normalizeFreq(obj.sampleFreq, value);
            %Note: you must call setFilter after calling this fxn!
        end
        
        %
        function setLoPass(obj,value)
            obj.loPassFreq = obj.normalizeFreq(obj.sampleFreq, value);
            %Note: you must call setFilter after calling this fxn!
        end
        
        %
        function setFilterType(obj,num)
            %Assumes num is 1,2, or 3
            %1 is low pass, 2 is high pass, 3 is band pass
            obj.filterType = num;
            %Note: you must call setFilter after calling this fxn!
        end
        
        % Note: setFilter function MUST BE CALLED each time setLoPass,
        % setHiPass, or setFilterType is called, otherwise the changes will
        % not take effect. Previously, all three of those functions called
        % setFilter on their ownn, which made turning the filter on take 
        %forever since it had to run this fxn three times.
        function setFilter(obj)
            %1 is low pass, 2 is high pass, 3 is band pass
            switch obj.filterType
                case 1; obj.actualTrack = lowpass(obj.originalCopy,...
                        obj.loPassFreq, 'Steepness', 0.5);
                case 2; obj.actualTrack = highpass(obj.originalCopy,...
                        obj.hiPassFreq, 'Steepness', 0.5);
                %"Bandpass" just means both high and low pass
                case 3; obj.actualTrack = highpass(lowpass(...
                        obj.originalCopy,obj.loPassFreq,'Steepness',0.5)...
                        ,obj.hiPassFreq, 'Steepness', 0.5);
            end
            %Note that the effect is applied to the original copy, so if
            %the sample was reversed it needs to be re-reversed.
            if obj.removeStatus
                obj.size(2) = 2;
                obj.removeCenter();
            end         
            if obj.reverseStatus
                obj.reverseOn();
            end
        end
        
        %%%% SPeed %%%%%%
        
        %Faster button
        function speedUp(obj)
            obj.speed = obj.speed+(obj.speed*0.05);
        end
        
        %Slower button
        function slowDown(obj)
            obj.speed = obj.speed - (obj.speed * 0.05);
        end
        
        % Manual input
        function setSpeed(obj,value)
            obj.speed = value;
        end
        
%%%%%%%%% EXTRA FUN STUFF %%%%%%%%%%%%        
              
        %For troubleshooting
        function showProperties(obj)
            fprintf('\nHi Cutoff Frequency = %3f', obj.loPassFreq);
            fprintf('\nLo Cutoff Frequency = %6f\n', obj.hiPassFreq);
            fprintf('Filter Type = %d\n',obj.filterType);
            fprintf('Samping Frequency = %d\n', obj.sampleFreq);
            fprintf('Playback Speed = %d\n', obj.speed);
            fprintf('\nDelay volume = %3d%%', obj.delayVol(1)*100);
            fprintf('\nDelay time = %6d ms\n', obj.delayTime);
            fprintf('Delay repeats = %d\n',obj.numRepeats);
            if obj.delayStatus == false
                fprintf('Delay Status =  off\n');
            else
                fprintf('Delay Status =  on\n');
            end
        end

         %This function is used by the gauge in sampleEditingSuite
        function speed = getSpeed(obj)
            speed = obj.speed;
        end
        
        %Used in the chopper GUI?
        function size = getSize(obj)
            size = obj.size;
        end
        
        %
        function sFreq = getSampleFreq(obj)
            sFreq = obj.sampleFreq;
        end
        
    end
    
    %%%%%%%% IN-HOUSE CALCULATIONS %%%%%%%%%%%%%%%
    
    methods(Static, Access = private)
        
        % Translates absolute frequency to frequency relative to the track
        %Used by filter
        function nrmlzd = normalizeFreq(sampleFreq,value)
            %Minimum value
            if value <= 0
                value = 0.01;
                nrmlzd = value.*2/sampleFreq;
           %If its less than 1 then its already normalized, so leave it
            elseif value < 1.0
                nrmlzd = value;
            %Maximum value - Nyquist frequency
            elseif value >= sampleFreq/2
                value = sampleFreq/2 - 0.01;
                nrmlzd = value.*2/sampleFreq;
            else
                nrmlzd = value.*2/sampleFreq;
            end
        end 
        
        %Converts an input milliseconds value to the number of samples
        %played in that time. Used to determine the length of the dead
        %space in the delay matrix
        function samplesNum = msToSamplesConverter(msValue, sampleFreq)
            samplesNum = msValue*sampleFreq/1000;
        end
        
        %Calculates total length of the delay matrix.
        function totalLength = calculateTotalLength(sampleLength,...
                timeSamples,numRepeats)
            totalLength = sampleLength;
            %How many repeats and how long between each repeat determines
            %how long the matrix is.
            for i = 1:numRepeats
                totalLength = (totalLength+timeSamples);
            end
        end
        
        % Used by the delayMatrix
        function monoTrack = mixToMono(array)
            sizeArray = size(array);
            %If the sample is stereo, a mono version needs to be made for
            %the delayMatrix to work (the way its set up now, anyways)
            if sizeArray(2) == 2
                peak = max(max(abs(array)));
            	%Add the two channels together...
                monoTrack = sum(array, 2);
                peak = peak/max(abs(monoTrack));
                %...Now get the volume back to where it was
                monoTrack = monoTrack*peak;
            elseif sizeArray(2) == 1
                monoTrack = zeros(sizeArray(1),1);
                for i = 1:sizeArray(1)
                    %Doing it this way so a copy is made
                    monoTrack(i,1) = array(i,1);
                end
            else
                errordlg('Error - see fxn mixToMono','Bad');
            end
        end
    end 
end