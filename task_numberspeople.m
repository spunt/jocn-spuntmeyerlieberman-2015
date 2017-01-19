%=========================================================================
% TASK_WHM  WhyHowMath Experimental Task for fMRI
%
% Created Feb 2011
% Bob Spunt
% Social Cognitive Neuroscience Lab (www.scn.ucla.edu)
% University of California, Los Angeles
%=========================================================================
clear all; home;
%---------------------------------------------------------------
%% PRINT VERSION INFORMATION TO SCREEN
%---------------------------------------------------------------
script_name='- Numbers and People Task -'; boxTop(1:length(script_name))='=';
fprintf('%s\n%s\n%s\n',boxTop,script_name,boxTop)
%---------------------------------------------------------------
%% GET USER INPUT
%---------------------------------------------------------------

% get subject ID
subjectID=input('\nEnter subject ID: ','s');
while isempty(subjectID)
    disp('ERROR: no value entered. Please try again.');
    subjectID=input('Enter subject ID: ','s');
end;

% get run number
runNum=input('Enter run number (1 or 2): ');
while isempty(find(runNum==[1 2], 1)),
  runNum=input('Run number must be 1 or 2 - please re-enter: ');
end;

% is this a scan?
MRIflag=input('Are you scanning? 1 for YES, 2 for NO: ');
while isempty(find(MRIflag==[1 2], 1));
    disp('ERROR: input must be 0 or 1. Please try again.');
    MRIflag=input('Are you scanning? 1 for YES, 2 for NO: ');
end

% are you using the buttonbox or keyboard?
if MRIflag==1  % then always use the button box
    deviceflag=1;
else            % then use the button box during in-scanner tests, and keyboard when not in the scanner
    deviceflag=input('Are you using the buttonbox? 1 for YES, 2 for NO: ');
    while isempty(find(deviceflag==[1 2], 1));
        disp('ERROR: input must be 1 or 2. Please try again.');
        deviceflag=input('Are you using the buttonbox? 1 for YES, 2 for NO: ');
    end
end

%---------------------------------------------------------------
%% WRITE TRIAL-BY-TRIAL DATA TO LOGFILE
%---------------------------------------------------------------
d=clock;
logfile=sprintf('sub%s_numberspeople.log',subjectID);
fprintf('\nA running log of this session will be saved to %s\n',logfile);
fid=fopen(logfile,'a');
if fid<1,
    error('could not open logfile!');
end;
fprintf(fid,'Started: %s %2.0f:%02.0f\n',date,d(4),d(5));
WaitSecs(1);

% for runNum=1:2

%---------------------------------------------------------------
%% GET DESIGN
%---------------------------------------------------------------
if runNum==1
    tmp=randperm(10);  % using 10 designs
    designNums=tmp(1:2);
else
    cd data; d=dir(['numbers*' num2str(subjectID) '_run1*']);
    load(d(1).name);
    cd ..
end;
    
designName=strcat('design',num2str(designNums(runNum)),'.txt');
cd design
design=load(designName);
cd ..

% now fix design to remove 0.5 secs for each ITI
correctionVector=0:0.5:30;
correctionVector=correctionVector(1:length(design))';
design(:,3)=design(:,3)-correctionVector;

% if runNum==1,

%---------------------------------------------------------------
%% TASK CONSTANTS & INITIALIZE VARIABLES
%---------------------------------------------------------------
nTrials=length(design);        % number of trials (per run)
nTrialsCond=20;                     % number of trials (per condition)
nCond=3;                            % number of conditions
nRuns=2;                            % number of runs
stimDur=4;
addStart=0;
addEnd=8;
actualStimulus=cell(nTrials,1);     % actual stimulus displayed for each trial
%---------------------------------------------------------------
%% SET UP INPUT DEVICES
%---------------------------------------------------------------

subdevice_string='- Choose device for PARTICIPANT responses -'; boxTop(1:length(subdevice_string))='-';
fprintf('\n%s\n%s\n%s\n',boxTop,subdevice_string,boxTop)
inputDevice = hid_probe;

exptdevice_string='- Choose device for EXPERIMENTER responses -'; boxTop(1:length(exptdevice_string))='-';
fprintf('\n%s\n%s\n%s\n',boxTop,exptdevice_string,boxTop)
experimenter_device = hid_probe;


%---------------------------------------------------------------
%% INITIALIZE SCREENS
%---------------------------------------------------------------
AssertOpenGL;
screens=Screen('Screens');
screenNumber=max(screens);
w=Screen('OpenWindow', screenNumber,0,[],32,2);
[wWidth, wHeight]=Screen('WindowSize', w);
xcenter=wWidth/2;
ycenter=wHeight/2;
priorityLevel=MaxPriority(w);
Priority(priorityLevel);

% colors
grayLevel=0;    
black=BlackIndex(w); % Should equal 0.
white=WhiteIndex(w); % Should equal 255.
Screen('FillRect', w, grayLevel);
Screen('Flip', w);

% text
theFont='Arial';
theFontSize=40;
Screen('TextSize',w,40);
theight = Screen('TextSize', w);
Screen('TextFont',w,theFont);
Screen('TextColor',w,white);

% cues
fixation='+';

% compute default Y position (vertically centered)
numlines = length(strfind(fixation, char(10))) + 1;
bbox = SetRect(0,0,1,numlines*theight);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
PosY = dv;
% compute X position for fixation
bbox=Screen('TextBounds', w, fixation);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
fixPosX = dh;

%---------------------------------------------------------------
%% ASSIGN RESPONSE KEYS
%---------------------------------------------------------------
if deviceflag==1 % input from button box (can choose this if not scanning)
    respset=['b','y','g','r','t'];
    trigger=KbName('t');
    buttonOne=KbName('b');
    buttonTwo=KbName('y');
    buttonThree=KbName('g');
    buttonFour=KbName('r');
else                % input from keyboard
    respset=['1!','2@','3#','4$','5%'];
    trigger=KbName('5%');
    buttonOne=KbName('1!');
    buttonTwo=KbName('2@');
    buttonThree=KbName('3#');
    buttonFour=KbName('4$');
end
HideCursor;

%---------------------------------------------------------------
%% GET AND LOAD STIMULI
%---------------------------------------------------------------
loadString=sprintf('LOADING ROUND %d',runNum);
DrawFormattedText_new(w,loadString, 'center','center',white, 600, 0, 0);

