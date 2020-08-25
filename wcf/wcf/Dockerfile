FROM mcr.microsoft.com/dotnet/framework/wcf:4.8-windowsservercore-ltsc2019 
RUN windows\system32\inetsrv\appcmd.exe set app 'Default Web Site/' /enabledProtocols:"http,net.tcp"
EXPOSE 80
#ARG source
WORKDIR /inetpub/wwwroot 
COPY . /inetpub/wwwroot