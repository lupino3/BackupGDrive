FROM microsoft/dotnet:2.2-sdk AS installer-env

COPY . /src/dotnet-function-app
RUN cd /src/dotnet-function-app && \
    mkdir -p /home/site/wwwroot && \
    dotnet publish *.csproj --output /home/site/wwwroot

FROM mcr.microsoft.com/azure-functions/dotnet:2.0
ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true

# RClone
#SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
#RUN Invoke-WebRequest -Uri "https://downloads.rclone.org/rclone-current-windows-amd64.zip" -OutFile /home/site/wwwroot/rclone.zip
#RUN mkdir /home/site/wwwroot/rclone
#RUN Expand-Archive -Path /home/site/wwwroot/rclone.zip -DestinationPath /home/site/wwwroot/rclone -Force -PassThru

COPY --from=installer-env ["/home/site/wwwroot", "/home/site/wwwroot"]
