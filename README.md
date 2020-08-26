----------------------------------------------------------
# Use Azure API Management with microservices (WCF and Web API) deployed in AKS - Episode 02

[Episode1](https://github.com/GBuenaflor/01azure-aks-apimanagement/) - Build the infrastructure using Azure Terraform and Generate the Lets Encrypt Certificate 

> Episode2 - Create and contenerize ASP.Net Core Web API and WCF app then deploy to AKS ( Windows and Linux Node Pool)

[Episode3](https://github.com/GBuenaflor/01azure-aks-apimanagement-03/) - Configure API Management External / Internal Enpoints and publish API's that runs in AKS
 
----------------------------------------------------------
### High Level Architecture Diagram for the 3 Episodes:


![Image description](https://github.com/GBuenaflor/01azure-aks-apimanagement/blob/master/Images/GB-AKS-API02B.png)

----------------------------------------------------------

### Episode 2 - Create and contenerize ASP.Net Core Web API and WCF app then deploy to AKS (Linux and Windows Node Pool)


1. Create ASP.net Core Web API Application
2. Create WCF Service Application 
3. Containerize the ASP.net Core and WCF Service Application and push images to docker hub
4. Deploy to Azure Kubernetes Service


![Image description](https://github.com/GBuenaflor/01azure-aks-apimanagement-02/blob/master/Images/GB-AKS-API-E2-01A.png)


----------------------------------------------------------
### Prerequisite, set up for development/work-station machine.

- Provision Azure Windows 10 EnterpriseN, Verion 1809 , VM Size: DS2_V3

- Install HyPer-V and Containers Role

- Install Docker for Windows
  https://docs.docker.com/docker-for-windows/install/
  
- Install VS2019 Community Edition  
  https://visualstudio.microsoft.com/vs/compare/
  
- Install SQL Express 2017 
  https://www.microsoft.com/en-us/download/details.aspx?id=55994
  
- Install SSMS
  https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms?redirectedfrom=MSDN&view=sql-server-ver15
   


----------------------------------------------------------
### 1. Create ASP.net Core Web API Application

#### 1.1 Add new API Controller

```diff
[ApiController]
    [Route("[controller]")]
    public class Data01Controller : ControllerBase
    {
        private static readonly string[] DataArray = new[]
        {
            "Data01-0001", "Data01-0002", "Data01-0003", "Data01-0004", "Data01-0005" , "Data01-0006"
        };

        private readonly ILogger<Data01Controller> _logger;

        public Data01Controller(ILogger<Data01Controller> logger)
        {
            _logger = logger;
        }

        [HttpGet]
        public string[] Get()
        {
            return DataArray;             
        }
    }
```


#### 1.1 Add new Docker file
```
FROM mcr.microsoft.com/dotnet/core/aspnet:3.1-buster-slim AS base
WORKDIR /app 
EXPOSE 80 

FROM mcr.microsoft.com/dotnet/core/sdk:3.1-buster AS build
WORKDIR /src
COPY ["webAPI.csproj", ""]
RUN dotnet restore "./webAPI.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "webAPI.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "webAPI.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "webAPI.dll"]
```

#### 1.1 Configure the appsettings.json file "ASPNETCORE_ENVIRONMENT"
```
{
  "iisSettings": {
    "windowsAuthentication": false,
    "anonymousAuthentication": true,
    "iisExpress": {
      "applicationUrl": "http://localhost:50466",
      "sslPort": 44342
    }
  },
  "$schema": "http://json.schemastore.org/launchsettings.json",
  "profiles": {
    "IIS Express": {
      "commandName": "IISExpress",
      "launchBrowser": true,
      "launchUrl": "Data01",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Production"
      }
    },
    "webAPI": {
      "commandName": "Project",
      "launchBrowser": true,
      "launchUrl": "Data01",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Production"
      },
      "applicationUrl": "https://localhost:8083;http://localhost:8083"
    },
    "Docker": {
      "commandName": "Docker",
      "launchBrowser": true,
      "launchUrl": "{Scheme}://{ServiceHost}:{ServicePort}/Data01",
      "publishAllPorts": true,
      "httpPort": 25083
    }
  }
}
```


----------------------------------------------------------
### 2. Create WCF Service Application 

#### 2.1 Create new Service Contract

```
[ServiceContract]
    public interface Data02
    {
        [OperationContract]
        string[] GetDataWCF();       
    }
```

#### 2.2 Create new Class

```
 public class WCF : Data02
    {

        private string[] DataArray02 = new[]
        {
            "Data02-0001", "Data02-0002", "Data02-0003", "Data02-0004", "Data02-0005" , "Data02-0006"
        };
         
        
        public string[] GetDataWCF()
        {
            return DataArray02;
        }

    }
```


#### 2.3 View the docker file, configure the Port

```
FROM mcr.microsoft.com/dotnet/framework/wcf:4.8-windowsservercore-ltsc2019 
RUN windows\system32\inetsrv\appcmd.exe set app 'Default Web Site/' /enabledProtocols:"http,net.tcp"
EXPOSE 80 
WORKDIR /inetpub/wwwroot 
COPY . /inetpub/wwwroot
```


#### 2.4 Add Service Model section inside the web.config file

```
  <system.serviceModel>
     <services>
      <service name="wcf.WCF">
        <endpoint binding="basicHttpBinding" contract="wcf.Data02" />
        <endpoint binding="netTcpBinding" contract="wcf.Data02" bindingConfiguration="noSecurityBind"/>
        <endpoint address="mex" binding="mexTcpBinding" contract="IMetadataExchange" />
        <!--<host>
          <baseAddresses>
            <add baseAddress="http://localhost:85" /> 
          </baseAddresses>
        </host>-->
      </service>
    </services>
    <bindings>
      <basicHttpBinding>
        <binding name="BasicHttpBinding_Data02" />
      </basicHttpBinding>
     <netTcpBinding>
        <binding name="noSecurityBind" portSharingEnabled="false">
          <security mode="None" />
        </binding>
      </netTcpBinding>
    </bindings>
    <client>
      <endpoint address="http://localhost:85/Data02.svc" binding="basicHttpBinding"
        bindingConfiguration="BasicHttpBinding_Data02" contract="wcf.Data02"
        name="BasicHttpBinding_Data02" />
    </client>
    <behaviors>
      <serviceBehaviors>
        <behavior>
          <!-- To avoid disclosing metadata information, set the values below to false before deployment -->
          <serviceMetadata httpGetEnabled="true" httpsGetEnabled="true"/>
          <!-- To receive exception details in faults for debugging purposes, set the value below to true.  Set to false before deployment to avoid disclosing exception information -->
          <serviceDebug includeExceptionDetailInFaults="false"/>
        </behavior>
      </serviceBehaviors>
    </behaviors>
    <protocolMapping>
        <add binding="basicHttpsBinding" scheme="https" />
    </protocolMapping>    
    <serviceHostingEnvironment aspNetCompatibilityEnabled="true" multipleSiteBindingsEnabled="true" />
  </system.serviceModel>
```


#### 2.5 In the web.config, set up the runAllManagedModulesForAllRequests and directoryBrowse

```
<system.webServer>
    <modules runAllManagedModulesForAllRequests="true"/>
    <directoryBrowse enabled="true"/>
</system.webServer>
```


#### 2.6 Ensure the "DockerLaunchAction" and "DockerLaunchUrl" is configured under the .csproj file

```
 ...
    <DockerLaunchAction>LaunchBrowser</DockerLaunchAction>
    <DockerLaunchUrl>http://{ServiceIPAddress}/Data02.svc</DockerLaunchUrl>
 ...
 
```
  

----------------------------------------------------------
### 3. Containerize the ASP.net Core and WCF Service Application and push images to docker hub


#### 3.1 Login to your DockerHub account, and view the container(s)

```
docker login
docker container list -a
docker ps
```
 
#### 3.2 Build and run the ASP.net Core Web API , You may need to switch to Linux Container

```
cd C:\webapi>

docker build -t webapi:dev01 .
docker run -it --rm -p 8083:80 webapi:dev01

```


#### 3.3 Build and run the WCF Service Application , you may need to switch to Windows Container 

```
cd C:\wcf>

docker build -t wcf:dev01 .
docker run -it --rm -p 8084:80 wcf:dev01
```



#### 3.4 Tag the image

```
docker images
docker tag webapi:dev01 gbbuenaflor/webapi01-app:v1
docker tag wcf:dev01 gbbuenaflor/wcf01-app:v1

```

#### 3.5 Push the Images to Docker Hub

```
docker images
docker push gbbuenaflor/webapi01-app:v1
docker push gbbuenaflor/wcf01-app:v1
```
 
 
#### 3.5 View the images from docker hub

 ![Image description](https://github.com/GBuenaflor/01azure-aks-apimanagement-02/blob/master/Images/GB-AKS-API-E2-02.png)

 
----------------------------------------------------------
### 4. Deploy to Azure Kubernetes Service

#### 4.1 Get K8S Credentials
``` 
az aks get-credentials --resource-group Dev01-APIG-RG --name az-k8s
```

#### 4.2 Check the connectivity
``` 
kubectl get nodes -o wide
```

#### 4.3 Deploy the .yaml files

``` 
kubectl apply --namespace default -f "02webapi.yaml" --force
kubectl apply --namespace default -f "03wcf-Ext-Int.yaml" --force
```


#### 4.4 View the ASP.net Core WebAPI and WCF container deployed in AKS (using Windows and Linux Node Pool)

 ![Image description](https://github.com/GBuenaflor/01azure-aks-apimanagement-02/blob/master/Images/GB-AKS-API-E2-03.png)


#### 4.5 View the WCF WebService running from AKS Windows Node Pool

 ![Image description](https://github.com/GBuenaflor/01azure-aks-apimanagement-02/blob/master/Images/GB-AKS-API-E2-04.png)


#### 4.6 View the ASP.net Core Web API running from in AKS Linux Node Pool

 ![Image description](https://github.com/GBuenaflor/01azure-aks-apimanagement-02/blob/master/Images/GB-AKS-API-E2-05.png)





#### Next Episode to configure API Management External / Internal Enpoints and publish API's that runs in AKS

------------------------------------------------------------------------------
 
  

#### Go to next or other Episodes:

[Episode1](https://github.com/GBuenaflor/01azure-aks-apimanagement/) - Build the infrastructure using Azure Terraform and Generate the Lets Encrypt Certificate 

> Episode2 - Create and contenerize ASP.Net Core Web API and WCF app then deploy to AKS ( Windows and Linux Node Pool)

[Episode3](https://github.com/GBuenaflor/01azure-aks-apimanagement-03/) - Configure API Management External / Internal Enpoints and publish API's that runs in AKS



------------------------------------------------------------------------------
 
Link to other Microsoft Azure projects
https://github.com/GBuenaflor/01azure
  
Note: My Favorite -> Microsoft :D
