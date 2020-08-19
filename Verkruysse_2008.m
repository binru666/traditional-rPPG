VideoFile = 'video.avi';  %ҪԤ�����Ƶ
FS = 25;                  %��Ƶ������
LPF = 0.7; %�ͽ�ֹƵ��
HPF = 2.5; %�߽�ֹƵ��
VidObj = VideoReader(VideoFile);
VidObj.CurrentTime = StartTime;  
FramesToRead=ceil(Duration*VidObj.FrameRate); 
T = zeros(FramesToRead,1);
RGB = zeros(FramesToRead,3);
FN = 0; 
while hasFrame(VidObj) && (VidObj.CurrentTime <= StartTime+Duration)
    FN = FN+1;
    T(FN) = VidObj.CurrentTime;
    VidFrame = readFrame(VidObj);
    VidROI = VidFrame;
    RGB(FN,:) = sum(sum(VidROI));
end
BVP = RGB(:,2);  %��ȡ������Ƶ����ɫͨ��
NyquistF = 1/2*FS;
[B,A] = butter(3,[LPF/NyquistF HPF/NyquistF]);%Butterworth 3rd order filter - originally specified in reference with a 4th order butterworth using filtfilt function
BVP_F = filtfilt(B,A,(double(BVP)-mean(BVP)));
BVP = BVP_F;  %����֮�����ɫͨ��

LL_PR = 40;  %���bpm
UL_PR = 200; %���bpm
Nyquist = FS/2;
FResBPM = 0.5; 

N = (60*2*Nyquist)/FResBPM;

% ���ƹ������ܶȣ�PSD��
[Pxx,F] = periodogram(BVP,hamming(length(BVP)),N,FS);
FMask = (F >= (LL_PR/60))&(F <= (UL_PR/60));

FRange = F(FMask);
PRange = Pxx(FMask);
MaxInd = argmax(Pxx(FMask),1);
PR_F = FRange(MaxInd);
HR = PR_F*60;   %Ԥ�����������
