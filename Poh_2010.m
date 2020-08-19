addpath(genpath([cd '\test_data\']))
addpath(genpath([cd '\tools\']))
VideoFile = 'video.avi';  %ҪԤ�����Ƶ
FS = 25;                  %��Ƶ������
StartTime = 0;  %��Ƶ��ʼʱ��
Duration = 26;  %��Ƶ����ʱ��
LPF = 0.7; %�ͽ�ֹƵ��
HPF = 2.5; %�߽�ֹƵ��
VidObj = VideoReader(VideoFile);
VidObj.CurrentTime = StartTime;
FramesToRead=ceil(Duration*VidObj.FrameRate); 
T = zeros(FramesToRead,1);%��ʼ��ʱ������
RGB=zeros(FramesToRead,3);%��ʼ����ɫͨ��
FN=0;
while hasFrame(VidObj) && (VidObj.CurrentTime <= StartTime+Duration)
    FN = FN+1;
    T(FN) = VidObj.CurrentTime;
    VidFrame = readFrame(VidObj);
    VidROI = VidFrame; 
    RGB(FN,:) = mean(sum(VidROI));
end

% ȥ���ƻ� �� ICA
NyquistF = 1/2*FS;
RGBNorm=zeros(size(RGB));
Lambda=100;
for c=1:3
    T=length(RGB(:,c));
    I=speye(T);
    D2=spdiags(ones(T-2,1)*[1 -2 1],[0:2],T-2,T);
    sr=double(RGB(:,c));
    y=(I-inv(I+Lambda^2*(D2'*D2)))*sr;
    RGBNorm(:,c) = (RGBDetrend - mean(RGBDetrend))/std(RGBDetrend);%��һ��
end
[nRows, nCols] = size(RGBNorm');
if nRows > nCols
    error('�в��ܱ��д�');
end
Nsources = 3;
if Nsources > min([nRows nCols])
    Nsources = min([nRows nCols]);
end
[Winv, Zhat] = jade(RGBNorm',Nsources); 
W = pinv(Winv);
S = Zhat;
MaxPx=zeros(1,3);
for c=1:3
    FF = fft(S(c,:));
    F=(1:length(FF))/length(FF)*FS*60;
    FF(1)=[];
    N=length(FF);
    Px = abs(FF(1:floor(N/2))).^2;
    Fx = (1:N/2)/(N/2)*NyquistF;
    Px=Px/sum(Px);
    MaxPx(c)=max(Px);
end
[M,MaxComp]=max(MaxPx(:));
BVP_I = S(MaxComp,:);
[B,A] = butter(3,[LPF/NyquistF HPF/NyquistF]);%���״�ͨ�˲�
BVP_F = filtfilt(B,A,double(BVP_I));
BVP=BVP_F;

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
[~,MaxInd] = max(Pxx(FMask),[],1);
PR_F = FRange(MaxInd);
HR = PR_F*60;   %Ԥ�����������