%=========================================================================
% RSS - SHAPEMATCH
%
% Created February 2011
% Bob Spunt
% Social Cognitive Neuroscience Lab (www.scn.ucla.edu)
% University of California, Los Angeles
%=========================================================================
clear all; clc;
%---------------------------------------------------------------
%% PRINT TITLE TO SCREN
%---------------------------------------------------------------
script_name='- Matching Task -'; boxTop(1:length(script_name))='=';
fprintf('%s\n%s\n%s\n',boxTop,script_name,boxTop)
%---------------------------------------------------------------
%% GET USER INPUT
%---------------------------------------------------------------

% get subject ID
subjectID=input('\nEnter subject ID: ');
while isempty(subjectID)
    disp('ERROR: no value entered. Please try again.');
    subjectID=input('Enter subject ID: ');
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
logfile=sprintf('sub%d_matching.log',subjectID);
fprintf('\nA running log of this session will be saved to %s\n',logfile);
fid=fopen(logfile,'a');
if fid<1,
    error('could not open logfile!');
end;
fprintf(fid,'Started: %s %2.0f:%02.0f\n',date,d(4),d(5));
WaitSecs(1);

%---------------------------------------------------------------
%% TASK CONSTANTS & INITIALIZE VARIABLES
%---------------------------------------------------------------
nBlocks=6;
nTrialsperBlock=9;
trialDur=1.5;
blockDur=20;
ISI=.5;
nShapes=44;
trialcode=zeros(nBlocks,3);
trialcode(:,1)=1:nBlocks;
trialcode(:,2)=[20 60 100 140 180 220];
trialcode(:,3)=trialcode(:,2)+20;

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
readyCUE='get ready!';
relaxCUE='relax';

% compute default Y position (vertically centered)
numlines = length(strfind(fixation, char(10))) + 1;
bbox = SetRect(0,0,1,numlines*theight);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
PosY = dv;
% compute X position for fixation
bbox=Screen('TextBounds', w, fixation);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
fixPosX = dh;
bbox=Screen('TextBounds', w, readyCUE);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
readyCUEPosX = dh;
bbox=Screen('TextBounds', w, relaxCUE);
[rect,dh,dv] = CenterRect(bbox, Screen('Rect', w));
relaxCUEPosX = dh;

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

DrawFormattedText_new(w, 'LOADING', 'center','center',white, 600, 0, 0);
Screen('Flip',w);
fmt='png';
shapematchStim=cell(nShapes,1);
shapematchName=cell(nShapes,1);
shapematchTex=cell(nShapes,1);
stimDirectory='stimuli/shapematch';
cd(stimDirectory);
d=dir(['*.' fmt]);
for i=1:nShapes,
    fname=d(i).name;
    shapematchStim{i}=fname;
    shapematchName{i}=imread(fname);
    shapematchTex{i}=Screen('MakeTexture',w,shapematchName{i});
end;
cd ../../

%---------------------------------------------------------------
%% iNITIALIZE SEEKER VARIABLE
%---------------------------------------------------------------
% COLUMN KEY
% 1 - block #
% 2 - intended onset
% 3 - intended offset
% 4 - actual onset
% 5 - actual offset
% 6 - performance (# correct)
Seeker=zeros(nBlocks,6);
Seeker(:,1:3)=trialcode;

% display GET READY screen
Screen('FillRect', w, grayLevel);
Screen('Flip', w);
WaitSecs(0.25);
DrawFormattedText_new(w, 'Use the 1 and 2 buttons to indicate which of the two bottom shapes matches the top shape. When + is on the screen, stare at it intently. Keep your head still throughout.', 'center','center',white, 700, 0, 0);
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
shapeCount=0;
tmp=randperm(nShapes);
shapematchOrder=tmp(1:nTrialsperBlock);
WaitSecs('UntilTime', anchor + Seeker(1,2));


try

for t=1:nBlocks
    blockStart=GetSecs;
    Screen('DrawText',w,readyCUE,readyCUEPosX,PosY);
    Screen('Flip',w);
    WaitSecs(0.8);
    Screen('FillRect', w, grayLevel);
    Screen('Flip', w);
    WaitSecs(0.2);
    perfCount=zeros(nTrialsperBlock,1);
    for i=1:nTrialsperBlock,
        Screen('DrawTexture',w, shapematchTex{shapematchOrder(i)});
        Screen('Flip',w);
        stimStart=GetSecs;
        while GetSecs - stimStart < 1.75,
           [keyIsDown,secs,keyCode]=KbCheck(inputDevice);
           if keyIsDown && (keyCode(buttonOne) || keyCode(buttonTwo))
                Screen('FillRect', w, grayLevel);
                Screen('Flip', w);
                if (keyCode(buttonOne) && shapematchStim{shapematchOrder(i)}(1)=='1') | ...
                        (keyCode(buttonTwo) && shapematchStim{shapematchOrder(i)}(1)=='2')
                    perfCount(i)=1;
                end;    
           end;
        end;
        Screen('FillRect', w, grayLevel);
        Screen('Flip', w);
        WaitSecs(0.25);
    end;
    Screen('DrawText',w,relaxCUE,relaxCUEPosX,PosY);
    Screen('Flip',w);
    WaitSecs(0.8);
    
    % Present fixation cross during intertrial interval
    Screen('DrawText',w,fixation,fixPosX,PosY);
    Screen('Flip', w);
    Seeker(t,5)=GetSecs-anchor;
    Seeker(t,4)=blockStart-anchor;
    Seeker(t,6)=sum(perfCount);
    tmp=randperm(nShapes);
    shapematchOrder=tmp(1:nTrialsperBlock);
	WaitSecs('UntilTime', anchor + Seeker(t,3) + 20);
       
    % PRINT TRIAL INFO TO LOG FILE
    try
        fprintf(fid,'%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n',Seeker(t,1:12));
    catch   % if sub responds weirdly, trying to print the resp crashes the log file...instead print "ERR"
        fprintf(fid,'ERROR SAVING THIS TRIAL\n');
    end;
end;    % end of trial loop

catch
    Screen('CloseAll');
    Priority(0);
    psychrethrow(psychlasterror);
end;

fprintf('\n\nThe total time is %2.2f\n\n',GetSecs-anchor);

%---------------------------------------------------------------
%% SAVE DATA
%---------------------------------------------------------------
d=clock;
outfile=sprintf('matching_%d_%s_%02.0f-%02.0f.mat',subjectID,date,d(4),d(5));

cd data
try
    save(outfile, 'Seeker','subjectID','triggerOFFSET');
catch
	fprintf('couldn''t save %s\n saving to matching_behav.mat\n',outfile);
	save act4;
end;
cd ..

%---------------------------------------------------------------
%% CLOSE SCREENS
%---------------------------------------------------------------
Screen('CloseAll');
Priority(0);
ShowCursor;

fprintf('\n\nThe total time is %2.2f\n\n',GetSecs-anchor);
