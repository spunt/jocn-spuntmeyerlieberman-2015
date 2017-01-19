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
script_name='- Personality Task -'; boxTop(1:length(script_name))='=';
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

% % is this a scan?
% MRIflag=input('Are you scanning? 1 for YES, 2 for NO: ');
% while isempty(find(MRIflag==[1 2], 1));
%     disp('ERROR: input must be 0 or 1. Please try again.');
%     MRIflag=input('Are you scanning? 1 for YES, 2 for NO: ');
% end

% % are you using the buttonbox or keyboard?
% if MRIflag==1  % then always use the button box
%     deviceflag=1;
% else            % then use the button box during in-scanner tests, and keyboard when not in the scanner
    deviceflag=input('Are you using the buttonbox? 1 for YES, 2 for NO: ');
    while isempty(find(deviceflag==[1 2], 1));
        disp('ERROR: input must be 1 or 2. Please try again.');
        deviceflag=input('Are you using the buttonbox? 1 for YES, 2 for NO: ');
    end
% end

%---------------------------------------------------------------
%% WRITE TRIAL-BY-TRIAL DATA TO LOGFILE
%---------------------------------------------------------------
d=clock;
logfile=sprintf('sub%d_traits.log',subjectID);
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
nCond=3;
nCondBlocks=3;
nBlocks=nCond*nCondBlocks;
nTrialsperBlock=10;
nTrials=nBlocks*nTrialsperBlock;
orders=[1 2 3 2 3 1 3 1 2; 2 3 1 3 1 2 1 2 3; 3 1 2 1 2 3 2 3 1];
ISI=.5;
tmp=randperm(3);
currentOrder=orders(tmp(1),:);
% trialcode key
% 1 - block #
% 2 - condition (1=self, 2=obama, 3=case)
trialcode=zeros(nTrials,2);
for i=1:nBlocks
    pos=1+(i-1)*nTrialsperBlock;
    trialcode(pos:pos+(nTrialsperBlock-1),1)=i;
    trialcode(pos:pos+(nTrialsperBlock-1),2)=currentOrder(i);
end

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
instructCUE='Welcome to the personality task. Please read the instructions carefully, and keep your head still throughout. Press 1 to begin.';
selfCUE='For the upcoming trials, answer for YOURSELF. Use 1=Yes and 2=No. Press 1 to begin.';
obamaCUE='For the upcoming trials, answer for OBAMA. Use 1=Yes and 2=No. Press 1 to begin.';
caseCUE='For the upcoming trials, answer LOWER OR UPPERCASE. Use 1=Lowercase, 2=Uppercase. Press 1 to begin.';
options1='1 = Yes, 2 = No';
options2='1 = lower, 2 = upper';


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
stimDirectory='stimuli';
cd(stimDirectory);
load words
cd ../

%---------------------------------------------------------------
%% iNITIALIZE SEEKER VARIABLE
%---------------------------------------------------------------
% trialcode key
% 1 - block #
% 2 - condition (1=self, 2=obama, 3=case)
% 3 - word # (1-30)
% 4 - case (0=lower, 1=upper)
% 5 - response button (1 or 2)
% 6 - reaction time
Seeker=zeros(nTrials,6);
Seeker(:,1:2)=trialcode;
% word orders
Seeker(Seeker(:,2)==1,3)=randperm(30);
Seeker(Seeker(:,2)==2,3)=randperm(30); 
Seeker(Seeker(:,2)==3,3)=randperm(30);
% case assignment
Seeker(Seeker(:,2)==1,4)=randperm(30)<16;
Seeker(Seeker(:,2)==2,4)=randperm(30)<16;
Seeker(Seeker(:,2)==3,4)=randperm(30)<16;

% display GET READY screen
Screen('FillRect', w, grayLevel);
Screen('Flip', w);
WaitSecs(0.25);
DrawFormattedText_new(w, instructCUE, 'center','center',white, 700, 0, 0);
Screen('Flip',w);

%---------------------------------------------------------------
%% WAIT FOR TRIGGER OR KEYPRESS
%---------------------------------------------------------------

