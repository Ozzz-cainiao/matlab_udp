%%产生目标到各个基阵的方位角  与正北方向的夹角

clear
close all
clc

%% 轨迹设置
[x0,y0]=deal(250,500);
v=10;
a1=0.1;
a2=0.5;
ta=0;
tb=120;
dt=0.1;
t=ta:dt:tb;
x=x0+v.*t+a1.*t.*t;
y=y0+v.*t+0.5*a2.*t.*t;
% figure
% plot(x,y);
% title('set trace');
% grid on;
% hold on;
[x1,y1,x2,y2,x3,y3,x4,y4,x5,y5]=deal(0,0,3000,0,3000,3000,0,5000,1500,4000);
arrX=[x1,x2,x3,x4,x5];
arrY=[y1,y2,y3,y4,y5];
% plot(arrX,arrY,'r*');

%% 求出目标到各平台的角度
for i=1:5
    theta(i,:)=atan2((x-arrX(i)),(y-arrY(i)));
    %     figure
    %     plot(theta(i,:));
end
%% 加上时延的
%到达节点的时间等于运动时间加传播时间
c=1500;
T=0.1;
d1=sqrt((x-arrX(1)).^2+(y-arrY(1)).^2);
t1=d1/c+t;
d2=sqrt((x-arrX(2)).^2+(y-arrY(2)).^2);
t2=d2/c+t;
d3=sqrt((x-arrX(3)).^2+(y-arrY(3)).^2);
t3=d3/c+t;
d4=sqrt((x-arrX(4)).^2+(y-arrY(4)).^2);
t4=d4/c+t;
d5=sqrt((x-arrX(5)).^2+(y-arrY(5)).^2);
t5=d5/c+t;

themin=[min(t1),min(t2),min(t3),min(t4),min(t5)];
themax=[max(t1),max(t2),max(t3),max(t4),max(t5)];
tt=max(themin):T:min(themax);

[err1,loc1]=min(abs(t1'-tt));
[err2,loc2]=min(abs(t2'-tt));
[err3,loc3]=min(abs(t3'-tt));
[err4,loc4]=min(abs(t4'-tt));
[err5,loc5]=min(abs(t5'-tt));


for ii=1:length(loc1)
    newtheta(1,ii)=theta(1,loc1(ii));
    newtheta(2,ii)=theta(2,loc2(ii));
    newtheta(3,ii)=theta(3,loc3(ii));
    newtheta(4,ii)=theta(4,loc4(ii));
    newtheta(5,ii)=theta(5,loc5(ii));
end
% csvwrite('Time_Y_Ori.csv',newtheta)
%% 各浮标的经纬度位置
lon=[120.0,120.031,120.032,120.001,120.017];
lat=[30.0,29.9993,30.0263,30.045,30.0357];
MAX_SAIL_NUM=10;
time=length(loc1)/10;
%% 直接产生结构体
% 经过一定的时延逐个发送？  产生一个发送一个？  每隔1秒中就发送五个浮标的数据
% 一个结构体 4632 字节 超过UDP上限了没？UDP无上限  但是IP层有上限
for fram=1:time
    for index=1:5
        tempvalue.buoyIndex=index;
        tempvalue.periodNum=fram;
        tempvalue.buoyLatHead=lat(index);
        tempvalue.buoyLongHead=lon(index)
        for sailnum=1:10
            tempvalue.sailInfoSN_H(sailnum).amplitude_V=100.0;
            tempvalue.sailInfoSN_H(sailnum).heading_deg=0.0;
            tempvalue.sailInfoSN_H(sailnum).orientation=newtheta(index,(fram-1)*MAX_SAIL_NUM+sailnum);  
        end
    end
end

%% 调用UDP端口发送出去
fclose(instrfindall);%先关闭之前可能存在的UDP
% %建立服务器端  
u1=udp('127.0.0.1',8080);

% u1的本机端口为8848  监听所有发送到8848端口的消息
% u1=udp('127.0.0.1','RemotePort',8847,'LocalPort',8848);
% u2=udp('127.0.0.1','RemotePort',8848,'LocalPort',8849);%同上
% u3=udp('127.0.0.1','RemotePort',8848,'LocalPort',8850);%同上

u1.DatagramReceivedFcn = @instrcallback;%设置u1接收到数据包时，调用回调函数显示
fopen(u1);%打开udp连接
%fopen(u2);%这里不需要建立u2和u3的UDP连接
%fopen(u3);%

%--------------------u1发送消息-------------------------
% u1.Remoteport=8849;
% fprintf(u1,'u2 reveive data from u1');%u1发送消息给u2
% 
% u1.Remoteport=8850;
% fprintf(u1,'u3 reveive data from u1');%u1发送消息给u3

u1.Remoteport=8080;
for fram=1:time
    pause(1)
    for index=1:5
        tempvalue.buoyIndex=index;
        tempvalue.periodNum=fram;
        tempvalue.buoyLatHead=lat(index);
        tempvalue.buoyLongHead=lon(index);
        for sailnum=1:10
            tempvalue.sailInfoSN_H(sailnum).amplitude_V=100.0;
            tempvalue.sailInfoSN_H(sailnum).heading_deg=0.0;
            tempvalue.sailInfoSN_H(sailnum).orientation=newtheta(index,(fram-1)*MAX_SAIL_NUM+sailnum);  
        end
%         aa=struct2cell(tempvalue);
%         yy=cell2mat(aa);
%         fprintf(u1,num2str(fram));
    end
end
% fprintf(u1,'netassistant receive from u1');%u1发送消息给u3

%--------------------u1接收消息-------------------------
fscanf(u1)
fscanf(u1)

fclose(u1);%关闭udp1连接
delete(u1);%删除udp1连接，释放内存
clear u1;%清除工作区中的udp1数据
% %连接后自动发送数据包
% for i=1:10
%     pause(1)
%     % 每隔1秒就发送5各浮标的数据
%     
%     fwrite(tcpipServer,doubleSize,'int');
%     fwrite(tcpipServer,str,'char');
%     fwrite(tcpipServer,i,'double');
% end


