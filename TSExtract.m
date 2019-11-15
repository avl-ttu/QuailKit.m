clc
clear
close all
datapath='../data/';
funpath='./resources/';
respath='../Spectrogram/';
addpath(funpath);
temp=dir([datapath,'*.wav']);
record=1;
Frange=[0,4000];
windowsize=0.3;
overlap=0.8;
filename=[datapath,temp(record).name];
[raw,fs]=audioread(filename);
[Data,Spectrogram]=HT_TSExtract(raw,fs,Frange,windowsize,overlap,temp(record).name(1:18));
save([respath,temp(record).name,'.Processed.mat'],'Data','Spectrogram');