Screen('Flip',w);
fmt='png';
% initialize some variables
whyStim=cell(nTrialsCond,1);
whyName=whyStim;
whyTex=whyStim;
howStim=whyStim;
howName=whyStim;
howTex=whyStim;
mathStim=whyStim;
mathName=whyStim;
mathTex=whyStim;
% get trial orders
if runNum==1
    trialOrders=[randperm(40)' randperm(40)' randperm(40)'];
end
% get stimuli
stimDirectory='stimuli/whyhowmath';
cd(stimDirectory);
d=dir(['*.' fmt]);
howCount=1;whyCount=1;mathCount=1;
for s=1:length(d),
    fname=d(s).name;
    if fname(4)=='0'
       howStim{howCount}=fname;
       howName{howCount}=imread(fname);
       howTex{howCount}=Screen('MakeTexture',w,howName{howCount});
       howCount=howCount+1;
    elseif fname(4)=='1'
       whyStim{whyCount}=fname;
       whyName{whyCount}=imread(fname);
       whyTex{whyCount}=Screen('MakeTexture',w,whyName{whyCount});
       whyCount=whyCount+1;
    elseif fname(4)=='2'
       mathStim{mathCount}=fname;
       mathName{mathCount}=imread(fname);
       mathTex{mathCount}=Screen('MakeTexture',w,mathName{mathCount});
       mathCount=mathCount+1;
    end;
end;
cd ../../

%---------------------------------------------------------------
%% iNITIALIZE SEEKER VARIABLE
%---------------------------------------------------------------
% COLUMN KEY
% 1 - trial #
% 2 - condition (1=Why, 2=How, 3=Math)
% 3 - stimulus index 
% 4 - intended onset
% 5 - actual onset
% 6 - actual offset
% 7 - response key
% 8 - correct response
% 9 - RT to stimulus onset
% 10 - skip index: 0=Valid Trials, 1=Skip (no response)
Seeker=zeros(nTrials,10);
Seeker(:,1:2)=design(:,1:2);
for o=1:nCond
    Seeker(Seeker(:,2)==o,3)=trialOrders(1+((runNum-1)*20):20+((runNum-1)*20),o);
end;
Seeker(:,4)=design(:,3)+addStart;

% display GET READY screen
Screen('FillRect', w, grayLevel);
Screen('Flip', w);
WaitSecs(0.25);

beginString=sprintf('Get ready for round %d of the Numbers & People Task.',runNum);
fullString=sprintf('%s\n\nFor NUMBER trials, indicate whether the bottom statement equals the number in the box. For PEOPLE trials, indicate whether most people would agree that the bottom statement is an appropriate description of the photograph. Keep your head still throughout.',beginString);

DrawFormattedText_new(w,fullString, 'center','center',white, 700, 0, 0);
Screen('Flip',w);

%---------------------------------------------------------------
%% WAIT FOR TRIGGER OR KEYPRESS
%---------------------------------------------------------------

% this is taken from Naomi's script
if MRIflag==1, % wait for experimenter keypress (experimenter_device) and then trigger from scanner (inputDevice)
    timer_started = 1;
    while timer_started
        [timerPressed,time] = KbCheck(experimenter_device);
        STARTscanner = time;
        if timerPressed
            timer_started = 0;
        end
    end
    DrawFormattedText_new(w, 'Waiting for the trigger...', 'center','center',white, 700, 0, 0);
    Screen('Flip',w);
    secs=KbTriggerWait(trigger,inputDevice);	% wait for trigger, return system time when detected
    anchor=secs;		% anchor timing here (because volumes are discarded prior to trigger)
    DisableKeysForKbCheck(trigger);     % So trigger is no longer detected
    triggerOFFSET = secs - STARTscanner;  % difference between experimenter keypress and when trigger detected
else % If using the keyboard, allow any key as input
    noresp=1;
    STARTscanner = GetSecs;
    while noresp
        [keyIsDown,secs,keyCode] = KbCheck(experimenter_device);
        if keyIsDown && noresp
            noresp=0;
            triggerOFFSET = secs - STARTscanner;
		anchor=secs;	% anchor timing here
        end
    end
end;
WaitSecs(0.001);

%---------------------------------------------------------------
%% TRIAL PRESENTATION!!!!!!!
%---------------------------------------------------------------
% present fixation cross until first trial cue onset
Screen('DrawText',w,fixation,fixPosX,PosY);
Screen('Flip', w);
WaitSecs('UntilTime', anchor + Seeker(1,4));

try

for t=1:nTrials
    
    
    %-----------------
    % Present stimulus
    %----------------- 
    if Seeker(t,2)==1       % why trial
        
        Screen('DrawTexture',w, whyTex{Seeker(t,3)});
        Screen('Flip',w);
        stimStart=GetSecs;
        actualStimulus{t}=whyStim{Seeker(t,3)};
        
    elseif Seeker(t,2)==2   % how trial
        
        Screen('DrawTexture',w, howTex{Seeker(t,3)});
        Screen('Flip',w);
        stimStart=GetSecs;
        actualStimulus{t}=howStim{Seeker(t,3)};
        
    elseif Seeker(t,2)==3   % math trial
        
        Screen('DrawTexture',w, mathTex{Seeker(t,3)});
        Screen('Flip',w);
        stimStart=GetSecs;
        actualStimulus{t}=mathStim{Seeker(t,3)};
        
    end
    
    %-----------------
    % Record response
    %----------------- 
    while GetSecs - stimStart < stimDur,
       [keyIsDown,secs,keyCode]=KbCheck(inputDevice);
       if keyIsDown && (keyCode(buttonOne) || keyCode(buttonTwo))
            Seeker(t,9)=secs-stimStart;
            Screen('DrawText',w,fixation,fixPosX,PosY);
            Screen('Flip', w);
            if keyCode(buttonOne)
                Seeker(t,7)=1;
            elseif keyCode(buttonTwo)
                Seeker(t,7)=2;
            end
       end;
    end; 
        
    %------------------------------------------------------
    % Present fixation cross during interstimulus interval
    %------------------------------------------------------
    Screen('DrawText',w,fixation,fixPosX,PosY);
    Screen('Flip', w);
    noresp=1;
    if Seeker(t,9)==0,   % if they did not respond to stimulus, look for button press
       while GetSecs - anchor < (Seeker(t,4) + 5)
       [keyIsDown,secs,keyCode]=KbCheck(inputDevice);
           if keyIsDown==1 && (keyCode(buttonOne) || keyCode(buttonTwo)),  
                Seeker(t,9)=secs-stimStart;
                noresp=0;
                if keyCode(buttonOne)
                    Seeker(t,7)=1;
                elseif keyCode(buttonTwo)
                    Seeker(t,7)=2;
                end
           end;
       end;
    end
    % record some variables while you wait
    Seeker(t,5)=stimStart-anchor;
    if Seeker(t,9)~=0
        Seeker(t,6)=Seeker(t,5) + Seeker(t,9);
    end
    if actualStimulus{t}(5)=='0'
        Seeker(t,8)=2;
    elseif actualStimulus{t}(5)=='1'
        Seeker(t,8)=1;
    end

    % wait for next trial
    if t~=nTrials
        WaitSecs('UntilTime', anchor + Seeker(t+1,4));
    end;
    
    if Seeker(t,7)==0,
       Seeker(t,10)=1;
    end;
       
    % PRINT TRIAL INFO TO LOG FILE
    try
        fprintf(fid,'%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n',Seeker(t,1:12));
    catch   % if sub responds weirdly, trying to print the resp crashes the log file...instead print "ERR"
        fprintf(fid,'ERROR SAVING THIS TRIAL\n');
    end;
    
end;    % end of trial loop

WaitSecs(addEnd);

catch
    Screen('CloseAll');
    Priority(0);
    psychrethrow(psychlasterror);
end;

totalTime=GetSecs-anchor;
disp(totalTime)

%---------------------------------------------------------------
%% SAVE DATA
%---------------------------------------------------------------
d=clock;
outfile=sprintf('numberspeople_%s_run%d_design%d_%s_%02.0f-%02.0f.mat',subjectID,runNum,designNums(runNum),date,d(4),d(5));

cd data
try
    save(outfile, 'Seeker','actualStimulus','subjectID','designNums','trialOrders','triggerOFFSET');
catch
	fprintf('couldn''t save %s\n saving to numberspeople_behav.mat\n',outfile);
	save act4;
end;
cd ..

%---------------------------------------------------------------
%% CLOSE SCREENS
%---------------------------------------------------------------
Screen('CloseAll');
Priority(0);
ShowCursor;