% this is taken from Naomi's script
% MRIflag==0
% if MRIflag==1, % wait for experimenter keypress (experimenter_device) and then trigger from scanner (inputDevice)
%     timer_started = 1;
%     while timer_started
%         [timerPressed,time] = KbCheck(experimenter_device);
%         STARTscanner = time;
%         if timerPressed
%             timer_started = 0;
%         end
%     end
%     secs=KbTriggerWait(trigger,inputDevice);	% wait for trigger, return system time when detected
%     anchor=secs;		% anchor timing here (because volumes are discarded prior to trigger)
%     DisableKeysForKbCheck(trigger);     % So trigger is no longer detected
%     triggerOFFSET = secs - STARTscanner;  % difference between experimenter keypress and when trigger detected
% else % If using the keyboard, allow any key as input
    noresp=1;
    while noresp
        [keyIsDown,secs,keyCode]=KbCheck(inputDevice);
        if keyIsDown && noresp
            noresp=0;
        end
    WaitSecs(0.001);
    end
% end;
Screen('FillRect', w, grayLevel);
Screen('Flip', w);
WaitSecs(0.25);

%---------------------------------------------------------------
%% TRIAL PRESENTATION!!!!!!!
%---------------------------------------------------------------
try

for b=1:nBlocks
    
    % 1 - block #
    % 2 - condition (1=self, 2=obama, 3=case)
    % 3 - word # (1-30)
    % 4 - case (0=lower, 1=upper)
    % 5 - response button (1 or 2)
    % 6 - reaction time
    pos=1+(b-1)*nTrialsperBlock;
    blockSeeker=zeros(nTrialsperBlock,6);
    blockSeeker=Seeker(pos:pos+(nTrialsperBlock-1),1:6);
    
    if blockSeeker(1,2)==1
       DrawFormattedText_new(w,selfCUE,'center','center',white, 700, 0, 0);
    elseif blockSeeker(1,2)==2
       DrawFormattedText_new(w,obamaCUE,'center','center',white, 700, 0, 0);
    elseif blockSeeker(1,2)==3
       DrawFormattedText_new(w,caseCUE,'center','center',white, 700, 0, 0);
    end
    % present cue
    Screen('Flip', w);
    noresp=1;
    while noresp
        [keyIsDown,secs,keyCode]=KbCheck(inputDevice);
        if noresp && keyIsDown
           noresp=0;
        end
        WaitSecs(.001);
    end
    Screen('FillRect', w, grayLevel);
    Screen('Flip', w);
    WaitSecs(0.5);
    
    % present trials
    for t=1:nTrialsperBlock
        
        if blockSeeker(t,4)==0
            currentWord=words{blockSeeker(t,3)};
        else
            currentWord=upper(words{blockSeeker(t,3)});
        end
        
        if blockSeeker(t,2)==3
            currentOptions=options2;
        else
            currentOptions=options1;
        end
        
        stimulus=sprintf('%s\n\n\n%s',currentWord,currentOptions);
        DrawFormattedText_new(w,stimulus,'center','center',white, 700, 0, 0);
        Screen('Flip',w);
        trialAnchor=GetSecs;
        noresp=1;
        while noresp
            [keyIsDown,secs,keyCode]=KbCheck(inputDevice);
            if noresp && keyIsDown && (keyCode(buttonOne) || keyCode(buttonTwo))
                noresp=0;
                Screen('FillRect', w, grayLevel);
                Screen('Flip', w);
                if keyCode(buttonOne)
                   blockSeeker(t,5)=1;
                elseif keyCode(buttonTwo)
                   blockSeeker(t,5)=2;
                end
                blockSeeker(t,6)=secs-trialAnchor;
            end
        end
        Screen('FillRect', w, grayLevel);
        Screen('Flip', w);
        WaitSecs(0.5);
        
    end; % end of trial loop
    Seeker(pos:pos+(nTrialsperBlock-1),1:6)=blockSeeker; 
    
    % PRINT TRIAL INFO TO LOG FILE
    try
        fprintf(fid,'%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n',Seeker(t,1:12));
    catch   % if sub responds weirdly, trying to print the resp crashes the log file...instead print "ERR"
        fprintf(fid,'ERROR SAVING THIS TRIAL\n');
    end;
end;    % end of block loop

catch
    Screen('CloseAll');
    Priority(0);
    psychrethrow(psychlasterror);
end;

%---------------------------------------------------------------
%% SAVE DATA
%---------------------------------------------------------------
d=clock;
outfile=sprintf('traits_%d_%s_%02.0f-%02.0f.mat',subjectID,date,d(4),d(5));

cd data
try
    save(outfile, 'Seeker','subjectID','currentOrder');
catch
	fprintf('couldn''t save %s\n saving to traits_behav.mat\n',outfile);
	save act4;
end;
cd ..

%---------------------------------------------------------------
%% CLOSE SCREENS
%---------------------------------------------------------------
Screen('CloseAll');
Priority(0);
ShowCursor;
